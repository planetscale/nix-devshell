{ lib, ... }:
{
  systems = lib.mkDefault [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];

  perSystem =
    { pkgs, ... }:
    {
      devShells.base = pkgs.mkShell {
        packages = with pkgs; [
          awscli2
          bash
          fd
          git
          gnumake
          google-cloud-sdk
          jq
          ripgrep
        ];

        shellHook = ''
          export PATH=$HOME/.ps-toolbox/bin:$PATH
        '';
      };
    };
}
