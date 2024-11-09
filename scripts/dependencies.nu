#!/usr/bin/env nu

use ./environment.nu list-nix-folder

def get-flake-dependencies [flake: string] {
  $flake
  | rg --multiline "packages = .+(\n|\\[|[^;])+\\]"
  | lines
  | drop nth 0
  | filter {|line| "[" not-in $line and "]" not-in $line}
  | str trim
}

export def merge-flake-dependencies [...flakes: string] {
  $flakes
  | each {
      |flake|

      get-flake-dependencies $flake
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
  let nix_files = "flake.nix" ++ (list-nix-folder | get name)

  let nix_files = if ($environment | is-empty) {
    $nix_files
  } else {
    $nix_files
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

  let contents = (
    $nix_files
    | each {|flake| open $flake}
  )

  let dependencies = (merge-flake-dependencies ...$contents)

  if ($dependency | is-empty) {
    print --no-newline $dependencies
  } else {
    try {
      $dependencies
      | rg --color always $dependency
    }
  }
}
