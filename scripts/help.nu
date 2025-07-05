#!/usr/bin/env nu

use color.nu use-colors
use find-script.nu

def append-main-aliases [
  help_text: string
  --color: string = "auto"
] {
  mut help_text = ($help_text | lines | enumerate)

  let aliases = (
    get-aliases
      true
      false
      false
      --color $color
    | where {$in.environment | is-not-empty}
  )

  for alias in $aliases {
    for line in $help_text {
      if ($line.item | str trim | str starts-with $alias.alias) {
        $help_text = (
          $help_text
          | update $line.index {
              let tag = "[main alias]"

              let tag = if (use-colors $color) {
                $"(ansi cyan)($tag)(ansi reset)"
              } else {
                $tag
              }

              {
                index: $line.index
                item: $"($line.item) ($tag)"
              }
            }
        )
      }
    }
  }

  $help_text.item
  | to text --no-newline
}

export def display-just-help [
  recipe?: string
  subcommands?: list<string>
  --color: string
  --environment: string
  --justfile: string
] {
  let args = [
    --color $color
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

    return (append-main-aliases (just ...$args) --color $color)
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
        return (just ...$args $recipe --quiet err> /dev/null)
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

def get-sortable-environment [
  alias: record<
    alias: string,
    environment: string,
    recipe: string
  >
] {
  if ($alias.environment == •) {
    null
  } else {
    $alias.environment
  }
}

def get-aliases [
  no_submodule_aliases: bool
  sort_by_environment: bool
  sort_by_recipe: bool
  --color: string
  --environment: string
  --justfile: string
] {
  let justfile = if ($justfile | is-empty) {
    "Justfile"
  } else {
    $justfile
  }

  let aliases = (
    open $justfile
    | lines
    | where {str starts-with  alias}
    | str replace "alias " ""
    | each {
        |alias|

        let parts = (
          $alias
          | split row ":="
          | str trim
        )

        let recipe_parts = ($parts | last | split row "::")

        {
          alias: ($parts | first)

          environment: (
            if ($recipe_parts | length) > 1 {
              ($recipe_parts | first)
            }
          )

          recipe: ($recipe_parts | last)
        }
      }
  )

  let aliases = if $no_submodule_aliases {
    $aliases
    | where {$in.environment == • or $in.alias == $in.recipe}
  } else {
    $aliases
  }

  if ($environment | is-not-empty) {
    $aliases
    | where {
        if $environment == default {
          $in.environment | is-empty
        } else {
          $in.environment =~ $environment
        }
      }
  } else {
    $aliases
  }
}

export def display-aliases [
  no_submodule_aliases: bool
  sort_by_environment: bool
  sort_by_recipe: bool
  --color: string
  --environment: string
  --justfile: string
] {
  let aliases = (
    get-aliases
    $no_submodule_aliases
    $sort_by_environment
    $sort_by_recipe
    --color $color
    --environment $environment
    --justfile $justfile
    | each {
        |alias|


        $alias
        | update environment (
            if ($alias.environment | is-empty) {
              "•"
            } else {
              $alias.environment
            }
          )
    }
  )

  let aliases = if ($environment | is-empty) and $sort_by_environment {
    $aliases
    | sort-by --custom {
        |a, b|

        (get-sortable-environment $a) < (get-sortable-environment $b)
      }
  } else if $sort_by_recipe {
    $aliases
    | sort-by recipe
  } else {
    $aliases
    | sort-by alias
  }

  let use_color = (use-colors $color)

  let no_environments = (
    $aliases.environment
    | all {$in == •}
  )

  print (
    $aliases
    | each {
        |alias|

        let alias_name = if $use_color {
          $"(ansi magenta_bold)($alias.alias)(ansi reset)"
        } else {
          $alias.alias
        }

        if $no_environments {
          $"($alias_name) => ($alias.recipe)"
        } else {
          let environment = if $use_color {
            $"(ansi cyan_bold)($alias.environment)(ansi reset)"
          } else {
            $alias.environment
          }

          $"($alias_name) => ($environment) ($alias.recipe)"
        }
      }
    | to text
    | column -t
    | str replace --all "•" " "
  )
}

# View module aliases
def "main aliases" [
  environment?: string # View aliases for $environment only
  --color = "auto" # When to use colored output
  --justfile: string # Which Justfile to use
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
      --environment $environment
      --justfile $justfile
  )
}

# View default recipe aliases
def "main aliases default" [
  --color = "auto" # When to use colored output
  --justfile: string # Which Justfile to use
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
      --environment default
      --justfile $justfile
  )
}


# View help text
def main [
  recipe?: string # View help text for recipe
  ...subcommands: string  # View help for a recipe subcommand
  --color = "always" # When to use colored output
] {
  display-just-help $recipe $subcommands --color $color
}
