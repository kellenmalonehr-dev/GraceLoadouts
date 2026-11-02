# Builds the release zip for Nexus. One zip covers every setup: the installers merge the menu
# with Convergence's or Seeker's Compass's on the player's PC (GraceLoadouts-merge.exe).
#   powershell -ExecutionPolicy Bypass -File release\package.ps1 [-Version 1.0.0] [-Loader <folder>]
# The game-folder loader is Seeker's Compass's shared one (both mods install it into
# Game\OfflineMods); -Loader defaults to its build output next to this repo (bash
# src/SeekersCompass.Loader/build.sh in BuildCompass).
param(
    [string]$Version = "1.0.0",
    [string]$Loader
)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$templates = Join-Path $PSScriptRoot "templates"
$stage = Join-Path $PSScriptRoot "staging\GraceLoadouts-$Version"
$dist = Join-Path $PSScriptRoot "dist"
if (-not $Loader) { $Loader = Join-Path (Split-Path $root) "BuildCompass\out\loader" }
$loaderSrc = Join-Path (Split-Path $Loader -Parent | Split-Path -Parent) "src\SeekersCompass.Loader"

foreach ($f in "xinput1_4.dll", "OfflineMods\offline_mods_loader.dll") {
    if (-not (Test-Path (Join-Path $Loader $f))) { throw "$Loader\$f is missing: build Seeker's Compass's loader first (bash src/SeekersCompass.Loader/build.sh)." }
}
$dll = Join-Path $root "out\GraceLoadouts\grace_loadouts.dll"
if (-not (Test-Path $dll)) { throw "out\GraceLoadouts\grace_loadouts.dll is missing: run  bash src/GraceLoadouts.Dll/build.sh  first." }

if (Test-Path (Split-Path $stage)) { Remove-Item (Split-Path $stage) -Recurse -Force }
New-Item -ItemType Directory -Force $stage, $dist | Out-Null

# Standalone menu (vanilla + Loadouts), built from the unpacked game.
dotnet run --project (Join-Path $root "src\GraceLoadouts.Gen") -c Release -- build --out (Join-Path $stage "GraceLoadouts") | Select-String "grace menu:|Exception"
if ($LASTEXITCODE) { throw "menu build failed" }

# The merge tool: one self-contained exe, so players need no .NET install.
$pub = Join-Path $PSScriptRoot "staging\merge"
dotnet publish (Join-Path $root "src\GraceLoadouts.Gen") -c Release -r win-x64 --self-contained `
    -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:PublishTrimmed=true -p:TrimMode=partial -p:InvariantGlobalization=true -p:DebugType=none -o $pub -v q | Out-Null
if ($LASTEXITCODE) { throw "merge tool publish failed" }
Copy-Item (Join-Path $pub "GraceLoadouts.Gen.exe") (Join-Path $stage "GraceLoadouts-merge.exe")
Remove-Item $pub -Recurse -Force

Copy-Item $dll $stage
foreach ($f in Get-ChildItem $templates -File) { Copy-Item $f.FullName $stage }

# Game-folder loader (shared with Seeker's Compass). Mod Engine 3's code: ship its licenses with it.
$gf = Join-Path $stage "GameFolder"
New-Item -ItemType Directory -Force $gf | Out-Null
Copy-Item (Join-Path $Loader "xinput1_4.dll"), (Join-Path $Loader "OfflineMods\offline_mods_loader.dll") $gf
Copy-Item (Join-Path $Loader "loader-version.txt") $gf
foreach ($f in "LICENSE-MIT", "LICENSE-APACHE") { Copy-Item (Join-Path $loaderSrc $f) (Join-Path $gf "ModEngine3-$f") }

$zip = Join-Path $dist "GraceLoadouts-$Version.zip"
if (Test-Path $zip) { Remove-Item $zip }
# .NET writes forward-slash zip entries (Windows PowerShell 5's Compress-Archive doesn't).
dotnet run --project (Join-Path $root "src\GraceLoadouts.Gen") -c Release --no-build -- zip $stage $zip
Get-ChildItem $dist | ForEach-Object { "{0}  {1:N1} MB" -f $_.Name, ($_.Length / 1MB) }
