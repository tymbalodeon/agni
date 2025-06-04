#!/usr/bin/env nu

# TODO: align indices to the right (and add color?)

# Open comment at $index in $EDITOR
def "main open" [
  index: int
  path?: string
  --sort-by-tag
] {
  ^$env.EDITOR (
    get-todos $sort_by_tag $path
    | get $index
    | get file
    | ansi strip
  )
}

def color [target: string color: string]: string -> string {
  $in
  | str replace $target $"(ansi $color)($target)(ansi reset)"
}

def get-todos [sort_by_tag: bool path?: string] {
  let pattern = "# (FIXME|NOTE|TODO)"

  let matches = if ($path | is-empty) {
    rg $pattern --json
  } else {
    rg $pattern --json $path
  }

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
  | where {not ($in.file | str starts-with scripts)}
  | sort-by {$in | get (if $sort_by_tag { "comment" } else { "file" })}
  | update comment {
      |row|

      (
        $row.comment
        | color FIXME red_bold
        | color NOTE blue_bold
        | color TODO cyan_bold
      )
    }
  | update file {
      |row|

      let file = $"(ansi magenta)($row.file)(ansi reset)"
      let line_number = $"(ansi green)($row.line_number)(ansi reset)"

      $"($file):($line_number)"
    }
}

# List TODO-style comments
def main [
  path?: string # A path to search for keywords
  --sort-by-tag # Sort by todo tag
] {
  let todos = (get-todos $sort_by_tag $path)

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

      let index = $"(ansi yellow)(
        $item.index | fill --alignment Right --width $width
      )(ansi reset)"

      $"($index) • ($item.item.file) • ($item.item.comment)"
    }
  | to text
  | column -s • -t
}
