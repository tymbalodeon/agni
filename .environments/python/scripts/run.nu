#!/usr/bin/env nu

use cd-to-root.nu
use command.nu

def --wrapped main [...args: string] {
  cd-to-root

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
