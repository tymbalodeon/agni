from typer.testing import CliRunner

from agni.main import app

bass_frequency = 440.0
melody_frequency = 466.0


def call_command(args: list[str]) -> str:
    if not any(args):
        return CliRunner().invoke(app).output
    return CliRunner().invoke(app, args).output
