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
