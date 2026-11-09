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

## GitHub Actions

The repository ships a composite action at `.github/actions/setup-nix`. It
installs Nix and restores the devShell closure from the Actions cache. On Depot
runners the Actions cache is Depot Cache.

```yaml
jobs:
  test:
    runs-on: depot-ubuntu-24.04
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha> # v7.0.1
        with:
          persist-credentials: false

      - uses: planetscale/nix-devshell/.github/actions/setup-nix@<sha> # v0.1.1

      - run: nix develop .#dev --command just test
```

Pin the action by SHA and keep the version in a comment; pinact verifies that
the two agree. A job that uses the action needs no other Nix setup.

Tags are cut automatically, as `v0.1.<n>`, when a commit changes
`.github/actions/`. Commits elsewhere in the repository get no tag, because
consumers only ever reference the action.

### Inputs

| Input | Default | Description |
| --- | --- | --- |
| `cache` | `true` | Restore and save the Nix store through the Actions cache. |
| `primary-key` | derived | Cache key. The default uses the runner OS and architecture and the digest of `flake.lock`. |
| `github-token` | workflow token | Token for `github:` flake inputs. Pass a bot token when the flake reads private sibling repositories, because the workflow token cannot. |
| `git-auth-token` | empty | Token for a global git `insteadOf` rewrite. This covers `git+https` flake inputs from private repositories. |

### Outputs

| Output | Description |
| --- | --- |
| `cache-hit` | `true` when the Nix store came from a cache entry, including a partial match. |
| `cache-key` | Cache key the store was saved under. |

### Cache behaviour

The key contains the `flake.lock` digest. When the lock file changes, the action
restores the previous store through the key prefix and downloads only the paths
that changed. The job then saves a new entry under the new key.

The action installs one Nix version for every repository: `install_url` is
pinned to a release, and it does not follow the latest Nix. Bump that line when
you mean to move the org.

Measured on Depot runners, restoring one project devShell closure (3.3 GiB over
149 paths) takes 4 to 9 seconds. A cold download from cache.nixos.org takes 24 to
31 seconds. `DeterminateSystems/magic-nix-cache-action` gives no speedup on
Depot runners: the store uploads fail or never happen, so every job stays cold.
