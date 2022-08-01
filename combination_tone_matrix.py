from typing import Iterator, Optional

from abjad import (
    Chord,
    Component,
    Duration,
    LilyPondFile,
    NamedPitch,
    Note,
    Rest,
    Staff,
    StaffGroup,
    Voice,
    show,
)

Matrix = list[list[float]]
Pitch = str | float | NamedPitch


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
    if isinstance(pitch, float):
        return pitch
    elif isinstance(pitch, str):
        return NamedPitch(pitch).hertz
    else:
        return pitch.hertz


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


def get_note_names(notes: list[Note]) -> str:
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
        pitch_names = get_note_names(notes)
        chord = Chord(pitch_names)
        voice = Voice(chord)
        show_with_preamble(preamble, voice)
    else:
        voice = Voice(notes)
        show_with_preamble(preamble, voice)


class NewVoice:
    def __init__(
        self,
        name: str,
        notes: list[Note],
    ) -> None:
        self.name = name
        self.notes = iter(notes)
        self.current_note = self.get_next_note(self.notes)

    def get_next_note(
        self, notes: Optional[Iterator[Note]] = None
    ) -> Optional[Note]:
        if not notes:
            notes = self.notes
        self.first_time = True
        self.current_note = next(notes, None)
        return self.current_note

    def shorten_current_note(self, duration: float):
        if not self.current_note:
            return
        current_duration = self.get_current_duration()
        if not current_duration:
            return
        shorter_duration = current_duration - duration
        self.current_note.written_duration = shorter_duration
        self.first_time = False

    def get_current_pitch(self) -> Optional[NamedPitch]:
        if not self.current_note or isinstance(self.current_note, Rest):
            return None
        return self.current_note.written_pitch

    def get_current_duration(self) -> Optional[Duration]:
        if not self.current_note:
            return None
        return self.current_note.written_duration

    def matches_duration(self, duration: float) -> bool:
        if not self.current_note:
            return False
        current_duration = self.get_current_duration()
        return current_duration == duration


def is_end_of_passage(voices: list[NewVoice]) -> bool:
    current_notes = [voice.current_note for voice in voices]
    return not any(current_notes)


def remove_none_values(collection: list) -> list:
    return [item for item in collection if item]


def get_current_pitches(voices: list[NewVoice]) -> list[NamedPitch]:
    current_pitches = [voice.get_current_pitch() for voice in voices]
    return remove_none_values(current_pitches)


def get_smallest_rhythmic_value(voices: list[NewVoice]) -> float:
    durations = [voice.get_current_duration() for voice in voices]
    durations = remove_none_values(durations)
    return float(min(durations))


def get_voices_matching_shortest_duration(
    voices, shortest_duration
) -> list[NewVoice]:
    return [
        voice for voice in voices if voice.matches_duration(shortest_duration)
    ]


def get_voices_with_longer_durations(
    voices, shortest_duration
) -> list[NewVoice]:
    return [
        voice
        for voice in voices
        if not voice.matches_duration(shortest_duration)
    ]


def get_next_pitches(voices: list[NewVoice]) -> list[NamedPitch]:
    shortest_duration = get_smallest_rhythmic_value(voices)
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


def get_simultaneous_pitches(
    staff_group: StaffGroup, show_adjacent_duplicates=False
) -> list[list[NamedPitch]]:
    staves = {staff.name: staff for staff in staff_group.components}
    voices = [NewVoice(name, notes) for name, notes in staves.items()]
    pitches = [get_current_pitches(voices)]
    end_of_passage = is_end_of_passage(voices)
    while not end_of_passage:
        new_pitches = get_next_pitches(voices)
        should_add = should_add_pitches(
            show_adjacent_duplicates, new_pitches, pitches
        )
        if should_add:
            pitches.append(new_pitches)
        end_of_passage = is_end_of_passage(voices)
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
