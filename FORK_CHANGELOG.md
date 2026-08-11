# UTDR SoupGen Enhanced

This fork tracks [SoupTaels/UTDR-SoupGen](https://github.com/SoupTaels/UTDR-SoupGen) and preserves the original MIT license and credits. The first enhanced release is based on upstream commit `b395269e494a7c8c8d174a93982e878fd4b70738`.

## 1.6.9

- Replaced single-file recovery and preferences writes with two checksummed, generation-tagged journal slots in GameMaker's save area. The newest valid slot wins and older desktop or Android files are migrated without overwriting the only legacy copy.
- Added platform-aware GIF frame and memory budgets, explicit encoder error handling, exact frame accounting, staged final files, and bounded cancel cleanup. Typewriter exports now always contain an initial frame and use a 2/2/1-centisecond cadence for an exact 60 FPS average.
- Rebuilt bulk face ZIP import around a stable archive snapshot and a conservative preflight parser. Imports reject traversal, links, duplicate aliases, unsupported ZIP features, excessive compression, invalid CRCs, unsafe PNG dimensions, and decoded-pixel budget overflows before loading sprites.
- Made ZIP installation transactional for handled runtime failures: files are staged and verified before rename, then aliases and dictionaries are registered only after every file is committed. A failed import rolls back its files, sprites, aliases, dictionaries, and staging directory.
- Added a pinned GitHub Actions pipeline for an automated Windows VM build, including static validation, headless GMLive fallback preparation, Igor logs, and downloadable build artifacts.

Known boundaries: ZIP support intentionally accepts only a conservative ASCII, stored/deflate subset. The runtime rollback is exception-safe but not process-crash atomic across a multi-file commit, and GameMaker's native extractor still requires platform smoke testing.

## 1.6.8

- Removed the decorative soup-bowl images around the README title.
- Reserved `Ctrl+S` by removing the destructive Clear All shortcut. Clear All remains available in the context menu.
- Kept UTF-8 crash-recovery text synchronized with both apply and undo operations.
- Restored the saved Arbitrary Border preference on startup.
- Made canceled face, border, and font file pickers leave the current state unchanged.
- Corrected portrait opacity preview, rectangular mini-speech geometry, and oversized portrait aspect fitting without shrinking normal or animated-strip portraits.
- Improved stack-surface bounds and allocation behavior.
- Restored the dialogue page that was active before export.
- Corrected the temporary-upload error message to name the service actually in use.
- Assigned fork-specific update metadata, application GUID, Windows display name, and Android package identity.
- Kept project-owned branding and copy neutral while preserving standard Unicode emoji data and generic color-formatting effects.

## Verification

The repository includes static integrity checks for GameMaker resource JSON, referenced files, room order, conflict markers, fork-specific regressions, and Git whitespace errors. Run them with:

```powershell
pwsh -NoLogo -NoProfile -NonInteractive -File .\tools\validate_fork.ps1
```

A compatible GameMaker IDE and runtime are not installed in the current environment, so a Windows and Android runtime smoke test is still required before publishing binaries.

## Provenance

The upstream project states that no generative AI was used in its original creation. The maintenance changes in this fork were produced with AI assistance under user direction. No upstream art, audio, font, or other content was replaced by generated assets.
