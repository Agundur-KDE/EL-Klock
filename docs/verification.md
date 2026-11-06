# Local verification — 2026-11-06

- Built with Qt 6.12 / KF6 6.31 on openSUSE Tumbleweed.
- CTest: all three targets passed (AppStream, metadata, Qt Quick).
- Qt Quick: 24 passed entries, including setup/cleanup; production parser/alarm tests and two real config UI tests.
- Observed the new 61-real-second game-minute test fail at 00:01:00 versus expected 00:00:59 before correcting the clock ratio. It passes afterwards.
- Config UI tests click real controls and cover checking/unchecking without losing other selections, reloading checkbox bindings, select-all, clear and search preserving selection.
- Source-loaded PlasmoidViewer, isolated Xvfb display: live game time and date, normal day, old invasion message labelled 10 hours old; no startup notification.
- In the real Plasma config dialog, searched for Sun Tzu, checked it, pressed Apply, then verified `SelectedDays=Day of Sun Tzu` in the isolated plasmoidviewer-appletsrc after the deferred write.
- CMake installation staged under .local/stage, including translation catalogs; no installation into the running desktop.
- qmllint exits successfully; remaining warnings concern injected i18n and dynamic KConfig properties (unqualified / missing-property). No structural QML warnings remain.
- German interface verified in the same isolated viewer with staged catalogs and LC_ALL=de_DE.UTF-8.
- No real new invasion or Special Day occurred during this development session. Alarm transitions are exercised by deterministic tests; live delivery on such an event remains to be observed.

Screenshots: [clock](preview.png), [configuration](config-preview.png).

## Optional invasion horn

- Added from the user-supplied MP3, copied unchanged into the package (10.704 seconds; MP3, 24 kHz stereo). Full decode with FFmpeg succeeded.
- Observed failing tests before adding the sound config and alarm condition. Tests now cover sound off, invasion alerts off, startup, duplicate, stale and old reports.
- UI test clicks the real sound checkbox and verifies its configuration binding and disabled state when invasion alerts are off.
- Audio playback is loaded only on demand. A test observed failing before that change now confirms no audio device opens when creating the config/widget. A fake audio target verifies first play and stop/restart without overlapping. No sound was played on the user's speakers during automated checks.
- Qt Multimedia QML runtime added to documented dependencies and CI setup.

## PlasmoidViewer terminal diagnostics reported by user

The user's normal viewer session printed desktopcontainment `isScreenUiReady` errors, `DeclarativeDropArea.enabled` override warnings, config delegate `undefined`→bool warnings, Kirigami BreadcrumbControl `globalDrawer` warnings and a SimpleKCM scene-placement warning. The first four point into installed KDE code. Local desktopcontainment calls `Plasmoid.containment.corona.isScreenUiReady(...)`; the viewer exposes a generic Plasma::Corona lacking that callable. This does not establish a defect in EL-Klock's parser or alarm rules. The scene-placement warning names our config component as the dynamically created object; its cause is not confirmed and should not be hidden by changing unrelated applet code.

Qt Multimedia then recognized the user-supplied MP3 as 10.70s, 24kHz stereo. `Estimating duration from bitrate` is an estimate notice; missing `libvdpau_nvidia.so` concerns an unavailable hardware backend, not an MP3 decode failure. That log alone does not prove audible playback; ask whether the Test Sound action was heard. Do not claim it was heard based only on media metadata.
