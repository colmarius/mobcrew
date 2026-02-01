# Manual Testing Checklist

Run the app with `./scripts/run.sh` or ⌘R in Xcode, then verify:

## Timer
- [ ] Timer displays configured duration (default 5 min)
- [ ] Play button starts countdown (MM:SS decrements)
- [ ] Pause button stops countdown
- [ ] Reset button returns to configured duration
- [ ] Duration stepper adjusts time (1-30 min range)
- [ ] Progress bar reflects remaining time

## Roster
- [ ] Can add mobsters via text field + button
- [ ] Can remove mobsters (delete/X button)
- [ ] Can bench mobsters (moves to bench section)
- [ ] Can activate benched mobsters (returns to active)
- [ ] Driver/Navigator labels show on first two active mobsters

## Rotation
- [ ] Skip button advances turn (rotates driver→navigator→rest)
- [ ] Timer completion triggers rotation

## Floating Window
- [ ] Floating timer window appears on launch
- [ ] Shows current countdown
- [ ] Shows Driver/Navigator names

## Menu Bar
- [ ] Menu bar icon visible
- [ ] Quick controls accessible from menu

## Persistence
- [ ] Quit and relaunch app
- [ ] Roster (mobsters, bench state) persists
