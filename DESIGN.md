# Design notes

(The generator also uses this file to find the project root.)

## Two halves
- **Talk scripts can't equip items.** The grace menu (`t000001000`, patched by `GraceLoadouts.Gen`)
  only sets event flags; `grace_loadouts.dll` acts on them. 78700+n asks to equip loadout n+1,
  78705+n to save it; the DLL clears the request and keeps 78710+n on while slot n+1 holds a
  loadout, which lights that slot's Equip line (the `c1_149` glow vanilla uses for Flasks).
  The flags sit in unreferenced slots of the 78xxx block (Seeker's Compass uses 78900-78999); the
  generator refuses to build if the game or base layer references any of them.
- **The DLL runs on the game's frame loop** (a `CSTaskImp` FrameBegin task from fromsoftware-rs),
  so it equips between frames on the game's own thread rather than racing it from another thread.

## Equipping
- Equipping calls the game's own routines (the ones its equipment menu uses), found by byte pattern
  so they survive patches that don't change their code. Patterns and calling conventions follow The
  Grand Archives' cheat table (`equipItem`, `changeMagic`): one routine for slots 0-21 (weapons,
  ammo, armor, talismans), one for quick items and pouch, one for memory slots. If any pattern is
  missing or ambiguous the DLL logs it and stays off.
- Equip calls take one inventory index across both lists: key items first, then normal items at
  `key_items_capacity + i`. The spell call takes one less (as the table does). Saving logs any quick
  item whose game-recorded index disagrees with this scheme, to catch it changing.
- Order: optional slots that will change are emptied first (so an item moving between slots is
  free), then talismans (they can change memory slots and equip load), armor, weapons, ammo, quick
  items, pouch, and spells (cleared, then attuned, into the slots the character has now).
- Weapons record their gaitem handle, so the same copy (upgrade, ash of war) is picked when several
  are carried; otherwise the first copy with the same item id is used.

## Installing next to other menu mods
- Only one copy of the talk script and of each menu text file can be used, and Convergence and
  Seeker's Compass replace them too. Shipping pre-merged copies would tie each release to one
  version of every other mod, so the installers merge on the player's PC instead:
  `GraceLoadouts-merge.exe` (the generator's `merge` command, published self-contained) applies the
  same patch to the other mods' copies, falling back to the zip's standalone menu for files they
  don't have. Players don't have the game unpacked, which is why the fallback is the standalone
  menu and not vanilla.
- It uses the game's own `oo2core_6_win64.dll` (the one Oodle every player has);
  `patches/soulsformats-oodle26-no-printf.patch` lets SoulsFormatsNEXT load it.
- **Mod Engine 3 profiles** (`GraceLoadouts-setup.ps1`): packages in the profile that have menu
  files form the base, in load order (later wins); the merged copy goes to `merged/<fingerprint>`
  (size and time of every base file, so profiles with the same mods share one) and loads after
  them. The block carries `# setup: <script>` so Seeker's Compass's setup and launcher can call
  `-Action refresh` after changing the profile.
- **Game folder** (`GraceLoadouts-gamefolder.ps1`): Seeker's Compass's game-folder loader, shared
  through `Game\OfflineMods` (`package.ini` per mod, newer `loader-version.txt` wins). Our
  package.ini records the base file's size and time; if that mod changes without telling us,
  the loader falls back to our standalone menu instead of loading a stale merge.
- `grace_loadouts.dll` takes a per-process mutex, so a second copy (say in Elden Mod Loader's
  folder too) stays off instead of doing every request twice.

## Storage
- Loadouts are text files in `loadouts/` beside the DLL, named by save slot and character name. They
  aren't in the save file, so they follow neither a character copied to another save nor a renamed one.
