# Secrets Management with sops-nix

## Overview

This NixOS configuration uses **sops-nix** for encrypted secrets management. Secrets are encrypted with **age** encryption and stored directly in git, ensuring reproducible deployments while maintaining security.

**Key Benefits**:
- ✅ Secrets stored in git (encrypted, reproducible)
- ✅ Per-host decryption (only authorized hosts can read secrets)
- ✅ Declarative configuration (secrets as code)
- ✅ Automatic deployment (no manual file copying)
- ✅ Version control (track secret changes over time)

**Location**: `modules/nixos/system/secrets.nix`

**Secrets file**: `secrets/secrets.yaml` (encrypted)

---

## Architecture

### How sops-nix Works

```
┌─────────────────────────────────────────────────────────────┐
│                    secrets.yaml (encrypted)                 │
│  Encrypted with multiple age public keys (admin + hosts)   │
│              Safely committed to git                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ NixOS activation
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Host: /var/lib/sops-nix/key.txt            │
│         (age private key - generated on each host)          │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Decryption
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Decrypted secrets deployed to:                 │
│   /var/lib/democratic-csi/.ssh/id_ed25519                   │
│   /var/lib/rancher/k3s/agent-token                          │
│               (runtime only - never stored)                 │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

**1. Age Keys** (per host + admin)
- Each host generates a unique age key at `/var/lib/sops-nix/key.txt`
- Admin key stored in `~/.config/sops/age/keys.txt` (for editing secrets)
- Public keys are added to `.sops.yaml`

**2. .sops.yaml** (encryption rules)
- Defines which age keys can decrypt which secrets
- Controls access: admin + specific hosts only

**3. secrets.yaml** (encrypted secrets)
- YAML file containing all secrets
- Encrypted with multiple age public keys
- Committed to git safely

**4. secrets.nix** (NixOS module)
- Configures sops-nix
- Defines where secrets are deployed
- Sets ownership and permissions

---

## Initial Setup

### Step 1: Generate Admin Age Key

On your workstation (one time only):

```bash
# Create sops config directory
mkdir -p ~/.config/sops/age

# Generate admin age key (for editing secrets)
age-keygen -o ~/.config/sops/age/keys.txt

# Get your public key
age-keygen -y ~/.config/sops/age/keys.txt
# Output: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
```

**Save this public key** - you'll need it for `.sops.yaml`.

---

### Step 2: Deploy NixOS with sops-nix

First deployment generates age keys on each host:

```bash
# On each host (jarvis, mainframe, akasha)
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>

# The secrets module will automatically:
#   1. Generate /var/lib/sops-nix/key.txt (if missing)
#   2. Set proper permissions (0400, root-only)
#   3. Create empty secret placeholders
```

---

### Step 3: Collect Host Age Public Keys

On each host after deployment:

```bash
# Get the age public key for this host
sudo age-keygen -y /var/lib/sops-nix/key.txt

# Example outputs:
# jarvis:    age1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
# mainframe: age1rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
# akasha:    age1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
```

**Save these public keys** - you'll need them for `.sops.yaml`.

---

### Step 4: Update .sops.yaml with Real Keys

Edit `.sops.yaml` and replace placeholders with your actual age public keys:

```yaml
keys:
  # Admin key (from Step 1)
  - &admin age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p

  # Host keys (from Step 3)
  - &jarvis age1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
  - &mainframe age1rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
  - &akasha age1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

creation_rules:
  # Default: all secrets encrypted with all keys
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *admin
          - *jarvis
          - *mainframe
          - *akasha
```

---

### Step 5: Create and Encrypt Initial Secrets

```bash
# Copy template to create initial secrets file
cp secrets/secrets.yaml.example secrets/secrets.yaml

# Edit and add actual secret values
nano secrets/secrets.yaml

# Example content:
democratic-csi:
  ssh-private-key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    ... (your actual private key) ...
    -----END OPENSSH PRIVATE KEY-----

k3s:
  agent-token-jarvis: "K10abc123::server:def456"
  agent-token-akasha: "K10abc123::server:def456"
```

Encrypt the file with sops:

```bash
# Encrypt using .sops.yaml rules
sops -e secrets/secrets.yaml > secrets/secrets.yaml.enc

# Replace unencrypted file with encrypted version
mv secrets/secrets.yaml.enc secrets/secrets.yaml

# Verify encryption
head secrets/secrets.yaml
# Should see: sops:
#             mac: ENC[AES256_GCM,data:...]
#             lastmodified: "..."
```

---

### Step 6: Commit Encrypted Secrets

```bash
# Add files to git
git add .sops.yaml secrets/secrets.yaml

# Verify .gitignore is protecting unencrypted files
git status
# Should NOT see: secrets/*.dec, secrets/key.txt, etc.

# Commit
git commit -m "feat: add encrypted secrets with sops-nix"
git push
```

---

### Step 7: Deploy and Verify

```bash
# On each host, rebuild to deploy secrets
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>

# Verify secrets are deployed and accessible
# (only by their designated users)

# On akasha:
sudo ls -la /var/lib/democratic-csi/.ssh/id_ed25519
# Expected: -r-------- 1 democratic-csi democratic-csi ... id_ed25519

# On jarvis and akasha:
sudo ls -la /var/lib/rancher/k3s/agent-token
# Expected: -r-------- 1 root root ... agent-token

# Test secret content (should be decrypted)
sudo cat /var/lib/rancher/k3s/agent-token
# Expected: K10abc123::server:def456 (actual token, not encrypted)
```

---

## Daily Usage

### Editing Encrypted Secrets

The `sops` command handles encryption/decryption automatically:

```bash
# Edit secrets (sops decrypts temporarily in your editor)
sops secrets/secrets.yaml

# Your editor opens with DECRYPTED content:
# democratic-csi:
#   ssh-private-key: |
#     -----BEGIN OPENSSH PRIVATE KEY-----
#     ...

# Make changes, save, and exit
# sops automatically re-encrypts the file

# Commit changes
git add secrets/secrets.yaml
git commit -m "chore: rotate democratic-csi SSH key"
git push

# Deploy to hosts
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
```

---

### Adding New Secrets

**Step 1: Define secret in secrets.nix**

```nix
# modules/nixos/system/secrets.nix

sops.secrets = {
  # Existing secrets...

  # New secret
  "example/api-token" = {
    mode = "0400";
    owner = "myapp";
    group = "myapp";
    path = "/var/lib/myapp/api-token";
  };
};
```

**Step 2: Add secret value to secrets.yaml**

```bash
sops secrets/secrets.yaml

# Add to file:
example:
  api-token: "secret-api-token-value-here"
```

**Step 3: Deploy**

```bash
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>

# Verify deployment
sudo ls -la /var/lib/myapp/api-token
sudo cat /var/lib/myapp/api-token
```

---

### Adding New Host

When adding a new host to the cluster:

**Step 1: Deploy with sops-nix enabled**

```bash
# Deploy to new host (generates age key automatically)
sudo nixos-rebuild switch --flake /etc/nixos#newhost
```

**Step 2: Get host's age public key**

```bash
# On the new host
sudo age-keygen -y /var/lib/sops-nix/key.txt
# Output: age1nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
```

**Step 3: Update .sops.yaml**

```yaml
keys:
  - &admin age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
  - &jarvis age1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
  - &mainframe age1rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
  - &akasha age1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  - &newhost age1nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn  # NEW

creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *admin
          - *jarvis
          - *mainframe
          - *akasha
          - *newhost  # NEW
```

**Step 4: Re-encrypt secrets with new key**

```bash
# Update keys and re-encrypt (adds new host key)
sops updatekeys secrets/secrets.yaml

# Commit changes
git add .sops.yaml secrets/secrets.yaml
git commit -m "feat: add newhost to sops-nix encryption keys"
git push

# Deploy to new host again (now has access to secrets)
sudo nixos-rebuild switch --flake /etc/nixos#newhost
```

---

## Key Rotation

### Rotating SSH Keys

**Use case**: Rotate the democratic-csi SSH key after compromise or periodic security audit.

```bash
# Step 1: Generate new SSH key pair
ssh-keygen -t ed25519 -C "democratic-csi" -f ~/.ssh/democratic-csi-new

# Step 2: Update secrets with new private key
sops secrets/secrets.yaml

# Replace old key:
democratic-csi:
  ssh-private-key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ... (paste NEW private key here) ...
    -----END OPENSSH PRIVATE KEY-----

# Step 3: Update akasha authorized keys
# Edit hosts/akasha/default.nix
services.democratic-csi-user.authorizedKeys = [
  "ssh-ed25519 AAAAC3NzaC1... democratic-csi-new"  # NEW public key
  "ssh-ed25519 AAAAC3NzaC1... democratic-csi"      # OLD (keep for rollback)
];

# Step 4: Deploy to akasha
sudo nixos-rebuild switch --flake /etc/nixos#akasha

# Step 5: Update Kubernetes secret with new private key
kubectl delete secret democratic-csi-ssh -n democratic-csi
kubectl create secret generic democratic-csi-ssh \
  --from-file=id_ed25519=~/.ssh/democratic-csi-new \
  -n democratic-csi

# Step 6: Restart Democratic CSI pods
kubectl rollout restart deployment democratic-csi-controller -n democratic-csi

# Step 7: Verify connectivity
kubectl logs -n democratic-csi deployment/democratic-csi-controller

# Step 8: Remove old key from authorized keys (after 24h testing)
services.democratic-csi-user.authorizedKeys = [
  "ssh-ed25519 AAAAC3NzaC1... democratic-csi-new"  # Only new key
];

# Redeploy
sudo nixos-rebuild switch --flake /etc/nixos#akasha
```

---

### Rotating Age Keys

**Use case**: Rotate host age keys after host reinstall or key compromise.

```bash
# Step 1: Backup current age key (if accessible)
sudo cp /var/lib/sops-nix/key.txt /root/sops-key-backup.txt

# Step 2: Generate new age key
sudo age-keygen -o /var/lib/sops-nix/key.txt

# Step 3: Get new public key
sudo age-keygen -y /var/lib/sops-nix/key.txt
# Output: age1nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

# Step 4: Update .sops.yaml with new public key
# (Replace old key with new one for this host)

# Step 5: Re-encrypt all secrets with new key
sops updatekeys secrets/secrets.yaml

# Step 6: Commit and deploy
git add .sops.yaml secrets/secrets.yaml
git commit -m "chore: rotate age key for <hostname>"
git push

sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
```

---

## Troubleshooting

### Issue: "Failed to get the data key"

**Symptom**: Secrets fail to decrypt during activation.

**Cause**: Host's age key not in `.sops.yaml`, or secrets not re-encrypted.

**Fix**:
```bash
# Verify host age public key is in .sops.yaml
sudo age-keygen -y /var/lib/sops-nix/key.txt

# Check .sops.yaml contains this key
cat .sops.yaml

# If missing, add to .sops.yaml and update secrets
sops updatekeys secrets/secrets.yaml
```

---

### Issue: "Permission denied" when accessing secret

**Symptom**: Application cannot read secret file.

**Cause**: Incorrect ownership or permissions in `secrets.nix`.

**Fix**:
```bash
# Check current permissions
sudo ls -la /path/to/secret

# Update secrets.nix
sops.secrets."example/api-token" = {
  mode = "0400";        # Read-only by owner
  owner = "myapp";      # Ensure user exists
  group = "myapp";      # Ensure group exists
};

# Rebuild
sudo nixos-rebuild switch
```

---

### Issue: Age key missing after reinstall

**Symptom**: Secrets fail to decrypt after NixOS reinstall.

**Cause**: `/var/lib/sops-nix/key.txt` lost during reinstall.

**Fix**:
```bash
# Option 1: Restore from backup
sudo cp /root/sops-key-backup.txt /var/lib/sops-nix/key.txt
sudo chmod 400 /var/lib/sops-nix/key.txt

# Option 2: Rotate key (see "Rotating Age Keys" above)
```

---

### Issue: Cannot edit secrets with sops

**Symptom**: `sops secrets/secrets.yaml` fails with "no valid key found".

**Cause**: Admin age key not in `.sops.yaml` or wrong key in `~/.config/sops/age/keys.txt`.

**Fix**:
```bash
# Verify admin public key
age-keygen -y ~/.config/sops/age/keys.txt

# Ensure this matches admin key in .sops.yaml
grep "admin" .sops.yaml
```

---

### Issue: Secrets not updating after `sops` edit

**Symptom**: Old secret values persist after editing.

**Cause**: Forgot to rebuild after editing secrets.

**Fix**:
```bash
# Always rebuild after editing secrets
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>

# Verify secret content
sudo cat /path/to/secret
```

---

## Best Practices

### 1. Never Commit Unencrypted Secrets

✅ **DO**:
- Commit `secrets/secrets.yaml` (encrypted)
- Commit `secrets/secrets.yaml.example` (template)
- Commit `.sops.yaml` (public keys only)

❌ **DON'T**:
- Commit `secrets/*.dec` (unencrypted)
- Commit `secrets/key.txt` (private age keys)
- Commit `~/.config/sops/age/keys.txt` (admin private key)

The `.gitignore` is configured to prevent this.

---

### 2. Backup Age Keys

```bash
# Backup admin key (store securely, e.g., password manager)
cp ~/.config/sops/age/keys.txt ~/Backups/sops-admin-key-$(date +%Y%m%d).txt

# Backup host keys (store in secure offline storage)
sudo cp /var/lib/sops-nix/key.txt /root/sops-key-backup.txt
```

**Without these keys, you cannot decrypt secrets!**

---

### 3. Use Host-Specific Secrets When Possible

For secrets only needed on one host, create host-specific secret files:

```yaml
# .sops.yaml

creation_rules:
  # Jarvis-specific secrets
  - path_regex: secrets/jarvis\.yaml$
    key_groups:
      - age:
          - *admin
          - *jarvis  # Only jarvis can decrypt
```

```nix
# hosts/jarvis/default.nix

sops.defaultSopsFile = ../../secrets/jarvis.yaml;
```

This reduces exposure if one host is compromised.

---

### 4. Rotate Secrets Regularly

**Recommended schedule**:
- SSH keys: Every 6-12 months
- API tokens: Every 3-6 months
- Age keys: Only after compromise or host reinstall

**Always rotate immediately** after:
- Key compromise
- Team member departure
- Security incident

---

### 5. Test Secret Deployment

After editing secrets, always test on one host before deploying everywhere:

```bash
# Edit secrets
sops secrets/secrets.yaml

# Test on one host first
sudo nixos-rebuild switch --flake /etc/nixos#akasha

# Verify secrets deployed correctly
sudo cat /var/lib/democratic-csi/.ssh/id_ed25519

# If successful, deploy to other hosts
sudo nixos-rebuild switch --flake /etc/nixos#jarvis
sudo nixos-rebuild switch --flake /etc/nixos#mainframe
```

---

### 6. Audit Secret Access

Secrets are logged by the audit system. Review regularly:

```bash
# View secret access logs
sudo ausearch -k sops

# Check which processes accessed secrets
sudo ausearch -k sops | aureport -f

# Look for unauthorized access
sudo ausearch -k sops | grep -i "denied\|failed"
```

---

## Security Considerations

### Encryption at Rest

- ✅ Secrets encrypted in git with age encryption (modern, secure)
- ✅ Decrypted secrets only exist in memory during activation
- ✅ Persistent secrets deployed to `/var/lib` with restrictive permissions

### Encryption in Transit

- ✅ Secrets pulled from git over HTTPS/SSH
- ⚠️ Decrypted secrets transmitted over SSH when using `nixos-rebuild --target-host`
- ✅ Use local builds when possible: `nixos-rebuild switch` (no remote transmission)

### Access Control

- ✅ Only authorized age keys can decrypt secrets (per `.sops.yaml`)
- ✅ Only root can read `/var/lib/sops-nix/key.txt`
- ✅ Deployed secrets owned by specific users (e.g., democratic-csi)
- ✅ Audit logging tracks all secret access

### Key Security

- ⚠️ **Admin age key is single point of failure** - protect carefully
- ⚠️ **Host age keys must be backed up** - lost keys = lost secrets
- ✅ Age keys never leave the host (except for backup)

---

## Current Secrets

| Secret Path | Used By | Deployed To | Purpose |
|------------|---------|-------------|---------|
| `democratic-csi/ssh-private-key` | akasha | `/var/lib/democratic-csi/.ssh/id_ed25519` | K3s CSI driver ZFS authentication |
| `k3s/agent-token-jarvis` | jarvis | `/var/lib/rancher/k3s/agent-token` | K3s agent authentication to mainframe |
| `k3s/agent-token-akasha` | akasha | `/var/lib/rancher/k3s/agent-token` | K3s agent authentication to mainframe |

---

## References

- **sops-nix documentation**: https://github.com/Mic92/sops-nix
- **age encryption**: https://age-encryption.org/
- **SOPS (Secrets OPerationS)**: https://github.com/getsops/sops
- **Democratic CSI security**: See `DEMOCRATIC_CSI_SECURITY.md`
- **Age key format**: Ed25519 public keys (age1...)

---

## Quick Reference

```bash
# Edit encrypted secrets
sops secrets/secrets.yaml

# Get age public key for a host
sudo age-keygen -y /var/lib/sops-nix/key.txt

# Re-encrypt after adding new host key
sops updatekeys secrets/secrets.yaml

# Deploy secrets to host
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>

# Verify secret deployment
sudo ls -la /path/to/secret
sudo cat /path/to/secret

# Audit secret access
sudo ausearch -k sops
```

---

**Summary**: Secrets are encrypted with age, stored in git, and automatically decrypted during NixOS activation using host-specific age keys. This provides secure, reproducible, version-controlled secrets management for the entire cluster.
