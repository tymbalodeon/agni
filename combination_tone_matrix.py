from typing import Optional

from abjad import (
    Chord,
    Component,
    Duration,
    LilyPondFile,
    NamedPitch,
    Note,
    Staff,
    StaffGroup,
    Voice,
    show,
)
from abjad.get import pitches
from abjad.select import leaves

Matrix = list[list[float]]
Pitch = str | float


def get_sum_frequency(
    multiplier: int, bass_multiple: float, melody: float
) -> float:
    melody_multiple = melody * multiplier
    return bass_multiple + melody_multiple


def get_melody_column(
    multiplier: int, columns: range, bass: float, melody: float
) -> list[float]:
    bass_multiple = bass * multiplier
    return [
        get_sum_frequency(column, bass_multiple, melody) for column in columns
    ]


def get_frequency(pitch: Pitch) -> float:
    if not isinstance(pitch, str):
        return pitch
    return NamedPitch(pitch).hertz


def get_matrix(bass: Pitch, melody: Pitch, count=5) -> Matrix:
    bass_frequency = get_frequency(bass)
    melody_frequency = get_frequency(melody)
    rows = range(count)
    return [
        get_melody_column(row, rows, bass_frequency, melody_frequency)
        for row in rows
    ]


def display_matrix(matrix: Matrix):
    for row in matrix:
        print(row)


def sort_frequencies(
    matrix: Matrix, limit: Optional[int] = None
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


def notate_matrix(matrix: Matrix, as_chord=False):
    frequencies = sort_frequencies(matrix)
    notes = [get_note(frequency) for frequency in frequencies]
    preamble = r"""
                    \header { tagline = ##f }
                    \layout {
                        \context {
                            \Score
                            \override SystemStartBar.stencil = ##f
                            \override TimeSignature.stencil = ##f
                            \override BarLine.stencil = ##f
                            \override Stem.stencil = ##f
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


def get_pitch(note):
    return next(iter(pitches(note)))


def get_pitch_and_duration(staff):
    notes = leaves(staff)
    return [(get_pitch(note), note.written_duration) for note in notes]


def get_pitches(simultaneity):
    return [note["current"].written_pitch for note in simultaneity.values()]


def get_simultaneity(staves, index):
    return {key: value[index] for key, value in staves.items()}


def is_end_of_passage(staff, index):
    print(staff)
    try:
        if not staff:
            return False
        staff[index + 1]
        return True
    except Exception:
        return False


def get_shortest_note(simultaneity):
    durations = [
        note["current"].written_duration for note in simultaneity.values()
    ]
    shortest = min(durations)
    small = [
        simultaneity[key]
        for key, note in simultaneity.items()
        if note["current"].written_duration == shortest
    ]
    other = [
        simultaneity[key]
        for key, note in simultaneity.items()
        if note["current"].written_duration != shortest
    ]
    return small, other


def get_simultaneous_pitches(staff_group: StaffGroup):
    staves = {staff.name: staff for staff in staff_group.components}
    simultaneity: dict = {
        key: {"current": None, "generator": iter(value)}
        for key, value in staves.items()
    }
    simultaneity = {
        key: {
            "current": next(simultaneity[key]["generator"], None),
            "generator": simultaneity[key]["generator"],
        }
        for key in simultaneity.keys()
    }
    pitches = []
    pitches.append(get_pitches(simultaneity))
    small, other = get_shortest_note(simultaneity)
    print(small, other)
    return
    index = 0
    lowest = None
    staff_name = ""
    end_of_passage = is_end_of_passage(staff_name, index)
    while not end_of_passage:
        for staff, note in simultaneity.items():
            duration = note.written_duration
            if not lowest or duration < lowest:
                lowest = duration
                staff_name = staff
        simultaneity[staff_name] = staves[staff_name][index + 1]
        pitches.append(get_pitches(simultaneity))
        end_of_passage = is_end_of_passage(
            get_simultaneity(staves, index), index
        )
        index += 1
    print(pitches)


staff_one = Staff("c,2 r4", name="bass")
staff_two = Staff("e'4 ef2", name="melody")
staff_group = StaffGroup([staff_one, staff_two])
get_simultaneous_pitches(staff_group)
