{ config, pkgs, ... }:
{
  # Base k3s configuration without GPU support
  # For GPU-enabled k3s, use k3s-nvidia.nix instead

  # --- Podman ---
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  virtualisation.containers.enable = true;

  # --- k3s (single-node server) ---
  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    extraFlags = [
      "--write-kubeconfig-mode=0644"
    ];
  };

  # --- Base Tooling ---
  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
    podman
    crun
    cni-plugins
    nerdctl
    runc
    coreutils
  ];

  systemd.services.k3s.path = [
    pkgs.runc
    pkgs.coreutils
  ];

  # --- Networking / sysctl helpful defaults ---
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
    6443
  ];
}
