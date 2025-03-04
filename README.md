# Dotfiles

Personal system configuration using [Home Manager](https://nix-community.github.io/home-manager/) and [Nix](https://nixos.org/).

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

## Prerequisites

- Nix package manager
- Home Manager

## Nix Flakes

This configuration uses [Nix Flakes](https://nixos.wiki/wiki/Flakes), a feature that provides:

- **Reproducible Builds**: Exact dependency versions are locked and tracked
- **Composable**: Easy to combine multiple configurations
- **Hermetic**: Builds are isolated and deterministic
- **Fast**: Efficient dependency resolution and caching
- **Version Control**: Direct integration with Git for managing configurations

To enable flakes support, ensure you have the following in your Nix configuration:
```nix
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
```

## Installation

1. Clone this repository:
```bash
git clone https://github.com/thebrianbug/dotfiles.git
cd dotfiles
```

2. Apply the configuration:
```bash
cd home-manager
home-manager switch --flake .
```

## Structure

- `home-manager/`: Home Manager configuration files
  - `desktop/`: Desktop environment configurations
  - `development/`: Development tool configurations
  - `programs/`: Program-specific configurations
  - `home.nix`: Main Home Manager configuration
  - `flake.nix`: Nix flake configuration
