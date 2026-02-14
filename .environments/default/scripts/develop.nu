#!/usr/bin/env nu

use print.nu print-error
use print.nu print-warning

def get-current-bookmark [] {
  let bookmarks = (
    jj log --no-graph --template "bookmarks ++ '\n'"
    | lines
    | where {is-not-empty}
    | first
  )

  let bookmarks = ($bookmarks | split row " ")

  let bookmarks = if ($bookmarks | length) > 1 {
    let development_bookmarks = ($bookmarks | where {$in !~ trunk})

    if ($development_bookmarks | length) > 1 {
      print-error "multiple bookmarks are set to this revision. Please pass a value for $name."

      return
    } else {
      $bookmarks
    }
  } else {
    $bookmarks
  }

  $bookmarks
  | first
  | str replace * ""
  | str replace ?? ""
}

def is-empty-revision [revision?: string] {
  let revision = if ($revision | is-empty) {
    "@"
  } else {
    $revision
  }

  jj log --no-graph --revisions $revision --template "empty"
  | into bool
}

# Combine current revision with fetched revisions from the remote
def "main fetch" [] {
  let current_bookmark = (get-current-bookmark)

  jj git fetch
  
  if (is-empty-revision) {
    jj new $current_bookmark
  } else if (
    jj log --no-graph --revisions $"::@ & bookmarks\(($current_bookmark)\)"
    | is-empty
  ) {
    jj new @ $current_bookmark
  }
}

def get-revision-names [type: string] {
  jj $type list --template "name ++ '\n'"
  | lines
  | uniq
}

def get-remote-revision-names [type: string] {
  let args = [$type list --template "name ++ '\n'"]

  let args = if $type == bookmark {
    $args
    | append [--remote origin]
  } else {
    $args
  }

  jj ...$args
  | lines
  | uniq
}

def get-local-bookmarks [] {
  get-revision-names bookmark
  | append (get-revision-names tag)
}

def get-remote-bookmarks [] {
  get-remote-revision-names bookmark
  | append (get-remote-revision-names tag)
}

def get-all-bookmarks [] {
  get-local-bookmarks
  | append (get-remote-bookmarks)
  | uniq
  | sort
}

# Switch to a development revision
def main [
  name?: string # The name of the bookmark to switch to
  --choose # Choose the revision to switch to interactively
  --local # (with `--choose`) Choose from local bookmarks only
  --remote # (with `--choose`) Choose from remote bookmarks only
  --revision: string # Switch to this particular revision
] {
  let bookmarks = if $local {
    get-local-bookmarks
  } else if $remote {
    get-remote-bookmarks
  } else {
    get-all-bookmarks
  }

  let name = if ($name | is-not-empty) {
    $name
  } else {
    $bookmarks
    | to text
    | fzf
  }

  if ($name | is-empty) {
    return
  }

  if ($name not-in $bookmarks) {
    print-error $"unrecognized bookmark `($name)`"

    return
  }

  let revision = if ($revision | is-not-empty) {
    $revision
  } else {
    let revisions = (
      jj log
        --no-graph
        --revisions $"descendants\(($name)\)"
        --template "change_id ++ '•' ++ description ++ '\n'"
      | lines
      | where {is-not-empty}
      | each {
          |line|

          let parts = ($line | split row •)

          {
            change_id: $parts.0
            description: $parts.1
          }
        }
    )

    if $choose {
      if ($revisions | length) == 1 {
        $revisions
        | first
        | get change_id
      } else {
        $revisions
        | each {|revision| $"($revision.change_id) ($revision.description)"}
        | to text
        | fzf
        | split row " "
        | first
      }
    } else {
      $revisions
      | first
      | get change_id
    }
  }

  if ($revision | is-empty) {
    return
  }

  if (
    jj log --no-graph --revisions $revision --template "immutable"
    | into bool
  ) {
    jj new $revision
  } else {
    jj edit $revision
  }
}

# List local development bookmarks
def "main list" [] {
  get-local-bookmarks
  | to text --no-newline
}

# List remote development bookmarks
def "main list remote" [] {
  get-remote-bookmarks
  | to text --no-newline
}

# List all development bookmarks
def "main list all" [] {
  get-all-bookmarks
  | to text --no-newline
}

# Merge development branches into trunk
def "main merge" [
  name?: string # The name of the bookmark to sync with trunk
] {
  let bookmark = if ($name | is-empty) {
    get-current-bookmark
  } else {
    $name
  }

  if ($bookmark | is-empty) or $bookmark == trunk {
    return
  }

  main sync $bookmark
  jj bookmark set trunk --to $bookmark

  if (jj log --no-graph --revisions $bookmark --template "description" | is-empty) {
    jj describe --message $"chore: merge ($bookmark)"
  }

  jj bookmark delete $bookmark
  jj git push --bookmark trunk
  jj git push --deleted
}

# Create a new development branch
def "main new" [
  name?: string # The name of the bookmark to create
  --from: string # The revision to start from (defaults to the current revision)
  --issue: int # The issue ID of the issue whose name to use
] {
  let name = if ($name | is-empty) {
    let json = if ($issue | is-empty) {
      gh issue list --json title
      | from json
      | get title
      | to text
      | fzf
    } else {
      gh issue view --json title $issue
      | from json
      | get title
    }
  } else {
    $name
  }

  if ($from | is-not-empty) {
    jj new $from
  }

  if $name not-in (get-local-bookmarks) {
    jj bookmark create $name
    jj bookmark track $name
    jj describe --message $"chore: init ($name)"
    jj git push
  } else {
    print-warning $"bookmark ($name) already exists"
  }
}

# Set the current branch to the current revision
def --wrapped "main push" [
  ...description: string # Description to use for the commit
] {
  let current_bookmark = (get-current-bookmark)

  let sync_status = try {
    (
      jj bookmark list
        --revisions $current_bookmark
        --template "name ++ '|' ++ synced ++ '\n'"
    )
  } catch {
    return
  }

  if not (
    $sync_status
    | lines
    | uniq
    | first
    | split row "|"
    | last
    | into bool
  ) {
    jj git push
  }

  let revision = if (is-empty-revision) {
    "@-"
  } else {
    "@"
  }

  if (get-change-id $current_bookmark) == (get-change-id $revision) {
    return
  }

  let empty_revisions = (
    jj log
      --no-graph
      --revisions $"($current_bookmark)+::@ & empty\(\)"
      --template "change_id ++ '\n'"
    | lines
  )

  if ($empty_revisions | is-not-empty) {
    jj abandon ...$empty_revisions err> /dev/null
  }

  let descriptions = (
    jj log
      --no-graph
      --revisions $"($current_bookmark)::@"
      --template "change_id ++ '|' ++ description ++ '\n'"
    | lines
    | where {is-not-empty}
    | each {
        |line|

        let parts = ($line | split row "|")
        let change_id = $parts.0
        let description = ($parts | last)

        let description = if $description == $change_id {
          ""
        } else {
          $description
        }

        {
          change_id: $change_id
          description: $description
        }
      }
  )

  for revision in $descriptions {
    if ($revision.description | is-empty) {
      let described_ancestors = (
        $descriptions
        | where {$in != $revision and ($in.description | is-not-empty)}
      )

      if ($described_ancestors | is-not-empty) {
        let closest_described_revision_id = (
          $described_ancestors
          | first
          | get change_id
        )

        if (
          jj log
            --no-graph
            --revisions $closest_described_revision_id
            --template "immutable"
          | into bool
        ) {
          let message = if ($description | is-empty) {
            $"chore: push ($current_bookmark)"
          } else {
            $description
            | str join " "
          }

          jj describe --message $message $revision.change_id
        } else {
          jj squash --from $revision.change_id --into $closest_described_revision_id
        }
      }
    }
  }

  jj bookmark move --from "heads(::@ & bookmarks())" --to @

  if $revision == "@" {
    jj new
  }

  jj git push
}

# Remove development branches
def "main remove" [
  ...names: string # The names of the branches to remove
  --force # Skip confirmation before removing from remote
  --local # Only remove local branches
] {
  let bookmarks = (get-all-bookmarks)
  let names = ($names | where {$in != trunk and $in in $bookmarks})

  if ($names | is-empty) {
    return
  }

  if $local {
    jj bookmark forget ...$names
  } else {
    print "The following branches will be removed from the remote:"

    print (
      $names
      | each {$in | prepend '- ' | str join}
      | to text --no-newline
    )

    print "\n\(Use `--local` to remove them from the local repository only.\)\n"

    if (input "Proceed [y/N]? " | str downcase) == y {
      print ""

      jj bookmark track ...$names out+err> /dev/null
      jj bookmark delete ...$names
      jj git push --deleted
    }
  }
}

# Sync development branch with trunk
def "main sync" [
  name?: string # The name of the bookmark to sync with trunk
] {
  let bookmark = if ($name | is-empty) {
    get-current-bookmark
  } else {
    $name
  }

  if ($bookmark | is-empty) or $bookmark == trunk {
    return
  }

  jj rebase --branch $bookmark --onto trunk
}

def get-change-id [revision: string] {
  jj log --no-graph --revisions $revision --template "change_id"
}
