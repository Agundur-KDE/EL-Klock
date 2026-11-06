// SPDX-License-Identifier: GPL-3.0-only
// Pure data and alarm rules, shared with the Qt Quick tests.
var staleAfter = 180000;
var warningMaxAge = 900000;
var futureTolerance = 60000;

function integer(value, min, max) {
    if (value === null || value === undefined || String(value).trim() === "")
        throw new Error("missing value");
    var number = Number(value);
    if (!Number.isInteger(number) || number < min || number > max)
        throw new Error("invalid number");
    return number;
}

function timestamp(value) {
    var n = Number(value);
    return Number.isFinite(n) && n > 0 ? n : 0;
}

function normalize(payload) {
    var raw = payload && (payload.eldata || payload);
    if (!raw || typeof raw !== "object") throw new Error("missing payload");
    var day = integer(raw.GameDay, 1, 30);
    var month = integer(raw.GameMonth, 1, 12);
    var year = integer(raw.GameYear, 1, 99999);
    var hour = integer(raw.GameHour, 0, 5);
    var minute = integer(raw.GameMinute, 0, 59);
    var second = integer(raw.GameSecond, 0, 59);
    // Gametimestamp belongs to the clock sample; Timestamp is the JSON generation time.
    var clockStamp = timestamp(raw.Gametimestamp);
    var stamp = timestamp(raw.Timestamp);
    if (!clockStamp || !stamp) throw new Error("missing timestamp");
    var name = String(raw.GameDayName || "").trim();
    if (!name) throw new Error("missing day name");
    return {
        day: day, month: month, year: year,
        seconds: hour * 3600 + minute * 60 + second,
        clockStamp: clockStamp, stamp: stamp,
        name: name, description: String(raw.GameDayDescription || ""),
        rolePlay: String(raw.GameDayRolePlay || ""),
        monsters: integer(raw.GIWS_Monsters, 0, 10000000),
        invasionText: String(raw.GIWS_Text || "").trim(),
        invasionStamp: timestamp(raw.GIWS_date_diff)
    };
}

function fresh(data, now) {
    if (!data) return false;
    return [data.stamp, data.clockStamp].every(function(stamp) {
        var age = now - stamp;
        return age >= -futureTolerance && age <= staleAfter;
    });
}

function normalDay(name) {
    return /^(normal day|ordinary day|today is an ordinary day:?)$/i.test(String(name).trim());
}

function dayKey(data) {
    return [data.year, data.month, data.day, data.name.toLowerCase()].join("/");
}

function invasionKey(data) {
    return data.invasionText ? String(data.invasionStamp) + "/" + data.invasionText : "";
}

function recentInvasion(data, now) {
    var age = now - data.invasionStamp;
    return fresh(data, now) && !!data.invasionText && data.invasionStamp > 0
        && age >= -futureTolerance && age <= warningMaxAge;
}

function pad(value) { return value < 10 ? "0" + value : String(value); }

function clock(data, now, showSeconds) {
    if (!fresh(data, now)) return "--:--";
    var elapsed = Math.max(0, Math.floor((now - data.clockStamp) * 60 / 61000));
    var seconds = data.seconds + elapsed;
    // Do not silently carry an old Special Day into a new EL day.
    if (seconds >= 21600) return "--:--";
    return pad(Math.floor(seconds / 3600)) + ":" + pad(Math.floor(seconds / 60) % 60)
        + (showSeconds ? ":" + pad(seconds % 60) : "");
}

function escapeMarkup(value) {
    return String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// Always establish a silent baseline on startup, including after restarts.
// Within the running instance, unchanged samples and reconnects stay silent.
function transition(data, state, now, selectedNames, invasionsEnabled, soundEnabled) {
    if (!fresh(data, now)) return { state: state, special: false, invasion: false, invasionSound: false };
    var dk = dayKey(data);
    var ik = invasionKey(data);
    var eligible = selectedNames.some(function(name) {
        return String(name).trim().toLowerCase() === data.name.trim().toLowerCase();
    });
    var changedDay = state.initialized && dk !== state.day;
    var result = {
        special: changedDay && eligible && !normalDay(data.name),
        invasion: state.initialized && invasionsEnabled && ik !== state.invasion
            && recentInvasion(data, now),
        state: { initialized: true, day: dk, invasion: ik }
    };
    result.invasionSound = !!(result.invasion && soundEnabled);
    return result;
}
