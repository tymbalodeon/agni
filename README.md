# Agni

Music compositional tools inspired by the techniques of Claude Vivier.

## Combination-Tone Matrix

The concept of a "Combination-Tone Matrix" comes from Bryan Christian's article,
["Combination-Tone Class Sets and Redefining the Role of les Couleurs in Claude Vivier’s Bouchara"](https://mtosmt.org/issues/mto.14.20.2/mto.14.20.2.christian.html).

Commands:

- `agni COMMAND -h`: See all available options for COMMAND.
- `agni matrix <bass> <melody>`: Generate a single matrix for a given bass
  and melody pitch, and display, notate, or play.
- `agni passage <input_file>`: Generate matrices for a given passage of bass
  and melody notes, and display or notate.

### Example (Lonely Child)

Vivier's _Lonely Child_ is provided as an example.

- `just example --input`: View an input file containing only the soprano melody
  and bass accompaniment.
- `just example --output`: View the input score harmonized with the associated
  matrices.
- `just example`: View both.

## Tasks

Task scripts are provided (using [`just`](https://just.systems/man/en/ "just"))
to facilitate development. Available commands:

- `just`: Show available commands
- `build *pip`: Build the project and install it using pipx, or optionally with
  pip ("--pip").
- `check *autoupdate`: Run pre-commit checks or autoupdate ("--autoupdate").
- `example *type`: Run an example passage and open the input score ("--input"),
  output score ("--output") or both.
- `install`: Install dependencies.
- `profile *args`: Run the py-spy profiler on a command and its \<args\> and open
  the results with speedscope.
- `try *args`: Try a command using the current state of the files without
  building.

## Dependencies

Most dependencies can be installed via [poetry](https://python-poetry.org/ "poetry")
by running `poetry install`. The rest (listed below) can be installed by running
the included script: `./install_dependencies`. Or, if `just` is already
installed: `just install` to install the rest of the dependencies.

Required for generating pdfs:

- [LilyPond](https://lilypond.org/ "lilypond")

Recommended for development using `justfile` commands:

- [just](https://just.systems/man/en/ "just")
- [checkexec](https://github.com/kurtbuilds/checkexec "checkexec")
- [speedscope](https://github.com/jlfwong/speedscope "speedscope")
