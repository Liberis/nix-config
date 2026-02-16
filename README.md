# NixOS Configuration

A modular, role-based NixOS flake configuration for managing multiple hosts with minimal duplication.

## Architecture Overview

This repository implements a **role-based configuration architecture** that separates concerns between system-level (NixOS) and user-level (home-manager) configurations. The design emphasizes modularity, reusability, and hardware abstraction.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FLAKE INPUTS                                    │
│                                                                             │
│   nixpkgs (unstable)    home-manager    nixos-wsl    disko                  │
└─────────────────────────────────────────┬───────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            GRANULAR PROFILES                                 │
│                                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │   BASE   │  │ DESKTOP  │  │ HEADLESS │  │ STORAGE  │  │   WSL    │      │
│  │          │  │          │  │          │  │  SERVER  │  │          │      │
│  │ • locale │  │ • wayland│  │ • boot   │  │ • zfs    │  │ • interop│      │
│  │ • fonts  │  │ • nvidia │  │ • ssh    │  │ • nfs    │  │ • shared │      │
│  │ • users  │  │ • audio  │  │          │  │          │  │   paths  │      │
│  │ • network│  │ • apps   │  │          │  │          │  │          │      │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘      │
│       │             │             │             │             │             │
│       └─────────────┴─────────────┴─────────────┴─────────────┘             │
│                               │                                             │
└───────────────────────────────┼─────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                 HOSTS                                        │
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │    jarvis    │  │  mainframe   │  │    akasha    │  │     wsl      │    │
│  │  (Desktop)   │  │  (Control)   │  │  (Storage)   │  │     (Dev)    │    │
│  │              │  │              │  │              │  │              │    │
│  │ Profiles:    │  │ Profiles:    │  │ Profiles:    │  │ Profiles:    │    │
│  │ • base       │  │ • base       │  │ • base       │  │ • base       │    │
│  │ • desktop    │  │ • headless   │  │ • headless   │  │ • wsl        │    │
│  │              │  │              │  │ • storage    │  │              │    │
│  │ Hardware:    │  │ Hardware:    │  │ Hardware:    │  │ Hardware:    │    │
│  │ • Ryzen      │  │ • i7-10710T  │  │ • Xeon 28c   │  │ • Virtual    │    │
│  │   9900X      │  │   (6 cores)  │  │ • 32GB RAM   │  │              │    │
│  │ • RTX 5070Ti │  │ • 16GB RAM   │  │ • ZFS RAIDZ1 │  │              │    │
│  │              │  │ • 256GB NVMe │  │   4TB        │  │              │    │
│  │ Services:    │  │              │  │              │  │              │    │
│  │ • K3s GPU    │  │ Services:    │  │ Services:    │  │              │    │
│  │   Worker     │  │ • K3s        │  │ • K3s Worker │  │              │    │
│  │ • NFS Client │  │   Server     │  │ • NFS Server │  │              │    │
│  └──────────────┘  │   (Control)  │  └──────────────┘  └──────────────┘    │
│                    └──────────────┘                                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            HOME-MANAGER                                      │
│                                                                             │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐     │
│  │   Common  │ │Development│ │   Shell   │ │  Wayland  │ │ Utilities │     │
│  │           │ │           │ │           │ │           │ │           │     │
│  │ • neovim  │ │ • go/rust │ │ • bash    │ │ • niri    │ │ • btop    │     │
│  │ • tmux    │ │ • gcc     │ │ • starship│ │ • sway    │ │ • yazi    │     │
│  │ • btop    │ │ • azure   │ │ • zoxide  │ │ • river   │ │ • ncdu    │     │
│  │ • yazi    │ │ • k8s     │ │ • fzf     │ │ • waybar  │ │           │     │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘ └───────────┘     │
│                                                                             │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐                                 │
│  │   Media   │ │    Comm   │ │   AI/ML   │                                 │
│  │           │ │           │ │           │                                 │
│  │ • player  │ │ • telegram│ │ • lmstudio│                                 │
│  │   ctl     │ │           │ │ • claude  │                                 │
│  │ • bright  │ │           │ │ • antigrav│                                 │
│  └───────────┘ └───────────┘ └───────────┘                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Design Principles

- **DRY (Don't Repeat Yourself)**: Centralized configuration in `config.nix` eliminates duplication
- **Modularity**: Clear separation between system/user, hardware/software, and role-specific configurations
- **Composability**: Hardware components (CPU/GPU) are separate modules that can be mixed and matched
- **Reproducibility**: Flake lock ensures consistent builds across all hosts
- **Declarative Infrastructure**: Disk management (Disko), services, and dotfiles all defined declaratively
- **Fully Declarative Disk Management**: All physical hosts use Disko for reproducible disk layouts

## Managed Hosts

| Host | Role | Hardware | Key Features |
|------|------|----------|--------------|
| `jarvis` | Desktop | AMD Ryzen 9900X + NVIDIA 5070Ti | Wayland, Gaming, K3s GPU Worker |
| `mainframe` | Control Plane | Intel i7-10710T (6c) + 16GB RAM | K3s Server, Dedicated Control Plane |
| `akasha` | Storage + Worker | Intel Xeon E2680v5 (28c) + 32GB | K3s Worker, ZFS RAIDZ1 (4TB), NFS Server |
| `wsl` | Development | WSL2 Virtual | Windows integration, CLI tools |

## Repository Structure

```
.
├── flake.nix                    # Entry point with host definitions and mkHost helper
├── flake.lock                   # Locked dependencies for reproducibility
├── config.nix                   # Centralized configuration (user, timezone, preferences)
├── profiles/                    # Granular, composable profiles
│   ├── base.nix                # Common to all hosts
│   ├── desktop.nix             # Full graphical workstation
│   ├── headless.nix            # Minimal headless server (boot + SSH)
│   ├── storage-server.nix      # ZFS storage + NFS server
│   └── wsl.nix                 # Windows Subsystem for Linux
├── modules/
│   ├── nixos/                  # System-level modules
│   │   ├── system/             # Base system configuration
│   │   │   ├── base.nix        # Essential services (dbus, polkit)
│   │   │   ├── flake-defaults.nix  # Flakes, unfree, state version
│   │   │   ├── fonts.nix       # Nerd Fonts configuration
│   │   │   ├── locale.nix      # Timezone and locale
│   │   │   ├── networking.nix  # NetworkManager, DNS, firewall
│   │   │   ├── system-packages.nix  # Base utilities
│   │   │   └── users.nix       # User accounts
│   │   ├── hardware/           # Hardware-specific modules
│   │   │   ├── audio.nix       # PipeWire setup
│   │   │   ├── bluetooth.nix   # Bluetooth support
│   │   │   ├── boot.nix        # GRUB bootloader
│   │   │   ├── cpu-amd.nix     # AMD CPU (Ryzen, EPYC)
│   │   │   ├── cpu-intel.nix   # Intel CPU (Xeon, Core)
│   │   │   ├── gpu-amd.nix     # AMD GPU configuration
│   │   │   ├── gpu-nvidia.nix  # NVIDIA (open kernel modules)
│   │   │   ├── kernel.nix      # Kernel 6.12 + tuning
│   │   │   └── zfs.nix         # ZFS with ARC tuning
│   │   ├── desktop/            # Desktop environment
│   │   │   ├── display-manager.nix  # SDDM with sugar-dark theme
│   │   │   ├── programs.nix    # Firefox, Chromium, compositors
│   │   │   ├── wayland.nix     # XDG portals, seatd
│   │   │   └── wayland-packages.nix
│   │   └── services/           # Service configurations
│   │       ├── k3s-base.nix    # K3s with Podman
│   │       ├── k3s-nvidia.nix  # K3s + NVIDIA support
│   │       ├── nfs.nix         # NFS server
│   │       ├── nfs-client.nix  # NFS client mounts
│   │       └── ssh.nix         # OpenSSH server
│   └── home-manager/           # User-level modules
│       ├── common.nix          # Core tools for all hosts
│       ├── development.nix     # Programming tools
│       ├── shell.nix           # Modern CLI tools
│       ├── wayland.nix         # Wayland desktop tools
│       ├── utilities.nix       # Desktop utilities
│       ├── media.nix           # Media control
│       ├── communication.nix   # Messaging apps
│       └── ai-ml.nix          # AI/ML tools
├── hosts/                       # Host-specific configurations
│   ├── jarvis/                 # Desktop workstation
│   │   ├── default.nix
│   │   └── disko.nix           # Declarative disk layout
│   ├── mainframe/              # K3s control plane
│   │   ├── default.nix
│   │   └── disko.nix           # Declarative disk layout
│   ├── akasha/                 # Storage server & K3s worker
│   │   ├── default.nix
│   │   └── disko.nix           # Declarative disk layout
│   └── wsl/                    # WSL development
│       └── default.nix
├── config/                      # Application dotfiles
│   ├── bash/                   # .bashrc with tmux integration
│   ├── btop/                   # System monitor
│   ├── foot/                   # Terminal emulator
│   ├── k3s/                    # Kubernetes manifests
│   ├── niri/                   # Niri compositor (primary)
│   ├── nvim/                   # Neovim (24 plugins, Lua config)
│   ├── river/                  # River compositor
│   ├── sway/                   # Sway compositor
│   ├── tmux/                   # Tmux configuration
│   ├── waybar/                 # Status bar (3 variants)
│   ├── way-displays/           # Display configuration
│   ├── wofi/                   # Application launcher
│   └── yazi/                   # File manager
└── scripts/                     # Setup utilities
    ├── create-zfs-datasets.sh
    └── setup-btrfs-jarvis.sh
```

## Core Architecture Patterns

### 1. Declarative Disk Management (Disko)

All physical hosts use **Disko** for fully declarative disk layouts:

**Benefits:**
- **Reproducible**: Disk layout is version controlled and reproducible
- **Automated**: One command partitions, formats, and mounts everything
- **Consistent**: Same BTRFS subvolume structure across all hosts
- **Safe**: Declare once, deploy many times

**Common BTRFS Layout:**
- `@root` - OS files (compressed, snapshots)
- `@home` - User files (compressed, snapshots)
- `@nix` - Nix store (nodatacow for performance)
- `@var-log` - System logs (compressed)
- `@rancher` - K3s data (nodatacow for database performance)
- `@snapshots` - Backup snapshots

**Host-Specific:**
- **jarvis**: 32GB swap (gaming/development), optimized for desktop use
- **mainframe**: 8GB swap (server), minimal layout for control plane
- **akasha**: No swap (32GB RAM sufficient), ZFS for bulk storage

### 2. Role-Based Configuration

Hosts are assigned roles that determine which profiles are loaded:

- **base**: Essential system configuration (all hosts)
- **desktop**: Full graphical workstation with Wayland
- **headless**: Minimal headless server (boot + SSH)
- **storage-server**: ZFS storage + NFS server
- **wsl**: Windows Subsystem for Linux integration

### 3. Hardware Abstraction

CPU and GPU configurations are completely separate modules, allowing easy hardware changes:

```nix
# Example: Swapping hardware in hosts/nixos/default.nix
imports = [
  ../../modules/nixos/hardware/cpu-intel.nix   # Changed from cpu-amd.nix
  ../../modules/nixos/hardware/gpu-amd.nix     # Changed from gpu-nvidia.nix
];
```

### 4. Centralized Configuration

`config.nix` serves as the single source of truth for:
- User details (name, email)
- System settings (state version, timezone)
- Desktop preferences
- Network configuration

All modules import this file to avoid hardcoded values.

### 5. Dynamic Module Loading

Home-manager modules are loaded conditionally based on host roles:

```nix
roleImports = if lib.any (r: r == "desktop") roles
  then coreModules ++ baseModules ++ desktopModules
  else coreModules ++ baseModules;
```

## Technology Stack

- **OS**: NixOS unstable
- **Init System**: systemd
- **Bootloader**: GRUB with EFI
- **Display Protocol**: Wayland
  - **Primary Compositor**: Niri (scrollable tiling)
  - **Alternatives**: Sway, River
- **Audio**: PipeWire (with PulseAudio/ALSA/JACK compatibility)
- **Container Runtime**: Podman
- **Orchestration**: K3s (Kubernetes)
- **Filesystems**:
  - BTRFS (OS and system data)
  - ZFS (bulk storage with RAIDZ1)
- **Networking**: NetworkManager + Flannel (K3s)
- **Display Manager**: SDDM with sugar-dark theme

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

**Desktop Tools:**
- **Terminal**: foot
- **Launcher**: wofi
- **Status Bar**: waybar (compositor-specific configs)
- **File Manager**: yazi (with smart-enter plugin, dracula theme)
- **Editor**: Neovim (24 plugins with LSP, treesitter, telescope)
- **Browsers**: Firefox, Chromium
- **Communication**: Telegram Desktop
- **AI Tools**: LM Studio, antigravity, claude-code

**Dual Monitor Setup:**
- Dell P2719H (1080p)
- Dell AW2724DM (2K @ 165Hz)

Also supports: Sway, River

## Key Features

### Kubernetes Cluster (K3s)

A 3-node K3s cluster with dedicated control plane:

**Control Plane:**
- **mainframe**: Dedicated K3s server (control plane only)
  - Intel i7-10710T (6 cores), 16GB RAM
  - Static IP: 192.168.10.10
  - No workload scheduling (control plane isolation)

**Worker Nodes:**
- **akasha**: Storage + compute worker (28 cores, 32GB RAM)
  - Runs K3s agent
  - Provides ZFS storage via NFS
  - Handles general workloads
- **jarvis**: GPU worker (AMD Ryzen 9900X, NVIDIA RTX 5070Ti)
  - Runs K3s agent with NVIDIA support
  - GPU workloads (AI/ML, rendering)
  - Development workstation

**Network Configuration:**
- K3s API: 6443 (HTTPS)
- Flannel VXLAN: 8472 (CNI networking)
- Kubelet metrics: 10250
- DNS: 53 (CoreDNS)
- HTTP/HTTPS: 80/443 (Ingress)

### ZFS Storage Management

Advanced ZFS configuration on akasha:
- **Pool**: "tank" (4x 1TB RAIDZ1)
- **ARC cache**: 5-8GB (optimized for 32GB RAM)
- **Auto-scrub**: Weekly on Sunday at 2 AM
- **Auto-snapshots** with retention:
  - Hourly: 24 snapshots
  - Daily: 14 snapshots
  - Weekly: 8 snapshots
  - Monthly: 12 snapshots
- **TRIM support**: Weekly for SSD longevity
- **Dataset optimizations**: Custom recordsize, compression, xattr per workload

**7 ZFS Datasets:**
- **media**: 1M recordsize, lz4 compression (large sequential files)
- **downloads**: 128K recordsize (mixed I/O)
- **k3s**: 128K recordsize, xattr=sa (container workloads)
- **paperless**, **immich**, **cloud**, **backups**: Various optimizations

### BTRFS Layout (akasha)

Declaratively managed via Disko with 6 subvolumes:
- `@root`: Root filesystem (compressed, snapshots enabled)
- `@home`: Home directories (compressed, snapshots enabled)
- `@nix`: Nix store (no CoW, no compression for performance)
- `@var-log`: System logs (compressed)
- `@rancher`: K3s data (no CoW for database performance)
- `@snapshots`: Backup snapshots

### Development Environment

Comprehensive tooling for multiple languages:
- **Languages**: Go, Rust, C/C++ (GCC)
- **Cloud**: Terraform, Azure CLI
- **Kubernetes**: kubectl, helm, k9s, flux
- **Version Control**: git, lazygit
- **Shell**: bash with starship prompt, zoxide, fzf

### Automated Validation

The flake includes automated checks:
- Build validation for all hosts
- Nix code formatting (nixfmt-rfc-style)
- config.nix syntax validation

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

Plus: starship (prompt), tmux, btop, lazygit, fzf, ncspot

## Network Architecture

### DNS Configuration

- **Primary**: Pi-hole (192.168.1.254)
- **Fallback**: Cloudflare (1.1.1.1, 1.0.0.1)

### Firewall Rules

jarvis server has extensive firewall configuration for:
- K3s cluster communication (6443, 8472, 10250)
- Web services (80, 443)
- DNS (53)
- NFS, Samba (commented out)
- Various application ports

## Storage Strategy

### Mixed Filesystem Approach

**BTRFS** (OS and system data):
- Benefits: Snapshots, compression, fast for small files
- Use: Root, home, nix store, logs
- Optimizations: No CoW for databases and Nix store

**ZFS** (Bulk data storage):
- Benefits: RAIDZ redundancy, proven data integrity, advanced features
- Use: Media, backups, application data
- Pool: "tank" (4x 1TB RAIDZ1)
- Features: Auto-scrub, auto-snapshots, ARC cache tuning

## Dotfile Management

Application configurations in `config/` are declaratively linked via home-manager:

- **bash**: Custom .bashrc with tmux integration, 8 predefined windows (term, nvim, yazi, k9s, logs, git, htop, azdotui)
- **nvim**: Lua-based configuration with 24 plugins (LSP, treesitter, telescope, neo-tree)
- **niri**: Compositor config (config.kdl) with dual monitor setup
- **waybar**: Compositor-specific status bar configs (niri, river, sway)
- **foot**: Terminal emulator styling
- **yazi**: File manager with plugins and theme

## Quick Start

### Fresh Installation (New System with Disko)

```bash
# 1. Boot NixOS installer USB
# 2. Clone the repository
git clone https://github.com/Liberis/nix-config /mnt/config
cd /mnt/config

# 3. Run Disko to partition and format disk
# WARNING: This will DESTROY all data on the disk!
# For mainframe (adjust device if needed):
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko \
  -- --mode disko /mnt/config#mainframe

# For jarvis desktop:
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko \
  -- --mode disko /mnt/config#jarvis

# For akasha server:
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko \
  -- --mode disko /mnt/config#akasha

# 4. Install NixOS
sudo nixos-install --flake /mnt/config#mainframe  # or #jarvis or #akasha

# 5. Reboot
reboot
```

### Existing Installation (Migration)

```bash
# Clone
git clone https://github.com/Liberis/nix-config ~/.config/nix-config
cd ~/.config/nix-config

# For existing installations, comment out disko.nix in hosts/*/default.nix
# and use your existing hardware-configuration.nix

# Build and switch
sudo nixos-rebuild switch --flake .#jarvis
sudo nixos-rebuild switch --flake .#mainframe
sudo nixos-rebuild switch --flake .#akasha
sudo nixos-rebuild switch --flake .#wsl

# Update flake inputs
nix flake update

# Run validation checks
nix flake check

# Format code
nix fmt
```

## Configuration Management

### Centralized Values

Edit `config.nix` to modify:
- User information
- Timezone and locale
- System state version
- Desktop preferences

### Adding a New Host

1. Create host directory: `hosts/new-host/`
2. Add `default.nix` and `hardware-configuration.nix`
3. Define host in `flake.nix`:
   ```nix
   nixosConfigurations.new-host = mkHost {
     hostname = "new-host";
     roles = [ "desktop" ];  # or "server", "wsl"
   };
   ```
4. Rebuild: `sudo nixos-rebuild switch --flake .#new-host`

### Remote Deployment

```bash
nixos-rebuild switch --flake .#hostname --target-host user@hostname --use-remote-sudo
```

## Unique Features

1. **Democratic-CSI User**: Special system user with sudo access to ZFS commands for Kubernetes CSI driver integration
2. **Declarative Disk Management**: Disko-based BTRFS partitioning for jarvis
3. **Role-Based Home-Manager**: Dynamic module loading based on host roles
4. **K3s Cluster**: Desktop as agent node (unusual for home setup, enables GPU workloads)
5. **Dual Storage Strategy**: BTRFS for OS, ZFS for data
6. **NVIDIA Wayland Support**: Open kernel modules with proper environment variables
7. **Automated tmux Sessions**: 8 predefined windows for different workflows

## Flake Inputs

- **nixpkgs**: nixos-unstable channel
- **home-manager**: master branch (follows nixpkgs)
- **nixos-wsl**: WSL integration
- **disko**: Declarative disk management

All inputs are locked in `flake.lock` for reproducibility.

## Key Design Decisions

1. **Flakes** - Reproducible builds with locked dependencies
2. **Role-based profiles** - DRY configuration across hosts
3. **Home-manager as module** - Integrated with NixOS rebuild
4. **Disko** - Declarative disk partitioning for new installs
5. **Hardware abstraction** - Separate CPU/GPU modules for flexibility
6. **Centralized config.nix** - Single source of truth for all values

## License

This configuration is personal and provided as-is for reference.

## Author

- **Name**: Liberis
- **Email**: libpatouch@gmail.com
- **Timezone**: Europe/Athens
