#!/usr/bin/env nu

use find-script.nu

# Open the source code for a recipe
def "main open" [
  recipe_or_environment?: string # Recipe or environment name
  recipe?: string # Recipe name
] {
  let script = (find-script $recipe_or_environment $recipe)

  if ($script | is-not-empty) {
    ^$env.EDITOR $script
  }
}

# View the source code for a recipe
def "main view" [
  recipe_or_environment?: string # Recipe or environment name
  recipe?: string # Recipe name
] {
  let script = (find-script $recipe_or_environment $recipe)

  if ($script | is-not-empty) {
    bat $script
  }
}

# View or open recipes
def main [
  recipe_or_environment?: string # Recipe or environment name
  recipe?: string # Recipe name
] {
  main view $recipe_or_environment $recipe
}
