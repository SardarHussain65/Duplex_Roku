# Duplex Roku — Architecture

## Tree

```
Duplex_Roku/
  lib/                     authored BrightScript (never zipped)
    platform/              BuildConfig, DeviceIdentity, RegistryStore, KeyNormalize, Locale
    api/                   GraphqlClient, RestClient, AuthService
    services/              Device, Playlist, Prepare, Content, Formatters,
                           Favorites, Parental, WatchHistory
    core/                  ScreenIds, Session
    keyboard/              DuplexKeyboard.brs
  channel/                 zip root
    manifest
    source/
      Main.brs
      DuplexShared.brs     generated bundle
      widgets/DuplexKeyboard.brs   generated copy
    components/
      MainScene.xml + MainScene.brs     router
      screens/             one .xml + one .brs per panel
      tasks/               network Task nodes
      widgets/             PlaylistCard, ContentCard
    images/
    locale/
  tools/                   build-lib, package, package-release
```

`npm run build:lib` concatenates `lib/{platform,api,services,core}` into `channel/source/DuplexShared.brs` and copies the keyboard. Edit `lib/`, not the generated files. A new module under `lib/` must be added to `ORDER` in `tools/build-lib.mjs` or the build fails.

Component scripts do not inherit the scene scope, so each panel and task includes `pkg:/source/DuplexShared.brs`.

## Runtime

```
Main.brs → MainScene
  ├── screens/   Splash, Activation, PlaylistSource, XtreamSetup,
  │              PlaylistLoading, Hub, Home, LiveChannel, VodDetail,
  │              Player, Settings, ParentalPin
  └── tasks/     Activation, PlaylistLoad, XtreamCreate, PlaylistPrepare, ContentLoad
```

`MainScene.brs` owns observers and `showScreen`. Each panel owns its layout (`.xml`) and `handleKeyEvent` (sibling `.brs`). Tasks run network I/O off the render thread.

## Navigation

Cold start is always Splash → Activation. Session tokens may persist, but the UI does not skip to Hub.

Playlist load success → Hub → Home (Live, Movies, Series, Favorites, Parental) → Live channel or VOD detail → Player.

## Build

| Script | Purpose |
|--------|---------|
| `npm run build:lib` | Regenerate `DuplexShared.brs` and the keyboard copy |
| `npm run package` | Dev zip (`isDev=true`) → `dist/duplex-roku.zip` |
| `npm run package:release` | Release zip (`isDev=false`) → `dist/duplex-roku-release.zip` |
| `npm run sim:deploy` | Package and sideload to the BrightScript Simulator |

The packager zips `channel/` only. It refuses the zip if `platform`, `api`, `services`, or `core` appear under `source/`, because those loose files plus the bundle declare the same functions twice and the channel crashes on load.
