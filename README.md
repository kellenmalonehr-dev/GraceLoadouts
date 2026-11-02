# Grace Loadouts

An Elden Ring mod that saves and equips whole loadouts from the Site of Grace menu. Pick
**Loadouts** at any grace, then **Save Gear to Loadout 1-5** or **Equip Loadout 1-5**. Slots that
hold a loadout glow.

A loadout covers both hands' weapons, arrows and bolts, armor, talismans, memorized spells, quick
items and the pouch. Items you no longer carry are skipped; the rest still goes on. Each character
has its own five slots.

Works offline, with Seamless Co-op and with Convergence. It is not for the official servers.

## Layout

| Path | Purpose |
|---|---|
| `src/GraceLoadouts.Gen` | C# generator: patches the grace talk script (`t000001000`) and adds the menu text in every game language |
| `src/GraceLoadouts.Dll` | Rust DLL: watches the menu's event flags on the game's frame loop and saves/equips |
| `release/templates` | Players' install scripts and README (Mod Engine 3 profiles, or the game folder without Mod Engine) |
| `release/package.ps1` | Builds the release zip: standalone menu, DLL, `GraceLoadouts-merge.exe`, the game-folder loader |
| `test/install-test.ps1` | Developer test install on top of an installed Seeker's Compass 1.2 (not for players) |
| `DESIGN.md` | Why it works the way it does |

## Building

1. `powershell -ExecutionPolicy Bypass -File setup.ps1` (SoulsFormatsNEXT, Paramdex, zig).
2. Unpack the game's `event`, `msg` and `script` folders (UXM Selective Unpack), as for Seeker's Compass.
3. Menu files: `dotnet run --project src\GraceLoadouts.Gen -c Release -- build`
   - `--base <folder>` builds on top of another mod's files: `E:\ConvergenceER\mod` for Convergence,
     or a Seeker's Compass folder so both menus are in one talk script.
   - `--out <folder>` (default `mod`).
   - `freeflags [--base <folder>]` lists unreferenced event flags in the 78xxx block.
4. DLL: `bash src/GraceLoadouts.Dll/build.sh` (Rust with the windows-gnu host) → `out/GraceLoadouts/`.
5. Release zip: build Seeker's Compass's game-folder loader (`bash src/SeekersCompass.Loader/build.sh` in
   the BuildCompass repo next to this one), then
   `powershell -ExecutionPolicy Bypass -File release\package.ps1 -Version 1.0.0` → `release/dist/`.

## Compatibility

- The menu replaces the grace talk script and the `menu*.msgbnd.dcx` text, like Seeker's Compass and
  Convergence. Players' installers merge it onto those mods' copies (`merge` command, see DESIGN.md);
  for development, build with `--base` on top of them.
- The equip routines are found by byte pattern. After a game patch the DLL logs whether they were
  found (`grace_loadouts.log`) and stays off if not; the fromsoftware-rs pin may also need updating.

## Credits

- [fromsoftware-rs](https://github.com/vswarte/fromsoftware-rs) (vswarte and contributors) for game
  structures and the frame-task hook
- [Mod Engine 3](https://github.com/garyttierney/me3) (garyttierney and contributors), whose mod host
  the game-folder loader reuses (MIT OR Apache-2.0)
- [The Grand Archives Elden Ring cheat table](https://github.com/The-Grand-Archives/Elden-Ring-CT-TGA),
  whose `equipItem`/`changeMagic` scripts document the equip routines and their patterns
- [SoulsFormatsNEXT](https://github.com/soulsmods/SoulsFormatsNEXT) and [Paramdex](https://github.com/soulsmods/Paramdex) (soulsmods)
- [Zig](https://ziglang.org) and [Rust](https://www.rust-lang.org) toolchains
- Built with AI coding assistance
