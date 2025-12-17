# NixOS Media Server Configuration

This repository contains the NixOS configuration for a complete media server setup with automated backups.

## Services Included

- **Sonarr** - TV show management
- **Radarr** - Movie management
- **Prowlarr** - Indexer manager
- **Jellyfin** - Media server with hardware transcoding
- **Jellyseerr** - Request management
- **SABnzbd** - NZB downloader
- **Homarr** - Dashboard
- **Uptime Kuma** - Monitoring
- **Tailscale** - Remote access

## Initial Setup

### 1. Set up Git Repository

```bash
# Navigate to NixOS config directory
cd /etc/nixos

# Initialize git repository
sudo git init

# Add your GitHub repository as remote
sudo git remote add origin https://github.com/andrewimpellitteri/nix-media-server.git

# Add files to git
sudo git add configuration.nix flake.nix flake.lock .gitignore README.md

# Commit the configuration
sudo git commit -m "Initial NixOS media server configuration"

# Push to GitHub
sudo git push -u origin main
```

### 2. Set up Restic Backup

```bash
# Create a strong password for restic encryption
echo "YOUR-SECURE-PASSWORD-HERE" | sudo tee /etc/nixos/restic-password.txt
sudo chmod 600 /etc/nixos/restic-password.txt

# Rebuild NixOS to apply restic configuration
sudo nixos-rebuild switch --flake /etc/nixos#nixos

# Initialize the restic repository (first time only)
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt init

# Run first backup manually to test
sudo systemctl start restic-backups-media-server.service

# Check backup status
sudo systemctl status restic-backups-media-server.service
```

## Backup Management

### Viewing Backups

```bash
# List all snapshots
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt snapshots

# List files in a specific snapshot
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt ls latest

# Check repository integrity
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt check
```

### Manual Backup

```bash
# Trigger backup manually
sudo systemctl start restic-backups-media-server.service

# View backup logs
sudo journalctl -u restic-backups-media-server.service -f
```

### Backup Schedule

Backups run automatically daily at 2:00 AM via systemd timer.

```bash
# Check timer status
sudo systemctl status restic-backups-media-server.timer

# View timer schedule
sudo systemctl list-timers restic-backups-media-server.timer
```

## Restore from Backup

### Full System Restore

1. **Restore NixOS configuration:**

```bash
# Clone your configuration repository
sudo git clone https://github.com/andrewimpellitteri/nix-media-server.git /etc/nixos
cd /etc/nixos

# Restore your restic password file
echo "YOUR-PASSWORD" | sudo tee /etc/nixos/restic-password.txt
sudo chmod 600 /etc/nixos/restic-password.txt

# Rebuild the system
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

2. **Stop all services before restoring data:**

```bash
sudo systemctl stop sonarr radarr prowlarr jellyfin jellyseerr sabnzbd docker
```

3. **Restore service data from latest backup:**

```bash
# Restore all data to original locations
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt restore latest --target /

# Or restore specific service (example: Sonarr)
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt restore latest --target / --include /var/lib/sonarr
```

4. **Start services:**

```bash
sudo systemctl start sonarr radarr prowlarr jellyfin jellyseerr sabnzbd docker
```

### Restore Specific Files/Directories

```bash
# List files in latest backup
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt ls latest

# Restore to a temporary location for inspection
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt restore latest --target /tmp/restore

# Restore specific path
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt restore latest --target / --include /var/lib/jellyfin
```

### Restore from Specific Snapshot

```bash
# List all snapshots with IDs
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt snapshots

# Restore from specific snapshot ID
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt restore SNAPSHOT_ID --target /
```

## Updating Configuration

```bash
# Edit configuration
sudo vim /etc/nixos/configuration.nix

# Test the new configuration
sudo nixos-rebuild test --flake /etc/nixos#nixos

# Apply changes permanently
sudo nixos-rebuild switch --flake /etc/nixos#nixos

# Commit and push changes
cd /etc/nixos
sudo git add configuration.nix
sudo git commit -m "Description of changes"
sudo git push
```

## Remote Backup Setup (Optional)

To backup to a remote location instead of local disk, update the repository in `configuration.nix`:

### Backblaze B2
```nix
repository = "b2:bucket-name:/media-server";
```

### SFTP
```nix
repository = "sftp:user@host:/path/to/backups";
```

### AWS S3
```nix
repository = "s3:s3.amazonaws.com/bucket-name/media-server";
```

Then add any required credentials/environment variables to the restic configuration.

## Troubleshooting

### Check Service Status
```bash
sudo systemctl status sonarr radarr prowlarr jellyfin jellyseerr sabnzbd
```

### View Service Logs
```bash
sudo journalctl -u sonarr -f
sudo journalctl -u jellyfin -f
```

### Verify Backup Integrity
```bash
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt check --read-data
```

### Restic Repository Issues
```bash
# Unlock repository if backup was interrupted
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt unlock

# Repair index
sudo restic -r /mnt/media2/backups/media-server --password-file /etc/nixos/restic-password.txt rebuild-index
```

## Backup Retention Policy

Current policy (configured in `configuration.nix`):
- Keep 7 daily backups
- Keep 4 weekly backups
- Keep 6 monthly backups

This ensures you can restore from recent backups while managing disk space.

## What Gets Backed Up

- `/var/lib/sonarr` - Sonarr configuration and database
- `/var/lib/radarr` - Radarr configuration and database
- `/var/lib/private/prowlarr` - Prowlarr configuration
- `/var/lib/jellyfin` - Jellyfin library metadata and settings
- `/var/lib/private/jellyseerr` - Jellyseerr configuration
- `/var/lib/sabnzbd` - SABnzbd configuration
- `/var/lib/homarr` - Homarr dashboard configuration
- `/var/lib/uptime-kuma` - Monitoring configuration
- `/etc/nixos` - NixOS configuration files

**Note:** Media files in `/mnt/media1` and `/mnt/media2` are NOT backed up (too large). Back these up separately if needed.

## Security Notes

- The `restic-password.txt` file is excluded from git (see `.gitignore`)
- **NEVER commit your restic password to git**
- Keep a copy of your restic password in a secure password manager
- Without the password, your backups are **unrecoverable**
