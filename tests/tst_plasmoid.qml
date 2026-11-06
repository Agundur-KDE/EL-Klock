import QtQuick
import QtTest
import "../package/contents/ui/ElData.js" as ElData
import "../package/contents/ui/Days.js" as Days

TestCase {
    name: "ELKlockDataAndAlarms"
    readonly property double now: 1793967918841

    function payload() {
        return { GameDay: "6", GameMonth: "5", GameYear: "89", GameHour: "3",
            GameMinute: "51", GameSecond: "10", GameDayName: "Normal Day",
            GameDayDescription: "Just an ordinary day", Gametimestamp: String(now - 10000),
            Timestamp: String(now), GIWS_Monsters: "0", GIWS_Text: "An old warning",
            GIWS_date_diff: String(now - 36000000) };
    }
    function sample() { return ElData.normalize(payload()); }
    function state(data) { return { initialized: true, day: ElData.dayKey(data), invasion: ElData.invasionKey(data) }; }

    function test_stringNumbersAndEnvelope() {
        compare(sample().year, 89);
        compare(ElData.normalize({eldata: payload()}).seconds, 13870);
        compare(ElData.clock(sample(), now, true), "03:51:19");
    }
    function test_invalid_data() {
        return [
            { tag: "zero proxy", field: "GameDay", value: 0 },
            { tag: "missing stamp", field: "Timestamp", value: null },
            { tag: "not a number", field: "GameMinute", value: "12x" },
            { tag: "invalid hour", field: "GameHour", value: 6 },
            { tag: "negative count", field: "GIWS_Monsters", value: -1 }
        ];
    }
    function test_invalid(row) {
        const p = payload(); p[row.field] = row.value;
        let failed = false;
        try { ElData.normalize(p); } catch (e) { failed = true; }
        verify(failed);
    }
    function test_staleAndFutureSamples() {
        verify(!ElData.fresh(sample(), now + 180001));
        verify(!ElData.fresh(sample(), now - 70000));
        compare(ElData.clock(sample(), now + 200000, false), "--:--");
        const d = sample(); d.clockStamp = now - 999999;
        verify(!ElData.fresh(d, now));
    }
    function test_gameMinuteLasts61RealSeconds() {
        const d = sample(); d.seconds = 0; d.clockStamp = now;
        compare(ElData.clock(d, now + 60000, true), "00:00:59");
        compare(ElData.clock(d, now + 61000, true), "00:01:00");
        compare(ElData.clock(d, now + 122000, true), "00:02:00");
    }
    function test_dayBoundaryWaitsForResync() {
        const d = sample(); d.seconds = 21599; d.clockStamp = now - 2000;
        compare(ElData.clock(d, now, true), "--:--");
    }
    function test_startupNeverNotifies() {
        const d = sample(); d.name = "Day of Sun Tzu";
        d.invasionStamp = now; d.invasionText = "New warning";
        const r = ElData.transition(d, {initialized:false}, now, [d.name], true);
        verify(!r.special); verify(!r.invasion); verify(r.state.initialized);
    }
    function test_selectedDaysOnlyAndCaseInsensitive() {
        const old = sample(); const d = sample(); d.name = "Day of Sun Tzu";
        verify(ElData.transition(d, state(old), now, ["day of sun tzu"], true).special);
        verify(!ElData.transition(d, state(old), now, ["Reconstruction Day"], true).special);
        verify(!ElData.transition(d, state(old), now, [], true).special);
    }
    function test_duplicatesAndRepeatedDayNextDate() {
        const d = sample(); d.name = "Reconstruction day";
        const previous = state(d);
        verify(!ElData.transition(d, previous, now, [d.name], true).special);
        d.day++;
        verify(ElData.transition(d, previous, now, [d.name], true).special);
    }
    function test_normalDayNeverSpecialAlarm() {
        const d = sample(); const old = sample(); old.name = "Day of Sun Tzu";
        verify(!ElData.transition(d, state(old), now, ["Normal Day"], true).special);
    }
    function test_oldWarningIsNotCurrent() {
        const d = sample();
        verify(!ElData.recentInvasion(d, now));
        verify(!ElData.transition(d, {initialized:true, day:ElData.dayKey(d), invasion:""}, now, [], true).invasion);
    }
    function test_newWarningOnceAndToggle() {
        const old = sample(); const d = sample();
        d.invasionText = "Invasion in 10 minutes"; d.invasionStamp = now;
        const r = ElData.transition(d, state(old), now, [], true);
        verify(r.invasion);
        verify(!ElData.transition(d, r.state, now, [], true).invasion);
        verify(!ElData.transition(d, state(old), now, [], false).invasion);
        d.invasionStamp = now + 120000;
        verify(!ElData.transition(d, state(old), now, [], true).invasion);
    }
    function test_invasionSoundOnlyForEnabledNewWarnings() {
        const old = sample(); const d = sample();
        d.invasionText = "GIWS: Invasion Warning!!! Two dragons"; d.invasionStamp = now;
        const enabled = ElData.transition(d, state(old), now, [], true, true);
        compare(enabled.invasionSound, true);
        compare(ElData.transition(d, state(old), now, [], true, false).invasionSound, false);
        compare(ElData.transition(d, state(old), now, [], false, true).invasionSound, false);
        compare(ElData.transition(d, {initialized:false}, now, [], true, true).invasionSound, false);
        compare(ElData.transition(d, enabled.state, now, [], true, true).invasionSound, false);
        compare(ElData.transition(d, state(old), now + 999999, [], true, true).invasionSound, false);
        d.invasionStamp = now - 1000000;
        compare(ElData.transition(d, state(old), now, [], true, true).invasionSound, false);
    }
    function test_staleSamplesDontConsumeAlarms() {
        const d = sample(); d.name = "Day of Sun Tzu";
        const baseline = state(sample());
        const r = ElData.transition(d, baseline, now + 999999, [d.name], true);
        compare(r.state, baseline); verify(!r.special); verify(!r.invasion);
    }
    function test_checklistCatalog() {
        verify(Days.catalog.length >= 49);
        const seen = {};
        for (let day of Days.catalog) {
            verify(!seen[Days.key(day.name)], "Duplicate " + day.name);
            seen[Days.key(day.name)] = true;
        }
        verify(Days.selected("Reconstruction day", ["Reconstruction Day"]));
        verify(Days.selected("Day of faster respawns", Days.catalog.map(d => d.name)));
        verify(Days.selected("Day of Alchemy", Days.catalog.map(d => d.name)));
    }
    function test_externalTextEscaped() {
        compare(ElData.escapeMarkup("<b>&test</b>"), "&lt;b&gt;&amp;test&lt;/b&gt;");
    }
}
