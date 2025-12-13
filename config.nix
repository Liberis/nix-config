{
  # ============================================================================
  # Centralized Configuration for NixOS Flake
  # ============================================================================
  # This file contains all customizable values for the NixOS setup.
  # All modules import this file to access consistent configuration values.
  # Modify these values to customize the system for different users/hosts.

  # ============================================================================
  # User Configuration
  # ============================================================================
  user = {
    # Primary username - used throughout the system configuration
    name = "liberis";

    # Full name for display purposes (Git commits, etc.)
    fullName = "Liberis";

    # Email address for Git configuration and other tools
    email = "libpatouch@gmail.com";

    # System groups for the user
    # - wheel: sudo access
    # - networkmanager: network configuration
    # - video: GPU/video device access
    # - bluetooth: Bluetooth device access
    # - seat: seat management (required for Wayland compositors)
    # - audio: audio device access
    groups = [
      "wheel"
      "networkmanager"
      "video"
      "bluetooth"
      "seat"
      "audio"
    ];
  };

  # ============================================================================
  # System Configuration
  # ============================================================================
  system = {
    # NixOS state version - MUST match your initial installation version
    # This controls state migration behavior. DO NOT change after installation
    # unless you understand the implications. See: man configuration.nix
    stateVersion = "25.05";

    # System timezone - affects system clock and timestamp displays
    # Find valid values: timedatectl list-timezones
    timezone = "Europe/Athens";

    # System locale - affects date formats, number formats, etc.
    # Common values: "en_US.UTF-8", "en_GB.UTF-8", "de_DE.UTF-8"
    locale = "en_US.UTF-8";

    # Allow installation of unfree packages (required for NVIDIA drivers,
    # VS Code, Steam, and many other proprietary software)
    allowUnfree = true;
  };

  # ============================================================================
  # Desktop Environment Configuration
  # ============================================================================
  desktop = {
    # Default user for the display manager (greetd/regreet)
    # This user will be pre-selected at the login screen
    defaultUser = "liberis";

    # Cache directory for regreet display manager
    # Used to store theme cache and temporary files
    cacheDir = "/var/cache/regreet";
  };
}
