from typer import Argument, Typer
from typer.params import Option

from .combination_tone_matrix import (
    PitchType,
    display_matrix,
    get_matrix,
    notate_matrix,
)

agni = Typer(
    help="Create combination-tone matrices.",
    context_settings={"help_option_names": ["-h", "--help"]},
    no_args_is_help=True,
    rich_markup_mode="rich",
)


@agni.command(name="display-matrix")
def display(
    bass: str = Argument(..., help="LilyPond pitch or frequency"),
    melody: str = Argument(..., help="LilyPond pitch or frequency"),
    count: int = Option(5, help="Number of calculations to make."),
    pitch_type: PitchType = Option(PitchType.HERTZ.value),
    microtonal: bool = Option(True, "--microtonal/--equal-tempered"),
):
    """Display matrix"""
    matrix = get_matrix(bass, melody, count=count)
    display_matrix(matrix, pitch_type=pitch_type, microtonal=microtonal)


@agni.command(name="notate-matrix")
def notate(
    bass: str = Argument(..., help="LilyPond pitch or frequency"),
    melody: str = Argument(..., help="LilyPond pitch or frequency"),
    count: int = Option(5, help="Number of calculations to make."),
    as_chord: bool = Option(False, "--as-chord", help="Notate as chords"),
    persist: bool = Option(False, "--persist", help="Save to Desktop"),
):
    """Notate matrix"""
    matrix = get_matrix(bass, melody, count=count)
    notate_matrix(matrix, as_chord=as_chord, persist=persist)
