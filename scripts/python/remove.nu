#!/usr/bin/env nu

use ./deps.nu list-dependencies

def is-a-dependency [
    dependency: string
    --dev
] {
    let dependencies = if $dev {
        list-dependencies --dev
    } else {
        list-dependencies
    }

    $dependency in $dependencies
}

# Remove dependencies
def main [
    ...dependencies: string # Dependencies to remove
] {
    for $dependency in $dependencies {
        if (is-a-dependency $dependency --dev) {
            uv remove --dev $dependency
        } else if (is-a-dependency $dependency) {
            uv remove $dependency
        }
    }
}
