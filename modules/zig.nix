{ mattware }:
{ lib, ... }: {
  perSystem =
    { system, pkgs, config, ... }:
    {
      options = {
        nix-devshell.zig.package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.zig_0_15;
          defaultText = lib.literalExpression "pkgs.zig_0_15";
        };
      };

      config = {
        devShells.zig = pkgs.mkShell {
          packages = [
            config.nix-devshell.zig.package
            pkgs.zls_0_15
            mattware.packages.${system}.ziglint
            mattware.packages.${system}.zigdoc
          ];
        };
      };
    };
}
