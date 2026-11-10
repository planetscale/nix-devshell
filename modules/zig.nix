{ mattware, version }:
{ lib, ... }:
{
  perSystem =
    {
      system,
      pkgs,
      ...
    }:
    let
      # "0.17" -> "0_17", the nixpkgs attribute suffix
      v = builtins.replaceStrings [ "." ] [ "_" ] version;

      # The version is a free-form string, so naming one newer than the
      # nixpkgs pin is the likely mistake. Say which attribute is missing
      # instead of leaving the raw attribute error.
      zig =
        pkgs."zig_${v}"
          or (throw "nix-devshell: the pinned nixpkgs has no zig_${v}; update the nixpkgs input");
    in
    {
      # The imported version *is* `devShells.zig`; import exactly one.
      # Two versions conflict on this attrpath, which is the desired loud failure.
      devShells.zig = pkgs.mkShell {
        packages = [
          zig
          mattware.packages.${system}.ziglint
          mattware.packages.${system}.zigdoc
        ]
        # zls trails Zig. A version without a zls_<v> in nixpkgs gets a shell
        # with no language server, and gains one when nixpkgs adds it.
        ++ lib.optional (pkgs ? "zls_${v}") pkgs."zls_${v}";
      };
    };
}
