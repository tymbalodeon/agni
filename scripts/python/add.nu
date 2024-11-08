#!/usr/bin/env nu

def main [
    ...dependencies: string, # Dependencies to add
    --dev # Add dependencies to the development group
] {
    if $dev {
        pdm add --dev ...$dependencies
    } else {
        pdm add ...$dependencies
    }
}
