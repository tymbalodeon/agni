from pathlib import Path

from rich import print
from rich.markup import escape
from typer import Argument, Exit, Option, Typer

from agni import __version__

from .matrix import Matrix
from .matrix_pitch import DisplayFormat, PitchType, Tuning
from .notation import Notation
from .passage import Passage

agni = Typer(
    help="Create combination-tone matrices.",
    context_settings={"help_option_names": ["-h", "--help"]},
    no_args_is_help=True,
    rich_markup_mode="rich",
)


def display_version(version: bool):
    if version:
        print(f"agni {__version__}")
        raise Exit()


@agni.callback()
def callback(
    _: bool = Option(
        False,
        "--version",
        "-v",
        callback=display_version,
        help="Display version number.",
    ),
):
    return


pitch_choices = escape("[hertz|midi|lilypond]")
pitch_help = f"[bold yellow]{pitch_choices}[/bold yellow]"
multiples = Option(4, help="Number of multiples to calculate.")
pitch_type_option_name = "--pitch-type"
pitch_type_help = (
    "Set the display type for pitches. (If none is provided, the same"
    " type as the input pitches is used.)"
)
tuning = Option(
    Tuning.MICROTONAL.value, "--tuning", help="Set the tuning to quantize to."
)
display_format = Option(
    DisplayFormat.TABLE.value,
    "--display",
    help="Set the matrix display format.",
)
as_chord = Option(False, "--as-chord", help="Output matrix as a chord.")
notate = Option(False, "--notate", help="Notate matrix in a pdf score.")
save = Option(
    False,
    "--save",
    help=(
        "Save the notated score as a named file instead of an Abjad temporary"
        " score."
    ),
)
as_ensemble = Option(
    False, "--as-ensemble", help="Notate each note on its own staff."
)
display = Option(
    True, " /--no-display", help="Display the output in the terminal."
)


@agni.command()
def matrix(
    bass: str = Argument(..., help=pitch_help),
    melody: str = Argument(..., help=pitch_help),
    multiples: int = multiples,
    pitch_type: PitchType = Option(
        None, pitch_type_option_name, help=pitch_type_help
    ),
    tuning: Tuning = tuning,
    midi_input: bool = Option(
        False,
        "--midi-input",
        help="Set the input type (applies to numeric input only).",
    ),
    display_format: DisplayFormat = display_format,
    as_chord: bool = as_chord,
    notate: bool = notate,
    save: bool = save,
    as_ensemble: bool = as_ensemble,
    display: bool = display,
    play: bool = Option(False, "--play", help="Play matrix."),
):
    """Create combination-tone matrix from two pitches."""
    matrix = Matrix(
        bass,
        melody,
        multiples,
        pitch_type,
        tuning,
        display_format,
        midi_input=midi_input,
    )
    if notate:
        Notation(matrix, as_ensemble, tuning, save, as_chord).notate()
    if display:
        matrix.display()
    if play:
        matrix.play()


@agni.command()
def passage(
    input_file: Path = Argument(
        Path("examples/lonely-child-notes.ily"), help="LilyPond input file."
    ),
    multiples: int = multiples,
    pitch_type: PitchType = Option(
        PitchType.LILYPOND.value,
        pitch_type_option_name,
        help=pitch_type_help,
    ),
    tuning: Tuning = tuning,
    display_format: DisplayFormat = display_format,
    as_chord: bool = as_chord,
    notate: bool = notate,
    save: bool = save,
    as_ensemble: bool = as_ensemble,
    as_set: bool = Option(
        True, "--as-set/--all", help="Output unique matrices only."
    ),
    adjacent_duplicates: bool = Option(
        False,
        "--adjacent-duplicates/",
        help="Output adjacent duplicate matrices.",
    ),
    full_score: bool = Option(
        False,
        "--full-score",
        help="Output matrices as an ensemble score using the input rhythms.",
    ),
    display: bool = display,
):
    """Create combination-tone matrices for a two-voice passage."""
    if full_score:
        as_ensemble = True
        as_set = False
        adjacent_duplicates = True
    passage = Passage(
        input_file,
        multiples,
        pitch_type,
        tuning,
        display_format,
        as_set,
        adjacent_duplicates,
    )
    if notate:
        Notation(
            passage,
            as_ensemble,
            tuning,
            save,
            as_chord,
            full_score,
        ).notate()
    if display:
        passage.display()
