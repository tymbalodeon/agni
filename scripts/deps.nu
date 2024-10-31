#!/usr/bin/env nu

use ./environment.nu list_nix_folder

def get_flake_dependencies [flake: string] {
  $flake
  | rg --multiline "packages = .+(\n|\\[|[^;])+\\]"
  | lines
  | drop nth 0
  | filter {|line| "[" not-in $line and "]" not-in $line}
  | str trim
}

export def merge_flake_dependencies [...flakes: string] {
  $flakes
  | each {
      |flake|

      get_flake_dependencies $flake
    }
  | flatten
  | uniq
  | sort
  | to text
}

# List dependencies
def main [
  dependency?: string # Search for a dependency
  --environment: string # List only dependencies for $environment
] {
  let environment_files = (
    "flake.nix" ++ (list_nix_folder | get name)
  )

  let environment_files = if ($environment | is-empty) {
    $environment_files
  } else {
    $environment_files
    | filter {
        |file|

        (
          $file
          | path basename
          | path parse
          | get stem
          | str replace --regex "^flake$" "generic"
        ) == $environment
      }
  }

  let flakes = (
    $environment_files
    | each {|flake| open $flake}
  )

  let dependencies = (merge_flake_dependencies ...$flakes)

  if ($dependency | is-empty) {
    print --no-newline $dependencies
  } else {
    try {
      $dependencies
      | rg --color always $dependency
    }
  }
}
