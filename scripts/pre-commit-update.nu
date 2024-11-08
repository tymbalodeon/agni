#!/usr/bin/env nu

def filter_repos_by_domain [repos: list<string> domain: string] {
  $repos
  | filter {|repo| $"($domain).com" in $repo}
}

def main [file: string] {
  let file = if ($file | is-empty) {
    ".pre-commit-config.yaml"
  } else {
    $file
  }

  let repos = (
    open $file
    | get repos
    | where repo != "local"
    | get repo
  )

  let github_repos = (filter_repos_by_domain $repos github)
  # let gitlab_repos = (filter_repos_by_domain $repos gitlab)

  let github_urls = (
    $github_repos
    | each {
      |repo|

      let release_url = (
        $repo
        | str replace "github.com" "api.github.com/repos"
        | str replace --regex ".git$" ""
        | path join "releases"
      )

      {repo: $repo release_url: $release_url}
    }
  )

  for url in $github_urls {
    try {
      let tag = (
        http get $url.release_url
        | get tag_name
        | first
      )

      print $tag
    } catch {
        print "BAD"
    }
  }
}
