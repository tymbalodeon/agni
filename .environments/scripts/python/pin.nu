#!/usr/bin/env nu

use cd-to-root.nu

# Manage python version
def main [version?: number] {
  cd-to-root

  if ($version | is-not-empty) {
    uv python pin $version
  } else {
    uv python pin
  }
}
