#!/usr/bin/env nu

def main [
  find: string # The text to match and replace
  replace: string # The text to replace with
  path?: string # Limit to a specific path
  --fixed-strings # Tread $find and $replace as literal strings
  --preview # Preview changes without writing
] {
  let path = if ($path | is-empty) {
    pwd
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
    mut args = [$find $replace $file]

    if $preview {
      $args = ($args | prepend "--preview")
    }

    if $fixed_strings {
      $args = ($args | prepend "--fixed-strings")
    }

    sd ...$args
  }
}
