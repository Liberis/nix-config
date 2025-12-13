{ config, pkgs, lib, ... }:

let
  cfg = config.services.k3s;
in
{
  options.services.k3s = {
    roleConfig = lib.mkOption {
      type = lib.types.enum [ "server" "agent" ];
      default = "server";
      description = "K3s role: server or agent";
    };

    serverAddr = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Server address for agent nodes (e.g., https://192.168.1.140:6443)";
    };

    tokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to file containing the K3s token for agent authentication";
    };

    tlsSans = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional TLS SANs for the server certificate";
    };

    clusterInit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Initialize a new cluster (only for server role)";
    };
  };

  config = {
    # --- Podman ---
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
    virtualisation.containers.enable = true;

    # --- k3s ---
    services.k3s = {
      enable = true;
      role = cfg.roleConfig;
      clusterInit = lib.mkIf (cfg.roleConfig == "server") cfg.clusterInit;

      extraFlags = [
        "--write-kubeconfig-mode=0644"
      ]
      ++ (lib.optionals (cfg.roleConfig == "server" && cfg.tlsSans != [])
          (map (san: "--tls-san=${san}") cfg.tlsSans))
      ++ (lib.optionals (cfg.roleConfig == "agent" && cfg.serverAddr != null)
          [ "--server=${cfg.serverAddr}" ]);

      tokenFile = lib.mkIf (cfg.roleConfig == "agent" && cfg.tokenFile != null) cfg.tokenFile;
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
    ] ++ (lib.optionals (cfg.roleConfig == "server") [ 6443 ]);
  };
}
