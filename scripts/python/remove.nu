#!/usr/bin/env nu

use ./remove.nu get-dependencies

# Remove dependencies
def main [
  ...dependencies: string # Dependencies to remove
] {
  let dependencies = (get-dependencies)

  for $dependency in $dependencies {
    if $dependency in $dependencies.dev {
      uv remove --dev $dependency
    } else if $dependency in $dependencies.prod {
      uv remove $dependency
    }
  }
}
