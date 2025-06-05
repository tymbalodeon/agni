#!/usr/bin/env nu

use environment.nu get-project-root

def main [
  find: string # The text to match and replace
  replace: string # The text to replace with
  path?: string # Limit to a specific path
  --preview # Preview changes without writing
] {
  let path = if ($path | is-empty) {
    get-project-root
  } else {
    $path
  }

  let files = if ($path | path type) == dir {
    fd --exclude *.lock --type file "" $path
    | lines
  } else {
    [$path]
  }

  for file in $files {
    if $preview {
      sd --preview $find $replace $file
    } else {
      sd $find $replace $file
    }
  }
}
