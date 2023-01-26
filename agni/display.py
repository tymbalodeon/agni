from functools import lru_cache
from math import log
from typing import Callable

from abjad import NamedPitch
from rich.box import SIMPLE
from rich.table import Table

from .enums import OutputType, Tuning
from .helpers import quantize_pitch


def get_matrix_table(output_type: OutputType) -> Table:
    title = f"Combination-Tone Matrix ({output_type.value.title()})"
    return Table(title=title, show_header=False, box=SIMPLE)


def get_header_multipler(multiplier: int, pitch: str) -> str:
    return f"[bold cyan]{multiplier} * {pitch}[/bold cyan]"


def get_melody_header(frequencies: list[list[float]]) -> list[str]:
    multiples = len(frequencies)
    header = [
        get_header_multipler(multiplier, "melody")
        for multiplier in range(multiples)
    ]
    return [""] + header


def bolden_base_frequency(multiplier: int, row_frequencies: list[str | None]):
    if multiplier == 1:
        index = 0
    elif not multiplier:
        index = 1
    else:
        return
    frequency = row_frequencies[index]
    row_frequencies[index] = f"[bold yellow]{frequency}[/bold yellow]"


def get_bass_header(multiplier: int) -> list[str | None]:
    return [get_header_multipler(multiplier, "bass")]


def add_melody_header(table: Table, frequencies: list[list[float]]):
    melody_header = get_melody_header(frequencies)
    table.add_row(*melody_header)


@lru_cache
def get_named_pitch(frequency: float, tuning: Tuning) -> str | None:
    if not frequency:
        return None
    named_pitch = NamedPitch.from_hertz(frequency)
    if tuning == Tuning.EQUAL_TEMPERED:
        named_pitch = quantize_pitch(named_pitch)
    return named_pitch.name


@lru_cache
def get_midi_number(frequency: float, tuning: Tuning) -> str | None:
    if not frequency:
        return None
    frequency = frequency / 440
    logarithm = log(frequency, 2)
    midi_number = 12 * logarithm + 69
    if tuning == Tuning.MICROTONAL:
        midi_number = round(midi_number * 2) / 2
    else:
        midi_number = round(midi_number)
    return str(midi_number)


@lru_cache
def get_hertz(frequency: float, tuning: Tuning) -> str | None:
    if not frequency:
        return None
    if tuning == Tuning.MICROTONAL:
        decimals = 2
    else:
        decimals = None
    frequency = round(frequency, decimals)
    return f"{frequency:,}"


@lru_cache
def get_output_types(frequency: float, tuning: Tuning) -> str | None:
    if not frequency:
        return None
    hertz = get_hertz(frequency, tuning)
    named_pitch = get_named_pitch(frequency, tuning)
    midi = get_midi_number(frequency, tuning)
    return f"{hertz}\n{named_pitch}\n{midi}"


def get_output_type_getter(
    output_type: OutputType,
) -> Callable[[float, Tuning], str | None]:
    output_type_getters: dict[
        OutputType, Callable[[float, Tuning], str | None]
    ] = {
        OutputType.LILYPOND: get_named_pitch,
        OutputType.MIDI: get_midi_number,
        OutputType.HERTZ: get_hertz,
        OutputType.ALL: get_output_types,
    }
    return output_type_getters.get(output_type, get_hertz)


def get_row_frequencies(
    row: list[float], tuning: Tuning, output_type: OutputType
) -> list[str | None]:
    output_type_getter = get_output_type_getter(output_type)
    return [output_type_getter(frequency, tuning) for frequency in row]
