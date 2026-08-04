local wezterm = require("wezterm")
local act = wezterm.action

-- Muscle memory carried over from the old tmux config (see .tmux.conf on the
-- `legacy` branch): C-b leader, tmux-style split keys, vi-style pane nav.
-- WezTerm's built-in copy mode already supports vi motions (hjkl) natively,
-- so nothing extra is needed there.
local config = {}

-- Custom warm-light theme, generated from 'mini.hues' in the Neovim config.
-- Palette source of truth: ~/.config/palette.json (chezmoi-managed).
config.colors = {
	foreground = "#2e2a22",
	background = "#ece4d8",
	cursor_bg = "#2e2a22",
	cursor_border = "#2e2a22",
	cursor_fg = "#ece4d8",
	selection_bg = "#cac3b7",
	selection_fg = "#2e2a22",

	ansi = {
		"#0f0b05", -- black
		"#6d0022", -- red
		"#005f24", -- green
		"#6f6600", -- yellow
		"#290774", -- blue
		"#570056", -- purple (ANSI magenta slot)
		"#008180", -- cyan
		"#a9a196", -- white
	},
	brights = {
		"#6f6d69", -- bright black
		"#994c64", -- bright red
		"#4c8f66", -- bright green
		"#9a944c", -- bright yellow
		"#69519e", -- bright blue
		"#894c89", -- bright purple
		"#4ca7a6", -- bright cyan
		"#d4d0ca", -- bright white
	},
}
config.font = wezterm.font("Iosevka Nerd Font")
config.font_size = 16.0
config.window_decorations = "RESIZE"

-- Number tabs from 1, like `base-index 1` in tmux
config.tab_and_split_indices_are_zero_based = false

-- WezTerm defaults to cmd.exe on Windows; use PowerShell 7 instead
if wezterm.target_triple:find("windows") then
	config.default_prog = { "pwsh.exe", "-NoLogo" }
end

-- tmux-sessionizer (https://github.com/ThePrimeagen/tmux-sessionizer) equivalent:
-- fuzzy-pick a project dir or existing workspace, spawn/switch to a workspace
-- named after it. WezTerm workspaces are the closest analog to tmux sessions.
local function is_windows()
	return wezterm.target_triple:find("windows") ~= nil
end

local function list_subdirs(root)
	local ok, stdout
	if is_windows() then
		ok, stdout = wezterm.run_child_process({
			"pwsh.exe",
			"-NoProfile",
			"-Command",
			"Get-ChildItem -LiteralPath '" .. root .. "' -Directory -ErrorAction SilentlyContinue "
				.. "| Select-Object -ExpandProperty FullName",
		})
	else
		ok, stdout = wezterm.run_child_process({ "find", root, "-mindepth", "1", "-maxdepth", "1", "-type", "d" })
	end
	local dirs = {}
	if ok then
		for line in stdout:gmatch("[^\r\n]+") do
			table.insert(dirs, line)
		end
	end
	return dirs
end

local function project_roots()
	local home = wezterm.home_dir
	if is_windows() then
		return { home .. "/Documents", home .. "/Documents/projects", home .. "/Documents/gitClones" }
	end
	return { home, home .. "/projects" }
end

-- Extra fixed entries that won't turn up from a plain directory scan of
-- project_roots() (e.g. dot-directories, repos living outside those roots).
local function extra_paths()
	local home = wezterm.home_dir
	return { home .. "/.local/share/chezmoi" }
end

local function sessionizer_choices()
	local choices = {}
	local seen = {}

	for _, name in ipairs(wezterm.mux.get_workspace_names()) do
		table.insert(choices, { id = "workspace:" .. name, label = "[workspace] " .. name })
		seen[name] = true
	end

	for _, dir in ipairs(extra_paths()) do
		local name = dir:match("([^/\\]+)$")
		if name and not seen[name] then
			seen[name] = true
			table.insert(choices, { id = "dir:" .. dir, label = name })
		end
	end

	for _, root in ipairs(project_roots()) do
		for _, dir in ipairs(list_subdirs(root)) do
			local name = dir:match("([^/\\]+)$")
			if name and not seen[name] then
				seen[name] = true
				table.insert(choices, { id = "dir:" .. dir, label = name })
			end
		end
	end

	return choices
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

	-- tmux-style window (tab) management
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "w", mods = "LEADER", action = act.ShowTabNavigator },
	{ key = "&", mods = "LEADER|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Rename tab",
			action = wezterm.action_callback(function(window, _pane, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- tmux-sessionizer equivalent, like `bind -r f run-shell tmux-sessionizer`
	{
		key = "f",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(
				act.InputSelector({
					title = "sessionizer",
					choices = sessionizer_choices(),
					fuzzy = true,
					action = wezterm.action_callback(function(inner_window, inner_pane, id, _label)
						if not id then
							return
						end
						local kind, value = id:match("^(%a+):(.*)$")
						if kind == "workspace" then
							inner_window:perform_action(act.SwitchToWorkspace({ name = value }), inner_pane)
						elseif kind == "dir" then
							local name = value:match("([^/\\]+)$")
							inner_window:perform_action(
								act.SwitchToWorkspace({ name = name, spawn = { cwd = value } }),
								inner_pane
							)
						end
					end),
				}),
				pane
			)
		end),
	},
}

-- switch to tab by number (1-9, then 0 for the 10th), like `bind 0-9 select-window` in tmux.
-- ActivateTab's index is always 0-based regardless of
-- 'tab_and_split_indices_are_zero_based', so subtract 1 from the displayed number.
for i = 1, 10 do
	table.insert(config.keys, { key = tostring(i % 10), mods = "LEADER", action = act.ActivateTab(i - 1) })
end

return config
