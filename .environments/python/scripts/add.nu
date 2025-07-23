#!/usr/bin/env nu

use ../../default/scripts/cd-to-root.nu

def main [
  ...dependencies: string, # Dependencies to add
  --dev # Add dependencies to the development group
] {
  cd-to-root python

  if $dev {
    uv add --dev ...$dependencies
  } else {
    uv add ...$dependencies
  }
}
