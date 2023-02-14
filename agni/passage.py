from collections.abc import Generator
from dataclasses import dataclass
from functools import cached_property, lru_cache
from pathlib import Path
from typing import cast

from abjad import (
    Duration,
    Leaf,
    LilyPondFile,
    MultimeasureRest,
    NamedPitch,
    Note,
    Rest,
    Staff,
    Tie,
    TimeSignature,
    Tuplet,
    parse,
)
from abjad.get import duration as get_duration
from abjad.get import indicators as get_indicators
from abjad.get import parentage as get_parentage
from abjad.select import components as get_components
from abjad.select import leaves as get_leaves
from abjad.select import logical_ties as get_logical_ties
from more_itertools import peekable

from .helpers import (
    InputPart,
    get_instrument_name,
    get_staff_by_name,
    remove_none_values,
)
from .matrix import DisplayFormat, Matrix
from .matrix_frequency import MatrixFrequency, PitchType, Tuning


@dataclass
class MeteredLeaf:
    leaf: Leaf
    time_signature: TimeSignature


@dataclass
class SoundingLeaf:
    named_pitch: NamedPitch | None
    duration: Duration
    time_signature: TimeSignature

    @staticmethod
    def _get_named_pitch(leaf: Leaf) -> NamedPitch | None:
        if isinstance(leaf, Note):
            return leaf.written_pitch
        return None

    @staticmethod
    def _get_sounding_duration(leaf: Leaf) -> Duration | None:
        logical_tie = get_logical_ties(leaf)
        if not logical_tie:
            return None
        return get_duration(logical_tie)

    @classmethod
    def from_leaves_in_measure(cls, metered_leaf: MeteredLeaf):
        leaf = metered_leaf.leaf
        named_pitch = cls._get_named_pitch(leaf)
        duration = cls._get_sounding_duration(metered_leaf.leaf)
        if not duration:
            return None
        time_signature = metered_leaf.time_signature
        return cls(named_pitch, duration, time_signature)


class Part:
    def __init__(self, leaves: list[MeteredLeaf]):
        self._leaves = peekable(leaf for leaf in leaves)
        self._sounding_leaves = self._get_leaves(leaves)
        self.current_leaf_duration = None
        self.current_leaf = self.get_next_leaf()
        self.current_sounding_leaf = self.get_next_sounding_leaf()

    @property
    def current_leaf_hertz(self) -> float | None:
        current_leaf_pitch = self.current_leaf_pitch
        if not current_leaf_pitch:
            return None
        return current_leaf_pitch.hertz

    @staticmethod
    def _get_leaves(
        leaves: list[MeteredLeaf],
    ) -> Generator[SoundingLeaf, None, None]:
        sounding_leaves = (
            SoundingLeaf.from_leaves_in_measure(leaf) for leaf in leaves
        )
        return (leaf for leaf in sounding_leaves if leaf)

    def peek_next_leaf(self, duration: Duration | None) -> Leaf | None:
        if duration:
            current_leaf = self.current_leaf
            if not current_leaf:
                return None
            return current_leaf.leaf
        next_leaf = self._leaves.peek(None)
        if not next_leaf:
            return None
        return next_leaf.leaf

    def get_next_leaf(
        self, duration: Duration | None = None
    ) -> MeteredLeaf | None:
        if duration:
            self._shorten_current_leaf(duration)
            return None
        next_leaf = next(self._leaves, None)
        if next_leaf:
            self.current_leaf_duration = get_duration(next_leaf.leaf)
        self.current_leaf = next_leaf
        return next_leaf

    def get_next_sounding_leaf(self) -> SoundingLeaf | None:
        next_sounding_leaf = next(self._sounding_leaves, None)
        self.current_sounding_leaf = next_sounding_leaf
        return next_sounding_leaf

    @property
    def current_sounding_leaf_duration(self) -> Duration | None:
        current_sounding_leaf = self.current_sounding_leaf
        if not current_sounding_leaf:
            return None
        return current_sounding_leaf.duration

    def _shorten_current_leaf(self, duration: Duration):
        current_duration = self.current_leaf_duration
        if not current_duration:
            return
        shorter_duration = current_duration - duration
        self.current_leaf_duration = shorter_duration

    def shorten_current_sounding_leaf(self, duration: float):
        if not self.current_sounding_leaf:
            return
        current_duration = self.current_sounding_leaf_duration
        if not current_duration:
            return
        shorter_duration = current_duration - duration
        self.current_sounding_leaf.duration = shorter_duration

    @property
    def current_leaf_pitch(self) -> NamedPitch | None:
        current_leaf = self.current_leaf
        if not current_leaf or not isinstance(current_leaf.leaf, Note):
            return None
        return current_leaf.leaf.written_pitch

    @property
    def current_sounding_pitch(self) -> NamedPitch | None:
        if not self.current_sounding_leaf or isinstance(
            self.current_sounding_leaf, Rest
        ):
            return None
        return self.current_sounding_leaf.named_pitch

    def matches_current_sounding_duration(self, duration: float) -> bool:
        if not self.current_sounding_leaf:
            return False
        current_duration = self.current_sounding_leaf_duration
        return current_duration == duration

    @property
    def current_leaf_tie(self) -> bool:
        if not self.current_leaf:
            return False
        return bool(get_indicators(self.current_leaf.leaf, prototype=Tie))

    @property
    def current_leaf_tuplet(self) -> Tuplet | None:
        if not self.current_leaf or not self.current_leaf_duration:
            return None
        current_leaf = self.current_leaf.leaf
        parent = get_parentage(current_leaf).parent
        if isinstance(parent, Tuplet):
            return parent
        return None

    @property
    def is_start_of_tuplet(self) -> bool:
        if not self.current_leaf or not self.current_leaf_tuplet:
            return False
        return self.current_leaf_tuplet.index(self.current_leaf.leaf) == 0

    @property
    def current_leaf_written_duration(self) -> Duration | None:
        current_leaf = self.current_leaf
        if not current_leaf:
            return None
        return current_leaf.leaf.written_duration

    @property
    def is_multi_measure_rest(self) -> bool:
        if not self.current_leaf or not isinstance(
            self.current_leaf.leaf, MultimeasureRest
        ):
            return False
        return True


@dataclass
class MatrixLeaf:
    _bass: NamedPitch | None
    _melody: NamedPitch | None
    duration: Duration | None
    is_multi_measure_rest: bool
    tie: bool
    tuplet: Tuplet | None
    is_start_of_tuplet: bool
    _multiples: int

    @property
    def contains_pitches(self) -> bool:
        return all([self._bass, self._melody])

    @cached_property
    def generated_pitches(self) -> list[MatrixFrequency]:
        bass = self._bass
        melody = self._melody
        duration = self.duration
        if not bass or not melody or not duration:
            return []
        matrix = Matrix(bass.name, melody.name, self._multiples)
        return matrix.get_sorted_generated_frequencies()

    @cached_property
    def instrument_names(self) -> list[str]:
        multiples = range(self._multiples)
        staff_names = []
        for melody_multiple in multiples:
            for bass_multiple in multiples:
                if (
                    bass_multiple == 0
                    and melody_multiple == 0
                    or bass_multiple == 1
                    and melody_multiple == 0
                    or bass_multiple == 0
                    and melody_multiple == 1
                ):
                    continue
                instrument_name = get_instrument_name(
                    bass_multiple, melody_multiple
                )
                staff_names.append(instrument_name)
        return staff_names


class Passage:
    def __init__(
        self,
        input_file: Path,
        multiples: int,
        pitch_type: PitchType,
        tuning: Tuning,
        display_format: DisplayFormat,
        as_set: bool,
        adjacent_duplicates: bool,
    ):
        lilypond_input = input_file.read_text()
        self._multiples = multiples
        self._pitch_type = pitch_type
        self._tuning = tuning
        self._display_format = display_format
        self._as_set = as_set
        self._adjacent_duplicates = adjacent_duplicates
        self.title = self._get_title(lilypond_input)
        self.composer = self._get_composer(lilypond_input)
        self._bass_input_staff = self._get_bass_staff(lilypond_input)
        self._melody_input_staff = self._get_melody_staff(lilypond_input)
        self._bass_part = self._get_bass_part()
        self._melody_part = self._get_melody_part()

    @staticmethod
    def _get_header_item(lilypond_input: str, item: str) -> str:
        lines = lilypond_input.splitlines()
        matching_line = next((line for line in lines if item in line), None)
        if not matching_line:
            return ""
        return matching_line.split('"')[1]

    @classmethod
    def _get_title(cls, lilypond_input: str) -> str:
        return cls._get_header_item(lilypond_input, "title")

    @classmethod
    def _get_composer(cls, lilypond_input: str) -> str:
        return cls._get_header_item(lilypond_input, "composer")

    @staticmethod
    @lru_cache
    def _get_staves(lilypond_input: str) -> list[Staff]:
        lilypond_file = cast(LilyPondFile, parse(lilypond_input))
        items = lilypond_file.items
        score = next(block for block in items if block.name == "score")
        return cast(list[Staff], get_components(score.items, prototype=Staff))

    @classmethod
    def _get_bass_staff(cls, lilypond_input: str) -> Staff | None:
        staves = cls._get_staves(lilypond_input)
        return get_staff_by_name(staves, InputPart.BASS.value)

    @classmethod
    def _get_melody_staff(cls, lilypond_input: str) -> Staff | None:
        staves = cls._get_staves(lilypond_input)
        return get_staff_by_name(staves, InputPart.MELODY.value)

    @staticmethod
    def _get_time_signature(leaf: Leaf) -> TimeSignature | None:
        return next(
            (
                time_signature
                for time_signature in get_indicators(
                    leaf, prototype=TimeSignature
                )
            ),
            None,
        )

    @classmethod
    def _get_metered_leaves(cls, notes: list[Leaf]) -> list[MeteredLeaf]:
        notes_in_measure = []
        current_time_signature = TimeSignature((4, 4))
        for note in notes:
            time_signature = cls._get_time_signature(note)
            if time_signature:
                current_time_signature = time_signature
            notes_in_measure.append(MeteredLeaf(note, current_time_signature))
        return notes_in_measure

    def _get_staff_leaves(self, input_part: InputPart) -> list[MeteredLeaf]:
        if input_part == InputPart.BASS:
            staff = self._bass_input_staff
        else:
            staff = self._melody_input_staff
        if not staff:
            return []
        components = staff.components
        leaves = get_leaves(components)
        return self._get_metered_leaves(leaves)

    def _get_bass_leaves(self):
        return self._get_staff_leaves(InputPart.BASS)

    def _get_melody_leaves(self):
        return self._get_staff_leaves(InputPart.MELODY)

    def _get_bass_part(self) -> Part:
        bass_leaves = self._get_bass_leaves()
        return Part(bass_leaves)

    def _get_melody_part(self) -> Part:
        melody_leaves = self._get_melody_leaves()
        return Part(melody_leaves)

    @property
    def _parts(self) -> tuple[Part, Part]:
        return self._bass_part, self._melody_part

    @property
    def bass_staff(self) -> Staff:
        return self._bass_input_staff or Staff()

    @property
    def melody_staff(self) -> Staff:
        return self._melody_input_staff or Staff()

    def _get_current_pitches(self) -> list[NamedPitch]:
        current_pitches = [part.current_sounding_pitch for part in self._parts]
        return remove_none_values(current_pitches)

    def _passage_contains_more_sounding_leaves(self) -> bool:
        current_notes = [part.current_sounding_leaf for part in self._parts]
        return any(current_notes)

    def _get_shortest_sounding_duration(self) -> float:
        current_durations = [
            part.current_sounding_leaf_duration for part in self._parts
        ]
        durations = remove_none_values(current_durations)
        return min(durations)

    def _get_shortest_sounding_duration_parts(
        self, shortest_duration: float
    ) -> list[Part]:
        return [
            part
            for part in self._parts
            if part.matches_current_sounding_duration(shortest_duration)
        ]

    def _get_longer_sounding_duration_parts(
        self, shortest_duration: float
    ) -> list[Part]:
        return [
            part
            for part in self._parts
            if not part.matches_current_sounding_duration(shortest_duration)
        ]

    def _get_next_pitches(self) -> list[NamedPitch]:
        shortest_duration = self._get_shortest_sounding_duration()
        shortest_sounding_duration_parts = (
            self._get_shortest_sounding_duration_parts(shortest_duration)
        )
        longer_sounding_duration_parts = (
            self._get_longer_sounding_duration_parts(shortest_duration)
        )
        for part in shortest_sounding_duration_parts:
            part.get_next_sounding_leaf()
        for part in longer_sounding_duration_parts:
            part.shorten_current_sounding_leaf(shortest_duration)
        return self._get_current_pitches()

    @staticmethod
    def _get_pitch_names(pitches: list[NamedPitch]) -> list[str]:
        return [pitch.name for pitch in pitches]

    @classmethod
    def _are_same_pitches(
        cls, new_pitches: list[NamedPitch], old_pitches: list[list[NamedPitch]]
    ) -> bool:
        new_pitch_names = cls._get_pitch_names(new_pitches)
        old_pitch_names = cls._get_pitch_names(old_pitches[-1])
        return new_pitch_names == old_pitch_names

    def _should_add_pitches(
        self,
        new_pitches: list[NamedPitch],
        old_pitches: list[list[NamedPitch]],
    ) -> bool:
        if not new_pitches:
            return False
        if self._adjacent_duplicates:
            return True
        return not self._are_same_pitches(new_pitches, old_pitches)

    @staticmethod
    def _get_ordered_unique_pitch_sets(
        pitches: list[list[NamedPitch]],
    ) -> list[list[NamedPitch]]:
        pitch_sets = [tuple(pitch_set) for pitch_set in pitches]
        pitch_sets = list(dict.fromkeys(pitch_sets))
        return [list(pitch_set) for pitch_set in pitch_sets]

    @property
    def _simultaneous_pitches(self) -> list[list[NamedPitch]]:
        pitches = [self._get_current_pitches()]
        while self._passage_contains_more_sounding_leaves():
            new_pitches = self._get_next_pitches()
            if self._should_add_pitches(new_pitches, pitches):
                pitches.append(new_pitches)
        if self._as_set:
            return self._get_ordered_unique_pitch_sets(pitches)
        return pitches

    def _passage_contains_more_leaves(self) -> bool:
        current_notes = [part.current_leaf for part in self._parts]
        return any(current_notes)

    def _current_leaves_are_notes(self) -> bool:
        if (
            self._bass_part.current_leaf
            and self._melody_part.current_leaf
            and isinstance(self._bass_part.current_leaf.leaf, Note)
            and isinstance(self._melody_part.current_leaf.leaf, Note)
        ):
            return True
        return False

    def _current_notes_have_different_durations(
        self, bass_duration: Duration | None, melody_duration: Duration | None
    ) -> bool:
        if (
            bass_duration
            and melody_duration
            and bass_duration != melody_duration
            and self._current_leaves_are_notes()
        ):
            return True
        return False

    @property
    def _current_hertz_values(self) -> set[float | None]:
        current_bass_hertz = self._bass_part.current_leaf_hertz
        current_melody_hertz = self._melody_part.current_leaf_hertz
        return {current_bass_hertz, current_melody_hertz}

    @staticmethod
    def _get_next_hertz_values(
        next_leaf_instructions: dict[Part, Duration | None]
    ) -> set[float | None]:
        next_notes = [
            part.peek_next_leaf(duration)
            for part, duration in next_leaf_instructions.items()
        ]
        next_notes = [leaf for leaf in next_notes if isinstance(leaf, Note)]
        next_pitches = [
            leaf.written_pitch
            for leaf in next_notes
            if leaf and leaf.written_pitch
        ]
        return {pitch.hertz for pitch in next_pitches}

    def _next_leaves_are_same_as_current(
        self, next_leaf_instructions: dict[Part, Duration | None]
    ) -> bool:
        next_hertz_values = self._get_next_hertz_values(next_leaf_instructions)
        return self._current_hertz_values == next_hertz_values

    @property
    def _both_parts_are_tied(self) -> bool:
        bass_tie = self._bass_part.current_leaf_tie
        melody_tie = self._melody_part.current_leaf_tie
        return bass_tie and melody_tie

    @property
    def _shorter_note_is_tied(self) -> bool:
        bass_duration = self._bass_part.current_leaf_duration
        melody_duration = self._melody_part.current_leaf_duration
        bass_tie = self._bass_part.current_leaf_tie
        melody_tie = self._melody_part.current_leaf_tie
        if not bass_duration or not melody_duration:
            return False
        return (
            bass_tie
            and bass_duration < melody_duration
            or melody_tie
            and melody_duration < bass_duration
        )

    def _get_tie(
        self, next_leaf_instructions: dict[Part, Duration | None]
    ) -> bool:
        return (
            self._both_parts_are_tied
            or self._shorter_note_is_tied
            and self._next_leaves_are_same_as_current(next_leaf_instructions)
        )

    @property
    def matrix_leaves(self) -> list[MatrixLeaf]:
        bass_part = self._bass_part
        melody_part = self._melody_part
        leaves = []
        while self._passage_contains_more_leaves():
            bass_duration = bass_part.current_leaf_duration
            melody_duration = melody_part.current_leaf_duration
            tuplet = melody_part.current_leaf_tuplet
            is_start_of_tuplet = melody_part.is_start_of_tuplet
            if (
                tuplet
                or melody_part.current_leaf
                and isinstance(melody_part.current_leaf.leaf, Note)
                and melody_duration
                and not melody_duration.is_assignable
            ):
                matrix_duration = melody_part.current_leaf_written_duration
            else:
                matrix_duration = melody_duration
            duration_to_shorten_by = melody_duration
            next_leaf_instructions: dict[Part, Duration | None] = {
                bass_part: None,
                melody_part: None,
            }
            if self._current_notes_have_different_durations(
                bass_duration, melody_duration
            ):
                if bass_duration and bass_duration < melody_duration:
                    tuplet = bass_part.current_leaf_tuplet
                    is_start_of_tuplet = bass_part.is_start_of_tuplet
                    if tuplet or not bass_duration.is_assignable:
                        matrix_duration = (
                            bass_part.current_leaf_written_duration
                        )
                    else:
                        matrix_duration = bass_duration
                    duration_to_shorten_by = bass_duration
                    next_leaf_instructions[melody_part] = (
                        duration_to_shorten_by
                    )
                else:
                    next_leaf_instructions[bass_part] = duration_to_shorten_by
            elif not tuplet and bass_part.current_leaf_tuplet:
                tuplet = bass_part.current_leaf_tuplet
            tie = self._get_tie(next_leaf_instructions)
            is_multi_measure_rest = (
                bass_part.is_multi_measure_rest
                and melody_part.is_multi_measure_rest
            )
            matrix_leaf = MatrixLeaf(
                bass_part.current_leaf_pitch,
                melody_part.current_leaf_pitch,
                matrix_duration,
                is_multi_measure_rest,
                tie,
                tuplet,
                is_start_of_tuplet,
                self._multiples,
            )
            leaves.append(matrix_leaf)
            for part, duration in next_leaf_instructions.items():
                part.get_next_leaf(duration)
        return leaves

    @property
    def matrices(self) -> list[Matrix]:
        matrices = []
        for pitches in self._simultaneous_pitches:
            if not len(pitches) == 2:
                continue
            bass, melody = pitches
            matrix = Matrix(
                bass,
                melody,
                self._multiples,
                self._pitch_type,
                self._tuning,
                self._display_format,
            )
            matrices.append(matrix)
        return matrices

    def display(self):
        for matrix in self.matrices:
            matrix.display()
