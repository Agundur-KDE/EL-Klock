pragma ComponentBehavior: Bound
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import "Days.js" as Days

KCM.SimpleKCM {
    id: page
    property var cfg_SelectedDays: []
    property alias cfg_InvasionAlerts: invasions.checked
    property alias cfg_InvasionSound: sound.checked

    InvasionSound { id: previewHorn }
    property alias cfg_ShowSeconds: seconds.checked
    property alias cfg_PollSeconds: polling.value

    function toggleDay(name, checked) {
        let next = cfg_SelectedDays.filter(function(day) { return Days.key(day) !== Days.key(name); });
        if (checked) next.push(name);
        cfg_SelectedDays = next;
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        Kirigami.FormLayout {
            QQC2.CheckBox {
                id: seconds
                text: i18n("Show seconds")
                Kirigami.FormData.label: i18n("Clock:")
            }
            QQC2.SpinBox {
                id: polling
                from: 15
                to: 300
                stepSize: 15
                editable: true
                Kirigami.FormData.label: i18n("Refresh interval (seconds):")
            }
            QQC2.CheckBox {
                id: invasions
                text: i18n("Notify about new invasion warnings")
                Kirigami.FormData.label: i18n("Invasions:")
            }
            RowLayout {
                QQC2.CheckBox {
                    id: sound
                    objectName: "invasionSoundCheck"
                    enabled: invasions.checked
                    text: i18n("Play a warning sound")
                }
                QQC2.Button {
                    text: i18n("Test sound")
                    icon.name: "audio-volume-high"
                    onClicked: previewHorn.playWarning()
                }
            }
        }
        Kirigami.Separator { Layout.fillWidth: true }
        Kirigami.Heading { level: 3; text: i18n("Special Day notifications") }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: i18n("Choose the days you want to hear about. Notifications start with the next change; opening EL-Klock during an existing day stays silent.")
        }
        QQC2.TextField {
            id: search
            objectName: "daySearch"
            Layout.fillWidth: true
            placeholderText: i18n("Find a Special Day…")
            Accessible.name: placeholderText
        }
        RowLayout {
            QQC2.Button {
                objectName: "selectAllDays"
                text: i18n("Select all")
                onClicked: page.cfg_SelectedDays = Days.catalog.map(function(day) { return day.name; })
            }
            QQC2.Button { objectName: "clearDays"; text: i18n("Clear selection"); onClicked: page.cfg_SelectedDays = [] }
            QQC2.Label { text: i18n("%1 selected", page.cfg_SelectedDays.length) }
        }
        Repeater {
            model: Days.catalog
            delegate: QQC2.CheckBox {
                required property var modelData
                objectName: "day-" + Days.key(modelData.name)
                Layout.fillWidth: true
                visible: modelData.name.toLowerCase().indexOf(search.text.toLowerCase()) !== -1
                text: modelData.name
                checked: Days.selected(modelData.name, page.cfg_SelectedDays)
                onClicked: page.toggleDay(modelData.name, checked)
            }
        }
        QQC2.Button {
            text: i18n("Special Days in the EL Wiki")
            icon.name: "help-browser"
            onClicked: Qt.openUrlExternally("https://el-wiki.holy-eternalland.de/index.php?title=Special_Days")
        }
    }
}
