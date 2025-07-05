#!/usr/bin/env nu

export def get-project-root [] {
  echo (git rev-parse --show-toplevel)
}

export def get-project-path [path: string] {
  get-project-root
  | path join $path
}

# Activate installed environments
def "main activate" [] {
  if (which direnv | is-empty) {
    print "Direnv (https://direnv.net/) is not installed."
    print "Please install and try again."

    exit 1
  }

  "use flake"
  | save --force (get-project-path .envrc)

  direnv allow
}

export def print-error [message: string] {
  print $"(ansi red_bold)error(ansi reset): ($message)"
}

export def print-warning [message: string] {
  print $"(ansi yellow_bold)warning(ansi reset): ($message)"
}

def get-features [
  environments: list<record>
  environment: record<name: string, features: list<string>>
] {
  if features in ($environments | columns) {
    $environments
    | where name == $environment.name
    | get features
    | flatten
  } else {
    []
  }
}

def get-environment-path [path?: string] {
  let environments_base = $env.ENVIRONMENTS

  if ($path | is-empty) {
    $environments_base
  } else {
    $"($environments_base)/($path)"
  }
}

def validate-environments [
  environments: list<record<name: string, features: list<string>>>
] {
  let valid_environments = (
    ls --short-names (get-environment-path)
    | where type == dir
    | get name
  )

  mut invalid_environments = []

  for environment in $environments {
    mut invalid_environment = {valid-name: true}

    if $environment.name not-in $valid_environments {
      $invalid_environment = (
        $invalid_environment
        | insert name $environment.name
        | update valid-name false
      )

      print-warning $"unrecognized environment: ($environment.name)"
    }

    mut invalid_features = []

    for feature in $environment.features {
      let features_directory = (
        get-environment-path $"($environment.name)/features"
      )

      if not ($features_directory | path exists) or $feature not-in (
        ls --short-names $features_directory
        | where type == dir
        | get name
      ) {
        $invalid_features = ($invalid_features | append $feature)

        print-warning (
          $"unrecognized feature for ($environment.name): ($feature)"
        )
      }
    }

    if ($invalid_features | is-not-empty) and (
      "name" not-in ($invalid_environment | columns)
    ) {
      $invalid_environment = (
        $invalid_environment
        | insert name $environment.name
      )
    }

    $invalid_environment = (
      $invalid_environment
      | insert features $invalid_features
    )

    $invalid_environments = (
      $invalid_environments
      | append $invalid_environment
    )
  }

  let invalid_environments = $invalid_environments

  $environments
  | where name not-in (
      $invalid_environments
      | where valid-name == false
      | get name
    )
  | each {
      |environment|

      $environment
      | update features (
          $environment.features
          | where {
              $in not-in (get-features $invalid_environments $environment)
            }
        )
    }
}

def parse-environments [environments: list<string>] {
  let environments = (
    $environments
    | str downcase
    | each {
        |environment|

        let parts = ($environment | split row "+")

        {
          name: ($parts | first)
          features: ($parts | drop nth 0)
        }
      }
    | sort-by name
  )

  mut $unique_environments = []

  for environment in $environments {
    if $environment.name in ($unique_environments.name) {
      let features = (
        get-features $unique_environments $environment
        | append $environment.features
        | uniq
        | sort
      )

      $unique_environments = (
        $unique_environments
        | where name != $environment.name
        | append {
            name: $environment.name
            features: $features
          }
      )
    } else {
      $unique_environments = ($unique_environments | append $environment)
    }
  }

  validate-environments $unique_environments
}

def convert-to-toml [environments: list<record>] {
  {
    environments: (
      $environments
      | each {
          |environment|

          if features in ($environment | columns) and (
            $environment.features
            | is-empty
          ) {
            {name: $environment.name}
          } else {
            $environment
          }
        }
      | sort-by name
    )
  }
  | to toml
}

# Add environments (and features) to the project
#
# Add features with <environment-name>[+<feature>...], e.g. "python+build"
export def "main add" [
  ...environments: string # Environments to add
] {
  let environments = (parse-environments $environments)
  mut environments = $environments

  if (".environments.toml" | path exists) {
    for environment in (open .environments.toml).environments {
      if ($environment.name in $environments.name) {
        let existing_environment = (
          $environments
          | where name == $environment.name
          | first
        )

        $environments = (
          $environments
          | where name != $environment.name
          | append {
              name: $environment.name

              features: (
                $existing_environment.features
                | append (
                    if features in ($environment | columns) {
                      $environment.features
                    } else {
                      []
                    }
                  )
                | uniq
                | sort
              )
            }
        )
      } else {
        $environments = ($environments | append $environment)
      }
    }
  }

  convert-to-toml $environments
  | save --force .environments.toml

  main activate
}

def get-available-environments [] {
  ls --short-names (get-environment-path)
  | where type == dir
  | get name
}

# List environments and files
export def "main list" [
  environment?: string # An environment whose files to lise
  path?: string # An environment path whose files to list
  --feature: string # List files for $feature only (requires $environment)
  --features # Show features
] {
  let environments = if ($environment | is-empty) {
    let environments = (get-available-environments)

    if $features {
      $environments
      | each {
        |environment|

        let features_path = (get-environment-path $"($environment)/features")

        let features = if ($features_path | path exists) {
          ls --short-names (get-environment-path $"($environment)/features")
          | get name
          | each {$"+($in)"}
          | str join " "
        } else {
          ""
        }

        [$environment $features "\n"]
        | str join " "
      }
      | to text
      | column -t
    } else {
      $environments
    }
  } else if ($path | is-empty) {
    let files = if ($feature | is-not-empty) {
      fd --hidden --type file "" (
        get-environment-path $"($environment)/features/($feature)"
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
      | each {|file| $file | split row $remove_path | last}
    )

    if ($feature | is-not-empty) or $features {
      $files
    } else {
      $files
      | where {not ($in | str starts-with features)}
      | to text --no-newline
    }
  } else {
    let base_path = if ($feature | is-empty) {
      $"($environment)"
    } else {
      $"($environment)/features/($feature)"
    }

    ls --short-names (get-environment-path $"($base_path)/($path)")
    | get name
  }

  $environments
  | str join "\n"
}

def get-local-environment-name [directory: string] {
  ls --short-names $directory
  | get name
  | path parse
  | get stem
}

def get-default-environments [] {
  [
    generic
    git
    just
    markdown
    nix
    toml
    yaml
  ]
  | each {
    {
      name: $in
      features: []
    }
  }
}

# List installed environments
def "main list active" [
  --all # Show all installed environments
  --default # Show only default installed environments
  --features # Show active features
  --local # Show local environments
  --user # Show only user installed environments [default]
] {
  if not (".environments.toml" | path exists) {
    return
  }

  let environments = (open .environments.toml).environments

  let local_environments = if $all or $user or not (
    [$all $default $user]
    | any {|item| $item}
  ) {
    get-local-environment-name just
    | append (
        get-local-environment-name nix
      )
    | uniq
    | where {$in not-in (get-available-environments)}
    | each {|environment| {name: $environment}}
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
    | where {$in not-in (get-available-environments)}
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

  let environments = if $features {
    mut unique_environments = []

    for environment in $environments {
      if $environment.name in $unique_environments.name {
        if (
          ($unique_environments | where name == $environment.name | first).features
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

    $unique_environments
    | each {
        |environment|

        let features = (
          $environment.features
          | each {$"+($in)"}
          | str join " "
        )

        $environment.name
        | append $features
        | str join " "
      }
  } else {
    $environments
  }

  $environments
  | uniq
  | sort
  | str join "\n"
}

def get-environment-files [
  environment: record<name: string, features: list<string>>
  filename: string
] {
  let feature_files = (
    $environment.features
    | each {
        (
          get-environment-path
            $"($environment.name)/features/($in)/($filename)"
        )
      }
  )

  if ($environment.features | is-empty) {
    get-environment-path $"($environment.name)/($filename)"
    | append $feature_files
  } else {
    $feature_files
  }
  | where {path exists}
  | each {open}
}

# Remove environments (and features) from the project
#
# Remove features with <environment-name>[+<feature>...], e.g. "python+build"
def "main remove" [
  ...environments: string # Environments to remove
  --force # Force removal even if environment(s) not currently active
] {
  if not $force and (
    not (".environments.toml" | path exists) or (
      $environments | is-empty
    )
  ) {
    return
  }

  let environments = (parse-environments $environments)

  if ($environments | is-empty) {
    return
  }

  let existing_environments = (open .environments.toml).environments

  let environments_to_remove = (
    $existing_environments
    | where {$in.name in $environments.name}
    | each {
        |environment|

        if features in ($environment | columns) {
          $environment
          | update features (
              get-features $existing_environments $environment
              | where {$in in (get-features $environments $environment)}
            )
        } else {
          $environment
          | insert features []
        }
      }
    | where {
        ($in.features | is-not-empty) or (
          $environments
          | where name == python
          | get features
          | flatten
          | is-empty
        )
      }
  )

  for environment in $environments_to_remove {
    if (".gitignore" | path exists) {
      let gitignore_lines = (
        get-environment-files $environment .gitignore
        | str join "\n"
        | lines
        | where {is-not-empty}
      )

      let updated_gitignore = (
        open .gitignore
        | lines
        | where {$in not-in $gitignore_lines}
        | to text
      )

      $updated_gitignore
      | save --force .gitignore
    }

    if (".helix/languages.toml" | path exists) {
      let languages = (open .helix/languages.toml)

      $languages
      | columns
      | each {
          |column|

          {
            $column: (
              $languages
            | get $column
            | where {
                let environment_languages = (
                  get-environment-files $environment languages.toml
                )

                $column not-in ($environment_languages | columns) or (
                  $in not-in ($environment_languages | get $column)
                )
              }
            )
          }
        }
      | into record
      | save --force .helix/languages.toml

      taplo format .helix/languages.toml out+err> /dev/null
    }

    for hook_file in (
      get-environment-path $"($environment.name)/hook.nu"
      | append (
          ls (get-environment-path $"($environment.name)/features")
          | get name
          | each {
              get-environment-path $"($environment.name)/features/($in)/hook.nu"
            }
        )
      | flatten
      | where {path exists}
    ) {
      nu $hook_file remove
    }

    if (".pre-commit-config.yaml" | path exists) {
      {
        repos: (
          open .pre-commit-config.yaml
          | get repos
          | where {
              $in not-in (
                get-environment-files $environment .pre-commit-config.yaml
              )
            }
        )
      }
      | save --force .pre-commit-config.yaml

      yamlfmt .pre-commit-config.yaml
    }
  }

  if ($environments_to_remove | is-not-empty) {
    let user_environments = (
      $existing_environments
      | where name not-in (
          $environments_to_remove
          | where {$in.features | is-empty}
          | get name
        )
      | each {
          |environment|

          if features in ($environment | columns) {
            $environment
            | update features (
                $environment.features
                | where {
                    $in not-in (
                      get-features $environments_to_remove $environment
                    )
                  }
              )
          } else {
            $environment
          }
        }
      | where {
          not (
            (
              ("features" not-in ($in | columns)) or (
                $in.features | is-empty
              )
            ) and ($in in (get-default-environments))
          )
        }
    )

    if ($user_environments | is-not-empty) {
      convert-to-toml $user_environments
      | save --force .environments.toml
    } else {
      rm .environments.toml
    }

    main activate
  }
}

def list-short-names [directory: string file?: string] {
  let search = if ($file | is-not-empty) {
    $file
  } else {
    ""
  }

  let files = (
    fd --hidden --type file $search $directory
    | lines
  )

  $files
  | wrap path
  | merge (
      $files
      | str replace $"($directory)/" ""
      | wrap name
    )
}

def select-file [files: table<path: string, name: string>] {
  let name = (
    $files.name
    | to text
    | fzf
  )

  $files
  | where name == $name
  | get path
  | first
}

# View the contents of an environment file
def "main source" [
  environment?: string # The environment whose file to view
  file?: string # The file to view
] {
  let environment = if ($environment | is-empty) {
    get-available-environments
    | to text
    | fzf
  } else {
    $environment
  }

  let environment_path = (get-environment-path $environment)

  if (ls $environment_path | is-empty) {
    return
  }

  let file = if ($file | is-empty) {
    select-file (list-short-names $environment_path)
  } else {
    let files = (list-short-names $environment_path $file)

    if ($files | length) > 1 {
      select-file $files
    } else {
      if ($files | is-empty) {
        return
      }

      $files
      | first
    }
  }

  bat $file
}

alias "main src" = main source

# Run tests
def "main test" [
  --suites: string # Regular expression to match against suite names (defaults to all)
  --tests: string # Regular expression to match against test names (defaults to all)
] {
  let command = "use nutest; nutest run-tests"

  let command = if ($suites | is-not-empty) {
    $"($command) --match-suites ($suites)"
  } else {
    $command
  }

  let command = if ($tests | is-not-empty) {
    $"($command) --match-suites ($tests)"
  } else {
    $command
  }

  nu --commands $command --include-path $env.NUTEST
}

# Update environment dependencies
def "main update" [
  --all # Update all flake inputs
] {
  let remote_url = (
    "https://raw.githubusercontent.com/tymbalodeon/environments/trunk"
  )

  let project_root = (git rev-parse --show-toplevel)

  http get $"($remote_url)/src/generic/flake.nix"
  | save --force $"($project_root)/flake.nix"

  if $all {
    nix flake update
  } else {
    nix flake update environments
  }

  main activate
}

def main [] {
  help main
}
