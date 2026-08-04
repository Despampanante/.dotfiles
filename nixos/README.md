# nixos config

Flake-based NixOS config, currently running on a VirtualBox VM, meant to
migrate to a laptop dual-booting Windows later. Lives at `nixos/` inside the
`Despampanante/.dotfiles` monorepo, alongside the Windows/chezmoi setup
under `windows/` — see the repo root README for how the two relate. See
`DECISIONS.md` (in this directory) for the full record of what was set up
and why.

## Layout

```
flake.nix              inputs + nixosConfigurations
hosts/vm/               this machine (VirtualBox guest)
  configuration.nix
  hardware-configuration.nix
home/santi.nix          home-manager config for santi
home/dotfiles/           plain dotfiles symlinked in by home-manager:
                          neovim, tmux, wezterm, palette.json (currently
                          duplicated copies of ../windows/dot_config/* —
                          see DECISIONS.md on why not shared yet), plus
                          sway, niri, waybar, fuzzel, swaync, swaylock
                          (Linux-desktop-only, no Windows equivalent)
```

## Rebuilding

```sh
sudo nixos-rebuild switch --flake ~/dotfiles/nixos#vm
# or, to just check it builds without applying:
sudo nixos-rebuild build --flake ~/dotfiles/nixos#vm
```

(aliased as `nrs` / `nrb` in the zsh config once applied)

## Adding the laptop later

See the migration checklist at the bottom of `DECISIONS.md`.
