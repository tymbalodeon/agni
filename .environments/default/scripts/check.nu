#!/usr/bin/env nu

use ../../git/scripts/leaks.nu

export def run-check [name: string paths: list<string>] {
  let justfiles = (
    open Justfile
    | lines
    | where {str starts-with mod}
    | each {
        let environment = (
          split row "mod "
          | last
          | split row " "
          | first
        )

        $".environments/($environment)/Justfile"
      }
    | where {path exists}
    | each {
        |environment|

        let recipes = (
          just --summary --justfile $environment
          | split row " "
        )

        if $name in $recipes {
          $environment
        }
      }
    | where {is-not-empty}
  )

  for justfile in $justfiles {
    let environment = ($justfile | path split | get 1)
    print $"($name | str capitalize)ing ($environment) files..."
    just --justfile $justfile $name ...$paths
  }
}

# Run checks
export def main [] {
  leaks
  nix flake check

  let checks = (
    just --summary
    | split row " "
    | where {
        ($in | str ends-with :check) or (
          $in
          | str starts-with format
        ) or (
          $in
          | str starts-with lint
        )
      }
  )

  for check in $checks {
    just $check
  }
}
