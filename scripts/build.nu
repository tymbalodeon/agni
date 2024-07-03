#!/usr/bin/env nu

# Build and install the application
export def main [] {
    let application_command = {{ application-command }}
    let version = just _get-application-version
    let file_name = $"($application_command)-($version)"

    let extensions = [
        "-py3-none-any.whl"
        ".tar.gz"
    ]

    let dependencies = $"($application_command)/**/*.py"

    for extension in $extensions {
        checkexec $"dist/($file_name)($extension)" $dependencies -- pdm build
    }
}
