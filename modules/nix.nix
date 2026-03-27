_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.nix = pkgs.mkShell {
        packages = with pkgs; [
          deadnix
          nixfmt
          statix
        ];
      };
    };
}
