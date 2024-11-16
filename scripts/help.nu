#!/usr/bin/env nu

use find-script.nu

export def display-just-help [
  recipe?: string
  justfile?: string
  environment?: string
] {
  if ($recipe | is-empty) {
    return (
      match $justfile {
        null => (
          just
            --color always
            --list
            --list-submodules
        )

        _ => (
            just
              --color always
              --justfile $justfile
              --list
        )
      }
    )
  }

  let recipe = match $environment {
    null => $recipe
    _ => $"($environment)/($recipe)"
  }

  let script = (find-script $recipe)

  if ($script | is-empty) {
    try {
      return (just --color always --list $recipe --quiet)
    } catch {
      return
    }
  }

  if (rg "^def main --wrapped" $script | is-not-empty) {
    nu $script "--self-help"
  } else {
    nu $script --help
  }
}

# View help text
def main [
  recipe?: string # View help text for recipe
] {
  display-just-help $recipe
}
