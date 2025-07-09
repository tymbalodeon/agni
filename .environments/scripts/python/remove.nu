#!/usr/bin/env nu

use cd-to-root.nu
use dependencies.nu get-dependencies

def remove-version []: string -> string {
  try {
    $in
    | split row ">="
    | first
  }
}

# Remove dependencies
def main [
  ...dependencies: string # Dependencies to remove
] {
  cd-to-root

  let existing_dependencies = (
    get-dependencies
    | update dev {|row| $row.dev | each {remove-version}}
    | update prod {|row| $row.prod | each {remove-version}}
  )

  for $dependency in $dependencies {
    if $dependency in $existing_dependencies.dev {
      uv remove --dev $dependency
    } else if $dependency in $existing_dependencies.prod {
      uv remove $dependency
    }
  }
}
