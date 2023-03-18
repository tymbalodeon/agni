from pytest import mark

from agni.matrix import Matrix
from tests.conftest import call_command

matrix_command = "matrix"


@mark.parametrize("arg", ["--help", "-h"])
def test_matrix_help(arg: str):
    matrix_help_text = "Create combination-tone matrix from two pitches."
    output = call_command([matrix_command, arg])
    assert matrix_help_text in output


def test_matrix_sorted_frequencies_in_hertz():
    bass = "440"
    melody = "466"
    expected_frequencies = [
        440.0,
        466.0,
        880.0,
        906.0,
        932.0,
        1_320.0,
        1_346.0,
        1_372.0,
        1_398.0,
        1_786.0,
        1_812.0,
        1_838.0,
        2_252.0,
        2_278.0,
        2_718.0,
    ]
    matrix = Matrix(bass, melody)
    assert matrix.sorted_frequencies_in_hertz == expected_frequencies


def test_matrix_command():
    bass = "440"
    melody = "466"
    expected_text = """Combination-Tone Matrix (Hertz)

             0 x melody   1 x melody   2 x melody   3 x melody
  0 x bass                466.0        932.0        1,398.0
  1 x bass   440.0        906.0        1,372.0      1,838.0
  2 x bass   880.0        1,346.0      1,812.0      2,278.0
  3 x bass   1,320.0      1,786.0      2,252.0      2,718.0
    """
    actual_output = call_command([matrix_command, bass, melody])
    expected_lines = expected_text.split("\n")
    actual_lines = actual_output.split("\n")
    for display_line, expected_line in zip(expected_lines, actual_lines):
        assert display_line.strip() == expected_line.strip()
