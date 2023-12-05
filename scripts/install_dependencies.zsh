#!/usr/bin/env zsh

dependencies=(
    "brew"
    "just"
    "nu"
)

install_dependency() {
    echo "Installing ${1}..."

    case ${1} in
        "brew")
            curl -fsSL \
                "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
            ;;
        "just")
            brew install just
            ;;
        "nu")
            brew install nu
            ;;
    esac
}

upgrade_dependency() {
    case ${1} in
        "brew")
            brew update
            ;;
        "just")
            brew upgrade just
            ;;
        "nu")
            brew upgrade nu
            ;;
    esac
}

for dependency in "${dependencies[@]}"; do
    if ! command -v "${dependency}" &>/dev/null; then
        install_dependency "${dependency}"
    fi
done

IFS=" " read -r -A ARGS <<< "$@"

if ! ((${ARGS[(I)*--update*]})); then
    exit
fi

for dependency in "${dependencies[@]}"; do
    upgrade_dependency "${dependency}"
done
