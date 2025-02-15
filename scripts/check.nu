#!/usr/bin/env nu

export def get-pre-commit-hook-names [config: record<repos: list<any>>] {
  $config
  | get repos.hooks
  | each {get id}
  | flatten
  | sort
  | to text
}

# Run `nix flake check`
def --wrapped "main flake" [...$args] {
  nix flake check ...$args
}

# List hook ids
def "main list" [] {
  get-pre-commit-hook-names (open .pre-commit-config.yaml)
}

# Update all pre-commit hooks
def "main update" [] {
  pre-commit run pre-commit-update --all-files
}

# Check flake and run pre-commit hooks
export def main [
  ...hooks: string # The hooks to run
  --all # Run all checks
  --update # Update all pre-commit hooks
] {
  if $all {
    main flake
  }

  if $update {
    main update
  }

  if $all or ($hooks | is-empty) {
    pre-commit run --all-files
  } else {
    for hook in $hooks {
      pre-commit run $hook --all-files
    }
  }
}
