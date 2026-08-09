# Project Instructions

MobCrew is a native Swift 6 macOS 14+ app built with SwiftUI and AppKit. Read [README.md](README.md)
for the product, requirements, and everyday development commands. Keep this file limited to
agent-specific repository constraints rather than duplicating the README.

## Repository Map

- `MobCrew/MobCrew/`: production source. `Core/` owns models, services, and global state; `Features/`
  owns feature UI; `App/` owns application lifecycle integration.
- `MobCrew/MobCrewTests/`: unit tests mirroring the production structure.
- `scripts/`: build, test, documentation, packaging, and release automation.
- `docs/`: public website plus the canonical [release procedure](docs/RELEASING.md).
- `.agents/work/`: durable active work; `.agents/research/`: reusable cross-work findings.
- `.agents/plans/` and `.agents/prds/`: legacy records, not locations for new work.

Do not maintain an exhaustive file tree here; use the repository and local `AGENTS.md` files as the
source of truth.

## Platform and Commands

- App builds, tests, and UI checks require a macOS runner or local Mac. Linux orbs cannot run Xcode
  or Apple simulators, and the project has no iOS target.
- Use the commands in [README.md#development](README.md#development) for routine work and
  [TESTING.md](TESTING.md) for interactive checks.
- Releases require the exact toolchain and ordered gates in [docs/RELEASING.md](docs/RELEASING.md).
  Do not copy release commands or qualification requirements into this file.
- In an Amp orb, use `amp orb services ensure` for the supervised documentation preview.

## Agent Work

- Keep small, self-contained planning and implementation in the current conversation.
- Create a durable work item under `.agents/work/<category>/<slug>/` when resumption,
  coordination, handoff, auditability, durable decisions, or an explicit request makes repository
  context useful.
- Use the `agent-work` skill for durable requirements, planning, refinement, execution, and optional
  handoffs. Follow `.agents/work/AGENTS.md` for status, artifact, evidence, and closeout rules.
- Keep task-specific research in its work item. Use `.agents/research/` only for reusable findings.
- Implement in the current thread by default. Handoffs are optional and should be persisted only when
  reuse or durable transition context justifies them.
- On completion, promote reusable outcomes, commit the final completed work-item snapshot, then use
  `close-work.sh` to stage its removal. Git history is the archive.

## Change and Documentation Rules

- Commit each logical step with a descriptive message; reference the durable work-item slug when one
  exists. Pushing and every GitHub release mutation require separate authority.
- Update only the canonical document whose facts changed:
  - `README.md`: product, installation, requirements, and routine development.
  - `CHANGELOG.md`: user-facing version history and release notes.
  - `TESTING.md`: manual and release-qualification checks.
  - `docs/RELEASING.md`: release toolchain, gates, evidence, and publication procedure.
  - `AGENTS.md`: agent workflow, ownership boundaries, and environment constraints.
- Keep work-item status, plans, and evidence aligned with `.agents/work/AGENTS.md` when durable work is
  used. Do not mirror that lifecycle into root documentation.
