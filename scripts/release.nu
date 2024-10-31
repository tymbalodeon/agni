#!/usr/bin/env nu

use ./check.nu

# Create a new release
def main [
  --preview # Preview new additions to the CHANGELOG without modifyiing anything
] {
  if not $preview {
    if not ((git branch --show-current) == "trunk") {
      return "Can only release from the trunk branch."
    }

    if (git status --short | is-not-empty) {
      return "Please commit all changes before releasing."
    }

    check
  }

  cog changelog
}
