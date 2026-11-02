GRACE LOADOUTS
==============

Save up to five loadouts per character and equip them from any Site of Grace: weapons in
both hands, arrows and bolts, armor, talismans, memorized spells, quick items and pouch.
Rest at a grace and choose "Loadouts". "Save Gear to Loadout 1-5" stores what you have on;
"Equip Loadout 1-5" puts it back on (slots that hold a loadout glow).

OFFLINE ONLY: NEVER USE THIS ON THE OFFICIAL SERVERS
Grace Loadouts is for offline play, Seamless Co-op and Convergence. Don't play with it while
connected to the official Elden Ring servers (Easy Anti-Cheat on): mods online can get your
account banned. Both install options below start the game without Easy Anti-Cheat, and
the game-folder option stays off whenever Easy Anti-Cheat is running.

REQUIREMENTS
- Elden Ring (Steam), built and tested with eldenring.exe 2.7.2.0. Later versions work if
  they keep the same equip code (grace_loadouts.log says if they don't).
- Option A: Mod Engine 3 (https://github.com/garyttierney/me3/releases), or Convergence.
- Option B needs nothing else.

INSTALL
Extract this zip to its own folder (not inside the ELDEN RING\Game folder) and keep it there:
the game loads Grace Loadouts from it in option A. Then pick the option that matches how you play.

A) With Mod Engine 3: Convergence, Seeker's Compass's launcher, or any Mod Engine 3 profile
   Run Install_GraceLoadouts.bat. If Convergence is installed it offers Convergence's own
   profiles; otherwise choose the profile's .me3 file (or drag .me3 files onto the .bat).
   Then keep launching the way you already do. The installer:
   - adds one marked block to the profile and keeps a backup (*.before-grace-loadouts);
   - if the profile's other mods change the grace menu too (Convergence, Seeker's Compass),
     builds a merged menu with both (takes about a minute) and loads it after them;
   - refuses profiles with online play switched on, and offers profiles that would play on
     your normal save their own one (ER0000.skc, which starts as a copy of your characters).
   Run it again if you move this folder, or after updating or adding a mod in that profile.
   Seeker's Compass's launcher (Launch_SeekersCompass.bat): choose its SeekersCompass.me3.

B) Without Mod Engine (Seamless Co-op's own launcher, Elden Mod Loader setups, offline starts)
   Close the game and run Install_Without_ModEngine.bat. It finds Elden Ring through Steam and
   adds xinput1_4.dll and an OfflineMods folder to ELDEN RING\Game. Then start the game the way
   you normally do:
   - Seamless Co-op's launcher (ersc_launcher.exe): with your Seamless characters.
   - eldenring.exe directly, or Steam with an anti-cheat toggler: on the mods' own save
     (ER0000.skc), which starts as a copy of your characters.
   It stays off whenever Easy Anti-Cheat is running or Mod Engine started the game. Seeker's
   Compass installs the same way into the same folder; with both installed, their menus are
   merged automatically, whichever you install first. If another mod already uses
   Game\xinput1_4.dll, use option A.
   Like any DLL in the game folder, Easy Anti-Cheat may refuse to start the normal online
   game while it's installed: uninstall it before playing online.

SAVED LOADOUTS
Kept per character (save slot and name) in a "loadouts" folder: next to grace_loadouts.dll in
this folder (option A) or in Game\OfflineMods\GraceLoadouts (option B). They aren't part of
your save file, so a renamed character starts with empty slots. Items you no longer carry
are skipped; the rest of the loadout still goes on.

UNINSTALL
Option A: run Uninstall_GraceLoadouts.bat. Option B: run Uninstall_Without_ModEngine.bat
(your saved loadouts are kept). Then delete this folder. Your saves are unaffected.

COMPATIBILITY
- Works with Seamless Co-op, Convergence and Seeker's Compass (menus merged by the installer).
- Other mods that change the grace menu (script/talk/m00_00_00_00.talkesdbnd.dcx) or menu
  text (msg/*/menu*.msgbnd.dcx) are merged the same way in option A. If the merge can't find
  its place in their menu, the installer says so and leaves that profile alone.
- After a game patch, if the equip code moved, Grace Loadouts turns itself off and says so in
  grace_loadouts.log until it's updated.

SOURCE
https://github.com/kellenmalonehr-dev/GraceLoadouts
(the game-folder loader in GameFolder\ is Mod Engine 3's code, built from
https://github.com/kellenmalonehr-dev/SeekersCompass, src/SeekersCompass.Loader)
