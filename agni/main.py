from typer import Argument, Option, Typer

from agni.play_matrix import play_matrix

from .display_matrix import display_matrix
from .matrix import PitchType, Tuning, get_matrix
from .notate_matrix import notate_matrix

agni = Typer(
    help="Create combination-tone matrices.",
    context_settings={"help_option_names": ["-h", "--help"]},
    no_args_is_help=True,
    rich_markup_mode="rich",
)


@agni.command(name="display-matrix")
def matrix(
    bass: str = Argument(..., help="LilyPond pitch or frequency"),
    melody: str = Argument(..., help="LilyPond pitch or frequency"),
    notate: bool = Option(False, "--notate", help="Notate the matrix and save file."),
    play: bool = Option(False, "--play", help="Play the matrix."),
    count: int = Option(5, help="Number of calculations to make."),
    pitch_type: PitchType = Option(PitchType.HERTZ.value),
    tuning: Tuning = Option(Tuning.MICROTONAL.value, "--tuning"),
    as_chord: bool = Option(False, "--as-chord", help="Notate as chords"),
    persist: bool = Option(False, "--persist", help="Save to Desktop"),
):
    """Display matrix"""
    matrix = get_matrix(bass, melody, count=count)
    if notate:
        notate_matrix(matrix, as_chord=as_chord, persist=persist)
    display_matrix(matrix, pitch_type=pitch_type, tuning=tuning)
    if play:
        play_matrix(matrix)
