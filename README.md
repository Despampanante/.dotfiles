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

## Legacy

Old Sway/waybar/qutebrowser/tmux/zsh Stow-based config lives on the [`legacy`](../../tree/legacy) branch.
