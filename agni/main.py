from rich.markup import escape
from typer import Argument, Option, Typer

from agni.passage import get_passage_matrices
from agni.play_matrix import play_matrix

from .display_matrix import display_matrix
from .matrix import InputType, OutputType, Tuning, get_matrix
from .notate_matrix import notate_matrix

agni = Typer(
    help="Create combination-tone matrices.",
    context_settings={"help_option_names": ["-h", "--help"]},
    no_args_is_help=True,
    rich_markup_mode="rich",
)

pitch_choices = escape("[hertz|midi|lilypond]")
pitch_help = f"[bold yellow]{pitch_choices}[/bold yellow]"
input_type = Option(
    InputType.HERTZ.value, "--input-type", help="Set the input type for numeric input."
)
tuning = Option(
    Tuning.MICROTONAL.value, "--tuning", help="Set the tuning to quantize to."
)
multiples = Option(5, help="Number of multiples to calculate.")
output_type = Option(OutputType.HERTZ.value, help="Set the output type for pitches.")
as_chord = Option(False, "--as-chord", help="Output matrix as chord.")
as_ensebmle = Option(False, "--as-ensemble", help="Notate each note on its own staff.")
notate = Option(False, "--notate", help="Notated matrix.")
persist = Option(False, "--persist", help="Persist the notated score.")


@agni.command()
def matrix(
    bass: str = Argument(..., help=pitch_help),
    melody: str = Argument(..., help=pitch_help),
    input_type: InputType = input_type,
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
    matrix = get_matrix(bass, melody, input_type=input_type, multiples=multiples)
    if notate:
        notate_matrix(
            matrix, as_chord=as_chord, persist=persist, as_ensemble=as_ensebmle
        )
    display_matrix(matrix, output_type=output_type, tuning=tuning)
    if play:
        play_matrix(matrix)


@agni.command()
def passage(
    parts: list[str] = Option([], "--part", help="LilyPond input."),
    input_type: InputType = input_type,
    tuning: Tuning = tuning,
    multiples: int = multiples,
    output_type: OutputType = output_type,
    as_chord: bool = as_chord,
    notate: bool = notate,
    persist: bool = persist,
    as_ensebmle: bool = as_ensebmle,
):
    """Create combination-tone matrices for a two-voice passage."""
    matrices = get_passage_matrices(parts, input_type=input_type, multiples=multiples)
    if notate:
        notate_matrix(
            *matrices, as_chord=as_chord, persist=persist, as_ensemble=as_ensebmle
        )
    display_matrix(*matrices, output_type=output_type, tuning=tuning)
