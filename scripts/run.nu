#!/usr/bin/env nu

use ./command.nu

export def main [
  args: list<string>
] {
  pdm run (command) ...$args
}
