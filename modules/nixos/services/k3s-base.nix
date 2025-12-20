{ config, pkgs, lib, ... }:

let
  cfg = config.services.k3s;
in
{
  options.services.k3s = {
    tlsSans = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional TLS SANs for the server certificate";
    };
  };

  config = lib.mkIf cfg.enable {
    # --- Podman ---
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
    virtualisation.containers.enable = true;

    # --- k3s ---
    services.k3s = {
      extraFlags =
        (lib.optionals (cfg.role == "server") [
        "--write-kubeconfig-mode=0644 --node-ip=192.168.10.11 --flannel-iface=ens1 --disable=servicelb --disable=traefik"
        ])
        ++ (lib.optionals (cfg.role == "server" && cfg.tlsSans != [])
            (map (san: "--tls-san=${san}") cfg.tlsSans));
    };

    # --- Base Tooling ---
    environment.systemPackages = with pkgs; [
      kubectl
      kubernetes-helm
      kubernetes-helmPlugins.helm-diff
      helmfile
      k9s
      podman
      crun
      cni-plugins
      nerdctl
      fluxcd
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
      53    # DNS (Pi-hole)
      80
      443
      445
      2283
      3456
      5201
      6379
      8080
      8123
      9000
      10250  # Kubelet metrics
    ] ++ (lib.optionals (cfg.role == "server") [ 6443 ]);

    networking.firewall.allowedUDPPorts = [
      53    # DNS (Pi-hole)
      8472  # Flannel VXLAN - required for cross-node pod networking
    ];

    # Trust pod network interfaces for inter-pod communication
    networking.firewall.trustedInterfaces = [ "cni0" "flannel.1" ];
  };
}
