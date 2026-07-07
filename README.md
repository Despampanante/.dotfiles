# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Works on both Windows and Linux via `XDG_CONFIG_HOME`.

## Setup

### Linux

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Despampanante/.dotfiles
```

### Windows

Neovim (and other XDG-respecting tools) need `XDG_CONFIG_HOME` set, since Windows doesn't use `~/.config` by default:

```powershell
setx XDG_CONFIG_HOME "$env:USERPROFILE\.config"
```

Then, in a new shell:

```powershell
winget install twpayne.chezmoi
chezmoi init --apply Despampanante/.dotfiles
```

## tmux

Uses [catppuccin/tmux](https://github.com/catppuccin/tmux) via TPM. TPM itself is cloned automatically by a
chezmoi run-once script (Linux-only; tmux isn't a native Windows tool). On first run inside tmux, press
`<prefix> + I` (capital i) to have TPM fetch the plugins.

QoL bindings on top of the defaults (prefix is `Ctrl+b`):
- `"` / `%` — split panes in the current pane's path (not `$HOME`)
- `h/j/k/l` — move between panes (repeatable, vi-style)
- `H/J/K/L` — resize panes (repeatable, vi-style)
- `Space` — jump to last window
- `y` — toggle synchronized-panes (type into all panes at once)
- `r` — reload config
- `f` — [tmux-sessionizer](https://github.com/ThePrimeagen/tmux-sessionizer): fuzzy-pick a project dir (via fzf)
  and jump to/create a tmux session for it. The script lives at `dot_local/bin/executable_tmux-sessionizer` →
  `~/.local/bin/tmux-sessionizer`. Requires `fzf` installed separately. Customize search paths via
  `~/.config/tmux-sessionizer/tmux-sessionizer.conf` (see the script's header for the config format).

## WezTerm

`dot_config/wezterm/wezterm.lua` uses a custom warm-light scheme (`config.colors`), generated from
`mini.hues` in the Neovim config — see [`docs/theming.md`](docs/theming.md) for how that palette is shared
across apps (tmux, Discord, Windows). Runs natively on Windows, so it doubles as a terminal multiplexer
there (via WezTerm's own pane/tab system and `wezterm-mux-server` for detach/reattach), since tmux itself
needs WSL/MSYS2 on Windows.

Leader key is `Ctrl+b`, matching the old tmux prefix:
- `leader + %` / `leader + "` — split pane vertical/horizontal (tmux muscle memory)
- `leader + h/j/k/l` — move between panes (vi-style, like the old tmux config)
- `leader + r` — reload config (like tmux's `bind r source-file`)
- `leader + c` / `n` / `p` / `0`-`9` / `,` / `&` (Shift) / `w` — tab management: new/next/previous/jump-to-number
  /rename/close/interactive-list (tabs are numbered from 1, matching tmux's `base-index 1`)
- `leader + f` — sessionizer: fuzzy-pick an existing WezTerm workspace or a project directory (scanned from
  `~/Documents`, `~/Documents/projects`, `~/Documents/gitClones` on Windows; `~` and `~/projects` elsewhere)
  and switch to/spawn a workspace named after it. WezTerm workspaces are the closest analog to tmux sessions,
  so this is the WezTerm-native version of tmux-sessionizer above (no fzf/tmux dependency — uses WezTerm's
  own `InputSelector` fuzzy finder).

## Theming

See [`docs/theming.md`](docs/theming.md) — a shared palette (`dot_config/palette.json`) drives Neovim, tmux,
WezTerm, Discord (via Vencord), and Windows' accent color/wallpaper.

## Legacy

Old Sway/waybar/qutebrowser/tmux/zsh Stow-based config lives on the [`legacy`](../../tree/legacy) branch.
