#!/usr/bin/env nu

# Run tests
def main [] {
    pdm run coverage run -m pytest tests
}
