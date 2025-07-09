[private]
@default:
    just help

# View full help text, or for a specific recipe
@help *args:
    .environments/scripts/help.nu {{ args }}

# Check flake and run pre-commit hooks
@check *args:
    .environments/scripts/check.nu {{ args }}

# Manage environments
@environment *args:
    .environments/scripts/environment.nu {{ args }}

alias env := environment

# Search available `just` recipes
[no-exit-message]
@find-recipe *args:
    .environments/scripts/find-recipe.nu {{ args }}

alias find := find-recipe

# View project history
@history *args:
    .environments/scripts/history.nu {{ args }}

# View issues
@issue *args:
    .environments/scripts/issue.nu {{ args }}

# View remote repository
@remote *args:
    .environments/scripts/remote.nu  {{ args }}

# Find/replace
@replace *args:
    .environments/scripts/replace.nu  {{ args }}

# View repository analytics
@stats *args:
    .environments/scripts/stats.nu {{ args }}

# List TODO-style comments
@todo *args:
    .environments/scripts/todo.nu {{ args }}

alias todos := todo

# Set helix theme
@theme *args:
    .environments/scripts/theme.nu {{ args }}

# View the source code for a recipe
@view-source *args:
    .environments/scripts/view-source.nu {{ args }}

alias src := view-source

[private]
@py *args:
    just python {{ args }}

mod agni ".environments/just/agni.just"
mod python ".environments/just/python.just"

alias add := python::add
alias build := python::build
alias deps := python::dependencies
alias dependencies := python::dependencies
alias example := agni::example
alias pin := python::pin
alias profile := python::profile
alias remove := python::remove
alias run := python::run
alias shell := python::shell
alias test := python::test
alias update := python::update
