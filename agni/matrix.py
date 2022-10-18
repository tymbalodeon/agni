from collections.abc import Callable
from enum import Enum
from math import log
from typing import TypeAlias

from abjad import NamedPitch, NumberedPitch

Matrix = list[list[float]]
Pitch: TypeAlias = NamedPitch | str | float


class PitchInput(Enum):
    MIDI = "midi"
    FREQUENCY = "frequency"


def convert_midi_to_frequency(midi_number: float) -> float:
    return (2 ** ((midi_number - 69) / 12)) * 440


def get_frequency(pitch: Pitch, pitch_input: PitchInput) -> float:
    if isinstance(pitch, NamedPitch):
        return pitch.hertz
    if isinstance(pitch, str):
        if pitch.isnumeric():
            if pitch_input == PitchInput.MIDI:
                return convert_midi_to_frequency(float(pitch))
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


def get_matrix(
    bass: Pitch, melody: Pitch, pitch_input: PitchInput, count: int
) -> Matrix:
    bass_frequency = get_frequency(bass, pitch_input=pitch_input)
    melody_frequency = get_frequency(melody, pitch_input=pitch_input)
    rows = range(count)
    return [
        get_melody_column(row, rows, bass_frequency, melody_frequency) for row in rows
    ]


class PitchDisplay(Enum):
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
    if tuning == Tuning.MICROTONAL:
        decimals = 2
    else:
        decimals = None
    frequency = round(frequency, decimals)
    return f"{frequency:,}"


def get_pitch_displays(frequency: float, tuning: Tuning) -> str | None:
    if not frequency:
        return None
    hertz = get_hertz(frequency, tuning)
    named_pitch = get_named_pitch(frequency, tuning)
    midi = get_midi_number(frequency, tuning)
    return f"{hertz}\n{named_pitch}\n{midi}"


def get_pitch_display_getter(
    pitch_display: PitchDisplay,
) -> Callable[[float, Tuning], str | None]:
    pitch_display_getters: dict[PitchDisplay, Callable[[float, Tuning], str | None]] = {
        PitchDisplay.NAME: get_named_pitch,
        PitchDisplay.MIDI: get_midi_number,
        PitchDisplay.HERTZ: get_hertz,
        PitchDisplay.ALL: get_pitch_displays,
    }
    return pitch_display_getters.get(pitch_display, get_hertz)


def get_row_frequencies(
    row: list[float], tuning: Tuning, pitch_display: PitchDisplay
) -> list[str | None]:
    pitch_display_getter = get_pitch_display_getter(pitch_display)
    return [pitch_display_getter(frequency, tuning) for frequency in row]
