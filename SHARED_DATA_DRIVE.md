# Shared 2TB Data Drive Configuration

## Overview

The 2TB NVMe PCIe5 drive is configured as shared storage accessible from both Windows and NixOS on the jarvis system.

**Hardware**:
- Drive: 2TB NVMe PCIe5
- Device: `/dev/nvme1n1` (typically)
- Format: NTFS (maximum compatibility)
- Windows: Appears as `D:` drive
- NixOS: Mounted at `/mnt/data`

---

## Initial Setup (During Windows Installation)

### In Windows

**Format the drive**:
```
1. Open Disk Management (Win + X → Disk Management)
2. Find the 2TB drive (should show as "Disk 1" or similar)
3. Right-click → Initialize Disk → GPT
4. Right-click unallocated space → New Simple Volume
   - Drive letter: D:
   - File system: NTFS
   - Volume label: Data
   - Allocation unit size: Default (4096 bytes)
   - Enable "Perform a quick format"
5. Finish
```

**Verify**:
- Open File Explorer
- Drive D: should appear with label "Data"
- Total size: ~1.81 TB (2TB formatted)

---

## NixOS Configuration

The 2TB data drive mount is already configured in `hosts/jarvis/default.nix`:

```nix
fileSystems."/mnt/data" = {
  device = "/dev/disk/by-label/Data";
  fsType = "ntfs";
  options = [
    "rw"           # Read-write access
    "uid=1000"     # Your user ID
    "gid=100"      # Users group
    "dmask=022"    # Directory permissions (755)
    "fmask=133"    # File permissions (644)
  ];
};
```

**How it works**:
- Device identified by label "Data" (set in Windows)
- NTFS driver provides read/write access
- Files created in NixOS are owned by uid 1000 (your user)
- Directories get 755 permissions, files get 644 permissions

---

## Usage

### From Windows

**Access**:
```
D:\
```

**Create folders** (recommended structure):
```
D:\
├── Documents\      (shared documents)
├── Downloads\      (shared downloads)
├── Projects\       (code projects)
├── Media\
│   ├── Photos\
│   ├── Videos\
│   └── Music\
├── Games\          (game libraries)
└── Backups\
```

### From NixOS

**Access**:
```bash
cd /mnt/data
ls -la
```

**Create files**:
```bash
# Files created in NixOS are accessible in Windows
echo "Hello from NixOS" > /mnt/data/test.txt

# Verify from Windows: D:\test.txt should exist
```

**Symlink to home directory** (optional):
```bash
# Create convenient symlinks in your home folder
ln -s /mnt/data/Documents ~/Documents-Shared
ln -s /mnt/data/Projects ~/Projects-Shared
ln -s /mnt/data/Media ~/Media

# Now access shared data from home directory
ls ~/Documents-Shared
```

---

## Recommended Workflows

### Software Development

**Store projects on shared drive**:
```bash
# Clone repos to shared drive
cd /mnt/data/Projects
git clone https://github.com/user/repo.git

# Access from both OSes
# Windows: D:\Projects\repo
# NixOS:   /mnt/data/Projects/repo
```

**Benefits**:
- Work on same codebase from both OSes
- No need to duplicate files
- Git history shared between boots

**Note**: Some language tools store config in home directory
- Node.js: `node_modules` may need separate installs
- Python: Virtual environments won't work across OSes
- Rust: `target/` directory is OS-specific

**Best practice**: Keep source code on shared drive, build artifacts on local filesystems

### Gaming

**Steam Library on D:**
```
Windows Steam:
Settings → Downloads → Steam Library Folders → Add D:\Games\Steam

NixOS Steam (via Proton):
~/.steam/steam/steamapps → symlink to /mnt/data/Games/Steam
```

**Note**: Some games may not share save files between Windows/Proton

### Media Files

**Store once, access from both**:
```
D:\Media\Photos\  → NixOS: /mnt/data/Media/Photos/
D:\Media\Videos\  → NixOS: /mnt/data/Media/Videos/
D:\Media\Music\   → NixOS: /mnt/data/Media/Music/
```

**Photo management**:
- Windows: Use Photos app, Lightroom, etc.
- NixOS: Use GNOME Photos, Shotwell, Darktable, etc.
- All access the same files on D:/Media/Photos/

---

## Performance Considerations

### NTFS Performance on Linux

**NTFS-3G driver** (used by default):
- ✅ Full read/write support
- ✅ POSIX permissions emulation
- ⚠️ Slightly slower than native Linux filesystems (ext4, btrfs, xfs)
- ⚠️ No Linux-native features (CoW, snapshots, etc.)

**For best performance**:
- Use for large files (media, ISOs, backups)
- Avoid for build artifacts (`node_modules`, `target/`, etc.)
- Database files should be on native filesystem

### Alternative: Kernel NTFS3 Driver

**NixOS has newer kernel NTFS3 driver** (faster, but experimental):
```nix
# In hosts/jarvis/default.nix (NOT recommended yet)
fileSystems."/mnt/data" = {
  device = "/dev/disk/by-label/Data";
  fsType = "ntfs3";  # Kernel driver instead of ntfs-3g
  options = [ "rw" "uid=1000" "gid=100" ];
};
```

**Note**: NTFS3 is faster but less mature. Stick with `ntfs` (ntfs-3g) for stability.

---

## Backup Strategy

### Windows Backup

**Use Windows built-in backup**:
```
Settings → Update & Security → Backup → Add a drive
```

**Or use third-party tools**:
- Veeam Agent for Windows (free)
- Macrium Reflect
- Acronis True Image

### NixOS Backup

**rsync to external drive**:
```bash
# Backup shared data
sudo rsync -av --progress /mnt/data/ /mnt/external-backup/jarvis-data/

# Automated with systemd timer
# (can be configured in NixOS)
```

**BTRFS snapshots for NixOS system**:
```bash
# Snapshot home directory
sudo btrfs subvolume snapshot /home /.snapshots/home-$(date +%Y%m%d)

# Note: 2TB NTFS drive doesn't support BTRFS snapshots
```

---

## Troubleshooting

### Drive Not Mounting in NixOS

**Check device name**:
```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT

# Expected:
# nvme1n1      2TB   disk
# └─nvme1n1p1  2TB   part  ntfs    Data
```

**Mount manually**:
```bash
sudo mkdir -p /mnt/data
sudo mount -t ntfs /dev/nvme1n1p1 /mnt/data
```

**If mount succeeds**, issue is with NixOS config. Verify:
```nix
fileSystems."/mnt/data" = {
  device = "/dev/disk/by-label/Data";  # Label must match!
  fsType = "ntfs";
};
```

### Permission Denied in NixOS

**Check user ID**:
```bash
id -u  # Should output 1000
```

**If different**, update config:
```nix
fileSystems."/mnt/data" = {
  options = [
    "uid=YOUR_UID_HERE"  # Use output from `id -u`
  ];
};
```

### Slow Performance in NixOS

**Check if using ntfs-3g**:
```bash
mount | grep /mnt/data
# Should show: /dev/nvme1n1p1 on /mnt/data type fuseblk (ntfs-3g)
```

**For large file transfers**: NTFS-3G is fine
**For many small files**: Use native Linux filesystem

### Files Created in Windows Not Visible in NixOS

**Ensure Windows Fast Startup is disabled**:
```
Control Panel → Power Options → Choose what power buttons do
→ Uncheck "Turn on fast startup"
```

**Disable hibernation** (optional):
```powershell
# In Windows PowerShell (Admin)
powercfg /hibernate off
```

**Why**: Fast Startup leaves NTFS in hibernated state, making it read-only in Linux

### Filesystem Corruption

**Check from Windows**:
```
Open Command Prompt (Admin):
chkdsk D: /F
```

**Check from NixOS**:
```bash
sudo ntfsfix /dev/nvme1n1p1
```

**Note**: Always unmount cleanly before switching OSes to prevent corruption

---

## Best Practices

1. **Disable Fast Startup in Windows** (prevents mount issues)
2. **Shut down cleanly** - avoid force reboots when files are open
3. **Use for data, not programs** - install apps on native OS filesystems
4. **Regular backups** - NTFS corruption can happen (rare but possible)
5. **Keep important data versioned** - use Git for code, cloud sync for documents
6. **Test permissions** - verify you can create/delete files from both OSes

---

## Summary

| Aspect | Windows | NixOS |
|--------|---------|-------|
| **Mount point** | `D:\` | `/mnt/data` |
| **Filesystem** | NTFS | NTFS (via ntfs-3g) |
| **Permissions** | Native Windows ACLs | Emulated POSIX (uid/gid) |
| **Performance** | Native (fast) | Good (slightly slower) |
| **Use cases** | All file types | Large files, shared data |

**Perfect for**:
- Documents, photos, videos, music
- Source code repositories
- Game libraries (with caveats)
- Shared downloads

**Not ideal for**:
- Build artifacts (`node_modules`, `target/`)
- Databases (SQLite, PostgreSQL data)
- OS-specific application data
- Frequent small file I/O

---

**See also**:
- `JARVIS_INSTALLATION_GUIDE.md` - Complete dual-boot setup
- `hosts/jarvis/default.nix` - NixOS mount configuration
