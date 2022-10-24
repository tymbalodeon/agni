command := ```
cat pyproject.toml | grep name | awk 'BEGIN { FS = "\"" } ; { print $2 }'
```

@_help:
    just --list

# Run pre-commit checks.
check:
    poetry run pre-commit run -a

# Try a command using the current state of the files without building.
try *args:
    poetry run {{command}} {{args}}
