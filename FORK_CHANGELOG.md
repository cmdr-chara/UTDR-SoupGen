# UTDR SoupGen Enhanced

This fork tracks [SoupTaels/UTDR-SoupGen](https://github.com/SoupTaels/UTDR-SoupGen) and preserves the original MIT license and credits. The first enhanced release is based on upstream commit `b395269e494a7c8c8d174a93982e878fd4b70738`.

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
