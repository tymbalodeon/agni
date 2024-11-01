# View help text
@help *recipe:
    ./scripts/help.nu {{ recipe }}

# View file annotated with version control information
[no-cd]
@annotate *filename:
    ./scripts/annotate.nu {{ filename }}

# Check flake and run pre-commit hooks
@check *args:
    ./scripts/check.nu {{ args }}

# List dependencies
@deps *args:
    ./scripts/deps.nu {{ args }}

# View the diff between environments
@diff-env *args:
    ./scripts/diff-env.nu {{ args }}

# Manage environments
@environment *args:
    ./scripts/environment.nu {{ args }}

# Search available `just` recipes
[no-cd]
[no-exit-message]
@find-recipe *search_term:
    ./scripts/find-recipe.nu {{ search_term }}

# View project history
[no-cd]
@history *args:
    ./scripts/history.nu {{ args }}

# Initialize direnv environment
@init *help:
    ./scripts/init.nu {{ help }}

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

# Update dependencies
@update-deps *help:
    ./scripts/update-deps.nu {{ help }}

# View the source code for a recipe
[no-cd]
@view-source *recipe:
    ./scripts/view-source.nu {{ recipe }}

mod agni "just/agni.just"

# Alias for `agni example`
@example *args:
    just agni example {{ args }}

mod python "just/python.just"

# Alias for `python add`
@add *args:
    just python add {{ args }}

# Alias for `python build`
@build *args:
    just python build {{ args }}

# Alias for `python clean`
@clean *args:
    just python clean {{ args }}

# Alias for `python coverage`
@coverage *args:
    just python coverage {{ args }}

# Alias for `python install`
@install *args:
    just python install {{ args }}

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
