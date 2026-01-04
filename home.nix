{ config, pkgs, catppuccin, ... }:

{
  imports = [
    catppuccin.homeManagerModules.catppuccin
  ];

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Home Manager needs to know about your home directory
  home.username = "plexxy";
  home.homeDirectory = "/home/plexxy";

  # This value determines the Home Manager release
  home.stateVersion = "25.11";

  # Enable Catppuccin globally for home-manager
  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
  };

  # GTK theming with Catppuccin
  gtk = {
    enable = true;
    catppuccin = {
      enable = true;
      icon.enable = true;  # Catppuccin icon theme
    };
  };

  # Qt theming to match GTK
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };

  # Catppuccin cursor theme
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "catppuccin-mocha-mauve-cursors";
    package = pkgs.catppuccin-cursors.mochaMauve;
    size = 24;
  };

  # Rice programs with Catppuccin theming
  programs = {
    # btop - resource monitor
    btop = {
      enable = true;
      catppuccin.enable = true;
      settings = {
        color_theme = "catppuccin_mocha";
        theme_background = false;
        truecolor = true;
        vim_keys = true;
      };
    };

    # bat - cat with syntax highlighting
    bat = {
      enable = true;
      catppuccin.enable = true;
    };

    # eza - modern ls replacement
    eza = {
      enable = true;
      enableZshIntegration = true;
      icons = "auto";
      git = true;
    };

    # fzf - fuzzy finder
    fzf = {
      enable = true;
      catppuccin.enable = true;
      enableZshIntegration = true;
    };

    # starship - cross-shell prompt
    starship = {
      enable = true;
      catppuccin.enable = true;
      enableZshIntegration = true;
    };

    # zsh improvements
    zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;

      shellAliases = {
        ls = "eza --icons --group-directories-first";
        ll = "eza -l --icons --group-directories-first";
        la = "eza -la --icons --group-directories-first";
        tree = "eza --tree --icons";
        cat = "bat";
      };

      initExtra = ''
        # Enable vim mode in zsh
        bindkey -v
      '';
    };

    # git with catppuccin delta diff viewer
    git = {
      enable = true;
      delta = {
        enable = true;
        catppuccin.enable = true;
      };
    };

    # Firefox theming
    firefox.profiles.default = {
      catppuccin.enable = true;
    };

    # neovim with catppuccin
    neovim = {
      enable = true;
      catppuccin.enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    # File manager theming
    yazi = {
      enable = true;
      catppuccin.enable = true;
      enableZshIntegration = true;
    };
  };

  # Additional packages for rice
  home.packages = with pkgs; [
    # System monitoring
    htop
    btop
    neofetch
    # Terminal tools
    ripgrep  # better grep
    fd       # better find
    dust     # better du
    duf      # better df

    # Fun stuff
    cmatrix
    pipes-rs
    cbonsai
  ];

  # Enable home-manager to manage XDG directories
  xdg.enable = true;
}
