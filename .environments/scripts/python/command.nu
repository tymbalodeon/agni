#!/usr/bin/env nu

use cd-to-root.nu

export def main [] {
  cd-to-root

  try {
    open pyproject.toml
    | get project.scripts
    | columns
    | first
  }
}
