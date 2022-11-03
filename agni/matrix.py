from collections.abc import Callable
from enum import Enum
from math import log
from typing import TypeAlias

from abjad import NamedPitch, NumberedPitch

Matrix = list[list[float]]
Pitch: TypeAlias = NamedPitch | str | float


def convert_midi_to_frequency(midi_number: float) -> float:
    return (2 ** ((midi_number - 69) / 12)) * 440


class InputType(Enum):
    HERTZ = "hertz"
    MIDI = "midi"


def get_frequency(pitch: Pitch, input_type: InputType) -> float:
    if isinstance(pitch, NamedPitch):
        return pitch.hertz
    if isinstance(pitch, str):
        if pitch.isnumeric():
            if input_type == InputType.MIDI:
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
    bass: Pitch, melody: Pitch, input_type=InputType.HERTZ, multiples: int = 4
) -> Matrix:
    bass_frequency = get_frequency(bass, input_type=input_type)
    melody_frequency = get_frequency(melody, input_type=input_type)
    rows = range(multiples)
    return [
        get_melody_column(row, rows, bass_frequency, melody_frequency) for row in rows
    ]


class Tuning(Enum):
    MICROTONAL = "microtonal"
    EQUAL_TEMPERED = "equal-tempered"


def quantize_pitch(pitch: NamedPitch) -> NamedPitch:
    pitch_number = pitch.number
    if not isinstance(pitch_number, float):
        return pitch
    pitch_number = int(pitch_number)
    pitch_name = NumberedPitch(pitch_number).name
    return NamedPitch(pitch_name)


def get_named_pitch(frequency: float, tuning: Tuning) -> str | None:
    if not frequency:
        return None
    named_pitch = NamedPitch.from_hertz(frequency)
    if tuning == Tuning.EQUAL_TEMPERED:
        named_pitch = quantize_pitch(named_pitch)
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


def get_output_types(frequency: float, tuning: Tuning) -> str | None:
    if not frequency:
        return None
    hertz = get_hertz(frequency, tuning)
    named_pitch = get_named_pitch(frequency, tuning)
    midi = get_midi_number(frequency, tuning)
    return f"{hertz}\n{named_pitch}\n{midi}"


class OutputType(Enum):
    HERTZ = "hertz"
    MIDI = "midi"
    LILYPOND = "lilypond"
    ALL = "all"


def get_output_type_getter(
    output_type: OutputType,
) -> Callable[[float, Tuning], str | None]:
    output_type_getters: dict[OutputType, Callable[[float, Tuning], str | None]] = {
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
