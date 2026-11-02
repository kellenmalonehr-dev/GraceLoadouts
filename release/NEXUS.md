# Nexus Mods page — Grace Loadouts

Copy each block into the matching field on the Nexus upload page.

## Upload checklist

1. Push this repo to https://github.com/kellenmalonehr-dev/GraceLoadouts (public) first, so the
   source link below works for players and for Nexus' file review.
2. Release together with Seeker's Compass 1.3.0 (its page: BuildCompass\release\NEXUS.md), so
   players who install Seeker's Compass after Grace Loadouts get the menu merge.
3. Create the mod page: name, summary, description, category below.
4. Upload **release\dist\GraceLoadouts-1.0.0.zip** as the Main file, with the file description below.
5. Images: at least one screenshot (Nexus requires a primary image). Suggested: the grace menu
   with the Loadouts line, the loadout list with glowing slots, a before/after of equipping.
6. Requirements tab: Mod Engine 3 (off-site, optional: only for option A) and, if you like,
   Seamless Co-op and Convergence as optional off-site links. Link Seeker's Compass as a
   compatible mod.
7. Permissions: your choice (e.g. whether others may reupload or modify). The game-folder loader
   in GameFolder\ is Mod Engine 3's code under MIT OR Apache-2.0, whose license files are in the zip.
8. Tick the **AI-generated content** disclosure: the mod was built with AI coding help.
9. Expect Nexus' file review (the zip has three DLLs and an exe). The "Files in this mod" section
   and the source link are there for the reviewer; if asked, point them at the GitHub source and
   at github.com/kellenmalonehr-dev/SeekersCompass (src/SeekersCompass.Loader) for the loader.

## File description

**GraceLoadouts-1.0.0.zip** (Main file)
> Grace Loadouts for the base game, Shadow of the Erdtree and Convergence. Install_GraceLoadouts.bat adds it to a Mod Engine 3 profile (Convergence's, Seeker's Compass's or your own); Install_Without_ModEngine.bat is for Seamless Co-op's own launcher and other setups without Mod Engine. Merges its grace menu with Convergence's and Seeker's Compass's. Offline only.

## Mod name

Grace Loadouts - Equip Saved Builds at Any Site of Grace

## Summary (max 255 characters)

Save up to five full loadouts per character and equip them from the Site of Grace menu: weapons, armor, talismans, spells, arrows, quick items and pouch. Works offline, with Seamless Co-op and with Convergence.

## Category / tags (suggestions)

Category: Gameplay (or User Interface). Tags: Quality of Life, Equipment, Convergence, Seamless Co-op.

## Description (BBCode)

```
[size=5][b]Grace Loadouts[/b][/size]

Swap your whole build in one step. Save what you're wearing to a loadout slot, then equip it again from any Site of Grace.

[size=4][color=#e06666][b]Do not use on the official servers[/b][/color][/size]
[list]
[*]Grace Loadouts is for [b]offline play, Seamless Co-op and Convergence[/b] only.
[*]Never play with it while connected to the official Elden Ring servers (Easy Anti-Cheat on). Using mods online can get your account banned.
[*]Both install options start the game without Easy Anti-Cheat, and the no-Mod Engine option stays off whenever Easy Anti-Cheat is running.
[/list]

[size=4][b]How it works[/b][/size]
[list=1]
[*]Rest at any Site of Grace and choose [b]Loadouts[/b].
[*]Pick [b]Save Gear to Loadout 1-5[/b] to store what you have equipped right now.
[*]Pick [b]Equip Loadout 1-5[/b] to put it back on. Slots that hold a loadout glow.
[/list]

[size=4][b]What a loadout includes[/b][/size]
[list]
[*]Weapons in both hands (all three slots per hand), arrows and bolts
[*]Head, chest, arms and legs
[*]Talismans
[*]Memorized sorceries and incantations
[*]Quick items and pouch
[/list]
Each character has its own five slots. If you no longer carry an item (sold it, or upgraded it into a different weapon), that slot is skipped and the rest still equips. Talismans go on first, so a talisman that adds a memory slot is on before the spells are attuned.

[size=4][b]Requirements[/b][/size]
[list]
[*]Elden Ring on Steam (built and tested with game version 1.17.2 / eldenring.exe 2.7.2.0; Shadow of the Erdtree supported).
[*]Option A: [url=https://github.com/garyttierney/me3/releases]Mod Engine 3[/url], or Convergence. Option B needs nothing else.
[/list]

[size=4][b]Installation[/b][/size]
Extract [b]GraceLoadouts-x.y.z.zip[/b] to its own folder (not inside ELDEN RING\Game) and keep it there. One file covers the base game, Convergence and Seeker's Compass.

[b]A) With Mod Engine 3 (Convergence, Seeker's Compass's launcher, or any Mod Engine 3 profile):[/b] run [b]Install_GraceLoadouts.bat[/b]. If Convergence is installed it offers Convergence's own launch profiles; otherwise pick the profile's [i].me3[/i] file (or drag profiles onto it). Then keep launching the way you already do.
[list]
[*]If the profile's other mods change the grace menu too (Convergence, Seeker's Compass), it builds a merged menu with both (about a minute) and loads it after them.
[*]It adds one marked block and keeps a backup. It refuses profiles that switch online play on, and offers profiles that would play on your normal save their own one.
[*]Run it again after updating Convergence or another mod in that profile. [b]Uninstall_GraceLoadouts.bat[/b] takes it back out.
[/list]
[b]B) Without Mod Engine (Seamless Co-op's own launcher, Elden Mod Loader setups):[/b] close the game and run [b]Install_Without_ModEngine.bat[/b]. It finds Elden Ring through Steam and adds [i]xinput1_4.dll[/i] and an [i]OfflineMods[/i] folder to ELDEN RING\Game. Then start the game the way you normally do:
[list]
[*][b]Seamless Co-op's launcher:[/b] Grace Loadouts loads alongside Seamless, with your Seamless characters.
[*][b]eldenring.exe directly, or Steam with an anti-cheat toggler:[/b] on the mods' own save, which starts as a copy of your characters.
[*]It stays off whenever Easy Anti-Cheat is running or Mod Engine started the game. The file loading is Mod Engine 3's own open-source code.
[*]Seeker's Compass installs into the same folder; with both, their grace menus are merged automatically.
[*]Like any DLL in the game folder, Easy Anti-Cheat may refuse to start the normal online game while it's installed: run [b]Uninstall_Without_ModEngine.bat[/b] before playing online.
[/list]

[size=4][b]Uninstall[/b][/size]
Option A: run Uninstall_GraceLoadouts.bat. Option B: run Uninstall_Without_ModEngine.bat (your saved loadouts are kept). Then delete the extracted folder. Your saves are unaffected.

[size=4][b]Compatibility[/b][/size]
[list]
[*][b]Seamless Co-op:[/b] supported.
[*][b]Convergence:[/b] supported (option A). The installer merges the grace menu with Convergence's.
[*][b]Seeker's Compass:[/b] supported, installed either way, in either order: both mods' installers merge the two grace menus (Seeker's Compass 1.3.0 or later for installing it second).
[*]Other mods that change the grace menu (talk script [i]m00_00_00_00.talkesdbnd.dcx[/i]) or menu text ([i]menu*.msgbnd.dcx[/i]) are merged the same way in option A when possible; the installer says so when it can't.
[*]Game updates: the mod finds the game's equip routines by pattern. If an update changes them, it turns itself off (see [i]grace_loadouts.log[/i]) until it's updated.
[/list]

[size=4][b]Files in this mod[/b][/size]
[list]
[*][b]grace_loadouts.dll[/b]: the mod. It watches the grace menu's choices and equips or saves gear through the game's own equipment functions. It writes only its log and the saved loadouts next to itself.
[*][b]GraceLoadouts-merge.exe[/b]: run only by the installers, to add the Loadouts line to another mod's grace menu files (Convergence, Seeker's Compass). It reads and writes those menu files and nothing else.
[*][b]GameFolder\xinput1_4.dll[/b] and [b]GameFolder\offline_mods_loader.dll[/b]: option B only. A small proxy the game loads at startup, and Mod Engine 3's own file-loading code (MIT/Apache-2.0), shared with Seeker's Compass.
[*]The .bat and .ps1 files are plain-text install scripts you can read.
[*]Source code: [url=https://github.com/kellenmalonehr-dev/GraceLoadouts]github.com/kellenmalonehr-dev/GraceLoadouts[/url] (the loader: [url=https://github.com/kellenmalonehr-dev/SeekersCompass]github.com/kellenmalonehr-dev/SeekersCompass[/url], src/SeekersCompass.Loader).
[/list]

[size=4][b]Credits[/b][/size]
[list]
[*]fromsoftware-rs (vswarte and contributors)
[*]Mod Engine 3 (garyttierney and contributors): the no-Mod Engine option reuses its file-loading, save and Arxan code (MIT/Apache-2.0)
[*]The Grand Archives Elden Ring cheat table, for documenting the equip routines
[*]SoulsFormatsNEXT and Paramdex (soulsmods)
[*]Built with AI coding assistance
[/list]
```

## Changelog

**1.0.0** — First release.
