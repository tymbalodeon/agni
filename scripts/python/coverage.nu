#!/usr/bin/env nu

use ./test.nu

# Run coverage report
def main [
  --fail-under: string # Fail if coverage is less than this percentage
] {
  test out+err> /dev/null

  if ($fail_under | is-not-empty) {
    (
      uv run coverage report -m
        --skip-covered
        --sort cover
        --fail-under $fail_under
    )
  } else {
    (
      uv run coverage report -m
        --skip-covered
        --sort cover
    )
  }
}
