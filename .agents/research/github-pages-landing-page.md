# MobCrew Landing Page Research

## Overview

Research for creating a presentational GitHub Pages website for MobCrew at `https://mob.crew`.

## Inspiration Analysis

### mobster.cc (Original Inspiration)

- Simple, clean single-page layout
- Cross-platform focus (Mac, Windows, Linux)
- Basic feature list and download button
- Minimal design, straightforward messaging

### Modern Mac App Landing Pages

**CleanShot X** (cleanshot.com)

- Hero section with bold tagline: "Capture your Mac's screen like a pro"
- Feature cards with animated GIFs/videos
- Social proof: user testimonials, tweets
- Dark theme with accent colors
- "Buy now" CTA prominently placed
- Feature breakdowns with visual demos
- User reviews/testimonials section

**Raycast** (raycast.com)

- Powerful hero: "Your shortcut to everything"
- Keyboard-first visual identity
- Feature showcases with interactive demos
- "Built for professionals like you" - social proof with recognizable names
- Community section (Slack, Twitter)
- YouTube video embeds
- Dark, modern aesthetic
- Download button with version info

**Arc Browser** (arc.net)

- Quote-based hero from The Verge
- Clean, minimal design
- Feature highlights with animations
- Privacy messaging prominent
- User testimonials
- Very clean, modern aesthetic

## Key Design Patterns

1. **Hero Section**
   - Bold, clear tagline explaining what the app does
   - Primary CTA (Download button)
   - Screenshot/video of the app in action

2. **Feature Showcase**
   - Visual demos (GIFs, videos, screenshots)
   - 3-4 key features highlighted
   - Brief, punchy descriptions

3. **Social Proof**
   - Testimonials/quotes
   - "Made for developers" messaging
   - GitHub stars (if applicable)

4. **Download/CTA**
   - macOS version requirement
   - Download button with version number
   - App Store badge (future)

5. **Footer**
   - Links to GitHub repo
   - MIT License mention
   - Contact/social links

## Technology

**Static HTML + Tailwind CSS** (via CDN) - zero build step, fast to deploy, perfect for a single landing page.

## GitHub Pages + Custom Domain Setup

### Files Needed

```text
docs/                    # or root, depending on config
├── index.html
├── CNAME               # Contains: mob.crew
├── assets/
│   ├── css/
│   │   └── style.css
│   ├── images/
│   │   ├── hero-screenshot.png
│   │   ├── feature-1.png
│   │   └── ...
│   └── fonts/          # (optional, use system fonts)
└── favicon.ico
```

### CNAME Configuration

Create `docs/CNAME` with content:

```text
mob.crew
```

### DNS Configuration for mob.crew

Add these DNS records:

**For apex domain (mob.crew):**

```text
Type: A
Name: @
Values:
  185.199.108.153
  185.199.109.153
  185.199.110.153
  185.199.111.153
```

**For www subdomain (optional):**

```text
Type: CNAME
Name: www
Value: colmarius.github.io
```

### GitHub Pages Settings

1. Go to repo Settings → Pages
2. Source: Deploy from a branch
3. Branch: `main` (or `gh-pages`) → `/docs` folder
4. Custom domain: `mob.crew`
5. Enforce HTTPS: ✓

## Proposed Page Structure

```text
┌─────────────────────────────────────────────────────────┐
│  MobCrew                              [GitHub] [Download]│
├─────────────────────────────────────────────────────────┤
│                                                         │
│              Your Mob Programming Companion             │
│     A native macOS timer for pair and mob programming   │
│                                                         │
│               [Download for Mac]                        │
│               macOS 14.0+ required                      │
│                                                         │
│              [Hero Screenshot of App]                   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Features                                               │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐             │
│  │ ⏱ Timer   │ │ 👥 Roster │ │ 🔄 Rotate │             │
│  │ Configur- │ │ Manage    │ │ Driver/   │             │
│  │ able turn │ │ your mob  │ │ Navigator │             │
│  │ duration  │ │ members   │ │ roles     │             │
│  └───────────┘ └───────────┘ └───────────┘             │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Screenshots                                            │
│  [Timer View] [Roster View] [Settings]                  │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Inspired by Mobster                                    │
│  MobCrew brings mob programming tools to modern macOS   │
│  with a native SwiftUI experience.                      │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Open Source                                            │
│  MIT Licensed • Built with SwiftUI                      │
│  [View on GitHub]                                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Design Recommendations

### Colors

- Dark theme (like modern dev tools)
- Primary: Blue accent (#0066FF or similar)
- Background: Near-black (#0A0A0A to #1A1A2E)
- Text: White/Light gray

### Typography

- Use system fonts (-apple-system, SF Pro)
- Large, bold headings
- Clean, readable body text

### Visual Style

- Rounded corners (matching macOS aesthetic)
- Subtle gradients
- Glass/blur effects (optional)
- App screenshots with drop shadows

## Screenshots Needed

1. **Hero screenshot** - Main timer view, full window
2. **Roster management** - Adding/editing mobsters
3. **Timer running** - Active session view
4. **Menu bar** (if applicable)

## Next Steps

1. ✅ Research complete
2. Create screenshots of current app
3. Create `docs/` folder with static site
4. Configure CNAME and deploy
5. Set up DNS for mob.crew domain

## Resources

- [GitHub Pages Custom Domain](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)
- [CleanShot X](https://cleanshot.com/) - Design inspiration
- [Raycast](https://raycast.com/) - Design inspiration
- [Arc Browser](https://arc.net/) - Design inspiration
