#!/usr/bin/env nu

def main [] {
    open ../pyproject.toml 
    | get project.name
}
