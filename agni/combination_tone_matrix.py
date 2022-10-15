from collections.abc import Iterator
from dataclasses import dataclass
from enum import Enum
from math import log
from typing import TypeAlias, cast

from abjad import Container, Duration, NamedPitch, Note, NumberedPitch, Rest
from abjad.select import leaves

Matrix = list[list[float]]
Pitch: TypeAlias = NamedPitch | str | float


def get_frequency(pitch: Pitch) -> float:
    if isinstance(pitch, NamedPitch):
        return pitch.hertz
    if isinstance(pitch, str):
        if pitch.isnumeric():
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


def get_matrix(bass: Pitch, melody: Pitch, count=5) -> Matrix:
    bass_frequency = get_frequency(bass)
    melody_frequency = get_frequency(melody)
    rows = range(count)
    return [
        get_melody_column(row, rows, bass_frequency, melody_frequency) for row in rows
    ]


def get_hertz(frequency: float, microtonal: bool) -> str | None:
    if not frequency:
        return None
    decimals = None
    if microtonal:
        decimals = 2
    frequency = round(frequency, decimals)
    return f"{frequency:,}"


def get_named_pitch(frequency: float, microtonal: bool) -> str | None:
    if not frequency:
        return None
    named_pitch = NamedPitch.from_hertz(frequency)
    if not microtonal:
        pitch_number = named_pitch.number
        if isinstance(pitch_number, float):
            pitch_number = int(pitch_number)
            pitch_name = NumberedPitch(pitch_number).name
            named_pitch = NamedPitch(pitch_name)
    return named_pitch.name


def get_midi_number(frequency: float, microtonal: bool) -> str | None:
    if not frequency:
        return None
    frequency = frequency / 440
    logarithm = log(frequency, 2)
    midi_number = 12 * logarithm + 69
    if microtonal:
        midi_number = round(midi_number * 2) / 2
    else:
        midi_number = round(midi_number)
    return str(midi_number)


def get_pitch_displays(frequency: float, microtonal: bool) -> str | None:
    if not frequency:
        return None
    hertz = get_hertz(frequency, microtonal)
    named_pitch = get_named_pitch(frequency, microtonal)
    midi = get_midi_number(frequency, microtonal)
    return f"{hertz}\n{named_pitch}\n{midi}"


class PitchType(Enum):
    NAME = "name"
    MIDI = "midi"
    HERTZ = "hertz"
    ALL = "all"


def get_row_frequencies(
    row: list[float], microtonal: bool, pitch_type: PitchType
) -> list[str | None]:
    if pitch_type == PitchType.NAME:
        return [get_named_pitch(frequency, microtonal) for frequency in row]
    if pitch_type == PitchType.MIDI:
        return [get_midi_number(frequency, microtonal) for frequency in row]
    if pitch_type == PitchType.HERTZ:
        return [get_hertz(frequency, microtonal) for frequency in row]
    return [get_pitch_displays(frequency, microtonal) for frequency in row]


@dataclass
class PitchAndDuration:
    named_pitch: NamedPitch | None
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
        pitch_and_durations = [PitchAndDuration.from_note(note) for note in notes]
        self.notes = iter(pitch_and_durations)
        self.current_note = self.get_next_note(self.notes)

    def get_next_note(
        self, notes: Iterator[PitchAndDuration] | None = None
    ) -> PitchAndDuration | None:
        if not notes:
            notes = self.notes
        self.first_time = True
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
        self.first_time = False

    def get_current_pitch(self) -> NamedPitch | None:
        if not self.current_note or isinstance(self.current_note, Rest):
            return None
        return self.current_note.named_pitch

    def matches_duration(self, duration: float) -> bool:
        if not self.current_note:
            return False
        current_duration = self.get_current_duration()
        return current_duration == duration


def get_lilypond_part(notes: str, relative: str | None = None) -> str:
    if not relative:
        return notes
    relative = f"\\relative {relative}"
    relative_notes = f"{relative} {{ {notes} }}"
    return relative_notes


def get_part_containers(
    parts: list[str], relative: str | None = None
) -> list[Container]:
    lilypond_parts = [get_lilypond_part(part, relative) for part in parts]
    return [Container(part) for part in lilypond_parts]


def get_parts(containers: list[Container]) -> list[Part]:
    parts = []
    for count, container in enumerate(containers):
        container.name = str(count)
        name = container.name
        notes = cast(list[Note], leaves(container))
        part = Part(name, notes)
        parts.append(part)
    return parts


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


def get_parts_matching_shortest_duration(parts, shortest_duration) -> list[Part]:
    return [part for part in parts if part.matches_duration(shortest_duration)]


def get_parts_with_longer_durations(parts: list[Part], shortest_duration) -> list[Part]:
    return [part for part in parts if not part.matches_duration(shortest_duration)]


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


def get_simultaneous_pitches(
    containers: list[Container], as_set=True, show_adjacent_duplicates=False
) -> list[list[NamedPitch]]:
    parts = get_parts(containers)
    pitches = [get_current_pitches(parts)]
    end_of_passage = is_end_of_passage(parts)
    while not end_of_passage:
        new_pitches = get_next_pitches(parts)
        should_add = should_add_pitches(show_adjacent_duplicates, new_pitches, pitches)
        if should_add:
            pitches.append(new_pitches)
        end_of_passage = is_end_of_passage(parts)
    if as_set:
        return get_ordered_unique_pitch_sets(pitches)
    return pitches


def get_passage_matrices(parts: list[str], relative: str | None = None) -> list[Matrix]:
    passage = get_part_containers(parts, relative)
    simultaneous_pitches = get_simultaneous_pitches(passage)
    matrices = []
    for pitches in simultaneous_pitches:
        if not len(pitches) == 2:
            continue
        bass, melody = pitches
        matrix = get_matrix(bass, melody)
        matrices.append(matrix)
    return matrices
