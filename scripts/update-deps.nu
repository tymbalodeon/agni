#!/usr/bin/env nu

# Update dependencies
def main [] {
    nix flake update
    pdm update
}
