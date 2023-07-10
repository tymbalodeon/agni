from abjad import Duration, Note, Tie
from abjad.get import indicators as get_indicators
from pytest import mark, raises

from agni.couleurs.matrix_pitch import MatrixPitch, Tuning

from .conftest import bass_frequency, melody_frequency

expected_displays = [
    (0, 0, "MatrixPitch(None)"),
    (0, 1, "MatrixPitch(466.0)"),
    (0, 2, "MatrixPitch(932.0)"),
    (1, 0, "MatrixPitch(440.0)"),
    (1, 1, "MatrixPitch(906.0)"),
    (1, 2, "MatrixPitch(1,372.0)"),
]


@mark.parametrize(
    "bass_multiplier, melody_multiplier, expected_display", expected_displays
)
def test_matrix_pitch_str(
    bass_multiplier: int, melody_multiplier: int, expected_display: str
):
    matrix_pitch = MatrixPitch(
        bass_frequency, melody_frequency, bass_multiplier, melody_multiplier
    )
    assert str(matrix_pitch) == expected_display


def test_matrix_pitch_eq():
    matrix_pitch = MatrixPitch(bass_frequency, melody_frequency, 1, 0)
    with raises(AssertionError):
        assert matrix_pitch == 440.0


expected_is_base_multiples = [
    (0, 0, False),
    (0, 1, False),
    (0, 2, True),
    (1, 0, False),
    (1, 1, False),
    (1, 2, False),
    (2, 0, True),
]


@mark.parametrize(
    "bass_multiplier, melody_multiplier, expected_is_base_multiple",
    expected_is_base_multiples,
)
def test_is_base_multiple(
    bass_multiplier: int,
    melody_multiplier: int,
    expected_is_base_multiple: bool,
):
    matrix_pitch = MatrixPitch(
        bass_frequency, melody_frequency, bass_multiplier, melody_multiplier
    )
    assert matrix_pitch.is_base_multiple is expected_is_base_multiple


expected_lilypond_displays = [
    (0, 0, Tuning.MICROTONAL, ""),
    (1, 0, Tuning.MICROTONAL, "a'"),
    (1, 0, Tuning.EQUAL_TEMPERED, "a'"),
    (1, 1, Tuning.MICROTONAL, "aqs''"),
    (1, 1, Tuning.EQUAL_TEMPERED, "a''"),
]


@mark.parametrize(
    "bass_multiplier, melody_multiplier, tuning, expected_display",
    expected_lilypond_displays,
)
def test_get_lilypond_display_pitch(
    bass_multiplier: int,
    melody_multiplier: int,
    tuning: Tuning,
    expected_display: str,
):
    matrix_pitch = MatrixPitch(
        bass_frequency, melody_frequency, bass_multiplier, melody_multiplier
    )
    actual_display_pitch = matrix_pitch._get_lilypond_display_pitch(tuning)
    assert actual_display_pitch == expected_display


expected_midi_displays = [
    (0, 0, Tuning.MICROTONAL, ""),
    (1, 0, Tuning.MICROTONAL, "69.0"),
    (1, 0, Tuning.EQUAL_TEMPERED, "69"),
    (1, 1, Tuning.MICROTONAL, "81.5"),
    (1, 1, Tuning.EQUAL_TEMPERED, "82"),
]


@mark.parametrize(
    "bass_multiplier, melody_multiplier, tuning, expected_display",
    expected_midi_displays,
)
def test_get_midi_display_pitch(
    bass_multiplier: int,
    melody_multiplier: int,
    tuning: Tuning,
    expected_display: str,
):
    matrix_pitch = MatrixPitch(
        bass_frequency, melody_frequency, bass_multiplier, melody_multiplier
    )
    actual_display_pitch = matrix_pitch._get_midi_display_pitch(tuning)
    assert actual_display_pitch == expected_display


expected_hertz_displays = [
    (0, 0, Tuning.MICROTONAL, ""),
    (1, 0, Tuning.MICROTONAL, "440.0"),
    (1, 0, Tuning.EQUAL_TEMPERED, "440"),
    (1, 1, Tuning.MICROTONAL, "906.0"),
    (1, 1, Tuning.EQUAL_TEMPERED, "906"),
]


@mark.parametrize(
    "bass_multiplier, melody_multiplier, tuning, expected_display",
    expected_hertz_displays,
)
def test_get_hertz_display_pitch(
    bass_multiplier: int,
    melody_multiplier: int,
    tuning: Tuning,
    expected_display: str,
):
    matrix_pitch = MatrixPitch(
        bass_frequency, melody_frequency, bass_multiplier, melody_multiplier
    )
    actual_display_pitch = matrix_pitch._get_hertz_display_pitch(tuning)
    assert actual_display_pitch == expected_display


expected_instrument_names = [
    (0, 0, ""),
    (1, 0, "B"),
    (1, 1, "B + M"),
    (1, 2, "B + 2M"),
    (2, 1, "2B + M"),
    (3, 3, "3B + 3M"),
]


@mark.parametrize(
    "bass_multiplier, melody_multiplier, expected_instrument_name",
    expected_instrument_names,
)
def test_get_instrument_name(
    bass_multiplier: int, melody_multiplier: int, expected_instrument_name: str
):
    matrix_pitch = MatrixPitch(
        bass_frequency, melody_frequency, bass_multiplier, melody_multiplier
    )
    assert matrix_pitch.instrument_name == expected_instrument_name


def test_get_note_no_frequency():
    matrix_pitch = MatrixPitch(bass_frequency, melody_frequency, 0, 0)
    assert matrix_pitch.get_note(Duration((1, 4)), tie=False) is None


expected_notes = [
    (1, 0, Duration((1, 4)), False, Note("a'4")),
    (0, 1, Duration((1, 8)), True, Note("bf'8")),
]


@mark.parametrize(
    "bass_multiplier, melody_multiplier, duration, tie, expected_note",
    expected_notes,
)
def test_get_note(
    bass_multiplier: int,
    melody_multiplier: int,
    duration: Duration,
    tie: bool,
    expected_note: Note | None,
):
    matrix_pitch = MatrixPitch(
        bass_frequency, melody_frequency, bass_multiplier, melody_multiplier
    )
    actual_note = matrix_pitch.get_note(duration, tie)
    actual_tie = next(iter(get_indicators(actual_note, prototype=Tie)), False)
    assert (
        actual_note is not None
        and expected_note is not None
        and actual_note.written_pitch == expected_note.written_pitch
        and actual_note.written_duration == expected_note.written_duration
        and bool(actual_tie) == tie
    )
