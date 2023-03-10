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

install_dependency() {
    case ${1} in
        "brew")
            curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
            ;;
        "just")
            brew install just
            ;;
        "lilypond")
            brew install lilypond
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
            pnpm add -g speedscope
            ;;
        "cargo")
            curl https://sh.rustup.rs -sSf | sh
            ;;
        "checkexec")
            cargo install checkexec
            ;;
    esac
}

for dependency in "${dependencies[@]}"; do
    if command -v "${dependency}" &>/dev/null; then
        echo "\"${dependency}\" installed."
    else
        echo "Installing ${dependency}..."
        install_dependency "${dependency}"
    fi
done
