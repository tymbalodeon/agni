#!/usr/bin/env nu

use ./command.nu

def main [] {
  open pyproject.toml | get project.version
}
