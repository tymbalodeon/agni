#!/usr/bin/env nu

use environment.nu get-available-environments
use environment.nu use-colors

# Open comment at $index in $EDITOR
def "main open" [
  index?: int # Open todo at $index as it appears in `todo` with the same options
  path?: string # A path to search for keywords
  --exclude-path: string # Path (or glob) to exclude when searching for TODO comments
  --keyword: string # Filter to the specified keyword
  --sort-by-keyword # Sort by todo keyword
] {
  let index = if ($index | is-empty) {
    let todos = if $sort_by_keyword {
      main --color never --sort-by-keyword $path
    } else {
      main --color never $path
    }

    if ($todos | is-empty) {
      return
    }

    let todo = if ($todos | lines | length) == 1 {
      $todos
    } else {
      $todos
      | fzf
    }

    $todo
    | split row " "
    | first
    | into int
  } else {
    $index
  }

  ^$env.EDITOR (
    (
      get-todos
        $sort_by_keyword
        never
        $path
        $exclude_path
        --keyword $keyword
    )
    | get $index
    | get file
  )
}

def color [target: string color: string]: string -> string {
  $in
  | str replace $target $"(ansi $color)($target)(ansi reset)"
}

def get-comment-token-pattern [] {
  "(#|%|--|//)"
}

def get-todos [
  sort_by_keyword: bool
  color: string
  path?: string
  exclude_path?: string
  --keyword: string
] {
  let pattern = $"(get-comment-token-pattern) \(FIXME|NOTE|TODO\)"

  let matches = try {
    if ($path | is-empty) {
      rg --hidden $pattern --json
    } else {
      rg --hidden $pattern --json $path
    }
  } catch {
    return []
  }

  let available_environments = (
    get-available-environments --exclude-local
    | get name
  )

  let excluded_paths = if (".environments/environments.toml" | path exists) {
    try {
      open .environments/environments.toml
      | get environments
      | where name == default
      | first
      | get todo.exclude_paths
    } catch {
      []
    }
  } else {
    []
  }

  let excluded_paths = if ($exclude_path | is-not-empty) {
    $excluded_paths
    | append $exclude_path
  } else {
    $excluded_paths
  }

  let matches = (
    $matches
    | lines
    | each {from json}
    | flatten
    | where {
        |match|

        if "path" not-in ($match | columns) {
          return false
        }

        let path = $match.path.text

        if ($path | str starts-with .git) or ($path in $excluded_paths) {
          return false
        }

        for excluded_path in $excluded_paths {
          let files_to_exclude = (ls ($excluded_path | into glob) | get name)

          if $path in $files_to_exclude {
            return false
          }

          for file in $files_to_exclude {
            if ($path | str starts-with $file) {
              return false
            }
          }
        }

        if not ($path | str starts-with .environments) {
          true
        } else if (
          $path
          | path split
          | drop nth 0
          | first
        ) in $available_environments {
          false
        } else {
          true
        }
      }
    | transpose
    | transpose --header-row
    | where {$in.lines | is-not-empty}
    | str trim
    | select line_number path.text lines.text
    | rename line_number file comment
  )

  let justfiles = (
    fd Justfile .environments
    | lines
    | where {($in | path dirname | path basename) not-in (just env list)}
  )

  let todos = (
    $matches
    | where {
        not ($in.file | str starts-with scripts) and (
          not (
            $in.file | str starts-with just
          ) or ($in.file in $justfiles)
        ) and (($keyword | is-empty) or ($keyword in $in.comment))
      }
    | sort-by {$in | get (if $sort_by_keyword { "comment" } else { "file" })}
  )

  let use_colors = (use-colors $color)

  let todos = if $use_colors {
    $todos
    | update comment {
        |row|

        (
          $row.comment
          | color FIXME red_bold
          | color NOTE blue_bold
          | color TODO cyan_bold
        )
      }
  } else {
    $todos
  }

  $todos
  | update file {
      |row|

      let file = if $use_colors {
        $"(ansi magenta)($row.file)(ansi reset)"
      } else {
        $row.file
      }

      let line_number = if $use_colors {
        $"(ansi green)($row.line_number)(ansi reset)"
      } else {
        $row.line_number
      }

      $"($file):($line_number)"
    }
}

# List TODO-style comments
def main [
  path?: string # A path to search for keywords
  --color = "auto" # When to use colored output {always|auto|never}
  --exclude-path: string # Path (or glob) to exclude when searching for TODO comments
  --keyword: string # Filter to the specified keyword
  --sort-by-keyword # Sort by todo keyword
] {
  let todos = (
    get-todos
      $sort_by_keyword
      $color
      $path
      $exclude_path
      --keyword $keyword
  )

  let width = (
    (
      $todos
      | length
    ) - 1
    | into string
    | split chars
    | length
  )

  $todos
  | enumerate
  | each {
      |item|

      let index = if (use-colors $color) {
        $"(ansi yellow)(
          $item.index
          | fill --alignment Right --width $width
        )(ansi reset)"
      } else {
        $item.index
      }

      let comment = (
        $item.item.comment
        | str replace --regex (get-comment-token-pattern) ""
      )

      $"($index) • ($item.item.file) • ($comment)"
    }
  | to text
  | column -s • -t
}
