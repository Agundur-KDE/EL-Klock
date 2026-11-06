// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import "ElData.js" as ElData

Item {
    id: source
    readonly property string endpoint: "https://mercator.holy-eternalland.de/botmanagement/elinfo.json"
    property int pollSeconds: 30
    property var sampleData: null
    property double now: Date.now()
    property bool busy: false
    property string errorCode: ""
    property double lastSuccess: 0
    property var request: null
    property bool active: true
    readonly property bool fresh: ElData.fresh(sampleData, now)
    signal sampleReceived(var sample)

    function refresh() {
        if (busy || !active) return;
        const xhr = new XMLHttpRequest();
        request = xhr;
        busy = true;
        deadline.restart();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || request !== xhr) return;
            deadline.stop();
            request = null;
            busy = false;
            now = Date.now();
            if (xhr.status !== 200) {
                errorCode = xhr.status ? "http" : "network";
                return;
            }
            try {
                const sample = ElData.normalize(JSON.parse(xhr.responseText));
                // Late or cached responses must never rewind the clock/alarm baseline.
                if (sampleData && sample.stamp < sampleData.stamp) return;
                sampleData = sample;
                lastSuccess = now;
                errorCode = ElData.fresh(sample, now) ? "" : "stale";
                sampleReceived(sample);
            } catch (error) {
                errorCode = "invalid";
            }
        };
        xhr.open("GET", endpoint);
        xhr.setRequestHeader("Accept", "application/json");
        xhr.send();
    }

    Timer {
        id: deadline
        interval: 10000
        onTriggered: {
            const xhr = source.request;
            source.request = null;
            source.busy = false;
            source.errorCode = "network";
            if (xhr) xhr.abort();
        }
    }
    Timer {
        interval: Math.max(15, source.pollSeconds) * 1000
        running: source.active
        repeat: true
        triggeredOnStart: true
        onTriggered: source.refresh()
    }
    Timer {
        interval: 1000
        running: source.active
        repeat: true
        onTriggered: source.now = Date.now()
    }
    Component.onDestruction: {
        const xhr = request;
        request = null;
        if (xhr) xhr.abort();
    }
}
