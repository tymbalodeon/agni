#!/usr/bin/env nu

use environment.nu "main upgrade"

# Update dependencies
def main [
  --upgrade-environment
] {
  if $upgrade_environment {
    ugprade
  }

  nix flake update
}
