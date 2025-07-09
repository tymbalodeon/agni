#!/usr/bin/env nu

use cd-to-root.nu
use command.nu

# Profile a command and view results
def main [
  ...args: string # Arguments to the command being profiled
] {
  cd-to-root

  let output_directory = "profiles"

  mkdir $output_directory

  let output_file = $"($output_directory)/profile.json"

  (
    uv run py-spy record
      --format speedscope
      --output $output_file
      --subprocesses
      -- uv run python -m (command) $args
  )

  speedscope $output_file
}
