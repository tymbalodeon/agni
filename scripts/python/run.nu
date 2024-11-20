#!/usr/bin/env nu

use ./command.nu

def --wrapped main [...args: string] {
  if "--self-help" in $args {
    return (help main)
  }

  uv run (command) ...$args
}
