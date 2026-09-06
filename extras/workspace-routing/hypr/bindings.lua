-- Open the workspace-name panel even when the current workspace has no label.
o.bind("SUPER + R", "Workspace name", "omarchy-shell shell toggle jankeesvw.workspace-name")

-- Chrome profiles have the same Wayland class, so launch them through a
-- profile-aware router that moves the newly opened window by address.
-- These replace Omarchy's two generic browser bindings.
hl.unbind("SUPER + SHIFT + RETURN")
hl.unbind("SUPER + SHIFT + B")
o.bind("SUPER + SHIFT + RETURN", "Chrome — TourScale", "omarchy-launch-chrome-profile tourscale")
o.bind("SUPER + SHIFT + B", "Chrome — TourScale", "omarchy-launch-chrome-profile tourscale")
o.bind("SUPER + ALT + B", "Chrome — Personal", "omarchy-launch-chrome-profile personal")
