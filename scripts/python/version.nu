#!/usr/bin/env nu

def main [] {
  try {
    open pyproject.toml
    | get project.version
  }
}
