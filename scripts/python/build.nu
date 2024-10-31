#!/usr/bin/env nu

use ./command.nu
use ./version.nu

# Build and install the application
def main [] {
    for extension in [
        "-py3-none-any.whl"
        ".tar.gz"
    ] {
        checkexec
            $"dist/(command)-(version)($extension)"
            $"(command)/**/*.py"
            -- pdm build
    }
}
