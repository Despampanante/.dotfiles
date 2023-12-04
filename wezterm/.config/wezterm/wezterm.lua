local wezterm = require("wezterm")
local act = wezterm.action
return {
	color_scheme = "Dracula (Official)",
	font = wezterm.font("Iosevka Nerd Font Mono"),
	font_size = 16.0,
	window_background_opacity = 1,
	window_decorations = "NONE",
	enable_tab_bar = false,
	keys = {
		{ key = "F11", mods = "NONE", action = act.ToggleFullScreen },
	},

}
