#!/usr/bin/env nu

use ../../default/scripts/paths.nu get-paths

# Lint yaml files
def main [
  ...paths: string # Files or directories to format
] {
  yamllint ...(get-paths $paths)
}
