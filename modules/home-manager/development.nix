{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # ===================
    # Programming Languages
    # ===================
    # Go
    go
    gopls # Go language server

    # Rust
    rustc
    cargo
    rust-analyzer

    # C/C++
    gcc
    gnumake
    cmake
    ninja
    gdb

    # Python
    python3
    python3Packages.pip
    python3Packages.virtualenv
    poetry
    ruff # Fast Python linter

    # Node.js
    nodejs
    pnpm
    nodePackages.typescript
    nodePackages.typescript-language-server

    # ===================
    # Build Tools
    # ===================
    pkg-config
    autoconf
    automake
    libtool

    # ===================
    # Infrastructure & Cloud
    # ===================
    terraform
    azure-cli
    awscli2
    oci-cli # Oracle Cloud Infrastructure CLI

    # ===================
    # Debugging & Analysis
    # ===================
    strace
    ltrace
    valgrind
  ];
}
