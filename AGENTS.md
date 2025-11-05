# Agent Guidelines for NixOS Configuration

## Build/Test Commands
- **Format code**: `nix fmt` (uses nixfmt-rfc-style per flake.nix:142-143)
- **Build config**: `sudo nixos-rebuild switch --flake .#<hostname>` (hostnames: dosa, appam, vada)
- **Test config**: `sudo nixos-rebuild test --flake .#<hostname>`
- **Check syntax**: `nix flake check`

## Code Style
- **Imports**: Function parameters use destructured attrset with `inputs, outputs, config, lib, pkgs, ...` pattern
- **Formatting**: RFC-style Nix formatting (2-space indentation, consistent attribute spacing)
- **Module structure**: Each feature in separate directory (hyprland/, stylix/, etc.) with configuration.nix
- **Naming**: Use kebab-case for filenames, camelCase for Nix attributes
- **Comments**: Minimal; keep existing NixOS template comments for context
- **Types**: Use proper Nix types; prefer explicit attribute sets over free-form

## Project Structure
- `systems/<hostname>/`: Per-machine configurations (appam, dosa, vada)
- Feature modules imported as list items in `flake.nix` nixosConfigurations
- Home-manager configuration in `home-manager/` directory
- `specialArgs` pattern: `inherit inputs outputs;` for passing flake inputs to modules

## Notes
- Three systems: dosa (desktop+nvidia), appam (VM), vada (Framework laptop)
- Uses flake inputs for packages (fontpkgs, gt-nvim, etc.)
- Never modify `system.stateVersion` values
