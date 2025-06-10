#!/usr/bin/env nu

use ../environment.nu get-project-path
use ../help.nu display-just-help

# View module aliases
def "main aliases" [] {
  open just/python.just
  | lines
  | where {str starts-with  alias}
  | to text
}

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
