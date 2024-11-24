#!/usr/bin/env nu

# Update dependencies
def main [
    --prod # Update only production dependencies
] {
  if $prod {
    uv sync --no-dev --upgrade
  } else {
    uv sync --upgrade
  }
}
