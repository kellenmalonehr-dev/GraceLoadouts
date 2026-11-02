# Puts Grace Loadouts into the ELDEN RING\Game folder (or takes it out again), for playing
# without Mod Engine: Seamless Co-op's own launcher, Steam with an anti-cheat toggler, or
# eldenring.exe directly. Nothing of the game's own is changed or replaced.
#   GraceLoadouts-gamefolder.ps1 -Action install|uninstall|refresh [-GameDir <...\ELDEN RING\Game>]
# Installs (the folder layout is shared with Seeker's Compass, which installs the same way):
#   Game\xinput1_4.dll                     small proxy the game loads at startup; passes controller
#                                          calls to Windows' own xinput1_4.dll
#   Game\OfflineMods\offline_mods_loader.dll
#                                          swaps in the mods' files (Mod Engine 3's own code) and loads
#                                          their DLLs, unless Easy Anti-Cheat is running or Mod Engine
#                                          started the game
#   Game\OfflineMods\GraceLoadouts\        this mod: grace_loadouts.dll, its menu, your saved loadouts
# If Seeker's Compass is installed there too, the two menus are merged into one (refresh redoes
# that; Seeker's Compass's installer runs it after installing or removing itself).
param(
    [ValidateSet("install", "uninstall", "refresh")][string]$Action = "install",
    [string]$GameDir
)
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
. (Join-Path $root "GraceLoadouts-common.ps1")

if (-not $GameDir) {
    # An installed copy (refresh) lives in Game\OfflineMods\GraceLoadouts.
    $up = Split-Path (Split-Path $root)
    $GameDir = if (Test-Path (Join-Path $up "eldenring.exe")) { $up } else { Find-GameDir }
}
if (-not $GameDir -or -not (Test-Path (Join-Path $GameDir "eldenring.exe"))) {
    Write-Host "Elden Ring's Game folder was not found through Steam."
    Write-Host "Run this again with the folder, e.g.:  Install_Without_ModEngine.bat -GameDir `"D:\SteamLibrary\steamapps\common\ELDEN RING\Game`""
    exit 1
}
if (Get-Process eldenring -ErrorAction SilentlyContinue) { Write-Host "Close Elden Ring first."; exit 1 }

$proxy = Join-Path $GameDir "xinput1_4.dll"
$mods = Join-Path $GameDir "OfflineMods"
$target = Join-Path $mods "GraceLoadouts"
$marker = Join-Path $target ".installed-by-grace-loadouts"
Write-Host "Elden Ring: $GameDir"

if ($Action -eq "refresh") {
    if (-not (Test-Path $marker)) { exit 0 }   # not installed this way: nothing to do
    try { Update-GameFolderMenu $target $GameDir } catch { Write-Host "Grace Loadouts: $($_.Exception.Message)"; exit 1 }
    exit 0
}

if ($Action -eq "uninstall") {
    if (Test-Path $marker) {
        # Saved loadouts are the player's: keep them.
        Get-ChildItem $target -Force | Where-Object { $_.Name -ne "loadouts" } | Remove-Item -Recurse -Force
        if (Test-Path (Join-Path $target "loadouts")) { Write-Host "Removed Grace Loadouts; kept your saved loadouts in $target\loadouts" }
        else { Remove-Item $target -Force; Write-Host "Removed Grace Loadouts" }
    } elseif (Test-Path $target) { Write-Host "Left Game\OfflineMods\GraceLoadouts alone: this installer didn't create it." }
    # The loader and proxy go once no mod uses them any more.
    if (@(Get-OfflineMods $GameDir "").Count -eq 0) {
        foreach ($f in "offline_mods_loader.dll", "loader-version.txt", "loader.log", "launch.log") {
            $p = Join-Path $mods $f; if (Test-Path $p) { Remove-Item $p }
        }
        if ((Get-ProxyKind $proxy) -eq "offline") { Remove-Item $proxy; Write-Host "Removed xinput1_4.dll" }
        if ((Test-Path $mods) -and -not (Get-ChildItem $mods -Force)) { Remove-Item $mods }
    }
    Write-Host "`nDone. Your saves are untouched."
    exit 0
}

# ---- install ----
$files = Join-Path $root "GameFolder"
foreach ($need in "GraceLoadouts\script", "grace_loadouts.dll", "GraceLoadouts-merge.exe", "GameFolder\xinput1_4.dll") {
    if (-not (Test-Path (Join-Path $root $need))) { Write-Host "Extract the whole zip first: $need is missing next to this script."; exit 1 }
}
$kind = Get-ProxyKind $proxy
if ($kind -eq "other") {
    Write-Host "Another mod already uses Game\xinput1_4.dll, so Grace Loadouts can't be installed this way."
    Write-Host "Use Install_GraceLoadouts.bat (Mod Engine 3) instead."
    exit 1
}
# (An uninstall leaves just the saved loadouts and the log behind.)
$foreign = @(Get-ChildItem $target -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin "loadouts", "grace_loadouts.log" })
if ($foreign.Count -and -not (Test-Path $marker)) {
    Write-Host "Game\OfflineMods\GraceLoadouts already exists and wasn't made by this installer. Move it away and run this again."
    exit 1
}

# The shared loader: install it, or update it if this copy is newer than the installed one.
New-Item -ItemType Directory -Force $target | Out-Null
$ours = [int](Get-Content (Join-Path $files "loader-version.txt"))
$versionFile = Join-Path $mods "loader-version.txt"
$installed = if (Test-Path $versionFile) { [int](Get-Content $versionFile) } else { 0 }
if ($ours -gt $installed -or -not (Test-Path (Join-Path $mods "offline_mods_loader.dll")) -or $kind -ne "offline") {
    Copy-Item (Join-Path $files "offline_mods_loader.dll") $mods -Force
    Copy-Item (Join-Path $files "loader-version.txt") $mods -Force
    Copy-Item (Join-Path $files "xinput1_4.dll") $proxy -Force
    if ($kind -eq "seekers-1.2") { Write-Host "Replaced Seeker's Compass 1.2's xinput1_4.dll with the shared one (it still loads Seeker's Compass)." }
}

# The mod itself. Replace everything but saved loadouts, so files a newer version dropped don't linger.
Get-ChildItem $target -Force | Where-Object { $_.Name -notin "loadouts", "grace_loadouts.log" } | Remove-Item -Recurse -Force
Copy-Item (Join-Path $root "GraceLoadouts") (Join-Path $target "standalone") -Recurse
foreach ($f in "grace_loadouts.dll", "GraceLoadouts-merge.exe", "GraceLoadouts-common.ps1", "GraceLoadouts-gamefolder.ps1") {
    Copy-Item (Join-Path $root $f) $target
}
Set-Content $marker "Installed by Install_Without_ModEngine.bat; Uninstall_Without_ModEngine.bat removes this folder (but keeps loadouts)."
try { Update-GameFolderMenu $target $GameDir }
catch {
    Write-Host "Grace Loadouts: $($_.Exception.Message)"
    Write-Host "It is installed with its own menu only, so the other mod's grace menu line is hidden."
    [IO.File]::WriteAllLines((Join-Path $target "package.ini"), [string[]]@("name = Grace Loadouts", "order = 20", "native = grace_loadouts.dll", "files = standalone"), $Utf8)
}

Write-Host "`nDone. Start Elden Ring the way you normally do without Mod Engine:"
Write-Host "  - Seamless Co-op's launcher (ersc_launcher.exe): with your Seamless characters."
Write-Host "  - eldenring.exe directly, or Steam with an anti-cheat toggler: on the mods' own save (ER0000.skc),"
Write-Host "    which starts as a copy of your characters. Your normal save is never written."
Write-Host "With Easy Anti-Cheat running, or through Mod Engine, it stays off."
Write-Host "If Easy Anti-Cheat refuses to start the normal game, run Uninstall_Without_ModEngine.bat."
