from typing import Optional

from abjad import Container, Duration, NamedPitch, Note, show


def get_pitch(multiplier: int, bass_multiple: float, melody: float) -> float:
    melody_multiple = melody * multiplier
    return bass_multiple + melody_multiple


def get_melody_column(
    multiplier: int, columns: range, bass: float, melody: float
) -> list[float]:
    bass_multiple = bass * multiplier
    return [get_pitch(column, bass_multiple, melody) for column in columns]


def get_matrix(bass: str, melody: str, count=5) -> list[list[float]]:
    bass_pitch = NamedPitch(bass).hertz
    melody_pitch = NamedPitch(melody).hertz
    rows = range(count)
    return [get_melody_column(row, rows, bass_pitch, melody_pitch) for row in rows]


def display_matrix(matrix: list[list[float]]) -> None:
    for row in matrix:
        print(row)


def get_sorted_frequencies(
    matrix: list[list[float]], limit: Optional[int] = None
) -> list[float]:
    frequencies = [frequency for row in matrix for frequency in row]
    frequencies.sort()
    frequencies = frequencies[1:]
    if not limit:
        return frequencies
    return frequencies[:limit]


def get_note(frequency: float) -> Note:
    duration = Duration(1, 4)
    pitch = NamedPitch.from_hertz(frequency)
    return Note(pitch, duration)


def notate_sorted_matrix(matrix: list[list[float]]) -> None:
    sorted_frequencies = get_sorted_frequencies(matrix)
    notes = [get_note(frequency) for frequency in sorted_frequencies]
    notes = Container(notes)
    show(notes)
