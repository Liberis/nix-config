{ config, pkgs, lib, ... }:

let
  cfg = config.services.k3s;
in
{
  # K3s Agent (Worker Node) Configuration

  config = lib.mkIf (cfg.enable && cfg.role == "agent") {
    # Container runtime
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
    virtualisation.containers.enable = true;

    # K3s tooling
    environment.systemPackages = with pkgs; [
      kubectl
      kubernetes-helm
      kubernetes-helmPlugins.helm-diff
      helmfile
      fluxcd
      k9s
      podman
      crun
      cni-plugins
      nerdctl
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
        10250 # Kubelet metrics
      ];
      allowedUDPPorts = [
        8472  # Flannel VXLAN
      ];
      trustedInterfaces = [ "cni0" "flannel.1" ];
    };
  };
}
