set shell := ["nu", "-c"]

_help:
    #!/usr/bin/env nu

    (
        just --list
            --color always
            --list-heading (
                [
                    "Available recipes:"
                    "(run `<recipe> --help/-h` for more info)\n"
                ]
                | str join " "
            )
    )

alias source := src

# Display the source code for a recipe
src recipe *args="_":
    #!/usr/bin/env nu

    # Display the source code for a recipe. If no args are provided, display
    # the raw `just` code, otherwise display the code with the args provided
    # to `just` applied. Pass `""` as args to see the code when no args are
    # provided to a recipe, and to see the code with `just` variables expanded.
    def src [
        recipe: string # The recipe command
        ...args: string # Arguments to the recipe
    ] {
        if "_" in $args {
            just --show $recipe
        } else {
            just --dry-run $recipe $args
        }
    }

    src {{ recipe }} `{{ args }}`

# Search available `just` commands
[no-exit-message]
find *regex:
    #!/usr/bin/env nu

    # Search available `just` commands interactively, or by <regex>
    def find [
        regex?: string # Regex pattern to match
    ] {
        if ($regex | is-empty) {
            just --list | fzf
        } else {
            just | grep --color=always --extended-regexp $regex
        }
    }

    find {{ regex }}

get-pyproject-value := "open pyproject.toml | get project."
application-command := "(" + get-pyproject-value + "name)"

[no-exit-message]
_install_and_run *command:
    #!/usr/bin/env nu

    let command = (
        echo `{{ command }}`
        | split row --regex "sudo pdm run |pdm run "
        | last
        | split words
        | filter { |arg| $arg != "pdm" }
        | first
    )

    if not ($command in (pdm list --fields name --csv)) {
        if $command == {{ application-command }} {
            just install --prod
        } else {
            just install
        }
    }

    {{ command }}

# Add dependencies
add *args:
    #!/usr/bin/env nu

    # Add dependencies
    def add [
        ...dependencies: string, # Dependencies to add
        --dev # Add dependencies to the development group
    ]: {
        if $dev {
            pdm add --dev ...$dependencies
        } else {
            pdm add ...$dependencies
        }
    }

    add {{ args }}

use-list-dependencies := """
    def list-dependencies [
        --dev
        --prod
        --include-version
    ] {
        let export = if $dev {
            pdm export --pyproject --no-default
        } else if $prod {
            pdm export --pyproject --prod
        } else {
            pdm export --pyproject
        }

        mut dependencies = $export
            | lines
            | filter {
                |line|

                (
                    (not ($line | is-empty))
                    and (not ($line | str starts-with "#"))
                )
            }

        if not $include_version {
            $dependencies = (
                $dependencies
                | each {
                    |dependency|

                    $dependency | split row ">=" | first
                }
            )
        }

        $dependencies | str join "\n"
    }
"""

# Remove dependencies
remove *args:
    #!/usr/bin/env nu

    {{ use-list-dependencies }}

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
    def remove [
        ...dependencies: string # Dependencies to remove
    ] {
        for $dependency in $dependencies {
            if (is-a-dependency $dependency --dev) {
                pdm remove --dev $dependency
            } else if (is-a-dependency $dependency) {
                pdm remove $dependency
            }
        }
    }

    remove {{ args }}

_get-application-version:
    #!/usr/bin/env nu

    open $"{{ application-command }}/__init__.py"
    | split row " "
    | last
    | str replace --all '"' ""

# Install dependencies
install *args:
    #!/usr/bin/env nu

    def not-installed [command: string] {
        (command -v $command | is-empty)
    }

    def module-not-installed [command: string] {
        (
            pdm run python -m $command --help err> /dev/null
            | complete
            | get exit_code
            | into bool
        )
    }

    # Install dependencies
    def install [
        --app # (Build and) install the application
        --dry-run # Display dependencies without installing
        --minimal # Install only dependencies necessary for other commands
        --prod # Install production dependencies only
    ] {
        if $dry_run {
            if $app or $prod {
                just dependencies --prod
            } else {
                just dependencies
            }

            exit
        }

        if not $prod {
            if (module-not-installed pip) {
                pdm run python -m ensurepip --upgrade --default-pip
            }

            if (module-not-installed pipx) {
                pdm run python -m pip install --upgrade pip pipx;
                pdm run python -m pipx ensurepath
            }

            if (not-installed speedscope) { pnpm add --global speedscope }

            if (not-installed cargo) {
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
            }

            if (not-installed cargo) { cargo install checkexec }
        }

        if $minimal {
            just _install_and_run pdm run pre-commit install out+err> /dev/null
        } else {
            if $app or $prod {
                pdm install --prod
            } else {
                pdm install
                just _install_and_run pdm run pre-commit install
            }
        }

        if $app {
            just build
            let application_version = (just _get-application-version)

            (
                pdm run python -m pipx install
                    $"./dist/{{ application-command }}-($application_version)-py3-none-any.whl"
                    --force
                    --pip-args="--force-reinstall"
            )
        }
    }

    install {{ args }}

alias update := upgrade

# Update dependencies
upgrade *args:
    #!/usr/bin/env nu

    # Update dependencies
    def upgrade [
        --prod # Update production dependencies
    ] {
        if $prod {
            just install --minimal --prod
        } else {
            just install --minimal
        }

        if not $prod {
            pdm run python -m pip install --upgrade pip pipx
            pnpm update --global speedscope
            rustup update
            cargo install-update checkexec
        }

        if $prod {
            pdm update --prod
        } else {
            pdm update
        }

        just check --update
    }

    upgrade {{ args }}

# Show application dependencies
dependencies *args:
    #!/usr/bin/env nu

    {{ use-list-dependencies }}

    def indent [text: string] {
        $text
        | lines
        | each { |line| $"\t($line)" }
        | str join "\n"
    }

    # Show application dependencies
    def show-dependencies [
        --dev # Show only development dependencies
        --prod # Show only production dependencies
        --installed # Show installed dependencies (python dependencies only)
        --tree # Show installed dependencies as a tree (python dependencies only)
        --licenses # Show dependency licenses
        --sort-by-license # [If --licenses] Sort by license
    ] {
        if $tree {
            pdm list --tree
            exit
        }

        if $installed {
            (
                pdm list
                    --fields name,version
                    --sort name
            )

            exit
        }

        if $licenses {
            mut dependencies = (
                if $dev {
                    pdm list --fields name,licenses --json --include dev
                } else if $prod {
                    pdm list --fields name,licenses --json --exclude dev
                } else {
                    pdm list --fields name,licenses --json
                }
                | from json
                | rename name license
            )

            $dependencies = if $sort_by_license {
                $dependencies | sort-by license
            } else {
                $dependencies | sort-by name
            }

            print $dependencies
            exit
        }

        let dependencies = if $dev {
            list-dependencies --include-version --dev
        } else if $prod {
            (
                (list-dependencies --include-version --prod)
                + "\n\n"
            )
        } else {
            let prod_dependencies = (
                indent (list-dependencies --include-version --prod)
            )

            let dev_dependencies = (
                indent (list-dependencies --include-version --dev)
            )

            (
                [
                    Production:
                    $prod_dependencies
                    ""
                    Development:
                    $dev_dependencies
                ]
                | str join "\n"
            )
        }

        if (command -v bat | is-empty) {
            just install
        }

        let bat_command = (
            "bat --language pip --plain --theme gruvbox-dark"
        )
        zsh -c $"print \"($dependencies)\" | ($bat_command)"
    }

    show-dependencies {{ args }}

# Run pre-commit hooks
check *args:
    #!/usr/bin/env nu

    # Run pre-commit hook by name, all hooks, or update all hooks
    def check [
        hook?: string # The hook to run
        --list # List all hook ids
        --update # Update all pre-commit hooks
    ] {
        if $list {
            print (
                grep id .pre-commit-config.yaml
                | str replace --all --regex "- +id:" ""
                | lines
                | each { |line| ($line | str trim) }
                | sort
                | str join "\n"
            )

            return
        }

        if $update {
            just _install_and_run pdm run pre-commit autoupdate

            return
        }

        if not ($hook | is-empty) {
            just _install_and_run pdm run pre-commit run $hook --all-files
        } else {
            just _install_and_run pdm run pre-commit run --all-files
        }
    }

    check {{ args }}

# Open an interactive python shell
shell *args:
    #!/usr/bin/env nu

    # Open an interactive python shell
    def shell [] {
        just _install_and_run pdm run bpython
    }

    shell {{ args }}

# Run the application
run *args:
    #!/usr/bin/env nu

    let args = (
        ["{{ args }}"]
        | split row " "
        | each { |arg| $"\"($arg)\"" }
        | str join " "
    )

    if $args == '""' {
        just _install_and_run pdm run {{ application-command }}
    } else {
        just _install_and_run pdm run {{ application-command }} $"`($args)`"
    }

# Profile a command and view results
profile *args:
    #!/usr/bin/env nu

    # Profile a command and view results
    def profile [
        ...args: string # Arguments to the command being profiled
    ] {
        just install --minimal

        let output_directory = "profiles"
        mkdir $output_directory

        let output_file = $"($output_directory)/profile.json"

        (
            just _install_and_run sudo pdm run py-spy record
                --format speedscope
                --output $output_file
                --subprocesses
                -- pdm run python -m {{ application-command }} $args
        )

        speedscope $output_file
    }

    profile {{ args }}

# Run coverage report
coverage *args:
    #!/usr/bin/env nu

    # Run coverage report
    def coverage [
        --fail-under: string # Fail if coverage is less than this percentage
    ] {
        just test out+err> /dev/null

        if not ($fail_under | is-empty) {
            (
                just _install_and_run pdm run coverage report -m
                    --skip-covered
                    --sort "cover"
                    --fail-under $fail_under
            )
        } else {
            (
                just _install_and_run pdm run coverage report -m
                    --skip-covered
                    --sort "cover"
            )
        }
    }

    coverage {{ args }}

# Run tests
test *args:
    #!/usr/bin/env nu

    # Run tests
    def test [] {
        just _install_and_run pdm run coverage run -m pytest tests
    }

    test {{ args }}

# Build and install the application
build *args:
    #!/usr/bin/env nu

    # Build and install the application
    def build [] {
        let application_command = {{ application-command }}
        let version = just _get-application-version
        let file_name = $"($application_command)-($version)"

        let extensions = [
            "-py3-none-any.whl"
            ".tar.gz"
        ]

        let dependencies = $"($application_command)/**/*.py"

        for extension in $extensions {
            checkexec $"dist/($file_name)($extension)" $dependencies -- pdm build
        }
    }

    build {{ args }}

generated_files := """
[
    [Option "Files to clean"];
    [<default> "<all EXCEPT dist and venv>"]
    [--all <all>]
    [coverage .coverage/]
    [dist [dist/ .pdm-build/]]
    [ds-store **/.DS_Store]
    [lilypond **/*-matrices.ly]
    [pdfs **/*.pdf]
    [profiles profiles/]
    [pycache **/__pycache__/]
    [pytest .pytest_cache/]
    [venv [.pdm-python .venv/]]
]
"""

# Remove generated files
clean *args:
    #!/usr/bin/env nu

    # Remove generated files
    def clean [
        --options, # Display possible values for ...(files)
        --all (-a), # Clean all files
        ...files: string # Which files to clean (see --options for available files)
    ] {
        if ($options) {
            print ({{ generated_files }} | table --expand)
            exit
        }

        let default_files_to_clean = [
            coverage
            ds-store
            lilypond
            pdfs
            profiles
            pycache
            pytest
        ]

        let files_to_clean = if $all {
            $default_files_to_clean | append [dist venv] | sort
        } else if ($files | is-empty) {
            $default_files_to_clean
        } else {
            $files
        }

        for file in $files_to_clean {
            let files_list = (
                {{ generated_files }}
                | where Option == $file
                | get "Files to clean"
                | flatten
            )

            if ($files_list | is-empty) {
                print $"Unknown option: \"($file)\""
                continue
            }

            if $file == "venv" and (
                not (command -v pdm | is-empty)) and (
                not (pdm run command -v pre-commit | is-empty)
            ) {
                pdm run pre-commit uninstall
            }

            for glob in ($files_list) {
                rm --recursive --force $glob
            }
        }
    }

    clean {{ args }}

# Release a new version of the application
release *args:
    #!/usr/bin/env nu

    # Release a new version of the application
    def release [
        target: string # Type of release to target (major, minor, or patch)
        --preview # Preview new additions to the CHANGELOG without modifyiing anything
    ] {
        let current_version_numbers = just _get-application-version | split row "."

        mut major = ($current_version_numbers.0 | into int)
        mut minor = ($current_version_numbers.1 | into int)
        mut patch = ($current_version_numbers.2 | into int)

        if not ($target in [major minor patch]) {
            print (
                [
                    $"\"($target)\" is not a valid release target."
                     "<target> must be one of: {major, minor, patch}"
                ]
                | str join " "
            )

            exit 1
        }

        if not ((git branch --show-current) == "main") {
            print "Can only release from the main branch."
            exit 1
        }

        if not (git status --short | is-empty) {
            print "Please commit all changes before releasing."
            exit 1
        }

        if not $preview {
            just check
        }

        if $target == "major" {
            $major += 1
            $minor = 0
            $patch = 0
        } else if $target == "minor" {
            $minor += 1
            $patch = 0
        } else if $target == "patch" {
           $patch += 1
        }

        let new_version = ([$major $minor $patch] | str join ".")

        if $preview {
            git-cliff --unreleased --tag $new_version
            exit
        }

        let init_file = $"{{ application-command }}/__init__.py"
        let current_version = $current_version_numbers | str join "."
        let files = [$init_file tests/main_test.py]

        for file in $files {
            (
                open $file
                | str replace $current_version $new_version
                | save --force $file
            )
        }

        git-cliff --unreleased --tag $new_version --prepend CHANGELOG.md
        git add $files CHANGELOG.md
        git commit --message $"chore\(release\): bump version to ($new_version)"
        git tag $"v($new_version)"
        git push --follow-tags
        just install --app
    }

    release {{ args }}

# Open the repository page in the browser
@repo:
    gh browse

# List repository issues
@issues:
    gh issue list

# Create issue interactively or view issue by <id>
issue *args:
    #!/usr/bin/env nu

    # Create issue interactively or view issue by <id>
    def issue [
        id?: string # The ID of the issue to view
        --web # View the issue in the browser
    ] {
        if $id == null {
            gh issue create
        } else if $web {
            gh issue view $id --web
        } else {
            gh issue view $id
        }
    }

    issue {{ args }}

# Show project statistics
stats *args:
    #!/usr/bin/env nu

    # Show project statistics
    def stats [
        --code # Show stats about the project code
        --git # Show stats related to git activity
    ] {
        let default = not ([$code $git] | any { |arg| $arg })

        if $default or $git {
            onefetch
        }

        if $default or $code {
            tokei --sort code
        }
    }

    stats {{ args }}

notate_reference_passage := """
just run \
    passage examples/lonely-child-notes.ily \
    --no-display \
    --notate \
    --save
"""
notate_ensemble_passage := """
just run \
    passage examples/lonely-child-notes.ily \
    --full-score \
    --no-display \
    --notate \
    --save
"""

# Run using an example score
example *args:
    #!/usr/bin/env nu

    # Generate matrices for the example score (Claude Vivier's "Lonely Child")
    def example [
        --input, # Open the compiled input file
        --generated, # Open all generated files (reference and ensemble)
        --reference, # Open the generated reference file
        --ensemble, # Open the generated full score file
        --force, # Force score generation even if the files are up to date
    ] {
        let default = (
            [$input $generated $reference $ensemble]
            | all { |arg| not $arg }
        )

        let input_file_name = "examples/lonely-child"

        let reference_pdf = (
            "examples/claude-vivier-lonely-child-reference-matrices.pdf"
        )

        let ensemble_pdf = (
            "examples/claude-vivier-lonely-child-ensemble-matrices.pdf"
        )

        let input_pdf = $"($input_file_name).pdf"
        mut pdf_files = []

        if $default or $input {
            let input_ly = $"($input_file_name).ly"

            if $force {
                lilypond -o examples $input_ly
                mv --force $"($input_file_name)-formatted.pdf" $input_pdf
            } else {
                (
                    checkexec $input_pdf $input_ly --
                        lilypond -o examples $input_ly
                )

                (
                    checkexec $input_pdf $input_ly
                        -- mv $"($input_file_name)-formatted.pdf" $input_pdf
                )
            }

            $pdf_files = ($pdf_files | append $input_pdf)
        }

        if $default or $reference or $generated {
            if $force {
                {{ notate_reference_passage }}
            } else {
                (
                    checkexec $reference_pdf $"($input_file_name)*.ily"
                        -- {{ notate_reference_passage }}
                )
            }

            $pdf_files = ($pdf_files | append $reference_pdf)
        }

        if $default or $ensemble or $generated {
            if $force {
                {{ notate_ensemble_passage }}
            } else {
                (
                    checkexec $ensemble_pdf $"($input_file_name)*.ily"
                        -- {{ notate_ensemble_passage }}
                )
            }

            $pdf_files = ($pdf_files | append $ensemble_pdf)
        }

        for file in $pdf_files {
            ^open $file
        }
    }

    example {{ args }}
