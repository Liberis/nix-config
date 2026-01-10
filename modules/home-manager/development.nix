{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # Programming language toolchains
    go # The Go programming language compiler and tools
    rustc # The Rust compiler
    cargo # Rust package manager
    gcc # GNU Compiler Collection (C/C++)
    gnumake # GNU Make build automation

    # Infrastructure and cloud CLIs
    terraform # HashiCorp Terraform for infrastructure provisioning
    azure-cli # Microsoft Azure CLI
  ];
}
