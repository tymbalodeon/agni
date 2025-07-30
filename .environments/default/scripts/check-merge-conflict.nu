#!/usr/bin/env nu

# Check for merge conflicts
def main [] {
  # TODO: add color to file/indices and --color option
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

  let conflict_lines = (
    jj file list
    | lines
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
        | each {$"($file.file):($in)"}
      }
    | flatten
    | to text --no-newline
  )

  if ($conflict_lines | is-not-empty) {
    print $conflict_lines
    exit 1
  }
}
