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

## Installation

1. Clone this repository:
```bash
git clone https://github.com/thebrianbug/dotfiles.git
cd dotfiles
```

2. Apply the configuration:
```bash
cd nix-linux
home-manager switch --flake .
```

## Structure

- `nix-linux/`: Nix configuration files
  - `desktop/`: Desktop environment configurations
  - `development/`: Development tool configurations
  - `programs/`: Program-specific configurations
  - `home.nix`: Main Home Manager configuration
  - `flake.nix`: Nix flake configuration
