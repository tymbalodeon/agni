{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nutest = {
      flake = false;
      url = "github:vyadh/nutest";
    };
  };

  outputs = {
    nixpkgs,
    nutest,
    ...
  }: let
    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems
      (system:
        f rec {
          mergeModuleAttrs = {
            attr,
            nullValue,
          }:
            pkgs.lib.lists.flatten
            (map (module: module.${attr} or nullValue) modules);

          modules =
            map (module: (import ./nix/${module} {inherit pkgs;}))
            (
              if (builtins.pathExists ./nix)
              then (builtins.attrNames (builtins.readDir ./nix))
              else []
            );

          pkgs = import nixpkgs {inherit system;};
        });

    supportedSystems = [
      "x86_64-darwin"
      "x86_64-linux"
    ];
  in {
    devShells = forEachSupportedSystem ({
      mergeModuleAttrs,
      modules,
      pkgs,
    }: {
      default = pkgs.mkShell ({
          packages = with pkgs;
            [
              alejandra
              ansible-language-server
              bat
              cocogitto
              deadnix
              delta
              eza
              fd
              flake-checker
              fzf
              gh
              git
              glab
              jujutsu
              just
              lychee
              markdown-oxide
              marksman
              nb
              nil
              nodePackages.prettier
              nushell
              pre-commit
              python312Packages.pre-commit-hooks
              ripgrep
              serie
              statix
              stylelint
              taplo
              tokei
              vscode-langservers-extracted
              yaml-language-server
              yamlfmt
            ]
            ++ mergeModuleAttrs {
              attr = "packages";
              nullValue = [];
            };

          shellHook = with pkgs;
            lib.concatLines (
              [
                "pre-commit install --hook-type commit-msg"
                "export NUTEST=${nutest}"
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
    });
  };
}
