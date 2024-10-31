#!/usr/bin/env nu

# Initialize direnv environment
def main [] {
  if (which direnv | is-empty) {
    print "Direnv (https://direnv.net/) is not installed."
    print "Please install and try again."

    exit 1
  }

  echo "use flake" | save --force .envrc
  direnv allow
}
