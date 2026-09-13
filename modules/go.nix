{ mattware, version }:
{ lib, ... }:
{
  perSystem =
    {
      system,
      pkgs,
      config,
      ...
    }:
    let
      # "1.27" -> "1_27", the mattware attribute suffix
      v = builtins.replaceStrings [ "." ] [ "_" ] version;
    in
    {
      options = {
        # The imported version's go-bin. Kept as an option so consumers can
        # read the selection (exosphere derives .go-version from it); consumer
        # definitions still override the module default.
        nix-devshell.go.package = lib.mkOption {
          type = lib.types.package;
          default = mattware.packages.${system}."go-bin_${v}";
          defaultText = lib.literalExpression "mattware.packages.\${system}.go-bin_${v}";
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
