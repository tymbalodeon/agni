set working-directory := ".."

# View help text
@help *args:
    ./scripts/python/help.nu {{ args }}

# Add dependencies
@add *args:
    ./scripts/python/add.nu {{ args }}

# Show application dependencies
@dependencies *args:
    ./scripts/python/dependencies.nu {{ args }}

alias deps := dependencies

# Manage python version
@pin *args:
    ./scripts/python/pin.nu {{ args }}

# Profile a command and view results
@profile *args:
    ./scripts/python/profile.nu {{ args }}

# Remove dependencies
@remove *args:
    ./scripts/python/remove.nu {{ args }}

# Run the application
@run *args:
    ./scripts/python/run.nu {{ args }}

# Open an interactive python shell
@shell *args:
    ./scripts/python/shell.nu {{ args }}

# Run tests
@test *args:
    ./scripts/python/test.nu {{ args }}

# Update dependencies
@update *args:
    ./scripts/python/update.nu {{ args }}

# Build and install the application
@build *args:
    ./scripts/python/build.nu {{ args }}
