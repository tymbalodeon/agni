#!/usr/bin/env nu

use domain.nu
use environment.nu get-project-root

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

# Close issue
def "main close" [
  issue_number: number # The id of the issue to view
  --service: string # Which service to use (see `list-services`)
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

  match (get-service $service) {
    "github" => (gh issue close $issue_number)
    "gitlab" => (glab issue close $issue_number)
    _ => (nb do $issue_number)
  }
}

def get-project-prefix [] {
  $"(get-project-root | path basename)/"
}

# Create issue
def "main create" [
  --service: string # Which service to use (see `list-services`)
] {
  match (get-service $service) {
    "github" => (gh issue create --editor)
    "gitlab" => (glab issue create)

    _ => {
      let title = (input "Enter title: ")

      nb todo add --title $"(get-project-prefix)($title)"
    }
  }
}

# Create/open issue and development branch
def "main develop" [
  issue_number: number # The id of the issue to view
  --service: string # Which service to use (see `list-services`)
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

# List available services
def "main list-services" [] {
  print ([github gitlab nb] | str join "\n")
}

# View issues
def "main view" [
  issue_number?: number # The id of the issue to view
  --service: string # Which service to use (see `list-services`)
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
  --service: string # Which service to use (see `list-services`)
  --web # Open the remote repository website in the browser
] {
  match (get-service $service) {
    "github" => {
      if ($issue_number | is-empty) {
        if $web {
          gh issue list --web
        } else {
          gh issue list
        }
      } else if $web {
        gh issue view $issue_number --web
      } else {
        gh issue view $issue_number
      }
    }

    "gitlab" => {
      if ($issue_number | is-empty) {
        if $web {
          print "`--web` not implemented for GitLab's `issue list`."
        }

        glab issue list
      } else if $web {
        glab issue view $issue_number --web
      } else {
        glab issue view $issue_number
      }
    }

    _ => {
      let repo_issues = (
        nb todo $"(get-project-prefix)*"
      )

      if ($issue_number | is-empty) {
        $repo_issues
      } else if (
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
