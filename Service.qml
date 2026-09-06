import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "ScrimModel.js" as ScrimModel

Item {
  id: root

  // Injected by omarchy-shell for service plugins.
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null

  property bool active: false
  property string activation: ""
  property double startedAtMs: 0
  property int elapsedSeconds: 0
  property bool previousDnd: false
  property bool previousIdleEnabled: true
  property bool restoreDnd: false
  property bool restoreIdle: false
  property var captureSessions: []

  property bool autoProtect: true
  property bool protectNotifications: true
  property bool keepAwake: true
  property int captureGraceMs: 1800

  property bool stateReady: false
  property bool hydrated: false
  property string pendingStateText: ""

  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
  readonly property string stateDir: stateHome + "/omarchy/plugins/scrim"
  readonly property string statePath: stateDir + "/session.json"
  readonly property var notificationService: shell && typeof shell.firstPartyServiceFor === "function"
    ? shell.firstPartyServiceFor("omarchy.notifications") : null
  readonly property var idleService: shell && typeof shell.firstPartyServiceFor === "function"
    ? shell.firstPartyServiceFor("omarchy.idle") : null
  readonly property bool dnd: notificationService ? notificationService.doNotDisturb === true : false
  readonly property bool idleEnabled: idleService ? idleService.idleEnabled === true : true
  readonly property bool capturing: captureSessions.length > 0
  readonly property string captureDescription: ScrimModel.captureLabel(captureSessions)
  readonly property string elapsedLabel: ScrimModel.durationLabel(elapsedSeconds)

  function configure(options) {
    var value = options || ({})
    if (value.autoProtect !== undefined) root.autoProtect = value.autoProtect !== false
    if (value.protectNotifications !== undefined) root.protectNotifications = value.protectNotifications !== false
    if (value.keepAwake !== undefined) root.keepAwake = value.keepAwake !== false
    if (value.captureGraceMs !== undefined) {
      root.captureGraceMs = Math.max(0, Math.min(10000, Number(value.captureGraceMs) || 0))
    }
  }

  function persistSession() {
    var snapshot = ScrimModel.sessionSnapshot(
      root.active,
      root.startedAtMs,
      root.activation,
      root.previousDnd,
      root.previousIdleEnabled,
      root.restoreDnd,
      root.restoreIdle
    )
    var text = JSON.stringify(snapshot, null, 2) + "\n"
    if (!root.stateReady) {
      root.pendingStateText = text
      return
    }
    sessionFile.setText(text)
  }

  function clearSession() {
    root.pendingStateText = ""
    if (root.stateReady) sessionFile.setText("")
  }

  function applyProtections() {
    if (root.protectNotifications && root.notificationService) {
      root.notificationService.setDoNotDisturb(true)
      if (typeof root.notificationService.clearPopups === "function") root.notificationService.clearPopups()
    }
    if (root.keepAwake && root.idleService) root.idleService.setIdleEnabled(false)
  }

  function beginSession(origin) {
    var requestedOrigin = String(origin || "manual")
    if (root.active) {
      if (requestedOrigin === "manual") root.activation = "manual"
      root.applyProtections()
      root.persistSession()
      return "active"
    }

    root.previousDnd = root.dnd
    root.previousIdleEnabled = root.idleEnabled
    root.restoreDnd = root.protectNotifications && root.notificationService !== null
    root.restoreIdle = root.keepAwake && root.idleService !== null
    root.activation = requestedOrigin
    root.startedAtMs = Date.now()
    root.elapsedSeconds = 0
    root.active = true
    root.applyProtections()
    root.persistSession()
    return "active"
  }

  function endSession() {
    if (!root.active) {
      root.clearSession()
      return "idle"
    }

    if (root.restoreDnd && root.notificationService)
      root.notificationService.setDoNotDisturb(root.previousDnd)
    if (root.restoreIdle && root.idleService)
      root.idleService.setIdleEnabled(root.previousIdleEnabled)

    root.active = false
    root.activation = ""
    root.startedAtMs = 0
    root.elapsedSeconds = 0
    root.restoreDnd = false
    root.restoreIdle = false
    root.clearSession()
    return "idle"
  }

  function toggleSession() {
    return root.active ? root.endSession() : root.beginSession("manual")
  }

  function adoptPersistedSession() {
    var text = String(sessionFile.text() || "").trim()
    if (text === "") return
    try {
      var saved = JSON.parse(text)
      if (!saved || saved.version !== 1 || saved.active !== true) return
      root.previousDnd = !!(saved.previous && saved.previous.dnd)
      root.previousIdleEnabled = !saved.previous || saved.previous.idleEnabled !== false
      root.restoreDnd = !saved.applied || saved.applied.dnd !== false
      root.restoreIdle = !saved.applied || saved.applied.idle !== false
      root.startedAtMs = Math.max(0, Number(saved.startedAtMs) || Date.now())
      root.activation = String(saved.activation || "manual")
      root.active = true
      root.elapsedSeconds = Math.max(0, Math.floor((Date.now() - root.startedAtMs) / 1000))
      root.applyProtections()
    } catch (error) {
      console.warn("scrim: could not restore session state:", error)
    }
  }

  function hydrateOnce() {
    if (root.hydrated) return
    root.hydrated = true
    root.adoptPersistedSession()
  }

  function statusJson() {
    return JSON.stringify({
      active: root.active,
      activation: root.activation,
      elapsedSeconds: root.elapsedSeconds,
      elapsed: root.elapsedLabel,
      capturing: root.capturing,
      capture: root.captureDescription,
      protections: {
        notifications: root.protectNotifications,
        keepAwake: root.keepAwake,
        dnd: root.dnd,
        idleEnabled: root.idleEnabled
      }
    })
  }

  FileView {
    id: sessionFile
    path: root.statePath
    blockLoading: true
    preload: true
    printErrors: false
    onLoaded: root.hydrateOnce()
  }

  Process {
    id: stateDirProcess
    command: ["mkdir", "-p", root.stateDir]
    running: true
    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) {
        console.warn("scrim: could not create state directory")
        return
      }
      root.stateReady = true
      if (root.pendingStateText !== "") {
        sessionFile.setText(root.pendingStateText)
        root.pendingStateText = ""
      } else {
        sessionFile.reload()
      }
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.active
    onTriggered: root.elapsedSeconds = Math.max(0, Math.floor((Date.now() - root.startedAtMs) / 1000))
  }

  Timer {
    id: captureGrace
    interval: root.captureGraceMs
    repeat: false
    onTriggered: {
      if (root.autoProtect && root.capturing) root.beginSession("capture")
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event) return
      var parsed = ScrimModel.parseCaptureEvent(event.name, event.data)
      if (!parsed) return
      root.captureSessions = ScrimModel.applyCaptureEvent(root.captureSessions, parsed)

      if (root.capturing) {
        if (root.autoProtect && !root.active) captureGrace.restart()
      } else {
        captureGrace.stop()
        if (root.active && root.activation === "capture") root.endSession()
      }
    }
  }

  IpcHandler {
    target: "scrim"

    function begin(origin: string): string { return root.beginSession(origin || "manual") }
    function end(): string { return root.endSession() }
    function toggle(): string { return root.toggleSession() }
    function status(): string { return root.statusJson() }
    function preflight(): string { return root.statusJson() }
  }

  Component.onCompleted: root.hydrateOnce()
}
