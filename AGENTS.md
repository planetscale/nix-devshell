# nix-devshell

This repo (`planetscale/nix-devshell`) exports shared flake-parts modules consumed by PlanetScale projects.

## Architecture

```
flake.nix                        # exports flakeModules, owns the dev shell for this repo
modules/
  base.nix                       # company-wide tools, sets systems via lib.mkDefault
  go.nix                         # Go toolchain, parameterized by version (mattware + version args)
                                 # exported as a version namespace: flakeModules.go."1.27"
                                 # nix-devshell.go.package defaults to the selected go-bin
  zig.nix                        # Zig toolchain, parameterized by version (mattware + version args)
                                 # exported as a version namespace: flakeModules.zig."0.16"
  teams/
    query-path.nix               # queryPath team module (imports base + adds just)
```

## How Modules Are Exported

Modules are exported via `flake.flakeModules` in `flake.nix`. Two patterns are used:

**Direct path** — for modules that only need nixpkgs (resolved by the consumer's flake-parts):
```nix
base = ./modules/base.nix;
```

**`importApply`** — for modules that need access to *this* flake's own inputs (e.g. `mattware`):
```nix
go = importApply ./modules/go.nix { inherit (inputs) mattware; };
```

`importApply` bakes in the provider-side values at export time. Without it, `inputs.mattware` inside a module would refer to the *consumer's* inputs, where mattware doesn't exist.

**Version namespace** — for toolchain modules that consumers pick a version of at import time (`go`, `zig`):
```nix
go = {
  "1.24" = go "1.24";
  "1.27" = go "1.27";
};
zig = {
  "0.15" = zig "0.15";
  "0.16" = zig "0.16";
};
```
Consumers import `go."1.27"` / `zig."0.16"` (exactly one — two versions conflict on the `devShells.<name>` attrpath). The zig module maps the version onto nixpkgs attrs (`zig_0_16`, `zls_0_16`); the go module maps it onto mattware attrs (`go-bin_1_27`) and defaults `nix-devshell.go.package` to it. Add a version by adding an entry to the namespace in `flake.nix`.

## Module Structure

A module that needs nix-devshell inputs (like `mattware`) takes them as the first argument:

```nix
{ mattware }: { lib, ... }: {
  perSystem = { system, pkgs, config, ... }: {
    options = {
      nix-devshell.go.package = lib.mkOption {
        type = lib.types.package;
        default = mattware.packages.${system}.go-bin_1_27;
      };
    };
    config = {
      devShells.go = pkgs.mkShell {
        packages = [ config.nix-devshell.go.package pkgs.gopls ];
      };
    };
  };
}
```

A module that only uses nixpkgs (no nix-devshell inputs needed) skips the first argument:

```nix
{ lib, ... }: {
  systems = lib.mkDefault [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
  perSystem = { pkgs, ... }: {
    devShells.base = pkgs.mkShell { ... };
  };
}
```

## Adding a New Module

1. Create `modules/<name>.nix`
2. If it needs `mattware` (or other nix-devshell inputs), use the two-argument form above
3. Export it in `flake.nix`:
   - Direct path if no nix-devshell inputs needed
   - `importApply ./modules/<name>.nix { inherit (inputs) mattware; }` otherwise
4. If it adds a `devShells.<name>`, consumers use `inputsFrom = [ config.devShells.<name> ]`

## Package Sources

- **Go packages** (`go-bin_1_27`, `go-bin_1_24`, etc.) — come from `mattware` (`github:mattrobenolt/nixpkgs`), not upstream nixpkgs. Mattware keeps these more up to date. The `go` namespace maps version strings to these attrs.
- **Zig** (`zig_0_15`/`zls_0_15`, `zig_0_16`/`zls_0_16`) — come from upstream nixpkgs; the zig module pairs each version with its matching zls. Add a version by adding an entry to the `zig` namespace in `flake.nix`.
- **Zig tools** (`ziglint`, `zigdoc`) — come from `mattware`

## Key Rules

- **Never use `nix flake update`** — only update specific inputs: `nix flake lock --update-input <name>`
- **`nixpkgs` in `base.nix` is this repo's own pin** — consumers pin nixpkgs independently (do not follow from planetscale)
- **`x86_64-darwin` is not supported** — base sets `lib.mkDefault` to the three supported systems; consumers can restrict further for Linux-only projects
- **`inputsFrom` does not propagate env vars or shellHook** — consumers needing shared config across multiple shells must use a `let mkDevShell = ...` pattern

## Dev Shell for This Repo

```bash
nix develop          # enters the base shell (default = devShells.base)
nix develop .#dev    # treefmt wrapper (nixfmt, statix, deadnix)
nix flake check      # runs treefmt check + validates all devShells
```
