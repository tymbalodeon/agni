#!/usr/bin/env nu

def filter-file [test: string file: string] {
  try {
    let name = (
      $test
      | split row "test-"
      | last
      | split row "--"
      | first
    )

    $name =~ $file
  } catch {
    false
  }
}

def filter-function [test: string function: string] {
  try {
    let name = (
      $test
      | split row "--"
      | last
    )

    $name =~ $function
  } catch {
    false
  }
}

def filter-module [test: string module: string] {
  let parent = (
    $test
    | path parse
    | get parent
  )

  $"src/($module)" in $parent or (
    $"scripts/($module)" in $parent
  )
}

export def get-tests [
  tests: list<string>
  filters: record<
    file: any,
    function: any,
    module: any,
  >
  search_term?: string
] {
  let module = $filters.module
  let file = $filters.file
  let function = $filters.function

  let tests = match $module {
    null => $tests
    _ => ($tests | filter {filter-module $in $module})
  }

  let $tests = match $file {
    null => $tests
    _ => ($tests | filter {filter-file $in $file})
  }

  let $tests = match $function {
    null => $tests
    _ => ($tests | filter {filter-function $in $function})
  }

  match $search_term {
    null => $tests
    _ => ($tests | filter {$in =~ $search_term})
  }
}

# Run tests
def main [
  --match-suites: string # Regular expression to match against suite names (defaults to all)
  --match-tests: string # Regular expression to match against test names (defaults to all)
] {
  let command = "use nutest; nutest run-tests"

  let command = if ($match_suites | is-not-empty) {
    $"($command) --match-suites ($match_suites)"
  } else {
    $command
  }

  let command = if ($match_tests | is-not-empty) {
    $"($command) --match-tests ($match_tests)"
  } else {
    $command
  }

  (
    nu
      --commands $command
      --include-path $env.NUTEST
  )
}
