#!/usr/bin/env nu

use cd-to-root.nu

# Open an interactive python shell
def main [] {
  cd-to-root

  try {
    uv run bpython
  } catch {
    uv run python
  }
}
