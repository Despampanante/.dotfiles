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

## Legacy

Old Sway/waybar/qutebrowser/tmux/zsh Stow-based config lives on the [`legacy`](../../tree/legacy) branch.
