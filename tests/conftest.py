from typer.testing import CliRunner
from agni.main import agni


def call_command(args: list[str]) -> str:
    if not any(args):
        return CliRunner().invoke(agni).output
    return CliRunner().invoke(agni, args).output
