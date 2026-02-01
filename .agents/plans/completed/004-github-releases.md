# Plan: GitHub Releases for MobCrew

Add release automation for the MobCrew Mac app with scripts to build, package, and publish releases to GitHub.

**Reference**: `.agents/research/macos-github-releases.md`

---

## Tasks

- [x] **Task 1: Create release build script**
  - Scope: `scripts/build-release.sh`
  - Depends on: none
  - Acceptance:
    - Script builds MobCrew in Release configuration
    - Output goes to `build/Release/MobCrew.app`
    - Script is executable and documented
    - Build uses `CONFIGURATION_BUILD_DIR` for predictable output location
  - Notes: Use xcodebuild with `-configuration Release`

- [x] **Task 2: Create DMG packaging script**
  - Scope: `scripts/create-dmg.sh`
  - Depends on: Task 1
  - Acceptance:
    - Script creates DMG from built app using `npx create-dmg`
    - DMG named `MobCrew-<version>.dmg`
    - Supports `--no-code-sign` flag for unsigned builds
    - Script checks for required dependencies (Node.js)
  - Notes: Initially skip code signing; add later with Developer ID

- [x] **Task 3: Create GitHub release script**
  - Scope: `scripts/release.sh`
  - Depends on: Task 2
  - Acceptance:
    - Script accepts version argument (e.g., `./scripts/release.sh 1.0.0`)
    - Calls build and DMG scripts
    - Creates GitHub release with `gh release create`
    - Uploads DMG as release asset
    - Uses `--generate-notes` for automatic changelog
    - Validates `gh` CLI is authenticated
  - Notes: Main entry point for creating releases

- [x] **Task 4: Add version injection to build**
  - Scope: `scripts/build-release.sh`, Info.plist handling
  - Depends on: Task 1
  - Acceptance:
    - Version passed to build script updates `CFBundleShortVersionString`
    - Build number set via `git rev-list --count HEAD`
    - Version visible in app's About dialog
  - Notes: Use PlistBuddy to inject version into Info.plist

- [x] **Task 5: Update documentation**
  - Scope: `README.md`, `docs/index.html`
  - Depends on: Task 3
  - Acceptance:
    - README documents release process (`./scripts/release.sh <version>`)
    - README lists prerequisites (gh CLI, Node.js)
    - docs/index.html download link points to latest release
  - Notes: Keep docs simple; detailed process in research doc

- [x] **Task 6: Create release checklist document**
  - Scope: `docs/RELEASING.md`
  - Depends on: Task 3, Task 5
  - Acceptance:
    - Documents full release process step-by-step
    - Includes pre-release checklist (tests pass, version bumped)
    - Documents manual steps if any
    - Includes troubleshooting section
  - Notes: Reference for maintainers

---

## Future Enhancements (Not in This Plan)

1. **Code Signing** - Requires Apple Developer ID ($99/year)
2. **Notarization** - Requires code signing first
3. **GitHub Actions** - Automate releases on tag push
4. **Sparkle Auto-Update** - In-app update mechanism
5. **Changelog Generation** - Automated from conventional commits

---

## Manual Steps (after plan completion)

1. **Install prerequisites**:

   ```bash
   brew install gh node
   gh auth login
   ```

2. **Test the release flow locally**:

   ```bash
   ./scripts/release.sh 0.1.0 --draft
   ```

3. **Create first release**:

   ```bash
   ./scripts/release.sh 0.1.0
   ```
