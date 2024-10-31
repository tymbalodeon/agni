#!/usr/bin/env nu

# Profile a command and view results
def main [
  ...args: string # Arguments to the command being profiled
] {
  let output_directory = "profiles"
  mkdir $output_directory

  let output_file = $"($output_directory)/profile.json"

  (
    sudo pdm run py-spy record
        --format speedscope
        --output $output_file
        --subprocesses
        -- pdm run python -m {{ application-command }} $args
  )

  speedscope $output_file
}
