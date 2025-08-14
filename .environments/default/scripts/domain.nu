#!/usr/bin/env nu

export def parse-git-origin [origin: string --quiet] {
  let parsed_origin = if ($origin | str starts-with "git@") {
    $origin
    | parse "git@{domain}:{owner}/{repo}.git"
  } else if ($origin | str starts-with "http") {
    let origin = ($origin | str replace --regex "https?://" "")
    if : in $origin {
      $origin
      | parse "{domain}:{owner}/{repo}.git"
    } else {
      $origin
      | parse "{domain}/{owner}/{repo}.git"
    }
  } else if ($origin | str starts-with "ssh://") {
    $origin
    | parse "ssh://git@{domain}/{owner}/{repo}.git"
  } else {
    if not $quiet {
      print --stderr $"Unable to parse remote origin: \"($origin)\""
    }

    [
      {
        domain: null
        owner: null
        repo: null
      }
    ]
  }

  $parsed_origin
  | first
}

export def main [] {
  parse-git-origin (git remote get-url origin)
  | get domain
  | str replace ".com" ""
}
