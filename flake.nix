{
  description = "Liberis • NixOS + Home‑Manager monorepo (role‑based)";

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

      # Helper function to build a NixOS system configuration
      # Automatically applies base profile, role-specific profiles, and home-manager
      mkHost =
        { hostName, roles }:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs roles; };
          modules = [
            # Base profile (common to all hosts)
            ./profiles/base.nix

            # Flake-managed defaults (experimental-features, allowUnfree, stateVersion)
            ./modules/nixos/system/flake-defaults.nix

            # Host-specific configuration
            ./hosts/${hostName}

            # Set hostname
            { networking.hostName = hostName; }

            # Home-Manager integration
            home-manager.nixosModules.home-manager
            ./modules/home-manager.nix
          ]
          # Add role-specific profiles
          ++ map (role: ./profiles/${role}.nix) roles;
        };
    in
    {
      nixosConfigurations = {
        nixos = mkHost {
          hostName = "nixos";
          roles = [ "desktop" ];
        };
        jarvis = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            roles = [ "server" ];
          };
          modules = [
            # Disko for declarative disk management
            disko.nixosModules.disko

            # Base profile (common to all hosts)
            ./profiles/base.nix

            # Flake-managed defaults
            ./modules/nixos/system/flake-defaults.nix

            # Host-specific configuration (includes disko.nix)
            ./hosts/jarvis

            # Set hostname
            { networking.hostName = "jarvis"; }

            # Home-Manager integration
            home-manager.nixosModules.home-manager
            ./modules/home-manager.nix

            # Server profile
            ./profiles/server.nix
          ];
        };
        wsl = mkHost {
          hostName = "wsl";
          roles = [ "wsl" ];
        };
      };

      # Flake checks for validation and testing
      checks.${system} = {
        # Check that all configurations build successfully
        nixos-build = self.nixosConfigurations.nixos.config.system.build.toplevel;
        jarvis-build = self.nixosConfigurations.jarvis.config.system.build.toplevel;
        wsl-build = self.nixosConfigurations.wsl.config.system.build.toplevel;

        # Format check for Nix files
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

        # Basic validation that config.nix is valid
        config-valid = pkgs.runCommand "config-check" { } ''
          echo "Validating config.nix..."
          ${pkgs.nix}/bin/nix-instantiate --eval --strict ${./config.nix} > /dev/null
          echo "config.nix is valid" > $out
        '';
      };
    };
}
