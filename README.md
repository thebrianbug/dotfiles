# Dotfiles

Personal system configuration using [Nix Flakes](https://nixos.wiki/wiki/Flakes) and [Home Manager](https://nix-community.github.io/home-manager/) for declarative, reproducible system management.

## Supported Systems

- **Fedora 41+**: Base metal with GNOME/Wayland
- **NixOS**: Virtual machines and ASUS laptop

## Features

- Declarative package management (VSCodium, Git, Neovim, Bash, GNOME)
- Development tools (Node.js, Python, containers)
- Reproducible builds with locked dependencies

## Setup Instructions

### Fedora

```bash
# Install Nix (enables flakes automatically)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Apply configuration
git clone https://github.com/thebrianbug/dotfiles.git && cd dotfiles && home-manager switch --flake .
```

### NixOS

```bash
# Clone repository
git clone https://github.com/thebrianbug/dotfiles.git && cd dotfiles

# Apply system configuration (choose your target)
sudo nixos-rebuild switch --flake .#vm          # For VMs
sudo nixos-rebuild switch --flake .#asus-linux  # For ASUS laptop
```

## Updates

```bash
# Update dependencies
nix flake update                              # All inputs
nix flake lock --update-input nixpkgs         # Specific input

# Apply changes
home-manager switch --flake .                 # Fedora
sudo nixos-rebuild switch --flake .#vm        # NixOS VM
sudo nixos-rebuild switch --flake .#asus-linux # NixOS ASUS

# Verify before applying
nix flake check                               # Check integrity
home-manager build --flake .                  # Build without applying
```

## Repository Structure

- `flake.nix`: Main configuration for the Nix flake
- `home-manager/`: Home Manager configurations
  - `common/`: Shared configurations across all systems
  - `fedora/`: Fedora-specific configurations
  - `vm/`: NixOS VM-specific configurations
- `hosts/`: NixOS system configurations
  - `vm/`: Configuration files for NixOS virtual machine

## Troubleshooting

- **Flake errors**: Ensure you're in the repository directory
- **Build failures**: Run `nix flake update`
- **Nix diagnostics**: Run `/nix/nix-installer diagnose`
- **Missing home-manager**: Use full path `~/.nix-profile/bin/home-manager switch --flake .`

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
