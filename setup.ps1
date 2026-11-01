# Fetches the build dependencies at the exact versions this project was built and tested with.
#   powershell -ExecutionPolicy Bypass -File setup.ps1
# - deps/SoulsFormatsNEXT, deps/Paramdex (git, pinned commits; same pins as Seeker's Compass)
# - patches/soulsformats-ignore-orphaned-bits.patch applied to SoulsFormatsNEXT
# - tools/zig (Zig 0.13.0, the assembler stand-in for the DLL build)
# The DLL's Rust crates (fromsoftware-rs, pinned in its Cargo.toml) are fetched by cargo.
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

$deps = @(
    @{ Name = "SoulsFormatsNEXT"; Url = "https://github.com/soulsmods/SoulsFormatsNEXT.git"; Commit = "9e1c36f54962f80c143e3c1fe8a709204aefacf9" },
    @{ Name = "Paramdex";         Url = "https://github.com/soulsmods/Paramdex.git";         Commit = "ff7245e524329bc3eab00036723d2bd53384cedf" }
)
New-Item -ItemType Directory -Force (Join-Path $root "deps") | Out-Null
foreach ($d in $deps) {
    $dir = Join-Path $root "deps\$($d.Name)"
    if (Test-Path (Join-Path $dir ".git")) { Write-Host "$($d.Name): already present"; continue }
    Write-Host "$($d.Name): fetching $($d.Commit.Substring(0, 9))"
    git -c core.longpaths=true init -q $dir
    git -C $dir config core.longpaths true
    git -C $dir remote add origin $d.Url
    git -C $dir fetch -q --depth 1 origin $d.Commit
    git -C $dir checkout -q FETCH_HEAD
}

# Read-only escape hatch for a param whose definition lags the game (see the patch header).
$sf = Join-Path $root "deps\SoulsFormatsNEXT"
$patch = Join-Path $root "patches\soulsformats-ignore-orphaned-bits.patch"
$row = Join-Path $sf "SoulsFormats\Formats\PARAM\PARAM\Row.cs"
if (Select-String -Path $row -Pattern "IgnoreOrphanedBits" -Quiet) { Write-Host "SoulsFormatsNEXT: patch already applied" }
else { git -C $sf apply $patch; Write-Host "SoulsFormatsNEXT: patch applied" }

# Checked against ziglang.org's published SHA-256.
$zig = Join-Path $root "tools\zig\zig.exe"
if (-not (Test-Path $zig)) {
    Write-Host "zig: downloading 0.13.0"
    $zip = Join-Path $root "tools\zig.zip"
    New-Item -ItemType Directory -Force (Join-Path $root "tools") | Out-Null
    Invoke-WebRequest "https://ziglang.org/download/0.13.0/zig-windows-x86_64-0.13.0.zip" -OutFile $zip
    if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne "D859994725EF9402381E557C60BB57497215682E355204D754EE3DF75EE3C158") { throw "zig download checksum mismatch" }
    Expand-Archive $zip (Join-Path $root "tools") -Force
    Rename-Item (Join-Path $root "tools\zig-windows-x86_64-0.13.0") "zig"
    Remove-Item $zip
}

Write-Host "`nDone. Build the menu files with:  dotnet run --project src\GraceLoadouts.Gen -c Release -- build"
Write-Host "and the DLL (needs Rust, host x86_64-pc-windows-gnu) with:  bash src/GraceLoadouts.Dll/build.sh"
