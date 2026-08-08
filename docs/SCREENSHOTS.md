# Screenshot Guide

Capture real MobCrew windows on macOS, then optimize them for the landing page. Do not substitute
mockups or present an isolated panel as proof that it floats over another app.

## Before capturing

Record these details with the change or pull request:

- MobCrew commit, app version, and build configuration
- macOS version and hardware architecture
- Light or dark appearance, display scale, and capture pixel dimensions
- Any cropping or image conversion applied

Use a Retina display where available. Stage only `Alice`, `Bob`, `Charlie`, and `Dana`; close other
apps or hide personal information. Capture timers mid-countdown, keep window chrome visible when it
clarifies scope, and inspect the result at full size before replacing an asset.

Install ImageMagick (`brew install imagemagick`) to produce the checked-in WebP files. Capture source
to a temporary PNG and do not commit both source and optimized copies.

## 1. Main window (`hero-screenshot.webp`)

This is the primary product proof.

1. Run `./scripts/run.sh`.
2. Add Alice, Bob, Charlie, and Dana in that order.
3. Set a 5-minute timer and run it to about 4:30.
4. Confirm Driver Alice, Navigator Bob, and the whole active roster are visible.
5. Capture only the main window:

   ```bash
   screencapture -o -w /tmp/mobcrew-hero.png
   magick /tmp/mobcrew-hero.png -strip -define webp:method=6 -quality 86 \
     docs/assets/images/hero-screenshot.webp
   ```

Target roughly 1800×1200 pixels at Retina scale. Preserve the full window and title bar.

## 2. Floating panel (`floating-timer.webp`)

This capture should eventually demonstrate the always-on-top context, not only the panel.

1. Open a clean editor or terminal with non-sensitive sample code/text.
2. Position MobCrew's floating timer over that window.
3. Show about 2:30 with Driver Alice and Navigator Bob.
4. Capture a bounded region containing both the panel and enough background app to prove context:

   ```bash
   screencapture -o -i /tmp/mobcrew-floating.png
   magick /tmp/mobcrew-floating.png -strip -define webp:method=6 -quality 86 \
     docs/assets/images/floating-timer.webp
   ```

The current checked-in file shows only the panel and is captioned accordingly. Do not strengthen the
caption until a replacement visibly proves the context.

## 3. In-window break (`break-overlay.webp`)

1. Trigger a break and let the countdown reach about 2:30.
2. Keep the main window title bar visible so the image does not imply a full-screen overlay.
3. Capture the window and optimize it:

   ```bash
   screencapture -o -w /tmp/mobcrew-break.png
   magick /tmp/mobcrew-break.png -strip -define webp:method=6 -quality 86 \
     docs/assets/images/break-overlay.webp
   ```

## 4. General settings (`settings.webp`)

1. Open Settings (⌘,) and select General.
2. Show Launch at Login, Turn duration, Notifications, and Show Tips.
3. Capture the window and optimize it:

   ```bash
   screencapture -o -w /tmp/mobcrew-settings.png
   magick /tmp/mobcrew-settings.png -strip -define webp:method=6 -quality 86 \
     docs/assets/images/settings.webp
   ```

This image does not show the Shortcuts tab. The page must not claim it demonstrates shortcut
customization; MobCrew's listed shortcuts are fixed.

## Review at every presentation size

- Open each WebP directly and confirm small UI text, gradients, controls, and staged names are clear.
- Review the rendered gallery at 1440×900, 390×844, and 320px wide.
- Open each gallery link on mobile and confirm the full-resolution file remains inspectable.
- Compare encoded bytes before and after; investigate unexpected growth or visible artifacts.
- Confirm the HTML `width` and `height` match the final file dimensions.

## Current published files

```text
docs/assets/images/
├── hero-screenshot.webp   1800×1204
├── floating-timer.webp     360×320   (panel only; stronger capture queued)
├── break-overlay.webp     1800×1204
├── settings.webp           900×816
├── logo.png                128×128
└── social-preview.jpg     1200×630
```
