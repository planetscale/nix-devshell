---
name: new-module
description: Create a new flake-parts module for planetscale/nix-devshell. Use when adding a new language toolchain module, team module, or any new shared devShell module to this repository.
---

# Creating a New nix-devshell Module

## Checklist

1. Create `modules/<name>.nix`
2. Export it in `flake.nix` under `flake.flakeModules`
3. If adding a team module, place it in `modules/teams/<name>.nix`

## Module Template

### Needs `mattware` (Go versions, Zig tools, etc.)

```nix
{ mattware }: { lib, ... }: {
  perSystem =
    { system, pkgs, config, ... }:
    {
      options = {
        nix-devshell.<name>.package = lib.mkOption {
          type = lib.types.package;
          default = mattware.packages.${system}.<package>;
          defaultText = lib.literalExpression "mattware.packages.\${system}.<package>";
        };
      };

      config = {
        devShells.<name> = pkgs.mkShell {
          packages = [
            config.nix-devshell.<name>.package
            pkgs.<tool1>
            pkgs.<tool2>
          ];
        };
      };
    };
}
```

### Only needs nixpkgs (no mattware)

```nix
{ lib, ... }: {
  perSystem =
    { pkgs, config, ... }:
    {
      devShells.<name> = pkgs.mkShell {
        packages = with pkgs; [ <tool1> <tool2> ];
      };
    };
}
```

### Team module (wraps base + adds team tools)

```nix
{ baseModule }: { ... }: {
  imports = [ baseModule ];

  perSystem =
    { pkgs, config, ... }:
    {
      devShells.<teamName> = pkgs.mkShell {
        inputsFrom = [ config.devShells.base ];
        packages = with pkgs; [ just <team-tools> ];
      };
    };
}
```

## Exporting in flake.nix

In the `flake.flakeModules` attrset:

```nix
# No nix-devshell inputs needed — direct path
<name> = ./modules/<name>.nix;

# Needs mattware — use importApply
<name> = importApply ./modules/<name>.nix withMattware;

# Team module needing baseModule
<teamName> = importApply ./modules/teams/<teamName>.nix {
  baseModule = ./modules/base.nix;
};
```

`withMattware` is already defined in `flake.nix` as `{ inherit (inputs) mattware; }`.

## Key Rules

- Use `importApply` whenever the module needs anything from *this* flake's inputs (mattware). Without it, `inputs` inside the module refers to the *consumer's* inputs — mattware won't be there.
- Options go under `nix-devshell.<name>.*` namespace.
- Include `defaultText` on any `lib.mkOption` that uses `${system}` interpolation (for documentation).
- Do not set `systems` in language modules — only `base` sets systems (via `lib.mkDefault`).
- Team modules should use `inputsFrom = [ config.devShells.base ]` rather than re-importing base directly, to avoid double-import issues.
