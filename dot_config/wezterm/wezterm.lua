local wezterm = require("wezterm")
local act = wezterm.action

-- Muscle memory carried over from the old tmux config (see .tmux.conf on the
-- `legacy` branch): C-b leader, tmux-style split keys, vi-style pane nav.
-- WezTerm's built-in copy mode already supports vi motions (hjkl) natively,
-- so nothing extra is needed there.
local config = {}

config.color_scheme = "Catppuccin Latte"
config.font = wezterm.font("Iosevka Nerd Font")
config.font_size = 16.0
config.window_decorations = "RESIZE"

-- WezTerm defaults to cmd.exe on Windows; use PowerShell 7 instead
if wezterm.target_triple:find("windows") then
	config.default_prog = { "pwsh.exe", "-NoLogo" }
end

config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	{ key = "F11", mods = "NONE", action = act.ToggleFullScreen },

	-- tmux-style splits: leader + % (vertical), leader + " (horizontal)
	{ key = "%", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "\"", mods = "LEADER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- vi-style pane navigation
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	-- reload config, like `bind r source-file` in tmux
	{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },
}

return config
