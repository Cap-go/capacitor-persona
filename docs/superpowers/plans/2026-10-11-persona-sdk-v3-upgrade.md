# Persona SDK v3 Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `@capgo/capacitor-persona` from Persona iOS Inquiry SDK 2.41.2 to 3.11.0 (and Android 2.32.1 to 2.59.1 for parity) with no breaking change to the JavaScript API, shipping as 8.2.0.

**Architecture:** The plugin is a thin bridge: `src/definitions.ts` is the public contract, `ios/Sources/PersonaPlugin/PersonaPlugin.swift` and `android/src/main/java/app/capgo/persona/PersonaPlugin.java` translate `startInquiry` options into the native builder API and forward SDK callbacks as `inquiryComplete` / `inquiryCanceled` / `inquiryError` events. Persona v3 removed `InquiryConfiguration` and typed the iOS error callback, so the iOS bridge switches entirely to the builder API and gains a small, unit-tested error mapper. Everything else is a version pin, docs, and a drift guard.

**Tech Stack:** Capacitor 8 plugin template (Bun, TypeScript 5.9, Rollup, `@capacitor/docgen`), Swift 5 language mode via SwiftPM (tools 5.9) and CocoaPods, Java 21 Android library (AGP 8.13), Persona `PersonaInquirySDK2` 3.11.0 (iOS) and `com.withpersona.sdk2:inquiry` 2.59.1 (Android), GitHub Actions.

**Spec:** No separate spec document exists. Requirements come from upstream issue [Cap-go/capacitor-persona#8](https://github.com/Cap-go/capacitor-persona/issues/8) ("Migrate iOS to v3 and bump version number accordingly for release"), the Persona [iOS v2 to v3 migration guide](https://docs.withpersona.com/migrate-from-ios-sdk-v2-to-v3), the Persona [iOS changelog](https://docs.withpersona.com/ios-sdk-v2-changelog), and the repo's `AGENTS.md`. The "Research findings" section below records every fact the plan relies on, with how it was verified.

---

## Research findings (verified 2026-10-11)

These were checked directly against the published artifacts, not just the docs. Re-verify only if a newer Persona release lands before implementation.

| Fact | Value | How verified |
| --- | --- | --- |
| Latest Persona iOS SDK | **3.11.0** (2026-10-05) | GitHub releases for `persona-id/inquiry-ios-2`; Persona iOS changelog |
| Where v3 lives | Same repo `persona-id/inquiry-ios-2`, same package `PersonaInquirySDK2`, same product `PersonaInquirySDK2`, same module `Persona2` | `Package.swift` at tag `3.11.0` |
| v3 minimum iOS | **15.0** (3.0.0 required 17.6, 3.0.1 lowered it to 15.0) | `Package.swift` at `3.11.0` declares `.iOS("15.0")`; changelog 3.0.1 |
| CocoaPods for v3 | **Available again from 3.8.0**; `PersonaInquirySDK2` 3.8.0, 3.9.0, 3.10.0, 3.11.0 are on trunk | CocoaPods CDN shard `all_pods_versions_2_b_1.txt` |
| iOS breaking changes that touch this plugin | (1) `InquiryDelegate.inquiryError(_:)` now takes `PersonaError`, not `Error`. (2) `InquiryConfiguration` and `Inquiry(config:delegate:)` are gone; `templateVersion` must use `Inquiry.from(templateVersion:delegate:)` | Negative compile probe of the v2 code against the 3.11.0 xcframework produced exactly these two errors |
| iOS breaking changes that do not touch this plugin | Theming (`InquiryTheme`), async upload APIs, `routingCountry` removed | Plugin never used them |
| `PersonaError` cases | `.networking`, `.invalidSessionToken`, `.oneTimeLinkCodeInvalid`, `.rateLimitExceeded`, `.camera`, `.gps`, `.permissions`, `.misconfigured(InquiryConfigurationError)`, `.other`; conforms to `CustomDebugStringConvertible`, not `LocalizedError` | `arm64-apple-ios.swiftinterface` in the 3.11.0 xcframework |
| `InquiryConfigurationError` cases | `.invalidTemplateId(String)`, `.invalidTemplateVersion(String)`, `.prefixSDKVersionMismatch(String)`, `.invalidFieldError(String)`, `.serverConfiguration`, `.webRtcMisconfiguration`, `.invalidStaticTemplate`, `.invalidInlineInquiry`; conforms to `LocalizedError` | same |
| v3 `InquiryTemplateBuilder` setters used here | `referenceId`, `accountId`, `fields`, `environment`, `locale`, `build` all exist, for both `from(templateId:)` and `from(templateVersion:)` | same; positive compile probe passed |
| v3 `InquiryBuilder` (resume by `inquiryId`) | Has `sessionToken`, `locale`; has **no** `environment` setter, so the existing "environment not allowed on resume" rejection stays | same |
| `InquiryField`, `Environment`, `inquiryComplete`, `inquiryCanceled` | Unchanged from v2 | same |
| `InquiryDelegate` isolation | Protocol is `@MainActor`. Conformance compiles unchanged in Swift 5 language mode (what this plugin uses). Swift 6 mode would need `@MainActor` on the plugin class | positive compile probe |
| Toolchain compatibility | 3.11.0 interface was emitted by Swift 6.3.2. Local Xcode 26.2 (Swift 6.2.3) type-checks it for device and simulator slices. CI `macos-latest` is macOS 26 arm64 with Xcode 26.6 default | `swiftc -typecheck` probes; `actions/runner-images` README |
| Latest Persona Android SDK | **2.59.1** (2026-10-08). **No Android v3 exists.** | Maven Central metadata; Persona Android changelog |
| Android 2.59.1 API used by plugin | `Inquiry.fromInquiry/fromTemplate/fromTemplateVersion`, `InquiryBuilder.sessionToken/locale`, `InquiryTemplateBuilder.referenceId/accountId/fields/environment/locale`, `InquiryResponse.Complete/Cancel/Error` getters, `Fields.Builder.field(...)/fieldMultiChoices`, all `InquiryField$*Field` subclasses: all present and unchanged | `javap` on `dynamic-feature-2.59.1.aar` |
| Android 2.59.0 "breaking change" | Only affects `SentinelEvent.trigger(...)`, which this plugin does not use | Persona Android changelog |
| Android artifact hosting | Persona's own Maven repo stops at 2.55.0; 2.56.0 and later are **Maven Central only**. The plugin's `android/build.gradle` already lists `mavenCentral()` first | `maven-metadata.xml` on both hosts |
| Repo state | `origin/main` still contains the Intune plugin (overwritten in `578537c`). The Persona restore is open as PR #7 (`cursor/restore-persona-plugin-afcd` into `main`). This branch `billpull/persona-v3-upgrade` is stacked on that restore. The author has **no push access** to `Cap-go/capacitor-persona` and no fork exists yet. | `git log`, `gh pr list`, author |
| Capacitor 8 iOS package manager | SPM is the default for new apps (`cap add ios`); CocoaPods still supported. The packed-example CI builds the SPM project | Ionic Capacitor 8 announcement; `.github/scripts/verify-packed-example.sh` |

## Global Constraints

From `AGENTS.md` and the CI workflows. Every task's requirements include these.

- **Version follows Capacitor major.** The plugin stays on `8.x`. This release is **8.2.0**, produced by CI (`capacitor-plugin-standard-version` in `.github/workflows/bump_version.yml`) from conventional-commit messages. Use `feat:` on at least one commit to get a minor bump. Never use `feat!:` or a `BREAKING CHANGE` footer. **Never hand-edit `"version"` in `package.json` or `CHANGELOG.md`.**
- **No breaking changes in `src/definitions.ts`.** Only JSDoc edits and additive, optional fields are allowed.
- **Ship both CocoaPods and SPM.** `CapgoCapacitorPersona.podspec` and `Package.swift` must both resolve Persona at the same version.
- **`capacitor-swift-pm` stays pinned `from: "8.0.0"`** in `Package.swift` (CI job `guard_swiftpm_version` fails otherwise).
- **iOS deployment target stays `15.0`** in both `Package.swift` and the podspec (Persona 3.x needs exactly that).
- **Bun for everything.** `bun install`, `bun run ...`, `bunx ...`. Never `npm`.
- **Java 21 only** for Android builds. `compileSdk` 36, `minSdk` 24 stay as they are.
- **README API section is generated.** Never edit between `<docgen-index>`/`<docgen-api>` markers; edit `src/definitions.ts` and run `bun run build` (which runs `docgen`).
- **Formatting:** `bun run fmt` (ESLint + Prettier + SwiftLint) before every commit. CI runs `bun run lint`.
- **Timeouts:** any new CI step or script stays within the job's existing `timeout-minutes: 10`.
- **Commit style:** lower-case conventional commits as in `git log` (`feat(ios): ...`, `fix(ci): ...`, `docs: ...`, `chore: ...`). No Jira prefixes in this repo. End every commit message with `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- **Public API behaviour documented in this plan must match on both platforms** unless the SDK makes that impossible; platform differences go into JSDoc.
- **No push.** The author has no write access to `Cap-go/capacitor-persona` and has not forked it yet. Every task commits locally only; the plan stops after local verification in Task 7. Pushing and opening the PR happen later, from a fork, outside this plan.

## Review Focus

Input classes the SDK change touches that the task tests do not fully exercise. Each line names the owning task where its check lives.

1. **`inquiryError` with `.misconfigured(...)` on iOS.** A user passing a bad `templateId` must receive `error` (human-readable), `errorCode: "misconfigured"`, and `cause` carrying the configuration detail, not a generic "operation couldn't be completed" string. Pinned by the XCTest in Task 3.
2. **`templateVersion` together with `locale` on iOS.** Previously rejected on iOS only. After the upgrade it must launch (both builders expose `locale`). Pinned by the manual example-app check in Task 7 and the JSDoc change in Task 4.
3. **`inquiryId` together with `environment` on iOS.** Must still reject with the existing message, since v3's `InquiryBuilder` has no `environment` setter and Android rejects it too. Pinned by the manual example-app check in Task 7.
4. **Apps consuming the plugin through CocoaPods.** `pod install` must resolve `PersonaInquirySDK2` 3.11.0 from trunk (3.x pods only exist from 3.8.0). Pinned by the podspec lint in Task 2 and the drift guard in Task 6.
5. **Apps built with an older Xcode.** The 3.11.0 binary's Swift interface was emitted by Swift 6.3.2 and is verified only with Xcode 26.2 (local) and 26.6 (CI). Pinned by the README requirement statement in Task 5 and by CI's iOS job in Task 7.

## File structure

| Path | Change | Responsibility |
| --- | --- | --- |
| `Package.swift` | Modify line 14 (pin) and line 27 (test deps) | SwiftPM pin to Persona 3.11.0; let tests import `Persona2` |
| `CapgoCapacitorPersona.podspec` | Modify line 17 | CocoaPods pin to 3.11.0 |
| `ios/Sources/PersonaPlugin/PersonaPlugin.swift` | Modify `buildInquiry` (lines 32-103), `inquiryError` (lines 206-210), `PersonaPluginError` (lines 213-234) | Builder-only inquiry construction; typed error forwarding |
| `ios/Sources/PersonaPlugin/PersonaErrorMapper.swift` | Create | Pure mapping `PersonaError` to the `inquiryError` payload |
| `ios/Tests/PersonaPluginTests/PersonaErrorMapperTests.swift` | Create | XCTests for the mapper |
| `ios/Tests/PersonaPluginTests/PersonaPluginTests.swift` | Delete | Placeholder test replaced by real tests |
| `src/definitions.ts` | Modify lines 41-46 and 104-111 | JSDoc: locale now works with `templateVersion` on iOS; document `errorCode` values per platform |
| `README.md` | Modify lines 23, 79-94, 96-111; add a "Upgrading from 8.1.x" subsection | Setup instructions, SDK versions, Xcode note, Info.plist keys |
| `android/build.gradle` | Modify line 7 | Default `personaInquiryVersion` 2.59.1 |
| `scripts/check-persona-sdk-pin.mjs` | Create | Fail CI when podspec and `Package.swift` disagree on the Persona version |
| `package.json` | Add script after line 52 | `check:persona-pin` |
| `.github/workflows/test.yml` | Add a step after lines 44, 75, 102 | Run the drift guard in all three jobs |

Not changed: `src/index.ts`, `src/web.ts`, `android/.../PersonaPlugin.java` (2.59.1 is source-compatible), `example-app/**` (no API change), `.github/scripts/patch-persona-example-android.py` (the Persona Maven repo is still useful for apps pinning 2.55.0 or older), `renovate.json`.

---

### Task 1: Toolchain baseline

Make sure the machine can run every verification command in later tasks, and record the green baseline before touching anything.

**Files:** none modified.

- [ ] **Step 1: Install Bun and SwiftLint (both are missing locally as of 2026-10-11)**

```bash
brew install oven-sh/bun/bun swiftlint
bun --version          # expect 1.x
swiftlint version      # expect 0.5x
xcodebuild -version    # expect Xcode 26.2 or newer
java -version          # expect 21.x
```

- [ ] **Step 2: Install dependencies**

```bash
cd /Users/parlaybillm3/code/ParlayPlay/capacitor-persona
bun install
```

Expected: completes without changing `bun.lock` (`git status --short` prints nothing).

- [ ] **Step 3: Record the baseline on the unmodified branch**

```bash
bun run check:package-identity && bun run check:wiring && bun run check:cap9-deprecated
bun run lint
bun run verify:web
bun run verify:ios
```

Expected: all four exit 0. `verify:ios` resolves `inquiry-ios-2` at `2.41.2` and prints `** BUILD SUCCEEDED **`. If any baseline step fails, stop and fix the environment before continuing; none of the later tasks can be judged otherwise.

- [ ] **Step 4: Confirm the branch and starting point**

```bash
git branch --show-current     # billpull/persona-v3-upgrade
git log --oneline -1          # e88d806 docs: add compressed example app screenshot
git status --short            # empty
```

No commit for this task.

---

### Task 2: Pin iOS to Persona 3.11.0 and migrate the Swift bridge to the builder API

Bump both iOS pins, prove the build breaks in exactly the two expected places, then make the minimal code change that restores a green build. The error payload stays identical in shape to today (just `error`); Task 3 enriches it.

**Files:**
- Modify: `Package.swift:14`, `Package.swift:27`
- Modify: `CapgoCapacitorPersona.podspec:17`
- Modify: `ios/Sources/PersonaPlugin/PersonaPlugin.swift:32-103`, `:206-210`, `:213-234`

**Interfaces:**
- Consumes: Persona 3.11.0 `Inquiry.from(templateId:delegate:)`, `Inquiry.from(templateVersion:delegate:)` (both return `InquiryTemplateBuilder`), `Inquiry.from(inquiryId:delegate:)` (returns `InquiryBuilder`), `InquiryDelegate.inquiryError(_ error: PersonaError)`.
- Produces: `PersonaPlugin.inquiryError(_ error: PersonaError)` which Task 3 will route through `PersonaErrorMapper.payload(for:)`.

- [ ] **Step 1: Bump the SwiftPM pin and give the test target access to `Persona2`**

In `Package.swift`, change line 14:

```swift
        .package(url: "https://github.com/persona-id/inquiry-ios-2.git", exact: "3.11.0")
```

and change the test target (lines 25-29) to:

```swift
        .testTarget(
            name: "PersonaPluginTests",
            dependencies: [
                "PersonaPlugin",
                .product(name: "PersonaInquirySDK2", package: "inquiry-ios-2")
            ],
            path: "ios/Tests/PersonaPluginTests")
```

- [ ] **Step 2: Bump the CocoaPods pin**

In `CapgoCapacitorPersona.podspec`, change line 17:

```ruby
  s.dependency 'PersonaInquirySDK2', '3.11.0'
```

- [ ] **Step 3: Build and confirm it fails for exactly the two expected reasons (the "red" step)**

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/capacitor-persona-*
bun run verify:ios 2>&1 | grep -E 'error:|Checking out' | sort -u
```

Expected output contains `Checking out 3.11.0 of package 'inquiry-ios-2'` and these two errors (paths abbreviated), and nothing else:

```
PersonaPlugin.swift:89: error: cannot find 'InquiryConfiguration' in scope
PersonaPlugin.swift:205: error: type 'PersonaPlugin' does not conform to protocol 'InquiryDelegate'
```

If other errors appear, the SDK surface changed after this plan was written: stop, re-read the `Persona2.swiftinterface` for the new release, and update this plan before continuing.

- [ ] **Step 4: Replace the template branches of `buildInquiry` with one builder-based branch**

In `ios/Sources/PersonaPlugin/PersonaPlugin.swift`, replace everything from `        if let templateId {` (line 64) through `        throw PersonaPluginError.missingIdentifier` (line 102) with:

```swift
        let templateBuilder: InquiryTemplateBuilder
        if let templateId {
            templateBuilder = Inquiry.from(templateId: templateId, delegate: self)
        } else if let templateVersion {
            templateBuilder = Inquiry.from(templateVersion: templateVersion, delegate: self)
        } else {
            throw PersonaPluginError.missingIdentifier
        }

        if let referenceId {
            _ = templateBuilder.referenceId(referenceId)
        }
        if let accountId {
            _ = templateBuilder.accountId(accountId)
        }
        if !fields.isEmpty {
            _ = templateBuilder.fields(fields)
        }
        if let environment {
            _ = templateBuilder.environment(environment)
        }
        if let locale {
            _ = templateBuilder.locale(locale)
        }

        return templateBuilder.build()
```

The `if let inquiryId { ... }` resume branch directly above stays exactly as it is (including the `environmentNotAllowedForResume` throw). This now mirrors the Android `buildInquiry` structure line for line.

- [ ] **Step 5: Update the delegate error method to the typed signature (minimal payload for now)**

Replace lines 206-210:

```swift
    public func inquiryError(_ error: PersonaError) {
        notifyListeners("inquiryError", data: [
            "error": error.debugDescription
        ])
    }
```

Why `debugDescription`: `PersonaError` is `CustomDebugStringConvertible` but not `LocalizedError`, so `error.localizedDescription` would print the useless `The operation couldn't be completed. (Persona2.PersonaError error 0.)`.

- [ ] **Step 6: Remove the two now-unreachable error cases**

In `private enum PersonaPluginError` delete `case invalidConfiguration` and `case templateVersionLocaleUnsupported`, and delete their two `return "..."` lines in `errorDescription`. The enum ends up with three cases: `missingIdentifier`, `invalidEnvironment(String)`, `environmentNotAllowedForResume`.

- [ ] **Step 7: Build and lint (the "green" step)**

```bash
bun run verify:ios 2>&1 | grep -E 'warning:|error:|BUILD'
bun run swiftlint -- lint
pod lib lint CapgoCapacitorPersona.podspec --allow-warnings --skip-tests 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`, zero `error:` lines, no new `warning:` lines mentioning `PersonaPlugin.swift`, SwiftLint reports 0 violations, `pod lib lint` ends with `CapgoCapacitorPersona passed validation.` (The pod lint needs network access to trunk; it is the only check that proves the 3.11.0 pod resolves.)

- [ ] **Step 8: Commit**

```bash
bun run fmt
git add Package.swift CapgoCapacitorPersona.podspec ios/Sources/PersonaPlugin/PersonaPlugin.swift
git commit -m "feat(ios): upgrade Persona Inquiry SDK to 3.11.0

Pin PersonaInquirySDK2 3.11.0 in Package.swift and the podspec. Build
templateVersion inquiries with Inquiry.from(templateVersion:) now that
InquiryConfiguration is gone, which also lifts the iOS-only restriction
on locale with templateVersion. Adopt the typed
InquiryDelegate.inquiryError(_ error: PersonaError) signature.

Refs #8

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Surface Persona error codes on iOS (test-first)

Android already fills `errorCode` and `cause` on `inquiryError`. With `PersonaError` typed, iOS can too. The mapping lives in its own file so it is unit-testable without a bridge or view controller.

**Files:**
- Create: `ios/Sources/PersonaPlugin/PersonaErrorMapper.swift`
- Create: `ios/Tests/PersonaPluginTests/PersonaErrorMapperTests.swift`
- Delete: `ios/Tests/PersonaPluginTests/PersonaPluginTests.swift`
- Modify: `ios/Sources/PersonaPlugin/PersonaPlugin.swift` (`inquiryError`)

**Interfaces:**
- Produces: `enum PersonaErrorMapper { static func code(for error: PersonaError) -> String; static func payload(for error: PersonaError) -> [String: Any] }`. Payload keys: `error: String` (always), `errorCode: String` (always), `cause: String` (only for `.misconfigured`). These are the exact keys of `InquiryErrorInfo` in `src/definitions.ts`.
- Consumed by: `PersonaPlugin.inquiryError(_:)`.

- [ ] **Step 1: Write the failing tests**

Create `ios/Tests/PersonaPluginTests/PersonaErrorMapperTests.swift`:

```swift
import XCTest
import Persona2
@testable import PersonaPlugin

final class PersonaErrorMapperTests: XCTestCase {
    func testNetworkingErrorProducesMessageAndCodeWithoutCause() {
        let payload = PersonaErrorMapper.payload(for: .networking)

        XCTAssertEqual(payload["errorCode"] as? String, "networking")
        XCTAssertEqual(payload["error"] as? String, PersonaError.networking.debugDescription)
        XCTAssertFalse((payload["error"] as? String ?? "").isEmpty)
        XCTAssertNil(payload["cause"])
    }

    func testMisconfiguredErrorCarriesConfigurationDetailAsCause() {
        let detail = InquiryConfigurationError.invalidTemplateId("itmpl_bad")

        let payload = PersonaErrorMapper.payload(for: .misconfigured(detail))

        XCTAssertEqual(payload["errorCode"] as? String, "misconfigured")
        XCTAssertEqual(payload["cause"] as? String, detail.localizedDescription)
        XCTAssertFalse((payload["cause"] as? String ?? "").isEmpty)
    }

    func testEveryKnownCaseMapsToAStableCode() {
        let expectations: [(PersonaError, String)] = [
            (.networking, "networking"),
            (.invalidSessionToken, "invalidSessionToken"),
            (.oneTimeLinkCodeInvalid, "oneTimeLinkCodeInvalid"),
            (.rateLimitExceeded, "rateLimitExceeded"),
            (.camera, "camera"),
            (.gps, "gps"),
            (.permissions, "permissions"),
            (.misconfigured(.serverConfiguration), "misconfigured"),
            (.other, "other")
        ]

        for (error, expectedCode) in expectations {
            XCTAssertEqual(PersonaErrorMapper.code(for: error), expectedCode, "\(error)")
        }
    }
}
```

Delete the placeholder:

```bash
git rm ios/Tests/PersonaPluginTests/PersonaPluginTests.swift
```

- [ ] **Step 2: Run the tests and confirm they fail to compile**

```bash
xcodebuild test -scheme CapgoCapacitorPersona \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 \
  | grep -E 'error:|TEST (SUCCEEDED|FAILED)' | sort -u
```

Expected: `error: cannot find 'PersonaErrorMapper' in scope` and `** TEST FAILED **`.

Note: CI's `verify:ios` only builds for `generic/platform=iOS` and never runs XCTests, so this simulator run is the only place these tests execute. Keep running it locally. The command above was verified on 2026-10-11: the `CapgoCapacitorPersona` scheme includes the `PersonaPluginTests` target and the placeholder test ran green in about 16 seconds after the first build.

- [ ] **Step 3: Implement the mapper**

Create `ios/Sources/PersonaPlugin/PersonaErrorMapper.swift`:

```swift
import Foundation
import Persona2

/// Translates Persona's typed `PersonaError` into the `inquiryError` event payload.
///
/// Keys mirror `InquiryErrorInfo` in `src/definitions.ts`. `errorCode` values are the
/// `PersonaError` case names so JavaScript can switch on them; Android emits its own
/// SDK enum names, which is documented in `definitions.ts`.
enum PersonaErrorMapper {
    static func code(for error: PersonaError) -> String {
        switch error {
        case .networking:
            return "networking"
        case .invalidSessionToken:
            return "invalidSessionToken"
        case .oneTimeLinkCodeInvalid:
            return "oneTimeLinkCodeInvalid"
        case .rateLimitExceeded:
            return "rateLimitExceeded"
        case .camera:
            return "camera"
        case .gps:
            return "gps"
        case .permissions:
            return "permissions"
        case .misconfigured:
            return "misconfigured"
        case .other:
            return "other"
        @unknown default:
            return "unknown"
        }
    }

    static func payload(for error: PersonaError) -> [String: Any] {
        var payload: [String: Any] = [
            "error": error.debugDescription,
            "errorCode": code(for: error)
        ]

        if case .misconfigured(let configurationError) = error {
            payload["cause"] = configurationError.localizedDescription
        }

        return payload
    }
}
```

`@unknown default` is required: `Persona2` is built with library evolution, so `PersonaError` is non-frozen and Swift warns on an otherwise-exhaustive switch.

- [ ] **Step 4: Run the tests and confirm they pass**

```bash
xcodebuild test -scheme CapgoCapacitorPersona \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 \
  | grep -E 'Test Case.*(passed|failed)|Executed|TEST (SUCCEEDED|FAILED)'
```

Expected: three `passed` lines, `Executed 3 tests, with 0 failures`, `** TEST SUCCEEDED **`.

- [ ] **Step 5: Wire the mapper into the delegate**

In `ios/Sources/PersonaPlugin/PersonaPlugin.swift`, replace the `inquiryError` body from Task 2 with:

```swift
    public func inquiryError(_ error: PersonaError) {
        notifyListeners("inquiryError", data: PersonaErrorMapper.payload(for: error))
    }
```

- [ ] **Step 6: Build for device and lint**

```bash
bun run verify:ios 2>&1 | grep -E 'warning:|error:|BUILD'
bun run swiftlint -- lint
```

Expected: `** BUILD SUCCEEDED **`, no `error:`/`warning:` lines from plugin sources, 0 SwiftLint violations.

- [ ] **Step 7: Commit**

```bash
bun run fmt
git add ios/Sources/PersonaPlugin/PersonaErrorMapper.swift ios/Tests/PersonaPluginTests/
git add ios/Sources/PersonaPlugin/PersonaPlugin.swift
git commit -m "feat(ios): include errorCode and cause in inquiryError events

Map every PersonaError case to a stable errorCode string and attach the
InquiryConfigurationError description as cause for misconfigured
inquiries, matching the fields Android already reports.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Update the TypeScript contract documentation

No type shapes change. Two JSDoc blocks become accurate again, and `bun run build` regenerates the README API section from them.

**Files:**
- Modify: `src/definitions.ts:41-46`, `src/definitions.ts:104-111`
- Regenerated: `README.md` (docgen section only)

- [ ] **Step 1: Fix the `locale` doc comment (lines 41-46)**

Replace:

```ts
  /**
   * Locale override, for example `en`, `fr`, `es`.
   *
   * Not supported on iOS when `templateVersion` is used.
   */
  locale?: string;
```

with:

```ts
  /**
   * Locale override, for example `en`, `fr`, `es`.
   *
   * Supported with `inquiryId`, `templateId`, and `templateVersion` on both platforms
   * (iOS support for `templateVersion` requires plugin 8.2.0 or newer).
   */
  locale?: string;
```

- [ ] **Step 2: Document `errorCode` and `cause` (lines 104-111)**

Replace:

```ts
/**
 * Payload emitted when an Inquiry errors.
 */
export interface InquiryErrorInfo {
  error: string;
  errorCode?: string;
  cause?: string;
}
```

with:

```ts
/**
 * Payload emitted when an Inquiry errors.
 */
export interface InquiryErrorInfo {
  /**
   * Human-readable description from the Persona SDK.
   */
  error: string;

  /**
   * Stable, platform-specific code.
   *
   * iOS (Persona SDK 3.x) emits the `PersonaError` case name: `networking`,
   * `invalidSessionToken`, `oneTimeLinkCodeInvalid`, `rateLimitExceeded`, `camera`,
   * `gps`, `permissions`, `misconfigured`, `other`, or `unknown` for cases added by a
   * newer SDK.
   *
   * Android (Persona SDK 2.x) emits the SDK `ErrorCode` enum name, for example
   * `NetworkError`, `CameraPermissionError`, `SdkConfigurationError`, `SessionTokenError`,
   * `RateLimitExceeded`, `InvalidOneTimeLinkCode`, `UnexpectedError`.
   */
  errorCode?: string;

  /**
   * Additional detail when available. On iOS this is the `InquiryConfigurationError`
   * description for `misconfigured` errors; on Android it is the SDK `cause` string.
   */
  cause?: string;
}
```

- [ ] **Step 3: Build, lint, and check the generated README**

```bash
bun run build
bun run lint
git diff --stat README.md
git diff README.md | grep -E '^\+.*(Supported with|Stable, platform-specific)' | head -2
```

Expected: `tsc` and Rollup succeed, `lint` exits 0, `README.md` shows changes only inside the `<docgen-api>` section, and both new doc strings appear in the diff.

- [ ] **Step 4: Commit**

```bash
git add src/definitions.ts README.md
git commit -m "docs(definitions): describe errorCode values and iOS locale support

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Update hand-written README setup sections

Only the prose outside the docgen markers is edited here.

**Files:**
- Modify: `README.md:23`, `README.md:79-94`, `README.md:96-111`; add a new subsection before `## API` (line 113)

- [ ] **Step 1: Update the feature bullet (line 23)**

```markdown
- Native Persona SDK integration on iOS (`PersonaInquirySDK2` 3.x) and Android (`com.withpersona.sdk2:inquiry` 2.x)
```

- [ ] **Step 2: Rewrite the iOS setup section (lines 79-94)**

Replace the whole `## iOS setup` section with:

```markdown
## iOS setup

1. Run `npx cap sync ios`.
2. Ensure the iOS deployment target is **15.0** or newer (matches the plugin podspec and `Package.swift`).
3. Build with **Xcode 26.2 or newer**. Persona 3.x ships as a binary XCFramework whose Swift interface is produced by a current Swift 6 toolchain; older Xcode releases are not verified.
4. Add usage descriptions to `ios/App/App/Info.plist`. Persona requires camera and location strings for every template, and microphone when a template records video:

```xml
<key>NSCameraUsageDescription</key>
<string>We use the camera to verify your identity.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location during identity verification.</string>
<key>NSMicrophoneUsageDescription</key>
<string>We use the microphone when a verification records video.</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>We use Bluetooth during identity verification when required.</string>
```

Templates that use NFC additionally need `NFCReaderUsageDescription`, the NFC Tag Reading capability, and the ISO7816 application identifiers listed in Persona's [iOS integration guide](https://docs.withpersona.com/ios-sdk-v2-integration-guide).

5. Dependency resolution: Swift Package Manager projects (the Capacitor 8 default) resolve `inquiry-ios-2` at exactly **3.11.0** through the plugin `Package.swift`. CocoaPods projects resolve the `PersonaInquirySDK2` **3.11.0** pod (Persona resumed CocoaPods publishing with 3.8.0).
```

- [ ] **Step 3: Update the Android SDK line (line 111)**

```markdown
3. The plugin library targets **minSdk 24** and depends on `com.withpersona.sdk2:inquiry` (default **2.59.1**, overridable with `personaInquiryVersion` in Gradle). Versions 2.56.0 and newer are published to Maven Central only; the Persona Maven repository above still serves older pins.
```

(The Gradle default itself changes in Task 6; this doc line and that change land in the same PR, so the README never claims a version the plugin does not ship.)

- [ ] **Step 4: Add an upgrade note before `## API`**

```markdown
## Upgrading from 8.1.x

Plugin 8.2.0 moves iOS to Persona Inquiry SDK 3.11.0 and Android to 2.59.1. No JavaScript changes are required.

- `inquiryError` events on iOS now include `errorCode` (and `cause` for misconfigured inquiries); see `InquiryErrorInfo` below.
- `locale` now works together with `templateVersion` on iOS.
- iOS builds need Xcode 26.2 or newer.
- Persona removed client-side theming in SDK 3; configure appearance in the Persona Dashboard Theme Editor.
```

- [ ] **Step 5: Lint and verify the docgen section is untouched**

```bash
bun run prettier -- --check
git diff README.md | grep -E '^[-+]' | grep -vE '^(\+\+\+|---)' | awk 'NR==1,/<docgen-index>/' | wc -l
```

Expected: Prettier passes; the diff contains no lines between `<docgen-index>` and `</docgen-api>` (open the diff and confirm by eye as well).

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: document Persona SDK 3.x setup, Xcode requirement, and 8.2.0 upgrade notes

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Android parity bump and SDK pin drift guard

Two small, independent changes that keep the two platforms and the two iOS manifests in step.

**Files:**
- Modify: `android/build.gradle:7`
- Create: `scripts/check-persona-sdk-pin.mjs`
- Modify: `package.json` (scripts, after line 52)
- Modify: `.github/workflows/test.yml` (after lines 44, 75, 102)

**Interfaces:**
- Produces: `bun run check:persona-pin`, exit 0 when `Package.swift` `exact:` and the podspec `s.dependency 'PersonaInquirySDK2', '<v>'` agree, exit 1 with both values printed otherwise. Also prints the Android default for visibility.

- [ ] **Step 1: Bump the Android default**

`android/build.gradle` line 7:

```groovy
    personaInquiryVersion = project.findProperty('personaInquiryVersion') ?: '2.59.1'
```

- [ ] **Step 2: Build and run Android unit tests**

```bash
bun run verify:android 2>&1 | grep -E 'BUILD|FAILED|error:|warning:.*PersonaPlugin' | tail -5
```

Expected: `BUILD SUCCESSFUL`, no compiler errors or deprecation warnings in `PersonaPlugin.java`. Gradle must log resolution of `com.withpersona.sdk2:inquiry:2.59.1` from `repo1.maven.org` (run with `--info` and grep `inquiry-2.59.1` if you need to see it).

- [ ] **Step 3: Write the drift guard's failing check**

Create a mismatched fixture in the scratchpad and run the not-yet-existing script so the failure mode is known:

```bash
bun run check:persona-pin
```

Expected: `error: Missing script "check:persona-pin"`.

- [ ] **Step 4: Create the script**

`scripts/check-persona-sdk-pin.mjs`:

```js
#!/usr/bin/env node
/**
 * Persona SDK pin guard.
 *
 * Fails when Package.swift and the podspec disagree on the PersonaInquirySDK2 version,
 * which happens when a dependency bot updates one manifest but not the other.
 *
 * Usage:
 *   node scripts/check-persona-sdk-pin.mjs
 *   node scripts/check-persona-sdk-pin.mjs --dir path/to/plugin
 */

import { readFileSync } from 'node:fs';
import path from 'node:path';

function parseArgs(argv) {
  const out = { dir: process.cwd() };
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--dir') out.dir = path.resolve(argv[++i] || '.');
  }
  return out;
}

const { dir } = parseArgs(process.argv);

const packageSwift = readFileSync(path.join(dir, 'Package.swift'), 'utf8');
const podspec = readFileSync(path.join(dir, 'CapgoCapacitorPersona.podspec'), 'utf8');
const gradle = readFileSync(path.join(dir, 'android', 'build.gradle'), 'utf8');

const spmVersion = /inquiry-ios-2\.git"\s*,\s*exact:\s*"([^"]+)"/.exec(packageSwift)?.[1];
const podVersion = /s\.dependency\s+'PersonaInquirySDK2'\s*,\s*'([^']+)'/.exec(podspec)?.[1];
const androidDefault = /personaInquiryVersion\s*=\s*project\.findProperty\('personaInquiryVersion'\)\s*\?:\s*'([^']+)'/.exec(gradle)?.[1];

const errors = [];
if (!spmVersion) errors.push('Package.swift: could not find an exact: pin for inquiry-ios-2');
if (!podVersion) errors.push("podspec: could not find s.dependency 'PersonaInquirySDK2', '<version>'");
if (!androidDefault) errors.push('android/build.gradle: could not find the personaInquiryVersion default');
if (spmVersion && podVersion && spmVersion !== podVersion) {
  errors.push(`iOS pins differ: Package.swift=${spmVersion} podspec=${podVersion}`);
}

if (errors.length) {
  console.error('[persona-pin] FAIL');
  for (const e of errors) console.error(`- ${e}`);
  process.exit(1);
}

console.log(`[persona-pin] OK iOS PersonaInquirySDK2 ${spmVersion}, Android com.withpersona.sdk2:inquiry default ${androidDefault}`);
```

Add to `package.json` scripts, directly after `"check:cap9-deprecated"`:

```json
    "check:persona-pin": "node scripts/check-persona-sdk-pin.mjs",
```

- [ ] **Step 5: Prove the guard passes on the repo and fails on a mismatch**

```bash
bun run check:persona-pin
# expected: [persona-pin] OK iOS PersonaInquirySDK2 3.11.0, Android com.withpersona.sdk2:inquiry default 2.59.1

FIX=/private/tmp/claude-501/-Users-parlaybillm3-code-ParlayPlay-capacitor-persona/cd1a7e03-0017-4580-ba54-6c13b86a989e/scratchpad/pin-fixture
rm -rf "$FIX" && mkdir -p "$FIX/android"
cp Package.swift "$FIX/" && cp android/build.gradle "$FIX/android/"
sed "s/'3.11.0'/'3.10.0'/" CapgoCapacitorPersona.podspec > "$FIX/CapgoCapacitorPersona.podspec"
node scripts/check-persona-sdk-pin.mjs --dir "$FIX"; echo "exit=$?"
# expected: "- iOS pins differ: Package.swift=3.11.0 podspec=3.10.0" and exit=1
```

- [ ] **Step 6: Run the guard in CI**

In `.github/workflows/test.yml`, add this step immediately after each `run: bun run check:cap9-deprecated` (three places: `build_android`, `build_ios`, `web`):

```yaml
      - name: Check Persona SDK pins
        run: bun run check:persona-pin
```

- [ ] **Step 7: Lint and commit**

```bash
bun run fmt
bun run lint
git add android/build.gradle scripts/check-persona-sdk-pin.mjs package.json .github/workflows/test.yml
git commit -m "feat(android): bump Persona Inquiry SDK default to 2.59.1 and guard iOS pin drift

Android has no SDK v3; 2.59.1 is the current release and is source
compatible with the existing bridge. Add check:persona-pin so Package.swift
and the podspec can never ship different Persona versions.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: Full verification and example-app smoke test

The plan ends with this task. Nothing is pushed.

**Files:** none modified unless verification finds a defect.

- [ ] **Step 1: Run every CI check locally**

```bash
bun run check:package-identity && bun run check:wiring && bun run check:cap9-deprecated && bun run check:persona-pin
bun run lint
bun run verify            # ios, android, web in sequence
bash .github/scripts/verify-packed-example.sh web
bash .github/scripts/verify-packed-example.sh android
bash .github/scripts/verify-packed-example.sh ios
```

Expected: every command exits 0. The iOS packed-example step must show `Checking out 3.11.0 of package 'inquiry-ios-2'` and `** BUILD SUCCEEDED **`. (`RUNNER_TEMP` is unset locally, so the script uses `mktemp -d`; the three runs are independent.)

- [ ] **Step 2: Manual smoke test on the iOS simulator with a sandbox template**

```bash
cd example-app && bun install && bun run build
bunx cap add ios        # first time only
bunx cap sync ios
bunx cap open ios
```

In Xcode, add the Info.plist keys from the README to `App/App/Info.plist`, run on `iPhone 17 Pro`, then in the web UI:

| Scenario | Inputs | Expected output in the `plugin-output` panel |
| --- | --- | --- |
| Happy path | real sandbox `templateId`, environment `sandbox`, default fields | `startInquiry launched`, Persona UI opens, then `inquiryComplete` with `inquiryId`, `status`, `fields` after finishing, or `inquiryCanceled` after dismissing |
| Review Focus 1 | `templateId` = `itmpl_doesnotexist`, environment `sandbox` | `inquiryError` with `errorCode: "misconfigured"`, non-empty `error`, non-empty `cause` |
| Review Focus 2 | `templateVersion` (paste a real `itmplv_...` into the Template ID field after temporarily changing `options.templateId` to `options.templateVersion` in `src/main.js`), plus `locale` `fr` added to `options` | Persona UI opens in French; no `locale option is not supported` rejection |
| Review Focus 3 | `inquiryId` + `sessionToken` + environment `sandbox` | `Error: The environment option cannot be used when resuming an inquiry by inquiryId.` |

Revert any temporary `src/main.js` edits afterwards (`git checkout example-app/src/main.js`).

- [ ] **Step 3: Android smoke test (same table)**

```bash
cd example-app && bunx cap add android && bunx cap sync android
python3 ../.github/scripts/patch-persona-example-android.py .
bunx cap open android
```

Run on an API 34+ emulator and repeat the four scenarios. Android `errorCode` for Review Focus 1 is `SdkConfigurationError` or `IntegrationError` (SDK enum name), not `misconfigured`; that difference is documented in `definitions.ts`.

- [ ] **Step 4: Confirm the commit series and version expectations**

```bash
git log --oneline main..HEAD | head -12
git diff main...HEAD --stat | tail -1
grep '"version"' package.json      # still 8.1.1; CI bumps to 8.2.0 on merge
```

At least one `feat(...)` commit exists (Tasks 2, 3, 6), none carries `!` or `BREAKING CHANGE`.

- [ ] **Step 5: Stop here. Do not push.**

The author has no push access to `Cap-go/capacitor-persona` and no fork exists yet, so the plan ends with the commits on the local `billpull/persona-v3-upgrade` branch. Confirm nothing has left the machine:

```bash
git remote -v                                 # only origin -> Cap-go/capacitor-persona
git log origin/main..HEAD --oneline           # the 7 restore commits plus this plan's 5 commits, all local
git status --short                            # empty
```

**Later, outside this plan, once a fork exists:** `gh repo fork Cap-go/capacitor-persona --remote --remote-name fork`, push the branch to `fork`, and open the PR with `--head <github-user>:billpull/persona-v3-upgrade` against `cursor/restore-persona-plugin-afcd` while PR #7 is open, retargeting to `main` after #7 merges, with `Closes #8` in the body. Two consequences of a fork PR: `test.yml` still runs on `pull_request` so CI coverage is unchanged, but the `/publish-beta` workflow refuses fork PRs because it needs repository secrets. The 8.2.0 tag and npm publish happen only when a maintainer merges to `main`.

---

## Deferred follow-ups (not in this plan)

Both SDK versions chosen here expose these on both platforms; each is an additive minor release on its own:

- `environmentId` (pin a specific sandbox environment) on template builders.
- `host: 'fedramp'` via `PersonaHost.fedramp` (iOS) / `PersonaHost.FedRamp` (Android).
- New entry points `oneTimeLinkCode` and `relaySessionToken`.
- `shareToken` + `fieldMappings`, `redirectUri`, `styleVariant`.
- An `inquiryEvent` listener forwarding `InquiryDelegate.inquiryEventOccurred` (`start` with `inquiryId`/`sessionToken`, `pageChange` with `name`/`path`) and the Android equivalent.
- Lowering Android `minSdk` from 24 to the SDK's 23 (needs a Capacitor-level decision; Capacitor 8 itself requires 23).
- Extracting `startInquiry` option parsing on iOS into a pure, testable type so Review Focus items 2 and 3 become XCTests rather than manual checks.

## Self-review notes

- Spec coverage: issue #8 asks for iOS v3 and a release bump. Tasks 2-3 deliver v3; versioning is handled by CI through `feat:` commits (Global Constraints), confirmed in Task 7 Step 4. The PR itself is out of scope until a fork exists (Task 7 Step 5).
- Placeholder scan: none; every step has concrete code or commands.
- Type consistency: `PersonaErrorMapper.code(for:)` and `payload(for:)` are the only new symbols and are used with those exact names in Task 3 Steps 1, 3, 5. Payload keys `error`, `errorCode`, `cause` match `InquiryErrorInfo` in Task 4.
- Review Focus: items 1 and 4 are pinned by automated checks (Task 3 tests, Task 2 pod lint, Task 6 guard); items 2, 3, 5 are pinned by documented manual checks in Task 7 and the README statement in Task 5. Converting 2 and 3 to XCTests is listed as a follow-up.
