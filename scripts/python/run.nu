#!/usr/bin/env nu

use ./command.nu

def main [...args: string] {
    if "help" in $args {
        return (help main)
    }

    uv run (command) ...$args
}
