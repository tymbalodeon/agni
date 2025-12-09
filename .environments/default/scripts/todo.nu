#!/usr/bin/env nu

use environment-common.nu get-available-environments
use color.nu use-colors

def get-todos [
  settings: record<
    sort_by_keyword: bool
    color: string
    path: any
    exclude_path: any
    keyword: any
  >
] {
  let pattern = $"(get-comment-token-pattern) \(FIXME|NOTE|TODO\)"

  let matches = try {
    if ($settings.path | is-empty) {
      rg --hidden $pattern --json err> /dev/null
    } else {
      rg --hidden $pattern --json $settings.path err> /dev/null
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

  let excluded_paths = if ($settings.exclude_path | is-not-empty) {
    $excluded_paths
    | append $settings.exclude_path
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
        ) and (
          ($settings.keyword | is-empty) or (
            $settings.keyword in $in.comment)
          )
      }
    | sort-by {
        $in
        | get (if $settings.sort_by_keyword { "comment" } else { "file" })
      }
  )

  let use_colors = (use-colors $settings.color)

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

def get-index [
  random: bool
  sort_by_keyword: bool
  exclude_path?: string
  keyword?: string
  path?: string
  index?: int
] {
  let keyword = if ($keyword | is-not-empty) {
    $keyword
    | str upcase
  }

  if ($index | is-empty) {
    let todos = if $sort_by_keyword {
      main --color never --keyword $keyword --sort-by-keyword $path
    } else {
      main --color never --keyword $keyword $path
    }

    if ($todos | is-empty) {
      return
    }

    let todo = if $random {
      random int 0..(($todos | lines | length) - 1)
      | into string
    } else if ($todos | lines | length) == 1 {
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
}

def edit-todo [
  sort_by_keyword: bool
  exclude_path?: string
  keyword?: string
  path?: string
  index?: int
] {
  ^$env.EDITOR (
    (
      get-todos {
        sort_by_keyword: $sort_by_keyword
        color: never
        path: $path
        exclude_path: $exclude_path
        keyword: $keyword
      }
    )
    | get $index
    | get file
  )
}

# Open comment at $index in $EDITOR [alias: `edit`]
def "main open" [
  index?: int # Open todo at $index as it appears in `todo` with the same options
  path?: string # A path to search for keywords
  --exclude-path: string # Path (or glob) to exclude when searching for TODO comments
  --keyword: string # Filter to the specified keyword
  --sort-by-keyword # Sort by todo keyword
] {
  let index = (
    get-index
      false
      $sort_by_keyword
      $exclude_path
      $keyword
      $path
      $index
  )

  if ($index | is-empty) {
    return
  }

  (
    edit-todo
      $sort_by_keyword
      $exclude_path
      $keyword
      $path
      $index
  )
}

alias "main edit" = main open

# Open random comment in $EDITOR [alias: `edit`]
def "main open random" [
  path?: string # A path to search for keywords
  --exclude-path: string # Path (or glob) to exclude when searching for TODO comments
  --keyword: string # Filter to the specified keyword
  --sort-by-keyword # Sort by todo keyword
] {
  let index = (
    get-index
      true
      $sort_by_keyword
      $exclude_path
      $keyword
      $path
  )

  if ($index | is-empty) {
    return
  }

  (
    edit-todo
      $sort_by_keyword
      $exclude_path
      $keyword
      $path
      $index
  )
}

def color [target: string color: string]: string -> string {
  $in
  | str replace $target $"(ansi $color)($target)(ansi reset)"
}

def get-comment-token-pattern [] {
  "(#|%|--|//)"
}

def list-todos [
  settings: record<
    sort_by_keyword: bool
    color: string
    path: string
    exclude_path: string
    keyword: string
  >
] {
  let todos = (get-todos $settings)

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

      let index = if (use-colors $settings.color) {
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

def display-todos [
  todos: list<
    record<
      line_number: int
      file: string
      comment: string
    >
  >
  color: string
] {
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

# View random comment
def "main random" [
  path?: string # A path to search for keywords
  --color = "auto" # When to use colored output {always|auto|never}
  --exclude-path: string # Path (or glob) to exclude when searching for TODO comments
  --keyword: string # Filter to the specified keyword
  --sort-by-keyword # Sort by todo keyword
] {
  let index = (
    get-index
      true
      $sort_by_keyword
      $exclude_path
      $keyword
      $path
  )

  let todos = (
    get-todos {
      sort_by_keyword: $sort_by_keyword
      color: $color
      path: $path
      exclude_path: $exclude_path
      keyword: $keyword
    }
    | enumerate
    | where index == $index
    | get item
  )

  display-todos $todos $color
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
    get-todos {
      sort_by_keyword: $sort_by_keyword
      color: $color
      path: $path
      exclude_path: $exclude_path
      keyword: $keyword
    }
  )

  display-todos $todos $color
}
