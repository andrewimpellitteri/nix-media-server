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

  # Enable networking
  networking.networkmanager.enable = true;

  # Performance optimizations for media streaming server
  boot.kernel.sysctl = {
    # TCP buffer sizes - critical for streaming performance
    "net.core.rmem_max" = 33554432;  # 32 MB receive buffer
    "net.core.wmem_max" = 33554432;  # 32 MB send buffer
    "net.core.rmem_default" = 262144;  # 256 KB default receive
    "net.core.wmem_default" = 262144;  # 256 KB default send
    "net.ipv4.tcp_rmem" = "4096 262144 33554432";  # min default max
    "net.ipv4.tcp_wmem" = "4096 262144 33554432";  # min default max

    # Network queue sizes - handle more concurrent connections
    "net.core.netdev_max_backlog" = 5000;  # increased from 1000
    "net.ipv4.tcp_max_syn_backlog" = 8192;  # increased from 1024

    # TCP performance tuning
    "net.ipv4.tcp_congestion_control" = "bbr";  # Better congestion control than cubic
    "net.core.default_qdisc" = "fq";  # Fair queue for BBR
    "net.ipv4.tcp_slow_start_after_idle" = 0;  # Don't slow down after idle
    "net.ipv4.tcp_mtu_probing" = 1;  # Enable MTU probing

    # Reduce TCP keepalive time for faster detection of dead connections
    "net.ipv4.tcp_keepalive_time" = 600;  # 10 minutes instead of 2 hours
    "net.ipv4.tcp_keepalive_intvl" = 60;
    "net.ipv4.tcp_keepalive_probes" = 3;
  };

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

  services.cron = {
      enable = true;
      systemCronJobs = [
        # Clean up Jeopardy episodes older than 30 days - runs daily at 3am
        "0 3 * * * root find /mnt/media2/TV/Jeopardy -type f -mtime +30 -delete"
      ];
  };

  # Enable the XFCE Desktop Environment
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "dvorak";
  };

  # Increase DPI for better readability on TV screen
  services.xserver.dpi = 144;  # Default is 96. Try 120-144 for TV viewing

  # Larger cursor for TV viewing
  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xsetroot}/bin/xsetroot -xcf ${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ/cursors/left_ptr 32
  '';

  # Configure console keymap with Catppuccin theme
  console = {
    keyMap = "dvorak";
    catppuccin.enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
 
  services.blueman.enable = true;

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
    wireplumber.enable = true;
    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  
  fileSystems."/mnt/media1" = {
    device = "/dev/disk/by-uuid/12f58dff-3e3f-4e2d-bd9b-4831b877e0ae";
    fsType = "ext4";
    # Performance optimizations for read-heavy media streaming
    options = [
      "nofail"
      "noatime"        # Don't update access time (reduces writes)
      "nodiratime"     # Don't update directory access time
      "data=writeback" # Faster writes, safe for media files
      "commit=60"      # Commit data every 60 seconds instead of 5
    ];
  };

  fileSystems."/mnt/media2" = {
    device = "/dev/disk/by-uuid/6e01d79a-2216-4c97-ab08-1560730aa181";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
      "nodiratime"
      "data=writeback"
      "commit=60"
    ];
  };

  # Increase read-ahead buffer for USB media drives (sequential read optimization)
  services.udev.extraRules = ''
    # Set read-ahead to 8MB for USB storage devices (better for large media files)
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTRS{idVendor}=="*", ATTR{bdi/read_ahead_kb}="8192"
  '';

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

  services.whisparr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.bazarr = {
    enable = true;
    openFirewall = true;
    group = "media";
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
      vpl-gpu-rt #QSV
      intel-compute-runtime
     ];
  };

  # Add jellyfin to video/render groups for hardware access
  users.users.jellyfin.extraGroups = [ "video" "render" ];

  # Add stash to media group for access to media directories
  users.users.stash.extraGroups = [ "media" ];

  services.jellyseerr = {
    enable = true;
    openFirewall = true;
  };

  # Nginx reverse proxy for Jellyfin and Jellyseerr
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;

    virtualHosts."localhost" = {
      listen = [
        { addr = "127.0.0.1"; port = 8081; }
      ];

      extraConfig = ''
        absolute_redirect off;
      '';

      locations."/" = {
        proxyPass = "http://127.0.0.1:8096";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
        '';
      };

      locations."/jellyseerr/" = {
        proxyPass = "http://127.0.0.1:5055/";
        proxyWebsockets = true;
        extraConfig = ''
          # Set proper headers for the proxied application
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $host;

          # Handle redirects - add /jellyseerr prefix
          proxy_redirect http://$host/ /jellyseerr/;
          proxy_redirect https://$host/ /jellyseerr/;
          proxy_redirect / /jellyseerr/;
        '';
      };

      # Redirect /jellyseerr to /jellyseerr/ (with trailing slash)
      locations."= /jellyseerr" = {
        extraConfig = ''
          return 301 /jellyseerr/;
        '';
      };

      # Proxy Jellyseerr assets and API when accessed from /jellyseerr context
      # This handles cases where assets are loaded with absolute paths
      locations."~ ^/(_next|api|os_icon\.svg|logo_stacked\.svg|apple-touch-icon\.png|favicon.*\.png|site\.webmanifest|apple-splash.*\.jpg)" = {
        proxyPass = "http://127.0.0.1:5055";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };

  # SABnzbd for NZB downloads
  services.sabnzbd = {
    enable = true;
    group = "media";
  };

  # Recyclarr configuration for Sonarr/Radarr quality profiles
  environment.etc."recyclarr/recyclarr.yml".text = ''
    sonarr:
      series:
        base_url: http://localhost:8989
        api_key: !env_var SONARR_API_KEY

        quality_definition:
          type: series
          preferred_ratio: 0.5  # Prefer middle of quality range, not max

        quality_profiles:
          - name: Compact 1080p
            reset_unmatched_scores:
              enabled: true
            upgrade:
              allowed: true
              until_quality: WEB 1080p
              until_score: 5000
            min_format_score: 0
            quality_sort: top
            qualities:
              - name: WEB 1080p
                qualities:
                  - WEBDL-1080p
                  - WEBRip-1080p
              - name: Bluray-1080p  # Encodes only, not remux
              - name: HDTV-1080p

        custom_formats:
          # BOOST: x265 (massive space savings)
          - trash_ids:
              - 47435ece6b99a0b477caf360e79ba0bb  # x265 (HD)
            quality_profiles:
              - name: Compact 1080p
                score: 150

          # BOOST: Compatible audio
          - trash_ids:
              - a570d4a0e56a2874b64e5bfa55202a1b  # DD+
              - 63487786a8b01b7f20dd2bc90dd4a477  # DD
              - 8e109e50e0a0b83a5098b056e13bf6db  # DTS
            quality_profiles:
              - name: Compact 1080p
                score: 50

          # PENALIZE: Lossless audio (bloat)
          - trash_ids:
              - 185f1dd7264c4562b9022d963ac37424  # TrueHD
              - 1af239278386be2919e1bcee0bde047e  # DD+ Atmos
              - 417804f7f2c4308c1f4c5d380d4c4475  # Atmos
              - 3cafb66171b47f226146a0770576870f  # TrueHD Atmos
              - dcf3ec6938fa32445f590a4da84256cd  # DTS-HD MA
              - e77382bcfeba57cb83744c9c5449b401  # DTS-HD HRA
            quality_profiles:
              - name: Compact 1080p
                score: -100

          # BLOCK: Remuxes and bloat
          - trash_ids:
              - 3a3ff47579026e76d6504ebea39390de  # Remux Tier 01
              - 9f98181fe5a3fbeb0cc29340da2a468a  # Remux Tier 02
              - 8baaf0b3142bf4d94c42a724f034e27a  # Remux Tier 03
              - 85c61753df5da1fb2aab6f2a47426b09  # BR-DISK
            quality_profiles:
              - name: Compact 1080p
                score: -10000

          # BLOCK: Garbage
          - trash_ids:
              - 9c11cd3f07101cdba90a2d81cf0e56b4  # LQ
              - e2315f990da2e2cbfc9fa5b7a6c62170  # LQ (Release Title)
              - fbcb31d8dabd2a319072b84fc0b7249c  # Extras
            quality_profiles:
              - name: Compact 1080p
                score: -10000

          # PREFER: Good encode groups
          - trash_ids:
              - c20f169ef63c5f40c2def54abaf4438e  # WEB Tier 01
              - 403816d65392c79236dcb6dd591aedd4  # WEB Tier 02
              - af94e0fe497124d1f9ce732069ec8c3b  # WEB Tier 03
            quality_profiles:
              - name: Compact 1080p
                score: 75

          # Streaming services
          - trash_ids:
              - d660701077794679fd59e8bdf4ce3a29  # AMZN
              - f67c9ca88f463a48346062e8ad07713f  # ATVP
              - 89358767a60cc28783cdc3d0be9388a4  # DSNP
              - 81d1fbf600e2540cee87f3a23f9d3c1c  # MAX
              - d34870697c9db575f17700212167be23  # NF
            quality_profiles:
              - name: Compact 1080p
                score: 25

    radarr:
      movies:
        base_url: http://localhost:7878
        api_key: !env_var RADARR_API_KEY

        quality_definition:
          type: movie
          preferred_ratio: 0.5

        quality_profiles:
          - name: Compact 1080p
            reset_unmatched_scores:
              enabled: true
            upgrade:
              allowed: true
              until_quality: WEB 1080p
              until_score: 5000
            min_format_score: 0
            quality_sort: top
            qualities:
              - name: WEB 1080p
                qualities:
                  - WEBDL-1080p
                  - WEBRip-1080p
              - name: Bluray-1080p
              - name: HDTV-1080p

        custom_formats:
          # BOOST: x265
          - trash_ids:
              - dc98083864ea246d05a42df0d05f81cc  # x265 (HD)
            quality_profiles:
              - name: Compact 1080p
                score: 150

          # BOOST: Compatible lossy audio
          - trash_ids:
              - 89dac1be53d5c2c1e2dafe43c3c86c57  # DD
              - c1a25cd67b5d2e08287c957b1eb903ec  # DTS
            quality_profiles:
              - name: Compact 1080p
                score: 50

          # PENALIZE: Lossless audio
          - trash_ids:
              - 496f355514737f7d83bf7aa4d24f8169  # TrueHD Atmos
              - 2f22d89048b01681dde8afe203bf2e95  # DTS-HD MA
              - 417804f7f2c4308c1f4c5d380d4c4475  # Atmos
              - 3cafb66171b47f226146a0770576870f  # TrueHD
            quality_profiles:
              - name: Compact 1080p
                score: -100

          # BLOCK: Remuxes
          - trash_ids:
              - ed27ebfef2f323e964fb1f61f24a63e5  # HQ-Remux
              - 3a3ff47579026e76d6504ebea39390de  # Remux Tier 01
              - 9f98181fe5a3fbeb0cc29340da2a468a  # Remux Tier 02
              - 8baaf0b3142bf4d94c42a724f034e27a  # Remux Tier 03
              - ed38b889b31be83fda192888e2286d83  # BR-DISK
            quality_profiles:
              - name: Compact 1080p
                score: -10000

          # BLOCK: Garbage and unnecessary
          - trash_ids:
              - 90a6f9a284dff5103f6346090e6280c8  # LQ
              - e204b80c87be9497a8a6eaff48f72905  # LQ (Release Title)
              - b8cd450cbfa689c0259a01d9e29ba3d6  # 3D
              - 0a3f082873eb454bde444150b70253cc  # Extras
              - bfd8eb01832d646a0a89c4deb46f8564  # Upscaled
            quality_profiles:
              - name: Compact 1080p
                score: -10000

          # PREFER: Good encode groups
          - trash_ids:
              - c20f169ef63c5f40c2def54abaf4438e  # WEB Tier 01
              - 403816d65392c79236dcb6dd591aedd4  # WEB Tier 02
              - af94e0fe497124d1f9ce732069ec8c3b  # WEB Tier 03
              - ed27ebfef2f323e964fb1f61f24a63e5  # Encode Tier 01
              - c20c8647f2746a1f4c4262b0fbbeeeae  # Encode Tier 02
            quality_profiles:
              - name: Compact 1080p
                score: 75

          # Streaming services
          - trash_ids:
              - b3b3a6ac74ecbd56bcdbefa4799fb9df  # AMZN
              - 40e9380490e748672c2522eaaeb692f7  # ATVP
              - 84272245b2988854bfb76a16e60baea5  # DSNP
              - 6a061313d22e51e0f25b7cd4dc065233  # MAX
              - 170b1d363bd8516fbf3a3eb05d4faff6  # NF
            quality_profiles:
              - name: Compact 1080p
                score: 25

          # Movie versions (still want these)
          - trash_ids:
              - 0f12c086e289cf966fa5948eac571f44  # Hybrid
              - e0c07d59beb37348e975a930d5e50319  # Criterion
              - 570bc9ebecd92723d2d21500f4be314c  # Remaster
            quality_profiles:
              - name: Compact 1080p
                score: 25
  '';

  # Recyclarr systemd service
  systemd.services.recyclarr = {
    description = "Recyclarr Sync";
    after = [ "network.target" "sonarr.service" "radarr.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.recyclarr}/bin/recyclarr sync --config /etc/recyclarr/recyclarr.yml";
      EnvironmentFile = "/var/lib/recyclarr/env";
    };
  };

  # Recyclarr timer for daily syncs
  systemd.timers.recyclarr = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Stash media organizer
  services.stash = {
    enable = true;
    openFirewall = true;
    mutableSettings = false;  # Force our config (no auth)
    settings = {
      host = "0.0.0.0";  # Listen on all interfaces for Tailscale access
      dangerous_allow_public_without_auth = true;  # Safe with Tailscale
      stash = [
        {
          path = "/mnt/media2/XXX";  # Media library location
        }
      ];
      generated = "/var/lib/stash/generated";
      cache = "/var/lib/stash/cache";
    };
    username = "temp";  # Required by module, will be overridden
    passwordFile = "/var/lib/stash/empty-password";  # Empty file = no auth
    jwtSecretKeyFile = "/var/lib/stash/jwt-secret";
    sessionStoreKeyFile = "/var/lib/stash/session-secret";
  };

  # Tailscale for remote access
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";  # Enable subnet routing and exit node
    permitCertUid = "plexxy";  # Allow Tailscale SSH for user plexxy
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
        extraOptions = [ "--network=host" ];  # Use host network to access system services
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
        environment = {
          UPTIME_KUMA_DISABLE_FRAME_SAMEORIGIN = "true";
        };
      };
      recommendarr = {
        image = "tannermiddleton/recommendarr:latest";
        autoStart = true;
        extraOptions = [ "--network=host" ];  # Use host network to access sonarr/radarr/jellyfin
        volumes = [
          "/var/lib/recommendarr:/app/server/data"
        ];
      };
      dashdot = {
        image = "mauricenino/dashdot:latest";
        autoStart = true;
        ports = [ "3002:3001" ];  # Host:Container - avoids conflict with Uptime Kuma
        extraOptions = [ "--privileged" ];
        volumes = [
          "/:/mnt/host:ro"
        ];
      };
      homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        autoStart = true;
        extraOptions = [
          "--network=host"
          "--privileged"  # Allows USB device access for future Zigbee/Z-Wave testing
        ];
        environment = {
          TZ = "America/New_York";
        };
        volumes = [
          "/var/lib/homeassistant:/config"
        ];
      };
    };
  };

  # Create data directories for containerized services
  systemd.tmpfiles.rules = [
    "d /var/lib/homarr 0755 root root -"
    "d /var/lib/homarr/configs 0755 root root -"
    "d /var/lib/homarr/icons 0755 root root -"
    "d /var/lib/homarr/data 0755 root root -"
    "d /var/lib/homeassistant 0755 root root -"
    "d /var/lib/uptime-kuma 0755 root root -"
    "d /var/lib/recommendarr 0755 root root -"
    # Recyclarr directory
    "d /var/lib/recyclarr 0750 root root -"
    # Stash directories and secret files
    "d /var/lib/stash/generated 0755 stash stash -"
    "d /var/lib/stash/cache 0755 stash stash -"
    "d /mnt/media2/XXX 0775 plexxy media -"
    "f /var/lib/stash/empty-password 0600 stash stash -"
    "f /var/lib/stash/jwt-secret 0600 stash stash - jwt-secret-change-me"
    "f /var/lib/stash/session-secret 0600 stash stash - session-secret-change-me"
    # NZB download directories with proper permissions for SABnzbd
    "d /mnt/media2/NZB 0775 plexxy media -"
    "d /mnt/media2/NZB/Pending 0775 plexxy media -"
    "d /mnt/media2/NZB/Complete 0775 plexxy media -"
    "d /mnt/media2/NZB/Complete/TV 0775 plexxy media -"
    "d /mnt/media2/NZB/Complete/Movies 0775 plexxy media -"
    "d /mnt/media2/NZB/Complete/XXX 0775 plexxy media -"
    "z /mnt/media2/NZB 0775 plexxy media -"
    # Media library directories - fix permissions for *arr services
    # Fix parent mount points first to avoid unsafe path transitions
    "z /mnt/media1 0775 plexxy media -"
    "z /mnt/media2 0775 plexxy media -"
    "z /mnt/media1/Movies 0775 plexxy media -"
    "z /mnt/media2/Movies 0775 plexxy media -"
    "z /mnt/media1/TV 0775 plexxy media -"
    "z /mnt/media2/TV 0775 plexxy media -"
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
      6767  # Bazarr
      7575  # Homarr
      8080  # SABnzbd
      8123  # Home Assistant
      3000  # Recommendarr
      3001  # Uptime Kuma
      3002  # Dashdot
      6969  # Whisparr
      9999  # Stash
    ];
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.plexxy = {
    isNormalUser = true;
    description = "plexxy";
    extraGroups = [ "networkmanager" "wheel" "sonarr" "radarr" "whisparr" "prowlarr" "bazarr" "jellyfin" "stash" "docker" "media" ];
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
      # Python shortcuts
      py = "python3";
      ipy = "python3 -i";  # Interactive Python
      # Nix-shell shortcuts (no more awful syntax!)
      pyshell = "nix-shell -p python3 python3Packages.requests";
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

  environment.variables = {
    XCURSOR_SIZE = "32";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vscode
    python3
    (kodi.withPackages (kodiPkgs: with kodiPkgs; [
      jellyfin
      youtube
    ]))
    vlc
    curl
    bind
    btop
    tree
    git
    mealie
    restic
    recyclarr
    mediainfo  # Video metadata analysis tool
    uv  # Modern Python package manager
    (python3.withPackages (ps: with ps; [
      requests
      matplotlib
      numpy
      pandas
    ]))
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon with secure configuration
  # Restricted to Tailscale network only
  services.openssh = {
    enable = true;
    settings = {
      # Security hardening
      PasswordAuthentication = false;  # Disable password auth, keys only
      PermitRootLogin = "no";  # No root login
      KbdInteractiveAuthentication = false;  # No keyboard-interactive auth
      X11Forwarding = false;  # Disable X11 forwarding
      # Allow only specific users
      AllowUsers = [ "plexxy" ];
    };
  };

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
        "/var/lib/whisparr"
        "/var/lib/private/prowlarr"
        "/var/lib/bazarr"
        "/var/lib/jellyfin"
        "/var/lib/private/jellyseerr"
        "/var/lib/sabnzbd"
        "/var/lib/stash"
        "/var/lib/homarr"
        "/var/lib/homeassistant"
        "/var/lib/uptime-kuma"
        "/var/lib/recommendarr"
        "/var/lib/recyclarr"
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