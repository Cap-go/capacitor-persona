#!/usr/bin/env python3
"""Patch a Capacitor example Android app for @capgo/capacitor-intune packed verify."""
from __future__ import annotations

import re
from pathlib import Path

DUO_URL = (
    "https://pkgs.dev.azure.com/MicrosoftDeviceSDK/DuoSDK-Public/"
    "_packaging/Duo-SDK-Feed/maven/v1"
)


def patch_repositories(build_gradle: Path) -> None:
    text = build_gradle.read_text()
    if "DuoSDK-Public" in text:
        return
    needle = """allprojects {
    repositories {
        google()
        mavenCentral()
    }
}"""
    insert = f"""allprojects {{
    repositories {{
        google()
        mavenCentral()
        maven {{
            url '{DUO_URL}'
        }}
    }}
}}"""
    if needle not in text:
        raise SystemExit(f"Could not patch repositories in {build_gradle}")
    build_gradle.write_text(text.replace(needle, insert, 1))
    print(f"Injected Duo SDK Maven repo into {build_gradle}")


def resolve_plugin_android() -> str:
    """Return plugin android path relative to android/ (matches capacitor.settings.gradle)."""
    cap_settings = Path("android/capacitor.settings.gradle")
    cap = cap_settings.read_text()
    match = re.search(
        r"include ':capgo-capacitor-intune'\s*\n"
        r"project\(':capgo-capacitor-intune'\)\.projectDir = new File\('([^']+)'\)",
        cap,
    )
    if not match:
        raise SystemExit(
            "capgo-capacitor-intune projectDir not found in capacitor.settings.gradle"
        )
    return match.group(1)


def patch_settings(settings: Path, plugin_android: str) -> None:
    text = settings.read_text()
    if "intune-mam-sdk" in text:
        return
    block = f"""
include ':intune-mam-sdk'
project(':intune-mam-sdk').projectDir = new File('{plugin_android}/intune-mam-sdk')
include ':intune-downlevel-stubs'
project(':intune-downlevel-stubs').projectDir = new File('{plugin_android}/intune-downlevel-stubs')
"""
    settings.write_text(text.rstrip() + "\n" + block)
    print(f"Included Intune AAR wrapper modules from {plugin_android}")


def patch_manifest(manifest: Path) -> None:
    text = manifest.read_text()
    perm = "android.permission.POST_NOTIFICATIONS"
    app_idx = text.find("<application")
    if app_idx < 0:
        raise SystemExit(f"No <application> in {manifest}")
    if perm in text and text.find(perm) < app_idx:
        return
    text = re.sub(
        r"\s*<uses-permission\s+android:name=\"android\.permission\.POST_NOTIFICATIONS\"\s*/>\s*",
        "\n",
        text,
    )
    app_idx = text.find("<application")
    injection = f'    <uses-permission android:name="{perm}" />\n\n'
    manifest.write_text(text[:app_idx] + injection + text[app_idx:])
    print(f"Added POST_NOTIFICATIONS before <application> in {manifest}")


def main() -> None:
    android = Path("android")
    plugin_android = resolve_plugin_android()
    patch_repositories(android / "build.gradle")
    patch_settings(android / "settings.gradle", plugin_android)
    patch_manifest(android / "app/src/main/AndroidManifest.xml")


if __name__ == "__main__":
    main()
