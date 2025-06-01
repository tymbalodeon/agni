#!/usr/bin/env nu

def main [
  path?: string # A path to search for keywords
] {
  try {
    if ($path | is-not-empty) {
      rg TODO $path
    } else {
      rg TODO
    }
  }
}
