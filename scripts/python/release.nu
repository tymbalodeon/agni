#!/usr/bin/env nu

use ./command.nu

def main [
  target: string # Type of release to target (major, minor, or patch)
  --preview # Preview new additions to the CHANGELOG without modifyiing anything
] {
  let current_version_numbers = (
    just _get-application-version
    | split row "."
  )

  mut major = ($current_version_numbers.0 | into int)
  mut minor = ($current_version_numbers.1 | into int)
  mut patch = ($current_version_numbers.2 | into int)

  if not ($target in [major minor patch]) {
      print (
          [
              $"\"($target)\" is not a valid release target."
               "<target> must be one of: {major, minor, patch}"
          ]
          | str join " "
      )

      exit 1
  }

  if not ((git branch --show-current) == "main") {
      print "Can only release from the main branch."
      exit 1
  }

  if (git status --short | is-not-empty) {
      print "Please commit all changes before releasing."
      exit 1
  }

  if not $preview {
      just check
  }

  if $target == "major" {
      $major += 1
      $minor = 0
      $patch = 0
  } else if $target == "minor" {
      $minor += 1
      $patch = 0
  } else if $target == "patch" {
     $patch += 1
  }

  let new_version = ([$major $minor $patch] | str join ".")

  if $preview {
      git-cliff --unreleased --tag $new_version
      exit
  }

  let init_file = $"($command)/__init__.py"
  let current_version = $current_version_numbers | str join "."
  let files = [$init_file tests/main_test.py]

  for file in $files {
    open $file
    | str replace $current_version $new_version
    | save --force $file
  }

  git-cliff --unreleased --tag $new_version --prepend CHANGELOG.md
  git add $files CHANGELOG.md
  git commit --message $"chore\(release\): bump version to ($new_version)"
  git tag $"v($new_version)"
  git push --follow-tags
  just install --app
}
