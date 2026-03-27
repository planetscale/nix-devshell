{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.follows = "planetscale/flake-parts";
    planetscale = {
      url = "github:planetscale/nix-devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Add modules here.
      # imports and inputsFrom below should mirror each other.
      imports = with inputs.planetscale.flakeModules; [
        base
        go
      ];

      perSystem =
        { pkgs, config, ... }:
        {
          devShells.default = pkgs.mkShell {
            inputsFrom = with config.devShells; [
              base
              go
            ];

            # Project-specific tools.
            packages = with pkgs; [ ];

            # Environment variables.
            GOPRIVATE = "github.com/planetscale/*";

            # shellHook = ''
            #   export PATH="$PWD/bin:$PATH"
            # '';
          };
        };
    };
}
