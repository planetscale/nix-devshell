{ mattware }:
{ lib, ... }: {
  perSystem =
    { system, pkgs, config, ... }:
    {
      options = {
        nix-devshell.go.package = lib.mkOption {
          type = lib.types.package;
          default = mattware.packages.${system}.go-bin_1_26;
          defaultText = lib.literalExpression "mattware.packages.\${system}.go-bin_1_26";
        };
      };

      config = {
        devShells.go = pkgs.mkShell {
          packages = [
            config.nix-devshell.go.package
            pkgs.gopls
            pkgs.golangci-lint
          ];
        };
      };
    };
}
