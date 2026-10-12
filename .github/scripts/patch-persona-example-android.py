#!/usr/bin/env python3
"""Add Persona Android Maven repo to a generated Capacitor example app."""

from __future__ import annotations

import pathlib
import sys

PERSONA_MAVEN = "maven { url 'https://sdk.withpersona.com/android/releases' }"


def patch_build_gradle(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if "sdk.withpersona.com" in text:
        return False
    marker = "allprojects {\n    repositories {"
    if marker not in text:
        raise SystemExit(f"Could not find allprojects.repositories in {path}")
    replacement = f"{marker}\n        google()\n        mavenCentral()\n        {PERSONA_MAVEN}"
    # Replace the default allprojects block opening (google/mavenCentral only once).
    text = text.replace(
        marker + "\n        google()\n        mavenCentral()\n    }",
        replacement + "\n    }",
        1,
    )
    path.write_text(text, encoding="utf-8")
    return True


def main() -> None:
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    build_gradle = root / "android" / "build.gradle"
    if not build_gradle.is_file():
        raise SystemExit(f"Missing {build_gradle}")
    patch_build_gradle(build_gradle)


if __name__ == "__main__":
    main()
