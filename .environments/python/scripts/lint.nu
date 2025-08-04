#!/usr/bin/env nu

use ../../default/scripts/paths.nu get-paths

# Lint python files
def main [
  ...paths: string # Files or directories to format
] {
  ruff check --fix ...(get-paths $paths)
}
