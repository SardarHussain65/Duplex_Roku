# Duplex Roku Web Parity — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port Duplex Web TV to Roku BrightScript so cold start, screens, features, and visuals match the web app.

**Architecture:** Keep MainScene router + panels + tasks + DuplexShared bundle. Port one screen/feature cluster per phase. Web TV is source of truth for flow, copy, colors, and assets.

**Tech Stack:** BrightScript, SceneGraph, GraphQL/REST (existing Duplex API), BrightScript Simulator.

## Global Constraints

- Cold start always Splash → Activation (never skip to Hub).
- Package `channel/` only. Authored modules live in `lib/` and are bundled into `channel/source/DuplexShared.brs`. Never put `platform`, `api`, `services`, or `core` under `channel/source/`.
- Visual clone: reuse Web brand assets and colors; adapt only for Roku input/Video.
- `DuplexIsDev()` soft-fail / preview data only when true.
- Do not invent real EPG beyond Web’s decorative strip.

---

## File map (primary)

| Area | Files |
|------|--------|
| Boot | `lib/core/Session.brs`, `channel/components/MainScene.brs` |
| Assets | `channel/images/*` ← copy from `Duplex_Web_TV/public/brand/` |
| Onboarding | `channel/components/screens/{Splash,Activation,PlaylistSource,XtreamSetup,PlaylistLoading}Panel.*` |
| Hub/Home | `channel/components/screens/{Hub,Home,LiveChannel,VodDetail}Panel.*` |
| Player/Settings | `channel/components/screens/{Player,Settings,ParentalPin}Panel.*` |
| Services | `lib/services/*.brs`, `lib/api/*.brs` |
| Build | `tools/{build-lib,package,package-release,zip-channel}.mjs`, `channel/manifest` |

---

## Phase 0 — Boot & navigation parity

### Task 0.1: Always start on Splash

**Files:** `lib/core/Session.brs`, regenerate `DuplexShared.brs`, `channel/components/MainScene.brs`

- [x] Change `DuplexResolveInitialScreen()` to always return splash (log only; remove hub restore branch).
- [x] Simplify `MainScene.init()` to always show splash + 2.2s timer (remove hub branch).
- [x] `npm run build:lib`

### Task 0.2: Hub Back → Playlist Source

**Files:** `channel/components/MainScene.brs`

- [x] In `onHubBack()`, when `backSelected = true`, `showScreen(playlistSource)`.

### Task 0.3: Copy Web brand assets

**Files:** `channel/images/`

- [x] Copy `logo.png`, `ActivationImage.png`, `trial-badge.png`, `hubCardFocusedBg.png`, `heroImageLiveTV.png` from Web `public/brand/`.
- [x] Copy `category-bg/` folder for later hub/home use.

### Task 0.4: Package & verify

- [x] Bump `build_version`, `npm run package && npm run sim:deploy`
- [ ] Confirm simulator log: no duplicate-function crash; first UI is Splash.

---

## Phase 1 — Onboarding visual/behavior polish

- [ ] Match Activation button matrix + colors/copy to Web ActivationScreen.
- [ ] Match PlaylistSource cards / Add control to Web.
- [ ] Match Xtream tabs + Loading steps labels/progress to Web.
- [ ] Simulator walkthrough: Splash → Activation → Continue → Playlist → Loading → Hub.

---

## Phase 2 — Hub visual parity

- [ ] Util row Playlists | Parental | Settings; enable Movies/Series/Favorites tiles (navigate even if destinations stub briefly).
- [ ] Magenta focus + `hubCardFocusedBg.png`.
- [ ] Parental entry → PIN modal (or temporary “coming soon” only if PIN not ready — prefer PIN stub that unlocks).

---

## Phase 3 — Live TV full path

- [ ] Home browse: hero, categories, channel grid.
- [ ] Live channel list + preview panel.
- [ ] Player LIVE controls + clean Back.

---

## Phase 4 — Movies / Series / Favorites / Parental

- [ ] VOD grids + VodDetailPanel (movie/series).
- [ ] Favorites library filters.
- [ ] Parental PIN, lock categories, locked library APIs wired.

---

## Phase 5 — Settings + i18n + history + autoplay

- [ ] Eight settings sections mirroring Web.
- [ ] Wire `DuplexT` across panels; language switch.
- [ ] Watch history + resume; series autoplay.

---

## Phase 6 — Player polish + release

- [ ] Seek ±10, captions/audio hooks, episodes panel.
- [ ] `package:release`, device QA, cert checklist.

---

## Execution order

Implement Phase 0 immediately after this plan is written. After each phase: package, deploy, manual D-pad check, then continue.
