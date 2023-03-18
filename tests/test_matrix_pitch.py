from pytest import mark, raises

from agni.matrix_pitch import MatrixPitch

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
