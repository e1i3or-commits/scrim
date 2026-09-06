# Workspace routing

Personal Omarchy rules for five named workspaces:

| Workspace | Name | Routed apps |
| --- | --- | --- |
| 1 | browser | TourScale Chrome and other Chrome windows |
| 2 | chat | TourScale Slack and Discord web apps |
| 3 | code | VS Code |
| 4 | focus | intentionally unassigned |
| 5 | personal | Personal Chrome, Spotify, and YouTube |

Install the files into their matching locations under `~/.config/hypr`,
`~/.local/bin`, and `~/.local/share/applications`. Then add this beside the
other user configuration imports in `~/.config/hypr/hyprland.lua`:

```lua
require("hypr.workspaces")
```

Reload Hyprland with `hyprctl reload`.

The Chrome router is necessary because running profiles share the same
`google-chrome` Wayland class. It detects the new window by address and moves
it after launch. The configured profile directories are `Default` for
TourScale and `Profile 1` for Personal.
