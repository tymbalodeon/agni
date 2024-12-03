#!/usr/bin/env nu

use domain.nu
use environment.nu get-project-root

# Close issue
def "main close" [issue_number: number] {
  match (domain) {
    "github" => (gh issue close $issue_number)
    "gitlab" => (glab issue close $issue_number)
  }
}

# Create issue
def "main create" [] {
  match (domain) {
    "github" => (gh issue create --editor)
    "gitlab" => (glab issue create)
  }
}

# Create/open issue and development branch
def "main develop" [issue_number: number] {
  match (domain) {
    "github" => (gh issue develop --checkout $issue_number)

    "gitlab" => (
      print "Feature not implemented for GitLab."

      exit 1
    )
  }
}

# View issues
def main [
  issue_number?: number # The number of the issue to view
  --domain: string
  --web # Open the remote repository website in the browser
] {
  let domain = match $domain {
    null => (domain)
    _ => $domain
  }

  match $domain {
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
        nb todo (get-project-root | path basename)
      )

      if ($issue_number | is-empty) {
        $repo_issues
      } else if ($repo_issues | find $issue_number | is-not-empty) {
        nb todo $issue_number
      }
    }
  }
}
