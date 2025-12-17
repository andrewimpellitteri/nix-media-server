{
  description = "NixOS system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    claude-code.url = "github:sadjow/claude-code-nix";
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = { self, nixpkgs, claude-code, catppuccin, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
        catppuccin.nixosModules.catppuccin

        ({ config, pkgs, ... }: {
          environment.systemPackages = [
            claude-code.packages.${system}.default
          ];
        })
      ];
    };
  };
}
