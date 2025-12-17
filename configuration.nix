{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Catppuccin theming - globally enabled
  catppuccin = {
    enable = true;
    flavor = "mocha";  # Options: latte, frappe, macchiato, mocha
    accent = "mauve";  # Options: rosewater, flamingo, pink, mauve, red, maroon, peach, yellow, green, teal, sky, sapphire, blue, lavender
  };

  # Enable Plymouth for themed boot splash
  boot.plymouth = {
    enable = true;
    catppuccin.enable = true;
  };

  # Bootloader with Catppuccin theme
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      catppuccin.enable = true;
    };
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the XFCE Desktop Environment
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "dvorak";
  };

  # Configure console keymap with Catppuccin theme
  console = {
    keyMap = "dvorak";
    catppuccin.enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  
  fileSystems."/mnt/media1" = {
    device = "/dev/disk/by-uuid/12f58dff-3e3f-4e2d-bd9b-4831b877e0ae";
    fsType = "ext4";
    options = ["defaults" "nofail"];
  };

  fileSystems."/mnt/media2" = {
    device = "/dev/disk/by-uuid/6e01d79a-2216-4c97-ab08-1560730aa181";
    fsType = "ext4";
    options = ["defaults" "nofail"];
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  # Jellyfin with hardware transcoding (Intel QuickSync)
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Enable Intel graphics driver for hardware transcoding
  boot.kernelModules = [ "i915" ];

  # Hardware acceleration for Intel QuickSync
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver  # VAAPI driver for newer Intel GPUs (Broadwell+)
      intel-compute-runtime  # OpenCL support
    ];
  };

  # Add jellyfin to video/render groups for hardware access
  users.users.jellyfin.extraGroups = [ "video" "render" ];

  services.jellyseerr = {
    enable = true;
    openFirewall = true;
  };

  # SABnzbd for NZB downloads
  services.sabnzbd = {
    enable = true;
    group = "media";
  };

  # Tailscale for remote access with Funnel for public access
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";  # Enable subnet routing and exit node
  };

  # Enable Docker for containers
  virtualisation.docker.enable = true;

  # Homarr and Uptime Kuma containers using OCI
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      homarr = {
        image = "ghcr.io/ajnart/homarr:latest";
        autoStart = true;
        ports = [ "7575:7575" ];
        volumes = [
          "/var/lib/homarr/configs:/app/data/configs"
          "/var/lib/homarr/icons:/app/public/icons"
          "/var/lib/homarr/data:/data"
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
      };
      uptime-kuma = {
        image = "louislam/uptime-kuma:1";
        autoStart = true;
        extraOptions = [ "--network=host" ];
        volumes = [
          "/var/lib/uptime-kuma:/app/data"
        ];
      };
    };
  };

  # Create homarr and uptime-kuma data directories
  systemd.tmpfiles.rules = [
    "d /var/lib/homarr 0755 root root -"
    "d /var/lib/homarr/configs 0755 root root -"
    "d /var/lib/homarr/icons 0755 root root -"
    "d /var/lib/homarr/data 0755 root root -"
    "d /var/lib/uptime-kuma 0755 root root -"
    # NZB download directories with proper permissions for SABnzbd
    "d /mnt/media2/NZB 0775 plexxy media -"
    "d /mnt/media2/NZB/Pending 0775 plexxy media -"
    "d /mnt/media2/NZB/Complete 0775 plexxy media -"
    "d /mnt/media2/NZB/Complete/TV 0775 plexxy media -"
    "d /mnt/media2/NZB/Complete/Movies 0775 plexxy media -"
    "z /mnt/media2/NZB 0775 plexxy media -"
    # Restic backup directory
    "d /mnt/media2/backups 0700 root root -"
  ];


  # Firewall config for Tailscale and exposing services
  networking.firewall = {
    enable = true;
    checkReversePath = "loose";  # Required for Tailscale
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    allowedTCPPorts = [
      7575  # Homarr
      8080  # SABnzbd
      3001  # Uptime Kuma
    ];
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.plexxy = {
    isNormalUser = true;
    description = "plexxy";
    extraGroups = [ "networkmanager" "wheel" "sonarr" "radarr" "prowlarr" "jellyfin" "docker" "media" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Create media group for sharing access between services
  users.groups.media = {};

  # Install firefox.
  programs.firefox.enable = true;

  # Enable zsh with oh-my-zsh
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";  # You can change this to any theme you like
      plugins = [ "git" "docker" "sudo" ];
    };
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;


  nix.settings = {
    substituters = [ "https://claude-code.cachix.org" ];
    trusted-public-keys = [ "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk=" ];
  };

  nix.settings.experimental-features = [
  "nix-command"
  "flakes"
  ];


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vscode
    python3
    (kodi.withPackages (kodiPkgs: with kodiPkgs; [
      jellyfin
      youtube
    ]))
    curl
    bind
    tree
    git
    restic
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Restic backup configuration for media server data
  services.restic.backups = {
    media-server = {
      # Local backup repository on media2 drive
      # For remote backups, you can also use: sftp, s3, b2, etc.
      # Example: repository = "sftp:user@host:/backups/media-server";
      # Example: repository = "b2:bucket-name:path";
      repository = "/mnt/media2/backups/media-server";

      # Password file for repository encryption
      # Create this file with: echo "your-secure-password" > /etc/nixos/restic-password.txt
      # Then: sudo chmod 600 /etc/nixos/restic-password.txt
      passwordFile = "/etc/nixos/restic-password.txt";

      # Paths to backup
      paths = [
        "/var/lib/sonarr"
        "/var/lib/radarr"
        "/var/lib/private/prowlarr"
        "/var/lib/jellyfin"
        "/var/lib/private/jellyseerr"
        "/var/lib/sabnzbd"
        "/var/lib/homarr"
        "/var/lib/uptime-kuma"
        "/etc/nixos"  # Backup NixOS configuration too
      ];

      # Automatic pruning to keep backups manageable
      pruneOpts = [
        "--keep-daily 7"    # Keep 7 daily backups
        "--keep-weekly 4"   # Keep 4 weekly backups
        "--keep-monthly 6"  # Keep 6 monthly backups
      ];

      # Backup schedule (daily at 2 AM)
      timerConfig = {
        OnCalendar = "02:00";
        Persistent = true;  # Run missed backups on startup
      };

      # Run backup as root to access all service directories
      user = "root";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}