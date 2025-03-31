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
        activeEnvironments =
          if builtins.pathExists ./.environments.toml
          then
            (
              builtins.fromTOML (builtins.readFile ./.environments.toml)
            ).environments
          else [];

        getFilenames = dir:
          if builtins.pathExists dir
          then builtins.attrNames (builtins.readDir dir)
          else [];

        inactiveEnvironments =
          builtins.filter
          (environment: !(builtins.elem environment activeEnvironments))
          (
            let
              srcDirectory = builtins.readDir environments;
              srcDirectoryItems = builtins.attrNames srcDirectory;
            in
              builtins.filter
              (item: srcDirectory.${item} == "directory")
              srcDirectoryItems
          );

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
          config.allowUnfree = true;
          inherit system;
        };
      in {
        default = pkgs.mkShellNoCC ({
            inputsFrom =
              builtins.map
              (environment: environments.devShells.${system}.${environment})
              activeEnvironments;

            packages = mergeModuleAttrs {
              attr = "packages";
              nullValue = [];
            };

            shellHook = let
              getArgsOrNone = args:
                if args == ""
                then "none"
                else args;
            in
              with pkgs;
                lib.concatLines (
                  [
                    ''
                      export NUTEST=${nutest}
                      export ENVIRONMENTS=${environments}

                      ${pre-commit}/bin/pre-commit install \
                        --hook-type commit-msg \
                        --overwrite

                      ${nushell}/bin/nu ${environments}/shell-hook.nu \
                        --active-environments "${
                        getArgsOrNone (lib.concatStringsSep " " activeEnvironments)
                      }" \
                        --environments-directory "${environments}" \
                        --inactive-environments "${
                        getArgsOrNone (lib.concatStringsSep " " inactiveEnvironments)
                      }" \
                        --local-justfiles "${
                        getArgsOrNone (lib.concatStringsSep " " (
                          map
                          (filename:
                            builtins.elemAt
                            (lib.strings.splitString "." filename)
                            0)
                          (getFilenames ./just)
                        ))
                      }"

                      ${yamlfmt}/bin/yamlfmt .pre-commit-conifg.yaml
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
