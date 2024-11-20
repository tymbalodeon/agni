#!/usr/bin/env nu

use find-script.nu

export def display-just-help [
  recipe?: string
  subcommands?: list<string>
  --environment: string
  --justfile: string
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
    if ($subcommands | is-empty) {
      nu $script "--self-help"
    } else {
      nu $script ...$subcommands "--self-help"
    }
  } else {
    if ($subcommands | is-empty) {
      nu $script --help
    } else {
      nu $script ...$subcommands --help
    }
  }
}

# View help text
def main [
  recipe?: string # View help text for recipe
  ...subcommands: string  # View help for a recipe subcommand
] {
  display-just-help $recipe $subcommands
}
