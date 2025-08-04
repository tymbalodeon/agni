#!/usr/bin/env nu

use ../../default/scripts/paths.nu get-paths

def main [
  ...paths: string # Files or directories to format
] {
  let result = (alejandra --check ...(get-paths $paths) | complete)

  if $result.exit_code != 0 {
    print $result.stderr
  }
}
