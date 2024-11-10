#!/usr/bin/env nu

export def get-test [
  tests: list<string>
  search_term?: string
  --file
  --function
] {
  if ($search_term | is-empty) {
    return $tests
  } 

  $tests
  | filter {
      |test|

      try {
        let test_name = if $file {
          $test
          | split row "test_"
          | last
          | split row "__"
          | first
        } else if $function {
          $test
          | split row "__"
          | last
        } else {
          $test
        }

        $test_name =~ $search_term
      } catch {
        false
      }
    }
}

# Run tests
def main [
  search_term?: string # Run tests matching $search_term only
  --file  # Match $search_term to $file only
  --function  # Match $search_term to $function only
] {
  let tests = try {
    ls **/tests/**/test_*.nu
    | get name
  } catch {
    return
  }

  let tests = (
    if $file {
      get-test --file $tests $search_term
    } else if $function {
      get-test --function $tests $search_term
    } else {
      get-test $tests $search_term
    }
  )

  for test in $tests {
    print --no-newline $"($test)..."

    try {
      nu $test

      print $"(ansi green_bold)OK(ansi reset)"
    }
  }
}
