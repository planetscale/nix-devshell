# nix-devshell

Shared [flake-parts](https://github.com/hercules-ci/flake-parts) modules for PlanetScale development environments.

## Getting Started

```bash
nix flake init -t github:planetscale/nix-devshell#go
```

The `go` template ships a `go.mod` and follows it (`go.fromGoMod`), so the devShell
toolchain tracks the module. In a project that already has a `go.mod`, `flake init`
leaves that file alone and the shell follows it as-is.

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
        go."1.27"
        zig."0.16"
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
- `go` — Go toolchain, a version namespace. Import the version you want (exactly one):
  ```nix
  imports = [ inputs.planetscale.flakeModules.go."1.27" ];
  ```
  The imported version provides `devShells.go` (go, gopls, golangci-lint, gotestsum).
  `nix-devshell.go.package` exposes the selected go-bin; consumer definitions still override it.
- `go.fromGoMod` — same shell, but the toolchain comes from your `go.mod` instead of a pinned version:
  ```nix
  imports = [ inputs.planetscale.flakeModules.go.fromGoMod ];
  ```
  A `toolchain go1.26.0` line wins when present. Otherwise `go 1.24.0` states a minimum
  and the newest tracked 1.24.x is used. Bumping the toolchain is then one file, not two.
  `nix-devshell.go.goMod` overrides the file; the default is `<flake root>/go.mod`.
  If `go.mod` names a release the pinned nixpkgs overlay does not track, evaluation fails
  and names it: update the `planetscale` input, or set `nix-devshell.go.package` yourself.
- `zig` — Zig toolchain, a version namespace. Import the version you want (exactly one):
  ```nix
  imports = [ inputs.planetscale.flakeModules.zig."0.16" ];
  ```
  The imported version provides `devShells.zig` (zig, matching zls, ziglint, zigdoc).
- `nix` — Nix linting and formatting (nixfmt, statix, deadnix)
- `queryPath` — Query Path team module
