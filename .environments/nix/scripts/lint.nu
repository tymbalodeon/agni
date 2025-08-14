#!/usr/bin/env nu

use ../../default/scripts/paths.nu get-paths

# Lint nix files
def main [
  ...paths: string # Files or directories to format
] {
  statix fix ...(get-paths $paths --extension nix)
}
