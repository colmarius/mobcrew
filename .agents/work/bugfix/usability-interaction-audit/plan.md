# Usability and Interaction Audit Plan

Exercise MobCrew as a user on macOS, correct reproducible interaction defects, and retain video and
frame-inspection evidence for the affected journeys.

## Goals

- Find interaction bugs through representative end-to-end use rather than source review alone.
- Fix each reproducible in-scope bug with the smallest change at the owning boundary.
- Demonstrate and inspect the corrected workflow in a native macOS recording.

## Tasks

- [ ] **Task 1: Audit representative interaction journeys**
  - Scope: Main timer, roster, break flow, Settings, floating timer, menu bar, and keyboard controls
  - Depends on: none
  - Acceptance:
    - Exercise the primary timer and roster workflow, including validation and role changes.
    - Exercise Settings, break controls, the floating timer, menu-bar controls, and fixed shortcuts where the runner environment permits.
    - Record reproducible defects with exact steps, expected behavior, and observed behavior.
  - Notes: System permission and multi-display checks may be reported as unverified when the runner cannot safely reset or provide the required environment.

- [ ] **Task 2: Fix reproducible interaction defects**
  - Scope: `MobCrew/MobCrew/` and matching `MobCrew/MobCrewTests/` ownership paths identified by Task 1
  - Depends on: Task 1
  - Acceptance:
    - Each confirmed defect is fixed at its source-of-truth boundary without unrelated UI redesign.
    - Automated regression coverage is added where the behavior is testable below the native UI layer.
    - The app builds and the relevant automated tests pass on macOS.
  - Notes: Leave unrelated findings unchanged and identify them separately.

- [ ] **Task 3: Verify corrected usability and produce evidence**
  - Scope: Corrected native app, `.amp/in/artifacts/`, and work-item evidence
  - Depends on: Task 2
  - Acceptance:
    - Re-run the affected journeys plus a representative happy path on the corrected build.
    - Save a demo video that visibly proves the exercised controls and resulting states.
    - Extract and inspect frames across the full video, including every interaction/state transition; record the frame count, cadence, and any visual anomalies.
    - Report tested facts separately from checks that remain unverified.
  - Notes: A finite audit cannot prove the absence of every possible bug; completion means no defects remain in the exercised journeys.

## Implementation Notes

Use the canonical checklist in `TESTING.md`. Prefer deterministic accessibility/keyboard automation
when practical, but visually inspect the running app and the final recording. Keep build products and
temporary extracted frames outside `.amp/in/artifacts/`; retain only user-reviewable evidence there.

## Constraints / Decisions

- Native app execution requires macOS 14+ and Xcode 26.6+; the coordinating orb is Linux.
- Do not reset system permissions, alter login state, publish changes, or mutate other shared state.
- The audit covers representative primary journeys, not every release-qualification matrix entry.

## Acceptance Criteria

- Confirmed interaction defects are fixed and regression-checked.
- The corrected app passes relevant automated checks on macOS.
- A reviewed demo recording demonstrates the corrected representative workflow.
- The result names any environment-dependent areas that were not verified.

## Verification

- `./scripts/test.sh` succeeds on the macOS runner.
- `./scripts/run.sh` launches the app and the Task 3 journeys complete with expected visible states.
- `ffprobe` (or equivalent) reports the final video metadata; extracted frames are inspected across the complete recording and around each interaction transition.
