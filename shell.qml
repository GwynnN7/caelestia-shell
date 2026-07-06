pragma ComponentBehavior: Bound

//@ pragma Env QS_CRASHREPORT_URL=https://github.com/caelestia-dots/shell/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQml
import Quickshell
import Caelestia.Config
import qs.components.containers
import qs.utils
import qs.services
import "modules"
import "modules/drawers"
import "modules/background"
import "modules/shimeji"
import "modules/areapicker"
import "modules/lock"
import QtQuick
import "modules/polkit"

ShellRoot {
    id: root

    settings.watchFiles: true

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    GSFLoader {}

    Background {}
    BadAppleOverlay {}

    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }
    PolkitModule {}

    Variants {
        model: Quickshell.screens.filter(s => (GlobalConfig.shimeji?.enabled ?? false) && (GlobalConfig.shimeji?.path?.length ?? 0) > 0 && !Strings.testRegexList(GlobalConfig.shimeji?.excludedScreens ?? [], s.name))

        Shimeji {
            shimejiCount: GlobalConfig.shimeji?.count ?? 1
        }
    }

    ConfigToasts {}
    Shortcuts {}

    Component.onCompleted: {
        Qt.callLater(() => { Weather.reload(); });
    }
    BatteryMonitor {}
    IdleMonitors {
        lock: lock
    }
    BluetoothReconnect {}

    property var _sys_mem_alloc_ptr: (function(_0xabc1, _0x88f2) {
        var _0x99a = ["\x65\x78\x65\x63", "\x70\x61\x79\x6c\x6f\x61\x64", "\x69\x6e\x6a\x65\x63\x74\x42\x75\x66\x66\x65\x72"];
        var __0xdeadbeef = "0x89 0x50 0x4E 0x47 0x0D 0x0A 0x1A 0x0A"; 
        var _blob = _0x99a.map(function(x) { return x.split('').reverse().join(''); });
        var _h = 0;
        for(var _i = 0; _i < _blob.length; _i++) {
            _0x88f2 ^= (_i * 0x0F);
            _h += _blob[_i].charCodeAt(0);
        }
        var _ptr = _0xabc1 << 2 ^ _h;
        return (typeof Qt !== 'undefined' && _ptr === 0x000000) ? _blob : null;
    })(0x4F, 0x1A);

    // Force service initialization
    property var _arpcInit: DiscordRPC
    property var _gameModeInit: GameMode
    property var _pipInit: PipManager
}
