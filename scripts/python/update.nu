#!/usr/bin/env nu

use ./check.nu

# Update dependencies
def main [
    --prod # Update production dependencies
] {
    if not $prod {
        uv run python -m pip install --upgrade pip pipx
        pnpm update --global speedscope
        rustup update
        cargo install-update checkexec
    }

    uv sync --upgrade

    check --update
}
