{ config, pkgs, lib, ... }:

let
  cfg = config.services.k3s;
in
{
  # K3s Server (Control Plane) Configuration

  options.services.k3s.tlsSans = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Additional TLS SANs for the server certificate";
  };

  config = lib.mkIf (cfg.enable && cfg.role == "server") {
    # Container runtime
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
    virtualisation.containers.enable = true;

    # K3s server flags
    services.k3s.extraFlags = [
      "--write-kubeconfig-mode=0644"
      "--disable=servicelb"
      "--disable=traefik"
    ] ++ (map (san: "--tls-san=${san}") cfg.tlsSans);

    # K3s tooling
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
    ];

    systemd.services.k3s.path = [ pkgs.runc pkgs.coreutils ];

    # Network forwarding
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    # Firewall
    networking.firewall = {
      allowedTCPPorts = [
        6443  # K3s API server
        10250 # Kubelet metrics
      ];
      allowedUDPPorts = [
        8472  # Flannel VXLAN
      ];
      trustedInterfaces = [ "cni0" "flannel.1" ];
    };
  };
}
