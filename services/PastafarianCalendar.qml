pragma Singleton

import QtQuick
import Quickshell
import qs.utils
import Caelestia

Singleton {
    id: root

    property var events: []

    function reload() {
        Requests.get("https://pastafariancalendar.com/holidays4.json", text => {
            try {
                events = JSON.parse(text);
            } catch (e) {
                console.error("Failed to parse Pastafarian calendar events:", e);
            }
        });
    }
}
