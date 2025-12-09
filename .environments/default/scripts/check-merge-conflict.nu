#!/usr/bin/env nu

use ../../default/scripts/color.nu use-colors
use check.nu get-files

# Check for merge conflicts
def main [
  ...paths: string # Files or directories to fix
  --color = "auto" # When to use colored output {always|auto|never}
] {
  let git_dir = (git rev-parse --git-dir | str trim)

  if not (
    ($"($git_dir)/MERGE_MSG" | path exists) and (
      [MERGE_HEAD rebase-apply rebase-merge]
      | any {$"(git_dir)/($in)" | path exists}
    )
  ) {
    return
  }

  let conflict_patterns = [
    "<<<<<<< ",
    "======= ",
    "=======\r\n",
    "=======\n",
    ">>>>>>> ",
  ]

  let use_colors = (use-colors $color)

  let conflict_lines = (
    get-files $paths
    | each {
        |file|

        let conflict_lines = (
          open --raw $file
          | lines
          | enumerate
          | where {
              |line|

              for pattern in $conflict_patterns {
                if ($line.item | str starts-with $pattern) {
                  return true
                }
              }

              return false
            }
        )

        if ($conflict_lines | is-not-empty) {
          {
            file: $file
            indices: $conflict_lines.index
          }
        }
      }
    | where {is-not-empty}
    | each {
        |file|

        $file.indices
        | each {
            |index|

            let file = if $use_colors {
              $"(ansi magenta)($file.file)(ansi reset)"
            } else {
              $file.file
            }

            let index = if $use_colors {
              $"(ansi green)($index)(ansi reset)"
            } else {
              $index
            }

            $"($file):($index)"
          }
      }
    | flatten
    | to text --no-newline
  )

  if ($conflict_lines | is-not-empty) {
    print $conflict_lines
    exit 1
  }
}
