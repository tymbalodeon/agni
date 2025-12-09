#!/usr/bin/env nu

use domain.nu
use print.nu print-error
use print.nu print-warning

def get-service [service?: string] {
  if ($service | is-empty) {
    domain
  } else {
    $service
  }
}

def get-branches [] {
  git branch --remote
  | lines
  | each {|line| $line | split row "/" | last}
  | append (
      git for-each-ref --format='%(refname:short)' refs/heads/
      | lines
   )
  | uniq
  | sort
}

def get-issue-branch [issue_number: number] {
  let branches = (
    (get-branches)
    | find $"($issue_number)-"
  )

  if ($branches | is-not-empty)  {
    $branches
    | last
  }
}

def --wrapped gh [...args] {
  ^gh ...$args
}

def --wrapped glab [...args] {
  ^gh ...$args
}

# Close issue
def "main close" [
  issue_number: number # The id of the issue to view
  --service: string # Which service to use (see `services`)
  --merge # Merge development branch, if one exists, before closing issue
] {
  if $merge {
    let issue_branch = (get-issue-branch $issue_number)

    mut has_stashed_changes = false

    if (git branch --show-current) == $issue_branch {
      if (git status --short | is-not-empty) {
        return $"($issue_branch) contains uncommitted changes."
      }

      git switch trunk
    } else {
      $has_stashed_changes = (
        (
          git stash --message $issue_branch
          | complete
          | get stdout
        ) != "No local changes to save"
      )
    }

    git merge $issue_branch

    if $has_stashed_changes {
      git stash pop
    }
  }

  let args = [issue close $issue_number]

  match (get-service $service) {
    "github" => (gh ...$args)
    "gitlab" => (glab ...$args)
    _ => (nb do $issue_number)
  }
}

def get-project-prefix [] {
  $"(pwd | path basename)/"
}

# Create issue
def "main create" [
  --service: string # Which service to use (see `services`)
] {
  let args = [issue create]

  match (get-service $service) {
    "github" => (gh ...$args --editor)
    "gitlab" => (glab ...$args)

    _ => {
      let title = (input "Enter title: ")

      nb todo add --title $"(get-project-prefix)($title)"
    }
  }
}

# Create/open issue and development branch
def "main develop" [
  issue_number: number # The id of the issue to view
  --service: string # Which service to use (see `services`)
] {
  match (get-service $service) {
    "github" => (gh issue develop --checkout $issue_number)

    _ => {
      let issues = (main $issue_number --service $service)

      try {
        let issue = (
          $issues
          | ansi strip
          | lines
          | split column "[ ] "
        )

        let id = (
          $issue
          | get column1
          | split row "["
          | split row "]"
          | get 1
        )

        let title = (
            $issue
            | get column2
          | first
          | str replace (get-project-prefix) ""
        )

        git switch --create $"($id)-($title)"
      }
    }
  }
}

# Edit issue
def "main edit" [
  issue_number: number # The id of the issue to view
  --service: string # Which service to use (see `services`)
] {
  match (get-service $service) {
    "github" => (gh issue edit $issue_number)
    "nb" => (nb edit $issue_number)
  }
}

def list [web: bool service?: string] {
  let service = (get-service $service)
  mut args = [issue list]

  let args = if $web and ($service == github) {
    $args
    | append "--web"
  } else {
    $args
  }

  match $service {
    "github" => (gh ...$args)

    "gitlab" => {
      if $web {
        print-warning "`--web` not implemented for GitLab's `issue list`."
      }

      glab ...$args
    }

    _ => {
      nb todo $"(get-project-prefix)*"
    }
  }
}

def "main list" [
  --service: string # Which service to use (see `services`)
  --web # Open the remote repository website in the browser
] {
  list $web $service
}

# List available services
def "main services" [] {
  print ([github gitlab nb] | str join "\n")
}

# View issues
def "main view" [
  issue_number: number # The id of the issue to view
  --service: string # Which service to use (see `services`)
  --web # Open the remote repository website in the browser
] {
  if $web {
    main $issue_number --service $service --web
  } else {
    main $issue_number --service $service
  }
}

# View issues
def main [
  issue_number?: number # The id of the issue to view
  --service: string # Which service to use (see `services`)
  --web # Open the remote repository website in the browser
] {
  if ($issue_number | is-empty) {
    list $web $service

    return
  }

  mut args = [issue view $issue_number]

  let args = if $web {
    $args
    | append "--web"
  } else {
    $args
  }

  match (get-service $service) {
    "github" => (gh ...$args)
    "gitlab" => (glab ...$args)

    _ => {
      let repo_issues = (
        nb todo $"(get-project-prefix)*"
      )

      if (
          $repo_issues
          | ansi strip
          | find $"[($issue_number)]"
          | is-not-empty
      ) {
        nb todo $issue_number
      }
    }
  }
}
