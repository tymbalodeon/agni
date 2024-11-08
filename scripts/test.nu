#!/usr/bin/env nu

# Run tests
def main [
  search_term?: string # Run tests matching $search_term only
  --file  # Match $search_term to $file only
  --function  # Match $search_term to $function only
] {
  let all_tests = try {
    ls **/tests/**/test_*.nu 
    | get name
  } catch {
    return
  }

  let tests = (
    if ($search_term | is-empty) {
      $all_tests
    } else if $file {
      $all_tests
      | filter {
          |file|

          try {
            (
              $file
              | split row "test_"
              | last
              | split row "__"
              | first
            ) =~ $search_term
          } catch {
            false
          }
        }
    } else if $function {
      $all_tests
      | filter {
          |file|

          try {
            (
              $file
              | split row "__"
              | last
            ) =~ $search_term
          } catch {
            false
          }
        }
    } else {
      $all_tests
      | filter {|file| $file =~ $search_term}
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
