#!/usr/bin/env nu

use ../../default/scripts/paths.nu get-paths

# Format python files
def main [
  ...paths: string # Files or directories to format
] {
  ruff check --fix ...(get-paths $paths)
}
