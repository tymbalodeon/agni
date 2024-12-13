#!/usr/bin/env nu

use version.nu

def get-last-modified []: string -> datetime {
  try {
    $in
    | lines
    | each {ls $in}
    | flatten
    | get modified
    | math max
  }
}

# Build and install the application
def main [] {
  try {
    open pyproject.toml
    | get build-system

    let build_modified = (
      fd --extension gz --extension whl --no-ignore
      | get-last-modified
    )

    let source_modified = (
      fd --extension py
      | get-last-modified
    )

    if ($build_modified | is-empty) or (
      $source_modified > $build_modified
    ) {
      uv build
    }
  }
}
