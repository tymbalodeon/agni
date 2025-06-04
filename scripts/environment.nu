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
    if not (".environments.toml" | path exists) {
      cp $"($env.ENVIRONMENTS)/generic/.environments.toml" .
    }

    cp $"($env.ENVIRONMENTS)/generic/flake.nix" .
    chmod +w flake.nix
  }
}

# Add environments to the project
export def "main add" [
  ...environments: string # Environments to add
] {
  initialize

  # TODO: add error message if any environments are invalid?
  let environments = (
    $environments
    | where {
        $in in (
          ls --short-names $env.ENVIRONMENTS
          | where type == dir
          | get name
        )
      }
  )

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

# List environments and files
def "main list" [
  environment?: string # An environment whose files to lise
  path?: string # An environment path whose files to list
] {
  if ($environment | is-empty) {
    ls --short-names $env.ENVIRONMENTS
    | where type == dir
    | get name
    | str join "\n"
  } else if ($path | is-empty) {
    fd --type file "" $"($env.ENVIRONMENTS)/($environment)"
    | lines
    | each {|file| $file | split row $"src/($environment)/" | last}
    | str join "\n"
  } else {
    ls --short-names $"($env.ENVIRONMENTS)/($environment)/($path)"
    | get name
    | str join "\n"
  }
}

# List installed environments
def "main list installed" [
  --all # Show all installed environments
  --default # Show only default installed environments
  --user # Show only user installed environments [default]
] {
  # TODO: show local environments
  let default_environments = (
    open $"($env.ENVIRONMENTS)/generic/.environments.toml"
  ).environments

  let environments = (open .environments.toml).environments

  let environments = if $all {
    $environments
  } else if $default {
    $environments
    | where {$in in $default_environments}
  } else {
    $environments
    | where {$in not-in $default_environments}
  }

  $environments
  | str join "\n"
}

# Remove environments from the project
def "main remove" [
  ...environments: string # Environments to remove
] {
  initialize

  open .environments.toml
  | update environments (
      (open .environments.toml).environments
      | where {$in not-in $environments}
    )
  | save --force .environments.toml

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
def "main update" [] {
  let remote_url = (
    "https://raw.githubusercontent.com/tymbalodeon/environments/trunk"
  )

  let project_root = (git rev-parse --show-toplevel)

  http get $"($remote_url)/src/generic/flake.nix"
  | save --force $"($project_root)/flake.nix"

  nix flake update
  main activate
}

def main [] {
  help main
}
