#!/usr/bin/env nu

use check.nu get-files

# Remove trailing whitespace from lines
def main [
  ...paths: string # Files or directories to fix
] {
  for file in (
    get-files $paths
    | where {
        open --raw $in
        | lines
        | where {($in | str ends-with " ") and ($in != "\n")}
        | is-not-empty
      }
  ) {
    open --raw $file
    | lines
    | each {$in | str trim --right}
    | to text
    | collect
    | save --force $file
  }
}
