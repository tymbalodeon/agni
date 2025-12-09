{
  inputs = {
    environments = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:tymbalodeon/environments/trunk?dir=src";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nutest = {
      flake = false;
      url = "github:vyadh/nutest";
    };

    systems.url = "github:nix-systems/default";
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
        mergeModuleAttrs = {
          attr,
          nullValue,
        }:
          pkgs.lib.lists.flatten
          (map (module: module.${attr} or nullValue) modules);

        modules =
          map
          (module: (import module {inherit pkgs;}))
          (builtins.filter
            (path: builtins.pathExists path)
            (map
              (item: ./.environments/${item.name}/shell.nix)
              (builtins.filter
                (item: item.value == "directory")
                (
                  if (builtins.pathExists ./.environments)
                  then
                    nixpkgs.lib.attrsets.attrsToList
                    (builtins.readDir ./.environments)
                  else []
                ))));

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
                  if builtins.pathExists ./.environments/environments.toml
                  then let
                    environments =
                      builtins.fromTOML
                      (builtins.readFile ./.environments/environments.toml);
                  in
                    if builtins.hasAttr "environments" environments
                    then
                      builtins.map (environment: environment.name)
                      environments.environments
                    else []
                  else []
                )
                ++ [
                  "default"
                  "git"
                  "just"
                  "markdown"
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
