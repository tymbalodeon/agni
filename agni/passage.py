from collections.abc import Generator
from dataclasses import dataclass
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
        self._leaves = self._get_leaves(leaves)
        self.current_leaf = self._get_next_leaf()

    @staticmethod
    def _get_leaves(
        leaves: list[MeteredLeaf],
    ) -> Generator[SoundingLeaf, None, None]:
        sounding_leaves = (
            SoundingLeaf.from_leaves_in_measure(leaf) for leaf in leaves
        )
        return (leaf for leaf in sounding_leaves if leaf)

    def _get_next_leaf(self) -> SoundingLeaf | None:
        leaves = self._leaves
        self.current_leaf = next(leaves, None)
        return self.current_leaf

    def _get_current_duration(self) -> Duration | None:
        if not self.current_leaf:
            return None
        return self.current_leaf.duration

    def _shorten_current_leaf(self, duration: float):
        if not self.current_leaf:
            return
        current_duration = self._get_current_duration()
        if not current_duration:
            return
        shorter_duration = current_duration - duration
        self.current_leaf.duration = shorter_duration

    def get_current_pitch(self) -> NamedPitch | None:
        if not self.current_leaf or isinstance(self.current_leaf, Rest):
            return None
        return self.current_leaf.named_pitch

    def _matches_duration(self, duration: float) -> bool:
        if not self.current_leaf:
            return False
        current_duration = self._get_current_duration()
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
        self.bass = self._get_bass_leaves(lilypond_input)
        self.melody = self._get_melody_leaves(lilypond_input)
        self._parts = self._get_parts()

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

    @classmethod
    def _get_staff_leaves(
        cls, lilypond_input: str, name: str
    ) -> list[MeteredLeaf]:
        staves = cls._get_staves(lilypond_input)
        staff = get_staff_by_name(staves, name)
        if not staff:
            return []
        components = staff.components
        leaves = get_leaves(components)
        return cls._get_metered_leaves(leaves)

    @classmethod
    def _get_bass_leaves(cls, lilypond_input: str):
        return cls._get_staff_leaves(lilypond_input, "bass")

    @classmethod
    def _get_melody_leaves(cls, lilypond_input: str):
        return cls._get_staff_leaves(lilypond_input, "melody")

    def _get_parts(self) -> list[Part]:
        bass_leaves = self.bass
        melody_leaves = self.melody
        parts = bass_leaves, melody_leaves
        return [Part(part) for part in parts]

    def _get_current_pitches(self) -> list[NamedPitch]:
        current_pitches = [part.get_current_pitch() for part in self._parts]
        return remove_none_values(current_pitches)

    def _is_end_of_passage(self) -> bool:
        current_notes = [part.current_leaf for part in self._parts]
        return not any(current_notes)

    def _get_shortest_duration(self) -> float:
        current_durations = [
            part._get_current_duration() for part in self._parts
        ]
        durations = remove_none_values(current_durations)
        return min(durations)

    def _get_parts_matching_shortest_duration(
        self, shortest_duration: float
    ) -> list[Part]:
        return [
            part
            for part in self._parts
            if part._matches_duration(shortest_duration)
        ]

    def _get_parts_with_longer_durations(
        self, shortest_duration: float
    ) -> list[Part]:
        return [
            part
            for part in self._parts
            if not part._matches_duration(shortest_duration)
        ]

    def _get_next_pitches(self) -> list[NamedPitch]:
        shortest_duration = self._get_shortest_duration()
        parts_matching_shortest_duration = (
            self._get_parts_matching_shortest_duration(shortest_duration)
        )
        parts_with_longer_durations = self._get_parts_with_longer_durations(
            shortest_duration
        )
        for part in parts_matching_shortest_duration:
            part._get_next_leaf()
        for part in parts_with_longer_durations:
            part._shorten_current_leaf(shortest_duration)
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
        while not self._is_end_of_passage():
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

    def display(self):
        for matrix in self.matrices:
            matrix.display()
