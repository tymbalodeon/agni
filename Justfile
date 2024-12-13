# View help text
@help *recipe:
    ./scripts/help.nu {{ recipe }}

# Check flake and run pre-commit hooks
@check *args:
    ./scripts/check.nu {{ args }}

# List dependencies (alias: `deps`)
@dependencies *args:
    ./scripts/dependencies.nu {{ args }}

alias deps := dependencies

# Manage environments
@environment *args:
    ./scripts/environment.nu {{ args }}

alias env := environment

# Search available `just` recipes
[no-cd]
[no-exit-message]
@find-recipe *search_term:
    ./scripts/find-recipe.nu {{ search_term }}

alias find := find-recipe

# View project history
[no-cd]
@history *args:
    ./scripts/history.nu {{ args }}

# View issues
@issue *args:
    ./scripts/issue.nu {{ args }}

# Create a new release
@release *preview:
    ./scripts/release.nu  {{ preview }}

# View remote repository
@remote *web:
    ./scripts/remote.nu  {{ web }}

# View repository analytics
@stats *help:
    ./scripts/stats.nu {{ help }}

# Run tests
@test *args:
    ./scripts/test.nu {{ args }}

# View the source code for a recipe
[no-cd]
@view-source *recipe:
    ./scripts/view-source.nu {{ recipe }}

alias src := view-source

mod agni "just/agni.just"

# Alias for `agni example`
@example *args:
    just agni example {{ args }}

mod python "just/python.just"

# Alias for `python _help`
@_help *args:
    just python _help {{ args }}

# Alias for `python add`
@add *args:
    just python add {{ args }}

# Alias for `python build`
@build *args:
    just python build {{ args }}

# Alias for `python profile`
@profile *args:
    just python profile {{ args }}

# Alias for `python remove`
@remove *args:
    just python remove {{ args }}

# Alias for `python run`
@run *args:
    just python run {{ args }}

# Alias for `python shell`
@shell *args:
    just python shell {{ args }}

# Alias for `python update`
@update *args:
    just python update {{ args }}
