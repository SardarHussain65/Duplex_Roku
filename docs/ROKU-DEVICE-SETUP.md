# Sideloading Duplex on a physical Roku device

## 1. Enable developer mode

1. On the Roku remote: press **Home** 3 times, **Up** 2 times, **Right**, **Left**, **Right**, **Left**, **Right**.
2. Set a developer password when prompted.
3. Note the IP address shown on the developer settings screen.

## 2. Package the channel

From `Duplex_Roku/`:

```bash
npm run package
# → dist/duplex-roku.zip

# Production (isDev=false, no preview fallbacks):
npm run package:release
# → dist/duplex-roku-release.zip
```

## 3. Install via web installer

1. Open `http://<ROKU_IP>` in a browser.
2. Username: `rokudev`
3. Password: the developer password you set
4. Upload the zip and click **Install**

## 4. Debug console

```bash
telnet <ROKU_IP> 8085
# or
nc <ROKU_IP> 8085
```

## 5. Cursor / VS Code deploy

Update `.vscode/launch.json` `host` to the Roku IP and `password` to your developer password, then press **F5**.

## Certification notes

- Session restore skips Splash/Activation when tokens + active playlist exist
- Preview playlists are disabled in release builds (`DuplexIsDev() = false`)
- All network I/O runs in Task nodes
- Player releases `Video` content on Back
