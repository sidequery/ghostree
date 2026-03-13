# Agent Development Guide

A file for [guiding coding agents](https://agents.md/).

## Commands

- **Build:** `zig build`
  - If you're on macOS and don't need to build the macOS app, use
    `-Demit-macos-app=false` to skip building the app bundle and speed up
    compilation.
- **Test (Zig):** `zig build test`
  - Prefer to run targeted tests with `-Dtest-filter` because the full
    test suite is slow to run.
- **Test filter (Zig)**: `zig build test -Dtest-filter=<test name>`
- **Formatting (Zig)**: `zig fmt .`
- **Formatting (Swift)**: `swiftlint lint --fix`
- **Formatting (other)**: `prettier -w .`

## Directory Structure

- Shared Zig core: `src/`
- macOS app: `macos/`
- GTK (Linux and FreeBSD) app: `src/apprt/gtk`

## macOS App

- Do not use `xcodebuild`
- Use `zig build` to build the macOS app and any shared Zig code
- Use `zig build run` to build and run the macOS app
- Run Xcode tests using `zig build test`

## Git workflow

- Don’t rebase a branch after it’s merged.
- Sync upstream into `upstream-main` via `--ff-only`, then merge `upstream-main` into `main`.
- **NEVER squash upstream commits.** Always use a real merge (`git merge`, not `git merge --squash`) when merging `upstream-main` into `main`. Squashing severs the git ancestry chain, which permanently inflates GitHub’s "behind" count and forces every future merge to re-resolve conflicts that git would otherwise auto-resolve. This has bitten us before and must not happen again.
- Avoid force-pushing `main`; if needed, push a `legacy/...` backup ref first.

## Ghostree Project Context

- Remotes:
  `origin` = `sidequery/ghostree` (`git@github.com:sidequery/ghostree.git`)
  `upstream` = `ghostty-org/ghostty` (`https://github.com/ghostty-org/ghostty.git`)
- Branch intent:
  `main` = Ghostree customizations.
  `upstream-main` = mirror of `upstream/main` (fast-forward only).
- Never merge `upstream/main` directly into `main`; update `upstream-main` first, then merge `upstream-main` into `main`.
- Versioning:
  Ghostree release version comes from `build.zig.zon` (`.version`).
  Keep app target marketing versions aligned in `macos/Ghostty.xcodeproj/project.pbxproj`.
- Release naming:
  use `Ghostree v0.X.Y`.
- Bundle identifier must stay `dev.sidequery.Ghostree` (not `com.mitchellh.ghostty`).

## Releasing

CI does NOT work for releases (upstream Namespace Cloud runners). All releases are built locally.

### Steps

1. **Bump version** in both `build.zig.zon` (`.version`) and all `MARKETING_VERSION = 0.X.Y` entries in `macos/Ghostty.xcodeproj/project.pbxproj`.
2. **Commit** the version bump, push to `main`.
3. **Tag and push**: `git tag v0.X.Y && git push origin v0.X.Y`
4. **Create GitHub release**: `gh release create v0.X.Y --repo sidequery/ghostree --title "Ghostree v0.X.Y" --notes "..."`
5. **Build locally**: `bash scripts/release_local.sh` (builds, signs, notarizes, staples the DMG). Requires `scripts/.env.release.local` with `SIGN_IDENTITY` and `NOTARYTOOL_PROFILE`.
6. **Upload DMG** to the GitHub release: `gh release upload v0.X.Y macos/build/ReleaseLocal/Ghostree.dmg --repo sidequery/ghostree`
7. **Get asset ID**: `gh api repos/sidequery/ghostree/releases/tags/v0.X.Y --jq '.assets[] | select(.name == "Ghostree.dmg") | .id'`
8. **Get sha256**: `shasum -a 256 macos/build/ReleaseLocal/Ghostree.dmg | awk '{print $1}'`
9. **Update homebrew cask** at `../homebrew-tap-sidequery/Casks/ghostree.rb`: set `version`, `sha256`, and `asset_id` to the new values.
10. **Commit and push** the homebrew tap repo.

### Cancel stuck CI runs

The release-tag workflow will queue forever on upstream's runners. Cancel them:
`gh run cancel <run_id> --repo sidequery/ghostree`

## Issue and PR Guidelines

- Never create an issue.
- NEVER EVER EVER EVER EVER EVER open a PR against `ghostty-org/ghostty` (upstream), under any circumstances.
- If a PR is explicitly requested, it must target `sidequery/ghostree` only, never upstream.
- Before creating any PR, verify: `gh repo set-default --view` must show `sidequery/ghostree`.
  If it does not, run `gh repo set-default sidequery/ghostree` first.
- Always use `--repo sidequery/ghostree` flag with `gh pr create` as a safeguard.
- NEVER use `--repo ghostty-org/ghostty` or any upstream reference in `gh pr` commands.
