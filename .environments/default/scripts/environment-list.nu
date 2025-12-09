use environment-common.nu open-configuration-file

def append-aliases [environment: record<name: string aliases: list<string>>] {
  if ($environment.aliases | is-empty) {
    $environment.name
  } else {
    let aliases = (
      $environment.aliases
      | str join ", "
    )

    $environment.name
    | append $"[alias: ($aliases)]"
    | flatten
    | str join " "
  }
}

def highlight-text [
  line: string
  regex: string
  color: string
] {
  let alias = try {
    $line
    | rg --only-matching $regex
  }

  if ($alias | is-empty) {
    $line
  } else {
    let highlighted_text = $"(ansi $color)($alias)(ansi reset)"

    $line
    | str replace $alias $highlighted_text
  }
}

def highlight-alias []: string -> string {
  highlight-text $in '\[alias: [a-zA-Z, ]+\]' magenta
}

def highlight-feature []: string -> string {
  highlight-text $in '\+[a-zA-Z]+\b' cyan
}

export def main [
  options: record<
    aliases: bool,
    color: string,
    feature: string,
    features: bool
  >
  environment?: string
  path?: string
] {
  let aliases = $options.aliases
  let color = $options.color
  let feature = $options.feature
  let features = $options.features

  let environments = if ($environment | is-empty) {
    let environments = (get-available-environments)

    let text = if $features {
      let text = (
        $environments
        | each {
          |environment|

          let features_path = (get-environment-path $environment.name features)

          let features = if ($features_path | path exists) {
            ls --short-names $features_path
            | get name
            | each {$"+($in)"}
            | str join " • "
          } else {
            ""
          }

          let environment = if $aliases and (
            $environment.aliases
            | is-not-empty
          ) {
            append-aliases $environment
          } else {
            $environment.name
          }

          [$environment • $features "\n"]
          | str join " "
        }
        | to text
        | column -t -s •
        | lines
      )

      if (use-colors $color) {
        $text
        | each {highlight-feature}
      } else {
        $text
      }
    } else {
      if $aliases {
        $environments
        | each {append-aliases $in}
      } else {
        $environments.name
      }
    }

    if $aliases and (use-colors $color) {
      $text
      | each {highlight-alias}
      | to text
    } else {
      $text
    }
  } else if ($path | is-empty) {
    let environment = (parse-environments [$environment])

    if ($environment | is-empty) {
      return
    }

    let environment = ($environment | first | get name)

    let files = if ($feature | is-not-empty) {
      fd --hidden --type file "" (
        get-environment-path $environment $"features/($feature)"
      )
    } else {
      fd --hidden --type file "" (get-environment-path $environment)
    }

    let remove_path = if ($feature | is-empty) {
      $"src/($environment)/"
    } else {
      $"src/($environment)/features/($feature)/"
    }

    let files = (
      $files
      | lines
      | each {split row $remove_path | last}
    )

    if ($feature | is-not-empty) or $features {
      $files
    } else {
      $files
      | where {not ($in | str starts-with features)}
      | to text --no-newline
    }
  } else {
    let path = if ($feature | is-empty) {
     ""
    } else {
      $"features/($feature)"
    }

    ls --short-names (get-environment-path $environment $path)
    | get name
  }

  $environments
  | str join "\n"
}

export def active [
  options: record<
    aliases: bool,
    color: string,
    default: bool,
    features: bool,
    local: bool,
    user: bool
  >
] {
  let aliases = $options.aliases
  let color = $options.color
  let default = $options.default
  let features = $options.features
  let local = $options.local
  let user = $options.user

  if not (".environments/environments.toml" | path exists) {
    return
  }

  let environments = (open-configuration-file).environments
  let valid_environments = (get-available-environments --exclude-local)
  let all = [$default $local $user] | all {not $in}

  let local_environments = if $all or $user or not (
    [$all $default $user]
    | any {$in}
  ) {
    ls --short-names .environments
    | where type == dir
    | get name
    | where {$in not-in $valid_environments.name}
    | each {{name: $in}}
  } else {
    []
  }

  let environments = if $all {
    $environments
    | append $local_environments
    | append (get-default-environments)
  } else if $default {
    get-default-environments
  } else if $local {
    $local_environments
  } else {
    $environments
    | where {$in not-in $valid_environments.name}
  }

  let environments = if $features {
    $environments
    | each {
        |environment|

        let features = if features in ($environment | columns) {
          $environment.features
        } else {
          []
        }

        {
          name: $environment.name
          features: $features
        }
      }
  } else {
    $environments.name
  }

  let environments = if $aliases {
    $environments
    | each {
        |environment|

        let name = if ($environment | describe) == string {
          $environment
        } else {
          $environment.name
        }

        let aliases = (
          $valid_environments
          | where name == $name
          | get aliases
          | flatten
        )

        if ($aliases | is-not-empty) {
          let display = (
            append-aliases {
              name: $name
              aliases: $aliases
            }
          )

          if $features {
            {
              name: $display
              features: $environment.features
            }
          } else {
            $display
          }
        } else {
          $environment
        }
    }
  } else {
    $environments
  }

  let environments = if $features {
    mut unique_environments = []

    for environment in $environments {
      if $environment.name in $unique_environments.name {
        if (
          (
            $unique_environments
            | where name == $environment.name
            | first
          ).features
          | length
        ) == 0 {
          $unique_environments = (
            $unique_environments
            | where name != $environment.name
            | append $environment.name
          )
        }
       } else {
        $unique_environments = ($unique_environments | append $environment)
      }
    }

    let text = (
      $unique_environments
      | each {
          |environment|

          let features = (
            $environment.features
            | each {$"+($in)"}
            | str join " "
          )

          $environment.name
          | append •
          | append $features
          | str join " "
        }
    )

    if (use-colors $color) {
      $text
      | each {highlight-feature}
    } else {
      $text
    }
  } else {
    $environments
  }

  let text = (
    $environments
    | uniq
    | sort
    | to text
    | column -t -s •
  )

  if $aliases and (use-colors $color) {
    $text
    | lines
    | each {highlight-alias}
    | to text
  } else {
    $text
  }
}

export def default [] {
  (get-default-environments).name
  | to text --no-newline
}
