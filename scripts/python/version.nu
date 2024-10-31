#!/usr/bin/env nu

use ./command.nu

def main [] {
  return (
    open $"(command)/__init__.py"
    | split row " "
    | last
    | str replace --all '"' ""
  )
}
