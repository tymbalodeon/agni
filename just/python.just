@_help:
    just --list --justfile python.just

# Add dependencies
@add *args:
    ../scripts/python/add.nu {{ args }}

# Build and install the application
@build *help:
    ../scripts/python/build.nu {{ help }}

# Show application dependencies
@dependencies *args:
    ../scripts/python/dependencies.nu {{ args }}

alias deps := dependencies

# Manage python version
@pin *version:
    ../scripts/python/pin.nu {{ version }}

# Profile a command and view results
@profile *args:
    ../scripts/python/profile.nu {{ args }}

# Remove dependencies
@remove *dependencies:
    ../scripts/python/remove.nu {{ dependencies }}

# Run the application
[no-cd]
@run *args:
    ./scripts/python/run.nu {{ args }}

# Open an interactive python shell
@shell *help:
    ../scripts/python/shell.nu {{ help }}

# Run tests
@test *help:
    ../scripts/python/test.nu {{ help }}

# Update dependencies
@update *prod:
    ../scripts/python/update.nu {{ prod }}
