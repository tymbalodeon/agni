@_help:
    just --list

# Run pre-commit checks.
@check:
    poetry run pre-commit run -a

@_get_pyproject_value value:
    printf "%s" \
        "$(awk -F '[ =\"]+' '$1 == "{{value}}" { print $2 }' pyproject.toml)"

# Try a command using the current state of the files without building.
try *args:
    #!/usr/bin/env zsh
    command="$(just _get_pyproject_value "name")"
    poetry run "${command}" {{args}}

_get_wheel:
    #!/usr/bin/env zsh
    command="$(just _get_pyproject_value "name")"
    version="$(just _get_pyproject_value "version")"
    printf "%s" ./dist/"${command}"-"${version}"-py3-none-any.whl

# Build the project and pipx install it.
build:
    #!/usr/bin/env zsh
    poetry install
    poetry build
    wheel="$(just _get_wheel)"
    pipx install "${wheel}" --force --pip-args="--force-reinstall"

# Run an example passage and open just the input score ("--input") or input and output scores
example *type:
    #!/usr/bin/env zsh
    input_file_name=examples/lonely-child
    lilypond_file="${input_file_name}.ly"
    input_score="${input_file_name}.pdf"
    checkexec "${input_score}" examples/*.*ly \
        -- lilypond -o examples "${lilypond_file}"
    mv "${input_file_name}-formatted.pdf" "${input_score}" 2>/dev/null
    pdf_files=("${input_score}")
    if [ "{{type}}" != "--input" ]; then
        matrix_score=examples/matrix.pdf
        checkexec "${matrix_score}" "${lilypond_file}" \
            -- just try passage --notate --persist --full-score
        pdf_files+="${matrix_score}"
    fi
    open "${pdf_files[@]}"

# Install dependencies.
@install:
    ./install_dependencies
