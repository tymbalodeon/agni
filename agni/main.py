from pathlib import Path

from rich.markup import escape
from typer import Argument, Option, Typer

from .matrix import InputType, Matrix
from .matrix_frequency import OutputType, Tuning
from .notation import Notation, Passage

agni = Typer(
    help="Create combination-tone matrices.",
    context_settings={"help_option_names": ["-h", "--help"]},
    no_args_is_help=True,
    rich_markup_mode="rich",
)

pitch_choices = escape("[hertz|midi|lilypond]")
pitch_help = f"[bold yellow]{pitch_choices}[/bold yellow]"
tuning = Option(
    Tuning.MICROTONAL.value, "--tuning", help="Set the tuning to quantize to."
)
multiples = Option(4, help="Number of multiples to calculate.")
output_type = Option(
    OutputType.LILYPOND.value, help="Set the output type for pitches."
)
as_chord = Option(False, "--as-chord", help="Output matrix as chord.")
as_ensemble = Option(
    False, "--as-ensemble", help="Notate each note on its own staff."
)
notate = Option(False, "--notate", help="Notated matrix.")
persist = Option(False, "--persist", help="Persist the notated score.")


@agni.command()
def matrix(
    bass: str = Argument(..., help=pitch_help),
    melody: str = Argument(..., help=pitch_help),
    input_type: InputType = Option(
        InputType.HERTZ.value,
        "--input-type",
        help="Set the input type for numeric input.",
    ),
    tuning: Tuning = tuning,
    multiples: int = multiples,
    output_type: OutputType = output_type,
    as_chord: bool = as_chord,
    notate: bool = notate,
    persist: bool = persist,
    as_ensemble: bool = as_ensemble,
    play: bool = Option(False, "--play", help="Play matrix."),
):
    """Create combination-tone matrix from two pitches."""
    matrix = Matrix(bass, melody, input_type=input_type, multiples=multiples)
    if notate:
        notation = Notation(matrix)
        notation.make_score(as_ensemble, tuning, persist, as_chord=as_chord)
    matrix.display(output_type, tuning)
    if play:
        matrix.play()


@agni.command()
def passage(
    input_file: Path = Argument(
        Path("examples/lonely-child-notes.ily"), help="LilyPond input file."
    ),
    tuning: Tuning = tuning,
    multiples: int = multiples,
    output_type: OutputType = output_type,
    as_chord: bool = as_chord,
    notate: bool = notate,
    persist: bool = persist,
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
        help="Output matrices as an ensemble score using the input rhythms.",
    ),
):
    """Create combination-tone matrices for a two-voice passage."""
    if full_score:
        as_ensemble = True
        as_set = False
        adjacent_duplicates = True
    passage = Passage(input_file)
    if notate:
        notation = Notation(
            *passage.get_matrices(multiples, as_set, adjacent_duplicates)
        )
        notation.make_score(
            as_ensemble,
            tuning,
            persist,
            as_chord=as_chord,
            full_score=full_score,
            passage=passage,
        )
    passage.display(
        output_type, tuning, multiples, as_set, adjacent_duplicates
    )
