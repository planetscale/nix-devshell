{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    mattware = {
      url = "github:mattrobenolt/nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake.flakeModules =
        let
          importApply = flake-parts.lib.importApply;
          withMattware = { inherit (inputs) mattware; };
        in
        {
          base = ./modules/base.nix;
          go = importApply ./modules/go.nix withMattware;
          zig = importApply ./modules/zig.nix withMattware;
          queryPath = importApply ./modules/teams/query-path.nix {
            baseModule = ./modules/base.nix;
          };
        };

      imports = [ ./modules/base.nix ];

      perSystem =
        { pkgs, config, ... }:
        {
          devShells.dev = pkgs.mkShell {
            packages = with pkgs; [
              statix
              deadnix
              nixfmt
            ];
          };

          devShells.default = config.devShells.base;
        };
    };
}
