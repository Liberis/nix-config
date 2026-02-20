{
  description = "Liberis NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      disko,
      ...
    }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = {
        # Desktop workstation (AMD Ryzen 9900X + NVIDIA RTX 5070Ti)
        jarvis = lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            ./modules/nixos/system/flake-defaults.nix
            ./hosts/jarvis
            { networking.hostName = "jarvis"; }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.liberis.imports = [
                ./modules/home-manager/common.nix
                ./modules/home-manager/development.nix
                ./modules/home-manager/shell.nix
                ./modules/home-manager/wayland.nix
                ./modules/home-manager/media.nix
                ./modules/home-manager/utilities.nix
                ./modules/home-manager/communication.nix
                ./modules/home-manager/ai-ml.nix
              ];
            }
          ];
        };

        # K3s control plane (Dell OptiPlex 3080 - Intel i7-10710T)
        mainframe = lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            ./modules/nixos/system/flake-defaults.nix
            ./hosts/mainframe
            { networking.hostName = "mainframe"; }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.liberis.imports = [
                ./modules/home-manager/common.nix
                ./modules/home-manager/development.nix
                ./modules/home-manager/shell.nix
              ];
            }
          ];
        };

        # Storage server and K3s worker (Lenovo P510 - Intel Xeon E2680v5)
        akasha = lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            ./modules/nixos/system/flake-defaults.nix
            ./hosts/akasha
            { networking.hostName = "akasha"; }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.liberis.imports = [
                ./modules/home-manager/common.nix
                ./modules/home-manager/development.nix
                ./modules/home-manager/shell.nix
              ];
            }
          ];
        };

        # WSL development environment
        wsl = lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./modules/nixos/system/flake-defaults.nix
            ./hosts/wsl
            { networking.hostName = "wsl"; }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.liberis.imports = [
                ./modules/home-manager/common.nix
                ./modules/home-manager/development.nix
                ./modules/home-manager/shell.nix
              ];
            }
          ];
        };
      };

      # Flake checks
      checks.${system} = {
        jarvis-build = self.nixosConfigurations.jarvis.config.system.build.toplevel;
        mainframe-build = self.nixosConfigurations.mainframe.config.system.build.toplevel;
        akasha-build = self.nixosConfigurations.akasha.config.system.build.toplevel;
        wsl-build = self.nixosConfigurations.wsl.config.system.build.toplevel;

        nixfmt-check =
          pkgs.runCommand "nixfmt-check"
            {
              buildInputs = with pkgs; [
                nixfmt-rfc-style
                fd
              ];
            }
            ''
              echo "Checking Nix file formatting..."
              cd ${./.}
              ${pkgs.fd}/bin/fd -e nix -x ${pkgs.nixfmt-rfc-style}/bin/nixfmt --check {}
              touch $out
              echo "All Nix files are properly formatted"
            '';

        config-valid = pkgs.runCommand "config-check" { } ''
          echo "Validating config.nix..."
          ${pkgs.nix}/bin/nix-instantiate --eval --strict ${./config.nix} > /dev/null
          echo "config.nix is valid" > $out
        '';
      };
    };
}
