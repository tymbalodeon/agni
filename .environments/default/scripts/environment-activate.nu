export def main [] {
  if (which direnv | is-empty) {
    nix develop
  } else {
    "use flake"
    | save --force .envrc

    direnv allow
  }
}
