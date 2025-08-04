#!/usr/bin/env nu

# Check flake.lock
def main [] {
  nix run github:DeterminateSystems/flake-checker
}
