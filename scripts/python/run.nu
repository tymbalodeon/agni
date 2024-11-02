#!/usr/bin/env nu

use ./command.nu

def main [...args: string] {
    if "help" in $args {
        help main
    } else {
        uv run (command) ...$args
    }
}
