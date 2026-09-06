function parseCaptureEvent(name, data) {
  if (String(name || "") !== "screencastv2") return null

  var raw = String(data || "")
  var first = raw.indexOf(",")
  if (first < 0) return null
  var second = raw.indexOf(",", first + 1)
  var state = raw.slice(0, first).trim()
  if (state !== "0" && state !== "1") return null

  return {
    starting: state === "1",
    kind: (second < 0 ? raw.slice(first + 1) : raw.slice(first + 1, second)).trim(),
    label: second < 0 ? "" : raw.slice(second + 1).trim()
  }
}

function applyCaptureEvent(sessions, event) {
  var next = Array.isArray(sessions) ? sessions.slice() : []
  if (!event) return next
  if (event.starting) {
    next.push({ kind: event.kind, label: event.label })
    return next
  }

  var match = -1
  for (var i = 0; i < next.length; i++) {
    if (next[i].kind === event.kind && next[i].label === event.label) {
      match = i
      break
    }
  }
  if (match < 0) {
    for (var j = 0; j < next.length; j++) {
      if (next[j].kind === event.kind) {
        match = j
        break
      }
    }
  }
  if (match >= 0) next.splice(match, 1)
  return next
}

function captureLabel(sessions) {
  var list = Array.isArray(sessions) ? sessions : []
  if (list.length === 0) return ""
  var first = list[0]
  var label = String(first.label || first.kind || "screen")
  return list.length > 1 ? label + " +" + (list.length - 1) : label
}

function durationLabel(totalSeconds) {
  var seconds = Math.max(0, Math.floor(Number(totalSeconds) || 0))
  var hours = Math.floor(seconds / 3600)
  var minutes = Math.floor((seconds % 3600) / 60)
  var rest = seconds % 60
  var mm = minutes < 10 ? "0" + minutes : String(minutes)
  var ss = rest < 10 ? "0" + rest : String(rest)
  return hours > 0 ? hours + ":" + mm + ":" + ss : minutes + ":" + ss
}

function sessionSnapshot(active, startedAtMs, activation, previousDnd, previousIdleEnabled, restoreDnd, restoreIdle) {
  return {
    version: 1,
    active: !!active,
    startedAtMs: Math.max(0, Number(startedAtMs) || 0),
    activation: String(activation || "manual"),
    previous: {
      dnd: !!previousDnd,
      idleEnabled: !!previousIdleEnabled
    },
    applied: {
      dnd: !!restoreDnd,
      idle: !!restoreIdle
    }
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    parseCaptureEvent: parseCaptureEvent,
    applyCaptureEvent: applyCaptureEvent,
    captureLabel: captureLabel,
    durationLabel: durationLabel,
    sessionSnapshot: sessionSnapshot
  }
}
