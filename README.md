# @capgo/capacitor-intune
 <a href="https://capgo.app/"><img src='https://raw.githubusercontent.com/Cap-go/capgo/main/assets/capgo_banner.png' alt='Capgo - Instant updates for capacitor'/></a>

<div align="center">
  <h2><a href="https://capgo.app/?ref=plugin_intune"> ➡️ Get Instant updates for your App with Capgo</a></h2>
  <h2><a href="https://capgo.app/consulting/?ref=plugin_intune"> Missing a feature? We’ll build the plugin for you 💪</a></h2>
</div>

Capacitor plugin for Microsoft Intune MAM enrollment, app protection policies, app config, and MSAL authentication.

## What it covers

- Interactive and silent Microsoft sign-in with MSAL
- Intune account registration, enrollment, logout, and selective wipe helpers
- Native Intune app configuration and app protection policy access
- Native change listeners for policy and app config refresh events
- iOS and Android native Intune SDK integration from one Capacitor API

## Platform requirements

- Capacitor 8+
- Android with the Microsoft Intune Android SDK `12.0.3`
- iOS with the Microsoft Intune iOS SDK `21.5.1`
- iOS deployment target `17.0+`

Ionic's Intune docs currently note that, starting January 19, 2026, apps built with Xcode 26 must use Intune iOS SDK `21.1.0` or later. This plugin bundles `21.5.1` for that reason.

## Install

```bash
bun add @capgo/capacitor-intune
bunx cap sync
```

## Native setup

This plugin wraps the native Intune SDKs, but your app still needs the host-project configuration Microsoft and Ionic require.

### Android

1. Add the Intune Gradle plugin to your app project's `android/build.gradle` buildscript classpath.
2. Add the Duo Maven feed Ionic calls out for current Intune Android SDK builds.
3. Apply `com.microsoft.intune.mam` in your app module.
4. Add the Intune SDK AAR and keep `android.enableResourceOptimizations=false`.
5. Add `android:name="app.capgo.intune.IntuneApplication"` to your `<application>` tag if you do not already use a custom `Application`.
6. If you do use a custom `Application`, extend `MAMApplication` and register `IntuneMamServiceAuthenticationCallback` in `onMAMCreate()`.
7. Add broker/auth queries plus the `BrowserTabActivity` intent filter for your `msauth://` redirect URI.
8. Create `android/app/src/main/res/raw/auth_config.json` with your MSAL app registration details.

Minimal `auth_config.json` example:

```json
{
  "client_id": "YOUR_CLIENT_ID",
  "authorization_user_agent": "BROWSER",
  "redirect_uri": "msauth://YOUR_PACKAGE/YOUR_SIGNATURE_HASH",
  "broker_redirect_uri_registered": true,
  "account_mode": "MULTIPLE",
  "authorities": [
    {
      "type": "AAD",
      "audience": {
        "type": "AzureADMyOrg"
      }
    }
  ]
}
```

If you target Android 16+, Ionic's docs also recommend `android:enableOnBackInvokedCallback="false"` on the `<application>` tag until the Intune SDK updates its back navigation support.

### iOS

1. Add your Intune and MSAL settings under `IntuneMAMSettings` in `Info.plist`.
2. Configure your URL scheme / redirect URI for MSAL.
3. Forward the auth callback URL to `MSALPublicClientApplication.handleMSALResponse(...)` from `AppDelegate`.
4. Run Microsoft's `IntuneMAMConfigurator` against your app's `Info.plist` and entitlements.
5. Keep the iOS deployment target at `17.0+`.

Minimal `Info.plist` configuration:

```xml
<key>IntuneMAMSettings</key>
<dict>
  <key>ADALClientId</key>
  <string>YOUR_CLIENT_ID</string>
  <key>ADALRedirectUri</key>
  <string>msauth.com.example.app://auth</string>
  <key>ADALAuthority</key>
  <string>https://login.microsoftonline.com/common</string>
</dict>
```

`AppDelegate.swift` example:

```swift
import MSAL

func application(
  _ app: UIApplication,
  open url: URL,
  options: [UIApplication.OpenURLOptionsKey: Any] = [:]
) -> Bool {
  return MSALPublicClientApplication.handleMSALResponse(
    url,
    sourceApplication: options[.sourceApplication] as? String
  )
}
```

## Usage

```ts
import { IntuneMAM } from '@capgo/capacitor-intune';

await IntuneMAM.addListener('appConfigChange', (result) => {
  console.log('Intune app config changed', result.accountId);
});

await IntuneMAM.addListener('policyChange', (result) => {
  console.log('Intune policy changed', result.accountId);
});

const auth = await IntuneMAM.acquireToken({
  scopes: ['https://graph.microsoft.com/.default'],
  loginHint: 'alex@example.com',
});

await IntuneMAM.registerAndEnrollAccount({ accountId: auth.accountId });

const user = await IntuneMAM.enrolledAccount();
const appConfig = await IntuneMAM.appConfig({ accountId: auth.accountId });
const policy = await IntuneMAM.getPolicy({ accountId: auth.accountId });
const versions = await IntuneMAM.sdkVersion();

console.log({ user, appConfig, policy, versions });
```

## Notes

- Web is not supported; the web implementation throws an unavailable error.
- The plugin does not create your Azure app registration, Intune policies, `auth_config.json`, or iOS entitlements for you.
- For iOS, follow Microsoft's latest Intune MAM configurator and entitlement guidance in addition to the plugin setup above.

## API

<docgen-index>

* [`acquireToken(...)`](#acquiretoken)
* [`acquireTokenSilent(...)`](#acquiretokensilent)
* [`registerAndEnrollAccount(...)`](#registerandenrollaccount)
* [`loginAndEnrollAccount()`](#loginandenrollaccount)
* [`enrolledAccount()`](#enrolledaccount)
* [`deRegisterAndUnenrollAccount(...)`](#deregisterandunenrollaccount)
* [`logoutOfAccount(...)`](#logoutofaccount)
* [`appConfig(...)`](#appconfig)
* [`getPolicy(...)`](#getpolicy)
* [`groupName(...)`](#groupname)
* [`sdkVersion()`](#sdkversion)
* [`displayDiagnosticConsole()`](#displaydiagnosticconsole)
* [`addListener('appConfigChange', ...)`](#addlistenerappconfigchange-)
* [`addListener('policyChange', ...)`](#addlistenerpolicychange-)
* [`removeAllListeners()`](#removealllisteners)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### acquireToken(...)

```typescript
acquireToken(options: AcquireTokenOptions) => Promise<IntuneMAMAcquireToken>
```

Present the Microsoft sign-in flow and return an access token plus the account metadata.

| Param         | Type                                                                |
| ------------- | ------------------------------------------------------------------- |
| **`options`** | <code><a href="#acquiretokenoptions">AcquireTokenOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#intunemamacquiretoken">IntuneMAMAcquireToken</a>&gt;</code>

--------------------


### acquireTokenSilent(...)

```typescript
acquireTokenSilent(options: AcquireTokenSilentOptions) => Promise<IntuneMAMAcquireToken>
```

Acquire a token from the MSAL cache for a previously signed-in user.

| Param         | Type                                                                            |
| ------------- | ------------------------------------------------------------------------------- |
| **`options`** | <code><a href="#acquiretokensilentoptions">AcquireTokenSilentOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#intunemamacquiretoken">IntuneMAMAcquireToken</a>&gt;</code>

--------------------


### registerAndEnrollAccount(...)

```typescript
registerAndEnrollAccount(options: RegisterAndEnrollAccountOptions) => Promise<void>
```

Register a previously authenticated account with Intune and start enrollment.

| Param         | Type                                                                                        |
| ------------- | ------------------------------------------------------------------------------------------- |
| **`options`** | <code><a href="#registerandenrollaccountoptions">RegisterAndEnrollAccountOptions</a></code> |

--------------------


### loginAndEnrollAccount()

```typescript
loginAndEnrollAccount() => Promise<void>
```

Ask Intune to authenticate and enroll a user without first requesting an app token.

--------------------


### enrolledAccount()

```typescript
enrolledAccount() => Promise<IntuneMAMUser | undefined>
```

Return the currently enrolled Intune account, if one is available.

**Returns:** <code>Promise&lt;<a href="#intunemamuser">IntuneMAMUser</a>&gt;</code>

--------------------


### deRegisterAndUnenrollAccount(...)

```typescript
deRegisterAndUnenrollAccount(user: IntuneMAMUser) => Promise<void>
```

Deregister the account from Intune and trigger selective wipe when applicable.

| Param      | Type                                                    |
| ---------- | ------------------------------------------------------- |
| **`user`** | <code><a href="#intunemamuser">IntuneMAMUser</a></code> |

--------------------


### logoutOfAccount(...)

```typescript
logoutOfAccount(user: IntuneMAMUser) => Promise<void>
```

Sign the user out of MSAL without unenrolling the Intune account.

| Param      | Type                                                    |
| ---------- | ------------------------------------------------------- |
| **`user`** | <code><a href="#intunemamuser">IntuneMAMUser</a></code> |

--------------------


### appConfig(...)

```typescript
appConfig(user: IntuneMAMUser) => Promise<IntuneMAMAppConfig>
```

Fetch the remote Intune app configuration for a managed account.

| Param      | Type                                                    |
| ---------- | ------------------------------------------------------- |
| **`user`** | <code><a href="#intunemamuser">IntuneMAMUser</a></code> |

**Returns:** <code>Promise&lt;<a href="#intunemamappconfig">IntuneMAMAppConfig</a>&gt;</code>

--------------------


### getPolicy(...)

```typescript
getPolicy(user: IntuneMAMUser) => Promise<IntuneMAMPolicy>
```

Fetch the currently effective Intune app protection policy for a managed account.

| Param      | Type                                                    |
| ---------- | ------------------------------------------------------- |
| **`user`** | <code><a href="#intunemamuser">IntuneMAMUser</a></code> |

**Returns:** <code>Promise&lt;<a href="#intunemampolicy">IntuneMAMPolicy</a>&gt;</code>

--------------------


### groupName(...)

```typescript
groupName(user: IntuneMAMUser) => Promise<IntuneMAMGroupName>
```

Convenience helper that resolves the `GroupName` app configuration value when present.

| Param      | Type                                                    |
| ---------- | ------------------------------------------------------- |
| **`user`** | <code><a href="#intunemamuser">IntuneMAMUser</a></code> |

**Returns:** <code>Promise&lt;<a href="#intunemamgroupname">IntuneMAMGroupName</a>&gt;</code>

--------------------


### sdkVersion()

```typescript
sdkVersion() => Promise<IntuneMAMVersionInfo>
```

Return the native Intune and MSAL SDK versions bundled by this plugin.

**Returns:** <code>Promise&lt;<a href="#intunemamversioninfo">IntuneMAMVersionInfo</a>&gt;</code>

--------------------


### displayDiagnosticConsole()

```typescript
displayDiagnosticConsole() => Promise<void>
```

Show the native Intune diagnostics UI.

--------------------


### addListener('appConfigChange', ...)

```typescript
addListener(eventName: 'appConfigChange', listenerFunc: (info: IntuneMAMChangeEvent) => void) => Promise<PluginListenerHandle>
```

Listen for remote app configuration refreshes.

| Param              | Type                                                                                     |
| ------------------ | ---------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'appConfigChange'</code>                                                           |
| **`listenerFunc`** | <code>(info: <a href="#intunemamchangeevent">IntuneMAMChangeEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('policyChange', ...)

```typescript
addListener(eventName: 'policyChange', listenerFunc: (info: IntuneMAMChangeEvent) => void) => Promise<PluginListenerHandle>
```

Listen for remote app protection policy refreshes.

| Param              | Type                                                                                     |
| ------------------ | ---------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'policyChange'</code>                                                              |
| **`listenerFunc`** | <code>(info: <a href="#intunemamchangeevent">IntuneMAMChangeEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### removeAllListeners()

```typescript
removeAllListeners() => Promise<void>
```

Remove all registered listeners for this plugin instance.

--------------------


### Interfaces


#### IntuneMAMAcquireToken

| Prop                    | Type                |
| ----------------------- | ------------------- |
| **`accountId`**         | <code>string</code> |
| **`accessToken`**       | <code>string</code> |
| **`accountIdentifier`** | <code>string</code> |
| **`idToken`**           | <code>string</code> |
| **`username`**          | <code>string</code> |
| **`tenantId`**          | <code>string</code> |
| **`authority`**         | <code>string</code> |


#### AcquireTokenOptions

Interactive token acquisition options.

| Prop              | Type                  | Description                                                            | Default            |
| ----------------- | --------------------- | ---------------------------------------------------------------------- | ------------------ |
| **`scopes`**      | <code>string[]</code> | Scopes to request, for example `https://graph.microsoft.com/.default`. |                    |
| **`forcePrompt`** | <code>boolean</code>  | When true, always show the Microsoft account picker or sign-in UI.     | <code>false</code> |
| **`loginHint`**   | <code>string</code>   | Optional login hint for the interactive sign-in flow.                  |                    |


#### AcquireTokenSilentOptions

Silent token acquisition options.

| Prop               | Type                  | Description                                                                | Default            |
| ------------------ | --------------------- | -------------------------------------------------------------------------- | ------------------ |
| **`scopes`**       | <code>string[]</code> | Scopes to request, for example `https://graph.microsoft.com/.default`.     |                    |
| **`accountId`**    | <code>string</code>   | Microsoft Entra object ID returned by `acquireToken` or `enrolledAccount`. |                    |
| **`forceRefresh`** | <code>boolean</code>  | When true, bypass the cached access token and request a fresh one.         | <code>false</code> |


#### RegisterAndEnrollAccountOptions

| Prop            | Type                | Description                                           |
| --------------- | ------------------- | ----------------------------------------------------- |
| **`accountId`** | <code>string</code> | Microsoft Entra object ID returned by `acquireToken`. |


#### IntuneMAMUser

| Prop                    | Type                |
| ----------------------- | ------------------- |
| **`accountId`**         | <code>string</code> |
| **`accountIdentifier`** | <code>string</code> |
| **`username`**          | <code>string</code> |
| **`tenantId`**          | <code>string</code> |
| **`authority`**         | <code>string</code> |


#### IntuneMAMAppConfig

| Prop            | Type                                                              |
| --------------- | ----------------------------------------------------------------- |
| **`accountId`** | <code>string</code>                                               |
| **`fullData`**  | <code><a href="#record">Record</a>&lt;string, string&gt;[]</code> |
| **`values`**    | <code><a href="#record">Record</a>&lt;string, string&gt;</code>   |
| **`conflicts`** | <code>string[]</code>                                             |


#### IntuneMAMPolicy

| Prop                           | Type                 |
| ------------------------------ | -------------------- |
| **`accountId`**                | <code>string</code>  |
| **`isPinRequired`**            | <code>boolean</code> |
| **`isManagedBrowserRequired`** | <code>boolean</code> |
| **`isScreenCaptureAllowed`**   | <code>boolean</code> |
| **`isContactSyncAllowed`**     | <code>boolean</code> |
| **`isAppSharingAllowed`**      | <code>boolean</code> |
| **`isFileEncryptionRequired`** | <code>boolean</code> |
| **`notificationPolicy`**       | <code>string</code>  |


#### IntuneMAMGroupName

| Prop            | Type                |
| --------------- | ------------------- |
| **`accountId`** | <code>string</code> |
| **`groupName`** | <code>string</code> |


#### IntuneMAMVersionInfo

| Prop                   | Type                            |
| ---------------------- | ------------------------------- |
| **`platform`**         | <code>'ios' \| 'android'</code> |
| **`intuneSdkVersion`** | <code>string</code>             |
| **`msalVersion`**      | <code>string</code>             |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### IntuneMAMChangeEvent

| Prop            | Type                |
| --------------- | ------------------- |
| **`accountId`** | <code>string</code> |


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>

</docgen-api>
