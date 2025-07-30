#!/usr/bin/env nu

# Lint nix files
def main [
  ...paths: string # Files or directories to format
] {
  let paths = if ($paths | is-empty) {
    ["."]
  } else {
    $paths
  }

  statix fix ...$paths
}
