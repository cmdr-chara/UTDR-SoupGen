#requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectPath,

    [ValidateNotNullOrEmpty()]
    [string]$ToolsRoot = (Join-Path ([IO.Path]::GetTempPath()) 'SoupGen-GameMaker-Tools')
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Set-StrictMode -Version Latest

$registry = 'https://gmpm.gamemaker.io'
$project = [IO.Path]::GetFullPath($ProjectPath)
$tools = [IO.Path]::GetFullPath($ToolsRoot)

if (-not (Test-Path -LiteralPath $project -PathType Leaf)) {
    throw "GameMaker project not found: $project"
}

New-Item -ItemType Directory -Path $tools -Force | Out-Null

$packages = @(
    '@gm-tools/project-tool-win-x64@2026.0.173',
    '@gm-tools/package-tool-win-x64@2024.14.29',
    '@gm-tools/gmpm-win-x64@2024.14.20'
)

& npm install `
    --ignore-scripts `
    --no-audit `
    --no-fund `
    --package-lock=false `
    --registry=$registry `
    --prefix $tools `
    @packages

if ($LASTEXITCODE -ne 0) {
    throw 'Could not install the pinned GameMaker prefab tools'
}

$toolPackages = Join-Path $tools 'node_modules/@gm-tools'
$projectTool = Join-Path $toolPackages 'project-tool-win-x64/ProjectTool.exe'
$packageTool = Join-Path $toolPackages 'package-tool-win-x64/PackageTool.exe'
$gmpmLibrary = Join-Path $toolPackages 'gmpm-win-x64/gmpm.dll'

foreach ($tool in @($projectTool, $packageTool, $gmpmLibrary)) {
    if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) {
        throw "Required GameMaker prefab tool not found: $tool"
    }
}

& $projectTool PREFABS RESTORE `
    "SOURCE=$project" `
    "PACKAGETOOL=$packageTool" `
    "GMPM_DLL=$gmpmLibrary" `
    "PACKAGETOOLREGISTRY=$registry" `
    'PACKAGETOOLVERBOSE=TRUE'

if ($LASTEXITCODE -ne 0) {
    throw 'GameMaker prefab restoration failed'
}

$prefabs = Join-Path (Split-Path -Parent $project) 'prefabs'
$parallaxPrefab = @(
    Get-ChildItem -LiteralPath $prefabs -Directory -Filter 'io.gamemaker.gm_filter_parallax-*' -ErrorAction Stop
)

if ($parallaxPrefab.Count -ne 1) {
    throw 'The required GameMaker parallax filter prefab was not restored'
}

[pscustomobject]@{
    Project = $project
    Prefabs = $prefabs
    ParallaxPackage = $parallaxPrefab[0].Name
    Status = 'PASS'
} | Format-List
