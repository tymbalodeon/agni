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

def copy-environments-toml [] {
  cp $"($env.ENVIRONMENTS)/generic/.environments.toml" .
  chmod +w .environments.toml
}

def initialize [] {
  try {
    if not (".environments.toml" | path exists) {
      copy-environments-toml
    }

    cp $"($env.ENVIRONMENTS)/generic/flake.nix" .
    chmod +w flake.nix
  }
}

# Add environments to the project
export def "main add" [
  ...environments: string # Environments to add
] {
  # TODO: handle features (what to do about removing features?)
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
    print $"Urecognized environments:\n(
      $unrecognized_environments
      | each {|environment| $'- ($environment)'}
      | to text --no-newline
    )"

    exit 1
  }

  initialize

  open .environments.toml
  | update environments (
      (open .environments.toml).environments
      | append $environments
      | uniq
      | sort
    )
  | save --force .environments.toml

  main activate
}

# TODO: add features
def list-environments [environment?: string path?: string] {
  if ($environment | is-empty) {
    ls --short-names $env.ENVIRONMENTS
    | where type == dir
    | get name
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
] {
  list-environments $environment $path
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
  --user # Show only user installed environments [default]
] {
  # TODO: display features
  let default_environments = (
    open $"($env.ENVIRONMENTS)/generic/.environments.toml"
  ).environments.name

  let environments = (open .environments.toml).environments.name

  let local_environments = if $all or $user or not (
    [$all $default $user]
    | any {|item| $item}
  ) {
    get-local-environment-name just
    | append (
        get-local-environment-name nix
      )
    | uniq
    | where {$in not-in (list-environments)}
    | each {|environment| $"($environment) \(local\)"}
  } else {
    []
  }

  let environments = if $all {
    $environments
    | append $local_environments
  } else if $default {
    $environments
    | where {$in in $default_environments}
  } else {
    $environments
    | where {$in not-in $default_environments}
    | append $local_environments
  }

  $environments
  | sort
  | str join "\n"
}

# Remove environments from the project
def "main remove" [
  ...environments: string # Environments to remove
] {
  let recognized_environments = if ($environments | is-not-empty) {
    $environments
    | where {
        $in in (
          ls --short-names $env.ENVIRONMENTS
          | where type == dir
          | get name
        )
      }
  } else {
    []
  }

  if ($environments | is-not-empty) and ($recognized_environments | is-empty) {
    return
  }

  initialize

  if ($environments | is-empty) {
    copy-environments-toml
  } else {
    open .environments.toml
    | update environments (
        (open .environments.toml).environments
        | where {$in not-in $environments}
      )
    | save --force .environments.toml
  }

  main activate
}

# View the contents of an environment file
def "main source" [
  environment: string # The environment whose file to view
  file: string # The file to view
] {
  # TODO: make env and file optional and use fzf in those cases
  let files = (^fd $file $"($env.ENVIRONMENTS)/($environment)")

  if ($files | is-empty) {
    return
  }

  let file = if ($files | lines | length) > 1 {
    $files
    | fzf
  } else {
    $files
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
