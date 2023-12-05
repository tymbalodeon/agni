def "main install" [] {
    if (command -v pnpm | is-empty) {
        brew install pnpm
    }
}

def "main update" [] {
    brew upgrade pnpm
}

def main [] {}
