use environment-activate.nu
use environment-revision.nu

export def main [
  inputs: list<string>
] {
  let current_revision = (environment-revision revision get)

  let current_revision = if ($current_revision | is-empty) {
    "trunk"
  } else {
    $current_revision
  }

  let update_environments = [environments env] | any {$in in $inputs}

  if ($inputs | is-empty) or $update_environments {
    let base_url = "https://raw.githubusercontent.com"

    let remote_url = (
      $"($base_url)/tymbalodeon/environments/($current_revision)"
    )

    let project_root = (git rev-parse --show-toplevel)

    http get $"($remote_url)/src/default/flake.nix"
    | save --force $"($project_root)/flake.nix"
  }

  if ($inputs | is-empty) {
    nix flake update
  } else {
    nix flake update ...$inputs
  }

  environment-activate
}
