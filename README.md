# @capgo/capacitor-plugin-template
 <a href="https://capgo.app/"><img src='https://raw.githubusercontent.com/Cap-go/capgo/main/assets/capgo_banner.png' alt='Capgo - Instant updates for capacitor'/></a>

Capgo Capacitor plugin template for quickly bootstrapping new plugins with iOS, Android, Web, CI, and a local example app.

## Quick Start

```bash
bun install
bun run init-plugin your-plugin YourPlugin app.capgo.yourplugin
bun run docgen
bun run verify
```

The `init-plugin` command updates package names, native class names, iOS/Android identifiers, and the local example app.

## Install

```bash
bun add @capgo/capacitor-your-plugin
bunx cap sync
```

## Usage

```typescript
import { YourPlugin } from '@capgo/capacitor-your-plugin';

const result = await YourPlugin.echo({ value: 'Hello from Capgo' });
console.log(result.value);
```

## API

<docgen-index>

* [`echo(...)`](#echo)
* [`getPluginVersion()`](#getpluginversion)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

Base API used by the template plugin.

### echo(...)

```typescript
echo(options: EchoOptions) => Promise<EchoResult>
```

Echo a string to validate JS &lt;-&gt; native wiring.

| Param         | Type                                                |
| ------------- | --------------------------------------------------- |
| **`options`** | <code><a href="#echooptions">EchoOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#echoresult">EchoResult</a>&gt;</code>

--------------------


### getPluginVersion()

```typescript
getPluginVersion() => Promise<PluginVersionResult>
```

Returns the platform implementation version marker.

**Returns:** <code>Promise&lt;<a href="#pluginversionresult">PluginVersionResult</a>&gt;</code>

--------------------


### Interfaces


#### EchoResult

Echo response payload.

| Prop        | Type                | Description                      |
| ----------- | ------------------- | -------------------------------- |
| **`value`** | <code>string</code> | The same value passed to `echo`. |


#### EchoOptions

Input payload for the echo call.

| Prop        | Type                | Description                                                           |
| ----------- | ------------------- | --------------------------------------------------------------------- |
| **`value`** | <code>string</code> | Arbitrary text that should be returned by native/web implementations. |


#### PluginVersionResult

Plugin version payload.

| Prop          | Type                | Description                                                 |
| ------------- | ------------------- | ----------------------------------------------------------- |
| **`version`** | <code>string</code> | Version identifier returned by the platform implementation. |

</docgen-api>
