{ mattware, version }:
{
  perSystem =
    {
      system,
      pkgs,
      ...
    }:
    let
      # "0.16" -> "0_16", the nixpkgs attribute suffix
      v = builtins.replaceStrings [ "." ] [ "_" ] version;
    in
    {
      # The imported version *is* `devShells.zig`; import exactly one.
      # Two versions conflict on this attrpath, which is the desired loud failure.
      devShells.zig = pkgs.mkShell {
        packages = [
          pkgs."zig_${v}"
          pkgs."zls_${v}"
          mattware.packages.${system}.ziglint
          mattware.packages.${system}.zigdoc
        ];
      };
    };
}
