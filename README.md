# AxiOm

A customized VPN client built on top of [Hiddify](https://github.com/hiddify/hiddify-app)
(Flutter + sing-box core). This is a standalone snapshot — it does **not** carry the
upstream Hiddify git history.

## Highlights / customizations

- **Simplified server picker** — choose a server by **country + transport** (WebSocket /
  Reality) instead of a raw outbound list, plus an **Auto (fastest)** mode. The last choice
  is remembered between sessions.
- **WARP indicator** — when Cloudflare WARP detour is enabled, the picker shows a
  "Дополнительное шифрование WARP" badge and still lists the underlying servers.
- **Connection stats bar** — traffic, days, ping and a live **device counter** for the
  active subscription (with manual refresh). Unlimited traffic/expiry render as `∞`.
- **Connection timer** that survives the app process being killed in the background.
- AxiOm branding (Ω) across app icon, splash and UI.

## Build

Standard Flutter project on top of Hiddify. Fetch the native sing-box core libs via the
Makefile targets (see upstream Hiddify docs), then:

```bash
flutter pub get
flutter build windows --release      # desktop
flutter build apk --release          # android
```

### Required secrets (not in this repo)

Intentionally git-ignored / externalized:

1. **Signing keystore** — `android/key.properties` + `android/app/release.jks`
   (git-ignored). Provide your own for release builds.

2. **Device-service API key** — the device counter calls a backend API. The key is **not**
   stored in source; pass it at build time:

   ```bash
   flutter build apk --release --dart-define=DEVICE_API_KEY=<your_key>
   flutter build windows --release --dart-define=DEVICE_API_KEY=<your_key>
   ```

   Without it, the device counter simply stays hidden (everything else works).

## Credits & license

Based on [Hiddify](https://github.com/hiddify/hiddify-app) and the
[sing-box](https://github.com/SagerNet/sing-box) core. This project inherits the upstream
license — see [LICENSE.md](LICENSE.md).
