from dataclasses import dataclass
from typing import cast

from abjad import (
    Duration,
    Leaf,
    LilyPondFile,
    MultimeasureRest,
    NamedPitch,
    Note,
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
from more_itertools import seekable

from .helpers import InputPart, get_staff_by_name


@dataclass
class MeteredLeaf:
    leaf: Leaf
    time_signature: TimeSignature


class Part:
    def __init__(self, lilypond_input: str, input_part: InputPart):
        self.input_staff = self._get_input_staff(lilypond_input, input_part)
        metered_leaves = self._get_metered_leaves()
        self._leaves = seekable(metered_leaves)
        self._current_index = 0
        self.current_leaf_duration: Duration | None = None
        self.current_leaf = self.get_next_leaf()

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

    @staticmethod
    def _get_time_signature(leaf: Leaf) -> TimeSignature | None:
        time_signatures = get_indicators(leaf, prototype=TimeSignature)
        return next(iter(time_signatures), None)

    @property
    def current_leaf_hertz(self) -> float | None:
        current_leaf_pitch = self.current_leaf_pitch
        if not current_leaf_pitch:
            return None
        return current_leaf_pitch.hertz

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
    def current_leaf_pitch(self) -> NamedPitch | None:
        current_leaf = self.current_leaf
        if not current_leaf or not isinstance(current_leaf.leaf, Note):
            return None
        return current_leaf.leaf.written_pitch

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

    @property
    def is_start_of_written_note(self) -> bool:
        return self.current_leaf_duration == self.current_leaf_written_duration
