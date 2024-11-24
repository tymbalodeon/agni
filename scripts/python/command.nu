#!/usr/bin/env nu

export def main [] {
  open ../pyproject.toml
  | get project.name
}
