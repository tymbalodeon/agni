#!/usr/bin/env nu

# Update dependencies
def upgrade [
  --prod # Update production dependencies
] {
  if $prod {
    just install --minimal --prod
  } else {
    just install --minimal
  }

  if not $prod {
    pdm run python -m pip install --upgrade pip pipx
    pnpm update --global speedscope
    rustup update
    cargo install-update checkexec
  }

  if $prod {
    pdm update --prod
  } else {
    pdm update
  }

  just check --update
}
