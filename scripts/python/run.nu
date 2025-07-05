#!/usr/bin/env nu

use ./command.nu

def --wrapped main [...args: string] {
  if "--self-help" in $args {
    return (help main)
  }

  let command = (command)

  let args = if ($command | is-empty) {
    $args
  } else {
    $args
    | prepend $command
  }

  uv run ...$args
}
