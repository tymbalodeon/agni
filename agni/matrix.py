from enum import Enum
from math import log
from typing import TypeAlias

from abjad import NamedPitch, NumberedPitch

Matrix = list[list[float]]
Pitch: TypeAlias = NamedPitch | str | float


def get_frequency(pitch: Pitch) -> float:
    if isinstance(pitch, NamedPitch):
        return pitch.hertz
    if isinstance(pitch, str):
        if pitch.isnumeric():
            return float(pitch)
        return NamedPitch(pitch).hertz
    return pitch


def get_sum_frequency(multiplier: int, bass_multiple: float, melody: float) -> float:
    melody_multiple = melody * multiplier
    return bass_multiple + melody_multiple


def get_melody_column(
    multiplier: int, columns: range, bass: float, melody: float
) -> list[float]:
    bass_multiple = bass * multiplier
    return [get_sum_frequency(column, bass_multiple, melody) for column in columns]


def get_matrix(bass: Pitch, melody: Pitch, count=5) -> Matrix:
    bass_frequency = get_frequency(bass)
    melody_frequency = get_frequency(melody)
    rows = range(count)
    return [
        get_melody_column(row, rows, bass_frequency, melody_frequency) for row in rows
    ]


class PitchType(Enum):
    NAME = "name"
    MIDI = "midi"
    HERTZ = "hertz"
    ALL = "all"


class Tuning(Enum):
    MICROTONAL = "microtonal"
    EQUAL_TEMPERED = "equal-tempered"


def get_named_pitch(frequency: float, tuning: Tuning) -> str | None:
    if not frequency:
        return None
    named_pitch = NamedPitch.from_hertz(frequency)
    if tuning == Tuning.EQUAL_TEMPERED:
        pitch_number = named_pitch.number
        if isinstance(pitch_number, float):
            pitch_number = int(pitch_number)
            pitch_name = NumberedPitch(pitch_number).name
            named_pitch = NamedPitch(pitch_name)
    return named_pitch.name


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


def get_hertz(frequency: float, tuning: Tuning) -> str | None:
    if not frequency:
        return None
    decimals = None
    if tuning == Tuning.MICROTONAL:
        decimals = 2
    frequency = round(frequency, decimals)
    return f"{frequency:,}"


def get_pitch_displays(frequency: float, tuning: Tuning) -> str | None:
    if not frequency:
        return None
    hertz = get_hertz(frequency, tuning)
    named_pitch = get_named_pitch(frequency, tuning)
    midi = get_midi_number(frequency, tuning)
    return f"{hertz}\n{named_pitch}\n{midi}"


def get_row_frequencies(
    row: list[float], tuning: Tuning, pitch_type: PitchType
) -> list[str | None]:
    if pitch_type == PitchType.NAME:
        return [get_named_pitch(frequency, tuning) for frequency in row]
    if pitch_type == PitchType.MIDI:
        return [get_midi_number(frequency, tuning) for frequency in row]
    if pitch_type == PitchType.HERTZ:
        return [get_hertz(frequency, tuning) for frequency in row]
    return [get_pitch_displays(frequency, tuning) for frequency in row]