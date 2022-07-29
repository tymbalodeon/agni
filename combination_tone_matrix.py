from typing import Optional

from abjad import (
    Chord,
    Component,
    Duration,
    LilyPondFile,
    NamedPitch,
    Note,
    Voice,
    show,
)


def get_frequency(
    multiplier: int, bass_multiple: float, melody: float
) -> float:
    melody_multiple = melody * multiplier
    return bass_multiple + melody_multiple


def get_melody_column(
    multiplier: int, columns: range, bass: float, melody: float
) -> list[float]:
    bass_multiple = bass * multiplier
    return [get_frequency(column, bass_multiple, melody) for column in columns]


def get_matrix(bass: str, melody: str, count=5) -> list[list[float]]:
    bass_frequency = NamedPitch(bass).hertz
    melody_frequency = NamedPitch(melody).hertz
    rows = range(count)
    return [
        get_melody_column(row, rows, bass_frequency, melody_frequency)
        for row in rows
    ]


def display_matrix(matrix: list[list[float]]):
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


def get_note(frequency: float) -> Note:
    pitch = NamedPitch.from_hertz(frequency)
    duration = Duration(1, 4)
    return Note(pitch, duration)


def get_note_name(note: Note) -> Optional[str]:
    if not note.written_pitch:
        return None
    return note.written_pitch.name


def get_pitch_names(notes: list[Note]) -> str:
    pitch_names = (get_note_name(note) for note in notes)
    pitch_names = (note for note in pitch_names if note)
    pitch_names = " ".join(pitch_names)
    return f"<{pitch_names}>"


def show_with_preamble(preamble: str, container: Component):
    lilypond_file = LilyPondFile([preamble, container])
    show(lilypond_file)


def notate_matrix(matrix: list[list[float]], as_chord=False):
    frequencies = sort_frequencies(matrix)
    notes = [get_note(frequency) for frequency in frequencies]
    preamble = r"""
                    \header { tagline = ##f }
                    \layout {
                        \context {
                            \Score
                            \override BarLine.stencil = ##f
                            \override SystemStartBar.stencil = ##f
                            \override Stem.stencil = ##f
                            \override TimeSignature.stencil = ##f
                        }
                    }
                """
    if as_chord:
        pitch_names = get_pitch_names(notes)
        chord = Chord(pitch_names)
        show_with_preamble(preamble, chord)
    else:
        voice = Voice(notes)
        show_with_preamble(preamble, voice)


matrix = get_matrix("g,", "a'")
notate_matrix(matrix)
