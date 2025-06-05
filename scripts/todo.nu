#!/usr/bin/env nu

use color.nu use-colors

# Open comment at $index in $EDITOR
def "main open" [
  index?: int
  --path: string
  --sort-by-tag
] {
  let index = if ($index | is-empty) {
    let todos = if $sort_by_tag {
      main --color never --sort-by-tag $path
    } else {
      main --color never $path
    }

    $todos
    | fzf --tac
    | split row " "
    | first
    | into int
  } else {
    $index
  }

  ^$env.EDITOR (
    get-todos never $sort_by_tag $path
    | get $index
    | get file
  )
}

def color [target: string color: string]: string -> string {
  $in
  | str replace $target $"(ansi $color)($target)(ansi reset)"
}

def get-todos [
  color: string
  sort_by_tag: bool
  path?: string
] {
  let pattern = "# (FIXME|NOTE|TODO)"

  let matches = if ($path | is-empty) {
    rg $pattern --json
  } else {
    rg $pattern --json $path
  }

  let justfiles = (
    ls --short-names just
    | get name
    | where {($in | path parse | get stem) not-in (just env list)}
  )

  let todos = (
    $matches
    | lines
    | each {|line| $line | from json}
    | flatten
    | transpose
    | transpose --header-row
    | where {$in.lines | is-not-empty}
    | str trim
    | select line_number path.text lines.text
    | rename line_number file comment
    | where {
        not ($in.file | str starts-with scripts) and (
          not (
            $in.file | str starts-with just
          ) or ($in.file in $justfiles)
        )
      }
    | sort-by {$in | get (if $sort_by_tag { "comment" } else { "file" })}
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
  --color = "auto" # When to use colored output
  --sort-by-tag # Sort by todo tag
] {
  let todos = (get-todos $color $sort_by_tag $path)

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

      $"($index) • ($item.item.file) • ($item.item.comment)"
    }
  | to text
  | column -s • -t
}
