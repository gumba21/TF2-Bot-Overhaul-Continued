$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Scripting = Join-Path $Root "tf/addons/sourcemod/scripting"
$SourceDir = Join-Path $Scripting "bot overhaul"
$IncludeDir = Join-Path $Scripting "include"
$ActiveDir = Join-Path $Root "tf/addons/sourcemod/plugins/bot overhaul"
$DisabledDir = Join-Path $Root "tf/addons/sourcemod/plugins/disabled"
$CacheDir = if ($env:TF2BOT_CACHE_DIR) { $env:TF2BOT_CACHE_DIR } else { Join-Path $Root ".cache/sourcemod" }
$SmVersion = if ($env:SOURCEMOD_VERSION) { $env:SOURCEMOD_VERSION } else { "1.12" }

New-Item -ItemType Directory -Force -Path $ActiveDir, $DisabledDir, $CacheDir | Out-Null

$Spcomp = $env:SPCOMP
if (-not $Spcomp) {
    $LocalCompiler = Join-Path $Scripting "spcomp.exe"
    $CachedCompiler = Join-Path $CacheDir "addons/sourcemod/scripting/spcomp.exe"
    if (Test-Path $LocalCompiler) { $Spcomp = $LocalCompiler }
    elseif (Test-Path $CachedCompiler) { $Spcomp = $CachedCompiler }
    else {
        $Latest = (Invoke-WebRequest -UseBasicParsing "https://www.sourcemod.net/smdrop/$SmVersion/sourcemod-latest-windows").Content.Trim()
        $Archive = Join-Path $CacheDir "sourcemod.zip"
        Invoke-WebRequest -UseBasicParsing "https://www.sourcemod.net/smdrop/$SmVersion/$Latest" -OutFile $Archive
        Expand-Archive -Force $Archive $CacheDir
        $Spcomp = $CachedCompiler
    }
}

if (-not (Test-Path $Spcomp)) { throw "spcomp was not found. Set SPCOMP or install SourceMod." }
$SmInclude = Join-Path (Split-Path $Spcomp) "include"

Get-Content (Join-Path $Root "tools/plugin-layout.txt") | ForEach-Object {
    $Line = $_.Trim()
    if (-not $Line -or $Line.StartsWith("#")) { return }
    $Parts = $Line.Split('|')
    $State, $SourceName, $OutputName = $Parts

    $Source = Join-Path $SourceDir "$SourceName.sp"
    $OutputDir = if ($State -eq "disabled") { $DisabledDir } else { $ActiveDir }
    $Output = Join-Path $OutputDir "$OutputName.smx"
    if (-not (Test-Path $Source)) { throw "Missing source: $Source" }

    & $Spcomp "-i$SmInclude" "-i$IncludeDir" "-o$Output" $Source
    if ($LASTEXITCODE -ne 0) { throw "Compilation failed: $SourceName" }
}

Write-Host "Compiled SourcePawn plugins into tf/addons/sourcemod/plugins."
