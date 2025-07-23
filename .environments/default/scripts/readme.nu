#!/usr/bin/env nu

# View README file
def main [] {
  if ("README.md" | path exists) {
    glow README.md
  }
}
