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
    let
      inherit (flake-parts.lib) importApply;
      withMattware = { inherit (inputs) mattware; };
      zig = version: importApply ./modules/zig.nix (withMattware // { inherit version; });
      go = version: importApply ./modules/go.nix (withMattware // { inherit version; });

      # flakeModules is a plain attrset and has no wildcard keys, so every
      # version a consumer can write must exist at eval time. Generate them
      # instead of listing them: zig."0.18" evaluates as soon as the nixpkgs
      # pin carries zig_0_18, and the module names the missing attribute when
      # the pin is older.
      zigVersions =
        map (minor: "0.${toString minor}") (builtins.genList (i: i + 10) 90)
        ++ map (minor: "1.${toString minor}") (builtins.genList (i: i) 20);
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake.templates = {
        go = {
          path = ./templates/go;
          description = "Go project with PlanetScale devShell";
        };
      };

      flake.flakeModules = {
        base = ./modules/base.nix;
        nix = ./modules/nix.nix;
        # Version namespaces: consumers import go."1.27" / zig."0.17", exactly
        # one each. Two entries conflict on devShells.go / devShells.zig, which
        # is the desired loud failure.
        # fromGoMod is a go namespace entry too: it resolves the toolchain from
        # the consumer's go.mod instead of pinning a version here.
        go = {
          "1.24" = go "1.24";
          "1.25" = go "1.25";
          "1.26" = go "1.26";
          "1.27" = go "1.27";
          fromGoMod = importApply ./modules/go.nix (withMattware // { version = null; });
        };
        zig = builtins.listToAttrs (
          map (version: {
            name = version;
            value = zig version;
          }) zigVersions
        );
        queryPath = importApply ./modules/teams/query-path.nix {
          baseModule = ./modules/base.nix;
        };
      };

      imports = [
        ./modules/base.nix
        ./modules/nix.nix
        (go "1.27")
        (zig "0.17")
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
            packages = [
              config.treefmt.build.wrapper
              # GitHub Actions auditing for this repo's .github/. Consumers do
              # not need these, so they stay out of the shared modules. zizmor
              # builds because the nixpkgs input is pinned to the last
              # revision before 1.32.0.
              pkgs.pinact
              pkgs.zizmor
            ];
          };

          devShells.default = config.devShells.base;
        };
    };
}
