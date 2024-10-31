#!/usr/bin/env nu

def main [] {
  return (
    open pyproject.toml | get project.name
  )
}
