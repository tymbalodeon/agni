#!/usr/bin/env nu

# Run coverage report
export def main [
  --fail-under: string # Fail if coverage is less than this percentage
] {
  just test out+err> /dev/null

  if not ($fail_under | is-empty) {
      (
          just _install_and_run pdm run coverage report -m
              --skip-covered
              --sort "cover"
              --fail-under $fail_under
      )
  } else {
      (
          just _install_and_run pdm run coverage report -m
              --skip-covered
              --sort "cover"
      )
  }
}

