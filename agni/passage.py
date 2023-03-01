from collections.abc import Generator
from dataclasses import dataclass
from functools import cached_property
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
from more_itertools import seekable

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
    def __init__(self, lilypond_input: str, input_part: InputPart):
        self.input_staff = self._get_input_staff(lilypond_input, input_part)
        metered_leaves = self._get_metered_leaves()
        self._leaves = seekable(metered_leaves)
        self._sounding_leaves = self._get_sounding_leaves(metered_leaves)
        self._current_index = 0
        self.current_leaf_duration: Duration | None = None
        self.current_leaf = self.get_next_leaf()
        self.current_sounding_leaf = self.get_next_sounding_leaf()

    @classmethod
    def _get_input_staff(
        cls, lilypond_input: str, input_part: InputPart
    ) -> Staff | None:
        lilypond_file = cast(LilyPondFile, parse(lilypond_input))
        items = lilypond_file.items
        score = next(block for block in items if block.name == "score")
        staves = cast(
            list[Staff], get_components(score.items, prototype=Staff)
        )
        return get_staff_by_name(staves, input_part.value)

    @staticmethod
    def _get_time_signature(leaf: Leaf) -> TimeSignature | None:
        time_signatures = get_indicators(leaf, prototype=TimeSignature)
        return next(iter(time_signatures), None)

    def _get_metered_leaves(self) -> list[MeteredLeaf]:
        staff = cast(Staff, self.input_staff)
        components = staff.components
        leaves = get_leaves(components)
        notes_in_measure = []
        current_time_signature = TimeSignature((4, 4))
        for leaf in leaves:
            time_signature = self._get_time_signature(leaf)
            if time_signature:
                current_time_signature = time_signature
            notes_in_measure.append(MeteredLeaf(leaf, current_time_signature))
        return notes_in_measure

    @property
    def current_leaf_hertz(self) -> float | None:
        current_leaf_pitch = self.current_leaf_pitch
        if not current_leaf_pitch:
            return None
        return current_leaf_pitch.hertz

    @staticmethod
    def _get_sounding_leaves(
        leaves: list[MeteredLeaf],
    ) -> Generator[SoundingLeaf, None, None]:
        sounding_leaves = (
            SoundingLeaf.from_leaves_in_measure(leaf) for leaf in leaves
        )
        return (leaf for leaf in sounding_leaves if leaf)

    def _shorten_current_leaf(self, duration: Duration):
        current_duration = self.current_leaf_duration
        if not current_duration:
            return
        shortened_duration = current_duration - duration
        if not shortened_duration:
            return
        if shortened_duration >= 0:
            self.current_leaf_duration = shortened_duration
            return
        self.get_next_leaf()
        shortened_duration = abs(shortened_duration)
        if self.current_leaf_duration == shortened_duration:
            shortened_duration = None
        self.get_next_leaf(shortened_duration)

    def get_next_leaf(
        self,
        shorten_duration: Duration | None = None,
        skip_duration: Duration | None = None,
    ) -> MeteredLeaf | None:
        if shorten_duration:
            self._shorten_current_leaf(shorten_duration)
            return None
        duration_skipped = self.current_leaf_duration
        next_leaf = next(self._leaves, None)
        if skip_duration and duration_skipped is not None:
            while not duration_skipped or duration_skipped < skip_duration:
                next_leaf = next(self._leaves, None)
                if next_leaf:
                    duration_skipped += get_duration(next_leaf.leaf)
        if next_leaf:
            self.current_leaf_duration = get_duration(next_leaf.leaf)
        self.current_leaf = next_leaf
        self._current_index += 1
        return next_leaf

    def get_next_sounding_leaf(self) -> SoundingLeaf | None:
        next_sounding_leaf = next(self._sounding_leaves, None)
        self.current_sounding_leaf = next_sounding_leaf
        return next_sounding_leaf

    @property
    def current_matrix_duration(self) -> Duration | None:
        current_duration = self.current_leaf_duration
        if (
            self.current_leaf_tuplet
            or self.current_leaf
            and isinstance(self.current_leaf.leaf, Note)
            and current_duration
            and not current_duration.is_assignable
        ):
            return self.current_leaf_written_duration
        return current_duration

    def peek_next_leaf(
        self, duration: Duration | None = None
    ) -> MeteredLeaf | None:
        if duration and duration < self.current_leaf_duration:
            return self.current_leaf
        next_leaf = self._leaves.peek(None)
        return next_leaf

    def seek(self, index: int):
        index = index - 1
        self._leaves.seek(index)
        self._current_index = index
        self.current_leaf = self.get_next_leaf()

    @property
    def current_sounding_leaf_duration(self) -> Duration | None:
        current_sounding_leaf = self.current_sounding_leaf
        if not current_sounding_leaf:
            return None
        return current_sounding_leaf.duration

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
        self._bass = self._get_bass(lilypond_input)
        self._melody = self._get_melody(lilypond_input)

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

    def _get_bass(self, lilypond_input: str) -> Part:
        return Part(lilypond_input, InputPart.BASS)

    def _get_melody(self, lilypond_input) -> Part:
        return Part(lilypond_input, InputPart.MELODY)

    @property
    def bass_staff(self) -> Staff:
        return self._bass.input_staff or Staff()

    @property
    def melody_staff(self) -> Staff:
        return self._melody.input_staff or Staff()

    @property
    def _parts(self) -> tuple[Part, Part]:
        return self._bass, self._melody

    @property
    def _current_pitches(self) -> list[NamedPitch]:
        current_pitches = [part.current_sounding_pitch for part in self._parts]
        return remove_none_values(current_pitches)

    @property
    def _contains_more_sounding_leaves(self) -> bool:
        current_notes = [part.current_sounding_leaf for part in self._parts]
        return any(current_notes)

    @property
    def _shortest_sounding_duration(self) -> float:
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
        shortest_duration = self._shortest_sounding_duration
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
        return self._current_pitches

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
        pitches = [self._current_pitches]
        while self._contains_more_sounding_leaves:
            new_pitches = self._get_next_pitches()
            if self._should_add_pitches(new_pitches, pitches):
                pitches.append(new_pitches)
        if self._as_set:
            return self._get_ordered_unique_pitch_sets(pitches)
        return pitches

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

    @property
    def _contains_more_leaves(self) -> bool:
        current_notes = [part.current_leaf for part in self._parts]
        return any(current_notes)

    @property
    def _current_leaves_are_notes(self) -> bool:
        current_bass_leaf = self._bass.current_leaf
        current_melody_leaf = self._melody.current_leaf
        if (
            current_bass_leaf
            and current_melody_leaf
            and isinstance(current_bass_leaf.leaf, Note)
            and isinstance(current_melody_leaf.leaf, Note)
        ):
            return True
        return False

    @property
    def _current_notes_have_different_durations(self) -> bool:
        bass_duration = self._bass.current_leaf_duration
        melody_duration = self._melody.current_leaf_duration
        if (
            self._current_leaves_are_notes
            and bass_duration
            and melody_duration
            and bass_duration != melody_duration
        ):
            return True
        return False

    @property
    def _bass_is_shorter_than_melody(self) -> bool:
        bass = self._bass
        melody = self._melody
        bass_duration = bass.current_leaf_duration
        melody_duration = melody.current_leaf_duration
        if (
            self._current_notes_have_different_durations
            and bass_duration
            and melody_duration
            and bass_duration < melody_duration
        ):
            return True
        return False

    @property
    def _shorter_part(self) -> Part:
        if self._bass_is_shorter_than_melody:
            return self._bass
        return self._melody

    @property
    def _longer_part(self) -> Part:
        if self._bass_is_shorter_than_melody:
            return self._melody
        return self._bass

    @property
    def _longer_part_has_shortest_sounding_note(self) -> bool:
        shorter_part = self._shorter_part
        longer_part = self._longer_part
        if (
            not self._current_notes_have_different_durations
            or not shorter_part.current_leaf_tie
            or longer_part.current_leaf_tie
        ):
            return False
        shorter_duration = shorter_part.current_leaf_duration
        duration_seeked = Duration()
        shorter_part_current_index = shorter_part._current_index
        longer_part_has_shortest_sounding_note = False
        while (
            shorter_part.current_leaf_tie
            and duration_seeked < longer_part.current_leaf_duration
        ):
            duration_seeked += shorter_part.current_leaf_duration
            shorter_part.get_next_leaf()
        next_leaf = shorter_part.peek_next_leaf()
        longer_written_duration = longer_part.current_leaf_written_duration
        if (
            duration_seeked >= longer_written_duration
            or next_leaf
            and isinstance(next_leaf.leaf, Note)
            and duration_seeked + next_leaf.leaf.written_duration
            >= longer_written_duration
            and longer_part.current_leaf_duration == longer_written_duration
        ):
            longer_part_has_shortest_sounding_note = True
        shorter_part.seek(shorter_part_current_index)
        shorter_part.current_leaf_duration = shorter_duration
        return longer_part_has_shortest_sounding_note

    @property
    def _is_multi_measure_rest(self) -> bool:
        return (
            self._bass.is_multi_measure_rest
            and self._melody.is_multi_measure_rest
        )

    @property
    def _both_parts_are_tied(self) -> bool:
        bass_tie = self._bass.current_leaf_tie
        melody_tie = self._melody.current_leaf_tie
        return bass_tie and melody_tie

    @property
    def _shorter_note_is_tied(self) -> bool:
        bass_duration = self._bass.current_leaf_duration
        melody_duration = self._melody.current_leaf_duration
        bass_tie = self._bass.current_leaf_tie
        melody_tie = self._melody.current_leaf_tie
        if not bass_duration or not melody_duration:
            return False
        return (
            bass_tie
            and bass_duration < melody_duration
            or melody_tie
            and melody_duration < bass_duration
        )

    @staticmethod
    def _get_next_hertz_values(
        next_leaf_instructions: dict[Part, Duration | None]
    ) -> set[float | None]:
        next_metered_leaves = [
            part.peek_next_leaf(duration)
            for part, duration in next_leaf_instructions.items()
        ]
        next_leaves = [
            metered_leaf.leaf
            for metered_leaf in next_metered_leaves
            if metered_leaf
        ]
        next_notes = [leaf for leaf in next_leaves if isinstance(leaf, Note)]
        next_pitches = [
            leaf.written_pitch
            for leaf in next_notes
            if leaf and leaf.written_pitch
        ]
        return {pitch.hertz for pitch in next_pitches}

    @property
    def _current_hertz_values(self) -> set[float | None]:
        current_bass_hertz = self._bass.current_leaf_hertz
        current_melody_hertz = self._melody.current_leaf_hertz
        return {current_bass_hertz, current_melody_hertz}

    def _next_leaves_are_same_as_current(
        self, next_leaf_instructions: dict[Part, Duration | None]
    ) -> bool:
        next_hertz_values = self._get_next_hertz_values(next_leaf_instructions)
        return self._current_hertz_values == next_hertz_values

    def _get_tie(
        self, next_leaf_instructions: dict[Part, Duration | None]
    ) -> bool:
        return (
            self._both_parts_are_tied
            or self._shorter_note_is_tied
            and self._next_leaves_are_same_as_current(next_leaf_instructions)
        )

    @property
    def _tuplet(self) -> Tuplet | None:
        shorter_part = self._shorter_part
        longer_part = self._longer_part
        shorter_part_tuplet = shorter_part.current_leaf_tuplet
        longer_part_tuplet = longer_part.current_leaf_tuplet
        if not shorter_part_tuplet and longer_part_tuplet:
            return longer_part_tuplet
        return shorter_part_tuplet

    @property
    def _is_start_of_tuplet(self) -> bool:
        shorter_part = self._shorter_part
        longer_part = self._longer_part
        if (
            not shorter_part.current_leaf_tuplet
            and longer_part.current_leaf_tuplet
        ):
            return longer_part.is_start_of_tuplet
        return shorter_part.is_start_of_tuplet

    @property
    def matrix_leaves(self) -> list[MatrixLeaf]:
        leaves = []
        while self._contains_more_leaves:
            bass = self._bass
            melody = self._melody
            decrement_durations: dict[Part, Duration | None] = {
                melody: None,
                bass: None,
            }
            shorter_part = self._shorter_part
            longer_part = self._longer_part
            if self._longer_part_has_shortest_sounding_note:
                longer_duration = longer_part.current_leaf_written_duration
                matrix_duration = longer_duration
                decrement_durations[shorter_part] = longer_duration
            else:
                matrix_duration = shorter_part.current_matrix_duration
                if self._current_notes_have_different_durations:
                    decrement_durations[longer_part] = (
                        shorter_part.current_leaf_duration
                    )
            matrix_leaf = MatrixLeaf(
                bass.current_leaf_pitch,
                melody.current_leaf_pitch,
                matrix_duration,
                self._is_multi_measure_rest,
                self._get_tie(decrement_durations),
                self._tuplet,
                self._is_start_of_tuplet,
                self._multiples,
            )
            leaves.append(matrix_leaf)
            for part, duration in decrement_durations.items():
                part.get_next_leaf(duration)
        return leaves

    def display(self):
        for matrix in self.matrices:
            matrix.display()
