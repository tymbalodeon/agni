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

pitch_help = "LilyPond pitch, midi note number, frequency"


@agni.command(name="display-matrix")
def matrix(
    bass: str = Argument(..., help=pitch_help),
    melody: str = Argument(..., help=pitch_help),
    count: int = Option(5, help="Number of multiples to calculate."),
    tuning: Tuning = Option(
        Tuning.MICROTONAL.value, "--tuning", help="Type of tuning quantization."
    ),
    pitch_type: PitchType = Option(PitchType.HERTZ.value, help="Pitch display format."),
    notate: bool = Option(
        False, "--notate", help="Generate notated score of the matrix."
    ),
    persist: bool = Option(False, "--persist", help="Persist the notated score."),
    play: bool = Option(False, "--play", help="Play the matrix."),
    as_chord: bool = Option(
        False, "--as-chord", help="Play and notate matrix as chords."
    ),
):
    """Create combination-tone matrix from a bass and melody pitch."""
    matrix = get_matrix(bass, melody, count=count)
    if notate:
        notate_matrix(matrix, as_chord=as_chord, persist=persist)
    display_matrix(matrix, pitch_type=pitch_type, tuning=tuning)
    if play:
        play_matrix(matrix)
