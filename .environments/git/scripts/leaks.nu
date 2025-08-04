#!/usr/bin/env nu

# Check for leaked secrets
export def main [] {
  gitleaks git
}
