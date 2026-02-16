# NixOS Configuration Organization Summary

## Overview

This document explains how software, services, and configurations are organized in this NixOS flake configuration. The architecture follows a **role-based modular design** with clear separation of concerns.

---

## Directory Structure

```
nix-config/
├── flake.nix              # Main flake entry point
├── profiles/              # Role-based configuration bundles
│   ├── base.nix           # Common to ALL hosts
│   ├── desktop.nix        # Full graphical workstation
│   ├── headless.nix       # Minimal server configuration
│   ├── storage-server.nix # ZFS + NFS storage functionality
│   └── wsl.nix            # Windows Subsystem for Linux
├── hosts/                 # Host-specific configurations
│   ├── jarvis/            # AMD Ryzen desktop (dual-boot, GPU worker)
│   ├── mainframe/         # Dell OptiPlex (K3s control plane)
│   ├── akasha/            # Lenovo P510 (storage server + K3s worker)
│   └── wsl/               # WSL2 development environment
└── modules/
    ├── nixos/             # System-level modules
    │   ├── desktop/       # Desktop environment (Wayland, display manager, programs)
    │   ├── hardware/      # Hardware support (GPU, audio, Bluetooth, ZFS, etc.)
    │   ├── services/      # Services (K3s, SSH, NFS, etc.)
    │   ├── system/        # Core system (locale, fonts, users, networking, base packages)
    │   ├── filesystem/    # Filesystem management (BTRFS quotas)
    │   └── utilities/     # Utility tools (network-tools)
    └── home-manager/      # User-level configuration
        ├── common.nix     # Programs for all users (neovim, tmux, btop, yazi)
        ├── shell.nix      # Shell enhancement (zsh, starship, modern CLI tools)
        ├── development.nix # Dev tools (Go, Rust, GCC, Terraform, Azure CLI)
        ├── communication.nix # Messaging (Telegram)
        ├── utilities.nix  # Desktop utilities (ncdu, dust, dua, deluge, cliphist)
        ├── media.nix      # Media control (playerctl, brightnessctl)
        ├── ai-ml.nix      # AI/ML tools (lmstudio, antigravity, claude-code)
        └── wayland.nix    # Wayland user packages (waybar, wofi, foot, etc.)
```

---

## Organization Principles

### 1. **Profiles = Role-Based Bundles**

Profiles import collections of modules based on the role of the system:

| Profile | Purpose | Imports |
|---------|---------|---------|
| **base** | Common to ALL hosts | Locale, fonts, users, networking, system packages, BTRFS quotas, network tools |
| **desktop** | Graphical workstation | Boot, kernel, GPU (NVIDIA), Wayland, audio, Bluetooth, display manager, programs, hardware tools |
| **headless** | Minimal server | Boot, SSH |
| **storage-server** | Storage functionality | ZFS, NFS server |
| **wsl** | WSL2 environment | Boot, SSH, WSL-specific tweaks |

### 2. **Hosts = Physical Machines**

Host configurations define:
- Which profile(s) to use
- Host-specific hardware (disko.nix, hardware-configuration.nix)
- Service configurations (K3s role, NFS mounts, etc.)
- Host-unique settings (IP addresses, quotas, etc.)

**Example: jarvis (Desktop)**
```nix
imports = [
  # Base profile (applied to all hosts)
  # Desktop profile (GUI, audio, Bluetooth, etc.)
  # Host-specific
  ./hardware-configuration.nix  # Dual-boot filesystems
  ../../modules/nixos/hardware/cpu-amd.nix
  ../../modules/nixos/hardware/gpu-nvidia.nix
  ../../modules/nixos/services/k3s-nvidia.nix  # K3s GPU worker
  ../../modules/nixos/services/nfs-client.nix  # NFS mounts
];
```

### 3. **Modules = Single Concern**

Each module handles ONE specific concern:

**Good module design**:
- `audio.nix` - PipeWire audio system
- `zfs.nix` - ZFS storage configuration
- `k3s-base.nix` - Kubernetes (K3s) setup
- `btrfs-quotas.nix` - BTRFS quota management

**Anti-pattern** (avoided in this config):
- `server.nix` containing audio, ZFS, NFS, K3s, monitoring, etc.

### 4. **System vs. User Packages**

**System packages** (`environment.systemPackages`):
- Available to all users
- Installed system-wide
- Examples: git, vim, curl, kubectl

**User packages** (`home.packages`):
- Per-user installation
- Desktop apps, TUI tools, dev utilities
- Examples: ncdu, dust, telegram-desktop, lazygit

---

## Package Categories

### System-Level Packages (`environment.systemPackages`)

#### **Base System Utilities** (`modules/nixos/system/system-packages.nix`)
Used by: **All hosts**

```nix
# Version control
git

# Network utilities
inetutils, iperf, curl, wget, bind

# Hardware information
pciutils, usbutils, lshw, dmidecode

# System monitoring
iftop, iotop, smartmontools, lm_sensors

# Disk utilities
hdparm, gparted, parted

# Security
openssl

# File utilities
vim, unzip, tree, bashmount

# Process utilities
psmisc
```

#### **Desktop Hardware Tools** (`modules/nixos/hardware/hardware-tools.nix`)
Used by: **Desktop hosts only** (jarvis)

```nix
powertop   # Power management analysis
solaar     # Logitech device manager
hd-idle    # Spin down idle drives
```

#### **Wayland System Utilities** (`modules/nixos/desktop/wayland.nix`)
Used by: **Desktop hosts only** (jarvis)

```nix
swayidle    # Idle session handler
waylock     # Screen locker
wlopm       # Monitor power management
wlrctl      # Window manager control
playerctl   # Media player control
jq          # JSON processor
```

#### **K3s Tools** (`modules/nixos/services/k3s-base.nix`)
Used by: **K3s hosts** (mainframe, akasha, jarvis)

```nix
kubectl, kubernetes-helm, helmfile, k9s
podman, crun, cni-plugins, nerdctl
fluxcd, runc, coreutils
```

#### **ZFS Storage** (`modules/nixos/hardware/zfs.nix`)
Used by: **Storage servers** (akasha)

```nix
zfs, zfs-prune-snapshots, sanoid, mbuffer
```

#### **NFS Server** (`modules/nixos/services/nfs.nix`)
Used by: **Storage servers** (akasha)

```nix
nfs-utils
```

#### **BTRFS Tools** (`hosts/akasha/default.nix`)
Used by: **Storage servers** (akasha)

```nix
btrfs-progs, compsize
```

#### **Dual-Boot Tools** (`hosts/jarvis/default.nix`)
Used by: **Dual-boot systems** (jarvis)

```nix
ntfs3g       # NTFS filesystem (shared Windows partition)
efibootmgr   # UEFI boot manager
```

---

### User-Level Packages (`home.packages`)

#### **Shell & CLI Tools** (`modules/home-manager/shell.nix`)
Used by: **All users**

```nix
# Shell
starship, zsh, detox

# Modern CLI replacements
zoxide, bat, eza, ripgrep, fd, fzf, tldr

# TUI apps
lazygit, ncspot

# Utilities
jq, convmv
```

#### **Development Tools** (`modules/home-manager/development.nix`)
Used by: **All users**

```nix
# Languages
go, rustc, cargo, gcc, gnumake

# Cloud/Infrastructure
terraform, azure-cli
```

#### **Desktop Utilities** (`modules/home-manager/utilities.nix`)
Used by: **Desktop users** (jarvis, wsl)

```nix
# Disk analysis
ncdu, dust, dua

# File management
zip, unzip, file

# Other
deluge, cliphist
```

#### **Desktop Wayland** (`modules/home-manager/wayland.nix`)
Used by: **Desktop users** (jarvis)

```nix
# Compositor & UI
waybar, wofi, foot, wl-clipboard, wideriver, way-displays
wlr-randr, bibata-cursors, conky

# Screenshot & recording
grim, slurp, wf-recorder

# Notifications & effects
mako, swww
```

#### **Communication** (`modules/home-manager/communication.nix`)
Used by: **Desktop users** (jarvis, wsl)

```nix
telegram-desktop
```

#### **Media Control** (`modules/home-manager/media.nix`)
Used by: **Desktop users** (jarvis)

```nix
playerctl, brightnessctl
```

#### **AI/ML Tools** (`modules/home-manager/ai-ml.nix`)
Used by: **Desktop users** (jarvis, wsl)

```nix
lmstudio, antigravity, claude-code
```

---

## Enabled Services

### System Services (`services.*`)

| Service | Module | Used By | Purpose |
|---------|--------|---------|---------|
| `dbus` | `system/base.nix` | All hosts | System message bus |
| `polkit` | `system/base.nix` | All hosts | Authorization |
| `networkmanager` | `system/networking.nix` | All hosts | Network management |
| `openssh` | `services/ssh.nix` | Headless, WSL | Remote access |
| `pipewire` | `hardware/audio.nix` | Desktop | Audio server |
| `bluetooth` | `hardware/bluetooth.nix` | Desktop | Bluetooth support |
| `seatd` | `desktop/wayland.nix` | Desktop | Seat management for Wayland |
| `sddm` | `desktop/display-manager.nix` | Desktop | Login manager |
| `k3s` | `services/k3s-base.nix` | K3s hosts | Kubernetes |
| `nfs.server` | `services/nfs.nix` | Storage servers | NFS file sharing |
| `zfs.*` | `hardware/zfs.nix` | Storage servers | ZFS management (scrub, snapshots, TRIM) |
| `journald` | Host configs | Servers | Log management |
| `btrfs-quotas` | `filesystem/btrfs-quotas.nix` | BTRFS hosts | Quota enforcement |

### Custom Systemd Services

| Service | Module | Purpose |
|---------|--------|---------|
| `btrfs-setup-quotas` | `filesystem/btrfs-quotas.nix` | Configure BTRFS quotas at boot |
| `btrfs-quota-check` | `filesystem/btrfs-quotas.nix` | Weekly quota usage report |

---

## Enabled Programs (`programs.*`)

### System Programs

| Program | Module | Used By | Purpose |
|---------|--------|---------|---------|
| `firefox` | `desktop/programs.nix` | Desktop | Web browser |
| `chromium` | `desktop/programs.nix` | Desktop | Chromium browser |
| `river-classic` | `desktop/programs.nix` | Desktop | Wayland window manager |
| `niri` | `desktop/programs.nix` | Desktop | Scrolling tiling compositor |
| `sway` | `desktop/wayland.nix` | Desktop | Wayland compositor |
| `winbox` | `utilities/network-tools.nix` | All hosts | RouterOS management |

### Home-Manager Programs

| Program | Module | Used By | Purpose |
|---------|--------|---------|---------|
| `home-manager` | `home-manager/common.nix` | All users | Home-Manager CLI |
| `neovim` | `home-manager/common.nix` | All users | Text editor |
| `tmux` | `home-manager/common.nix` | All users | Terminal multiplexer |
| `btop` | `home-manager/common.nix` | All users | System monitor |
| `yazi` | `home-manager/common.nix` | All users | File manager |

---

## Host-Specific Breakdown

### jarvis (Desktop Workstation)

**Profiles**: `base` + `desktop`

**Unique Features**:
- Dual-boot with Windows 11
- NVIDIA RTX 5070Ti GPU
- K3s GPU worker node
- NFS client (mounts from akasha)
- BTRFS quotas (284GB partition)
- Shared games partition (400GB NTFS)
- Dedicated K3s storage (2TB NVMe)

**Package Count**: ~150+ (system + user)

---

### mainframe (K3s Control Plane)

**Profiles**: `base` + `headless`

**Unique Features**:
- Dedicated K3s server (cluster init)
- Static IP: 192.168.10.10
- BTRFS quotas (240GB partition)
- Journal logging (2GB, 30-day retention)
- Minimal headless config

**Package Count**: ~80+ (system only)

---

### akasha (Storage Server & K3s Worker)

**Profiles**: `base` + `headless` + `storage-server`

**Unique Features**:
- ZFS storage pool (tank - RAIDZ1, 4x 1TB HDDs)
- NFS server (exports ZFS datasets)
- K3s worker node
- Auto-scrub (Sunday 02:00)
- Auto-snapshots (hourly/daily/weekly/monthly)
- BTRFS quotas (500GB SSD)
- Journal logging (500M, 7-day retention)

**Package Count**: ~100+ (system + user)

---

### wsl (Windows Subsystem for Linux)

**Profiles**: `base` + `wsl`

**Unique Features**:
- WSL2 integration
- SSH access
- Development environment
- Minimal filesystem (managed by WSL)

**Package Count**: ~80+ (user development tools)

---

## Adding New Software

### Where to Add Packages

**Question**: Where should I add a new package?

**Decision Tree**:

1. **Is it a system-wide utility needed on all hosts?**
   - YES → `modules/nixos/system/system-packages.nix`
   - Example: `htop`, `tmux`, `ncdu`

2. **Is it specific to desktop environments?**
   - YES → `modules/nixos/desktop/` or `modules/home-manager/` (desktop modules)
   - Example: `waybar`, `wofi`, `firefox`

3. **Is it for a specific hardware feature?**
   - YES → `modules/nixos/hardware/` module
   - Example: `solaar` (Logitech) → `hardware-tools.nix`

4. **Is it for a specific service?**
   - YES → Create or add to service module in `modules/nixos/services/`
   - Example: `kubectl` → `k3s-base.nix`

5. **Is it a user CLI tool?**
   - YES → `modules/home-manager/shell.nix` or `utilities.nix`
   - Example: `bat`, `eza`, `ripgrep`

6. **Is it only needed on one host?**
   - YES → `hosts/<hostname>/default.nix`
   - Example: `efibootmgr` (only jarvis for dual-boot)

### Creating a New Module

**When**: If you're adding 3+ related packages or a new service category

**Template**:
```nix
{ config, pkgs, lib, ... }:

{
  # Module description
  # What it provides
  # Which profile imports it
  # Dependencies

  # Service configuration
  services.myservice = {
    enable = true;
    # ...
  };

  # Related packages
  environment.systemPackages = with pkgs; [
    package1
    package2
  ];

  # Firewall rules (if needed)
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
```

**Location**: `modules/nixos/<category>/<name>.nix`

**Import in**: Appropriate profile (`profiles/`) or host config (`hosts/`)

---

## Recent Changes (Cleanup)

### Fixed Issues

1. **Removed duplicate `iperf`** from `system-packages.nix`
2. **Removed duplicate `openssl` and `hdparm`** from `hardware-tools.nix` (kept in system-packages.nix)
3. **Created `utilities/network-tools.nix`** and moved `programs.winbox` from `networking.nix`
4. **Deleted empty `wayland-packages.nix`** (consolidated into `wayland.nix`)
5. **Added organizational comments** to `system-packages.nix` (categorized by purpose)
6. **Added clarifying comments** to `wayland.nix` (explains split between system/user packages)

### New Modules

- **`modules/nixos/utilities/network-tools.nix`**: Network administration tools (Winbox, future: nmap, wireshark, etc.)
- **`modules/nixos/filesystem/btrfs-quotas.nix`**: BTRFS quota management with systemd services

---

## Best Practices

### ✅ DO

1. **Use profiles for roles**: Group related modules into role-based profiles
2. **Keep modules focused**: One module = one concern
3. **Comment liberally**: Explain what each module does, who uses it, and why
4. **Separate system and user packages**: System-wide in `environment.systemPackages`, user-specific in `home.packages`
5. **Host-specific config in hosts/**: Don't clutter modules with host-specific settings
6. **Use meaningful names**: `audio.nix`, `zfs.nix`, `k3s-base.nix` are self-documenting

### ❌ DON'T

1. **Mix concerns**: Don't put audio + GPU + networking in one module
2. **Duplicate packages**: Check if a package is already installed elsewhere
3. **Hard-code values**: Use variables and host-specific overrides
4. **Create empty modules**: If a module has no content, delete it
5. **Put everything in one file**: Split large modules into focused sub-modules
6. **Skip documentation**: Future you (and others) will thank you for comments

---

## Summary

**Configuration Grade: A-** (Excellent with minor cleanup opportunities)

**Strengths**:
- ✅ Clear role-based architecture
- ✅ Proper separation of concerns (hardware, services, desktop, system)
- ✅ Host-specific overrides in appropriate locations
- ✅ Good use of Home-Manager for user packages
- ✅ Well-documented modules with explanatory comments
- ✅ No critical organizational issues

**Improvements Made**:
- Removed duplicates
- Created dedicated network-tools module
- Consolidated Wayland packages
- Added categorization to system packages
- Clarified module purposes with comments

**Future Recommendations**:
- Consider role-based directory structure under `modules/nixos/`
- Add `SERVICES.md` documenting service dependencies and firewall ports
- Create monitoring/observability module for future metrics collection
- Consider storage-tools.nix to consolidate ZFS/BTRFS utilities

---

## Quick Reference

**Find where a package is installed**:
```bash
# System packages
rg "environment\.systemPackages" modules/

# User packages
rg "home\.packages" modules/home-manager/
```

**Find where a service is configured**:
```bash
rg "services\.<servicename>" modules/
```

**See what a host imports**:
```bash
cat hosts/<hostname>/default.nix | grep imports -A 20
```

**Check what profile includes**:
```bash
cat profiles/<profilename>.nix
```

---

**Last Updated**: 2026-02-15
**Maintained By**: Configuration owner
**For Questions**: See module-specific comments or this summary
