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

## Storage
- Loadouts are text files in `loadouts/` beside the DLL, named by save slot and character name. They
  aren't in the save file, so they follow neither a character copied to another save nor a renamed one.
