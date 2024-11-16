#!/usr/bin/env nu

export def parse-args [...args: string] {
  (
    $args
    | window 2 --stride 2
    | filter {
        |arg|

        let value = ($arg | last)

        try {
          $value
          | into bool
        } catch {
          $value
          | is-not-empty
        }
      }
    | flatten
  ) | filter {$in not-in ["false" "true"]}
}

def --wrapped cog-log [...args: string] {
  let args = (parse-args ...$args)

  cog log ...$args
}

# View project history
def main [
  filename?: string
  --author: string # Filter on commit author
  --breaking-change # Filter BREAKING CHANGE commits
  --no-error # Omit error on the commit log
  --oneline # View commits on one line
  --scope: string # Filter on commit scope
  --type: string # Filter on commit type
] {
  if ($filename | is-empty) {
    if $oneline {
      (
        ^git log
          --pretty=format:'%C(auto)%h%d%C(reset) %C(dim)%ar%C(reset) %C(bold)%s%C(reset) %C(dim blue)(%an)%C(reset)'
          --graph
      )
    } else {
      (
        cog-log
          --author $author
          --breaking-change ($breaking_change | into string)
          --no-error ($no_error | into string)
          --scope $scope
          --type $type
      )
    }
  } else {
    git log --patch $filename
  }
}
