# Phase 3: Release and distribution hardening

Make MobCrew's documented/scripted release path reproducible, inspectable, target-bound, and safe to
resume. Harden the current non-Developer-ID path first; Developer ID signing/notarization is a
conditional extension after an owner decision and approved credential model.

## Phase-boundary refinement (2026-08-08)

- Phase 1's released-artifact signatures, architectures, notarization/stapling, Gatekeeper/TCC, and
  clean-Mac behavior remain **unverified**. Local tooling will record a newly built artifact's facts,
  but this phase will not infer the `v0.2.0` state, enforce an architecture set, or strengthen public
  claims without a real quarantined macOS qualification run.
- Use explicit `check`, `prepare`, `create-draft`, `status`, `verify-draft`, and `publish` operations.
  Draft metadata creation and asset upload form a resumable state machine: matching partial state is
  resumed without clobbering, while conflicting state aborts without delete/retag recovery.
- Strict local manifest, remote-evidence, and qualification schemas form a hash chain over the exact
  target, artifact, verifier evidence, numeric GitHub release ID, asset, release notes, and manual
  qualification. Files are parsed as data and never sourced or evaluated.
- Publication must freshly re-download and hash the asset, recheck release ID/draft/tag/target/title/
  notes/asset state and remote-tag absence, require an interactive exact-tag confirmation, patch the
  recorded numeric release ID, and verify the resulting tag. A mismatch stops for manual recovery;
  no automatic rollback is added.
- Pin Node 24.19.0 and lock `create-dmg` 8.1.0's dependency graph with npm metadata. This is
  reproducible release tooling, not a landing-page framework or frontend build system. The scripts
  run packaging from a controlled repository directory and do not promise byte-identical DMGs across
  macOS versions.
- Production scripts remain compatible with macOS Bash 3.2 and BSD tools. Linux-safe tests use a
  local temporary git remote plus mocked `gh`, Node, Xcode, and Swift boundaries; they must never
  contact GitHub or mutate a real release.
- Tasks 3.5 and 3.6 remain blocked on an explicit owner decision and credentials. Task 3.4 can gain
  tooling/documentation but stays unchecked until real macOS trust/Gatekeeper evidence exists.

## Goals

- Prevent releases from the wrong tree, branch, version, or untested artifact.
- Make draft testing and publication resumable instead of destructive.
- Verify bundle version, architecture, DMG contents, app/DMG signature states, and checksum locally
  before any remote release operation.
- Prepare qualification and publication operations without performing shared-state actions unless
  separately authorized.
- Keep Developer ID signing/notarization from blocking useful non-credential release hardening.

## Tasks

- [x] **Task 3.1: Define and enforce safe release preflight invariants**
  - Scope: `scripts/release.sh`, `scripts/build-release.sh`, `docs/RELEASING.md`
  - Depends on: Phase 1 release facts complete
  - Acceptance:
    - Version input is validated and normalized consistently with tag/asset naming.
    - Release refuses a dirty worktree, unexpected branch/upstream state, or an existing release/tag
      without a clear non-destructive recovery path.
    - The verified full commit SHA is bound to release/tag creation using `gh release create --target`
      or an exact pre-created remote tag verified with `--verify-tag`; printing the SHA alone is not
      sufficient.
    - Required Xcode, Swift, `gh`, Node, repository permissions, and complete git history/build-number
      assumptions are checked before a long build.
    - Tests complete successfully before remote release state is created.
    - Preflight failures leave existing local artifacts and remote releases untouched.
  - Notes: Do not add bypass flags for invariants that should always hold. A script can harden only
    the documented path; it cannot prevent maintainers from using GitHub directly.

- [ ] (macos-verify) **Task 3.2: Build and verify the local release artifact before upload**
  - Scope: `scripts/build-release.sh`, `scripts/create-dmg.sh`, `.github/workflows/ci.yml`,
    `docs/RELEASING.md`
  - Depends on: Task 3.1
  - Acceptance:
    - Bundle marketing version/build number match the requested release and are recorded.
    - `lipo -archs` output is recorded for the qualification matrix. No architecture set is enforced
      until support is documented from artifact evidence and an explicit product decision.
    - DMG is mounted in a temporary location; app presence, bundle identity, executable, and
      Applications install affordance are checked before any upload.
    - App bundle and outer DMG signatures are inspected and reported separately; structural signing,
      Developer ID identity, notarization/stapling, and Gatekeeper assessment are not conflated.
    - Existing output is replaced atomically only after a new DMG passes verification.
    - Local SHA-256 is generated and recorded for later comparison with the uploaded draft asset.
    - CI and release scripts use the same material artifact checks where practical.
  - Notes: This task is entirely local/non-publishing. Structural `codesign --verify` is not evidence
    of Developer ID trust or notarization. The scripts and CI integration are implemented; keep this
    unchecked until the pinned macOS runner actually builds, mounts, inspects, and records an
    artifact with them.

- [x] **Task 3.3: Implement resumable, separately authorized release operations**
  - Scope: `scripts/release.sh`, `docs/RELEASING.md`
  - Depends on: Task 3.1, Task 3.2
  - Acceptance:
    - Local preparation, draft metadata creation/asset upload, status inspection, uploaded-digest
      verification, and publication of the existing draft are distinct operations.
    - Draft creation accepts only the locally verified artifact and binds to the Task 3.1 target SHA.
    - After an authorized upload, the GitHub asset digest or a downloaded draft asset is compared
      with the recorded local SHA-256 before qualification.
    - Rerunning after a partial failure reports existing remote state and a safe next operation rather
      than deleting or duplicating tags/releases.
    - Publish/delete operations never run implicitly; each requires explicit invocation and user
      authority.
    - Publication revalidates the live numeric release ID, draft/tag/target, title/body hash, exact
      asset set/identity/size/digest, and remote-tag absence immediately before changing state, then
      verifies the resulting tag target without automatic rollback.
  - Notes: Implement and test operation boundaries without creating a real draft. Prefer publishing
    the tested draft over rebuilding a supposedly identical artifact.

- [ ] (manual-verify) **Task 3.4: Harden and document the default non-Developer-ID path**
  - Scope: release scripts/checks, `docs/RELEASING.md`, `TESTING.md`, public trust/install wording
  - Depends on: Task 3.2; Phase 1 Task 1.7 findings or its explicitly recorded unverified state
  - Acceptance:
    - Tooling records the actual app-bundle and outer-DMG signature states and explicitly reports
      absence/presence of Developer ID, notarization, and stapling.
    - Public and maintainer docs use the observed terms rather than a generic “unsigned” label.
    - Qualification guidance records Gatekeeper/TCC behavior for the downloaded/quarantined draft
      and keeps unobserved behavior marked unverified.
    - This path requires no Apple signing credentials and remains usable if Developer ID work is not
      approved.
  - Notes: This is the default plan path, not a degraded fallback. The inspection tooling and
    qualified documentation are implemented, but actual app/DMG states and quarantined Gatekeeper
    behavior remain unverified in the Linux orb.

- [ ] (blocked) **Task 3.5: Decide whether and where to pursue Developer ID distribution**
  - Scope: owner decision recorded in this work item or a durable decision file
  - Depends on: Task 3.4
  - Acceptance:
    - Owner decides whether to pursue Developer ID signing/notarization.
    - If approved, the decision names the release execution environment and approved credential
      store/secret owner; CI signing is not assumed.
    - If deferred, Phase 3 can complete the non-Developer-ID hardening path without inventing
      credentials or weakening documentation.
  - Notes: Blocked on owner/credential context; it does not block Tasks 3.1-3.4 or Task 3.7.

- [ ] (blocked) **Task 3.6: Implement the approved signed/notarized extension**
  - Scope: Xcode Release settings/entitlements, release scripts, approved signing environment,
    `docs/RELEASING.md`, public install documentation
  - Depends on: Task 3.5 approved with credentials available
  - Acceptance:
    - App uses the approved Developer ID identity and hardened runtime without unintended entitlement
      changes.
    - Artifact is submitted with `notarytool`, accepted, stapled, and passes `codesign`, `spctl`, and
      stapler validation before it can enter an authorized draft operation.
    - Credentials remain only in the approved keychain/secret infrastructure and never appear in
      logs, repository files, or artifacts.
    - Accessibility/TCC, Notifications, launch at login, and sandbox behavior are revalidated after
      signing-identity changes.
  - Notes: Local keychain and CI signing are different operating models; implement only the approved
    one.

- [x] **Task 3.7: Create the clean-Mac qualification and release-evidence contract**
  - Scope: `TESTING.md`, `docs/RELEASING.md`, work-item evidence template only if repeated use
    justifies it
  - Depends on: Task 3.3, Task 3.4; Task 3.6 only when the signed extension is selected
  - Acceptance:
    - Checklist starts from the downloaded draft asset and records target SHA, version, local/remote
      digest, app/DMG trust state, machine, macOS version, and architecture.
    - Install, Gatekeeper, first launch, Accessibility and Notifications allow/deny/recovery, launch
      at login, timer/rotation/breaks, persistence, and update from the previous release are covered.
    - Qualification uses the states `tested`, `unverified`, and `unsupported by explicit decision`;
      lack of a test machine never implies unsupported status.
    - A finite matrix is selected from artifact architectures plus owner-selected minimum/current
      macOS samples instead of promising every OS-by-architecture combination.
    - Release-note, latest-link, problem-notice, and non-destructive rollback requirements are named.
  - Notes: This task prepares the contract; creating a draft, qualifying it, or publishing it are
    separately authorized operational gates below.

## Implementation Notes

- Keep build, package, verify, upload-draft, qualify, and publish boundaries observable.
- Reuse the current scripts rather than replacing them with a release framework unless the existing
  structure cannot support safe retries.
- Prefer atomic local output and non-destructive remote-state detection.
- Treat signing identity changes as a permission/TCC regression risk, not only a packaging detail.

## Constraints / Decisions

- A signed/notarized path requires Apple Developer Program access and approved secure secrets.
- Non-Developer-ID distribution remains an explicit supported process only when actual app/DMG trust
  state and observed Gatekeeper behavior are documented accurately.
- Release publication and destructive GitHub operations require explicit approval.
- Architecture support must be derived from the built artifact and qualification evidence, not from
  marketing language or host assumptions.

## Acceptance Criteria

- A maintainer can stop and resume a release without recreating or deleting tested remote state.
- The documented/scripted path cannot create a draft from an untested, dirty, ambiguously versioned,
  or wrong-target build.
- Local artifact version, architecture, digest, DMG contents, and trust status are recorded before
  any separately authorized upload.
- Draft, qualification, and publish operations are explicit and can be resumed without destructive
  recovery.
- The qualification contract can prove or explicitly bound release support without treating missing
  machines as unsupported configurations.

## Verification

- Exercise every preflight failure mode in a temporary/non-publishing context and confirm no local
  known-good artifact or remote state is destroyed.
- Run the full unit suite and release build on the pinned Xcode/macOS environment.
- Inspect Info.plist versions, `lipo -archs`, mounted DMG contents, app/DMG signatures, notarization
  state, and SHA-256 locally.
- Test release-state detection, exact target binding, and create/status/publish command construction
  without changing real GitHub release state.
- If the signed extension is selected, run `codesign --verify --deep --strict`, inspect signing
  identity/entitlements, run `xcrun stapler validate`, and run `spctl --assess` on the artifact.
- Review the qualification contract against the public install/permission claims and confirm every
  required evidence field has one owner/source.

## Deployment / Migration

- **Gate A — Create draft:** after separate approval, upload the locally verified artifact with the
  exact target SHA, then compare the remote/downloaded digest to the local SHA-256.
- **Gate B — Qualify draft:** on approved macOS environments, download the draft and execute Task
  3.7's finite matrix; record `tested`, `unverified`, or explicitly `unsupported` results and block
  publication on release-critical failures.
- **Gate C — Publish:** after separate approval, publish the already qualified draft, verify release
  notes/latest links/tag target, and retain the evidence before work-item closeout.
- Task 3.5/3.6 are a conditional signing decision and extension. Without Apple credentials, finish
  and qualify the non-Developer-ID path rather than inventing or weakening secret handling.
- Draft creation/publication, tag changes, release deletion, secret configuration, and workflow
  infrastructure changes remain shared-state actions requiring separate approval.
- If a published release is defective, preserve evidence and prefer a visible warning/superseding
  release over silently deleting history; destructive rollback is a last resort requiring approval.
