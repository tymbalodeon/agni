#!/usr/bin/env nu

use ../environment.nu get-project-path
use ../help.nu display-just-help

# View help text
def main [
  recipe?: string # View help text for recipe
  ...subcommands: string  # View help for a recipe subcommand
] {
  let environment = "python"

  (
    display-just-help
      $recipe
      $subcommands
      --environment $environment
      --justfile (get-project-path $"just/($environment).just")
  )
}
