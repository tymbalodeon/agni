#!/usr/bin/env nu

use environment-common.nu get-aliases-files
use environment-common.nu get-default-environments
use environment-common.nu open-configuration-file
use environment-common.nu parse-environments
use print.nu print-warning
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
      let words = (
        $line.item
        | ansi strip
        | split row " "
        | where {is-not-empty}
      )

      if ($words | is-not-empty) and ($words | first) == $alias.alias {
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

  let environment_aliases = (
    fd Justfile .environments
    | lines
    | each {
        |file|

        let environment = (
          $file
          | path dirname
          | path basename
        )

        try {
          get-aliases-files $environment
          | each {
              {
                alias: $in
                environment: $environment
              }
            }
        } catch {
            {
              alias: null
              environment: $environment
            }
        }
      }
    | flatten
  )

  let environment_aliases = (
    $environment_aliases
    | where {$in.alias | is-not-empty}
  )

  let aliases = (
    $aliases
    | append $environment_aliases
  )

  let duplicates = (
    $aliases
    | where {
        |alias|

        (
          $aliases.alias
          | where {$in == $alias.alias}
          | length
        ) > 1
      }
    | get alias
    | uniq
  )

  for duplicate in $duplicates {
    print-warning $"duplicate alias \"($duplicate)\""
  }

  let lines = (
    $help_text.item
    | each {
        |line|

        mut matching_environment = null

        for environment in $environment_aliases.environment {
          if (
            $line
            | str trim
            | str starts-with $"($environment):"
          ) {
            $matching_environment = $environment
            break
          }
        }

        if ($matching_environment | is-not-empty) {
          let aliases = (
            $environment_aliases
            | where environment == $matching_environment
            | get alias
            | str join ", "
          )

          let alias = $"[alias: ($aliases)]"

          let alias = if (use-colors $color) {
            $"(ansi magenta)($alias)(ansi reset)"
          }

          $"($line) ($alias)"
        } else {
          $line
        }
      }
  )

  $lines
  | to text --no-newline
}

def main-help [all: bool environment?: string --color: string] {

  let environments = if not $all and (
    ".environments/environments.toml"
    | path exists
  ) {
    open .environments/environments.toml
  }

  let hide_help = ($environments | is-not-empty) and (
    "hide_help" in ($environments | columns)
  ) and (
    $environments.hide_help
  )

  let args = [
      --color $color
      --list
    ]

  let args = if not $hide_help {
    $args
    | append [
      --list-heading $"(
        ansi default_bold
      )use `just help` for more options \(see `just help --help`\)(
        ansi reset
      )\n\nAvailable recipes:\n"
    ]
  } else {
    $args
  }

  let args = (
    $args
    | append (
        if ($environment | is-not-empty) {
          [--justfile $".environments/($environment)/Justfile"]
        } else {
          [--list-submodules]
        }
      )
  )

  let hidden_submodules = if ($environments | is-not-empty) and (
    "environemnts" in ($environments | columns)
  ) {
    $environments
    | get environments
    | where {"hide" in ($in | columns) and $in.hide}
    | get name
  }

  let hidden_submodules = if (
    $environments
    | is-not-empty
  ) and hide_default in ($environments | columns) and (
    $environments.hide_default
  ) {
    $hidden_submodules
    | append (get-default-environments).name
  } else {
    $hidden_submodules
  }

  let text = (just ...$args | lines | enumerate)

  let text = if ($hidden_submodules | is-empty) {
    $text.item
    | to text
  } else {
    mut lines_to_remove = []
    mut remove_line = false

    for line in $text {
      if ($line.item | str starts-with "    ") and (
        $line.item
        | find --regex "    [a-z-]+:"
        | is-not-empty
      ) {
        if (
          $line.item
          | find --regex $"\(($hidden_submodules | str join '|')\):"
          | is-not-empty
        ) {
          $remove_line = true
        } else {
          $remove_line = false
        }
      }

      if $remove_line {
        $lines_to_remove = ($lines_to_remove | append $line.index)
      }
    }

    $text
    | where {$in.index not-in $lines_to_remove}
    | get item
    | to text --no-newline
  }

  let text = if $hide_help {
    $text
    | lines
    | where {$in | ansi strip | find --regex ' +help \*args' | is-empty}
    | str join "\n"
  } else {
    $text
  }

  if not $all and (
    (get-settings-bool hide_default) or (get-settings-bool hide_help)
  ) {
    print $"(
      ansi default_bold
    )use `just help --all` for more recipes(ansi reset)\n"
  }

  append-main-aliases $text --color $color
}

def get-help-text [
  all: bool
  environment_or_recipe?: string
  recipe_or_subcommand?: string
  subcommands?: list<string>
  --color: string
] {
  let summary = (just --summary | split row " ")

  let environments = (
    $summary
    | where {"::" in $in}
    | each {split row :: | first}
    | uniq
  )

  let default_recipes = (
    $summary
    | where {"::" not-in $in}
  )

  let parsed_environments = try {
    if ($environment_or_recipe | is-not-empty) {
      parse-environments [$environment_or_recipe] true
    } else {
      []
    }
  } catch {
    []
  }

  let environment_or_recipe = if ($parsed_environments | is-not-empty) {
    $parsed_environments
    | first
    | get name
  } else {
    $environment_or_recipe
  }

  let environment = if ($environment_or_recipe in $environments) {
    $environment_or_recipe
  } else if ($environment_or_recipe | is-empty) {
    return (main-help $all --color $color)
  } else {
    if $environment_or_recipe == default and (
      $recipe_or_subcommand
      | is-empty
    ) {
      return (
        just --list --color $color
        | lines
        | where {not ($in | str ends-with ...)}
        | to text --no-newline
      )
    }
  }

  let environment_or_recipe = if $environment_or_recipe == default {
    $recipe_or_subcommand
  } else {
    $environment_or_recipe
  }

  let recipe_or_script = if ($recipe_or_subcommand | is-not-empty) and (
    $environment
    | is-not-empty
  ) {
    let environment_recipes = (
      $summary
      | where {str starts-with $environment}
      | each {split row :: | last}
    )

    if ($recipe_or_subcommand in $environment_recipes) {
      $recipe_or_subcommand
    } else {
      let aliases = (get-aliases false false false --environment $environment)

      if ($recipe_or_subcommand in $aliases.alias) {
        $aliases
        | where alias == $recipe_or_subcommand
        | first
        | get recipe
      } else {
        return
      }
    }
  } else if ($recipe_or_subcommand | is-empty) and (
    $environment_or_recipe in $default_recipes
  ) {
    $environment_or_recipe
  } else if ($environment_or_recipe | is-not-empty) {
    if ($environment_or_recipe != $environment) {
      let aliases = (get-aliases true false false --environment default)

      if ($environment_or_recipe in $aliases.alias) {
        $aliases
        | where alias == $environment_or_recipe
        | first
        | get recipe
      } else {
        let matching_scripts = (
          $summary
          | where {$environment_or_recipe in $in}
        )

        if ($matching_scripts | is-not-empty) {
          let matching_scripts = (
            $matching_scripts
            | each {
                |recipe|


                let parts = (
                  $recipe
                  | split row ::
                )

                find-script ($parts | first) ($parts | last)
              }
          )

          if ($matching_scripts | length) > 1 {
            $matching_scripts
            | to text
            | fzf --preview "bat --force-colorization {}"
          } else {
            $matching_scripts
            | first
          }
        } else {
          return
        }
      }
    }
  } else if ($environments | is-not-empty) {
    return (main-help $all $environment --color $color)
  }

  if ($environment | is-not-empty) and (
    $recipe_or_script
    | is-empty
  ) {
    return (
      append-main-aliases (
        just
          --color $color
          --justfile $".environments/($environment)/Justfile"
          --list
      ) --color $color
    )
  }

  let script = if ($recipe_or_script | is-not-empty) and (
    $recipe_or_script
    | path exists
  ) {
    $recipe_or_script
  } else {
    let environment = if ($environment | is-empty) {
      "default"
    } else {
      $environment
    }

    find-script $environment $recipe_or_script
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

export def display-just-help [
  environment_or_recipe?: string
  recipe_or_subcommand?: string
  subcommands?: list<string>
  all = true
  --color: string
  --paging = "auto"
] {
  let help_text = (
    get-help-text
      $all
      $environment_or_recipe
      $recipe_or_subcommand
      $subcommands
      --color $color
  )

  match $paging {
    "never" => $help_text,
    _ => ($help_text | bat)
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
    | where {($in.environment | is-empty) or $in.alias == $in.recipe}
  } else {
    $aliases
  }

  if ($environment | is-not-empty) {
    $aliases
    | where {
        if $environment == default {
          $in.environment
          | is-empty
        } else {
          ($in.environment | is-not-empty) and $in.environment =~ $environment
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
  --color = "auto" # When to use colored output {always|auto|never}
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
  --color = "auto" # When to use colored output {always|auto|never}
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
def "main default" [
  recipe_or_subcommand?: string # View help text for recipe
  ...subcommands: string  # View help for a recipe subcommand
  --all # Display all help text, including hidden environments and recipes
  --color = "always" # When to use colored output {always|auto|never}
] {
  (
    display-just-help
      default
      $recipe_or_subcommand
      $subcommands
      $all
      --color $color
  )
}

def get-settings-bool [column: string] {
  let settings = (open-configuration-file)

  try {
    $settings
    | get $column
  } catch {
    false
  }
}

# View help text
def main [
  environment_or_recipe?: string # View help text for recipe
  recipe_or_subcommand?: string # View help text for recipe
  ...subcommands: string  # View help for a recipe subcommand
  --all # Display all help text, including hidden environments and recipes
  --color = "always" # When to use colored output {always|auto|never}
  --paging = "auto" # When to use pager {always|auto|never}
] {
  (
    display-just-help
      $environment_or_recipe
      $recipe_or_subcommand
      $subcommands
      $all
      --color $color
      --paging $paging
  )
}
