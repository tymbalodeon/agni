#!/usr/bin/env nu

use ./command.nu
use ./version.nu

def not-installed [command: string] {
  (command -v $command | is-empty)
}

def module-not-installed [command: string] {
  return (
    pdm run python -m $command --help err> /dev/null
    | complete
    | get exit_code
    | into bool
  )
}

# Install dependencies
def install [
    --app # (Build and) install the application
    --dry-run # Display dependencies without installing
    --minimal # Install only dependencies necessary for other commands
    --prod # Install production dependencies only
] {
    if $dry_run {
        if $app or $prod {
            just dependencies --prod
        } else {
            just dependencies
        }

        exit
    }

    if not $prod {
        if (module-not-installed pip) {
            pdm run python -m ensurepip --upgrade --default-pip
        }

        if (module-not-installed pipx) {
            pdm run python -m pip install --upgrade pip pipx;
            pdm run python -m pipx ensurepath
        }

        if (not-installed speedscope) { pnpm add --global speedscope }

        if (not-installed cargo) {
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        }

        if (not-installed cargo) { cargo install checkexec }
    }

    if $minimal {
        just _install_and_run pdm run pre-commit install out+err> /dev/null
    } else {
        if $app or $prod {
            pdm install --prod
        } else {
            pdm install
            just _install_and_run pdm run pre-commit install
        }
    }

    if $app {
        just build

        (
            pdm run python -m pipx install
                $"./dist/($command)-($version)-py3-none-any.whl"
                --force
                --pip-args="--force-reinstall"
        )
    }
}
