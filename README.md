# .dotfiles

Two independent setups sharing one repo:

- **`windows/`** — chezmoi-managed dotfiles (Windows, primarily). This is
  the whole repo as it used to be, just moved under this subdirectory — see
  `.chezmoiroot` (re-points chezmoi's source root here transparently) and
  `windows/README.md` for chezmoi-specific docs/setup.
- **`nixos/`** — a flake-based NixOS config, currently running on a
  VirtualBox VM ahead of migrating to a laptop dual-booting Windows. See
  `nixos/README.md` and `nixos/DECISIONS.md`.

## Why one repo

Kept as two clearly separated directories rather than mixed together, since
the two sides use unrelated tooling (chezmoi vs. Nix flakes) with different
git-history relevance. `.chezmoiroot` and the `--flake nixos#...` path both
mean neither tool has to know the other exists.

## Shared configs

`nixos/home/dotfiles/{nvim,tmux,wezterm,palette.json}` are currently
**duplicated copies** of `windows/dot_config/{nvim,tmux,wezterm,palette.json}`,
not shared — a deliberate choice while the NixOS side (WM choice, desktop
tooling) is still actively changing. Once that settles, these can switch to
direct relative-path references (`../windows/dot_config/nvim`, etc.) from
`nixos/home/santi.nix` instead of copies, so edits only need to happen once.
See `nixos/DECISIONS.md` ("Merged into the dotfiles monorepo") for the full
reasoning.
