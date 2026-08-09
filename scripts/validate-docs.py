#!/usr/bin/env python3
"""Validate MobCrew's static GitHub Pages source without network access."""

from __future__ import annotations

import argparse
from html.parser import HTMLParser
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlparse


REQUIRED_METADATA = (
    "description",
    "og:title",
    "og:description",
    "og:url",
    "og:image",
    "twitter:card",
    "twitter:title",
    "twitter:description",
    "twitter:image",
)

STALE_CLAIMS = {
    "old global shortcut ⌘⇧M": re.compile(r"⌘⇧M", re.IGNORECASE),
    "full-screen break claim": re.compile(r"full[- ]screen break", re.IGNORECASE),
    "tip jar claim": re.compile(r"tip jar", re.IGNORECASE),
    "customizable hotkey claim": re.compile(r"customize timer and hotkeys", re.IGNORECASE),
    "five-minute default claim": re.compile(r"default 5 min", re.IGNORECASE),
    "unverified current-release architecture claim": re.compile(
        r"architectures? in the current public release remain unverified", re.IGNORECASE
    ),
    "Accessibility-required global shortcut claim": re.compile(
        r"(?:requires?|after granting|only so).{0,80}Accessibility(?: access| permission)?",
        re.IGNORECASE | re.DOTALL,
    ),
}


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.ids: set[str] = set()
        self.duplicate_ids: set[str] = set()
        self.references: list[tuple[str, str, int]] = []
        self.metadata: dict[str, str] = {}
        self.canonical: str | None = None
        self.images: list[tuple[dict[str, str], int]] = []
        self.svgs: list[tuple[dict[str, str], int]] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = {key: value or "" for key, value in attrs}
        line = self.getpos()[0]

        element_id = values.get("id")
        if element_id:
            if element_id in self.ids:
                self.duplicate_ids.add(element_id)
            self.ids.add(element_id)

        if tag in {"a", "link"} and values.get("href"):
            self.references.append(("href", values["href"], line))
        if tag in {"img", "script"} and values.get("src"):
            self.references.append(("src", values["src"], line))

        if tag == "meta":
            key = values.get("property") or values.get("name")
            if key:
                self.metadata[key] = values.get("content", "")
        elif tag == "link" and "canonical" in values.get("rel", "").split():
            self.canonical = values.get("href")
        elif tag == "img":
            self.images.append((values, line))
        elif tag == "svg":
            self.svgs.append((values, line))


def local_target(docs_root: Path, source: Path, reference: str) -> Path | None:
    parsed = urlparse(reference)
    if parsed.scheme or parsed.netloc:
        return None

    path = unquote(parsed.path)
    if not path:
        return source
    if path.startswith("/"):
        target = docs_root / path.lstrip("/")
    else:
        target = source.parent / path
    if target.is_dir() or path.endswith("/"):
        target /= "index.html"
    return target.resolve()


def validate(docs_root: Path) -> list[str]:
    errors: list[str] = []
    index = docs_root / "index.html"
    if not index.is_file():
        return [f"missing landing page: {index}"]

    parser = PageParser()
    html = index.read_text(encoding="utf-8")
    parser.feed(html)

    for duplicate in sorted(parser.duplicate_ids):
        errors.append(f"{index}: duplicate id #{duplicate}")

    for attribute, reference, line in parser.references:
        target = local_target(docs_root, index, reference)
        if target is not None and not target.is_file():
            errors.append(f"{index}:{line}: {attribute} target does not exist: {reference}")

        fragment = urlparse(reference).fragment
        if fragment and target == index.resolve() and fragment not in parser.ids:
            errors.append(f"{index}:{line}: fragment target does not exist: #{fragment}")

    for key in REQUIRED_METADATA:
        if not parser.metadata.get(key, "").strip():
            errors.append(f"{index}: missing metadata value: {key}")

    if parser.canonical != "https://mobcrew.team/":
        errors.append(f"{index}: canonical URL must be https://mobcrew.team/")

    if parser.metadata.get("og:url") != "https://mobcrew.team/":
        errors.append(f"{index}: og:url must be https://mobcrew.team/")

    social_path = "https://mobcrew.team/assets/images/social-preview.jpg"
    for key in ("og:image", "twitter:image"):
        if parser.metadata.get(key) != social_path:
            errors.append(f"{index}: {key} must reference {social_path}")
    if not (docs_root / "assets/images/social-preview.jpg").is_file():
        errors.append(f"{index}: social preview image does not exist")

    for attributes, line in parser.images:
        if "alt" not in attributes:
            errors.append(f"{index}:{line}: image is missing alt text")
        for dimension in ("width", "height"):
            value = attributes.get(dimension, "")
            if not value.isdigit() or int(value) <= 0:
                errors.append(f"{index}:{line}: image has invalid {dimension}: {value!r}")

    for attributes, line in parser.svgs:
        if attributes.get("aria-hidden") != "true":
            errors.append(f"{index}:{line}: decorative SVG must use aria-hidden=\"true\"")

    for required_id in ("main-content", "how-it-works", "features", "install", "faq"):
        if required_id not in parser.ids:
            errors.append(f"{index}: missing required section id #{required_id}")

    text_files = [
        path
        for path in docs_root.rglob("*")
        if path.is_file() and path.suffix.lower() in {".css", ".html", ".md", ".txt", ".xml"}
    ]
    repository_root = docs_root.parent
    text_files.extend(
        path for path in (repository_root / "README.md", repository_root / "TESTING.md") if path.is_file()
    )
    for path in text_files:
        content = path.read_text(encoding="utf-8")
        if "cdn.tailwindcss.com" in content:
            errors.append(f"{path}: runtime Tailwind CDN is not allowed")
        for description, pattern in STALE_CLAIMS.items():
            match = pattern.search(content)
            if match:
                line = content.count("\n", 0, match.start()) + 1
                errors.append(f"{path}:{line}: stale claim found ({description})")

    hotkey_source = repository_root / "MobCrew/MobCrew/Core/Services/GlobalHotkeyService.swift"
    settings_source = repository_root / "MobCrew/MobCrew/Features/Settings/SettingsView.swift"
    readme = repository_root / "README.md"
    if hotkey_source.is_file():
        source = hotkey_source.read_text(encoding="utf-8")
        required_definition = (
            "keyCode: UInt32(kVK_ANSI_L)",
            "modifiers: UInt32(cmdKey | shiftKey)",
            'displayName: "⌘⇧L"',
            'actionDescription: "Toggle floating timer"',
        )
        for fragment in required_definition:
            if fragment not in source:
                errors.append(f"{hotkey_source}: fixed shortcut definition is missing {fragment!r}")
        for stale_api in ("AXIsProcessTrusted", "ApplicationServices"):
            if stale_api in source:
                errors.append(f"{hotkey_source}: obsolete Accessibility dependency remains: {stale_api}")
    else:
        errors.append(f"missing global hotkey source: {hotkey_source}")

    if settings_source.is_file():
        settings = settings_source.read_text(encoding="utf-8")
        for fragment in (
            "GlobalHotkeyService.shortcut.displayName",
            "GlobalHotkeyService.shortcut.actionDescription",
        ):
            if fragment not in settings:
                errors.append(f"{settings_source}: Settings does not use {fragment}")

    if readme.is_file() and "**Global hotkey** - ⌘⇧L toggles the floating timer" not in readme.read_text(
        encoding="utf-8"
    ):
        errors.append(f"{readme}: global hotkey text does not match ⌘⇧L / Toggle floating timer")

    normalized_html = re.sub(r"\s+", " ", html)
    if not re.search(r"<kbd>⌘⇧L</kbd> to toggle the floating timer", normalized_html):
        errors.append(f"{index}: global hotkey text does not match ⌘⇧L / Toggle floating timer")

    for expected_file in ("assets/styles.css", "favicon.png", "robots.txt", "sitemap.xml"):
        if not (docs_root / expected_file).is_file():
            errors.append(f"{docs_root}: missing required static file: {expected_file}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "docs_root",
        nargs="?",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "docs",
    )
    args = parser.parse_args()
    docs_root = args.docs_root.resolve()
    errors = validate(docs_root)

    if errors:
        print("Documentation validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Documentation validation passed:")
    print("- local links, assets, and fragments resolve")
    print("- required search/social metadata is present")
    print("- images declare alternatives and intrinsic dimensions")
    print("- runtime Tailwind and known stale claims are absent")
    print("- app, Settings, README, and landing-page global shortcut text agrees")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
