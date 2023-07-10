from pathlib import Path

from rich.markup import escape
from typer import Argument, Option, Typer

from agni import __version__

from .matrix import Matrix
from .matrix_pitch import DisplayFormat, PitchType, Tuning
from .notation import Notation
from .passage import Passage
from typer import Typer

couleurs = Typer(
    no_args_is_help=True,
    help="Couleurs",
    context_settings={"help_option_names": ["-h", "--help"]},
    add_completion=False,
)

pitch_choices = escape("[hertz|midi|lilypond]")
pitch_help = f"[bold yellow]{pitch_choices}[/bold yellow]"
multiples = Option(
    Matrix.DEFAULT_MULTIPLES, help="Number of multiples to calculate."
)
pitch_type_option_name = "--pitch-type"
pitch_type_help = (
    "Set the display type for pitches. (If none is provided, the same"
    " type as the input pitches is used.)"
)
tuning = Option(
    Tuning.MICROTONAL, "--tuning", help="Set the tuning to quantize to."
)
display_format = Option(
    DisplayFormat.TABLE,
    "--display-format",
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
output_directory = Option(
    Path("examples"),
    "--output-directory",
    help="If saving, the directory in which to save the output file.",
)
display = Option(
    True, " /--no-display", help="Don't show the output in the terminal."
)


@couleurs.command(no_args_is_help=True)
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
    output_directory: Path = output_directory,
    display: bool = display,
    play: bool = Option(False, "--play", help="Play matrix."),
):
    """Create combination-tone matrix from two pitches."""
    if as_chord and not notate:
        display_format = DisplayFormat.CHORD
    matrix = Matrix(
        bass,
        melody,
        multiples,
        pitch_type,
        tuning,
        display_format,
        midi_input=midi_input,
    )
    if display or not notate and not play:
        matrix.display()
    if notate:
        Notation(
            matrix, as_ensemble, tuning, save, as_chord, output_directory
        ).notate()
    if play:
        matrix.play()


@couleurs.command(no_args_is_help=True)
def passage(
    input_file: Path = Argument(None, help="LilyPond input file."),
    multiples: int = multiples,
    pitch_type: PitchType = Option(
        PitchType.LILYPOND,
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
    output_directory: Path = output_directory,
    full_score: bool = Option(
        False,
        "--full-score",
        help="Output matrices as an ensemble score using the input rhythms.",
    ),
    display: bool = display,
):
    """Create combination-tone matrices for a two-voice passage."""
    if as_chord and not notate:
        display_format = DisplayFormat.CHORD
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
    if display or not notate:
        passage.display()
    if notate:
        Notation(
            passage,
            as_ensemble,
            tuning,
            save,
            as_chord,
            output_directory,
            full_score,
        ).notate()
