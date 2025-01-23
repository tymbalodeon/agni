#!/usr/bin/env nu

# Manage python version
def main [version?: number] {
  if ($version | is-not-empty) {
    uv python pin $version
  } else {
    uv python pin
  }
}
