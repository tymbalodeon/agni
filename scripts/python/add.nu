#!/usr/bin/env nu

def main [
  ...dependencies: string, # Dependencies to add
  --dev # Add dependencies to the development group
] {
  if $dev {
    uv add --dev ...$dependencies
  } else {
    uv add ...$dependencies
  }
}
