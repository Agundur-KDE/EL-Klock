# Template findings while building EL-Klock

Upstream: https://github.com/Agundur-KDE/KDE-Plasma-Plasmoid-template
Baseline: f064644 (2026-11-06). Collect here; implement and test upstream later.

## Reproduced

1. **Repository name is coupled to plugin ID.** `rename.sh` asks for lowercase project ID and derives the GitHub URL from it. `elklock` is the plugin ID, but the requested repository is `EL-Klock`. Add a separate repository-name prompt, defaulting to the ID. In EL-Klock the website / issue URLs were corrected manually.
2. **ID validation disagrees with metadata validation.** `rename.sh` accepts hyphens (`^[a-z][a-z0-9-]*$`), but `scripts/validate-metadata.py` rejects hyphens in reverse-domain segments. Reproduce with the suggested ID `my-sensor`. Decide the permitted IDs once and use the same validation in both tools.
3. **Display name passes through unescaped sed replacement.** The display-name prompt accepts `&`, `|` and backslashes; replacements interpolate the name directly. A name like `Clock & Alerts` expands `&` to the matched old name; `|` can break the expression. Escape replacement values, or use literal replacement in Python. Metadata's JSON write is safe, but other source text is affected.
4. **Translation scaffold is not release-ready.** Existing PO headers still contain YEAR / FULL NAME placeholders and all example translations are empty. `msgfmt --check` flags the headers after adapting the template. Document these as scaffolding or provide real sample translations and valid headers. EL-Klock supplies German strings and preserves other languages as untranslated scaffolds.
5. **Default full representation sizing is underspecified.** The source-loaded viewer starts the widget at its minimum size even with larger implicit dimensions. Document how initial desktop sizing is chosen: full-representation implicit and preferred dimensions alone did not change the 320×300 source-viewer default in this setup. EL-Klock uses useful minimum constraints as a fallback; investigate the appropriate root/applet sizing convention upstream. Also use `font.pointSize` with a point-based theme font, rather than assigning points to `font.pixelSize`.

6. **License metadata and license file disagree.** Metadata / existing QML headers offer the KDE GPL alternatives, while the root LICENSE contains LGPL v3. Align the intended project license and include the appropriate license texts. EL-Klock preserves the original template license and notices separately and labels its new code GPL-3.0-only.

## Documentation suggestions

- The inline-representations rule is too absolute. Separate QML files work if state and signals are passed explicitly through properties. Explain this option instead of implying every representation must remain inline.
- Mention that pure QML `kpackagetool6` installation does not install `ki18n_install` catalogs, whereas CMake installation does. Otherwise language testing from the source folder can be misleading.
- Add a small Qt Quick test that imports production logic. The example counter test duplicates state in its test fixture and stays green if the real counter breaks.
- Mention headless preview's D-Bus requirements separately from pure Qt Quick tests; offscreen alone is not sufficient in a restricted environment.

## Domain-specific finding (not an upstream template bug)

Mercator's bundled clock JavaScript advances one game second per real second. The EL Wiki specifies 60 game seconds per 61 real seconds. EL-Klock follows the Wiki ratio, guarded by a regression test that was observed failing before the correction. Do not copy the web clock's tick rate into other EL clients.

## Viewer diagnostics to document

A normal Wayland viewer session can print warnings from desktopcontainment (`isScreenUiReady` on generic Plasma::Corona), ConfigCategoryDelegate (`undefined` bool) and Kirigami BreadcrumbControl (missing globalDrawer). Keep a troubleshooting note distinguishing installed viewer/containment code from applet errors; a config component's filename in a scene-placement warning is not by itself proof its own QML caused the parenting issue. The isolated Xvfb preview did not emit these warnings, so that preview does not substitute for testing in the actual desktop session.
