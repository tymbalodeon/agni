#!/usr/bin/env nu

use check.nu run-check

# Format files
def main [
  ...paths: string # Files or directories to format
] {
  run-check format $paths
}
