#!/usr/bin/env nu

# Profile a command and view results
export def main [
  ...args: string # Arguments to the command being profiled
] {
  just install --minimal

  let output_directory = "profiles"
  mkdir $output_directory

  let output_file = $"($output_directory)/profile.json"

  (
    just _install_and_run sudo pdm run py-spy record
        --format speedscope
        --output $output_file
        --subprocesses
        -- pdm run python -m {{ application-command }} $args
  )

  speedscope $output_file
}
