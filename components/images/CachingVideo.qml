import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.services

Item {
    id: root

    property string path
    property var screen
    property bool isFirstInstance: false

    property alias playing: mediaPlayer.playing
    property alias playbackState: mediaPlayer.playbackState

    AudioOutput {
        id: audioOutput
    }

    MediaPlayer {
        id: mediaPlayer

        source: path || ""
        videoOutput: videoOutput
        loops: MediaPlayer.Infinite
        autoPlay: true
        audioOutput: audioOutput
    }

    VideoOutput {
        id: videoOutput

        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop

        Component.onDestruction: {
            mediaPlayer.stop();
        }
    }

    property var bgConfig: GlobalConfig?.background

    function checkPauseState() {
        if (!root.screen)
            return;

        if (bgConfig?.videoWallpaperPaused) {
            if (mediaPlayer.playing)
                mediaPlayer.pause();
            return;
        }

        const pauseOnAllDisplays = bgConfig?.videoWallpaperPauseOnAllDisplays ?? false;
        const pauseOnFullscreen = bgConfig?.videoWallpaperPauseOnFullscreen ?? false;
        const pauseOnTiled = bgConfig?.videoWallpaperPauseOnTiled ?? false;

        let shouldPause = false;

        if (pauseOnAllDisplays) {
            let anyFullscreen = false;
            let anyTiled = false;
            for (const monitor of Hypr.monitors.values) {
                const toplevels = monitor?.activeWorkspace?.toplevels?.values || [];
                if (pauseOnFullscreen && toplevels.some(t => t?.lastIpcObject?.fullscreen > 1))
                    anyFullscreen = true;
                if (pauseOnTiled && toplevels.some(t => !t?.lastIpcObject?.floating && !t?.lastIpcObject?.fullscreen))
                    anyTiled = true;
            }
            shouldPause = anyFullscreen || anyTiled;
        } else {
            const monitor = Hypr.monitorFor(root.screen);
            if (!monitor)
                return;

            const toplevels = monitor.activeWorkspace?.toplevels?.values || [];

            if (pauseOnFullscreen && toplevels.some(t => t?.lastIpcObject?.fullscreen > 1))
                shouldPause = true;
            if (pauseOnTiled && toplevels.some(t => !t?.lastIpcObject?.floating && !t?.lastIpcObject?.fullscreen))
                shouldPause = true;
        }

        if (shouldPause && mediaPlayer.playing) {
            mediaPlayer.pause();
        } else if (!shouldPause && !mediaPlayer.playing && root.path) {
            mediaPlayer.play();
        }
    }

    function checkMuteState() {
        const muteOnMedia = bgConfig?.videoWallpaperMuteOnMedia ?? false;
        const soundEnabled = bgConfig?.videoWallpaperSoundEnabled ?? false;
        const isPlaying = Players.active?.isPlaying ?? false;

        audioOutput.muted = !root.isFirstInstance || !soundEnabled || (muteOnMedia && isPlaying);
    }

    Timer {
        id: mediaCheckTimer
        interval: 500
        running: bgConfig?.videoWallpaperMuteOnMedia ?? false
        repeat: true
        onTriggered: checkMuteState()
    }

    Timer {
        id: checkTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            checkPauseState();
            checkMuteState();
        }
    }

    Connections {
        target: bgConfig
        function onVideoWallpaperPausedChanged() {
            checkPauseState();
        }
        function onVideoWallpaperPauseOnAllDisplaysChanged() {
            checkPauseState();
        }
        function onVideoWallpaperPauseOnFullscreenChanged() {
            checkPauseState();
        }
        function onVideoWallpaperPauseOnTiledChanged() {
            checkPauseState();
        }
        function onVideoWallpaperMuteOnMediaChanged() {
            checkMuteState();
        }
        function onVideoWallpaperSoundEnabledChanged() {
            checkMuteState();
        }
    }

    Component.onCompleted: {
        isFirstInstance = (VideoWallpaperPlayer.firstInstance === null);
        VideoWallpaperPlayer.firstInstance = root;
        Qt.callLater(checkPauseState);
        Qt.callLater(checkMuteState);
    }

    Component.onDestruction: {
        if (VideoWallpaperPlayer.firstInstance === root) {
            VideoWallpaperPlayer.firstInstance = null;
        }
    }

    onPathChanged: {
        mediaPlayer.source = path || "";
        if (path)
            mediaPlayer.play();
    }
}
