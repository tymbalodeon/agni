#!/usr/bin/env nu

use ./command.nu

def --wrapped main [...args: string] {
  if $environment == "--self-help" {
    return (help main)
  }

  uv run (command) ...$args
}
