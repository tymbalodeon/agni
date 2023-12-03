@_help:
    just --list

pre_commit := "pdm run pre-commit"

# Run pre-commit checks or "autoupdate".
check *autoupdate:
    #!/usr/bin/env zsh
    if [ "{{autoupdate}}" = "autoupdate" ]; then
        {{pre_commit}} autoupdate
    else
        {{pre_commit}} run --all-files
    fi

@_get_pyproject_value value:
    printf "$(awk -F '[ =\"]+' '$1 == "{{value}}" { print $2 }' pyproject.toml)"

@_get_command_name:
    just _get_pyproject_value "name"

# Try a command using the current state of the files without building.
try *args:
    #!/usr/bin/env zsh
    command="$(just _get_command_name)"
    pdm run "${command}" {{args}}

# Clean Python cache or generated pdfs.
clean *pdfs:
    #!/usr/bin/env zsh
    if [ "{{pdfs}}" = "pdfs" ]; then
        files=(**/**.pdf(N))
    else
        files=(**/**.pyc(N))
    fi
    if [ -z "${files[*]}" ]; then
        echo "No files found."
        exit
    fi
    for file in "${files[@]}"; do
        rm "${file}"
        echo "Removed ${file}."
    done

_get_wheel:
    #!/usr/bin/env zsh
    command="$(just _get_command_name)"
    version="$(just _get_pyproject_value "version")"
    printf "./dist/${command}-${version}-py3-none-any.whl"

# Build the project and install it using pipx, or optionally with pip ("--pip").
build *pip: install
    #!/usr/bin/env zsh
    pdm build
    wheel="$(just _get_wheel)"
    if [ "{{pip}}" = "--pip" ]; then
        pip install --user "${wheel}" --force-reinstall
    else
        pipx install "${wheel}" --force --pip-args="--force-reinstall"
    fi

notate_reference_passage := """
just try couleurs \
    passage examples/lonely-child-notes.ily \
    --no-display \
    --notate \
    --save"""

notate_ensemble_passage := """
just try couleurs \
    passage examples/lonely-child-notes.ily \
    --full-score \
    --no-display \
    --notate \
    --save"""

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
        else
            if [[ "{{args}}" = *"--reference"* ]]; then
                    reference="true"
            fi
            if [[ "{{args}}" = *"--ensemble"* ]]; then
                    ensemble="true"
            fi
            if [[ "{{args}}" = *"--force"* ]]; then
                force="true"
                if [ -z "${reference}" ] \
                    && [ -z "${ensemble}" ]; then
                    reference="true"
                    ensemble="true"
                fi
            fi
        fi
    fi
    input_file_name="examples/lonely-child"
    reference_pdf="examples/claude-vivier-lonely-child-reference-matrices.pdf"
    ensemble_pdf="examples/claude-vivier-lonely-child-ensemble-matrices.pdf"
    pdf_files=()
    input_pdf="${input_file_name}.pdf"
    if [ -n "${input}" ]; then
        input_ly="${input_file_name}.ly"
        checkexec "${input_pdf}" examples/*.*ly \
            -- lilypond -o examples "${input_ly}"
        mv "${input_file_name}-formatted.pdf" "${input_pdf}" 2>/dev/null
        pdf_files+="${input_pdf}"
    fi
    if [ -n "${reference}" ]; then
        checkexec "${reference_pdf}" "${input_file_name}"*.ily \
            -- {{notate_reference_passage}}
        pdf_files+="${reference_pdf}"
    fi
    if [ -n "${ensemble}" ]; then
        checkexec "${ensemble_pdf}" "${input_file_name}"*.ily \
            -- {{notate_ensemble_passage}}
        pdf_files+="${ensemble_pdf}"
    fi
    if [ -n "${force}" ]; then
        pdf_files+="${input_pdf}"
        if [ -n "${reference}" ]; then
            {{notate_reference_passage}}
            pdf_files+="${reference_pdf}"
        fi
        if [ -n "${ensemble}" ]; then
            {{notate_ensemble_passage}}
            pdf_files+="${ensemble_pdf}"
        fi
    fi
    if [ -n "${pdf_files[*]}" ]; then
        for file in "${pdf_files[@]}"; do
            if [ -f "${file}" ]; then
                open "${pdf_files[@]}" 2>/dev/null
            fi
        done
    fi

# Install (or "--upgrade") external dependencies.
@install *upgrade:
    ./install_dependencies.zsh {{upgrade}}
    pdm install

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
@shell:
    pdm run bpython

# Update project dependencies, pre-commit hooks, and lilypond file versions (or just the latter if "lilypond").
update *lilypond: (install "--upgrade")
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

coverage := "pdm run coverage"

# Run coverage report.
@coverage *args: test
    {{coverage}} report -m \
        --omit "*/pdm/*" \
        --skip-covered \
        --sort "cover" \
        {{args}}

# Run tests.
test *args:
    #!/usr/bin/env zsh
    if [ -z "{{args}}" ]; then
        args="tests"
    else
        args="{{args}}"
    fi
    {{coverage}} run -m pytest "${args}"

# Create a new virtual environment, overwriting an existing one if present.
venv:
    rm -f .pdm-python
    pdm venv create --force
