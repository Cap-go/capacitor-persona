# AGENTS.md

This file provides guidance to AI agents and contributors working on this Capacitor plugin template.

## Template First

Run this before implementing real plugin logic:

```bash
bun run init-plugin <plugin-slug> [ClassName] [app.capgo.packageid] [GitHubOrg]
```

Example:

```bash
bun run init-plugin downloader CapacitorDownloader app.capgo.downloader Cap-go
```

This command renames JS/iOS/Android identifiers, package metadata, and native file paths.

## Quick Start

```bash
# Install dependencies
bun install

# Build the plugin (TypeScript + Rollup + docgen)
bun run build

# Full verification (iOS, Android, Web)
bun run verify

# Format code (ESLint + Prettier + SwiftLint)
bun run fmt

# Lint without fixing
bun run lint
```

## Development Workflow

1. **Install** - `bun install` (never use npm)
2. **Build** - `bun run build` compiles TypeScript, generates docs, and bundles with Rollup
3. **Verify** - `bun run verify` builds for iOS, Android, and Web. Always run this before submitting work
4. **Format** - `bun run fmt` auto-fixes ESLint, Prettier, and SwiftLint issues
5. **Lint** - `bun run lint` checks code quality without modifying files

### Individual Platform Verification

```bash
bun run verify:ios
bun run verify:android
bun run verify:web
```

### Example App

The `example-app/` directory links to the plugin via `file:..`:

```bash
cd example-app
bun install
bun run start
```

Use `bunx cap sync <platform>` to test iOS/Android shells.

## Project Structure

- `src/definitions.ts` - TypeScript interfaces and types (source of truth for API docs)
- `src/index.ts` - Plugin registration
- `src/web.ts` - Web implementation
- `ios/Sources/` - iOS native code (Swift)
- `android/src/main/` - Android native code (Java/Kotlin)
- `dist/` - Generated output (do not edit manually)
- `Package.swift` - SwiftPM definition
- `*.podspec` - CocoaPods spec

## iOS Package Management

We always support both **CocoaPods** and **Swift Package Manager (SPM)**. Every plugin must ship a valid `*.podspec` and `Package.swift`.

## API Documentation

API docs in the README are auto-generated from JSDoc in `src/definitions.ts`. **Never edit the `<docgen-index>` or `<docgen-api>` sections in `README.md` directly.** Instead, update `src/definitions.ts` and run `bun run docgen`.

## Versioning

The plugin major version follows the Capacitor major version (e.g., plugin v8 for Capacitor 8). Ship breaking changes only with a Capacitor major migration.

## Changelog

`CHANGELOG.md` is managed automatically by CI/CD. Do not edit it manually.

## Common Pitfalls

- Always rename Swift/Java classes and package IDs when creating a new plugin from this template.
- We only use Java 21 for Android builds.
- `dist/` is regenerated on every build and should never be edited directly.
- Use Bun for everything. If a command needs a package binary, use `bunx`.
