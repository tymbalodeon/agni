#!/usr/bin/env nu

use find-script.nu

export def display-just-help [
  recipe?: string
  subcommands?: list<string>
  --environment: string
  --justfile: string
] {
  let args = [
    --color always
    --list
  ]

  if ($recipe | is-empty) {
    let args = (
      $args
      | append (
          match $justfile {
            null => [--list-submodules]
            _ => [--justfile $justfile]
          }
        )
    )

    return (^just ...$args)
  }

  let recipe = match $environment {
    null => $recipe
    _ => $"($environment)/($recipe)"
  }

  let script = (find-script $recipe)

  mut recipe_is_module = false

  let script = if ($script | is-empty) {
    let args = ([$recipe] ++ $subcommands)

    if ($args | length) > 1 {
      $recipe_is_module = true

      find-script (
        $args
        | window 2
        | first
        | str join "/"
      )
    } else {
      try {
        return (^just ...$args $recipe --quiet)
      } catch {
        return
      }
    }
  } else {
    $script
  }

  let subcommands = if $recipe_is_module {
    $subcommands
    | drop nth 0
  } else {
    $subcommands
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
  --aliases # View module aliases
  --default
] {
  let output = (display-just-help $recipe $subcommands)

  if ($output | is-not-empty) {
    if $aliases {
      $output
      | split row "\n\n"
      | last
    } else if $default {
      $output
      | split row "[aliases]"
      | first
      | split row "\n\n"
      | first
    } else {
      $output
    }
  }
}
