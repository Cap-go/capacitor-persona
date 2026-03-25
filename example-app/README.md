# Example App for `@capgo/capacitor-intune`

This Vite project links directly to the local plugin source so you can validate Intune MAM and MSAL flows against the local package.

## Getting started

```bash
bun install
bun run start
```

To test on native shells:

```bash
bunx cap add ios
bunx cap add android
bunx cap sync
```

Before testing on device or simulator, add your own:

- Android `android/app/src/main/res/raw/auth_config.json`
- Android manifest redirect URI and broker queries
- iOS `IntuneMAMSettings` values in `Info.plist`
- iOS MSAL callback handling in `AppDelegate`

The sample UI lets you:

- acquire a token interactively
- acquire a token silently for a cached account
- register and enroll the account with Intune
- inspect enrolled user, app config, policy, group name, and SDK versions
- listen for policy and app config refresh events
