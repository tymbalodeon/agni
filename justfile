@_help:
    just --list

# Run pre-commit checks.
check:
    poetry run pre-commit run -a

@_get_pyproject_value value:
    echo $(awk -F '[ =\"]+' '$1 == "{{value}}" { print $2 }' pyproject.toml)

# Try a command using the current state of the files without building.
try *args:
    #!/usr/bin/env zsh
    command=$(just _get_pyproject_value "name")
    poetry run $command {{args}}
