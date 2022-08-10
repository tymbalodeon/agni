from dataclasses import dataclass
from typing import Iterator, Optional, TypeAlias

from abjad import (
    Staff,
    Chord,
    Component,
    Duration,
    LilyPondFile,
    NamedPitch,
    Note,
    Rest,
    StaffGroup,
    Voice,
    show,
)

Matrix = list[list[float]]
Pitch: TypeAlias = NamedPitch | str | float


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
    if isinstance(pitch, NamedPitch):
        return pitch.hertz
    elif isinstance(pitch, str):
        return NamedPitch(pitch).hertz
    return pitch


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
        row_frequencies = [str(int(frequency)) for frequency in row]
        row_display = " ".join(row_frequencies)
        print(row_display)


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


def remove_none_values(collection: list) -> list:
    return [item for item in collection if item]


def get_chord_notes(notes: list[Note]) -> str:
    note_names = [get_note_name(note) for note in notes]
    pitched_note_names = remove_none_values(note_names)
    chord_notes = " ".join(pitched_note_names)
    return f"<{chord_notes}>"


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
        chord_notes = get_chord_notes(notes)
        chord = Chord(chord_notes)
        voice = Voice(chord)
        show_with_preamble(preamble, voice)
    else:
        voice = Voice(notes)
        show_with_preamble(preamble, voice)


@dataclass
class PitchAndDuration:
    named_pitch: Optional[NamedPitch]
    duration: Duration

    @staticmethod
    def from_note(note: Note):
        named_pitch = note.written_pitch
        duration = note.written_duration
        return PitchAndDuration(named_pitch, duration)


class Part:
    def __init__(
        self,
        name: str,
        notes: list[Note],
    ) -> None:
        self.name = name
        note_durations = [PitchAndDuration.from_note(note) for note in notes]
        self.notes = iter(note_durations)
        self.current_note = self.get_next_note(self.notes)

    def get_next_note(
        self, notes: Optional[Iterator[PitchAndDuration]] = None
    ) -> Optional[PitchAndDuration]:
        if not notes:
            notes = self.notes
        self.first_time = True
        self.current_note = next(notes, None)
        return self.current_note

    def get_current_duration(self) -> Optional[Duration]:
        if not self.current_note:
            return None
        return self.current_note.duration

    def shorten_current_note(self, duration: float):
        if not self.current_note:
            return
        current_duration = self.get_current_duration()
        if not current_duration:
            return
        shorter_duration = current_duration - duration
        self.current_note.duration = shorter_duration
        self.first_time = False

    def get_current_pitch(self) -> Optional[NamedPitch]:
        if not self.current_note or isinstance(self.current_note, Rest):
            return None
        return self.current_note.named_pitch

    def matches_duration(self, duration: float) -> bool:
        if not self.current_note:
            return False
        current_duration = self.get_current_duration()
        return current_duration == duration


def is_end_of_passage(voices: list[Part]) -> bool:
    current_notes = [voice.current_note for voice in voices]
    return not any(current_notes)


def get_current_pitches(voices: list[Part]) -> list[NamedPitch]:
    current_pitches = [voice.get_current_pitch() for voice in voices]
    return remove_none_values(current_pitches)


def get_shortest_duration(voices: list[Part]) -> float:
    current_durations = [voice.get_current_duration() for voice in voices]
    durations = remove_none_values(current_durations)
    return min(durations)


def get_voices_matching_shortest_duration(
    voices, shortest_duration
) -> list[Part]:
    return [
        voice for voice in voices if voice.matches_duration(shortest_duration)
    ]


def get_voices_with_longer_durations(voices, shortest_duration) -> list[Part]:
    return [
        voice
        for voice in voices
        if not voice.matches_duration(shortest_duration)
    ]


def get_next_pitches(voices: list[Part]) -> list[NamedPitch]:
    shortest_duration = get_shortest_duration(voices)
    voices_matching_shortest_duration = get_voices_matching_shortest_duration(
        voices, shortest_duration
    )
    voices_with_longer_durations = get_voices_with_longer_durations(
        voices, shortest_duration
    )
    for voice in voices_matching_shortest_duration:
        voice.get_next_note()
    for voice in voices_with_longer_durations:
        voice.shorten_current_note(shortest_duration)
    return get_current_pitches(voices)


def get_pitch_names(pitches: list[NamedPitch]) -> list[str]:
    return [pitch.name for pitch in pitches]


def are_same_pitches(
    new_pitches: list[NamedPitch], old_pitches: list[list[NamedPitch]]
) -> bool:
    new_pitch_names = get_pitch_names(new_pitches)
    old_pitch_names = get_pitch_names(old_pitches[-1])
    return new_pitch_names == old_pitch_names


def should_add_pitches(
    show_adjacent_duplicates: bool,
    new_pitches: list[NamedPitch],
    old_pitches: list[list[NamedPitch]],
) -> bool:
    if not new_pitches:
        return False
    if show_adjacent_duplicates:
        return True
    is_duplicate = are_same_pitches(new_pitches, old_pitches)
    should_add = not is_duplicate
    return should_add


def get_ordered_unique_pitch_sets(
    pitches: list[list[NamedPitch]],
) -> list[list[NamedPitch]]:
    pitch_sets = [tuple(pitch_set) for pitch_set in pitches]
    pitch_sets = list(dict.fromkeys(pitch_sets))
    return [list(pitch_set) for pitch_set in pitch_sets]


def get_staves(staves: tuple[Staff]) -> tuple[Staff]:
    staff_number = 0
    for staff in staves:
        if not staff.name:
            staff.name = staff_number
            staff_number += 1
    return staves


def get_part(staff: Staff, staff_number: int) -> Part:
    if not staff.name:
        staff.name = str(staff_number)
    name = staff.name
    notes: list[Note] = list(staff.components)
    return Part(name, notes)


def get_simultaneous_pitches(
    staff_group: StaffGroup, as_set=True, show_adjacent_duplicates=False
) -> list[list[NamedPitch]]:
    staves = staff_group.components
    parts = [get_part(staff, index) for index, staff in enumerate(staves)]
    pitches = [get_current_pitches(parts)]
    end_of_passage = is_end_of_passage(parts)
    while not end_of_passage:
        new_pitches = get_next_pitches(parts)
        should_add = should_add_pitches(
            show_adjacent_duplicates, new_pitches, pitches
        )
        if should_add:
            pitches.append(new_pitches)
        end_of_passage = is_end_of_passage(parts)
    if as_set:
        return get_ordered_unique_pitch_sets(pitches)
    return pitches


def get_passage_matrices(passage: StaffGroup) -> list[Matrix]:
    simultaneous_pitches = get_simultaneous_pitches(passage)
    matrices = list()
    for pitches in simultaneous_pitches:
        if not len(pitches) == 2:
            continue
        bass, melody = pitches
        matrix = get_matrix(bass, melody)
        matrices.append(matrix)
    return matrices
