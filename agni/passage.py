from collections.abc import Generator
from dataclasses import dataclass
from enum import Enum
from functools import lru_cache
from pathlib import Path
from typing import cast

from abjad import (
    Duration,
    Leaf,
    LilyPondFile,
    NamedPitch,
    Note,
    Rest,
    Staff,
    TimeSignature,
    parse,
)
from abjad.get import duration as get_duration
from abjad.get import indicators as get_indicators
from abjad.select import components as get_components
from abjad.select import leaves as get_leaves
from abjad.select import logical_ties as get_logical_ties

from .helpers import get_staff_by_name, remove_none_values
from .matrix import DisplayFormat, Matrix
from .matrix_frequency import PitchType, Tuning


class InputPart(Enum):
    BASS = "bass"
    MELODY = "melody"


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
        self._leaves = (leaf for leaf in leaves)
        self._sounding_leaves = self._get_leaves(leaves)
        self.current_leaf_duration = None
        self.current_leaf = self.get_next_leaf()
        self.current_sounding_leaf = self.get_next_sounding_leaf()

    @staticmethod
    def _get_leaves(
        leaves: list[MeteredLeaf],
    ) -> Generator[SoundingLeaf, None, None]:
        sounding_leaves = (
            SoundingLeaf.from_leaves_in_measure(leaf) for leaf in leaves
        )
        return (leaf for leaf in sounding_leaves if leaf)

    def get_next_leaf(self) -> MeteredLeaf | None:
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

    def shorten_current_leaf(self, duration: Duration):
        if not self.current_leaf:
            return
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
        self._bass_staff = self._get_bass_staff(lilypond_input)
        self._melody_staff = self._get_melody_staff(lilypond_input)
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
    def _get_time_signature(note: Leaf) -> TimeSignature | None:
        return next(
            (
                time_signature
                for time_signature in get_indicators(
                    note, prototype=TimeSignature
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
            staff = self._bass_staff
        else:
            staff = self._melody_staff
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
        return self._bass_staff or Staff()

    @property
    def melody_staff(self) -> Staff:
        return self._melody_staff or Staff()

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

    def _simultaneous_leaves(self):
        bass_part = self._bass_part
        melody_part = self._melody_part
        while self._passage_contains_more_leaves():
            print(bass_part.current_leaf_pitch, melody_part.current_leaf_pitch)
            if (
                bass_part.current_leaf
                and isinstance(bass_part.current_leaf.leaf, Note)
                and melody_part.current_leaf
                and isinstance(melody_part.current_leaf.leaf, Note)
            ):
                bass_duration = bass_part.current_leaf_duration
                melody_duration = melody_part.current_leaf_duration
                if bass_duration and melody_duration:
                    if bass_duration != melody_duration:
                        if bass_duration < melody_duration:
                            bass_part.get_next_leaf()
                            melody_part.shorten_current_leaf(bass_duration)
                        else:
                            melody_part.get_next_leaf()
                            bass_part.shorten_current_leaf(melody_duration)
                            continue
            bass_part.get_next_leaf()
            melody_part.get_next_leaf()

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
        # for matrix in self.matrices:
        #     matrix.display()
        from rich import print

        leaves = self._simultaneous_leaves()
        print(leaves)
