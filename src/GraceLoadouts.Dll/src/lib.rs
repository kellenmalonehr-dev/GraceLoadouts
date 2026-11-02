//! Grace Loadouts: save and equip whole gear sets from the Site of Grace menu.
//!
//! The grace menu is a talk script (patched by GraceLoadouts.Gen), and talk scripts can't equip
//! items. So the menu asks through event flags: "Equip loadout N" sets `EQUIP_FLAG + N - 1`,
//! "Save gear to loadout N" sets `SAVE_FLAG + N - 1`. A task on the game's frame loop sees the flag,
//! clears it and does the work. It also keeps `STORED_FLAG + N - 1` on for every slot that holds a
//! loadout, which makes that slot's Equip line glow in the menu.
//!
//! Loadouts live in `loadouts/` next to this DLL, one file per save slot and character name.

mod equip;
mod log;
mod scan;
mod store;

use std::panic::{AssertUnwindSafe, catch_unwind};
use std::path::PathBuf;
use std::sync::OnceLock;
use std::time::Duration;

use eldenring::cs::{CSEventFlagMan, CSTaskGroupIndex, CSTaskImp, GameDataMan, GameMan, WorldChrMan};
use eldenring::fd4::FD4TaskData;
use fromsoftware_shared::{FromStatic, SharedTaskImpExt};
use windows::Win32::Foundation::{ERROR_ALREADY_EXISTS, GetLastError, HMODULE};
use windows::Win32::System::LibraryLoader::GetModuleFileNameW;
use windows::Win32::System::SystemServices::DLL_PROCESS_ATTACH;
use windows::Win32::System::Threading::CreateMutexW;
use windows::core::PCWSTR;

use crate::store::Store;

/// Loadout slots per character. The flag blocks and menu lines below are sized for this.
pub const SLOTS: u32 = 5;
// Event flags shared with the talk script (GraceLoadouts.Gen/GraceMenu.cs). The generator checks
// that nothing in the game or its base layer uses them.
pub const EQUIP_FLAG: u32 = 78700;
pub const SAVE_FLAG: u32 = 78705;
pub const STORED_FLAG: u32 = 78710;

/// The folder this DLL was loaded from; logs and loadouts are kept there.
static HOME: OnceLock<PathBuf> = OnceLock::new();

pub fn home() -> &'static PathBuf {
    HOME.get().expect("home set in DllMain")
}

/// # Safety
/// Called by the Windows loader only.
#[unsafe(no_mangle)]
pub unsafe extern "system" fn DllMain(module: HMODULE, reason: u32, _: *mut ()) -> bool {
    if reason != DLL_PROCESS_ATTACH {
        return true;
    }
    let mut buf = [0u16; 1024];
    let len = unsafe { GetModuleFileNameW(Some(module), &mut buf) } as usize;
    let dll = PathBuf::from(String::from_utf16_lossy(&buf[..len]));
    let _ = HOME.set(dll.parent().map(PathBuf::from).unwrap_or_default());

    // Nothing here may wait on the game: we're inside the loader lock.
    std::thread::spawn(start);
    true
}

fn start() {
    log::line(&format!("Grace Loadouts {} loaded", env!("CARGO_PKG_VERSION")));
    // Two loaders may both load a copy (say Mod Engine and Elden Mod Loader); only the first acts,
    // or every request would be done twice. The mutex lives as long as the game.
    let name: Vec<u16> = format!("Local\\GraceLoadouts.{}\0", std::process::id()).encode_utf16().collect();
    let first = unsafe { CreateMutexW(None, false, PCWSTR(name.as_ptr())) }.is_ok()
        && unsafe { GetLastError() } != ERROR_ALREADY_EXISTS;
    if !first {
        log::line("another copy of grace_loadouts.dll is already running in this game; this one stays off");
        return;
    }
    let calls = match equip::GameCalls::find() {
        Ok(c) => c,
        Err(e) => {
            log::line(&format!("equip functions not found ({e}); this game version isn't supported, so loadouts stay off"));
            return;
        }
    };
    let Ok(tasks) = CSTaskImp::wait_for_instance(Duration::MAX) else {
        log::line("task runner not found; loadouts stay off");
        return;
    };
    let mut state = State { calls, store: None };
    let handle = tasks.run_recurring(
        move |_: &FD4TaskData| {
            // A bug here must not crash the game: log it once and stop acting.
            if state.calls.broken {
                return;
            }
            if let Err(p) = catch_unwind(AssertUnwindSafe(|| state.tick())) {
                let msg = p.downcast_ref::<String>().cloned().or_else(|| p.downcast_ref::<&str>().map(|s| s.to_string()));
                log::line(&format!("error, loadouts turned off until restart: {}", msg.unwrap_or_default()));
                state.calls.broken = true;
            }
        },
        CSTaskGroupIndex::FrameBegin,
    );
    // The task runs for the life of the game.
    std::mem::forget(handle);
    log::line("ready");
}

struct State {
    calls: equip::GameCalls,
    /// The loaded character's loadouts; None at the title screen.
    store: Option<Store>,
}

impl State {
    fn tick(&mut self) {
        let in_world = unsafe { WorldChrMan::instance() }.map(|w| w.main_player.is_some()).unwrap_or(false);
        let (Ok(game_data), Ok(game_man), Ok(flags)) =
            (unsafe { GameDataMan::instance_mut() }, unsafe { GameMan::instance() }, unsafe { CSEventFlagMan::instance_mut() })
        else {
            return;
        };
        if !in_world {
            self.store = None;
            return;
        }
        let player = &mut *game_data.main_player_game_data;
        let flags = &mut flags.virtual_memory_flag;

        // A different character (or the first one since launch): load its loadouts and light the
        // menu lines of the slots it has.
        let key = store::character_key(game_man.save_slot, &player.character_name);
        if self.store.as_ref().map(|s| &s.key) != Some(&key) {
            let s = Store::load(key);
            log::line(&format!("character {}: {} saved loadouts", s.key, s.count()));
            for n in 0..SLOTS {
                flags.set_flag(STORED_FLAG + n, s.get(n).is_some());
            }
            self.store = Some(s);
        }
        let store = self.store.as_mut().unwrap();

        for n in 0..SLOTS {
            if flags.get_flag(SAVE_FLAG + n) {
                flags.set_flag(SAVE_FLAG + n, false);
                let loadout = equip::read_current(player);
                store.set(n, loadout);
                flags.set_flag(STORED_FLAG + n, true);
                log::line(&format!("saved loadout {}", n + 1));
            }
            if flags.get_flag(EQUIP_FLAG + n) {
                flags.set_flag(EQUIP_FLAG + n, false);
                match store.get(n) {
                    Some(loadout) => {
                        let report = self.calls.apply(player, loadout);
                        log::line(&format!("equipped loadout {}: {report}", n + 1));
                    }
                    None => log::line(&format!("loadout {} is empty", n + 1)),
                }
            }
        }
    }
}
