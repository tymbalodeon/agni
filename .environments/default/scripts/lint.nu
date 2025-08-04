#!/usr/bin/env nu

use check.nu run-check

# Lint files
def main [
  ...paths: string # Files or directories to lint
] {
  run-check lint $paths
}
