from typing import Optional

from abjad import Chord, Duration, NamedPitch, Note, Voice, show


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


def sort_frequencies(
    matrix: list[list[float]], limit: Optional[int] = None
) -> list[float]:
    frequencies = [frequency for row in matrix for frequency in row]
    frequencies.sort()
    frequencies = frequencies[1:]
    if not limit:
        return frequencies
    return frequencies[:limit]


def get_named_pitch(frequency: float) -> NamedPitch:
    return NamedPitch.from_hertz(frequency)


def get_note(frequency: float) -> Note:
    pitch = get_named_pitch(frequency)
    duration = Duration(1, 4)
    return Note(pitch, duration)


def get_pitch_names(notes: list[Note]) -> str:
    pitch_names = (note.written_pitch.name for note in notes if note.written_pitch)
    pitch_names = " ".join(pitch_names)
    return f"<{pitch_names}>"


def notate_sorted_matrix(matrix: list[list[float]], as_chord=False) -> None:
    sorted_frequencies = sort_frequencies(matrix)
    notes = [get_note(frequency) for frequency in sorted_frequencies]
    if as_chord:
        pitch_names = get_pitch_names(notes)
        chord = Chord(pitch_names)
        show(chord)
    else:
        voice = Voice(notes)
        show(voice)
