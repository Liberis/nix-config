# Host Renaming Summary

## Overview

All hosts have been renamed to match your preferred naming scheme.

## Host Name Changes

| Old Name | New Name | Hardware | Role |
|----------|----------|----------|------|
| `nixos` | **`jarvis`** | AMD Ryzen 9900X + NVIDIA RTX 5070Ti | Desktop workstation + GPU worker |
| `optiplex` | **`mainframe`** | Dell OptiPlex 3080 (i7-10710T) | K3s control plane |
| `jarvis` | **`akasha`** | Lenovo P510 (Xeon E2680v5) | Storage server + K3s worker |
| `wsl` | `wsl` | WSL2 Virtual | Development (unchanged) |

## New Cluster Topology

```
                  mainframe (K3s Control Plane)
                  Dell OptiPlex 3080
                  192.168.10.10
                       |
        +--------------+--------------+
        |                             |
   jarvis (GPU Worker)           akasha (Storage + Worker)
   AMD Ryzen 9900X                 Lenovo P510 Xeon
   NVIDIA RTX 5070Ti               28 cores, ZFS, NFS
   Desktop + Gaming                Storage Server
```

## Files Modified

### Host Configurations
- `hosts/nixos/` → `hosts/jarvis/`
  - Updated comments to reflect desktop workstation role
  - K3s server address points to mainframe
  - NFS mounts from akasha

- `hosts/optiplex/` → `hosts/mainframe/`
  - Updated TLS SANs to use mainframe hostname
  - Updated comments about worker nodes

- `hosts/jarvis/` → `hosts/akasha/`
  - K3s server address points to mainframe
  - Maintains all ZFS and NFS server functionality

### Flake Configuration
- `flake.nix`
  - Updated all `nixosConfigurations` keys
  - Updated all build checks (jarvis-build, mainframe-build, akasha-build)
  - Added hardware descriptions in comments

### Documentation
- `README.md`
  - Updated architecture diagram with new names
  - Updated host table
  - Updated all command examples
  - Updated K3s topology section
  - Updated Disko installation examples

- `ARCHITECTURE_REFACTOR.md`
  - Will be updated with new naming

## K3s Configuration Updates

All K3s worker nodes now point to the new control plane:

```nix
# Both jarvis and akasha
services.k3s = {
  enable = true;
  role = "agent";
  serverAddr = "https://192.168.10.10:6443"; # mainframe control plane
  tokenFile = "/var/lib/rancher/k3s/agent-token";
};
```

## Static IP Requirements

Ensure your network configuration matches:

| Host | IP Address | Hostname |
|------|------------|----------|
| mainframe | 192.168.10.10 | mainframe.local |
| akasha | 192.168.10.11 | akasha.local |
| jarvis | DHCP or static | jarvis.local |

## Migration Steps

### If Installing Fresh

Simply use the new hostnames:

```bash
# Install mainframe (control plane)
sudo nix run github:nix-community/disko -- --mode disko /mnt/config#mainframe
sudo nixos-install --flake /mnt/config#mainframe

# Install akasha (storage server)
sudo nix run github:nix-community/disko -- --mode disko /mnt/config#akasha
sudo nixos-install --flake /mnt/config#akasha

# Install jarvis (desktop)
sudo nix run github:nix-community/disko -- --mode disko /mnt/config#jarvis
sudo nixos-install --flake /mnt/config#jarvis
```

### If Migrating Existing Systems

#### Option 1: Rebuild with New Name (Recommended)

```bash
# On desktop (currently named nixos)
sudo nixos-rebuild switch --flake /path/to/config#jarvis

# On control plane (currently named optiplex)
sudo nixos-rebuild switch --flake /path/to/config#mainframe

# On storage server (currently named jarvis)
sudo nixos-rebuild switch --flake /path/to/config#akasha
```

This will change the hostname without reinstalling.

#### Option 2: Manual Hostname Update

If you prefer to keep using the old configuration temporarily:

```bash
# Update /etc/hostname manually
echo "jarvis" | sudo tee /etc/hostname

# Update /etc/hosts
sudo sed -i 's/nixos/jarvis/g' /etc/hosts

# Rebuild
sudo nixos-rebuild switch --flake /path/to/config#jarvis
```

## DNS/Network Updates

Update your DNS server (Pi-hole at 192.168.1.254) with new hostnames:
- Remove: nixos, optiplex, jarvis (old)
- Add: jarvis, mainframe, akasha (new)

Or update local /etc/hosts on machines that connect to these hosts.

## Verification

After rebuilding, verify:

```bash
# Check hostname
hostname

# Check K3s cluster (on mainframe)
kubectl get nodes

# Expected output:
# NAME        STATUS   ROLES                  AGE   VERSION
# mainframe   Ready    control-plane,master   ...   ...
# akasha      Ready    <none>                 ...   ...
# jarvis      Ready    <none>                 ...   ...

# Check NFS mounts (on jarvis desktop)
mount | grep akasha
```

## Benefits of New Naming

- **jarvis**: Desktop AI assistant theme (fitting for the main workstation)
- **mainframe**: Classic control system name (perfect for K3s control plane)
- **akasha**: Sanskrit for "ether/space" (appropriate for storage server)
- **Clear roles**: Names now better reflect primary functions
- **Scalable**: Room to add more thematic names (HAL, Deep Thought, etc.)

## Rollback

If needed, you can revert by:

```bash
git revert HEAD
sudo nixos-rebuild switch --flake .#old-hostname
```

## Notes

- All Disko configurations have been created for all physical hosts
- ZFS storage remains on akasha (no data migration needed)
- K3s cluster topology improved with dedicated control plane
- Fully declarative disk management across all hosts
