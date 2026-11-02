# Shared by Grace Loadouts' install scripts (dot-sourced). Nothing here runs on its own.
#
# Grace Loadouts adds a line to the grace menu, which lives in two kinds of files: the grace talk
# script and the menu text (msg\<language>\menu*.msgbnd.dcx). Other mods (Seeker's Compass,
# Convergence) replace the same files, and only one copy of a file can be used. So whenever
# another installed mod has its own copy, the installer rebuilds Grace Loadouts' menu on top of
# that copy (GraceLoadouts-merge.exe, which uses the game's own oo2core_6_win64.dll), and that
# merged copy loads after the other mod. Both menus then work.

$GraceMenuFiles = @("script\talk\m00_00_00_00.talkesdbnd.dcx")
$GraceMenuBnds = @("menu.msgbnd.dcx", "menu_dlc01.msgbnd.dcx", "menu_dlc02.msgbnd.dcx")
$Utf8 = New-Object Text.UTF8Encoding $false

function Find-GameDir {
    $steam = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
    if (-not $steam) { return $null }
    $libs = @($steam.Replace('/', '\'))
    $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        $libs += [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object { $_.Groups[1].Value.Replace('\\', '\') }
    }
    foreach ($lib in $libs | Select-Object -Unique) {
        $manifest = Join-Path $lib "steamapps\appmanifest_1245620.acf"   # Elden Ring's Steam app id
        if (-not (Test-Path $manifest)) { continue }
        $dir = [regex]::Match((Get-Content $manifest -Raw), '"installdir"\s+"([^"]+)"').Groups[1].Value
        $game = Join-Path $lib "steamapps\common\$dir\Game"
        if (Test-Path (Join-Path $game "eldenring.exe")) { return $game }
    }
    return $null
}

# The menu files a mod folder has, as relative paths (lower case).
function Get-MenuFiles([string]$dir) {
    $found = @()
    foreach ($f in $GraceMenuFiles) { if (Test-Path (Join-Path $dir $f)) { $found += $f.ToLowerInvariant() } }
    $msg = Join-Path $dir "msg"
    if (Test-Path $msg) {
        foreach ($lang in Get-ChildItem $msg -Directory) {
            foreach ($b in $GraceMenuBnds) {
                if (Test-Path (Join-Path $lang.FullName $b)) { $found += "msg\$($lang.Name)\$b".ToLowerInvariant() }
            }
        }
    }
    $found
}

# The copy of each menu file the game would see from these mod folders, in load order (later wins):
# an ordered map of relative path -> full path, plus a fingerprint that changes when any of them does.
function Get-MenuBase([string[]]$dirs) {
    $map = [ordered]@{}
    foreach ($d in $dirs) { foreach ($f in Get-MenuFiles $d) { $map[$f] = Join-Path $d $f } }
    $lines = foreach ($k in $map.Keys) { $i = Get-Item -LiteralPath $map[$k]; "$k|$($i.Length)|$($i.LastWriteTimeUtc.Ticks)" }
    $sha = [Security.Cryptography.SHA256]::Create()
    $hash = -join ($sha.ComputeHash($Utf8.GetBytes(($lines -join "`n"))) | Select-Object -First 6 | ForEach-Object { $_.ToString("x2") })
    @{ Files = $map; Fingerprint = $hash }
}

# Builds Grace Loadouts' menu on top of $base (from Get-MenuBase) into $out.
function Invoke-Merge($base, [string]$standalone, [string]$out, [string]$gameDir, [string]$mergeExe) {
    $work = "$out.base"
    if (Test-Path $work) { Remove-Item $work -Recurse -Force }
    foreach ($k in $base.Files.Keys) {
        $to = Join-Path $work $k
        New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
        Copy-Item -LiteralPath $base.Files[$k] $to
    }
    Write-Host "  Merging the Grace Loadouts menu with the other mod's menu (this takes about a minute)..."
    $output = & $mergeExe merge --base $work --standalone $standalone --out $out --game $gameDir 2>&1
    $ok = $LASTEXITCODE -eq 0
    Remove-Item $work -Recurse -Force
    if (-not $ok) {
        if (Test-Path $out) { Remove-Item $out -Recurse -Force }
        throw "the menus could not be merged: $(($output | Out-String).Trim())"
    }
}

# ---- game-folder install (Game\OfflineMods, shared with Seeker's Compass) ----------------------

# What Game\xinput1_4.dll is: "offline" (the shared loader's proxy), "seekers-1.2" (Seeker's
# Compass 1.2's own proxy, which this one replaces), "other" (another mod's), or $null (none).
function Get-ProxyKind([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    $bytes = [IO.File]::ReadAllBytes($path)
    # Names are stored as UTF-16; read the file at both byte alignments.
    foreach ($start in 0, 1) {
        $text = [Text.Encoding]::Unicode.GetString($bytes, $start, $bytes.Length - $start)
        if ($text -match "offline_mods_loader\.dll") { return "offline" }
        if ($text -match "seekers_compass_loader\.dll") { return "seekers-1.2" }
    }
    "other"
}

# The other mods in Game\OfflineMods (and a Seeker's Compass 1.2 install), in load order, as
# @{ Name; Order; Files } - Files is the folder whose game files they swap in.
function Get-OfflineMods([string]$gameDir, [string]$except) {
    $mods = @()
    $root = Join-Path $gameDir "OfflineMods"
    foreach ($dir in Get-ChildItem $root -Directory -ErrorAction SilentlyContinue) {
        if ($dir.Name -eq $except) { continue }
        $ini = Join-Path $dir.FullName "package.ini"
        if (-not (Test-Path $ini)) { continue }
        $keys = @{}
        foreach ($line in Get-Content $ini) {
            $l = ($line -split '#')[0].Trim()
            if ($l -match '^([A-Za-z_]+)\s*=\s*(.*)$') { $keys[$Matches[1]] = $Matches[2].Trim() }
        }
        $files = Join-Path $dir.FullName $(if ($keys.files) { $keys.files } else { "." })
        $mods += @{ Name = $(if ($keys.name) { $keys.name } else { $dir.Name }); Order = [int]$keys.order; Files = [IO.Path]::GetFullPath($files) }
    }
    $legacy = Join-Path $gameDir "SeekersCompass"
    if (Test-Path (Join-Path $legacy ".installed-by-seekers-compass")) {
        $mods += @{ Name = "Seeker's Compass"; Order = 10; Files = $legacy }
    }
    @($mods | Sort-Object { $_.Order }, { $_.Name })
}

# Chooses Grace Loadouts' menu in Game\OfflineMods\GraceLoadouts: merged with the menus of the
# other installed mods if they have any, else the standalone copy. Writes package.ini.
function Update-GameFolderMenu([string]$pkgDir, [string]$gameDir) {
    $others = @(Get-OfflineMods $gameDir "GraceLoadouts" | Where-Object { (Get-MenuFiles $_.Files).Count -gt 0 })
    $ini = @(
        "# Read by Game\OfflineMods\offline_mods_loader.dll. Written by Grace Loadouts' installer.",
        "name = Grace Loadouts",
        "order = 20",
        "native = grace_loadouts.dll"
    )
    $menu = Join-Path $pkgDir "menu"
    if (Test-Path $menu) { Remove-Item $menu -Recurse -Force }
    if ($others.Count) {
        $base = Get-MenuBase ($others | ForEach-Object { $_.Files })
        Write-Host "Grace Loadouts shares the grace menu with: $(($others | ForEach-Object { $_.Name }) -join ', ')"
        Invoke-Merge $base (Join-Path $pkgDir "standalone") $menu $gameDir (Join-Path $pkgDir "GraceLoadouts-merge.exe")
        # If that mod is removed or updated without telling us, the loader falls back to standalone.
        $key = @($base.Files.Keys | Where-Object { $_ -like "script\*" }) + @($base.Files.Keys) | Select-Object -First 1
        $stamp = Get-Item -LiteralPath $base.Files[$key]
        $ini += "files = menu", "fallback = standalone",
            "base = $($stamp.FullName)",
            "base_size = $($stamp.Length)", "base_time = $($stamp.LastWriteTimeUtc.ToFileTimeUtc())"
        Write-Host "  Both menus are in place."
    } else {
        $ini += "files = standalone"
    }
    [IO.File]::WriteAllLines((Join-Path $pkgDir "package.ini"), [string[]]$ini, $Utf8)
}
