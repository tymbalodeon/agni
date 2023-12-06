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

_Currently commands are implemented for recreating Vivier's "couleurs" only._

``` sh
# Generate a single matrix for a given bass and melody pitch,
# and display, notate, or play.
agni couleurs matrix <bass> <melody>
```


``` sh
# Generate matrices for a given passage of bass and melody notes,
# and display or notate.
agni couleurs passage <input_file>
```

### Input files

Abjad's LilyPondParser does not support all of LilyPond's syntax. Please see [Abjad's
documentation](https://abjad.github.io/api/abjad/parsers/parser.html#abjad.parsers.parser.LilyPondParser) for supported syntax that can be used in input files.

### Example (Lonely Child)

Vivier's [_Lonely Child_](https://www.boosey.com/cr/music/Claude-Vivier-Lonely-Child/47752 "Lonely Child") is provided as an example.

_To install `just`, see the "Installation" instructions below._

``` sh
# View an input file containing only the soprano melody and bass accompaniment.
just example --input
```

``` sh
# View the input score harmonized with the associated matrices.
just example --output
```

``` sh
# View both
just example
```

## Quickstart

``` sh
# Install the necessary dependencies and run the application
./scripts/install_dependencies.zsh && just try
```

## Installation

``` sh
# Instal brew, just, and nu to be able to use `just` commands
./scripts/install_dependencies.zsh
```

``` sh
# Display all available just commands
just
```
