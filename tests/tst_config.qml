import QtQuick
import QtTest
import "../package/contents/ui/Days.js" as Days

TestCase {
    id: testCase
    name: "SpecialDayChecklist"
    when: windowShown
    width: 780
    height: 650
    visible: true

    function openConfig() {
        const configComponent = Qt.createComponent("../package/contents/ui/configGeneral.qml");
        compare(configComponent.status, Component.Ready, configComponent.errorString());
        const page = createTemporaryObject(configComponent, testCase, { width: 760, height: 640 });
        verify(page !== null);
        wait(30);
        return page;
    }

    function test_checkAndUncheckUpdatesConfigWithoutLosingOtherDays() {
        const page = openConfig();
        const search = findChild(page, "daySearch");
        verify(search !== null, "Search must be accessible to the UI test");
        page.cfg_SelectedDays = ["Day of Sun Tzu"];
        search.text = "Reconstruction";
        wait(50);
        const box = findChild(page, "day-reconstruction day");
        verify(box !== null, "Reconstruction checkbox must exist");
        tryCompare(box, "visible", true);
        verify(!box.checked);
        mouseClick(box);
        verify(Days.selected("Reconstruction Day", page.cfg_SelectedDays));
        verify(Days.selected("Day of Sun Tzu", page.cfg_SelectedDays));
        // The binding must survive the user click and a config reload.
        page.cfg_SelectedDays = ["Day of Sun Tzu"];
        tryCompare(box, "checked", false);
        page.cfg_SelectedDays = ["Day of Sun Tzu", "Reconstruction Day"];
        tryCompare(box, "checked", true);
        mouseClick(box);
        verify(!Days.selected("Reconstruction Day", page.cfg_SelectedDays));
        compare(page.cfg_SelectedDays.length, 1);
    }

    function test_soundLoadsOnlyOnDemand() {
        const component = Qt.createComponent("../package/contents/ui/InvasionSound.qml");
        compare(component.status, Component.Ready, component.errorString());
        const horn = createTemporaryObject(component, testCase);
        compare(horn.active, false);
    }
    Component {
        id: fakeAudio
        QtObject {
            property int plays: 0
            property int stops: 0
            function play() { plays++; }
            function stop() { stops++; }
        }
    }
    function test_soundStartsOnceAndRestartsWithoutOverlap() {
        const component = Qt.createComponent("../package/contents/ui/InvasionSound.qml");
        const horn = createTemporaryObject(component, testCase, {sourceComponent: fakeAudio});
        verify(horn !== null);
        horn.playWarning();
        verify(horn.active);
        compare(horn.item.plays, 1);
        compare(horn.item.stops, 0);
        horn.playWarning();
        compare(horn.item.plays, 2);
        compare(horn.item.stops, 1);
    }
    function test_optionalInvasionSoundSetting() {
        const page = openConfig();
        const sound = findChild(page, "invasionSoundCheck");
        verify(sound !== null, "Sound option must be present");
        page.cfg_InvasionAlerts = true;
        page.cfg_InvasionSound = false;
        tryCompare(sound, "checked", false);
        mouseClick(sound);
        compare(page.cfg_InvasionSound, true);
        page.cfg_InvasionAlerts = false;
        tryCompare(sound, "enabled", false);
        page.cfg_InvasionAlerts = true;
        tryCompare(sound, "checked", true);
        mouseClick(sound);
        compare(page.cfg_InvasionSound, false);
    }
    function test_selectAllClearAndFilteringPreserveSelection() {
        const page = openConfig();
        const all = findChild(page, "selectAllDays");
        const clear = findChild(page, "clearDays");
        const search = findChild(page, "daySearch");
        verify(all !== null && clear !== null && search !== null);
        mouseClick(all);
        compare(page.cfg_SelectedDays.length, Days.catalog.length);
        search.text = "Sun Tzu";
        compare(page.cfg_SelectedDays.length, Days.catalog.length);
        mouseClick(clear);
        compare(page.cfg_SelectedDays.length, 0);
    }
}
