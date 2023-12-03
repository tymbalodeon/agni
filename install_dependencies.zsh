#!/usr/bin/env zsh

dependencies=(
    "brew"
    "just"
    "lilypond"
    "pdm"
    "pipx"
    "pnpm"
    "speedscope"
    "cargo"
    "checkexec"
)

thoth_install_lilypond() {
    command -v thoth &>/dev/null \
        && thoth lilypond install latest-stable \
}

install_dependency() {
    case ${1} in
        "brew")
            curl -fsSL \
                "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
            ;;
        "just")
            brew install just
            ;;
        "lilypond")
            thoth_install_lilypond || brew install lilypond
            ;;
        "pdm")
            brew install pdm
            ;;
        "pipx")
            brew install pipx
            pipx ensurepath
            ;;
        "pnpm")
            brew install pnpm
            ;;
        "speedscope")
            pnpm add --global speedscope
            ;;
        "cargo")
            curl https://sh.rustup.rs -sSf | sh
            ;;
        "checkexec")
            cargo install checkexec
            ;;
    esac
}

upgrade_dependency() {
    case ${1} in
        "just")
            brew upgrade just
            ;;
        "lilypond")
            thoth_install_lilypond || brew upgrade lilypond
            ;;
        "pdm")
            brew upgrade pdm
            ;;
        "pipx")
            brew upgrade pipx &>/dev/null \
            || python3 -m pip install --user pipx
            ;;
        "pnpm")
            pnpm add --global pnpm
            ;;
        "speedscope")
            pnpm update --global speedscope
            ;;
        "checkexec")
            if [ -z "$(cargo --list \
                        | grep install-update &>/dev/null)" ]; then
                cargo install cargo-update
            fi
            cargo install-update checkexec
            ;;
    esac
}

for dependency in "${dependencies[@]}"; do
    if !command -v "${dependency}" &>/dev/null; then
        echo "Installing ${dependency}..."
        install_dependency "${dependency}"
    fi
done

IFS=" " read -r -A ARGS <<< "$@"

if ! ((${ARGS[(I)*--upgrade*]})); then
    exit
fi

for dependency in "${dependencies[@]}"; do
    upgrade_dependency "${dependency}"
done
