#!/usr/bin/env nu

# View project history
def main [
  filename?: string
  --annotate-lines # Annotate $filename lines with commit information
] {
  if ($filename | is-empty) {
      serie
  } else if $annotate_lines {
    git blame $filename
  } else {
    git log --patch $filename
  }
}
