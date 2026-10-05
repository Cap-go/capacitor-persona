# @capgo/capacitor-persona

<a href="https://capgo.app/?ref=plugin_persona"><img src="https://capgo.app/readme-banner.svg?repo=Cap-go/capacitor-persona" alt="Capgo - Instant updates for Capacitor" /></a>

<div align="center">
  <p><b>Capgo</b>: push fixes to your Capacitor users in minutes, build signed iOS and Android apps without a Mac, and roll back in one click.</p>
  <h2><a href="https://capgo.app/register/?ref=plugin_persona">➡️ Get started for free</a></h2>
  <p>14-day unlimited free trial. No credit card required</p>
  <p><a href="https://capgo.app/consulting/?ref=plugin_persona">Missing a feature? We'll build the plugin for you 💪</a></p>
</div>

<p align="center">
  <img src="https://capgo.app/icons/plugins/persona.svg" alt="Persona plugin icon" width="300" />
</p>

Launch [Persona Inquiry](https://docs.withpersona.com/docs/inquiry-overview) flows from Capacitor apps on iOS and Android. Use template IDs or resume existing inquiries, prefill fields, and listen for completion, cancel, and error events in JavaScript.

## What it covers

- Start a Persona Inquiry from a template ID, template version, or existing inquiry ID
- Prefill inquiry fields and set sandbox or production environment
- Receive `inquiryComplete`, `inquiryCanceled`, and `inquiryError` events in the WebView layer
- Native Persona SDK integration on iOS (`PersonaInquirySDK2`) and Android (`com.withpersona.sdk2:inquiry`)

## Install

You can use our AI-Assisted Setup to install the plugin. Add the Capgo skills to your AI tool using the following command:

```bash
npx skills add https://github.com/cap-go/capacitor-skills --skill capacitor-plugins
```

Then use the following prompt:

```text
Use the `capacitor-plugins` skill from `cap-go/capacitor-skills` to install the `@capgo/capacitor-persona` plugin in my project.
```

If you prefer Manual Setup, install the plugin by running the following commands and follow the platform-specific instructions below:

```bash
npm install @capgo/capacitor-persona
npx cap sync
```

Docs: [capgo.app/docs/plugins/persona/](https://capgo.app/docs/plugins/persona/)

## Usage

```ts
import { Persona } from '@capgo/capacitor-persona';

await Persona.addListener('inquiryComplete', (result) => {
  console.log('Persona complete', result.inquiryId, result.status, result.fields);
});

await Persona.addListener('inquiryCanceled', (result) => {
  console.log('Persona canceled', result.inquiryId, result.sessionToken);
});

await Persona.addListener('inquiryError', (result) => {
  console.error('Persona error', result.error, result.errorCode);
});

await Persona.startInquiry({
  templateId: 'itmpl_EXAMPLE',
  environment: 'sandbox',
  referenceId: 'user_123',
  fields: {
    name_first: 'Alex',
    age: 29,
    is_verified_user: true,
  },
});
```

Use Persona webhooks on your backend for authoritative verification status. SDK callbacks are best for UX, not compliance decisions.

## iOS setup

1. Run `npx cap sync ios`.
2. Ensure iOS deployment target is **15.0** or newer (matches the plugin podspec).
3. Add usage descriptions to `ios/App/App/Info.plist` (Persona may use camera, location, and Bluetooth during verification):

```xml
<key>NSCameraUsageDescription</key>
<string>We use the camera to verify your identity.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location during identity verification.</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>We use Bluetooth during identity verification when required.</string>
```

4. CocoaPods: the plugin podspec pulls `PersonaInquirySDK2` **2.41.2**. Swift Package Manager projects resolve `inquiry-ios-2` via the plugin `Package.swift`.

## Android setup

1. Run `npx cap sync android`.
2. In the app root `android/build.gradle`, add Persona's Maven repository so Gradle can resolve the inquiry SDK:

```gradle
allprojects {
  repositories {
    google()
    mavenCentral()
    maven { url 'https://sdk.withpersona.com/android/releases' }
  }
}
```

3. The plugin library targets **minSdk 24** and depends on `com.withpersona.sdk2:inquiry` (default **2.32.1**, overridable with `personaInquiryVersion` in Gradle).

## API

<docgen-index>

* [`startInquiry(...)`](#startinquiry)
* [`addListener('inquiryComplete', ...)`](#addlistenerinquirycomplete-)
* [`addListener('inquiryCanceled', ...)`](#addlistenerinquirycanceled-)
* [`addListener('inquiryError', ...)`](#addlistenerinquiryerror-)
* [`removeAllListeners()`](#removealllisteners)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### startInquiry(...)

```typescript
startInquiry(options: StartInquiryOptions) => Promise<void>
```

Launch a Persona Inquiry flow.

| Param         | Type                                                                |
| ------------- | ------------------------------------------------------------------- |
| **`options`** | <code><a href="#startinquiryoptions">StartInquiryOptions</a></code> |

--------------------


### addListener('inquiryComplete', ...)

```typescript
addListener(eventName: 'inquiryComplete', listenerFunc: (info: InquiryCompleteInfo) => void) => Promise<PluginListenerHandle>
```

Listen for successful completion.

| Param              | Type                                                                                   |
| ------------------ | -------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'inquiryComplete'</code>                                                         |
| **`listenerFunc`** | <code>(info: <a href="#inquirycompleteinfo">InquiryCompleteInfo</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('inquiryCanceled', ...)

```typescript
addListener(eventName: 'inquiryCanceled', listenerFunc: (info: InquiryCanceledInfo) => void) => Promise<PluginListenerHandle>
```

Listen for cancellation.

| Param              | Type                                                                                   |
| ------------------ | -------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'inquiryCanceled'</code>                                                         |
| **`listenerFunc`** | <code>(info: <a href="#inquirycanceledinfo">InquiryCanceledInfo</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('inquiryError', ...)

```typescript
addListener(eventName: 'inquiryError', listenerFunc: (info: InquiryErrorInfo) => void) => Promise<PluginListenerHandle>
```

Listen for unrecoverable errors.

| Param              | Type                                                                             |
| ------------------ | -------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'inquiryError'</code>                                                      |
| **`listenerFunc`** | <code>(info: <a href="#inquiryerrorinfo">InquiryErrorInfo</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### removeAllListeners()

```typescript
removeAllListeners() => Promise<void>
```

Remove all registered listeners for this plugin instance.

--------------------


### Interfaces


#### StartInquiryOptions

Input payload used to launch an Inquiry.

Provide at least one of:
- `templateId`
- `templateVersion`
- `inquiryId`

| Prop                  | Type                                                                                                        | Description                                               | Default                   |
| --------------------- | ----------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | ------------------------- |
| **`inquiryId`**       | <code>string</code>                                                                                         | Existing Inquiry ID created on your backend.              |                           |
| **`sessionToken`**    | <code>string</code>                                                                                         | Session token required when resuming an existing Inquiry. |                           |
| **`templateId`**      | <code>string</code>                                                                                         | Inquiry template ID from Persona Dashboard (recommended). |                           |
| **`templateVersion`** | <code>string</code>                                                                                         | Inquiry template version ID from Persona Dashboard.       |                           |
| **`referenceId`**     | <code>string</code>                                                                                         | Your internal user reference.                             |                           |
| **`accountId`**       | <code>string</code>                                                                                         | Persona account ID.                                       |                           |
| **`environment`**     | <code><a href="#personaenvironment">PersonaEnvironment</a></code>                                           | Persona environment.                                      | <code>'production'</code> |
| **`locale`**          | <code>string</code>                                                                                         | Locale override, for example `en`, `fr`, `es`.            |                           |
| **`fields`**          | <code><a href="#record">Record</a>&lt;string, <a href="#personafieldvalue">PersonaFieldValue</a>&gt;</code> | Optional fields pre-written into the Inquiry.             |                           |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### InquiryCompleteInfo

Payload emitted when an Inquiry is completed.

| Prop            | Type                                                                                                                    |
| --------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **`inquiryId`** | <code>string</code>                                                                                                     |
| **`status`**    | <code>string</code>                                                                                                     |
| **`fields`**    | <code><a href="#record">Record</a>&lt;string, <a href="#personaresultfieldvalue">PersonaResultFieldValue</a>&gt;</code> |


#### InquiryCanceledInfo

Payload emitted when an Inquiry is canceled.

| Prop               | Type                |
| ------------------ | ------------------- |
| **`inquiryId`**    | <code>string</code> |
| **`sessionToken`** | <code>string</code> |


#### InquiryErrorInfo

Payload emitted when an Inquiry errors.

| Prop            | Type                |
| --------------- | ------------------- |
| **`error`**     | <code>string</code> |
| **`errorCode`** | <code>string</code> |
| **`cause`**     | <code>string</code> |


### Type Aliases


#### PersonaEnvironment

Environment where Persona should run.

<code>'production' | 'sandbox'</code>


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>


#### PersonaFieldValue

Supported field value types for pre-writing Inquiry fields.

<code>string | number | boolean | string[]</code>


#### PersonaResultFieldValue

Serialized field value returned in Inquiry result callbacks.

<code>string | number | boolean | string[] | null</code>

</docgen-api>
