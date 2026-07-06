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

local function sessionizer_choices()
	local choices = {}
	local seen = {}

	for _, name in ipairs(wezterm.mux.get_workspace_names()) do
		table.insert(choices, { id = "workspace:" .. name, label = "[workspace] " .. name })
		seen[name] = true
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

return config
