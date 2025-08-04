#!/usr/bin/env nu

use ../../default/scripts/paths.nu get-paths

def main [
  ...paths: string # Files or directories to format
] {
  yamlfmt ...(get-paths $paths)
}
