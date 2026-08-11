#requires -Version 7.0

[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-Condition {
    param(
        $Condition,
        [string]$Message
    )

    $passed = $true
    foreach ($value in @($Condition)) {
        if (-not [bool]$value) {
            $passed = $false
            break
        }
    }

    if (-not $passed) {
        throw $Message
    }
}

$repository = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\')
$projectRoot = Join-Path $repository 'UTDR Textbox Gen'
$projectPath = Join-Path $projectRoot 'UTDR Textbox Gen.yyp'

Assert-Condition (Test-Path -LiteralPath $projectPath -PathType Leaf) "GameMaker project not found: $projectPath"

$jsonFiles = @(
    Get-ChildItem -LiteralPath $projectRoot -Recurse -File |
        Where-Object { $_.Extension -in @('.yy', '.yyp', '.resource_order') }
)

foreach ($file in $jsonFiles) {
    try {
        Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json | Out-Null
    }
    catch {
        throw "Invalid GameMaker JSON: $($file.FullName)"
    }
}

$project = Get-Content -LiteralPath $projectPath -Raw | ConvertFrom-Json

foreach ($resource in $project.resources) {
    $resourcePath = Join-Path $projectRoot $resource.id.path
    Assert-Condition (Test-Path -LiteralPath $resourcePath -PathType Leaf) "Missing resource: $($resource.id.path)"
}

foreach ($included in $project.IncludedFiles) {
    $includedPath = Join-Path $projectRoot (Join-Path $included.filePath $included.name)
    Assert-Condition (Test-Path -LiteralPath $includedPath -PathType Leaf) "Missing included file: $($included.filePath)/$($included.name)"
}

foreach ($room in $project.RoomOrderNodes) {
    $roomPath = Join-Path $projectRoot $room.roomId.path
    Assert-Condition (Test-Path -LiteralPath $roomPath -PathType Leaf) "Missing room in room order: $($room.roomId.path)"
}

$textFiles = @(
    Get-ChildItem -LiteralPath $repository -Recurse -File |
        Where-Object {
            $_.FullName -notmatch '[\\/]\.git[\\/]' -and
            $_.Extension -in @('.gml', '.yy', '.yyp', '.md', '.json', '.resource_order')
        }
)

foreach ($file in $textFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    Assert-Condition ($content -notmatch '(?m)^(<<<<<<< .+|=======|>>>>>>> .+)$') "Conflict marker found: $($file.FullName)"
}

$readme = Get-Content -LiteralPath (Join-Path $repository 'README.md') -Raw
$uimanager = Get-Content -LiteralPath (Join-Path $projectRoot 'scripts/uimanager/uimanager.gml') -Raw
$uiinit = Get-Content -LiteralPath (Join-Path $projectRoot 'scripts/uiinit/uiinit.gml') -Raw
$miniDraw = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_mini/Draw_64.gml') -Raw
$recovery = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_system/Other_4.gml') -Raw
$portraitLoaded = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_system/Other_60.gml') -Raw
$androidGallery = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_system/Other_70.gml') -Raw
$stackDraw = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_stacker/Draw_75.gml') -Raw
$updateCheck = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_updatechecker/Create_0.gml') -Raw
$manifestRaw = Get-Content -LiteralPath (Join-Path $repository 'SOUP') -Raw
try {
    $strictManifest = [Text.Json.JsonDocument]::Parse($manifestRaw)
    $strictManifest.Dispose()
}
catch {
    throw 'SOUP manifest is not strict JSON'
}
$manifest = $manifestRaw | ConvertFrom-Json

$neutralityExclusions = @(
    [IO.Path]::GetFullPath((Join-Path $projectRoot 'scripts/get_emojis/get_emojis.gml')),
    [IO.Path]::GetFullPath((Join-Path $projectRoot 'scripts/emobble_get_emoji/emobble_get_emoji.gml')),
    [IO.Path]::GetFullPath((Join-Path $projectRoot 'extensions/WebView'))
)
$editorialIdentityPattern = '(?i)\b(LGBTQ?\+?|pride|lesbian|gay|bisexual|queer|transgender|non[ -]?binary|same[ -]?sex)\b'
$editorialIdentityMatches = @(
    foreach ($file in $textFiles) {
        $fullPath = [IO.Path]::GetFullPath($file.FullName)
        $excluded = $false
        foreach ($excludedPath in $neutralityExclusions) {
            if ($fullPath -eq $excludedPath -or $fullPath.StartsWith("$excludedPath\", [StringComparison]::OrdinalIgnoreCase)) {
                $excluded = $true
                break
            }
        }
        if (-not $excluded -and (Get-Content -LiteralPath $fullPath -Raw) -match $editorialIdentityPattern) {
            $fullPath
        }
    }
)

Assert-Condition ($readme -notmatch 'ath3jh\.png|9l8b2v\.png|6kttry\.png|tuckng\.png|So%20Soupy') 'Decorative soup/flag header imagery returned to README.md'
Assert-Condition ($editorialIdentityMatches.Count -eq 0) "Project-owned editorial identity reference found outside Unicode/vendor catalogs: $($editorialIdentityMatches -join ', ')"
Assert-Condition ($uimanager -notmatch 'keyboard_check\(vk_control\).*ord\("S"\).*soupy_context_clear') 'Ctrl+S still clears dialogue text'
Assert-Condition ($uiinit -notmatch 'Clear All.*SetShortcut\("Ctrl\+S"\)') 'Clear All still advertises Ctrl+S'
Assert-Condition (([regex]::Matches($uimanager, 'function soupy_save_last_typed\(')).Count -eq 1) 'Recovery writer must have exactly one definition'
Assert-Condition (([regex]::Matches($uimanager, 'soupy_save_last_typed\(dial_text\)')).Count -eq 2) 'Apply and undo must both update recovery'
Assert-Condition ($uimanager -match 'buffer_write\(lasttyped, buffer_text, text_\)') 'Recovery writer is not using the UTF-8 buffer path'
Assert-Condition ($uiinit -notmatch 'dial_face_alpha_orig = SYSTEMUI\.dial_face_alpha;\s*soup_checkout\("dataimage", false, true\)\.angle') 'Opacity preview still writes image angle'
Assert-Condition ($miniDraw -match 'hh_ = sprite_get_height\(face\)') 'Mini-speech height regression detected'
Assert-Condition ($recovery -match 'buffer_read\(lasttyped, buffer_text\)') 'Recovery no longer reads complete multiline text'
Assert-Condition ($recovery.IndexOf('file_exists(LAST_SAVED)', [StringComparison]::Ordinal) -lt $recovery.IndexOf('file_exists(errname)', [StringComparison]::Ordinal)) 'Recovery is conditional on an error log again'
Assert-Condition ($portraitLoaded -match 'if \( max_dimension_ > 70 \)[\s\S]{0,200}140/ max_dimension_' -and $portraitLoaded -notmatch 'min\(1, 70/ max_dimension_\)') 'Portrait fitting no longer preserves the default 2x size for normal faces'
Assert-Condition ($androidGallery -notmatch 'if \( type == "face" \)[\s\S]{0,500}MobileUtils_Image_Resize') 'Android import resizes a complete strip before splitting it into frames'
Assert-Condition ($stackDraw -notmatch 'surface_create\(sprW,') 'Stack surface is created with the old narrow width'
Assert-Condition ($stackDraw -match 'surface_get_width\(soupstack_surf\) != soupstack_width') 'Stack surface resize guard is missing'
Assert-Condition ($updateCheck -match 'cmdr-chara/UTDR-SoupGen') 'Update checker does not target the fork'
Assert-Condition ($manifest.game_version -eq '1.6.8') 'SOUP manifest version is not 1.6.8'
Assert-Condition ($uimanager -match '#macro GAME_VERSION "1\.6\.8"') 'GAME_VERSION does not match the SOUP manifest'

& git -C $repository diff --check
if ($LASTEXITCODE -ne 0) {
    throw 'git diff --check failed'
}

$remotes = & git -C $repository remote -v
if ($LASTEXITCODE -ne 0) {
    throw 'Could not read Git remotes'
}
Assert-Condition (($remotes -join "`n") -match 'origin\s+https://github\.com/cmdr-chara/UTDR-SoupGen\.git') 'origin does not point to the fork'
Assert-Condition (($remotes -join "`n") -match 'upstream\s+https://github\.com/SoupTaels/UTDR-SoupGen\.git') 'upstream does not point to SoupTaels'

[pscustomobject]@{
    JsonFiles = $jsonFiles.Count
    Resources = $project.resources.Count
    IncludedFiles = $project.IncludedFiles.Count
    Rooms = $project.RoomOrderNodes.Count
    Version = $manifest.game_version
    Status = 'PASS'
} | Format-List
