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
$windowsWorkflowPath = Join-Path $repository '.github/workflows/build-windows.yml'

Assert-Condition (Test-Path -LiteralPath $projectPath -PathType Leaf) "GameMaker project not found: $projectPath"
Assert-Condition (Test-Path -LiteralPath $windowsWorkflowPath -PathType Leaf) "Windows GitHub Actions workflow not found: $windowsWorkflowPath"

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
    Assert-Condition ($content -notmatch '(?m)^(<<<<<<< .+|=======|>>>>>>> .+)\r?$') "Conflict marker found: $($file.FullName)"
}

$readme = Get-Content -LiteralPath (Join-Path $repository 'README.md') -Raw
$forkChangelog = Get-Content -LiteralPath (Join-Path $repository 'FORK_CHANGELOG.md') -Raw
$windowsWorkflow = Get-Content -LiteralPath $windowsWorkflowPath -Raw
$uimanager = Get-Content -LiteralPath (Join-Path $projectRoot 'scripts/uimanager/uimanager.gml') -Raw
$uiinit = Get-Content -LiteralPath (Join-Path $projectRoot 'scripts/uiinit/uiinit.gml') -Raw
$systemCreate = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_system/Create_0.gml') -Raw
$gifDraw = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_system/Draw_75.gml') -Raw
$miniDraw = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_mini/Draw_64.gml') -Raw
$recovery = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_system/Other_4.gml') -Raw
$portraitLoaded = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_system/Other_60.gml') -Raw
$androidGallery = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_system/Other_70.gml') -Raw
$zipAsync = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_system/Other_72.gml') -Raw
$zipDrop = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_system/Other_75.gml') -Raw
$zipHelpers = Get-Content -LiteralPath (Join-Path $projectRoot 'scripts/uiexternals/uiexternals.gml') -Raw
$stackDraw = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_stacker/Draw_75.gml') -Raw
$updateCheck = Get-Content -LiteralPath (Join-Path $projectRoot 'objects/obj_updatechecker/Create_0.gml') -Raw
$windowsOptions = Get-Content -LiteralPath (Join-Path $projectRoot 'options/windows/options_windows.yy') -Raw | ConvertFrom-Json
$androidOptions = Get-Content -LiteralPath (Join-Path $projectRoot 'options/android/options_android.yy') -Raw | ConvertFrom-Json
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
Assert-Condition ($uimanager -match '#macro LAST_SAVED "latest_soupy_last_typed\.soupy"' -and $uimanager -match '#macro LAST_SAVED_BAK "latest_soupy_last_typed\.bak\.soupy"') 'Recovery journal slots are not relative save-area paths'
Assert-Condition ($uimanager -match '#macro PREF_SOUP "soupy_preferences\.soupy"' -and $uimanager -match '#macro PREF_SOUP_BAK "soupy_preferences\.bak\.soupy"') 'Preference journal slots are not relative save-area paths'
Assert-Condition ($uimanager -match '#macro SOUPY_STORE_MARKER "@@SOUPY_STORE_V1@@\\n"') 'Storage journal marker is missing'
Assert-Condition ($uimanager -match 'checksum_ = md5_string_utf8\(\$"\{kind_\}\\n\{generation_\}\\n\{payload_\}"\)' -and $uimanager -match 'json_parse\(json_, undefined, true\)') 'Storage slots are not checksum-validating kind, generation, and payload with safe JSON parsing'
Assert-Condition ($uimanager -match 'target_ = !is_undefined\(previous_\).*previous_\.path == primary_ \? backup_ : primary_' -and $uimanager -match 'soupy_store_read_slot\(target_, kind_\)') 'Storage writer does not alternate and verify the inactive journal slot'
Assert-Condition ($uimanager -match 'buffer_write\(buffer_, buffer_text, encoded_\)' -and $uimanager -match 'buffer_save\(buffer_, target_\)') 'Storage journal writer is not using a UTF-8 buffer'
Assert-Condition ($uimanager -notmatch 'function soupy_store_read_file\(path_\) \{\s*if \( !file_exists\(path_\) \)') 'Storage reads are incorrectly gated by the native file_exists extension instead of the GameMaker save area'
Assert-Condition ($uimanager -match 'raw_primary_ = soupy_store_validate_legacy_payload' -and $uimanager -match 'raw_backup_ = soupy_store_validate_legacy_payload') 'Relative pre-journal files are not migrated on browser and sandboxed targets'
Assert-Condition ($uimanager -match 'soupy_store_write\(backup_, primary_, kind_, legacy_\)') 'Legacy migration does not seed the fallback slot first'
Assert-Condition ($uimanager -match 'is_wasm\(\) \|\| os_browser != browser_not_a_browser' -and $uimanager -match 'return executable_get_directory\(\) \+ filename_') 'Legacy storage migration is not guarded for browser targets'
Assert-Condition ($systemCreate -match 'soupy_store_payload\(PREF_SOUP, PREF_SOUP_BAK, "preferences"' -and $systemCreate -match 'soupy_store_write\(PREF_SOUP, PREF_SOUP_BAK, "preferences"') 'Preferences do not use the verified two-slot journal'
Assert-Condition ($uiinit -notmatch 'dial_face_alpha_orig = SYSTEMUI\.dial_face_alpha;\s*soup_checkout\("dataimage", false, true\)\.angle') 'Opacity preview still writes image angle'
Assert-Condition ($miniDraw -match 'hh_ = sprite_get_height\(face\)') 'Mini-speech height regression detected'
Assert-Condition ($recovery -match 'soupy_restore_last_typed\(\);') 'Room-start recovery no longer restores the newest journal payload'
Assert-Condition ($recovery.IndexOf('soupy_restore_last_typed();', [StringComparison]::Ordinal) -lt $recovery.IndexOf('file_exists(errname)', [StringComparison]::Ordinal)) 'Recovery is conditional on an error log again'
Assert-Condition (([regex]::Matches($androidGallery, 'soupy_restore_last_typed\(\)')).Count -eq 2) 'Android SAF migration no longer retries recovery after directory selection'
Assert-Condition ($portraitLoaded -match 'if \( max_dimension_ > 70 \)[\s\S]{0,200}140/ max_dimension_' -and $portraitLoaded -notmatch 'min\(1, 70/ max_dimension_\)') 'Portrait fitting no longer preserves the default 2x size for normal faces'
Assert-Condition ($androidGallery -notmatch 'if \( type == "face" \)[\s\S]{0,500}MobileUtils_Image_Resize') 'Android import resizes a complete strip before splitting it into frames'
Assert-Condition ($stackDraw -notmatch 'surface_create\(sprW,') 'Stack surface is created with the old narrow width'
Assert-Condition ($stackDraw -match 'surface_get_width\(soupstack_surf\) != soupstack_width') 'Stack surface resize guard is missing'

Assert-Condition ($gifDraw -notmatch 'buffer_exists\(record\.id_\)|gif_save_buffer\(|soupytemp\.gif') 'GIF handles are still treated as buffers or discarded through an unbounded buffer/fixed filename'
Assert-Condition ($gifDraw -match 'record\.id_ = gif_open\(' -and $gifDraw -match 'record\.id_ == -1') 'GIF initialization failure is not checked'
Assert-Condition ($gifDraw -match 'var add_status = gif_add_surface\(' -and $gifDraw -match 'add_status != 0') 'GIF frame encoder failures are not checked'
Assert-Condition ($gifDraw -match 'var save_status = gif_save\(' -and $gifDraw -match 'save_status != 0') 'GIF finalization failures are not checked'
Assert-Condition ($gifDraw -match 'fpath_staging = .*\.part' -and $gifDraw -match 'file_rename\(fpath_staging, fpath_final\)') 'GIF output is not staged before its final rename'
Assert-Condition ($gifDraw -match '128 \* 1024 \* 1024' -and $gifDraw -match '192 \* 1024 \* 1024' -and $gifDraw -match '384 \* 1024 \* 1024' -and $gifDraw -match 'record\.framesmax > record\.frames_limit') 'Platform-aware GIF memory/frame budgets are missing'
Assert-Condition ($gifDraw -match 'os_browser != browser_not_a_browser \|\| is_wasm\(\)') 'GIF web budget does not cover browser and WASM builds'
Assert-Condition ($gifDraw -match 'record\.frames_total mod 3 == 2 \) \? 1 : 2') 'GIF timing no longer uses the exact 2/2/1-centisecond 60 FPS cadence'
Assert-Condition ($gifDraw -match 'record\.type == 1 && record\.frames_total == 0') 'Typewriter GIF can regress to a zero-frame export'

Assert-Condition (([regex]::Matches($zipHelpers, 'zip_unzip_async\(')).Count -eq 1) 'ZIP extraction must have exactly one centralized call site'
Assert-Condition ($zipHelpers.IndexOf('soupy_zip_preflight(snapshot_)', [StringComparison]::Ordinal) -lt $zipHelpers.IndexOf('zip_unzip_async(snapshot_, extract_)', [StringComparison]::Ordinal)) 'ZIP snapshot is not preflighted before extraction'
Assert-Condition ($zipHelpers -match '\$06054B50' -and $zipHelpers -match '\$02014B50' -and $zipHelpers -match '\$04034B50') 'ZIP preflight no longer validates EOCD, central, and local headers'
Assert-Condition ($zipHelpers -match 'buffer_crc32\(' -and $zipHelpers -match 'IHDR' -and $zipAsync -match 'SOUPY_ZIP_MAX_TOTAL_PIXELS') 'ZIP imports no longer verify CRC, PNG IHDR, and decoded-pixel budgets before sprite loading'
Assert-Condition ($zipHelpers -match 'function soupy_zip_collect_files_inner\(' -and $zipAsync -notmatch '\bgumshoe\(') 'ZIP staging traversal can follow directory links again'
Assert-Condition ($zipHelpers -match 'symlink_exists\(path_\)' -and $zipAsync -match 'soupy_zip_path_within\(faces_root_canonical_') 'ZIP source/destination confinement checks are missing'
Assert-Condition ($zipAsync.IndexOf('soup_checkout("bulkload", false, true)', [StringComparison]::Ordinal) -lt $zipAsync.IndexOf('soup_checkout("bulkload", true, true)', [StringComparison]::Ordinal)) 'ZIP async state is consumed before the request ID is matched'
Assert-Condition ($zipAsync.IndexOf('array_push(part_paths_, copy_item_.part_path)', [StringComparison]::Ordinal) -lt $zipAsync.IndexOf('file_copy(copy_item_.source, copy_item_.part_path)', [StringComparison]::Ordinal)) 'ZIP rollback does not track partial copies before writing them'
Assert-Condition ($zipAsync -match 'finally \{' -and $zipAsync -match 'scribble_external_sprite_remove' -and $zipAsync -match 'file_delete\(committed_path_\)' -and $zipAsync -match 'file_delete\(part_path_\)') 'ZIP transaction rollback is incomplete'
Assert-Condition ($zipAsync -match 'planned_aliases_' -and $zipAsync -match 'Face aliases collide after normalization') 'ZIP preflight does not reject aliases that collide across planned entries'
Assert-Condition (([regex]::Matches($zipHelpers, 'if \( soupy_zip_begin\(')).Count -eq 1 -and ([regex]::Matches($zipDrop, 'if \( soupy_zip_begin\(')).Count -eq 1) 'ZIP picker and drag-drop paths do not share the same importer'
Assert-Condition ($updateCheck -match 'cmdr-chara/UTDR-SoupGen') 'Update checker does not target the fork'
Assert-Condition ($manifest.game_version -eq '1.6.9') 'SOUP manifest version is not 1.6.9'
Assert-Condition ($uimanager -match '#macro GAME_VERSION "1\.6\.9"') 'GAME_VERSION does not match the SOUP manifest'
Assert-Condition ($windowsOptions.option_windows_version -eq '1.6.9.0') 'Windows version does not match release 1.6.9'
Assert-Condition ($androidOptions.option_android_version -eq '1.6.9.0') 'Android version does not match release 1.6.9'
Assert-Condition ($forkChangelog -match '(?m)^## 1\.6\.9\r?$') 'Fork changelog has no 1.6.9 entry'
Assert-Condition ($windowsWorkflow -match 'secrets\.ACCESS_KEY' -and $windowsWorkflow -match 'bscotch/igor-setup@[0-9a-f]{40}' -and $windowsWorkflow -match 'bscotch/igor-build@[0-9a-f]{40}') 'Windows workflow is missing GameMaker authentication or immutable Igor action pins'
Assert-Condition ($windowsWorkflow -match 'GMLive\.fallback\.gml' -and $windowsWorkflow -match 'GMLive\.gml' -and $windowsWorkflow -match 'yyc: "false"') 'Windows workflow does not prepare the headless GMLive fallback or select the VM compiler'
Assert-Condition ($windowsWorkflow -match 'actions/upload-artifact@[0-9a-f]{40}' -and $windowsWorkflow -match 'UTDR-SoupGen-Enhanced-Windows') 'Windows workflow does not publish a pinned build artifact'

& git -C $repository diff --check
if ($LASTEXITCODE -ne 0) {
    throw 'git diff --check failed'
}

$remotes = & git -C $repository remote -v
if ($LASTEXITCODE -ne 0) {
    throw 'Could not read Git remotes'
}
$remoteText = $remotes -join "`n"
Assert-Condition ($remoteText -match 'origin\s+https://github\.com/cmdr-chara/UTDR-SoupGen(?:\.git)?(?:\s|$)') 'origin does not point to the fork'

if ($env:GITHUB_ACTIONS -eq 'true') {
    Assert-Condition ([string]::Equals($env:GITHUB_REPOSITORY, 'cmdr-chara/UTDR-SoupGen', [StringComparison]::OrdinalIgnoreCase)) 'GitHub Actions is running outside the fork repository'
}
else {
    Assert-Condition ($remoteText -match 'upstream\s+https://github\.com/SoupTaels/UTDR-SoupGen(?:\.git)?(?:\s|$)') 'upstream does not point to SoupTaels'
}

[pscustomobject]@{
    JsonFiles = $jsonFiles.Count
    Resources = $project.resources.Count
    IncludedFiles = $project.IncludedFiles.Count
    Rooms = $project.RoomOrderNodes.Count
    Version = $manifest.game_version
    Status = 'PASS'
} | Format-List
