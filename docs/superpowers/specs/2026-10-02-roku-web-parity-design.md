# Duplex Roku ↔ Web TV Full Parity Design

**Date:** 2026-10-02  
**Source of truth:** `Duplex_Web_TV` (`src/app/App.tsx` + screens)  
**Target:** `Duplex_Roku` BrightScript / SceneGraph channel  
**UI bar:** Visual clone (reuse Web TV layout, colors, copy, brand assets; adapt only for Roku focus / Video / keyboard)

---

## Goal

Ship a Roku channel that matches Duplex Web TV **screen-for-screen**: same cold-start order, same features, same UI language. Multi-phase delivery; each phase must leave the app runnable in the BrightScript Simulator.

---

## Approaches considered

| Approach | Pros | Cons |
|----------|------|------|
| **A. Screen-by-screen port** (recommended) | Matches Web flow early; easy to verify; reuses existing Roku shell | Longer calendar time |
| B. Big-bang rewrite | Clean architecture | High risk of long broken period |
| C. Shared JS core in WebView | Faster UI reuse | Not a certified Roku SceneGraph channel; rejected |

**Chosen:** A — multi-phase screen-by-screen with Web TV as reference.

---

## Navigation contract (must match Web)

Cold start **always**:

```
splash (2.2s / OK / Back)
  → activation (always; tokens refresh via generateDeviceId)
  → playlistSource (Continue) | playlistSource@Add / xtreamSetup (Quick Setup)
  → playlistLoading
  → hub
  → home (Live | Movies | Series | Favorites | Parental | Settings)
  → live channel / VOD detail / player
```

**Rules (parity with Web):**

1. **No skip-to-hub** on cold start. Tokens may persist; `activePlaylistId` may persist for prepare — but UI still walks Splash → Activation → user Continue → pick playlist → Loading → Hub.
2. `hasPlaylist` from activation only changes **button set** (hide Quick Setup when playlists exist), never auto-routes.
3. Session expiry / logout → Activation (Web clears tokens + device; Roku same).
4. Hub Back → Playlist Source (Web does this; Roku currently no-ops — fix).
5. Auth failure mid-session → Activation.

---

## Screen map

| Web screen | Roku panel | Parity target |
|------------|------------|---------------|
| SplashScreen | SplashPanel | Logo, “Duplex New Player”, black, 2.2s |
| ActivationScreen | ActivationPanel | States, QR, MAC/device, Continue / Quick Setup / Refresh / Exit |
| PlaylistSourceScreen | PlaylistSourcePanel | Cards, + Add Xtream, skeletons |
| XtreamSetupScreen | XtreamSetupPanel | XC + URL tabs, keyboard |
| PlaylistLoadingScreen | PlaylistLoadingPanel | Steps + progress + error |
| HubScreen | HubPanel | 4 tiles + util (Playlists / Parental / Settings), magenta focus |
| HomeScreen | HomePanel (+ new layers) | Browse, categories, library, overlays |
| LiveChannelScreen | (new or Home mode) | List + preview + enter fullscreen |
| VodDetailScreen | (new) | Movie / series detail |
| PlayerScreen | PlayerPanel | Live vs VOD chrome |
| SettingsScreen | SettingsPanel | 8 sections |
| Modals | SceneGraph dialogs | PIN, parental setup, playlist sidebar, confirm, keyboard |

---

## Phases

### Phase 0 — Boot & navigation parity (blocking)
- Always splash on cold start (remove hub restore jump).
- Hub Back → Playlist Source.
- Sign-out → Activation; clear tokens like Web.
- Copy Web brand assets into `channel/images/` as needed.
- Verify: every launch shows Splash first.

### Phase 1 — Onboarding visual + behavior polish
- Activation states/buttons match Web exactly.
- Playlist source layouts/cards match Web.
- Xtream + loading step copy/progress match Web.
- Dev soft-fail stays behind `DuplexIsDev()` only.

### Phase 2 — Hub visual parity
- Util row: Playlists | Parental | Settings.
- Tiles: Live / Movies / Series / Favorites with focus scale + magenta glow assets.
- Parental entry (PIN gate stub → full in Phase 4).

### Phase 3 — Live TV full path
- Home browse hero + categories + recently watched (history stub OK until Phase 5).
- Live category → channel list + preview.
- Player: LIVE badge, play/pause, back teardown; favorite/lock hooks.

### Phase 4 — Movies / Series / Favorites / Parental
- VOD browse grids, detail (Watch Now / seasons / episodes).
- Favorites library (Live \| Movies \| Series filters).
- Parental PIN setup, lock categories, locked library.

### Phase 5 — Settings + i18n + history + autoplay
- Settings sections: Language, Cache, Device, Subscription, Playlist, Parental, Watch History, Autoplay.
- Wire `DuplexT` + locale JSON on all panels.
- Watch history resume; series autoplay next episode.

### Phase 6 — Player polish + certification
- Seek ±10, captions/audio when available, episodes panel.
- Release package (`isDev=false`), device QA matrix, cert checklist.

---

## Architecture (Roku)

Keep existing stack:

- `MainScene` = router (field observers + `showScreen`).
- Panels = UI + `handleKeyEvent`.
- Tasks = network off main thread.
- `channel/source/DuplexShared.brs` = bundled modules only. Authored files live in `lib/` and are never shipped loose.

**New screen modes** may be:

- Separate panels (`LiveChannelPanel`, `VodDetailPanel`), or  
- Modes on `HomePanel` / `PlayerPanel` via fields  

Prefer separate panels when Web has a distinct screen (cleaner parity).

**Assets:** Copy from `Duplex_Web_TV/public/brand/` (and related) into Roku `channel/images/`; reference via `pkg:/images/...`.

**API:** Reuse existing GraphQL/REST helpers; extend stubs (`Favorites`, `Parental`, `WatchHistory`) to real calls mirroring Web `src/api/operations/*`.

---

## Non-goals / known Web gaps (do not invent)

- Real live EPG data (Web is decorative) — optional static strip only.
- TopNavBar if Web still unwinds it from Home — match whatever Web ships; prefer wiring a Roku top nav if Home needs tab switch.
- Samsung/LG native player adapters.

---

## Success criteria

1. Cold start always Splash → Activation before any playlist/hub UI.
2. User can complete: activate → pick/create playlist → hub → Live → play → back.
3. Movies / Series / Favorites / Parental / Settings behave as Web for happy paths.
4. Visuals use Web brand colors/assets; focus is D-pad first.
5. `npm run package` zip has no duplicate `.brs` modules; no `EXIT_BRIGHTSCRIPT_CRASH` on load.

---

## Testing

- BrightScript Simulator after each phase (`npm run package && npm run sim:deploy`).
- Manual D-pad walkthrough checklist per phase.
- Release zip + real Roku device before Phase 6 close.
