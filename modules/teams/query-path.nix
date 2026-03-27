{ baseModule }:
{ ... }:
{
  imports = [ baseModule ];

  perSystem =
    { pkgs, config, ... }:
    {
      devShells.queryPath = pkgs.mkShell {
        inputsFrom = [ config.devShells.base ];
        packages = with pkgs; [ just ];
      };
    };
}
