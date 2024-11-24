#!/usr/bin/env nu

# Remove generated files
def main [] {
  for file in [
    .coverage
    dist
    profiles
    **/__pycache__
    .pytest_cache
    .venv
  ] {
    rm --force --recursive $file
  }
}
