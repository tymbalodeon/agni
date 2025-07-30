#!/usr/bin/env nu

# Check flake
export def main [] {
  nix flake check
}
