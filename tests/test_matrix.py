from pytest import mark

from tests.conftest import call_command

matrix_command = "matrix"


@mark.parametrize("arg", ["--help", "-h"])
def test_matrix_help(arg: str):
    matrix_help_text = "Create combination-tone matrix from two pitches."
    output = call_command([matrix_command, arg])
    assert matrix_help_text in output
