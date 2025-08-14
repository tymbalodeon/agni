#!/usr/bin/env nu

use check.nu get-files

# Fix end of files
def main [
  ...paths: string # Files or directories to fix
] {
  for file in (get-files $paths) {
    open --raw $file
    | str trim
    | append "\n"
    | str join
    | to text
    | collect
    | save --force $file
  }
}
