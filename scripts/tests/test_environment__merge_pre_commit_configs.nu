use std assert

use ../environment.nu merge_pre_commit_configs

let generic_pre_commit_config = "repos:
  - repo: https://gitlab.com/vojko.pribudic.foss/pre-commit-update
    rev: v0.5.0
    hooks:
      - id: pre-commit-update
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.4
    hooks:
      - id: gitleaks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-merge-conflict
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
  - repo: https://github.com/DavidAnson/markdownlint-cli2
    rev: v0.14.0
    hooks:
      - id: markdownlint-cli2
        args:
          - --fix
  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.1.0
    hooks:
      - id: prettier
        types:
          - markdown
  - repo: https://github.com/kamadorueda/alejandra
    rev: 3.0.0
    hooks:
      - id: alejandra-system
  - repo: https://github.com/astro/deadnix
    rev: v1.2.1
    hooks:
      - id: deadnix
        args:
          - --edit
  - repo: local
    hooks:
      - id: flake-checker
        name: flake-checker
        entry: flake-checker
        language: system
        pass_filenames: false
      - id: justfile
        name: justfile
        entry: just --fmt --unstable
        language: system
        pass_filenames: false
      - id: statix
        name: statix
        entry: statix fix
        language: system
        pass_filenames: false
      - id: yamlfmt
        name: yamlfmt
        entry: yamlfmt
        language: system
        pass_filenames: false
  - repo: https://github.com/lycheeverse/lychee.git
    rev: v0.15.1
    hooks:
      - id: lychee
        args: [\"--no-progress\", \".\"]
        pass_filenames: false
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v3.4.0
    hooks:
      - id: conventional-pre-commit
        stages:
          - commit-msg
"

let environment_pre_commit_config = "repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-json
      - id: check-toml
      - id: pretty-format-json
        args:
          - --autofix
  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.1.0
    hooks:
      - id: prettier
        types:
          - json
  - repo: local
    hooks:
      - id: taplo
        name: taplo
        entry: taplo format
        language: system
"

let actual_pre_commit_conifg = (
  merge_pre_commit_configs
    $generic_pre_commit_config
    python
    $environment_pre_commit_config
)

let expected_pre_commit_config = "repos:
  - repo: https://gitlab.com/vojko.pribudic.foss/pre-commit-update
    rev: v0.5.0
    hooks:
      - id: pre-commit-update
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.4
    hooks:
      - id: gitleaks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-merge-conflict
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
  - repo: https://github.com/DavidAnson/markdownlint-cli2
    rev: v0.14.0
    hooks:
      - id: markdownlint-cli2
        args:
          - --fix
  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.1.0
    hooks:
      - id: prettier
        types:
          - markdown
  - repo: https://github.com/kamadorueda/alejandra
    rev: 3.0.0
    hooks:
      - id: alejandra-system
  - repo: https://github.com/astro/deadnix
    rev: v1.2.1
    hooks:
      - id: deadnix
        args:
          - --edit
  - repo: local
    hooks:
      - id: flake-checker
        name: flake-checker
        entry: flake-checker
        language: system
        pass_filenames: false
      - id: justfile
        name: justfile
        entry: just --fmt --unstable
        language: system
        pass_filenames: false
      - id: statix
        name: statix
        entry: statix fix
        language: system
        pass_filenames: false
      - id: yamlfmt
        name: yamlfmt
        entry: yamlfmt
        language: system
        pass_filenames: false
  - repo: https://github.com/lycheeverse/lychee.git
    rev: v0.15.1
    hooks:
      - id: lychee
        args: [\"--no-progress\", \".\"]
        pass_filenames: false
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v3.4.0
    hooks:
      - id: conventional-pre-commit
        stages:
          - commit-msg
  # python
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-json
      - id: check-toml
      - id: pretty-format-json
        args:
          - --autofix
  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.1.0
    hooks:
      - id: prettier
        types:
          - json
  - repo: local
    hooks:
      - id: taplo
        name: taplo
        entry: taplo format
        language: system
"

assert equal $actual_pre_commit_conifg $expected_pre_commit_config
