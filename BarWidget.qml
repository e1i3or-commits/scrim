pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "scrim"

  readonly property var service: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor("scrim") : null
  readonly property bool active: service ? service.active === true : false
  readonly property bool showWhenIdle: setting("showWhenIdle", true)
  readonly property var audioSource: Pipewire.defaultAudioSource
  readonly property bool microphoneMuted: !audioSource || !audioSource.audio || audioSource.audio.muted === true
  readonly property var pipewireNodes: Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property var microphoneStreams: {
    var result = []
    for (var i = 0; i < pipewireNodes.length; i++) {
      var node = pipewireNodes[i]
      if (node && node.isStream && node.isSink === false && node.audio && !node.audio.muted) result.push(node)
    }
    return result
  }
  readonly property bool microphoneInUse: microphoneStreams.length > 0 && !microphoneMuted
  readonly property string microphoneStatus: microphoneMuted ? "MUTED" : (microphoneInUse ? "LIVE" : "READY")

  function configureService() {
    if (!root.service) return
    root.service.configure({
      autoProtect: root.setting("autoProtect", true),
      protectNotifications: root.setting("protectNotifications", true),
      keepAwake: root.setting("keepAwake", true),
      captureGraceMs: root.setting("captureGraceMs", 1800)
    })
  }

  implicitWidth: button.visible ? button.implicitWidth : 0
  implicitHeight: button.visible ? button.implicitHeight : 0

  onServiceChanged: configureService()
  onSettingsChanged: configureService()
  Component.onCompleted: configureService()

  PwObjectTracker {
    objects: root.audioSource ? [root.audioSource] : []
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    visible: root.active || root.showWhenIdle
    text: root.active
      ? (root.vertical ? "󰹑" : "󰹑 LIVE  " + (root.service ? root.service.elapsedLabel : "0:00"))
      : "󰹐"
    active: root.active
    dimmed: !root.active
    tooltipText: root.active
      ? "Scrim is protecting this presentation — click for status"
      : "Scrim preflight — right click to start immediately"
    onPressed: function(mouseButton) {
      if (!root.service) return
      if (mouseButton === Qt.RightButton) root.service.toggleSession()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onActivateRequested: if (root.service) root.service.toggleSession()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)

        PanelHero {
          title: root.active ? "ON AIR" : "SCRIM"
          meta: root.active
            ? (root.service && root.service.captureDescription !== ""
                ? "SHARING " + root.service.captureDescription
                : "PRESENTATION MODE")
            : "SHARE THE STAGE, NOT YOUR DESKTOP"
          detail: root.active && root.service ? root.service.elapsedLabel : "PREFLIGHT"
          iconComponent: Component {
            Text {
              text: root.active ? "󰹑" : "󰹐"
              color: root.active ? Color.urgent : Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.display
            }
          }
        }

        PanelSeparator { foreground: root.barForeground }

        PanelSectionHeader {
          text: root.active ? "SESSION" : "PREFLIGHT"
          foreground: root.barForeground
        }

        Row {
          width: parent.width
          spacing: Style.space(10)

          Text {
            width: (parent.width - parent.spacing) / 2
            text: "󰂛  NOTIFICATIONS\n" + (root.service && root.service.protectNotifications
              ? (root.service.dnd ? "SILENCED" : "WILL SILENCE") : "UNCHANGED")
            color: root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Text {
            width: (parent.width - parent.spacing) / 2
            text: "󰍬  MICROPHONE\n" + root.microphoneStatus
            color: root.microphoneInUse ? Color.urgent : root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(10)

          Text {
            width: (parent.width - parent.spacing) / 2
            text: "󰒲  IDLE LOCK\n" + (root.service && root.service.keepAwake
              ? (root.service.idleEnabled ? "WILL PAUSE" : "PAUSED") : "UNCHANGED")
            color: root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Text {
            width: (parent.width - parent.spacing) / 2
            text: "󰄀  CAPTURE\n" + (root.service && root.service.capturing ? "DETECTED" : "STANDBY")
            color: root.service && root.service.capturing ? Color.urgent : root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }
        }

        PanelSeparator { foreground: root.barForeground }

        Button {
          width: parent.width
          text: root.active ? "End presentation" : "Start presentation"
          iconText: root.active ? "󰓛" : "󰐊"
          bordered: true
          foreground: root.barForeground
          onClicked: if (root.service) root.service.toggleSession()
        }

        Text {
          width: parent.width
          wrapMode: Text.WordWrap
          text: root.active
            ? "Scrim will restore the notification and idle settings that were active before this session."
            : "Starting Scrim applies the protections above. Automatic mode also starts after a sustained screen capture; ordinary screenshots are ignored."
          color: Qt.darker(root.barForeground, 1.5)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
