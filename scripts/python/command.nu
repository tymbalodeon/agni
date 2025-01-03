#!/usr/bin/env nu

use ../environment.nu get-project-path

export def main [] {
  open (get-project-path pyproject.toml)
  | get project.name
}
