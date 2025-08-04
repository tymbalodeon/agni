#!/usr/bin/env nu

use ../../default/scripts/paths.nu get-paths

# Format markdown files
def main [
  ...paths: string # Files or directories to format
] {
  let paths = if ($paths | is-empty) {
    fd --extension md
    | lines
  } else {
    get-paths $paths
    | where {($in | path parse | get extension) == md}
  }

  prettier --parser markdown --write ...$paths out> /dev/null
}
