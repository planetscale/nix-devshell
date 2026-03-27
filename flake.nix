{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    mattware = {
      url = "github:mattrobenolt/nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, treefmt-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake.templates = {
        go = {
          path = ./templates/go;
          description = "Go project with PlanetScale devShell";
        };
      };

      flake.flakeModules =
        let
          inherit (flake-parts.lib) importApply;
          withMattware = { inherit (inputs) mattware; };
        in
        {
          base = ./modules/base.nix;
          go = importApply ./modules/go.nix withMattware;
          nix = ./modules/nix.nix;
          zig = importApply ./modules/zig.nix withMattware;
          queryPath = importApply ./modules/teams/query-path.nix {
            baseModule = ./modules/base.nix;
          };
        };

      imports = [
        ./modules/base.nix
        ./modules/nix.nix
        treefmt-nix.flakeModule
      ];

      perSystem =
        { pkgs, config, ... }:
        {
          treefmt.config = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.statix.enable = true;
            programs.deadnix.enable = true;
          };

          devShells.dev = pkgs.mkShell {
            inputsFrom = [ config.devShells.nix ];
            packages = [ config.treefmt.build.wrapper ];
          };

          devShells.default = config.devShells.base;
        };
    };
}
