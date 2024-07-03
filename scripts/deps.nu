#!/usr/bin/env nu

export def list-dependencies [
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
