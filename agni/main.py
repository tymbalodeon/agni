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
count = Option(5, help="Number of multiples to calculate.")
output_type = Option(OutputType.HERTZ.value, help="Set the output type for pitches.")


@agni.command()
def matrix(
    bass: str = Argument(..., help=pitch_help),
    melody: str = Argument(..., help=pitch_help),
    pitch_input: InputType = input_type,
    tuning: Tuning = tuning,
    count: int = count,
    output_type: OutputType = output_type,
    as_chord: bool = Option(False, "--as-chord", help="Output matrix as chord."),
    notate: bool = Option(False, "--notate", help="Notated matrix."),
    persist: bool = Option(False, "--persist", help="Persist the notated score."),
    play: bool = Option(False, "--play", help="Play matrix."),
):
    """Create combination-tone matrix from a bass and melody pitch."""
    matrix = get_matrix(bass, melody, pitch_input=pitch_input, count=count)
    if notate:
        notate_matrix(matrix, as_chord=as_chord, persist=persist)
    display_matrix(matrix, pitch_display=output_type, tuning=tuning)
    if play:
        play_matrix(matrix)


@agni.command()
def passage(
    voices: list[str] = Option([], "--voice", help="LilyPond input."),
    input_type: InputType = input_type,
    tuning: Tuning = tuning,
    count: int = count,
    output_type: OutputType = output_type,
):
    """Create combination-tone matrices for a two-voice passage."""
    matrices = get_passage_matrices(voices, pitch_input=input_type, count=count)
    for matrix in matrices:
        display_matrix(matrix, pitch_display=output_type, tuning=tuning)
