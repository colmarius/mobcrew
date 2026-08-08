# Releasing MobCrew

The release path prepares, drafts, verifies, qualifies, and publishes the **same bytes**. Local
interlocks reduce mistakes; they are not proof that the operator has owner authority. Creating a
draft and publishing each require separate, explicit authorization. No script deletes, clobbers,
retags, or rolls back a release.

## Toolchain and preflight

Use a Mac with exactly Xcode 26.6 / Swift 6.3, `gh`, and Node 24.19.0 (pinned in `.nvmrc`). From the
repository root run `npm ci`; `create-dmg` 8.1.0 is locked in `package-lock.json` and invoked locally,
not through `npx`. Its locked macOS-native helper is built during installation, so do not suppress
dependency install scripts. The canonical checkout must have stored origin
`https://github.com/colmarius/mobcrew.git`, clean `main` tracking `origin/main`, complete history, and
freshly fetched HEAD equal to both `origin/main` and the canonical GitHub API's `main` SHA. The
operator needs authenticated canonical-repository push permission even though `check` itself is
non-mutating.

```bash
./scripts/release.sh check 1.2.3
./scripts/release.sh prepare 1.2.3
```

`prepare` tests before building. It writes fixed local outputs under `build/`:

- `Release/MobCrew.app`
- `MobCrew-1.2.3.dmg`, `.dmg.sha256`, and `.dmg.size`
- `MobCrew-1.2.3.dmg.verification.evidence` and `.verification.log`
- `MobCrew-1.2.3.manifest`

The strict, never-sourced manifest binds the canonical repository, full target SHA, artifact
identity/size/hash, bundle version/build/architectures, exact tools, lockfile, and inspection
evidence. Replacing the DMG is atomic on one filesystem; the companion files are intentionally not
described as a multi-file transaction. App structural signing is required. App identity, Developer
ID, team, hardened runtime,
app stapled-ticket validation/spctl, and outer-DMG signature/stapled-ticket validation/spctl are
recorded separately, including each probe's exit status. A negative probe can be expected for the
current non-Developer-ID path. Stapler validates a stapled ticket and is not by itself evidence of
notarization; missing or unclassifiable inspection infrastructure is an error. Architectures are
recorded, not enforced.

## Separately authorized draft gate

After authority to change GitHub state is explicit:

```bash
./scripts/release.sh create-draft 1.2.3
./scripts/release.sh status 1.2.3       # always read-only
./scripts/release.sh verify-draft 1.2.3
```

Draft creation first revalidates main, local evidence, artifact contents, and remote tag absence. It
discovers an existing draft by exact tag across the paginated releases API. When absent, it creates
metadata with a REST `POST` whose `target_commitish` is the full target SHA, captures the numeric
release ID, reads that exact release back, and uploads through that release ID's asset endpoint. A
matching asset is untouched; duplicate drafts, conflicting metadata, wrong state, wrong asset, extra
assets, and generic network failures stop. `verify-draft` binds the numeric release/asset IDs,
title/body, target, API digest when supplied, and a freshly downloaded size/SHA in
`build/MobCrew-1.2.3.remote-evidence`.

## Qualification contract

Download the draft through a browser onto a clean supported macOS account/Mac so quarantine is
preserved. Confirm it before launch with `xattr -l MobCrew-1.2.3.dmg` (record the
`com.apple.quarantine` value). A `gh` download is useful for byte verification but is not assumed to
carry quarantine. Select a finite matrix from recorded artifact architectures plus owner-selected
minimum/current macOS samples. Use only `tested`, `unverified`, or
`unsupported-by-explicit-decision`; unavailable hardware is **unverified**, never implicitly
unsupported. Task 3.4 remains manually unverified until this real quarantined-Mac run; Developer ID
signing/notarization remain blocked decisions.

For historical comparison, read-only inspection of the public `v0.2.0` browser download on
2026-08-08 recorded SHA-256 `1d7f8daff797dd20876b4a9ab011a98e20d23bf931e98118a131e7ba9c4b99d4`,
3,593,226 bytes, bundle version/build `0.2.0`/`146`, and an `arm64` executable. The app signature was
structurally valid and ad-hoc, with no Developer ID identity, team, or hardened runtime; the outer
DMG was unsigned, and neither app nor DMG had a stapled ticket. Both `spctl` probes were not accepted.
The DMG had `com.apple.quarantine` before mounting, but it was not launched; these negative probes do
not establish notarization status or predict the exact Gatekeeper first-launch result.

For each machine record target/version/digests, macOS/hardware, trust outputs, install and first
launch/Gatekeeper, Accessibility and Notifications allow/deny/recovery, launch at login, timer,
rotation, breaks, persistence, upgrade from the previous release, release notes/latest link, and
problem-notice plan. Publication consumes an exact-schema data file (values must be `tested`):

```text
schema=mobcrew-qualification-v1
manifest_sha256=<64 lowercase hex>
remote_evidence_sha256=<64 lowercase hex>
artifact_integrity=tested
gatekeeper_first_launch=tested
core_regression=tested
permissions=tested
upgrade=tested
release_notes=tested
publication_approved=tested
```

## Separately authorized publish gate

```bash
./scripts/release.sh publish 1.2.3 /absolute/path/to/qualification.txt
```

Publication requires a real `/dev/tty` and exact `v1.2.3` confirmation first. It then performs one
fresh, uninterrupted final gate: it reads the recorded numeric release, checks all metadata and
exactly one asset, downloads/hashes it again, and makes canonical API tag absence its last read
before PATCH. It PATCHes only `draft=false` on that numeric release ID and
verifies draft=false and that the resulting tag peels to the manifest SHA. If post-publication
verification fails, stop and report it: there is no automatic rollback. Verify the public asset,
latest link, notes, and install wording afterward. Prefer a corrective patch/problem notice over
rewriting public history. This ordering narrows and detects races; GitHub does not provide a
transactional publication lock, so it cannot prevent every concurrent change.
