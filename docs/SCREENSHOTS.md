# Screenshot Guide

Instructions for capturing screenshots for the landing page.

## Required Screenshots

### 1. hero-screenshot.png (required)

The main app window showing timer and roster.

**Setup:**

1. Run the app: `./scripts/run.sh`
2. Add 4 mobsters: Alice, Bob, Charlie, Dana
3. Set timer to 5 minutes
4. Start timer, let it run to ~3:45 remaining
5. Ensure Driver/Navigator labels are visible

**Capture:**

```bash
screencapture -o -w docs/assets/images/hero-screenshot.png
# Click on the main MobCrew window
```

**Specs:** ~1200x800px, Retina preferred

---

### 2. floating-timer.png (optional)

The always-on-top mini timer window.

**Setup:**

1. Enable floating timer from menu/settings
2. Position over a code editor or terminal
3. Timer showing ~2:30

**Capture:**

```bash
screencapture -o -w docs/assets/images/floating-timer.png
```

---

### 3. break-overlay.png (optional)

Full-screen break timer overlay.

**Setup:**

1. Trigger break timer
2. Let countdown reach ~4:30

**Capture:**

```bash
screencapture docs/assets/images/break-overlay.png
# Full screen capture
```

---

## Tips

- Use Retina display for crisp images
- Stage realistic names (not "Test1", "Test2")
- Capture with timer mid-countdown for visual interest
- Avoid personal info in screenshots

## Current Files

```text
docs/assets/images/
├── hero-screenshot.png  ← main hero image
└── logo.png             ← app icon
```
