#!/usr/bin/env nu

use find-recipe.nu choose-recipe
use find-script.nu

# View the source code for a recipe. If no args are provided, display
# the raw `just` code, otherwise display the code with the args provided
# to `just` applied. Pass `""` as args to see the code when no args are
# provided to a recipe, and to see the code with `just` variables expanded.
def main [
  recipe_or_environment?: string # Recipe or environment name
  recipe?: string # Recipe name
] {
  let recipe = if ($recipe | is-not-empty) {
      $"($recipe_or_environment)/($recipe)"
  } else {
    match $recipe_or_environment {
      null => (choose-recipe)
      _ => $recipe_or_environment
    }
  }

  try {
    bat (find-script $recipe)
  }
}
