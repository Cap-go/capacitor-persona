# @capgo/capacitor-persona
 <a href="https://capgo.app/"><img src='https://raw.githubusercontent.com/Cap-go/capgo/main/assets/capgo_banner.png' alt='Capgo - Instant updates for capacitor'/></a>

<div align="center">
  <h2><a href="https://capgo.app/?ref=plugin_persona"> ➡️ Get Instant updates for your App with Capgo</a></h2>
  <h2><a href="https://capgo.app/consulting/?ref=plugin_persona"> Missing a feature? We’ll build the plugin for you 💪</a></h2>
</div>

Capacitor plugin for launching Persona Inquiry flows in iOS and Android apps.

## Install

```bash
bun add @capgo/capacitor-persona
bunx cap sync
```

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

## Integration Notes

- iOS requires Persona usage descriptions in `Info.plist`, including `NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`, and `NSBluetoothAlwaysUsageDescription`.
- Android uses Persona's Maven repository (`https://sdk.withpersona.com/android/releases`) and bundles `com.withpersona.sdk2:inquiry`.
- For critical business logic, rely on Persona webhooks instead of SDK callbacks.

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
