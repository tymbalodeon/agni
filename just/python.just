# View help text
@help *recipe:
    ../scripts/python/help.nu {{ recipe }}

# Add dependencies
@add *args:
    ../scripts/python/add.nu {{ args }}

# Build and install the application
@build *help:
    ../scripts/python/build.nu {{ help }}

# Remove generated files
@clean *args:
    ../scripts/python/clean.nu {{ args }}

# Run coverage report
@coverage *fail_under:
    ../scripts/python/coverage.nu {{ fail_under }}

# Show application dependencies
@deps *args:
    ../scripts/python/deps.nu {{ args }}

# Install dependencies
@install *args:
    ../scripts/python/install.nu {{ args }}

# Profile a command and view results
@profile *args:
    ../scripts/python/profile.nu {{ args }}

# Release a new version of the application
@release *args:
    ../scripts/python/release.nu {{ args }}

# Remove dependencies
@remove *dependencies:
    ../scripts/python/remove.nu {{ dependencies }}

# Run the application
@run *args:
    ../scripts/python/run.nu {{ args }}

# Open an interactive python shell
@shell *help:
    ../scripts/python/shell.nu {{ help }}

# Run tests
@test *help:
    ../scripts/python/test.nu {{ help }}

# Update dependencies
@update *prod:
    ../scripts/python/update.nu {{ prod }}
