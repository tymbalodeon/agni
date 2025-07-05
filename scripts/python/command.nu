#!/usr/bin/env nu

export def main [] {
  try {
    open pyproject.toml
    | get project.scripts
    | columns
    | first
  }
}
