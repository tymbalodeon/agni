#!/usr/bin/env nu

# TODO: move this to its own module? Since not every generic project has
# "releases"

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
