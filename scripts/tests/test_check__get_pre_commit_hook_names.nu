use std assert

use ../check.nu get_pre_commit_hook_names

let config = "
repos:
  - repo: https://gitlab.com/vojko.pribudic.foss/pre-commit-update
    rev: v0.4.0post1
    hooks:
      - id: pre-commit-update
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-merge-conflict
      - id: check-yaml
      - id: end-of-file-fixer
      - id: sort-simple-yaml
      - id: trailing-whitespace
"

let expected_hooks = "check-merge-conflict
check-yaml
end-of-file-fixer
pre-commit-update
sort-simple-yaml
trailing-whitespace"

let actual_hooks = (get_pre_commit_hook_names ($config | from yaml))

assert equal $actual_hooks $expected_hooks
