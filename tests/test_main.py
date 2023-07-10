from pytest import mark

from agni import __version__

from .conftest import call_command

version = "0.2.0"


def test_version():
    assert __version__ == version


@mark.parametrize("arg", ["--version", "-V"])
def test_version_display(arg: str):
    version_display = f"agni {version}\n"
    output = call_command([arg])
    assert output == version_display


@mark.parametrize("arg", [None, "--help", "-h"])
def test_help(arg: str):
    help_text = "Agni: Use compositional techniques inspired by Claude Vivier."
    output = call_command([arg])
    assert help_text in output
