const assert = require("node:assert/strict")
const model = require("../ScrimModel.js")

const start = model.parseCaptureEvent("screencastv2", "1,monitor,DP-1")
assert.deepEqual(start, { starting: true, kind: "monitor", label: "DP-1" })

const commaTitle = model.parseCaptureEvent("screencastv2", "1,window,Deck, notes — Chromium")
assert.equal(commaTitle.label, "Deck, notes — Chromium")
assert.equal(model.parseCaptureEvent("workspace", "1"), null)
assert.equal(model.parseCaptureEvent("screencastv2", "wat,monitor,DP-1"), null)

let sessions = model.applyCaptureEvent([], start)
sessions = model.applyCaptureEvent(sessions, start)
assert.equal(sessions.length, 2)
sessions = model.applyCaptureEvent(sessions, model.parseCaptureEvent("screencastv2", "0,monitor,DP-1"))
assert.equal(sessions.length, 1)
assert.equal(model.captureLabel(sessions), "DP-1")

assert.equal(model.durationLabel(0), "0:00")
assert.equal(model.durationLabel(65), "1:05")
assert.equal(model.durationLabel(3661), "1:01:01")

assert.deepEqual(model.sessionSnapshot(true, 123, "manual", true, false, true, false), {
  version: 1,
  active: true,
  startedAtMs: 123,
  activation: "manual",
  previous: { dnd: true, idleEnabled: false },
  applied: { dnd: true, idle: false }
})

console.log("Scrim model tests passed")
