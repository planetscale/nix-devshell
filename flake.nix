{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.dev = pkgs.mkShell {
          packages = with pkgs; [
            statix
            deadnix
            nixfmt-rfc-style
          ];
        };

        devShells.default = pkgs.mkShell {
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

        devShells.queryPath = pkgs.mkShell {
          inputsFrom = [ self.devShells.${system}.default ];
          packages = with pkgs; [
            just
          ];
        };
      }
    );
}
