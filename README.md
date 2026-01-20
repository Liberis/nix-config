# NixOS Configuration

Declarative NixOS configuration using Flakes for multiple hosts with role-based profiles.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FLAKE INPUTS                                    │
│                                                                             │
│   nixpkgs (unstable)    home-manager    nixos-wsl    disko                  │
└─────────────────────────────────────────┬───────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                 PROFILES                                     │
│                                                                             │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │   BASE   │    │ DESKTOP  │    │  SERVER  │    │   WSL    │              │
│  │          │    │          │    │          │    │          │              │
│  │ • locale │    │ • wayland│    │ • minimal│    │ • interop│              │
│  │ • fonts  │    │ • nvidia │    │ • ssh    │    │ • shared │              │
│  │ • users  │    │ • apps   │    │ • k3s    │    │   paths  │              │
│  │ • network│    │ • gaming │    │          │    │          │              │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘              │
│       │               │               │               │                     │
│       └───────────────┴───────┬───────┴───────────────┘                     │
│                               │                                             │
└───────────────────────────────┼─────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                 HOSTS                                        │
│                                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐  │
│  │       nixos         │  │       jarvis        │  │        wsl          │  │
│  │   (Desktop/Gaming)  │  │    (Home Server)    │  │  (Dev Environment)  │  │
│  │                     │  │                     │  │                     │  │
│  │ Profiles:           │  │ Profiles:           │  │ Profiles:           │  │
│  │ • base              │  │ • base              │  │ • base              │  │
│  │ • desktop           │  │ • server            │  │ • wsl               │  │
│  │                     │  │                     │  │                     │  │
│  │ Hardware:           │  │ Hardware:           │  │ Hardware:           │  │
│  │ • AMD Ryzen         │  │ • Intel Xeon        │  │ • Virtual           │  │
│  │ • NVIDIA 5070Ti     │  │ • ZFS storage       │  │                     │  │
│  │                     │  │ • K3s cluster       │  │                     │  │
│  └─────────────────────┘  └─────────────────────┘  └─────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            HOME-MANAGER                                      │
│                                                                             │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐     │
│  │    CLI    │ │Development│ │   Shell   │ │  Wayland  │ │  Utilities│     │
│  │           │ │           │ │           │ │           │ │           │     │
│  │ • eza     │ │ • neovim  │ │ • bash    │ │ • niri    │ │ • btop    │     │
│  │ • bat     │ │ • git     │ │ • tmux    │ │ • sway    │ │ • yazi    │     │
│  │ • ripgrep │ │ • go/rust │ │ • zoxide  │ │ • river   │ │           │     │
│  │ • fd      │ │ • node    │ │           │ │ • waybar  │ │           │     │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘ └───────────┘     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Hosts

| Host | Role | Hardware | Key Features |
|------|------|----------|--------------|
| `nixos` | Desktop | AMD Ryzen + NVIDIA | Wayland, Gaming, Development |
| `jarvis` | Server | Intel Xeon + ZFS | K3s, NFS, Homelab services |
| `wsl` | Dev | WSL2 | Windows integration, CLI tools |

## Repository Structure

```
├── flake.nix                 # Entry point
├── config.nix                # Shared configuration values
├── profiles/
│   ├── base.nix              # Common to all hosts
│   ├── desktop.nix           # GUI workstation
│   ├── server.nix            # Headless server
│   └── wsl.nix               # WSL optimizations
├── modules/
│   ├── nixos/
│   │   ├── hardware/         # CPU, GPU, audio, ZFS
│   │   ├── desktop/          # Wayland, display manager
│   │   ├── services/         # K3s, NFS, SSH
│   │   └── system/           # Base system config
│   └── home-manager/
│       ├── cli.nix           # Modern CLI tools
│       ├── development.nix   # Dev environment
│       ├── shell.nix         # Bash, tmux
│       └── wayland.nix       # Compositor configs
├── hosts/
│   ├── nixos/                # Desktop workstation
│   ├── jarvis/               # Home server
│   └── wsl/                  # Windows Subsystem
├── config/                   # Dotfiles
│   ├── nvim/                 # Neovim (Lua)
│   ├── niri/                 # Niri compositor
│   ├── waybar/               # Status bar
│   └── ...
└── scripts/                  # Setup utilities
```

## Desktop Environment

Primary compositor: **Niri** (scrollable tiling Wayland)

```
┌─────────────────────────────────────────────────────────────────┐
│  Waybar                                              [tray] [clock]
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│   │   Firefox   │  │    Code     │  │   Terminal  │  ◄── scroll
│   │             │  │             │  │             │            │
│   │             │  │             │  │   foot +    │            │
│   │             │  │             │  │   tmux      │            │
│   └─────────────┘  └─────────────┘  └─────────────┘            │
│                                                                 │
│   Workspaces: 1  2  3  4  5  6  7  8  9                        │
└─────────────────────────────────────────────────────────────────┘
```

Also supports: Sway, River

## Quick Start

```bash
# Clone
git clone https://github.com/Liberis/nix-config ~/.config/nix-config
cd ~/.config/nix-config

# Build and switch (existing NixOS)
sudo nixos-rebuild switch --flake .#nixos

# Build and switch (for jarvis)
sudo nixos-rebuild switch --flake .#jarvis

# Update flake inputs
nix flake update
```

## Key Design Decisions

1. **Flakes** - Reproducible builds with locked dependencies
2. **Role-based profiles** - DRY configuration across hosts
3. **Home-manager as module** - Integrated with NixOS rebuild
4. **Disko** - Declarative disk partitioning for new installs
5. **Hardware abstraction** - Separate CPU/GPU modules for flexibility

## CLI Tools

Modern replacements for traditional Unix tools:

| Traditional | Modern | Description |
|-------------|--------|-------------|
| `ls` | `eza` | Better file listing with git integration |
| `cat` | `bat` | Syntax highlighting |
| `grep` | `ripgrep` | Faster search |
| `find` | `fd` | Simpler syntax |
| `cd` | `zoxide` | Smart directory jumping |
| `vim` | `neovim` | Lua config, LSP, Treesitter |

## License

MIT
