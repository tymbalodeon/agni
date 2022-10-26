from rich.box import SIMPLE
from rich.console import Console
from rich.table import Table

from .matrix import Matrix, OutputType, Tuning, get_row_frequencies


def get_header_multipler(multiplier: int, pitch: str) -> str:
    return f"[bold cyan]{multiplier} * {pitch}[/bold cyan]"


def get_melody_header(matrix: Matrix) -> list[str]:
    count = len(matrix)
    header = [get_header_multipler(multiplier, "melody") for multiplier in range(count)]
    return [""] + header


def get_matrix_table(output_type: OutputType) -> Table:
    title = f"Combination-Tone Matrix ({output_type.value.title()})"
    return Table(title=title, show_header=False, box=SIMPLE)


def add_melody_header(table: Table, matrix: Matrix):
    melody_header = get_melody_header(matrix)
    table.add_row(*melody_header)


def bolden_frequency(index: int, row_frequencies: list[str | None]):
    frequency = row_frequencies[index]
    row_frequencies[index] = f"[bold yellow]{frequency}[/bold yellow]"


def bolden_base_frequency(multiplier: int, row_frequencies: list[str | None]):
    if multiplier == 1:
        index = 0
    elif not multiplier:
        index = 1
    else:
        return
    bolden_frequency(index, row_frequencies)


def get_bass_header(multiplier: int) -> list[str | None]:
    return [get_header_multipler(multiplier, "bass")]


def display_matrix(matrix: Matrix, output_type: OutputType, tuning: Tuning):
    table = get_matrix_table(output_type)
    add_melody_header(table, matrix)
    for multiplier, row in enumerate(matrix):
        row_frequencies = get_row_frequencies(
            row, tuning=tuning, output_type=output_type
        )
        bolden_base_frequency(multiplier, row_frequencies)
        bass_header = get_bass_header(multiplier)
        formatted_row = bass_header + row_frequencies
        table.add_row(*formatted_row)
    Console().print(table)
