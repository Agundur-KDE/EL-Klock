pragma ComponentBehavior: Bound
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.notification
import "ElData.js" as ElData

PlasmoidItem {
    id: root
    readonly property bool onDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar
    readonly property var current: source.sampleData
    readonly property string timeText: ElData.clock(current, source.now, Plasmoid.configuration.ShowSeconds)
    readonly property bool live: source.fresh && timeText !== "--:--"
    readonly property bool special: live && !ElData.normalDay(current.name)
    readonly property bool invasion: live && ElData.recentInvasion(current, source.now)
    readonly property string stateIcon: !live ? "network-disconnect" : invasion ? "dialog-warning" : special ? "starred-symbolic" : "chronometer"
    readonly property color stateColor: !live ? Kirigami.Theme.disabledTextColor
        : invasion ? Kirigami.Theme.negativeTextColor : special ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
    property var alarmState: ({ initialized: false, day: "", invasion: "" })

    preferredRepresentation: onDesktop ? fullRepresentation : compactRepresentation
    Plasmoid.title: "EL-Klock"
    Plasmoid.icon: "chronometer"
    Plasmoid.status: invasion ? PlasmaCore.Types.NeedsAttentionStatus : PlasmaCore.Types.ActiveStatus
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    toolTipMainText: "EL-Klock · " + timeText
    toolTipSubText: live ? current.name + "\n" + current.description : statusText()
    toolTipTextFormat: Text.PlainText

    function statusText() {
        if (source.errorCode === "invalid") return i18n("Mercator returned invalid data.");
        if (source.errorCode === "network" || source.errorCode === "http") return i18n("Cannot reach Mercator. Retrying automatically.");
        if (current && !live) return i18n("Data is outdated. Waiting for a fresh update.");
        return i18n("Connecting to Mercator…");
    }

    function ageText(stamp) {
        if (!stamp) return i18n("Time unknown");
        const minutes = Math.max(0, Math.floor((source.now - stamp) / 60000));
        if (minutes === 0) return i18n("Just now");
        if (minutes < 60) return i18np("%1 minute ago", "%1 minutes ago", minutes);
        return i18np("%1 hour ago", "%1 hours ago", Math.floor(minutes / 60));
    }

    function notify(title, message) {
        notice.title = "EL-Klock · " + title;
        notice.text = ElData.escapeMarkup(message);
        notice.sendEvent();
    }

    Notification {
        id: notice
        // Available to source-loaded and kpackagetool-installed plasmoids alike.
        componentName: "plasma_workspace"
        eventId: "notification"
        iconName: "chronometer"
        autoDelete: false
    }

    InvasionSound { id: horn }

    MercatorSource {
        id: source
        pollSeconds: Plasmoid.configuration.PollSeconds
        onSampleReceived: function(sample) {
            const result = ElData.transition(sample, root.alarmState, source.now,
                Plasmoid.configuration.SelectedDays, Plasmoid.configuration.InvasionAlerts,
                Plasmoid.configuration.InvasionSound);
            root.alarmState = result.state;
            if (result.special) root.notify(sample.name, sample.description);
            if (result.invasion) root.notify(i18n("Invasion warning"), sample.invasionText);
            if (result.invasionSound) horn.playWarning();
        }
    }

    compactRepresentation: FocusScope {
        id: compact
        Layout.minimumWidth: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? 0 : compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? compactRow.implicitHeight : 0
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: root.toolTipMainText
        Accessible.description: root.toolTipSubText
        Accessible.onPressAction: root.expanded = !root.expanded
        Keys.onSpacePressed: root.expanded = !root.expanded
        Keys.onReturnPressed: root.expanded = !root.expanded

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon {
                source: root.stateIcon
                color: root.stateColor
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: width
            }
            PlasmaComponents.Label {
                text: root.timeText
                font.bold: true
                font.family: "monospace"
                visible: Plasmoid.formFactor !== PlasmaCore.Types.Vertical
                textFormat: Text.PlainText
            }
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Kirigami.Theme.highlightColor
            border.width: compact.activeFocus ? 1 : 0
            radius: Kirigami.Units.smallSpacing
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 22
        implicitHeight: Kirigami.Units.gridUnit * 27
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 24
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing
            RowLayout {
                Layout.fillWidth: true
                Kirigami.Icon {
                    source: root.stateIcon
                    color: root.stateColor
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: width
                }
                Kirigami.Heading { text: "EL-Klock"; level: 3; Layout.fillWidth: true }
                PlasmaComponents.ToolButton {
                    icon.name: "view-refresh"
                    text: i18n("Refresh")
                    display: QQC2.AbstractButton.IconOnly
                    enabled: !source.busy
                    onClicked: source.refresh()
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                }
                PlasmaComponents.ToolButton {
                    icon.name: "configure"
                    text: i18n("Configure")
                    display: QQC2.AbstractButton.IconOnly
                    onClicked: Plasmoid.internalAction("configure").trigger()
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: i18n("Eternal Lands time")
                    opacity: 0.7
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.timeText
                    font.pixelSize: Kirigami.Units.gridUnit * 2.7
                    font.family: "monospace"
                    font.weight: Font.Light
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.current ? i18n("Day %1 · Month %2 · Year %3", root.current.day, root.current.month, root.current.year) : "—"
                    opacity: root.live ? 0.7 : 0.4
                }
            }
            Kirigami.Separator { Layout.fillWidth: true }
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                clip: true
                ColumnLayout {
                    width: parent.width
                    spacing: Kirigami.Units.largeSpacing
                    PlasmaComponents.Label {
                        visible: !root.live || source.errorCode.length > 0
                        Layout.fillWidth: true
                        text: root.statusText()
                        wrapMode: Text.Wrap
                        color: Kirigami.Theme.neutralTextColor
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.current !== null
                        opacity: root.live ? 1 : 0.5
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: root.current ? root.current.name : ""
                            textFormat: Text.PlainText
                            font.bold: true
                            wrapMode: Text.Wrap
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: root.current ? root.current.description : ""
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                        }
                        PlasmaComponents.Label {
                            visible: root.current !== null && root.current.rolePlay.length > 0
                            Layout.fillWidth: true
                            text: root.current ? root.current.rolePlay : ""
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            opacity: 0.7
                            font.italic: true
                        }
                    }
                    Kirigami.Separator { Layout.fillWidth: true }
                    ColumnLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: root.invasion ? i18n("Recent invasion warning") : i18n("Last invasion report")
                            font.bold: true
                            color: root.invasion ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                            wrapMode: Text.Wrap
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: root.current && root.current.invasionText.length ? root.current.invasionText : i18n("No invasion report available.")
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            visible: root.current !== null && root.current.invasionText.length > 0
                            text: root.current ? root.ageText(root.current.invasionStamp) : ""
                            opacity: 0.6
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            visible: root.live && root.current.monsters > 0
                            text: root.current ? i18np("%1 monster reported", "%1 monsters reported", root.current.monsters) : ""
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: i18n("Source: Mercator")
                    opacity: 0.6
                    font: Kirigami.Theme.smallFont
                }
                PlasmaComponents.Button {
                    text: i18n("Open Mercator")
                    icon.name: "internet-services"
                    onClicked: Qt.openUrlExternally("https://mercator.holy-eternalland.de/")
                }
            }
        }
    }
}
