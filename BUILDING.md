# Building UTDR SoupGen Enhanced

## GitHub Actions Windows build

The repository workflow `.github/workflows/build-windows.yml` validates the project, installs the GameMaker runtime selected from the `.yyp` metadata, builds a Windows VM package with Igor, and uploads the result as a GitHub Actions artifact.

Before the first build:

1. Generate a GameMaker Access Key from <https://gamemaker.io/en/account/access-keys>. The account must have the license required for the Windows export.
2. Open the GitHub repository and go to **Settings > Secrets and variables > Actions**.
3. Add the access key as a repository secret named `ACCESS_KEY`. Do not add the key to a file, commit, issue, or workflow log.
4. Open **Actions > Build Windows > Run workflow**, select the desired branch, and start the build.

Successful runs publish the `UTDR-SoupGen-Enhanced-Windows` artifact for 14 days. The workflow also retains the Igor compiler log when GameMaker produces one.

The Windows workflow deliberately uses the VM compiler for the first repeatable CI target. Android builds require separate keystore, SDK, signing, and platform validation, so they are not enabled by this workflow.

## Local static validation

Without a GameMaker installation, the repository integrity checks can still be run with:

```powershell
pwsh -NoLogo -NoProfile -NonInteractive -File .\tools\validate_fork.ps1
```
