#!/usr/bin/env nu

# TODO: only add this file if submodule formatters are present (they are
# included in the default environments for now, but maybe they won't be later, or
# could be turned off?)

# Format files
def main [
  ...paths: string # Files or directories to format
] {
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

        if "format" in $recipes {
          $environment
        }
      }
    | where {is-not-empty}
  )

  let paths = if ($paths | is-empty) {
    ["."]
  } else {
    $paths
  }

  for justfile in $justfiles {
    just --justfile $justfile format ...$paths
  }
}
