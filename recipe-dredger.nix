{ config, pkgs, ... }:

{
  # Recipe Dredger - Automated bulk recipe importer for Mealie
  # https://github.com/D0rk4ce/mealie-recipe-dredger

  systemd.services.recipe-dredger = {
    description = "Mealie Recipe Dredger - Bulk recipe import automation";
    after = [ "network.target" "mealie.service" ];
    wants = [ "mealie.service" ];  # Ensure Mealie is available

    serviceConfig = {
      Type = "oneshot";
      User = "plexxy";
      WorkingDirectory = "/tmp";

      # Security hardening
      PrivateTmp = true;
      NoNewPrivileges = true;

      # Environment variables (non-sensitive config)
      Environment = [
        "MEALIE_ENABLED=true"
        "MEALIE_URL=http://localhost:9000"
        "TANDOOR_ENABLED=false"
      ];

      # Load API token from secure file
      EnvironmentFile = "/var/lib/recipe-dredger/env";
    };

    script = let
      # Python environment with required dependencies
      pythonEnv = pkgs.python3.withPackages (ps: with ps; [
        requests
        beautifulsoup4
        lxml
      ]);
    in ''
      # Create temporary workspace
      WORK_DIR=$(mktemp -d)
      cd "$WORK_DIR"

      echo "Fetching latest Recipe Dredger..."
      ${pkgs.git}/bin/git clone --depth 1 https://github.com/D0rk4ce/mealie-recipe-dredger.git .

      echo "Running Recipe Dredger..."
      ${pythonEnv}/bin/python dredger.py

      # Cleanup
      cd /tmp
      rm -rf "$WORK_DIR"
      echo "Recipe Dredger completed successfully"
    '';
  };

  # Systemd timer - runs weekly on Sundays at 3am
  systemd.timers.recipe-dredger = {
    description = "Recipe Dredger weekly schedule";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "Sun *-*-* 03:00:00";  # Weekly: Sunday 3am
      Persistent = true;  # Run missed executions after system boot
      RandomizedDelaySec = "30m";  # Add up to 30min random delay to avoid load spikes
    };
  };

  # Create secure directory for API token
  systemd.tmpfiles.rules = [
    "d /var/lib/recipe-dredger 0700 plexxy users -"
  ];
}
