from typer import Argument, Option, Typer

from agni.passage import get_passage_matrices
from agni.play_matrix import play_matrix

from .display_matrix import display_matrix
from .matrix import PitchDisplay, PitchInput, Tuning, get_matrix
from .notate_matrix import notate_matrix

agni = Typer(
    help="Create combination-tone matrices.",
    context_settings={"help_option_names": ["-h", "--help"]},
    no_args_is_help=True,
    rich_markup_mode="rich",
)

pitch_help = "LilyPond pitch, midi note number, frequency"


@agni.command()
def matrix(
    bass: str = Argument(..., help=pitch_help),
    melody: str = Argument(..., help=pitch_help),
    pitch_input: PitchInput = Option(
        PitchInput.FREQUENCY.value,
        "--pitch-input",
        help="Input bass and melody as midi note numbers.",
    ),
    tuning: Tuning = Option(
        Tuning.MICROTONAL.value, "--tuning", help="Type of tuning quantization."
    ),
    count: int = Option(5, help="Number of multiples to calculate."),
    pitch_display: PitchDisplay = Option(
        PitchDisplay.HERTZ.value, help="Pitch display format."
    ),
    as_chord: bool = Option(
        False, "--as-chord", help="Play and notate matrix as chords."
    ),
    notate: bool = Option(
        False, "--notate", help="Generate notated score of the matrix."
    ),
    persist: bool = Option(False, "--persist", help="Persist the notated score."),
    play: bool = Option(False, "--play", help="Play the matrix."),
):
    """Create combination-tone matrix from a bass and melody pitch."""
    matrix = get_matrix(bass, melody, count=count, pitch_input=pitch_input)
    if notate:
        notate_matrix(matrix, as_chord=as_chord, persist=persist)
    display_matrix(matrix, pitch_display=pitch_display, tuning=tuning)
    if play:
        play_matrix(matrix)


@agni.command()
def passage(
    voices: list[str] = Option([], "--voice", help="LilyPond input."),
    tuning: Tuning = Option(
        Tuning.MICROTONAL.value, "--tuning", help="Type of tuning quantization."
    ),
    pitch_display: PitchDisplay = Option(
        PitchDisplay.HERTZ.value, help="Pitch display format."
    ),
):
    """Create combination-tone matrices for a two-voice passage."""
    matrices = get_passage_matrices(voices)
    for matrix in matrices:
        display_matrix(matrix, pitch_display=pitch_display, tuning=tuning)
