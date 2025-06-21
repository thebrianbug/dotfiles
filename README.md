# Dotfiles

Personal system configuration using [Home Manager](https://nix-community.github.io/home-manager/) and [Nix](https://nixos.org/) for both Fedora 41 with GNOME on Wayland and NixOS virtual machines.

## Features

- **Package Management**: Declarative system package installation
- **Program Configurations**:
  - VSCodium with extensions
  - Git configuration
  - Neovim setup
  - Bash configuration
- **Desktop Environment**: GNOME configuration with custom preferences
- **Development Tools**: Node.js, Python, and container management tools
- **System Tools**: Various utility programs and applications

## System Overview

This repository supports:

- **Fedora Base Metal**: Primary configuration for Fedora 41+ with GNOME/Wayland
- **NixOS VM**: Complete system configuration for NixOS virtual machines

## Nix Flakes

This configuration uses [Nix Flakes](https://nixos.wiki/wiki/Flakes), a feature that provides:

- **Reproducible Builds**: Exact dependency versions are locked and tracked
- **Composable**: Easy to combine multiple configurations
- **Hermetic**: Builds are isolated and deterministic
- **Fast**: Efficient dependency resolution and caching
- **Version Control**: Direct integration with Git for managing configurations

This configuration uses [Nix Flakes](https://nixos.wiki/wiki/Flakes) for reproducible builds, composability, and version tracking.

## Setup Instructions

### Fedora Installation

#### Prerequisites

- Fedora 41 or later with GNOME and Wayland

#### Quick Setup (Two Commands)

```bash
# 1. Install Nix with the determinate systems installer (automatically enables flakes)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Apply dotfiles configuration
git clone https://github.com/thebrianbug/dotfiles.git && cd dotfiles && home-manager switch --flake .
```

### NixOS VM Installation

#### Prerequisites

- A NixOS virtual machine installation
- Git installed on the VM (available on default NixOS installations)
- Root access via sudo

#### 1. Clone Repository

```bash
git clone https://github.com/thebrianbug/dotfiles.git
cd dotfiles
```

#### 2. Apply System Configuration

```bash
sudo nixos-rebuild switch --flake .#vm
```

#### 3. Apply User Configuration (Optional)

If you're not using the NixOS module approach and want to manage the user environment separately:

```bash
home-manager switch --flake .#brianbug-vm
```

## Maintaining Your System

### Updating Dependencies

To update your system packages and configurations:

```bash
# Update all flake inputs
nix flake update

# Or update a specific input
nix flake lock --update-input nixpkgs
```

### Applying Updates

#### Fedora

```bash
cd dotfiles
home-manager switch --flake .
```

#### NixOS VM

```bash
cd dotfiles
sudo nixos-rebuild switch --flake .#vm
```

### Checking Updates Before Applying

```bash
# Verify flake integrity
nix flake check

# Build without applying
home-manager build --flake .
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

### Common Issues

- **Flake errors**: Make sure you're in the repository directory
- **Build failures**: Try updating the flake inputs with `nix flake update`
- **Nix issues**: The determinate installer provides built-in diagnostics - run `/nix/nix-installer diagnose`
- **Missing Home Manager command**: The first time you run, use the full path: `~/.nix-profile/bin/home-manager switch --flake .`

### Getting Help

- Nix documentation: https://nixos.org/manual/nix/stable/
- Home Manager manual: https://nix-community.github.io/home-manager/
