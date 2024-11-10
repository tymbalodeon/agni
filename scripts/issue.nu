#!/usr/bin/env nu

use ./domain.nu

# View issues
def main [
  issue_number?: number # The number of the issue to view
  --close # Close issue
  --create # Create issue
  --develop # Create development branch for issue
  --web # Open the remote repository website in the browser
] {
  let domain = (domain)
  match (domain) {
    "github" => {
      if $close {
        gh issue close $issue_number
      } else if $create {
        gh issue create --editor
      } else if $develop {
        gh issue develop --checkout $issue_number
      } else if ($issue_number | is-empty) {
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
      if $close {
        glab issue close $issue_number
      } else if $create {
        glab issue create
      } else if $develop {
        print "Feature not implemented for GitLab."

        exit 1
      } else if ($issue_number | is-empty) {
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
      let repo_name = (pwd | path basename)

      let todos = (
        nb todo $repo_name
        | lines
        | each {
            |line|

            $line
            | ansi strip
            | split row --regex '[\[\]0-9]'
            | last
            | str trim
        }
      )

      let new_todo = if ($repo_name in $todos)

      nb todo add --edit
    }
  }
}
