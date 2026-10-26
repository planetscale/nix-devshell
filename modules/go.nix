{
  mattware,
  version ? null,
}:
{ lib, self, ... }:
{
  perSystem =
    {
      system,
      pkgs,
      config,
      ...
    }:
    let
      # A null version means: resolve the toolchain from the consumer's go.mod.
      fromGoMod = version == null;

      # "1.27" -> "1_27", the mattware attribute suffix
      v = builtins.replaceStrings [ "." ] [ "_" ] version;

      package =
        if fromGoMod then
          mattware.packages.${system}.go-bin.fromGoMod config.nix-devshell.go.goMod
        else
          mattware.packages.${system}."go-bin_${v}";
    in
    {
      options.nix-devshell.go = {
        # The imported version's go-bin. Kept as an option so consumers can
        # read the selection (exosphere derives .go-version from it); consumer
        # definitions still override the module default.
        package = lib.mkOption {
          type = lib.types.package;
          default = package;
          defaultText = lib.literalExpression (
            if fromGoMod then
              "mattware.packages.\${system}.go-bin.fromGoMod ./go.mod"
            else
              "mattware.packages.\${system}.go-bin_${v}"
          );
        };
      }
      // lib.optionalAttrs fromGoMod {
        goMod = lib.mkOption {
          type = lib.types.path;
          default = self.outPath + "/go.mod";
          description = ''
            go.mod or go.work file that selects the toolchain. The `toolchain`
            directive wins; otherwise the `go` directive states a minimum and
            the newest tracked patch of that minor is used.
          '';
        };
      };

      config = {
        # The imported version *is* `devShells.go`; import exactly one.
        # Two versions conflict on this attrpath, which is the desired loud failure.
        devShells.go = pkgs.mkShell {
          packages = [
            config.nix-devshell.go.package
            pkgs.gopls
            pkgs.golangci-lint
            pkgs.gotestsum
          ];
        };
      };
    };
}
