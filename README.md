# EL-Klock

An Eternal Lands clock for KDE Plasma 6, with Special Day notifications and invasion warnings from [Mercator](https://mercator.holy-eternalland.de/api). No account or personal token is required.

- Panel: game time with a status icon; click to open details. Vertical panels show the icon and put the time in the tooltip.
- Desktop / popup: game date, current day and description, last invasion report and its age.
- Settings: choose individual Special Days from a searchable checklist, toggle invasion warnings and the optional horn sound, seconds and polling interval (default 30 seconds).
- English interface with German translation; day names and reports retain their original game text.

## Preview and install

```bash
plasmoidviewer -a package/
```

For installation without translations:

```bash
kpackagetool6 --type Plasma/Applet --install package/
# After changes:
kpackagetool6 --type Plasma/Applet --upgrade package/
```

For installation including translations:

```bash
cmake -B build -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build build -j2
cmake --install build
```

Then add **EL-Klock** via Plasma's widget browser. Build dependencies and CI container are inherited from the [Agundur KDE template](https://github.com/Agundur-KDE/KDE-Plasma-Plasmoid-template): CMake, ECM, Qt 6.7+ Quick/Test/QuickTest and KF6 6.10+ Config/I18n/KCMUtils. Runtime also requires the KDE Notifications QML module and Qt Multimedia QML (`qt6-multimedia-imports` on openSUSE).

## Notifications

No Special Days are selected initially. Open settings, check the days you care about and apply. Day names come from the [EL Wiki](https://el-wiki.holy-eternalland.de/index.php?title=Special_Days); Day of Alchemy was also observed in Mercator's history. Matching ignores capitalization, including `Reconstruction day` versus `Reconstruction Day`. This bundled list does not fetch the wiki at runtime.

Starting the widget establishes a silent baseline, even if a selected day or invasion warning already exists. Subsequent changes trigger notifications; repeated samples remain silent. Invasions can be enabled separately. New GIWS reports qualify only if their timestamp is at most 15 minutes old and not more than a minute in the future. A recent report is not proof that an invasion is still running. The widget always shows the report's age and does not turn “in ~10 minutes” into a countdown.

Desktop popups use KDE's standard Plasma Workspace notification event. Its settings and Do Not Disturb apply; EL-Klock does not force critical-priority notifications. The optional **Play a warning sound** setting plays the bundled horn once per accepted new invasion warning; it is off by default and disabled together with invasion alerts. **Test sound** previews it on demand, independently of that checkbox. The horn uses Qt Multimedia and the normal system audio output, independently of Plasma notification muting / Do Not Disturb; mute it with the EL-Klock sound checkbox or the system audio controls. There is no background service: the widget must be loaded in Plasma to monitor events. Each widget instance monitors separately.

## Data and clock behavior

The source is `https://mercator.holy-eternalland.de/botmanagement/elinfo.json`. The documented `/_elday/clock-data` proxy returned zero-filled data during development and is not used. Zero-filled / malformed responses are rejected.

The game clock uses `Gametimestamp` as its sample reference, advances 60 game seconds per 61 real seconds and has a six-game-hour day (6 hours 6 minutes of real time), following the [EL Wiki timekeeping rules](https://el-wiki.holy-eternalland.de/index.php?title=Time_Keeping). At day rollover it waits for a new sample instead of carrying an old day's name forward. After three minutes without fresh source timestamps the clock shows `--:--`, and alarms are suppressed. Last known information remains visible as outdated. Network requests time out after ten seconds and retry at the configured interval.

Invasions use `GIWS_Text` and the absolute millisecond timestamp `GIWS_date_diff`; the field name is misleading. `GIWS_Monsters` is displayed as the reported count rather than used as the only trigger: advance warnings can have a zero count. API availability, accuracy and polling latency limit how quickly alarms arrive. Manual or other invasions not reported by this feed cannot be detected.

Personal-token endpoints (messages, watchlists, account identity) are outside this first version.

## Development and verification

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j2
QT_QPA_PLATFORM=offscreen ctest --test-dir build --output-on-failure
qmllint6 package/contents/ui/*.qml
./Messages.sh
```

The Qt Quick tests exercise the actual production parser and alarm rules, including null proxy values, stale and future timestamps, day rollover, selected days, startup, duplicates and old invasion reports. `qmllint` cannot statically resolve Plasma's injected `i18n` context and dynamic KConfig keys; runtime preview is also necessary.

`tools/preview-check.sh` starts a temporary Xvfb display and a source-loaded PlasmoidViewer using temporary isolated configuration. It saves `docs/preview.png` and `docs/config-preview.png`; it does not install the widget or alter the running desktop.

Template findings are collected in [docs/template-improvements.md](docs/template-improvements.md) for a later upstream pass. The template repository is kept as the `template` Git remote. Development repository: `Agundur-KDE/EL-Klock` (private).
