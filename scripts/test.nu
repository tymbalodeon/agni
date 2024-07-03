#!/usr/bin/env nu

# Run tests
export def main [] {
  pdm run coverage run -m pytest tests
}
