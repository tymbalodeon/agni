#!/usr/bin/env nu

use ../../default/scripts/cd-to-root.nu

# Manage python version
def main [version?: number] {
  cd-to-root python

  if ($version | is-not-empty) {
    uv python pin $version
  } else {
    uv python pin
  }
}
