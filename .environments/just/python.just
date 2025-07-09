set working-directory := "../.."

# View help text
@help *args:
    .environments/scripts/python/help.nu {{ args }}

# Add dependencies
@add *args:
    .environments/scripts/python/add.nu {{ args }}

# Show application dependencies
@dependencies *args:
    .environments/scripts/python/dependencies.nu {{ args }}

alias deps := dependencies

# Manage python version
@pin *args:
    .environments/scripts/python/pin.nu {{ args }}

# Profile a command and view results
@profile *args:
    .environments/scripts/python/profile.nu {{ args }}

# Remove dependencies
@remove *args:
    .environments/scripts/python/remove.nu {{ args }}

# Run the application
@run *args:
    .environments/scripts/python/run.nu {{ args }}

# Open an interactive python shell
@shell *args:
    .environments/scripts/python/shell.nu {{ args }}

# Run tests
@test *args:
    .environments/scripts/python/test.nu {{ args }}

# Update dependencies
@update *args:
    .environments/scripts/python/update.nu {{ args }}

# Build and install the application
@build *args:
    .environments/scripts/python/build.nu {{ args }}
