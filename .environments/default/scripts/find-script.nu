#!/usr/bin/env nu

use environment-common.nu parse-environments

export def choose-recipe [environment?: string] {
  let recipes = (just --summary | split row " ")

  let recipes = if ($environment | is-not-empty) {
    $recipes
    | where {$"($environment)::" in $in}
  } else {
    $recipes
  }

  $recipes
  | each {
      |recipe|

      if :: in $recipe {
        let parts = ($recipe | split row ::)

       $".environments/($parts | first)/scripts/($parts | last).nu"
      } else {
        $".environments/default/scripts/($recipe).nu"
      }
  }
  | to text
  | (
      fzf
        --preview
        "bat --force-colorization {}"
    )
  | str trim
  | split row " "
  | first
}

export def get-script [
  scripts: list<string>
  path_or_environment_or_recipe?: string
  recipe?: string
  quiet = true
] {
  if ($path_or_environment_or_recipe | is-not-empty) and (
    $path_or_environment_or_recipe | path exists
  ) {
    return $path_or_environment_or_recipe
  }

  let parts = if ($recipe | is-empty) and (
    $path_or_environment_or_recipe
    | is-not-empty
  ) {
    $path_or_environment_or_recipe
    | split row "::"
    | split row "/"
  }

  let recipe_name = if ($recipe | is-not-empty) {
    $recipe
  } else if ($path_or_environment_or_recipe | is-not-empty) {
    $parts
    | last
  } else {
    return (choose-recipe)
  }

  let environment = if ($recipe | is-not-empty) {
    $path_or_environment_or_recipe
  } else if ($path_or_environment_or_recipe | is-not-empty) {
    if ($parts | length) == 1 {
      ""
    } else {
      $parts
      | first
    }
  }

  let recipe = $recipe_name

  let matching_scripts = (
    $scripts
    | where {
        let path = ($in | path parse)

        $path.stem == $recipe and $path.extension == "nu"
      }
  )

  let matching_scripts = if ($matching_scripts | length) > 1 {
    if ($environment | is-not-empty) {
      let matches = (
        $matching_scripts
        | str replace .environments/ ""
        | find --no-highlight $environment
      )

      let matching_scripts = (
        $matching_scripts
        | where {
            |script|

            $matches
            | where {$in in $script}
            | is-not-empty
          }
      )

      if ($matching_scripts | is-empty) {
        return
      }

      $matching_scripts
    } else {
      $matching_scripts
    }
  } else if ($recipe | is-not-empty) and ($matching_scripts | is-empty) {
    let environment = (parse-environments [$recipe] $quiet)

    if ($environment | is-not-empty) {
      return (choose-recipe ($environment | first | get name))
    } else {
      return
    }
  } else {
    $matching_scripts
  }

  if ($matching_scripts | length) > 1 {
    $matching_scripts
    | to text
    | (
        fzf
          --preview
          "bat --force-colorization {}"
      )
  } else {
    if ($matching_scripts | is-not-empty) {
      $matching_scripts
      | first
    }
  }
}

export def main [
  environment_or_recipe?: string
  recipe?: string
  quiet = false
] {
  let scripts = (
    fd --exclude tests --extension nu "" .environments
    | lines
  )

  get-script $scripts $environment_or_recipe $recipe $quiet
}
