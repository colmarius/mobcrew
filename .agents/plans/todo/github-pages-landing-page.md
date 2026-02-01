# Plan: GitHub Pages Landing Page

Create a static landing page for MobCrew deployed via GitHub Pages on pushes to main branch.

**Reference**: `.agents/research/github-pages-landing-page.md`

---

## Tasks

- [ ] **Task 1: Create docs folder structure**
  - Scope: `docs/`
  - Depends on: none
  - Acceptance:
    - `docs/` folder exists at repo root
    - `docs/CNAME` file contains `mob.crew`
    - `docs/assets/images/` directory exists for screenshots
  - Notes: No build step needed, static files only

- [ ] **Task 2: Create landing page HTML**
  - Scope: `docs/index.html`
  - Depends on: Task 1
  - Acceptance:
    - Single-page HTML with Tailwind CSS via CDN
    - Dark theme (#0A0A0A to #1A1A2E background, white/gray text, blue accent #0066FF)
    - Hero section with tagline "Your Mob Programming Companion" and subtitle
    - Download CTA button (link to GitHub releases) with "macOS 14.0+ required" note
    - Placeholder for hero screenshot (`assets/images/hero-screenshot.png`)
    - Features section with 3 cards: Timer, Roster, Rotate roles
    - "Inspired by Mobster" section mentioning native SwiftUI
    - Footer with GitHub repo link, MIT License, "Built with SwiftUI"
    - System fonts (-apple-system, SF Pro)
    - Responsive layout (mobile-friendly)
  - Notes: See research doc for wireframe structure

- [ ] **Task 3: Create favicon**
  - Scope: `docs/favicon.ico`
  - Depends on: Task 1
  - Acceptance:
    - Favicon file exists (can be simple placeholder or extracted from app icon)
    - Referenced in index.html `<link rel="icon">`
  - Notes: Use existing app icon if available in MobCrew/Resources

- [ ] **Task 4: Create GitHub Actions workflow for deployment**
  - Scope: `.github/workflows/pages.yml`
  - Depends on: Task 1
  - Acceptance:
    - Workflow triggers on push to `main` branch
    - Deploys `docs/` folder to GitHub Pages
    - Uses `actions/upload-pages-artifact` and `actions/deploy-pages`
    - Configures proper permissions for Pages deployment
  - Notes: No build step needed, just deploy static files

- [ ] **Task 5: Verify deployment setup**
  - Scope: `.github/workflows/pages.yml`, `docs/`
  - Depends on: Task 2, Task 4
  - Acceptance:
    - All files in place: `docs/index.html`, `docs/CNAME`, `.github/workflows/pages.yml`
    - HTML is valid and renders correctly (check with browser)
  - Notes: Manual DNS configuration for mob.crew domain is separate (done in Namecheap)

---

## Manual Steps (after plan completion)

1. **Configure DNS in Namecheap** (Advanced DNS → Host Records):
   | Type | Host | Value |
   |------|------|-------|
   | A Record | `@` | `185.199.108.153` |
   | A Record | `@` | `185.199.109.153` |
   | A Record | `@` | `185.199.110.153` |
   | A Record | `@` | `185.199.111.153` |
   | CNAME | `www` | `colmarius.github.io` |

2. **Enable GitHub Pages** in repo Settings → Pages:
   - Source: GitHub Actions
   - Custom domain: `mob.crew`
   - Enforce HTTPS: ✓

3. **Add app screenshots** to `docs/assets/images/`:
   - `hero-screenshot.png` - Main timer view
   - Additional feature screenshots as needed
