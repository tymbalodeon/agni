#!/usr/bin/env nu

use ../../default/scripts/cd-to-root.nu

# Open an interactive python shell
def main [] {
  cd-to-root python

  try {
    uv run bpython
  } catch {
    uv run python
  }
}
