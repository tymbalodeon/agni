def "main install" [] {
    if (command -v cargo | is-empty) {
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    }
}

def "main update" [] {
    rustup update
}

def main [] {}
