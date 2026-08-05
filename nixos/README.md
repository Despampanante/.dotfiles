# nixos config

Flake-based NixOS config. Started on a VirtualBox VM (`vm` host, still kept
around) and now also covers the real laptop (`legion-laptop` host, a Lenovo
Legion 5 17ACH6H dual-booting Windows). Lives at `nixos/` inside the
`Despampanante/.dotfiles` monorepo, alongside the Windows/chezmoi setup
under `windows/` — see the repo root README for how the two relate. See
`DECISIONS.md` (in this directory) for the full record of what was set up
and why.

## Layout

```
flake.nix                     inputs + nixosConfigurations (vm, legion-laptop)
hosts/vm/                      VirtualBox guest, used to build up this config
  configuration.nix
  hardware-configuration.nix
hosts/legion-laptop/           the real laptop
  configuration.nix
  hardware-configuration.nix
home/santi.nix                 home-manager config for santi, shared by both hosts
home/dotfiles/                  plain dotfiles symlinked in by home-manager:
                                 neovim, tmux, wezterm, palette.json (currently
                                 duplicated copies of ../windows/dot_config/* —
                                 see DECISIONS.md on why not shared yet), plus
                                 sway, niri, waybar, fuzzel, swaync, swaylock
                                 (Linux-desktop-only, no Windows equivalent)
```

## Rebuilding

```sh
sudo nixos-rebuild switch --flake ~/dotfiles/nixos#$(hostname)
# or, to just check it builds without applying:
sudo nixos-rebuild build --flake ~/dotfiles/nixos#$(hostname)
```

(aliased as `nrs` / `nrb` in the zsh config once applied.)

**First switch on the laptop only**: the live hostname right now is
`legionlaptop` (no hyphen — see below), not `legion-laptop`, so `$(hostname)`
in `nrs`/`nrb` won't find `nixosConfigurations.legion-laptop` yet. Run the
first switch explicitly:
```sh
sudo nixos-rebuild switch --flake ~/dotfiles/nixos#legion-laptop
```
After that switch (and a reboot/relogin so the new hostname is fully live),
`hostname` returns `legion-laptop` and `nrs`/`nrb` work unmodified from then
on.

## Laptop-specific open items

See the "legion-laptop host" entry in `DECISIONS.md`:
- No `hardware.nvidia.*`/PRIME config yet — the RTX 3060 Mobile dGPU is
  currently unconfigured and falls back to `nouveau`.
- `/etc/nixos/configuration.nix` on this machine is stale (untouched
  installer template) — it's not what built the running system and
  should not be used directly; always rebuild via `--flake` as above.
