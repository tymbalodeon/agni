from typer import Argument, Typer
from typer.params import Option

from .combination_tone_matrix import PitchType, display_matrix, get_matrix

agni = Typer(
    help="Create combination-tone matrices.",
    context_settings={"help_option_names": ["-h", "--help"]},
    no_args_is_help=True,
    rich_markup_mode="rich",
)


@agni.command()
def matrix(
    bass: str = Argument(..., help="LilyPond pitch or frequency"),
    melody: str = Argument(..., help="LilyPond pitch or frequency"),
    count: int = Option(5),
    pitch_type: PitchType = Option(PitchType.HERTZ.value),
    microtonal: bool = Option(True, "--microtonal/--equal-tempered"),
):
    """Display matrix"""
    matrix = get_matrix(bass, melody, count=count)
    display_matrix(matrix, pitch_type=pitch_type, microtonal=microtonal)


@agni.command()
def notate_matrix(
    bass: str = Argument(..., help="LilyPond pitch or frequency"),
    melody: str = Argument(..., help="LilyPond pitch or frequency"),
):
    matrix = get_matrix(bass, melody)
    display_matrix(matrix)
