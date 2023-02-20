# Agni

Music compositional tools inspired by the techniques of [Claude Vivier](https://www.boosey.com/composer/Claude+Vivier "Claude Vivier").

"Agni" is a character from Vivier's opera [_Kopernikus_](https://www.boosey.com/cr/music/Claude-Vivier-Kopernikus/47743 "Kopernikus"):

> The main character is Agni; mystical beings borrowed from stories (represented
> by the other six singers) gravitate around her: Lewis Carroll, Merlin, a witch,
> the Queen of the Night, a blind prophet, an old monk, Tristan and Isolde,
> Mozart, the Master of the Waters, Copernicus and his mother. These characters
> could be Agni’s dreams that follow her during her initiation and finally into
> her dematerialization.
>
> \- Claude Vivier

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

Vivier's [_Lonely Child_](https://www.boosey.com/cr/music/Claude-Vivier-Lonely-Child/47752 "Lonely Child")
is provided as an example.

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
- `example *args*`: Run example if output is nonexistent or outdated (or if
  "--force-output"), then open input and output files (or only "--input" or
  "--output").
- `install`: Install dependencies.
- `profile *args`: Run the py-spy profiler on a command and its \<args\> and open
  the results with speedscope.
- `try *args`: Try a command using the current state of the files without
  building.

## Dependencies

Most dependencies can be installed via [pdm](https://pdm.fming.dev/latest/)
by running `pdm install`. The rest (listed below) can be installed by running
the included script: `./install_dependencies`. Or, if `just` is already
installed: `just install` to install the rest of the dependencies.

Required for generating pdfs:

- [LilyPond](https://lilypond.org/ "lilypond")

Recommended for development using `justfile` commands:

- [just](https://just.systems/man/en/ "just")
- [checkexec](https://github.com/kurtbuilds/checkexec "checkexec")
- [speedscope](https://github.com/jlfwong/speedscope "speedscope")
