{
  inputs = {
    environments = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:tymbalodeon/environments?dir=src";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nutest = {
      flake = false;
      url = "github:vyadh/nutest";
    };
  };

  outputs = {
    environments,
    nixpkgs,
    nutest,
    systems,
    ...
  }: {
    devShells = nixpkgs.lib.genAttrs (import systems) (
      system: let
        getFilenames = dir:
          if builtins.pathExists dir
          then builtins.attrNames (builtins.readDir dir)
          else [];

        mergeModuleAttrs = {
          attr,
          nullValue,
        }:
          pkgs.lib.lists.flatten
          (map (module: module.${attr} or nullValue) modules);

        modules =
          map
          (module: (import ./nix/${module} {inherit pkgs;}))
          (getFilenames ./nix);

        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        default = pkgs.mkShellNoCC ({
            inputsFrom =
              builtins.map
              (environment: environments.devShells.${system}.${environment})
              ((
                  if builtins.pathExists ./.environments.toml
                  then
                    builtins.map (environment: environment.name)
                    (
                      builtins.fromTOML (builtins.readFile ./.environments.toml)
                    ).environments
                  else []
                )
                ++ [
                  "generic"
                  "git"
                  "nix"
                  "toml"
                  "yaml"
                ]);

            packages = mergeModuleAttrs {
              attr = "packages";
              nullValue = [];
            };

            shellHook = with pkgs;
              lib.concatLines (
                [
                  ''
                    export NUTEST=${nutest}
                    export ENVIRONMENTS=${environments}
                    ${nushell}/bin/nu ${environments}/shell-hook.nu

                    ${pre-commit}/bin/pre-commit install \
                      --hook-type commit-msg \
                      --overwrite
                  ''
                ]
                ++ mergeModuleAttrs {
                  attr = "shellHook";
                  nullValue = "";
                }
              );
          }
          // builtins.foldl'
          (a: b: a // b)
          {}
          (map
            (module: builtins.removeAttrs module ["packages" "shellHook"])
            modules));
      }
    );
  };
}
