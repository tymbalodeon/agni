#!/usr/bin/env nu

use ../../default/scripts/cd-to-root.nu

export def main [] {
  cd-to-root python

  try {
    open pyproject.toml
    | get project.scripts
    | columns
    | first
  }
}
