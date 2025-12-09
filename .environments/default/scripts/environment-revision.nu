use print.nu print-error

def get-current-revision [flake="flake.nix"] {
  try {
    open $flake
    | find github:tymbalodeon/environments/
    | first
    | ansi strip
    | str trim
    | parse 'url = "github:tymbalodeon/environments/{revision}?dir=src";'
    | first
    | get revision
    | str trim
  } catch {
    ""
  }
}

export def "revision get" [] {
  let current_revision = (get-current-revision)

  if ($current_revision | is-not-empty) {
    $current_revision
  }
}

export def "revision list" [] {
  gh api repos/tymbalodeon/environments/branches
  | from json
  | append (
      gh api repos/tymbalodeon/environments/tags
      | from json
    )
  | get name
  | sort
  | to text --no-newline
}

export def "revision set" [
  revision: string
  source_flake="flake.nix"
] {
  try {
      (
        gh search commits
          --hash $revision
          --json commit
          --owner tymbalodeon
          --repo environments
          err> /dev/null
      )
      | from json
      | get --optional commit.tree.sha
      | append (
          gh api repos/tymbalodeon/environments/tags
          | from json
          | get --optional name
        )
  } catch {
    print-error $"invalid revision: \"($revision)\""

    return
  }

  let repo_url_base = "github:tymbalodeon/environments"

  open $source_flake
  | (
      str replace
        $"($repo_url_base)/(get-current-revision $source_flake)"
        $"($repo_url_base)/($revision)"
    )
  | save --force flake.nix
}
