#!/usr/bin/env nu

# View repository analytics
def main [] {
  tokei --hidden --sort lines
}
