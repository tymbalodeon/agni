from rich.box import SIMPLE
from rich.console import Console
from rich.table import Table

from .combination_tone_matrix import Matrix, PitchType, get_row_frequencies


def get_header_multipler(multiplier: int, pitch: str) -> str:
    return f"[bold cyan]{multiplier} * {pitch}[/bold cyan]"


def get_melody_header(matrix: Matrix) -> list[str]:
    count = len(matrix)
    header = [get_header_multipler(multiplier, "melody") for multiplier in range(count)]
    return [""] + header


def display_matrix(matrix: Matrix, pitch_type=PitchType.HERTZ, microtonal=True):
    title = f"Combination-Tone Matrix ({pitch_type.value.title()})"
    table = Table(title=title, show_header=False, box=SIMPLE)
    melody_header = get_melody_header(matrix)
    table.add_row(*melody_header)
    for multiplier, row in enumerate(matrix):
        row_frequencies = get_row_frequencies(
            row, microtonal=microtonal, pitch_type=pitch_type
        )
        if not multiplier:
            melody = row_frequencies[1]
            row_frequencies[1] = f"[bold yellow]{melody}[/bold yellow]"
        elif multiplier == 1:
            bass = row_frequencies[0]
            row_frequencies[0] = f"[bold yellow]{bass}[/bold yellow]"
        bass_header: list[str | None] = [get_header_multipler(multiplier, "bass")]
        formatted_row = bass_header + row_frequencies
        table.add_row(*formatted_row)
    Console().print(table)
