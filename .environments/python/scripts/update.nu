#!/usr/bin/env nu

use ../../default/scripts/cd-to-root.nu

# Update dependencies
def main [
  ...dependencies: string # Dependencies to update
  --breaking # Update to latest SemVer-breaking versions
  --dev # Update only development dependencies
  --prod # Update only production dependencies
] {
  cd-to-root python

  if $breaking {
    let all = not $dev and not $prod
    let pyproject = (open pyproject.toml)

    if $all or $dev {
      let dependencies = try {
        $pyproject.dependency-groups.dev
      } catch {
        []
      }

      if ($dependencies | is-not-empty) {
        uv remove --dev ...$dependencies out+err> /dev/null
        uv add --dev ...$dependencies
      }
    } else if $all or $prod {
      let dependencies = try {
        $pyproject.project.dependencies
      } catch {
        []
      }

      if ($dependencies | is-not-empty) {
        uv remove ...$dependencies out+err> /dev/null
        uv add ...$dependencies
      }
    }

    taplo format pyproject.toml out+err> /dev/null
  } else {
    let args = [--upgrade]

    let args = if $dev {
      $args
      | append "--only-dev"
    } else if $prod {
      $args
      | append "--no-dev"
    } else {
      $args
    }

    uv sync ...$args
  }
}
