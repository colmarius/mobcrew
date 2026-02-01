# Progress: GitHub Releases for MobCrew

## Tasks 1-6: Complete GitHub Release Automation

**Thread**: https://ampcode.com/threads/T-019c1af0-e92b-701c-bd97-b65ed6bb4414
**Status**: completed
**Iteration**: 1

### Changes

- `scripts/build-release.sh` - Created release build script with version injection
- `scripts/create-dmg.sh` - Created DMG packaging script using npx create-dmg
- `scripts/release.sh` - Created main release script orchestrating build → DMG → GitHub
- `README.md` - Added Download section and Releasing section with prerequisites
- `docs/RELEASING.md` - Created comprehensive release documentation

### Commands Run

- `./scripts/build-release.sh 0.1.0` ✓ (built app with version 0.1.0, build 65)
- `./scripts/create-dmg.sh 0.1.0` ✓ (created MobCrew-0.1.0.dmg)
- `xcodebuild build` ✓
- `xcodebuild test` ✓

### Learnings

- Project uses `GENERATE_INFOPLIST_FILE = YES` with `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` build settings
- Version injection works via xcodebuild command line overrides, no PlistBuddy needed
- `create-dmg` npm package uses `--no-code-sign` flag (not `--skip-jenkins`)

### Next

- Move plan to completed/
- Create first release with `./scripts/release.sh 0.1.0`

---
