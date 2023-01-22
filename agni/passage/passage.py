from collections.abc import Iterator
from dataclasses import dataclass

from abjad import Duration, NamedPitch, Rest, TimeSignature
from abjad.get import duration as get_duration

from agni.matrix import Matrix, get_matrix
from agni.passage.read_passage import NoteInMeasure, Passage


@dataclass
class SoundingNote:
    named_pitch: NamedPitch | None
    duration: Duration
    time_signature: TimeSignature

    @classmethod
    def from_note(cls, note: NoteInMeasure):
        named_pitch = note.note.written_pitch
        duration = get_duration(note.note)
        time_signature = note.time_signature
        return SoundingNote(named_pitch, duration, time_signature)


class Part:
    def __init__(self, name: str, notes: list[NoteInMeasure]):
        self.name = name
        self.notes = (SoundingNote.from_note(note) for note in notes)
        self.current_note = self.get_next_note(self.notes)

    def get_next_note(
        self, notes: Iterator[SoundingNote] | None = None
    ) -> SoundingNote | None:
        if not notes:
            notes = self.notes
        self.current_note = next(notes, None)
        return self.current_note

    def get_current_duration(self) -> Duration | None:
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

    def get_current_pitch(self) -> NamedPitch | None:
        if not self.current_note or isinstance(self.current_note, Rest):
            return None
        return self.current_note.named_pitch

    def matches_duration(self, duration: float) -> bool:
        if not self.current_note:
            return False
        current_duration = self.get_current_duration()
        return current_duration == duration


def get_parts(passage: Passage) -> list[Part]:
    bass = passage.bass
    melody = passage.melody
    parts = bass, melody
    return [Part(str(index), part) for index, part in enumerate(parts)]


def remove_none_values(collection: list) -> list:
    return [item for item in collection if item]


def get_current_pitches(parts: list[Part]) -> list[NamedPitch]:
    current_pitches = [part.get_current_pitch() for part in parts]
    return remove_none_values(current_pitches)


def is_end_of_passage(parts: list[Part]) -> bool:
    current_notes = [part.current_note for part in parts]
    return not any(current_notes)


def get_shortest_duration(parts: list[Part]) -> float:
    current_durations = [part.get_current_duration() for part in parts]
    durations = remove_none_values(current_durations)
    return min(durations)


def get_parts_matching_shortest_duration(
    parts, shortest_duration
) -> list[Part]:
    return [part for part in parts if part.matches_duration(shortest_duration)]


def get_parts_with_longer_durations(
    parts: list[Part], shortest_duration
) -> list[Part]:
    return [
        part for part in parts if not part.matches_duration(shortest_duration)
    ]


def get_next_pitches(parts: list[Part]) -> list[NamedPitch]:
    shortest_duration = get_shortest_duration(parts)
    parts_matching_shortest_duration = get_parts_matching_shortest_duration(
        parts, shortest_duration
    )
    parts_with_longer_durations = get_parts_with_longer_durations(
        parts, shortest_duration
    )
    for part in parts_matching_shortest_duration:
        part.get_next_note()
    for part in parts_with_longer_durations:
        part.shorten_current_note(shortest_duration)
    return get_current_pitches(parts)


def get_pitch_names(pitches: list[NamedPitch]) -> list[str]:
    return [pitch.name for pitch in pitches]


def are_same_pitches(
    new_pitches: list[NamedPitch], old_pitches: list[list[NamedPitch]]
) -> bool:
    new_pitch_names = get_pitch_names(new_pitches)
    old_pitch_names = get_pitch_names(old_pitches[-1])
    return new_pitch_names == old_pitch_names


def should_add_pitches(
    adjacent_duplicates: bool,
    new_pitches: list[NamedPitch],
    old_pitches: list[list[NamedPitch]],
) -> bool:
    if not new_pitches:
        return False
    if adjacent_duplicates:
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


def get_simultaneous_pitches(
    passage: Passage,
    as_set=True,
    adjacent_duplicates=False,
) -> list[list[NamedPitch]]:
    parts = get_parts(passage)
    pitches = [get_current_pitches(parts)]
    end_of_passage = is_end_of_passage(parts)
    while not end_of_passage:
        new_pitches = get_next_pitches(parts)
        should_add = should_add_pitches(
            adjacent_duplicates, new_pitches, pitches
        )
        if should_add:
            pitches.append(new_pitches)
        end_of_passage = is_end_of_passage(parts)
    if as_set:
        return get_ordered_unique_pitch_sets(pitches)
    return pitches


def get_passage_matrices(
    passage: Passage,
    multiples: int,
    as_set: bool,
    adjacent_duplicates: bool,
) -> list[Matrix]:
    simultaneous_pitches = get_simultaneous_pitches(
        passage,
        as_set=as_set,
        adjacent_duplicates=adjacent_duplicates,
    )
    matrices = []
    for pitches in simultaneous_pitches:
        if not len(pitches) == 2:
            continue
        bass, melody = pitches
        matrix = get_matrix(bass, melody, multiples=multiples)
        matrices.append(matrix)
    return matrices
