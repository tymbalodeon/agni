[private]
@default:
    just help

# View full help text, or for a specific recipe
@help *args:
    .environments/default/scripts/help.nu {{ args }}

# Check flake
@check *args:
    .environments/default/scripts/check.nu {{ args }}

# Manage environments
@environment *args:
    .environments/default/scripts/environment.nu {{ args }}

alias env := environment

# Format files
@format *args:
    .environments/default/scripts/format.nu {{ args }}

# View project history
@history *args:
    .environments/default/scripts/history.nu {{ args }}

# View issues
@issue *args:
    .environments/default/scripts/issue.nu {{ args }}

# View README file
@readme *args:
    .environments/default/scripts/readme.nu  {{ args }}

# View or open recipes
@recipe *args:
    .environments/default/scripts/recipe.nu  {{ args }}

# View remote repository
@remote *args:
    .environments/default/scripts/remote.nu  {{ args }}

# Find/replace
@replace *args:
    .environments/default/scripts/replace.nu  {{ args }}

# View repository analytics
@stats *args:
    .environments/default/scripts/stats.nu {{ args }}

# List TODO-style comments
@todo *args:
    .environments/default/scripts/todo.nu {{ args }}

alias todos := todo

# Set helix theme
@theme *args:
    .environments/default/scripts/theme.nu {{ args }}

[private]
@py *args:
    just python {{ args }}

mod agni ".environments/agni/Justfile"
mod nix ".environments/nix/Justfile"
mod python ".environments/python/Justfile"

alias add := python::add
alias build := python::build
alias deps := python::dependencies
alias dependencies := python::dependencies
alias example := agni::example
alias pin := python::pin
alias profile := python::profile
alias rm := python::remove
alias remove := python::remove
alias run := python::run
alias test := python::test
alias up := python::update
alias update := python::update
