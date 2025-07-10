#!/usr/bin/env nu

use cd-to-root.nu

def main [] {
  cd-to-root

  try {
    open pyproject.toml
    | get project.version
  }
}
