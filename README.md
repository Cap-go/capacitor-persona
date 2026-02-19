# @capgo/capacitor-plugin-template
 <a href="https://capgo.app/"><img src='https://raw.githubusercontent.com/Cap-go/capgo/main/assets/capgo_banner.png' alt='Capgo - Instant updates for capacitor'/></a>

<div align="center">
  <h2><a href="https://capgo.app/?ref=plugin_{{PLUGIN_REF_SLUG}}"> ➡️ Get Instant updates for your App with Capgo</a></h2>
  <h2><a href="https://capgo.app/consulting/?ref=plugin_{{PLUGIN_REF_SLUG}}"> Missing a feature? We’ll build the plugin for you 💪</a></h2>
</div>

> Template README. Replace every `{{PLACEHOLDER}}` value before releasing.

## Snapshot

- **Plugin name:** `{{PLUGIN_DISPLAY_NAME}}`
- **One-line value:** `{{PLUGIN_TAGLINE}}`
- **Maintainer:** `{{MAINTAINER_OR_TEAM}}`
- **Status:** `{{alpha|beta|stable}}`

## Pre-Release Checklist

- [ ] Replace all `{{PLACEHOLDER}}` values in this README.
- [ ] Replace `{{PLUGIN_REF_SLUG}}` in Capgo CTA links (example: `native_audio`).
- [ ] Replace all `__AI_KEYWORD_*__` entries in `package.json`.
- [ ] Update the compatibility table for this plugin.
- [ ] Update `src/definitions.ts` with the real public API and JSDoc.
- [ ] Run `bun run docgen` and review generated API docs below.
- [ ] Confirm examples in this file run against the real implementation.
- [ ] Set GitHub repo description to start with `Capacitor plugin for ...`.
- [ ] Set GitHub repo homepage to `https://capgo.app/docs/plugins/{{PLUGIN_SLUG}}/`.
- [ ] Open docs/website PR to add this plugin to plugin list + plugin tutorial.
- [ ] Run `bun run verify` before publishing.

## Problem & Scope

### Why this plugin exists

`{{WHAT_PAIN_POINT_IT_SOLVES}}`

## Capgo Links

- **Plugin docs URL:** `https://capgo.app/docs/plugins/{{PLUGIN_SLUG}}/`
- **Plugin tutorial URL:** `{{PLUGIN_TUTORIAL_URL}}`
- **Website/docs repo:** `https://github.com/Cap-go/website`

### What it does

- `{{CAPABILITY_1}}`
- `{{CAPABILITY_2}}`
- `{{CAPABILITY_3}}`

### What it does not do

- `{{OUT_OF_SCOPE_1}}`
- `{{OUT_OF_SCOPE_2}}`

## Compatibility

| Plugin version | Capacitor compatibility | Maintained |
| -------------- | ----------------------- | ---------- |
| v8.\*.\*       | v8.\*.\*                | ✅          |
| v7.\*.\*       | v7.\*.\*                | On demand   |
| v6.\*.\*       | v6.\*.\*                | On demand   |

Policy:

- New plugins start at version `8.0.0` (Capacitor 8 baseline).
- Backward compatibility for older Capacitor majors is supported on demand.

## Quick Start (Template Authors)

```bash
bun install
bun run init-plugin your-plugin YourPlugin app.capgo.yourplugin
bun run verify
```

The `init-plugin` command updates package names, native class names, iOS/Android identifiers, and the local example app wiring.

## Public Launch (Required)

### 1) Publish in Capgo GitHub org as public

```bash
gh repo create Cap-go/capacitor-{{PLUGIN_SLUG}} --public --source=. --remote=origin --push
```

If the repo already exists and is private:

```bash
gh repo edit Cap-go/capacitor-{{PLUGIN_SLUG}} --visibility public --accept-visibility-change-consequences
```

### 2) Set GitHub description and homepage

Description must always start with: `Capacitor plugin for ...`

```bash
gh repo edit Cap-go/capacitor-{{PLUGIN_SLUG}} \
  --description "Capacitor plugin for {{SHORT_USE_CASE}}." \
  --homepage "https://capgo.app/docs/plugins/{{PLUGIN_SLUG}}/"
```

### 3) Open docs/website pull request

Create a PR on `https://github.com/Cap-go/website` that includes:

- Add plugin card/entry in website plugin list file: `{{WEBSITE_PLUGIN_LIST_FILE}}`
- Add plugin documentation page: `{{WEBSITE_PLUGIN_DOC_FILE}}`
- Add plugin tutorial page: `{{WEBSITE_PLUGIN_TUTORIAL_FILE}}`
- Cross-link docs page and tutorial page

## Install

```bash
bun add @capgo/capacitor-plugin-template
bunx cap sync
```

## Minimal Usage

```typescript
import { PluginTemplate } from '@capgo/capacitor-plugin-template';

const result = await PluginTemplate.echo({ value: 'Hello from Capgo' });
console.log(result.value);
```

## Integration Notes

- **iOS:** `{{IOS_NOTES_OR_PERMISSIONS}}`
- **Android:** `{{ANDROID_NOTES_OR_PERMISSIONS}}`
- **Web:** `{{WEB_LIMITATIONS_OR_BEHAVIOR}}`

## Example App

The `example-app/` folder is linked via `file:..` and is intended for validating native wiring during development.

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
