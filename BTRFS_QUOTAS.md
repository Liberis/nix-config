# BTRFS Quotas Configuration

## Overview

BTRFS quotas are enabled on all hosts to prevent any single subvolume from consuming the entire disk. This protects against:
- Runaway logs filling `/var/log`
- Nix store growing unbounded in `/nix`
- K3s data consuming all space in `/var/lib/rancher`
- User data filling `/home`

## Quota Allocations by Host

### jarvis (Desktop Workstation - 284GB BTRFS)

```nix
services.btrfs-quotas = {
  enable = true;
  quotas = {
    "@root" = "60G";       # OS files
    "@home" = "100G";      # User files (documents, downloads, configs)
    "@nix" = "80G";        # Nix store (desktop packages, GUI apps)
    "@var-log" = "10G";    # Logs
    "@rancher" = "20G";    # K3s worker data
    "@snapshots" = "14G";  # BTRFS snapshots
  };
};
```

**Total**: 284GB allocated
**Note**: Games on separate 400GB NTFS partition, K3s volumes on 2TB drive

### mainframe (Control Plane - 240GB BTRFS)

```nix
services.btrfs-quotas = {
  enable = true;
  quotas = {
    "@root" = "50G";       # OS files
    "@home" = "10G";       # Minimal (headless)
    "@nix" = "80G";        # Nix store
    "@var-log" = "10G";    # K8s API logs
    "@rancher" = "80G";    # etcd data (CRITICAL)
    "@snapshots" = "10G";  # Snapshots
  };
};
```

**Total**: 240GB allocated
**Critical**: `@rancher` must have room for etcd to grow

### akasha (Storage Server - 500GB BTRFS)

```nix
services.btrfs-quotas = {
  enable = true;
  quotas = {
    "@root" = "80G";       # OS files
    "@home" = "50G";       # Minimal (headless)
    "@nix" = "200G";       # Nix store (largest allocation)
    "@var-log" = "20G";    # Logs
    "@rancher" = "100G";   # K3s worker data
    "@snapshots" = "50G";  # Snapshots
  };
};
```

**Total**: 500GB allocated
**Note**: ZFS pool "tank" on separate disks (not subject to BTRFS quotas)

---

## How It Works

### Automatic Setup

When the system boots:
1. `systemd.services.btrfs-setup-quotas` runs
2. Enables BTRFS quotas on root filesystem
3. Applies quota limits to each subvolume
4. Logs quota status

### Weekly Monitoring

A systemd timer (`btrfs-quota-check`) runs weekly to:
- Display quota usage report
- Warn if any subvolume exceeds 90% of quota
- Log results to systemd journal

---

## Managing Quotas

### Check Current Usage

```bash
# Show quota usage for all subvolumes
sudo btrfs qgroup show -reF /

# Human-readable format
sudo btrfs qgroup show -reF --human-readable /

# Example output:
# Qgroupid    Referenced  Exclusive   Path
# --------    ----------  ---------   ----
# 0/256       45.2GiB     45.2GiB     @root
# 0/257       32.1GiB     32.1GiB     @home
# 0/258       120.5GiB    120.5GiB    @nix
# 0/259       2.3GiB      2.3GiB      @var-log
# 0/260       15.8GiB     15.8GiB     @rancher
# 0/261       8.1GiB      8.1GiB      @snapshots
```

### Check Which Subvolumes Are Near Limit

```bash
# Show subvolumes using >80% of quota
sudo btrfs qgroup show -reF / | awk 'NR>2 && $3 > 0 && ($2/$3) > 0.8 {
  printf "%s using %.0f%% of quota\n", $4, ($2/$3)*100
}'
```

### Manually Adjust Quotas

If a subvolume needs more space:

```bash
# Increase @nix quota to 250GB
sudo btrfs qgroup limit 250G /@nix /

# Remove quota limit entirely (not recommended)
sudo btrfs qgroup limit none /@nix /
```

**Important**: Manual changes will be reset on next boot! To make permanent changes, edit the host configuration:

```nix
# In hosts/hostname/default.nix
services.btrfs-quotas.quotas."@nix" = "250G";
```

Then rebuild:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#hostname
```

### Disable Quotas Entirely

To disable quotas on a specific host:

```nix
# In hosts/hostname/default.nix
services.btrfs-quotas.enable = false;
```

To disable quotas on the live system (temporary):
```bash
sudo systemctl stop btrfs-setup-quotas
sudo btrfs quota disable /
```

---

## Troubleshooting

### Issue: "Cannot write, quota exceeded"

**Symptom**: Applications fail with "No space left on device" but `df -h` shows space available.

**Cause**: A subvolume has reached its quota limit.

**Solution**:

1. **Identify which subvolume is full**:
   ```bash
   sudo btrfs qgroup show -reF /
   ```

2. **Temporarily increase the quota**:
   ```bash
   # Example: increase @nix to 250G
   sudo btrfs qgroup limit 250G /@nix /
   ```

3. **Clean up space** (if possible):
   ```bash
   # For /nix
   sudo nix-collect-garbage -d

   # For /var/log
   sudo journalctl --vacuum-size=500M

   # For @home
   # Manually delete old files
   ```

4. **Make quota change permanent**:
   Edit host configuration and rebuild.

### Issue: Quota Status Shows "none"

**Symptom**: `btrfs qgroup show` returns empty or shows no limits.

**Cause**: Quotas not enabled or service failed.

**Solution**:

```bash
# Check service status
sudo systemctl status btrfs-setup-quotas

# Manually enable quotas
sudo btrfs quota enable /

# Re-run quota setup
sudo systemctl restart btrfs-setup-quotas

# Verify
sudo btrfs qgroup show -reF /
```

### Issue: "Qgroup scan failed"

**Symptom**: Quota commands fail with qgroup errors.

**Cause**: BTRFS quota tree out of sync.

**Solution**:

```bash
# Rescan quota tree (can take time on large filesystems)
sudo btrfs quota rescan -w /

# Check status
sudo btrfs qgroup show -reF /
```

---

## Best Practices

### 1. Monitor Regularly

Check quota usage weekly or monthly:
```bash
# Add to crontab or use systemd timer
sudo btrfs qgroup show -reF --human-readable /
```

### 2. Leave Headroom

- Don't allocate 100% of disk space to quotas
- Leave 10-20% unallocated for:
  - BTRFS metadata
  - Filesystem overhead
  - Future growth
  - Emergency space

### 3. Adjust Based on Usage

After running for a few weeks, review actual usage:
```bash
# See what's actually being used
sudo btrfs filesystem df /
sudo btrfs qgroup show -reF /
```

Reallocate quotas based on real-world usage patterns.

### 4. Prioritize Critical Subvolumes

**Critical subvolumes** (must never fill up):
- `@root` - OS won't boot if full
- `@rancher` on mainframe - etcd failure if full

**Less critical**:
- `@snapshots` - can delete old snapshots
- `@var-log` - can vacuum logs

### 5. Use Compression

BTRFS compression (`compress=zstd`) is enabled on:
- `@root`
- `@home`
- `@var-log`
- `@snapshots`

This effectively multiplies quota space by ~1.5-2x.

---

## Quota Recommendations by Subvolume

### @root (OS Files)
- **Minimum**: 30GB
- **Recommended**: 50-80GB
- **Growth**: Grows with system updates, kernel versions
- **Cleanup**: `nix-collect-garbage`, remove old kernels

### @home (User Files)
- **Desktop**: 100GB+
- **Server**: 10-50GB
- **Growth**: User-dependent
- **Cleanup**: Manual file deletion

### @nix (Nix Store)
- **Minimal**: 50GB
- **Desktop**: 80-150GB (GUI apps, dev tools)
- **Server**: 80-200GB (depending on services)
- **Growth**: Grows with package updates
- **Cleanup**: `nix-collect-garbage -d` (aggressive)

### @var-log (System Logs)
- **Minimum**: 5GB
- **Recommended**: 10-20GB
- **Growth**: Depends on verbosity, retention
- **Cleanup**: `journalctl --vacuum-size=500M`

### @rancher (K3s Data)
- **Worker**: 20-100GB
- **Control Plane**: 50-100GB (etcd grows over time)
- **Growth**: Depends on cluster size, resources
- **Cleanup**: Delete old container images, PVs

### @snapshots (Backups)
- **Minimum**: 10GB
- **Recommended**: 10-50GB
- **Growth**: Based on snapshot retention policy
- **Cleanup**: Delete old snapshots manually

---

## Integration with NixOS

### Configuration Structure

```nix
# modules/nixos/filesystem/btrfs-quotas.nix
# Defines the quota module

# profiles/base.nix
# Imports the quota module (available to all hosts)

# hosts/hostname/default.nix
# Enables and configures quotas per-host
services.btrfs-quotas = {
  enable = true;
  quotas = { ... };
};
```

### Automatic Application

Quotas are applied:
1. **During boot**: `btrfs-setup-quotas.service` runs
2. **After rebuild**: When you run `nixos-rebuild switch`
3. **Idempotent**: Safe to run multiple times

### Systemd Services

```bash
# View quota setup service
sudo systemctl status btrfs-setup-quotas

# View quota check timer
sudo systemctl status btrfs-quota-check.timer

# Manually trigger quota check
sudo systemctl start btrfs-quota-check

# View logs
sudo journalctl -u btrfs-setup-quotas
sudo journalctl -u btrfs-quota-check
```

---

## Example Workflows

### Scenario 1: Nix Store Full

```bash
# 1. Identify the issue
$ sudo btrfs qgroup show -reF /
Qgroupid    Referenced  Exclusive   Max Rfer    Path
0/258       85.2GiB     85.2GiB     80.0GiB     @nix

# 2. Temporarily increase quota
$ sudo btrfs qgroup limit 100G /@nix /

# 3. Clean up
$ sudo nix-collect-garbage -d
$ nix-store --gc
$ nix-store --optimise

# 4. Check new usage
$ sudo btrfs qgroup show -reF /
Qgroupid    Referenced  Exclusive   Max Rfer    Path
0/258       65.3GiB     65.3GiB     100.0GiB    @nix

# 5. Decide: keep 100G or revert to 80G
# Edit hosts/hostname/default.nix if keeping 100G
$ sudo nixos-rebuild switch --flake /etc/nixos#hostname
```

### Scenario 2: Logs Filling Up

```bash
# 1. Check log usage
$ sudo btrfs qgroup show -reF / | grep var-log
0/259       12.8GiB     12.8GiB     10.0GiB     @var-log

# 2. Vacuum logs
$ sudo journalctl --vacuum-size=2G
$ sudo journalctl --vacuum-time=7d

# 3. Adjust retention in configuration
# In hosts/hostname/default.nix:
services.journald.extraConfig = ''
  SystemMaxUse=2G
  MaxRetentionSec=7day
'';

# 4. Rebuild
$ sudo nixos-rebuild switch --flake /etc/nixos#hostname
```

### Scenario 3: Adding New Subvolume

```bash
# 1. Create new BTRFS subvolume
$ sudo btrfs subvolume create /@custom

# 2. Add to quota configuration
# In hosts/hostname/default.nix:
services.btrfs-quotas.quotas."@custom" = "50G";

# 3. Add filesystem mount
fileSystems."/mnt/custom" = {
  device = "/dev/disk/by-label/nixos";
  fsType = "btrfs";
  options = [ "subvol=@custom" "compress=zstd" "noatime" ];
};

# 4. Rebuild and verify
$ sudo nixos-rebuild switch --flake /etc/nixos#hostname
$ sudo btrfs qgroup show -reF /
```

---

## Summary

**Quotas are enabled by default** on all BTRFS hosts to prevent disk space issues.

**Key commands**:
```bash
# Check usage
sudo btrfs qgroup show -reF /

# Temporarily adjust
sudo btrfs qgroup limit 250G /@nix /

# Permanent adjustment
# Edit host config, then:
sudo nixos-rebuild switch --flake /etc/nixos#hostname

# Monitor
sudo journalctl -u btrfs-quota-check
```

**Remember**: Quotas protect your system from runaway processes and ensure critical services always have space to operate.
