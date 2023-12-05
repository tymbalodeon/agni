def "main install" [] {
    if (command -v speedscope | is-empty) {
        pnpm add --globall speedscope
    }
}

def "main update" [] {
    pnpm update --global speedscope
}

def main [] {}
