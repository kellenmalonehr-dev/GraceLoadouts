# Developer test install, for a game that already runs Seeker's Compass from Game\SeekersCompass
# (game-folder loader) and Elden Mod Loader (Game\mods). Not for players: release installers come later.
#   powershell -ExecutionPolicy Bypass -File test\install-test.ps1 [-Uninstall]
# - Backs up Seeker's Compass's talk script and menu text to Game\SeekersCompass\.grace-loadouts-backup,
#   then copies in mod-with-compass (both menus; build it with
#   GraceLoadouts.Gen build --base "<Game>\SeekersCompass" --out mod-with-compass).
# - Copies out\GraceLoadouts\grace_loadouts.dll into Game\mods. Its log and saved loadouts go to Game\mods.
# -Uninstall restores the backup and removes the DLL (saved loadouts are kept).
param([switch]$Uninstall)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot
$game = "D:\SteamLibrary\steamapps\common\ELDEN RING\Game"
$compass = Join-Path $game "SeekersCompass"
$backup = Join-Path $compass ".grace-loadouts-backup"
$dll = Join-Path $game "mods\grace_loadouts.dll"

if (Get-Process eldenring -ErrorAction SilentlyContinue) { throw "Close Elden Ring first." }

if ($Uninstall) {
    if (-not (Test-Path $backup)) { throw "No backup at $backup; nothing to restore." }
    Copy-Item (Join-Path $backup "*") $compass -Recurse -Force
    Remove-Item $backup -Recurse -Force
    if (Test-Path $dll) { Remove-Item $dll }
    Write-Host "Restored Seeker's Compass's files and removed grace_loadouts.dll."
    exit 0
}

$src = Join-Path $root "mod-with-compass"
$built = Join-Path $root "out\GraceLoadouts\grace_loadouts.dll"
foreach ($p in $src, $built) { if (-not (Test-Path $p)) { throw "Missing $p; build it first." } }

# Back up exactly the files we replace, once (a second install keeps the original backup).
$files = Get-ChildItem $src -Recurse -File | ForEach-Object { $_.FullName.Substring($src.Length + 1) }
if (-not (Test-Path $backup)) {
    foreach ($f in $files) {
        $from = Join-Path $compass $f
        if (-not (Test-Path $from)) { continue }
        $to = Join-Path $backup $f
        New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
        Copy-Item $from $to
    }
    Write-Host "Backed up $((Get-ChildItem $backup -Recurse -File).Count) files to $backup"
}
foreach ($f in $files) {
    $to = Join-Path $compass $f
    New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
    Copy-Item (Join-Path $src $f) $to -Force
}
Copy-Item $built $dll -Force
Write-Host "Installed $($files.Count) menu files into $compass and $dll"
