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
| `test/install-test.ps1` | Developer test install on top of an installed Seeker's Compass (not for players) |
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

## Compatibility

- The menu replaces the grace talk script and the `menu*.msgbnd.dcx` text, like Seeker's Compass. Build
  with `--base` on top of any other mod that changes those files.
- The equip routines are found by byte pattern. After a game patch the DLL logs whether they were
  found (`grace_loadouts.log`) and stays off if not; the fromsoftware-rs pin may also need updating.

## Credits

- [fromsoftware-rs](https://github.com/vswarte/fromsoftware-rs) (vswarte and contributors) for game
  structures and the frame-task hook
- [The Grand Archives Elden Ring cheat table](https://github.com/The-Grand-Archives/Elden-Ring-CT-TGA),
  whose `equipItem`/`changeMagic` scripts document the equip routines and their patterns
- [SoulsFormatsNEXT](https://github.com/soulsmods/SoulsFormatsNEXT) and [Paramdex](https://github.com/soulsmods/Paramdex) (soulsmods)
- [Zig](https://ziglang.org) and [Rust](https://www.rust-lang.org) toolchains
- Built with AI coding assistance
