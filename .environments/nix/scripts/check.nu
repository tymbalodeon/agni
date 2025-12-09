#!/usr/bin/env nu

# Check flake.lock
def main [] {
  nix flake check
}
