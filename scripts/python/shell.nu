#!/usr/bin/env nu

# Open an interactive python shell
def main [] {
  try {
    uv run bpython
  } catch {
    uv run python
  }
}
