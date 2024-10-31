use std assert

use ../environment.nu merge_gitignores

let generic_gitignore = ".config
.direnv
.envrc
.pdm-python
.venv"

let environment_gitignore = "*.pyc
.coverage
__pycache__/
build/
dist/"

let actual_gitignore = (
  merge_gitignores
    $generic_gitignore
    python
    $environment_gitignore
)

let expected_gitignore = ".config
.direnv
.envrc
.pdm-python
.venv

# python

*.pyc
.coverage
__pycache__/
build/
dist/
"

assert equal $actual_gitignore $expected_gitignore
