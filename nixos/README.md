# nixos config

Flake-based NixOS config for the laptop (`legion-laptop` host, a Lenovo
Legion 5 17ACH6H dual-booting Windows). Lives at `nixos/` inside the
`Despampanante/.dotfiles` monorepo, alongside the Windows/chezmoi setup
under `windows/` — see the repo root README for how the two relate. See
`DECISIONS.md` (in this directory) for the full record of what was set up
and why.

## Layout

```
flake.nix                     inputs + nixosConfigurations (legion-laptop)
hosts/legion-laptop/           the laptop
  configuration.nix
  hardware-configuration.nix
home/santi.nix                 home-manager config for santi -- owns all
                                 user-facing packages/apps too, not just
                                 dotfiles (system config stays focused on
                                 hardware/drivers/daemons/boot)
home/dotfiles/                  plain dotfiles symlinked in by home-manager:
                                 neovim, tmux (currently duplicated copies
                                 of ../windows/dot_config/* — see
                                 DECISIONS.md on why not shared yet), plus
                                 niri, waybar, fuzzel, swaync, swaylock,
                                 ghostty (Linux-desktop-only, no Windows
                                 equivalent -- Windows keeps wezterm
                                 instead, see DECISIONS.md)
```

## Rebuilding

```sh
sudo nixos-rebuild switch --flake ~/dotfiles/nixos#$(hostname)
# or, to just check it builds without applying:
sudo nixos-rebuild build --flake ~/dotfiles/nixos#$(hostname)
```

(aliased as `nrs` / `nrb` in the zsh config once applied — `$(hostname)`
resolves to `legion-laptop` on this machine.)

## Open items

See `DECISIONS.md` for the full history. Current known gaps:
- No PRIME sync/offload games have been verified beyond a smoke test —
  `nvidia-offload <command>` routes a program to the RTX 3060 dGPU (offload
  mode; this is a muxless laptop, so sync mode doesn't apply).
- wlsunset's night-light location is a static Arlington, VA lat/long, not
  GPS-aware — needs manual adjustment during extended stretches elsewhere.
