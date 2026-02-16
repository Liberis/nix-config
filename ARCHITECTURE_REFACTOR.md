# Architecture Refactoring Summary

## Overview

Refactored the NixOS configuration from a monolithic profile system to **granular, composable profiles** and introduced a new **dedicated K3s control plane** server.

## Changes Made

### 1. Profile Refactoring

**Old Profile Structure:**
- `base.nix` - Common configuration
- `server.nix` - Headless server (boot + SSH + implicit K3s)
- `desktop.nix` - Desktop environment (included K3s)
- `wsl.nix` - WSL configuration

**New Profile Structure:**
- `base.nix` - Common configuration (unchanged)
- `headless.nix` - **NEW** - Minimal headless (boot + SSH only)
- `storage-server.nix` - **NEW** - ZFS + NFS server
- `desktop.nix` - **MODIFIED** - Pure desktop environment (K3s removed)
- `wsl.nix` - WSL configuration (unchanged)

### 2. New Host: OptiPlex 3080

**Hardware:**
- Dell OptiPlex 3080
- Intel i7-10710T (6 cores)
- 16GB RAM
- 256GB NVMe

**Role:** Dedicated K3s control plane
- Runs K3s server with cluster init
- No workload scheduling (control plane isolation)
- Static IP: 192.168.10.10
- Profiles: base + headless

**Files Created:**
- `hosts/optiplex/default.nix`
- `hosts/optiplex/hardware-configuration.nix` (placeholder)

### 3. Host Role Changes

#### jarvis (Modified)
**Old Role:** K3s Server + Storage
**New Role:** K3s Worker + Storage

**Changes:**
- K3s role changed from `server` to `agent`
- Now connects to optiplex (192.168.10.10:6443)
- Profiles: base + headless + storage-server
- Removed direct ZFS/NFS imports (now via storage-server profile)

**Still Provides:**
- ZFS storage pool "tank"
- NFS server for cluster storage
- 28-core compute node

#### nixos (Modified)
**Old Role:** K3s Agent (to jarvis)
**New Role:** K3s GPU Worker (to optiplex)

**Changes:**
- Now connects to optiplex control plane
- K3s configuration now in host file (not profile)
- Profiles: base + desktop (desktop no longer includes K3s)

**Still Provides:**
- NVIDIA GPU for AI/ML workloads
- Full Wayland desktop environment
- Development workstation

#### wsl (Unchanged)
**Role:** Development environment
- No changes

### 4. K3s Cluster Topology

**Old Architecture:**
```
jarvis (K3s Server) -----> nixos (K3s Agent + GPU)
   |
   +-- ZFS Storage
   +-- NFS Server
   +-- Compute workloads
```

**New Architecture:**
```
                  optiplex (K3s Server)
                  Control Plane Only
                  192.168.10.10
                       |
        +--------------+--------------+
        |                             |
   jarvis (Agent)               nixos (Agent)
   Storage + Compute            GPU Worker
   28 cores, 32GB               Ryzen 9900X
   ZFS, NFS                     RTX 5070Ti
```

**Benefits:**
- **Separation of Concerns:** Control plane separate from workloads
- **High Availability Ready:** Can add 2nd control plane node easily
- **Better Resource Utilization:** jarvis 28 cores available for workloads
- **Stability:** Control plane not affected by storage or compute issues
- **Best Practice:** Follows Kubernetes production patterns

### 5. Updated Files

**Modified:**
- `flake.nix` - Added optiplex host, renamed server → headless
- `profiles/desktop.nix` - Removed K3s nvidia import
- `profiles/server.nix` → `profiles/headless.nix` - Renamed
- `hosts/jarvis/default.nix` - Changed to K3s agent, new control plane
- `hosts/nixos/default.nix` - Updated to point to optiplex
- `README.md` - Updated architecture diagrams and documentation

**Created:**
- `profiles/storage-server.nix` - ZFS + NFS profile
- `hosts/optiplex/default.nix` - Control plane configuration
- `hosts/optiplex/hardware-configuration.nix` - Placeholder

**Deleted:**
- `profiles/server.nix` - Replaced by headless.nix

## Validation

All configurations build successfully:
```bash
nix flake check
```

Output:
- ✅ nixos-build
- ✅ optiplex-build
- ✅ jarvis-build
- ✅ wsl-build
- ✅ nixfmt-check
- ✅ config-valid

## Next Steps

### 1. Install OptiPlex

```bash
# On the OptiPlex 3080:
# 1. Boot NixOS installer
# 2. Generate hardware configuration
sudo nixos-generate-config --root /mnt

# 3. Copy hardware-configuration.nix to this repo
cp /mnt/etc/nixos/hardware-configuration.nix \
   /path/to/nix-config/hosts/optiplex/

# 4. Set static IP in your router or adjust networking config
# 5. Install
sudo nixos-install --flake .#optiplex
```

### 2. Migrate jarvis

```bash
# On jarvis (after optiplex is running):
# 1. Stop K3s
sudo systemctl stop k3s

# 2. Backup K3s data (optional but recommended)
sudo cp -r /var/lib/rancher/k3s /root/k3s-backup

# 3. Switch to new configuration
sudo nixos-rebuild switch --flake .#jarvis

# 4. Copy agent token from optiplex
# On optiplex:
sudo cat /var/lib/rancher/k3s/server/agent-token

# On jarvis:
sudo mkdir -p /var/lib/rancher/k3s
echo "TOKEN_FROM_OPTIPLEX" | sudo tee /var/lib/rancher/k3s/agent-token

# 5. Start K3s agent
sudo systemctl start k3s
```

### 3. Migrate nixos

```bash
# On nixos desktop:
# Same process as jarvis
sudo systemctl stop k3s
sudo nixos-rebuild switch --flake .#nixos
# Add agent token
sudo systemctl start k3s
```

### 4. Verify Cluster

```bash
# On optiplex:
kubectl get nodes

# Should show:
# NAME       STATUS   ROLES                  AGE   VERSION
# optiplex   Ready    control-plane,master   ...   ...
# jarvis     Ready    <none>                 ...   ...
# nixos      Ready    <none>                 ...   ...
```

## Architecture Benefits

### Granular Profiles
- **Composable:** Mix and match profiles as needed
- **Explicit:** Each host clearly states what it includes
- **Maintainable:** Changes to storage don't affect desktop config
- **Scalable:** Easy to add new combinations

### Dedicated Control Plane
- **Production-Ready:** Follows Kubernetes best practices
- **Reliable:** Control plane isolated from workload issues
- **Scalable:** Can add more worker nodes easily
- **HA-Ready:** Can add 2nd control plane for redundancy

### Clear Separation of Concerns
- **Control:** optiplex
- **Storage:** jarvis (ZFS + NFS)
- **Compute:** jarvis (28 cores)
- **GPU:** nixos (RTX 5070Ti)
- **Desktop:** nixos (Wayland)

## Rollback Plan

If issues arise, rollback is simple:

```bash
# Restore to previous generation
sudo nixos-rebuild switch --rollback
```

Or revert git changes:

```bash
git revert HEAD
sudo nixos-rebuild switch --flake .#hostname
```

## Notes

- The k3s-base.nix module has hardcoded values (IP: 192.168.10.11, iface: ens1) that may need adjustment for your network
- OptiPlex hardware-configuration.nix is a placeholder - replace after installation
- All hosts now need agent tokens copied from the control plane
- Consider setting up automatic token distribution (e.g., via NFS mount or secrets management)
