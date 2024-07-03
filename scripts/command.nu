#!/usr/bin/env nu

export def main [] {
  return (
    open pyproject.toml | get project.name
  )
}
