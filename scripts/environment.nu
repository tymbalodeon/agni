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

def initialize [] {
  try {
    cp --update $"($env.ENVIRONMENTS)/generic/flake.nix" flake.nix
    chmod +w flake.nix
  }
}

export def print-error [message: string] {
  print $"(ansi red_bold)error(ansi reset): ($message)"
}

export def print-warning [message: string] {
  print $"(ansi yellow_bold)warning(ansi reset): ($message)"
}

def validate-environments [environments: list<string>] {
  let unrecognized_environments = (
    $environments
    | where {
        $in not-in (
          ls --short-names $env.ENVIRONMENTS
          | where type == dir
          | get name
        )
      }
  )

  if ($unrecognized_environments | is-not-empty) {
    print-error $"Urecognized environments:\n(
      $unrecognized_environments
      | each {|environment| $'- ($environment)'}
      | to text --no-newline
    )"

    exit 1
  }
}

# Add environments to the project
export def "main add" [
  ...environments: string # Environments to add
] {
  let environments = ($environments | str downcase)
  validate-environments $environments
  initialize

  let environments = (
    $environments
    | each {|environment| {name: $environment}}
  )

  let environments = if (".environments.toml" | path exists) {
    (open .environments.toml).environments
    | append $environments
  } else {
    $environments
  }

  let environments = (
    $environments
    | uniq
    | sort
  )

  {environments: $environments}
  | to toml
  | save --force .environments.toml

  main activate
}

def get-available-environments [] {
  ls --short-names $env.ENVIRONMENTS
  | where type == dir
  | get name
}

def validate-features [
  environment: string
  features: list<string>
] {
  if ($environment not-in (get-available-environments)) {
    print-error $"Urecognized environment: ($environment)"
    exit 1
  }

  mut unrecognized_features = []

  for feature in $features {
    if not (
      $"($env.ENVIRONMENTS)/($environment)/features/($feature)"
      | path exists
    ) {
      $unrecognized_features = ($unrecognized_features | append $feature)
    }
  }

  for feature in $unrecognized_features {
    print-error $"Unrecognized feature: ($feature)"
  }

  if ($unrecognized_features | is-not-empty) {
    exit 1
  }
}

# Add features to active environments
export def "main add features" [
  environment: string # Activate features for specified environment
  ...features: string # The features to activate
] {
  let environment = ($environment | str downcase)
  validate-features $environment $features
  initialize

  let environments = if (".environments.toml" | path exists) {
    (open .environments.toml).environments
  } else {
    []
  }

  let environments = if ($environment in $environments.name) {
    $environments
    | each {
        |existing_environment|

        let is_environment_to_update = (
          $existing_environment.name == $environment
        )

        let features = if features not-in ($existing_environment | columns) {
          if $is_environment_to_update {
            $features
          }
        } else {
          if $is_environment_to_update {
            $existing_environment.features
            | append $features
            | uniq
          } else {
            $existing_environment.features
          }
        }

        {name: $existing_environment.name features: $features}
      }
  } else {
    $environments
    | append {name: $environment.name features: $features}
  }
  | each {
      |environment|

      if ($environment.features | is-empty) {
        $environment
        | reject features
      } else {
        $environment
      }
    }

  {environments: $environments}
  | to toml
  | save --force .environments.toml

  main activate
}

def list-environments [
  features: bool
  environment?: string
  path?: string
] {
  if ($environment | is-empty) {
    get-available-environments
  } else if ($path | is-empty) {
    fd --type file "" $"($env.ENVIRONMENTS)/($environment)"
    | lines
    | each {|file| $file | split row $"src/($environment)/" | last}
  } else {
    ls --short-names $"($env.ENVIRONMENTS)/($environment)/($path)"
    | get name
  }
}

# List environments and files
export def "main list" [
  environment?: string # An environment whose files to lise
  path?: string # An environment path whose files to list
  --features # Show features
] {
  list-environments $features $environment $path
  | str join "\n"
}

def get-local-environment-name [directory: string] {
  ls --short-names $directory
  | get name
  | path parse
  | get stem
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
    | where {$in not-in (list-environments false)}
    | each {|environment| {name: $environment}}
  } else {
    []
  }

  let default_environments = (
    [
      generic
      git
      nix
      toml
      yaml
    ]
    | each {|environment| {name: $environment}}
  )

  let environments = if $all {
    $environments
    | append $local_environments
    | append $default_environments
  } else if $default {
    $default_environments
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

        let features = if features in ($environment| columns) {
          $environment.features
        } else {
          []
        }

        {name: $environment.name features: $features}
      }
  } else {
    $environments.name
  }

  let environments = if $features {
    mut unique_environments = []

    for thing in $environments {
      if $thing.name in $unique_environments.name {
        if (
          ($unique_environments | where name == $thing.name | first).features
          | length
        ) == 0 {
          $unique_environments = (($unique_environments | where name != $thing.name) | append $thing.name)
        }
       } else {
        $unique_environments = ($unique_environments | append $thing)
      }
    }

    $unique_environments
    | each {
        |environment|

        let features = (
          $environment.features
          | each {|feature| $"+($feature)"}
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

# Remove environments from the project
def "main remove" [
  ...environments: string # Environments to remove
] {
  let environments = ($environments | str downcase)
  validate-environments $environments
  initialize

  let environments = (
    $environments
    | each {|environment| {name: $environment}}
  )

  if (".environments.toml" | path exists) {
    let environments = (
      (open .environments.toml).environments
      | where name not-in $environments.name
    )

    {environments: $environments}
    | to toml
    | save --force .environments.toml

    main activate
  }
}

# Remove environments from the project
def "main remove features" [
  environment: string # Remove features for specified environment
  ...features: string # The features to remove
] {
  let environment = ($environment | str downcase)
  validate-features $environment $features
  initialize

  if (".environments.toml" | path exists) {
    let existing_environments = (open .environments.toml).environments

    let environments = (
      $existing_environments
      | each {
          |environment|

          {
            name: $environment.name

            features: (
              if features in ($environment | columns) {
                $environment.features
                | where {$in not-in $features}
              }
            )
          }
        }
      | each {
          |environment|

          if ($environment.features | is-empty) {
            $environment
            | reject features
          } else {
            $environment
          }
        }
    )

    {environments: $environments}
    | to toml
    | save --force .environments.toml

    main activate
  }
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

  let environment_path = $"($env.ENVIRONMENTS)/($environment)"

  if (ls $environment_path | is-empty) {
    return
  }

  let file = if ($file | is-empty) {
    let files = (
      fd --type file "" $environment_path
      | lines
      | wrap path
      | merge (
          fd --type file "" $environment_path
          | lines
          | str replace $"($environment_path)/" ""
          | wrap name
        )
    )

    let name = (
      $files.name
      | to text
      | fzf
    )

    $files
    | where name == $name
    | get path
    | first
  } else {
    let files = (
      fd $file $environment_path
      | lines
    )

    if ($files | length) > 1 {
      $files
      | fzf
    } else {
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
