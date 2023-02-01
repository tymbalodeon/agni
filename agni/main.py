from pathlib import Path

from rich.markup import escape
from typer import Argument, Option, Typer

from .matrix import Matrix
from .matrix_frequency import DisplayType, Tuning
from .notation import notate_matrix, notate_passage
from .passage import Passage

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
sorted = Option(
    False,
    "--sorted",
    help="Display frequencies as a list in ascending order.",
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
    multiples: int = multiples,
    display_type: DisplayType = Option(
        None, "--display-type", help="Set the display type for pitches."
    ),
    tuning: Tuning = tuning,
    midi_input: bool = Option(
        False,
        "--midi-input",
        help="Set the input type for numeric input.",
    ),
    sorted: bool = sorted,
    as_chord: bool = as_chord,
    notate: bool = notate,
    persist: bool = persist,
    as_ensemble: bool = as_ensemble,
    play: bool = Option(False, "--play", help="Play matrix."),
):
    """Create combination-tone matrix from two pitches."""
    matrix = Matrix(
        bass, melody, multiples, display_type, tuning, midi_input=midi_input
    )
    if notate:
        notate_matrix(matrix, as_ensemble, tuning, persist, as_chord)
    matrix.display(sorted)
    if play:
        matrix.play()


@agni.command()
def passage(
    input_file: Path = Argument(
        Path("examples/lonely-child-notes.ily"), help="LilyPond input file."
    ),
    multiples: int = multiples,
    display_type: DisplayType = Option(
        DisplayType.HERTZ.value,
        "--display-type",
        help="Set the display type for pitches.",
    ),
    tuning: Tuning = tuning,
    sorted: bool = sorted,
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
    passage = Passage(
        input_file,
        multiples,
        display_type,
        tuning,
        as_set,
        adjacent_duplicates,
    )
    if notate:
        notate_passage(
            passage,
            as_ensemble,
            tuning,
            persist,
            as_chord,
            full_score,
        )
    passage.display(sorted)
