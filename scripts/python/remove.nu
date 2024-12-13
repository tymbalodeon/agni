#!/usr/bin/env nu

use dependencies.nu get-dependencies

def remove-version [dependency: string] {
  $dependency 
  | split row ">=" 
  | first
}

# Remove dependencies
def main [
  ...dependencies: string # Dependencies to remove
] {
  let dependencies = (
    get-dependencies
    | update dev {remove-version}
    | update prod {remove-version}
  )

  for $dependency in $dependencies {
    if $dependency in $dependencies.dev {
      uv remove --dev $dependency
    } else if $dependency in $dependencies.prod {
      uv remove $dependency
    }
  }
}
