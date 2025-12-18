# nix-devshell

Shared Nix Flake development environments for PlanetScale engineering teams.

## Overview

This repository provides baseline development shells that teams can layer
their own tooling on top of. The goal is consistent, reproducible
environments across all projects.

**Layering approach:**
1. `default` - baseline tools for all engineering teams
2. Team-specific shells (e.g., `queryPath`) - add team tooling
3. Individual project flakes - add project-specific dependencies

## Requirements

- [Nix](https://nixos.org/) with flakes enabled
- [direnv](https://direnv.net/) (optional, for automatic shell activation)

## Available Shells

| Shell | Description |
|-------|-------------|
| `default` | Baseline for all engineering teams |
| `dev` | Nix linting and formatting tools |
| `queryPath` | Query Path team baseline (extends default) |

## Usage

### Using in a project

Reference this flake as an input in your project's `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    planetscale.url = "github:planetscale/nix-devshell";
  };

  outputs = { self, nixpkgs, flake-utils, planetscale, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          inputsFrom = [ planetscale.devShells.${system}.queryPath ];
          packages = with pkgs; [
            # project-specific tools here
          ];
        };
      }
    );
}
```

### Adding a team shell

Teams can add their own baseline shells. For example, an `orch` team shell:

```nix
devShells.orch = pkgs.mkShell {
  inputsFrom = [ self.devShells.${system}.default ];
  packages = with pkgs; [
    # orch team tools
  ];
};
```

## Included Tools

### default (all teams)

- awscli2
- bash
- fd
- git
- gnumake
- google-cloud-sdk
- jq
- ripgrep

### dev

- statix (Nix linter)
- deadnix (dead code finder)
- nixfmt-rfc-style (formatter)

### queryPath

- Everything in `default`
- just (command runner)
