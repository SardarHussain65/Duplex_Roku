# Duplex Roku

Production-oriented Roku channel for Duplex IPTV (BrightScript / SceneGraph).

## Quick start (simulator)

```bash
cd Duplex_Roku
npm run sim:open      # BrightScript Simulator
npm run sim:deploy    # package + sideload + launch
```

Credentials: `rokudev` / `rokudev`

## Architecture

See [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md). Edit shared logic under `lib/`. `npm run build:lib` writes `channel/source/DuplexShared.brs` and copies the on-screen keyboard into the package. The zip root is `channel/`.

## Screens (MVP)

1. Splash → Activation (device register + subscription banner)
2. Playlist Source → Xtream Setup
3. Playlist Loading (real prepare / soft-success in dev)
4. Hub → Live TV Home → Player
5. Settings (device info + sign out)

Movies / Series / Favorites / Parental UI are Phase 5 stubs (API helpers already in place).

## Builds

| Command | Output |
|---------|--------|
| `npm run package` | `dist/duplex-roku.zip` (dev, preview fallbacks on) |
| `npm run package:release` | `dist/duplex-roku-release.zip` (production flags) |

## Physical device

See [docs/ROKU-DEVICE-SETUP.md](./docs/ROKU-DEVICE-SETUP.md).

## Cursor debugging

See [DEBUGGING.md](./DEBUGGING.md). Open the `Duplex_Roku/` folder as the workspace root, then F5.
