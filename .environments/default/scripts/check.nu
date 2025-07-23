#!/usr/bin/env nu

# Clean pre-commit cache
def "main clean" [] {
  pre-commit clean
}

export alias clean = main clean

# Run `nix flake check`
def "main flake" [] {
  nix flake check
}

export def get-pre-commit-hook-names [config: record<repos: list<any>>] {
  let hooks = (
    $config
    | get repos.hooks
    | flatten
  )

  mut names = {}

  for hook in $hooks {
    let name = (
      if types in ($hook | columns) {
        $hook.types
      }
    )

    if ($name | is-not-empty) {
      $names = (
        $names
        | upsert $hook.id (
            if $hook.id in ($names | columns) {
              $names
              | get $hook.id
              | append $name
            } else {
              $name
            }
          )
      )
    } else {
      $names = ($names | upsert $hook.id $hook.id)
    }
  }

  $names
  | transpose id types
  | sort-by id
  | each {
      |hook|

      if $hook.id == $hook.types {
        $hook.id
      } else {
        $"($hook.id) [($hook.types | str join ', ')]"
      }
    }
}

# List hook ids
def "main list" [] {
  get-pre-commit-hook-names (open .pre-commit-config.yaml)
  | to text
}

# Run pre-commit hooks
def "main pre-commit" [hooks?: list<string>] {
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
  ^pre-commit run pre-commit-update --all-files
  yamlfmt .pre-commit-config.yaml
}

export alias update = main update

# Check flake and run pre-commit hooks
export def main [
  ...hooks: string # The hooks to run
  --update # Update all pre-commit hooks
] {
  if $update {
    main update
  }

  if ($hooks | is-empty) {
    main flake
  }

  main pre-commit $hooks
}
