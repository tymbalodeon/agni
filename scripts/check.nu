#!/usr/bin/env nu

use environment.nu get-project-root

# Clean pre-commit cache
def "main clean" [] {
  cd (get-project-root)
  pre-commit clean
}

# Run `nix flake check`
def "main flake" [] {
  cd (get-project-root)
  nix flake check --all-systems
}

export def get-pre-commit-hook-names [config: record<repos: list<any>>] {
  $config
  | get repos.hooks
  | each {get id}
  | flatten
  | append flake
  | sort
  | to text --no-newline
}

# List hook ids
def "main list" [] {
  get-pre-commit-hook-names (open .pre-commit-config.yaml)
}

# Run pre-commit hooks
def "main pre-commit" [hooks: list<string>] {
  if ($hooks | is-empty) {
    pre-commit run --all-files
  } else {
    for hook in $hooks {
      pre-commit run $hook --all-files
    }
  }
}

# Update all pre-commit hooks
def "main update" [] {
  pre-commit run pre-commit-update --all-files
  yamlfmt .pre-commit-config.yaml
}

# Check flake and run pre-commit hooks
export def main [
  ...hooks: string # The hooks to run
  --update # Update all pre-commit hooks
] {
  if $update {
    main update
  }

  main flake
  main pre-commit $hooks
}
