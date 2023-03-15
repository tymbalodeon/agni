@_help:
    just --list

pre_commit := "pdm run pre-commit"

# Run pre-commit checks or autoupdate ("autoupdate").
check *autoupdate:
    #!/usr/bin/env zsh
    if [ "{{autoupdate}}" = "autoupdate" ]; then
        {{pre_commit}} autoupdate
    else
        {{pre_commit}} run --all-files
    fi

@_get_pyproject_value value:
    printf "%s" \
        "$(awk -F '[ =\"]+' '$1 == "{{value}}" { print $2 }' pyproject.toml)"

@_get_command_name:
    just _get_pyproject_value "name"

# Try a command using the current state of the files without building.
try *args:
    #!/usr/bin/env zsh
    command="$(just _get_command_name)"
    pdm run "${command}" {{args}}

_get_wheel:
    #!/usr/bin/env zsh
    command="$(just _get_command_name)"
    version="$(just _get_pyproject_value "version")"
    printf "%s" ./dist/"${command}"-"${version}"-py3-none-any.whl

# Build the project and install it using pipx, or optionally with pip ("--pip").
build *pip:
    #!/usr/bin/env zsh
    pdm install
    pdm build
    wheel="$(just _get_wheel)"
    if [ "{{pip}}" = "--pip" ]; then
        pip install --user "${wheel}" --force-reinstall
    else
        pipx install "${wheel}" --force --pip-args="--force-reinstall"
    fi

# Run examples if outdated (or "--force") and open (with options: "--input", "--output", "--reference", "--ensemble").
example *args:
    #!/usr/bin/env zsh
    if [ -z "{{args}}" ]; then
        input="true"
        reference="true"
        ensemble="true"
    else
        if [[ "{{args}}" = *"--input"* ]]; then
                input="true"
        fi
        if [[ "{{args}}" = *"--output"* ]]; then
                reference="true"
                ensemble="true"
        elif [[ "{{args}}" = *"--reference"* ]]; then
                reference="true"
        elif [[ "{{args}}" = *"--ensemble"* ]]; then
                ensemble="true"
        fi
    fi
    input_file_name="examples/lonely-child"
    reference_pdf="examples/claude-vivier-lonely-child-reference-matrices.pdf"
    ensemble_pdf="examples/claude-vivier-lonely-child-ensemble-matrices.pdf"
    pdf_files=()
    if [ -n "${input}" ]; then
        input_pdf="${input_file_name}.pdf"
        input_ly="${input_file_name}.ly"
        checkexec "${input_pdf}" examples/*.*ly \
            -- lilypond -o examples "${input_ly}"
        mv "${input_file_name}-formatted.pdf" "${input_pdf}" 2>/dev/null
        pdf_files+="${input_pdf}"
    fi
    if [ -n "${reference}" ]; then
        checkexec "${reference_pdf}" "${input_file_name}"*.ily \
            -- just try passage --notate --save --no-display
        pdf_files+="${reference_pdf}"
    fi
    if [ -n "${ensemble}" ]; then
        checkexec "${ensemble_pdf}" "${input_file_name}"*.ily \
            -- just try passage --notate --save --full-score --no-display
        pdf_files+="${ensemble_pdf}"
    fi
    if [[ "{{args}}" = *"--force"* ]]; then
        if [ -n "${reference}" ]; then
            just try passage --notate --save
            pdf_files+="${reference_pdf}"
        fi
        if [ -n "${ensemble}" ]; then
            just try passage --notate --save --full-score
            pdf_files+="${ensemble_pdf}"
        fi
    fi
    if [ -n "${pdf_files[*]}" ]; then
        open "${pdf_files[@]}"
    fi

# Install (or "upgrade") external dependencies.
@install *upgrade:
    ./install_dependencies.zsh {{upgrade}}

# Run the py-spy profiler on a command and its <args> and open the results with speedscope.
profile *args:
    #!/usr/bin/env zsh
    output_directory="profiles"
    mkdir -p "${output_directory}"
    output_file="${output_directory}/profile.json"
    command="$(just _get_command_name)"
    sudo py-spy record -f speedscope -o "${output_file}" \
        -- pdm run python -m "${command}" {{args}}
    speedscope "${output_file}"

# Open a python shell with project dependencies available.
shell:
    #!/usr/bin/env zsh
    pdm run bpython

# Update project dependencies, pre-commit hooks, and lilypond file versions (or just the latter if "lilypond").
update *lilypond:
    #!/usr/bin/env zsh
    if [ -z "{{lilypond}}" ]; then
        pdm update
        {{pre_commit}} autoupdate
    fi
    get_lilypond_version() {
        version_text="$(lilypond --version)"
        first_line="$(echo "${version_text}" | head -1)"
        version_number="$(
            echo "${first_line}" | grep -o "[0-9]\.[0-9]\{2\}\.[0-9]"
        )"
        echo "${version_number}"
    }
    current_lilypond_version="$(get_lilypond_version)"
    for file in examples/**.ly; do
        file_version="$(grep -o "${current_lilypond_version}" "${file}")"
        [ -n "${file_version}" ]
        if [ -n "${file_version}" ] \
            && [ "${file_version}" != "${current_lilypond_version}" ]; then
            convert-ly --current-version --edit "${file}"
            rm -f "${file}"~
        else
            echo "\"${file}\" is already up to date."
        fi
    done
