# Adds Grace Loadouts to (or removes it from) Mod Engine 3 profiles: Convergence's, one that
# another mod's launcher uses (Seeker's Compass's included), or one you made yourself. You keep
# launching the way you already do. Only a marked block (plus, if you agree, a marked savefile
# line) is added; the rest of each profile is left as it was, and a backup is kept. Safe to run
# more than once.
#   GraceLoadouts-setup.ps1 -Action install|uninstall|refresh [-AddSavefile] [-Yes] [profile.me3 ...]
# Without profiles: install offers Convergence's profiles if Convergence is installed, otherwise a
# file picker; uninstall uses every profile it was added to before. refresh redoes the menu merge
# in profiles that already load Grace Loadouts (Seeker's Compass's installer and launcher run it).
#
# If a profile already loads mods with their own grace menu (Convergence, Seeker's Compass, ...),
# Grace Loadouts' menu is rebuilt on top of theirs (in merged\) and set to load after them.
param(
    [ValidateSet("install", "uninstall", "refresh")][string]$Action = "install",
    [switch]$AddSavefile, # agree up front to give a profile without its own save one
    [switch]$Yes,         # agree up front to use Convergence's profiles
    [Parameter(ValueFromRemainingArguments = $true)][object[]]$Profiles
)
$ErrorActionPreference = "Stop"
$Profiles = @($Profiles | ForEach-Object { $_ } | ForEach-Object { "$_" }) # an array passed as one argument -> its items
$root = $PSScriptRoot
. (Join-Path $root "GraceLoadouts-common.ps1")
$begin = "# >>> Grace Loadouts (managed by Grace Loadouts setup - do not edit)"
$end = "# <<< Grace Loadouts"
$savefileLine = 'savefile = "ER0000.skc" # added by Grace Loadouts'
$record = Join-Path $root ".grace-loadouts-profiles.txt"
$standalone = Join-Path $root "GraceLoadouts"
$native = Join-Path $root "grace_loadouts.dll"
$merged = Join-Path $root "merged"

if ($Action -ne "uninstall") {
    foreach ($need in $standalone, $native, (Join-Path $root "GraceLoadouts-merge.exe")) {
        if (-not (Test-Path $need)) { Write-Host "Extract the whole zip first: $(Split-Path $need -Leaf) is missing next to this script."; exit 1 }
    }
}
$gameDir = $null

# Profiles keep their own line breaks (Windows or Unix style).
function New-Line([string]$text) { if ($text.Contains("`r`n")) { "`r`n" } else { "`n" } }

function Remove-OurLines([string]$text, [string]$nl) {
    $text = [regex]::Replace($text, "(\r?\n)*" + [regex]::Escape($begin) + "[\s\S]*?" + [regex]::Escape($end) + "\r?\n?", $nl)
    [regex]::Replace($text, "(?m)^" + [regex]::Escape($savefileLine) + "\r?\n", "")
}

# Just enough TOML for me3 profiles: top-level keys, and each [[package(s)]] / [[natives]] entry.
function Read-Profile([string]$path, [string]$text) {
    $dir = Split-Path $path -Parent
    $info = @{ Top = @{}; Packages = @(); Natives = @(); Style = "package" }
    $table = $null; $entry = $null
    foreach ($line in $text -split "\r?\n") {
        $t = $line.Trim()
        if ($t -match '^\[\[\s*(packages?|natives)\s*\]\]') {
            $entry = @{ after = @() }; $table = $Matches[1]
            if ($table -eq "natives") { $info.Natives += $entry } else { $info.Packages += $entry; $info.Style = $table }
        } elseif ($t -match '^\[') {
            $table = "other"; $entry = $null
        } elseif ($t -match '^([A-Za-z_]+)\s*=\s*(.+)$') {
            $key = $Matches[1]; $raw = $Matches[2].Trim()
            $value = if ($raw -match "^'([^']*)'") { $Matches[1] }
                     elseif ($raw -match '^"((?:[^"\\]|\\.)*)"') { $Matches[1] -replace '\\(.)', '$1' }
                     else { ($raw -split '#')[0].Trim() }
            if ($null -eq $table) { $info.Top[$key] = $value }
            elseif ($entry) {
                $entry[$key] = $value
                if ($key -eq "load_after") { $entry.after = @([regex]::Matches($raw, 'id\s*=\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }) }
            }
        }
    }
    foreach ($e in @($info.Packages) + @($info.Natives)) {
        if ($e.path) { $e.full = [IO.Path]::GetFullPath($(if ([IO.Path]::IsPathRooted($e.path)) { $e.path } else { Join-Path $dir $e.path })).TrimEnd('\') }
    }
    $info
}

function Format-TomlPath([string]$path) {
    if ($path -notmatch "'") { "'$path'" } else { '"' + $path.Replace('\', '\\').Replace('"', '\"') + '"' }
}

# Orders packages so each comes after the ones it loads after (as me3 does); $null if they can't
# be ordered. Those with no rule between them keep the profile's order.
function Get-LoadOrder($packages) {
    $left = [Collections.ArrayList]@($packages); $ordered = @()
    while ($left.Count) {
        $next = $left | Where-Object { $p = $_; -not ($left | Where-Object { $_ -ne $p -and $_.id -and $p.after -contains $_.id }) } | Select-Object -First 1
        if (-not $next) { return $null }
        $ordered += $next; $left.Remove($next)
    }
    $ordered
}

function Install-Into([string]$path, [bool]$onlyIfPresent) {
    $text = [IO.File]::ReadAllText($path)
    $nl = New-Line $text
    if ($onlyIfPresent -and -not $text.Contains($begin)) { return "not using Grace Loadouts." }
    $clean = Remove-OurLines $text $nl
    $p = Read-Profile $path $clean
    $name = Split-Path $path -Leaf
    $hadSavefile = $text -match "(?m)^" + [regex]::Escape($savefileLine)

    if ($p.Top["start_online"] -eq "true") {
        return "skipped: it turns on online play (start_online = true). Grace Loadouts is offline only."
    }
    if (@($p.Packages | Where-Object { $_.id -eq "grace-loadouts" }).Count -or @($p.Natives | Where-Object { $_.path -match 'grace_loadouts\.dll$' }).Count) {
        return "skipped: it already loads Grace Loadouts."
    }

    # Mods in this profile with their own copy of the grace menu files: merge onto them.
    $menuMods = @($p.Packages | Where-Object { $_.full -and (Test-Path $_.full) -and (Get-MenuFiles $_.full).Count })
    $package = $standalone; $after = @()
    if ($menuMods.Count) {
        $order = Get-LoadOrder $p.Packages
        if (-not $order) { return "skipped: its mods' load_after rules go in a circle." }
        $order = @($order | Where-Object { $menuMods -contains $_ })
        $unnamed = @($menuMods | Where-Object { -not $_.id })
        if ($unnamed.Count) { return "skipped: the mod at $($unnamed[0].path) has no id, so Grace Loadouts can't be set to load after it." }
        $base = Get-MenuBase ($order | ForEach-Object { $_.full })
        $package = Join-Path $merged $base.Fingerprint
        $after = @($order | ForEach-Object { $_.id })
        Write-Host "$name`: Grace Loadouts shares the grace menu with $($after -join ', ')."
        if (-not (Test-Path (Join-Path $package "script"))) {
            if (-not $script:gameDir) { $script:gameDir = Find-GameDir }
            if (-not $script:gameDir) { return "skipped: Elden Ring's Game folder (for its Oodle DLL) was not found through Steam." }
            try { Invoke-Merge $base $standalone $package $script:gameDir (Join-Path $root "GraceLoadouts-merge.exe") }
            catch { return "skipped: $($_.Exception.Message)" }
        }
    }

    # The modded game must never play on the normal online save. Seamless Co-op uses its own save.
    $seamless = @($p.Natives | Where-Object { $_.path -match 'ersc\.dll$' }).Count -gt 0
    $save = $p.Top["savefile"]
    $addSave = $hadSavefile
    if (-not $seamless -and (-not $save -or $save -match '\.sl2$') -and -not $addSave) {
        if ($save) { return "skipped: it plays on the normal save ($save). Change its savefile first." }
        Write-Host "`n$name plays on your normal save (ER0000.sl2). Grace Loadouts needs a separate one."
        Write-Host "Mod Engine 3 will start it with a copy of your characters in ER0000.skc; your normal save stays untouched."
        # (A refresh means another mod's own savefile line just went away: keep the profile off the normal save.)
        $answer = if ($AddSavefile -or $onlyIfPresent) { "y" } else { Read-Host "Give this profile its own save (ER0000.skc)? [Y/N]" }
        if ($answer -notmatch '^\s*y') { return "skipped: it would play on your normal save." }
        $addSave = $true
    }

    $block = "$begin${nl}# setup: $(Join-Path $root 'GraceLoadouts-setup.ps1')${nl}"
    $block += "[[$($p.Style)]]${nl}id = `"grace-loadouts`"${nl}path = $(Format-TomlPath $package)${nl}"
    if ($after.Count) {
        $rules = foreach ($id in $after) { '{ id = "' + $id + '", optional = false }' }
        $block += "load_after = [" + ($rules -join ", ") + "]$nl"
    }
    $block += "${nl}[[natives]]${nl}path = $(Format-TomlPath $native)${nl}$end"

    $new = $clean
    if ($addSave) {
        # Top-level keys must come before the first table: put it under profileVersion.
        $m = [regex]::Match($new, '(?m)^profileVersion\s*=.*\r?\n')
        $at = if ($m.Success) { $m.Index + $m.Length } else { 0 }
        $new = $new.Insert($at, "$savefileLine$nl")
    }
    $new = $new.TrimEnd() + "$nl$nl" + $block + "$nl"

    # Back up the profile as its mod left it (refreshed when an update replaced it since).
    $backup = "$path.before-grace-loadouts"
    if ($text -eq $clean -or -not (Test-Path $backup)) { [IO.File]::WriteAllText($backup, $text, $Utf8) }
    if ($new -ne $text) { [IO.File]::WriteAllText($path, $new, $Utf8) }
    $paths = @(if (Test-Path $record) { Get-Content $record }) + $path | Select-Object -Unique
    [IO.File]::WriteAllLines($record, [string[]]$paths, $Utf8)
    $how = if ($after.Count) { "with the grace menu merged, loading after $($after -join ', ')" } else { "with its own grace menu" }
    "added ($how$(if ($addSave -and -not $hadSavefile) { '; its own save, ER0000.skc' }))."
}

function Uninstall-From([string]$path) {
    $text = [IO.File]::ReadAllText($path)
    $nl = New-Line $text
    $new = (Remove-OurLines $text $nl).TrimEnd()
    # Unchanged since the backup apart from our lines: put back the backup exactly as it was.
    $backup = "$path.before-grace-loadouts"
    $original = if (Test-Path $backup) { [IO.File]::ReadAllText($backup) } else { $null }
    $new = if ($original -and $original.TrimEnd() -ceq $new) { $original } else { $new + $nl }
    if ($new -ne $text) { [IO.File]::WriteAllText($path, $new, $Utf8) }
    if (Test-Path $record) {
        $left = @(Get-Content $record | Where-Object { $_ -ne $path })
        if ($left.Count) { [IO.File]::WriteAllLines($record, [string[]]$left, $Utf8) } else { Remove-Item $record }
    }
    "removed."
}

# Merged menus no profile points at any more.
function Remove-UnusedMerges {
    if (-not (Test-Path $merged)) { return }
    $used = @(if (Test-Path $record) { Get-Content $record | Where-Object { Test-Path $_ } | ForEach-Object { [IO.File]::ReadAllText($_) } }) -join "`n"
    foreach ($d in Get-ChildItem $merged -Directory) {
        # (Format-TomlPath escapes backslashes in paths that contain an apostrophe.)
        if (-not ($used.Contains($d.FullName) -or $used.Contains($d.FullName.Replace('\', '\\')))) { Remove-Item $d.FullName -Recurse -Force }
    }
    if (-not (Get-ChildItem $merged)) { Remove-Item $merged }
}

# Convergence's own profiles: next to this folder (extracted into ConvergenceER), or where the
# Convergence Launcher installed it.
function Find-ConvergenceProfiles {
    $dirs = @($root, (Split-Path $root))
    $settings = Join-Path $env:APPDATA "ConvergenceLauncher\settings.json"
    if (Test-Path $settings) { try { $dirs += (Get-Content $settings -Raw | ConvertFrom-Json).InstallationPath } catch {} }
    foreach ($d in $dirs | Where-Object { $_ }) {
        $found = @("convergence.me3", "convergence - seamless.me3") | ForEach-Object { Join-Path $d "me3\$_" } | Where-Object { Test-Path $_ }
        if ($found) { return $found }
    }
    @()
}

# ---- which profiles ----
if (-not $Profiles) {
    if ($Action -ne "install") { $Profiles = @(if (Test-Path $record) { Get-Content $record }) }
    else {
        $convergence = @(Find-ConvergenceProfiles)
        if ($convergence.Count) {
            Write-Host "Convergence found: $(Split-Path (Split-Path $convergence[0]))"
            $answer = if ($Yes) { "y" } else { Read-Host "Add Grace Loadouts to Convergence's launch profiles? (N picks other profiles) [Y/N]" }
            if ($answer -match '^\s*y') { $Profiles = $convergence }
        }
        if (-not $Profiles) {
            Add-Type -AssemblyName System.Windows.Forms
            $dlg = New-Object Windows.Forms.OpenFileDialog
            $dlg.Title = "Choose the Mod Engine 3 profile(s) to add Grace Loadouts to"
            $dlg.Filter = "Mod Engine 3 profiles (*.me3)|*.me3"
            $dlg.Multiselect = $true
            $me3Profiles = Join-Path $env:LOCALAPPDATA "garyttierney\me3\config\profiles"
            if (Test-Path $me3Profiles) { $dlg.InitialDirectory = $me3Profiles }
            if ($dlg.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) { Write-Host "No profile chosen."; exit 1 }
            $Profiles = $dlg.FileNames
        }
    }
}
if (-not $Profiles) { Write-Host "No profiles to change."; exit 0 }

$failed = 0
foreach ($path in $Profiles) {
    $path = [IO.Path]::GetFullPath($path)
    if (-not (Test-Path $path)) { Write-Host "$path`: not found."; $failed++; continue }
    $result = switch ($Action) {
        "install" { Install-Into $path $false }
        "refresh" { Install-Into $path $true }
        "uninstall" { Uninstall-From $path }
    }
    # A refresh that can't merge any more takes Grace Loadouts out rather than hide the other menu.
    if ($Action -eq "refresh" -and $result -like "skipped*") { Uninstall-From $path | Out-Null; $result += " Grace Loadouts was taken out of it." }
    Write-Host "$(Split-Path $path -Leaf): $result"
    if ($result -like "skipped*") { $failed++ }
}
Remove-UnusedMerges
if ($Action -eq "install" -and $failed -eq $Profiles.Count) {
    Write-Host "`nGrace Loadouts was not added to any profile."
} elseif ($Action -eq "install") {
    Write-Host "`nLaunch the way you normally do; Grace Loadouts is now part of the profile(s) marked 'added'."
    Write-Host "Run this again if you move this folder, or after updating or adding a mod in that profile."
} elseif ($Action -eq "uninstall") {
    Write-Host "`nGrace Loadouts is no longer loaded by those profiles."
}
exit $failed
