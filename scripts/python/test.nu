#!/usr/bin/env nu

# Run tests
def main [] {
    uv run coverage run -m pytest tests
}
