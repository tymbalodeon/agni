from pathlib import Path

from cyclopts import App

from agni import __version__

from .matrix import Matrix
from .matrix_pitch import DisplayFormat, PitchType, Tuning
from .notation import Notation
from .passage import Passage

agni = App(
    help="agni: Compositional tools inspired by the techniques of Claude Vivier."
)


def display_version(version: bool):
    if version:
        return f"agni {__version__}"


def get_display_format_from_input(
    as_chord: bool, display_format: DisplayFormat
) -> DisplayFormat:
    if display_format == DisplayFormat.DEFAULT:
        if as_chord:
            return DisplayFormat.CHORD
        return DisplayFormat.TABLE
    return display_format


@agni.command()
def matrix(
    bass: str,
    melody: str,
    multiples=Matrix.DEFAULT_MULTIPLES,
    pitch_type=PitchType.LILYPOND,
    tuning=Tuning.MICROTONAL,
    midi_input=False,
    display_format=DisplayFormat.DEFAULT,
    as_chord=False,
    notate=False,
    save=False,
    as_ensemble=False,
    output_directory=Path("examples"),
    display=True,
    play=False,
):
    """Create combination-tone matrix from two pitches.

    Parameters
    ----------
    bass: str
        [hertz|midi|lilypond]
    melody: str
        [hertz|midi|lilypond]
    multiples: Matrix
        Number of multiples to calculate
    pitch_type: PitchType
        Set the display type for pitches. (If none is provided, the same type as the input pitches is used.)
    tuning: Tuning
        Set the tunint to quantize to
    midi_input: False
        Set the input type (applies to numeric input only)
    display_format: DisplayFormat
        Set the matrix display format
    as_chord: False
        Output matrix as a chord
    notate: False
        Notate matrix in a PDF score
    save: False
        Save the notated score as a named file instead of an Abjad temporary score
    as_ensemble: False
        Notate each matrix note on its own staff
    output_directory: Path
        If saving, the directory in which to save the output file
    display: True
        Set the matrix display format
    play: False
        Play matrix
    """
    display_format = get_display_format_from_input(as_chord, display_format)
    matrix = Matrix(
        bass,
        melody,
        multiples,
        pitch_type,
        tuning,
        display_format,
        midi_input=midi_input,
    )
    if display or not notate and not play:
        matrix.display()
    if notate:
        as_chord = as_chord or display_format == DisplayFormat.CHORD
        Notation(
            matrix, as_ensemble, tuning, save, as_chord, output_directory
        ).notate()
    if play:
        matrix.play()


@agni.command()
def passage(
    input_file: Path,
    multiples=Matrix.DEFAULT_MULTIPLES,
    pitch_type=PitchType.LILYPOND,
    tuning=Tuning.MICROTONAL,
    display_format=DisplayFormat.DEFAULT,
    as_chord=False,
    notate=False,
    save=False,
    as_ensemble=False,
    as_set=True,
    adjacent_duplicates=False,
    output_directory=Path("examples"),
    full_score=False,
    display=True,
):
    """Create combination-tone matrices for a two-voice passage.

    Parameters
    ----------
    input_file: Path
        LilyPond input file
    multiples: Matrix
        Number of multiples to calculate
    pitch_type: PitchType
        Set the display type for pitches. (If none is provided, the same type as the input pitches is used.)
    tuning: Tuning
        Set the tunint to quantize to
    display_format: DisplayFormat
        Set the matrix display format
    as_chord: False
        Output matrix as a chord
    notate: False
        Notate matrix in a PDF score
    save: False
        Save the notated score as a named file instead of an Abjad temporary score
    as_ensemble: False
        Notate each matrix note on its own staff
    as_set: True
        Output unique matrices only
    adjacent_duplicates: False
        Output adjacent duplicate matrices
    output_directory: Path
        If saving, the directory in which to save the output file
    full_score: False
        Output matrices as an ensemble score using the input rhythms
    display: True
        Don't show the output in the terminal
    """

    message = ""
    exit = False
    if not input_file.exists():
        message = f"{input_file} does not exist"
        exit = True
    if exit:
        return message
    display_format = get_display_format_from_input(as_chord, display_format)
    if full_score:
        as_ensemble = True
        as_set = False
        adjacent_duplicates = True
    passage = Passage(
        input_file,
        multiples,
        pitch_type,
        tuning,
        display_format,
        as_set,
        adjacent_duplicates,
    )
    if display or not notate:
        passage.display()
    if notate:
        Notation(
            passage,
            as_ensemble,
            tuning,
            save,
            as_chord,
            output_directory,
            full_score,
        ).notate()
