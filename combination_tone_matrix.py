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
    return [
        note["current"].written_pitch
        for note in simultaneity.values()
        if isinstance(note["current"], Note)
    ]


def is_end_of_passage(staff, index):
    print(staff)
    try:
        if not staff:
            return False
        staff[index + 1]
        return True
    except Exception:
        return False


def make_first_time(simultaneity):
    for value in simultaneity.values():
        value["first_time"] = True
    return simultaneity


def get_shortest_note(simultaneity):
    durations = [
        note["current"].written_duration for note in simultaneity.values()
    ]
    shortest = min(durations)
    small = [
        {key: simultaneity[key]}
        for key, note in simultaneity.items()
        if note["current"] and note["current"].written_duration == shortest
    ]
    small = [get_next_simultaneity(note) for note in small]
    small = [make_first_time(simultaneity) for simultaneity in small]
    for note in small:
        key = next(iter(note.keys()), None)
        simultaneity[key] = note[key]
    other = [
        {key: simultaneity[key]}
        for key, note in simultaneity.items()
        if note["current"] and note["current"].written_duration != shortest
    ]
    other = [shorten_notes(note, float(shortest)) for note in other]
    for note in other:
        key = next(iter(note.keys()), None)
        simultaneity[key] = note[key]
    return simultaneity


def get_next(thing):
    thing = next(thing, None)
    print("THING: ", thing)
    return thing


def get_next_simultaneity(simultaneity):
    return {
        key: {
            "current": get_next(simultaneity[key]["generator"]),
            "generator": simultaneity[key]["generator"],
            "first_time": True,
        }
        for key in simultaneity.keys()
    }


def shorten(note: Note, difference: float):
    new_duration = Duration.from_float(
        float(note.written_duration) - difference
    )
    new_note = Note(note)
    new_note.written_duration = new_duration
    return new_note


def shorten_notes(simultaneity, difference):
    return {
        key: {
            "current": shorten(simultaneity[key]["current"], difference),
            "generator": simultaneity[key]["generator"],
            "first_time": False,
        }
        for key in simultaneity.keys()
    }


def get_simultaneous_pitches(staff_group: StaffGroup):
    staves = {staff.name: staff for staff in staff_group.components}
    simultaneity: dict = {
        key: {"current": None, "generator": iter(value), "first_time": True}
        for key, value in staves.items()
    }
    pitches = []
    simultaneity = get_next_simultaneity(simultaneity)
    new_pitches = get_pitches(simultaneity)
    pitches.append(new_pitches)
    simultaneity = get_shortest_note(simultaneity)
    new_pitches = get_pitches(simultaneity)
    pitches.append(new_pitches)
    simultaneity = get_shortest_note(simultaneity)
    new_pitches = get_pitches(simultaneity)
    pitches.append(new_pitches)
    # simultaneity = get_shortest_note(simultaneity)
    # new_pitches = get_pitches(simultaneity)
    # pitches.append(new_pitches)
    return


staff_one = Staff("c,2 r4", name="bass")
staff_two = Staff("e'4 ef2", name="melody")
staff_group = StaffGroup([staff_one, staff_two])
get_simultaneous_pitches(staff_group)
