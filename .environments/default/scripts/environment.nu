#!/usr/bin/env nu

use color.nu use-colors
use environment-activate.nu
use environment-add.nu
use environment-common.nu get-available-environments
use environment-common.nu get-default-environments
use environment-common.nu get-environment-path
use environment-common.nu get-features
use environment-common.nu parse-environments
use environment-edit.nu
use environment-help.nu
use environment-inputs.nu
use environment-list.nu
use environment-remove.nu
use environment-revision.nu
use environment-source.nu
use environment-test.nu
use environment-update.nu
use print.nu print-error
use print.nu print-warning

# Activate installed environments
def "main activate" [] {
  environment-activate
}

# Add features with <environment-name>[+<feature>...], e.g. "python+build"
def "main add" [
  ...environments: string # Environments to add
  --skip-activation # Update the configuration file, but skip activating the new environments
] {
  environment-add $environments $skip_activation
}

# Open .environments/environments.toml file
def "main edit" [] {
  environment-edit
}

# Open local helix configuration in $EDITOR [alias: `edit languages`]
def "main edit helix languages" [] {
  environment-edit helix languages
}

alias "main edit languages" = main edit helix languages

# Open local helix configuration in $EDITOR
def "main edit helix" [] {
  environment-edit helix
}

# Open local justfile configuration in $EDITOR
def "main edit justfile" [] {
  environment-edit justfile
}

# Open a local recipe in $EDITOR
def "main edit recipe" [recipe?: string] {
  environment-edit recipe $recipe
}

# Open local shell(s) in $EDITOR
def "main edit shell" [] {
  environment-edit shell
}

# Hide environments in help text
def "main hide" [...environments: string] {
  environment-help hide $environments
}

# Hide default environments in help text
def "main hide default" [] {
  environment-help hide default
}

# Hide help recipes help text
def "main hide help" [] {
  environment-help hide help
}

# List flake inputs
def "main inputs" [] {
  environment-inputs
}

# List environments and files
def "main list" [
  environment?: string # An environment whose files to lise
  path?: string # An environment path whose files to list
  --aliases # Show environment aliases
  --color = "auto" # When to use colored output {always|auto|never}
  --feature: string # List files for $feature only (requires $environment)
  --features # Show features
] {
  let feature = if ($feature | is-empty) {
    ""
  } else {
    $feature
  }

  environment-list {
    aliases: $aliases
    color: $color
    feature: $feature
    features: $features
  } $environment $path
}

# List active environments
def "main list active" [
  --aliases # Show environment aliases
  --color = "auto" # When to use colored output {always|auto|never}
  --default # Show only default active environments
  --features # Show active features
  --local # Show local environments
  --user # Show only user active environments
] {
  environment-list active {
    aliases: $aliases
    color: $color
    default: $default
    features: $features
    local: $local
    user: $user
  }
}

# List default environments
def "main list default" [] {
  environment-list default
}

# Remove environments (and features) from the project
#
# Remove features with <environment-name>[+<feature>...], e.g. "python+build"
def "main remove" [
  ...environments: string # Environments to remove
  --force # Force removal even if environment(s) not currently active
] {
  environment-remove $environments $force
}

alias "main rm" = main remove

# Show the current revision being used by `environments`
def "main revision" [] {
  environment-revision revision get
}

# List available revisions (branches and tags only)
def "main revision list" [] {
  environment-revision revision list
}

# Set the revision of `environments` to use
def "main revision set" [
  revision: string
  --source-flake="flake.nix"
] {
  environment-revision revision set $revision $source_flake
}

# Show environments in help text
def "main show" [...environments: string] {
  environment-help show $environments
}

# Show default environments in help text
def "main show default" [] {
  environment-help show default
}

# Show help recipes in help text
def "main show help" [] {
  environment-help show help
}

# View the contents of an environment file
def "main source" [
  environment?: string # The environment whose file to view
  file?: string # The file to view
] {
  environment-source $environment $file
}

alias "main src" = main source

# Run tests
def "main test" [
  --suites: string # Regular expression to match against suite names (defaults to all)
  --tests: string # Regular expression to match against test names (defaults to all)
] {
  environment-test $suites $tests
}

# Update environment inputs (see `environment inputs`)
def "main update" [
  ...inputs: string # The name of the input(s) to update (leave blank to update all)
] {
  environment-update $inputs
}

def main [] {
  help main
}
