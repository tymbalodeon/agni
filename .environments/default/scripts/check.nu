#!/usr/bin/env nu

use ../../git/scripts/leaks.nu
use color.nu use-colors

export def get-files [paths: list<string>] {
  if ($paths | is-empty) {
    jj file list
    | lines
    | where {
        (
          $in
          | path parse
          | get extension
        ) not-in [
          jpeg
          png
        ]
      }
  } else {
    let directories = (
      $paths
      | where {($in | path type) == dir}
    )

    $paths
    | where {($in | path type) == file}
    | append (
        $directories
        | each {ls ($"($in)/**/*" | into glob) | get name}
      )
    | flatten
  }
}

def get-submodules [] {
  open Justfile
  | lines
  | where {str starts-with mod}
  | each {
      split row "mod "
      | last
      | split row " "
      | first
    }
}

export def run-check [type: string paths: list<string>] {
  let justfiles = (
    get-submodules
    | each {$".environments/($in)/Justfile"}
    | where {path exists}
    | each {
        |environment|

        let recipes = (
          just --summary --justfile $environment
          | split row " "
        )

        if $type in $recipes {
          $environment
        }
      }
    | where {is-not-empty}
  )

  for justfile in $justfiles {
    let environment = ($justfile | path split | get 1)
    print $"($type | str capitalize)ing ($environment) files..."
    just --justfile $justfile $type ...$paths
  }
}

def get-default-checks [] {
  ls .environments/default/scripts/check-*
  | get name
  | each {
      {
        file: $in
        name: ($in | path parse | get stem | str replace check- "")
      }
    }
}

def append-comment [check_name: string comment: string color: string] {
  let comment = if (use-colors $color) {
    $"(ansi blue)# ($comment)(ansi reset)"
  } else {
    $"# ($comment)"
  }

  $"($check_name) • ($comment)"
}

def list-default-checks [color: string] {
  get-default-checks
  | each {
      let comment = (
        nu $in.file --help
        | split row "\n\n"
        | first
      )

      append-comment $in.name $comment $color
    }
}

# List default checks
def "main list default" [
  --color = "auto" # When to use colored output {always|auto|never}
] {
  list-default-checks $color
  | to text
  | column -t -s •
}

# List checks
def "main list" [
  --color = "auto" # When to use colored output {always|auto|never}
] {
  # TODO: add cyan note next to default checks?
  list-default-checks $color
  | append (
      [
        {
          name: default
          comment: "Run default checks (see `check list default`)"
        }

        {
          name: leaks
          comment: "Scan code for secrets"
        }
      ]
      | each {append-comment $in.name $in.comment $color}
    )
  | append (
      fd "(check|format|lint).nu" .environments
      | lines
      | each {split row "/" | get 1}
      | where $it != default
      | uniq
      | each {append-comment $in $"Check, format, and lint ($in) files" $color}
    )
  | sort
  | to text
  | column -t -s •
}

# Run checks
export def main [...checks: string] {
  let checks = ($checks | str downcase)
  let all = ($checks | is-empty)

  if $all or ("leaks" in $checks) {
    leaks
  }

  mut failed = false

  for check in (
    just --summary
    | split row " "
    | where {
        ($in | str ends-with :check) or (
          $in
          | str starts-with format
        ) or (
          $in
          | str starts-with lint
        )
      }
  ) {
    if $all or $check in $checks {
      let results = (just --color always $check out+err>| complete)

      print $results.stdout

      if ($results.exit_code) != 0 {
        $failed = true
      }
    }
  }

  let default_checks = (get-default-checks)

  let checks = if $all or ("default" in $checks) {
    $default_checks.name
  } else {
    $checks
  }

  let submodules = (get-submodules)

  for check_name in $checks {
    if $check_name in $default_checks.name {
      for check in ($default_checks | where name == $check_name) {
        let results = (nu $check.file out+err>| complete)

        print $results.stdout

        if ($results.exit_code) != 0 {
          $failed = true
        }
      }
    } else if $check_name in $submodules {
      let results = (just --color always $check_name check out+err>| complete)

      print $results.stdout

      if ($results.exit_code) != 0 {
          $failed = true
      }
    }
  }

  if $failed {
    exit 1
  }
}
