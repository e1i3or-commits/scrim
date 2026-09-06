-- App routing for the labels managed by jankeesvw.workspace-name.
-- Rules target the underlying numeric workspace IDs; "silent" keeps a newly
-- opened app from pulling focus away from the workspace you are using.
--
--   1  browser
--   2  chat
--   3  code
--   4  focus     (intentionally unassigned)
--   5  personal

-- Browser: unclassified Chrome windows default to TourScale's workspace.
-- Profile-specific launchers route TourScale here and Personal to workspace 5
-- even though Chrome exposes the same Wayland class for both profiles.
o.window({ initial_class = "^google-chrome$" }, { workspace = "1 silent" })

-- Chat: Omarchy web apps for the configured Slack workspace and Discord.
o.window(
  { initial_class = "^.+-(tourscaleworkspace\\.slack\\.com|discord\\.com)__.*$" },
  { workspace = "2 silent" }
)

-- Code: graphical editor windows. Terminals remain free to open anywhere.
o.window({ initial_class = "^(Code|code)$" }, { workspace = "3 silent" })

-- Personal: native Spotify and the Omarchy YouTube web app.
o.window({ initial_class = "^spotify$" }, { workspace = "5 silent" })
o.window(
  { initial_class = "^.+-youtube\\.com__.*$" },
  { workspace = "5 silent" }
)
