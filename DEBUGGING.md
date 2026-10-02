# Debugging Duplex Roku in Cursor

## Setup

1. Open **`Duplex_Roku/`** as the workspace folder.
2. Extension: **BrightScript Language** (`RokuCommunity.brightscript`).
3. Start BrightScript Simulator (`npm run sim:open`) or point `launch.json` at a physical Roku IP.

## F5 debug

Select **Duplex → BrightScript Simulator** and press **F5**.

Simulator requires `"enableDebugProtocol": false` (already set).

## Logs

```bash
nc 127.0.0.1 8085          # simulator
telnet <ROKU_IP> 8085      # device
```

Or Cursor task **Telnet Debug Console**.

## Architecture notes

- Shared code: edit modules under `lib/{platform,api,services,core}/`. F5 runs `npm run build:lib` first.
- Keyboard: edit `lib/keyboard/DuplexKeyboard.brs` (copied into the package by the same build).
- Screens: `channel/components/screens/` — markup in `.xml`, logic in the sibling `.brs`.
- Tasks: `channel/components/tasks/`
- Router: `channel/components/MainScene.brs`
- Key routing: `MainScene` → `handleKeyEvent` on the active panel

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Connection refused | Start simulator / check Roku IP |
| Upload 401 | Password `rokudev` (sim) or device developer password |
| Component parse errors | Avoid reserved words (`step`, `pos`) as identifiers |
| Stale shared helpers | Run `npm run build:lib` (package and F5 already do this) |
