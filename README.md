# Agni

Music compositional tools inspired by the techniques of [Claude Vivier](
https://www.boosey.com/composer/Claude+Vivier "Claude Vivier").

"Agni" is a character from Vivier's opera [_Kopernikus_](
https://www.boosey.com/cr/music/Claude-Vivier-Kopernikus/47743 "Kopernikus"):

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
["Combination-Tone Class Sets and Redefining the Role of les Couleurs in
Claude Vivier’s Bouchara"](https://mtosmt.org/issues/mto.14.20.2/mto.14.20.2.christian.html).

### Matrix

Generate a single matrix for a bass frequency of 98 Hz and melody of 440 Hz:

``` sh
> agni couleurs matrix 98 440
                Combination-Tone Matrix (Hertz)

             0 x melody   1 x melody   2 x melody   3 x melody
  0 x bass                440.0        880.0        1,320.0
  1 x bass   98.0         538.0        978.0        1,418.0
  2 x bass   196.0        636.0        1,076.0      1,516.0
  3 x bass   294.0        734.0        1,174.0      1,614.0
```

By default, numeric input is assumed to be in Hertz, and the output will be
displayed in the same format as the input. Specify the "pitch type" explicitly
to change the output format to something dfferent:

``` sh
> agni couleurs matrix 98 440 --pitch-type lilypond
               Combination-Tone Matrix (Lilypond)

             0 x melody   1 x melody   2 x melody   3 x melody
  0 x bass                a'           a''          e'''
  1 x bass   g,           cqs''        b''          f'''
  2 x bass   g            eqf''        cqs'''       gqf'''
  3 x bass   d'           fs''         d'''         gqs'''
```

The output can also be shown in various forms. For example, you can display the
pitches as a "list," which makes it easy to copy the output into a LilyPond document:

``` sh
> agni couleurs matrix g, "a'" --display-format list
g, g d' a' cqs'' eqf'' fs'' a'' b'' cqs''' d''' e''' f''' gqf''' gqs'''
```

You can also display pitches stacked as a "chord." Here is the same matrix,
using midi number input, shown stacked as a chord:

``` sh
> agni couleurs matrix 43 69 --display-format chord
   Combination-Tone Matrix (Hertz)

  (3 x bass) + (3 x melody) = 336.0
  (2 x bass) + (3 x melody) = 293.0
  (3 x bass) + (2 x melody) = 267.0
  (1 x bass) + (3 x melody) = 250.0
  (2 x bass) + (2 x melody) = 224.0
  (0 x bass) + (3 x melody) = 207.0
  (3 x bass) + (1 x melody) = 198.0
  (1 x bass) + (2 x melody) = 181.0
  (2 x bass) + (1 x melody) = 155.0
  (0 x bass) + (2 x melody) = 138.0
  (3 x bass) + (0 x melody) = 129.0
  (1 x bass) + (1 x melody) = 112.0
  (2 x bass) + (0 x melody) = 86.0
  (0 x bass) + (1 x melody) = 69.0
  (1 x bass) + (0 x melody) = 43.0
```

You can also control the tuning quantization and number of multiples. Here is
the same matrix quantized to equal temperament, calculated up to only 3 multiples:

``` sh
> agni couleurs matrix 98 440 --tuning equal-tempered --multiples 3
          Combination-Tone Matrix (Hertz)

             0 x melody   1 x melody   2 x melody
  0 x bass                440          880
  1 x bass   98           538          978
  2 x bass   196          636          1,076
```

### Passage

An entire passage can be processed and matrices or harmonized scores can be
output to PDF via LilyPond.

#### Input Files

Abjad's LilyPondParser does not support all of LilyPond's syntax. Please see [Abjad's
documentation](
https://abjad.github.io/api/abjad/parsers/parser.html#abjad.parsers.parser.LilyPondParser
) for supported syntax that can be used in input files.

#### Example (Claude Vivier's Lonely Child)

Vivier's [_Lonely Child_](
https://www.boosey.com/cr/music/Claude-Vivier-Lonely-Child/47752 "Lonely Child"
) is provided as an example.

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
# Install brew, just, and nushell to be able to use `just` commands
./scripts/install_dependencies.zsh
```

``` sh
# Display all available just commands
just
```
