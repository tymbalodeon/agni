#!/usr/bin/env nu

use ./build.nu
use ./command.nu
use ./deps.nu
use ./version.nu

def not-installed [command: string] {
  (command -v $command | is-empty)
}

def module-not-installed [command: string] {
  return (
    uv run python -m $command --help err> /dev/null
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
            deps --prod
        } else {
            deps
        }

        exit
    }

    if not $prod {
        if (module-not-installed pip) {
            uv run python -m ensurepip --upgrade --default-pip
        }

        if (module-not-installed pipx) {
            uv run python -m pip install --upgrade pip pipx;
            uv run python -m pipx ensurepath
        }

        if (not-installed speedscope) { pnpm add --global speedscope }

        if (not-installed cargo) {
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        }

        if (not-installed cargo) { cargo install checkexec }
    }

    if $minimal {
        uv run pre-commit install out+err> /dev/null
    } else {
        uv sync

        if not $app and not $prod {
            uv sync
            uv run pre-commit install
        }
    }

    if $app {
        build

        (
            uv run python -m pipx install
                $"./dist/(command)-(version)-py3-none-any.whl"
                --force
                --pip-args="--force-reinstall"
        )
    }
}
