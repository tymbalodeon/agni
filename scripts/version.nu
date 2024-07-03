#!/usr/bin/env nu

use ./command.nu

export def main [] {
  return (
    open $"(command)/__init__.py"
    | split row " "
    | last
    | str replace --all '"' ""
  )
}
