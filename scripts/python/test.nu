#!/usr/bin/env nu

# Run tests
def main [] {
  uv run pytest tests
}
