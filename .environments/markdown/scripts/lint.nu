#!/usr/bin/env nu

use ../../default/scripts/paths.nu get-paths

# Lint markdown files
def main [
  ...paths: string # Files or directories to format
] {
  markdownlint-cli2 ...(get-paths $paths --extension md) out> /dev/null
}
