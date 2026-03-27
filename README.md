# nix-devshell

Shared [flake-parts](https://github.com/hercules-ci/flake-parts) modules for PlanetScale development environments.

## Getting Started

```bash
nix flake init -t github:planetscale/nix-devshell#go
```

## Usage

```nix
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
      imports = with inputs.planetscale.flakeModules; [
        base
        go
        zig
      ];

      perSystem =
        { pkgs, config, ... }:
        {
          devShells.default = pkgs.mkShell {
            inputsFrom = with config.devShells; [
              base
              go
              zig
            ];
            packages = with pkgs; [ just ];
          };
        };
    };
}
```

## Modules

- `base` — company-wide tools (awscli2, gcloud, jq, ripgrep, …) and ps-toolbox PATH
- `go` — Go toolchain. Overridable via `nix-devshell.go.package`.
- `zig` — Zig toolchain. Overridable via `nix-devshell.zig.package`.
- `nix` — Nix linting and formatting (nixfmt, statix, deadnix)
- `queryPath` — Query Path team module
