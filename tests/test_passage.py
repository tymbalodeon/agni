from pytest import mark
from .conftest import call_command

passage_command_name = "passage"


@mark.parametrize("arg", ["--help", "-h"])
def test_passage_help(arg: str):
    passage_help_text = (
        " Create combination-tone matrices for a two-voice passage."
    )
    output = call_command([passage_command_name, arg])
    assert passage_help_text in output
