# UTDR SoupGen agent instructions

## Fork and resource contracts

- Preserve the offline dialogue/textbox workflow, editable scenes, custom resources, export behavior, and cancellation. Do not introduce an online dependency into ordinary generation as a maintenance shortcut.
- Keep GameMaker project/resource references coherent inside `UTDR Textbox Gen`. Preserve resource identities and dependency metadata; do not repair generated build output instead of project source.
- Select the runtime from the actual `.yyp` metadata and restore the declared official prefab dependencies. Do not replace a missing runtime with an arbitrary version to make a build start.
- Preserve SoupTaels' upstream attribution and distinguish the upstream no-generative-AI statement from this fork's disclosed AI-assisted maintenance. Do not rewrite provenance claims as applying to both.
- Never commit GameMaker access keys, Android keystores, signing material, or private custom resources.

## Guidance and verification

Use [BUILDING.md](BUILDING.md) for the Windows VM build and local PowerShell integrity check, and [FORK_CHANGELOG.md](FORK_CHANGELOG.md) for fork-specific changes and their evidence. Quote paths containing spaces when invoking tools.

Without GameMaker, run the documented `tools/validate_fork.ps1` integrity check and report that boundary. A static pass is not an Igor build, a working export, or Android/Linux/macOS runtime validation. Android signing and export prerequisites remain separate from the Windows workflow.

Completion requires affected project/resource contracts checked, applicable build/export behavior exercised, and honest platform limits. Update fork-facing documentation when behavior changes; do not infer successful builds from queued workflows or missing-credential runs.
