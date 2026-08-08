# Releasing MobCrew

The release path prepares, drafts, verifies, qualifies, and publishes the **same bytes**. Local
interlocks reduce mistakes; they are not proof that the operator has owner authority. Creating a
draft and publishing each require separate, explicit authorization. No script deletes, clobbers,
retags, or rolls back a release.

## Toolchain and preflight

Use a Mac with exactly Xcode 26.6 / Swift 6.3, `gh`, and Node 24.19.0 (pinned in `.nvmrc`). From the
repository root run `npm ci`; `create-dmg` 8.1.0 is locked in `package-lock.json` and invoked locally,
not through `npx`. The canonical checkout must have stored origin
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
creates metadata with the full target SHA only when absent, reads it back by canonical API, and then
uploads only when the expected asset is absent. A matching asset is untouched; conflicting metadata,
wrong state, wrong asset, extra assets, and generic network failures stop. `verify-draft` binds the
numeric release/asset IDs, title/body, target, API digest when supplied, and a freshly downloaded
size/SHA in `build/MobCrew-1.2.3.remote-evidence`.

## Qualification contract

Download the draft through a browser onto a clean supported macOS account/Mac so quarantine is
preserved. Confirm it before launch with `xattr -l MobCrew-1.2.3.dmg` (record the
`com.apple.quarantine` value). A `gh` download is useful for byte verification but is not assumed to
carry quarantine. Select a finite matrix from recorded artifact architectures plus owner-selected
minimum/current macOS samples. Use only `tested`, `unverified`, or
`unsupported-by-explicit-decision`; unavailable hardware is **unverified**, never implicitly
unsupported. Task 3.4 remains manually unverified until this real quarantined-Mac run; Developer ID
signing/notarization remain blocked decisions.

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
