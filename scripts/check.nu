#!/usr/bin/env nu

export def get_pre_commit_hook_names [config: record<repos: list<any>>] {
    $config
    | get repos
    | get hooks
    | each {|hook| $hook | get id}
    | flatten
    | sort
    | to text
}

# Run `nix flake check`
def "main flake" [] {
    nix flake check
}

# List hook ids
def "main list" [] {
    get_pre_commit_hook_names (open .pre-commit-config.yaml)
}

# Update all pre-commit hooks
def "main update" [] {
    pre-commit run pre-commit-update --all-files
}

# Check flake and run pre-commit hooks
def main [
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
