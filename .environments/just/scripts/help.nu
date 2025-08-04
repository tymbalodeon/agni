#!/usr/bin/env nu

use ../../default/scripts/help.nu display-aliases
use ../../default/scripts/help.nu display-just-help

# View module aliases
def "main aliases" [
  --color = "auto" # When to use colored output {always|auto|never}
  --sort-by-environment # Sort aliases by environment name
  --sort-by-recipe # Sort recipe by original recipe name
  --no-submodule-aliases # Don't include submodule aliases
] {
  (
    display-aliases
      $no_submodule_aliases
      $sort_by_environment
      $sort_by_recipe
      --color $color
      --justfile .environments/just/Justfile
  )
}

# View help text
def main [
  recipe?: string # View help text for recipe
  ...subcommands: string  # View help for a recipe subcommand
  --color = "always" # When to use colored output {always|auto|never}
] {
  (
    display-just-help
      just
      $recipe
      $subcommands
      --color $color
  )
}
