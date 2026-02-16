{ config, pkgs, lib, inputs, ... }:

{
  # Secrets management using sops-nix
  # Secrets are encrypted with age and stored in git
  # Decrypted at activation time using host-specific age keys
  #
  # Setup:
  #   1. Install sops: nix-shell -p sops
  #   2. Generate age key: age-keygen -o ~/.config/sops/age/keys.txt
  #   3. Create .sops.yaml in repo root
  #   4. Create secrets/secrets.yaml and encrypt with sops
  #
  # Usage:
  #   sops secrets/secrets.yaml  # Edit encrypted secrets
  #
  # See: SECRETS_MANAGEMENT.md for complete guide

  # Import sops-nix module
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # Configure sops
  sops = {
    # Default sops file for all hosts
    defaultSopsFile = ../../../secrets/secrets.yaml;

    # Age key file location (generated on each host)
    age = {
      # Path to age key (generated during setup)
      keyFile = "/var/lib/sops-nix/key.txt";

      # Generate key if missing (for initial setup)
      generateKey = true;
    };

    # Define secrets to be deployed
    secrets = {
      # Democratic CSI SSH private key
      # Used by: akasha (storage server)
      # Purpose: K3s Democratic CSI driver authentication
      "democratic-csi/ssh-private-key" = {
        mode = "0400"; # Read-only by owner
        owner = "democratic-csi";
        group = "democratic-csi";
        path = "/var/lib/democratic-csi/.ssh/id_ed25519";
      };

      # K3s agent token (for jarvis - GPU worker)
      # Purpose: Authenticate jarvis to mainframe control plane
      "k3s/agent-token-jarvis" = {
        mode = "0400";
        owner = "root";
        group = "root";
        path = "/var/lib/rancher/k3s/agent-token";
      };

      # K3s agent token (for akasha - storage worker)
      # Purpose: Authenticate akasha to mainframe control plane
      "k3s/agent-token-akasha" = {
        mode = "0400";
        owner = "root";
        group = "root";
        path = "/var/lib/rancher/k3s/agent-token";
      };

      # Example: API tokens (add as needed)
      # "example/api-token" = {
      #   mode = "0400";
      #   owner = "root";
      #   group = "root";
      # };
    };
  };

  # Ensure democratic-csi user exists before secret is deployed
  # (prevents activation failure if secret references non-existent user)
  systemd.services.sops-install-secrets = {
    after = [ "users.service" ];
    wants = [ "users.service" ];
  };
}
