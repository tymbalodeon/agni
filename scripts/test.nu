#!/usr/bin/env nu

# Run tests
def main [
  file?: string # Run tests in $file only
] {

  let tests = try {
    let glob = (
      "**"
      | path join (
        if ($file | is-empty) {
          "test_*.nu"
        } else {
          let file = if ($file | path parse | get extension) == "nu" {
            $file
          } else {
            $"($file).nu"
          }

          let file = if (($file | path basename) | str starts-with "test_") {
            $file
          } else {
            $"test_($file)"
          }

          $file
        }
      )
    )

    ls ($glob | into glob)
    | get name
  } catch {
    return
  }

  for test in $tests {
    print --no-newline $"($test)..."

    try {
      nu $test

      print $"(ansi green_bold)OK(ansi reset)"
    }
  }
}
