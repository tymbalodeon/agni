from pathlib import Path

from rich.markup import escape
from typer import Argument, Option, Typer

from .matrix import InputType, Matrix, Notation, OutputType, Tuning
from .passage.passage import get_passage_matrices
from .passage.read_passage import get_passage_from_input_file

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
as_ensebmle = Option(
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
    as_ensebmle: bool = as_ensebmle,
    play: bool = Option(False, "--play", help="Play matrix."),
):
    """Create combination-tone matrix from two pitches."""
    matrix = Matrix(bass, melody, input_type=input_type, multiples=multiples)
    if notate:
        matrix.notate(tuning, as_chord, persist, as_ensebmle)
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
    as_ensemble: bool = as_ensebmle,
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
    passage = get_passage_from_input_file(input_file)
    matrices = get_passage_matrices(
        passage,
        multiples=multiples,
        as_set=as_set,
        adjacent_duplicates=adjacent_duplicates,
    )
    if notate:
        if not full_score:
            notation_passage = None
        else:
            notation_passage = passage
        notation = Notation(*matrices)
        if as_ensemble:
            notation.make_ensemble_score(
                tuning,
                persist=persist,
                passage=notation_passage,
                full_score=full_score,
            )
        else:
            notation.make_reference_score(
                tuning,
                as_chord=as_chord,
                persist=persist,
                full_score=full_score,
            )
    for matrix in matrices:
        matrix.display(output_type, tuning)
