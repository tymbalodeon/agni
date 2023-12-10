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
        self._metered_leaves = seekable(metered_leaves)
        self._index = 0
        self.remaining_duration: Duration | None = None
        self.metered_leaf = self.get_next_metered_leaf()

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
        return get_staff_by_name(staves, input_part)

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

    def _shorten_leaf(self, duration: Duration):
        remaining_duration = self.remaining_duration
        if not remaining_duration:
            return
        shortened_duration = remaining_duration - duration
        if not shortened_duration:
            return
        if shortened_duration >= 0:
            self.remaining_duration = shortened_duration
            return
        self.get_next_metered_leaf()
        shortened_duration = abs(shortened_duration)
        if self.remaining_duration == shortened_duration:
            shortened_duration = None
        self.get_next_metered_leaf(shortened_duration)

    def get_next_metered_leaf(
        self,
        shorten_duration: Duration | None = None,
        skip_duration: Duration | None = None,
    ) -> MeteredLeaf | None:
        if shorten_duration:
            self._shorten_leaf(shorten_duration)
            return None
        duration_skipped = self.remaining_duration
        next_leaf = next(self._metered_leaves, None)
        if skip_duration and duration_skipped is not None:
            while not duration_skipped or duration_skipped < skip_duration:
                next_leaf = next(self._metered_leaves, None)
                if next_leaf:
                    duration_skipped += get_duration(next_leaf.leaf)
        if next_leaf:
            self.remaining_duration = get_duration(next_leaf.leaf)
        self.metered_leaf = next_leaf
        self._index += 1
        return next_leaf

    def peek(self, duration: Duration | None = None) -> MeteredLeaf | None:
        if duration and duration < self.remaining_duration:
            return self.metered_leaf
        next_leaf = self._metered_leaves.peek(None)
        return next_leaf

    def seek(self, index: int):
        index = index - 1
        self._metered_leaves.seek(index)
        self._index = index
        self.metered_leaf = self.get_next_metered_leaf()

    @property
    def named_pitch(self) -> NamedPitch | None:
        metered_leaf = self.metered_leaf
        if not metered_leaf or not isinstance(metered_leaf.leaf, Note):
            return None
        return metered_leaf.leaf.written_pitch

    @property
    def matrix_duration(self) -> Duration | None:
        remaining_duration = self.remaining_duration
        if (
            self.tuplet
            or self.metered_leaf
            and isinstance(self.metered_leaf.leaf, Note)
            and remaining_duration
            and not remaining_duration.is_assignable
        ):
            return self.written_duration
        return remaining_duration

    @property
    def written_duration(self) -> Duration | None:
        metered_leaf = self.metered_leaf
        if not metered_leaf:
            return None
        return metered_leaf.leaf.written_duration

    @property
    def is_start_of_written_note(self) -> bool:
        return self.remaining_duration == self.written_duration

    @property
    def is_multi_measure_rest(self) -> bool:
        if not self.metered_leaf or not isinstance(
            self.metered_leaf.leaf, MultimeasureRest
        ):
            return False
        return True

    @property
    def hertz(self) -> float | None:
        named_pitch = self.named_pitch
        if not named_pitch:
            return None
        return named_pitch.hertz

    @property
    def tie(self) -> bool:
        if not self.metered_leaf:
            return False
        ties = get_indicators(self.metered_leaf.leaf, prototype=Tie)
        return bool(ties)

    @property
    def tuplet(self) -> Tuplet | None:
        if not self.metered_leaf or not self.remaining_duration:
            return None
        leaf = self.metered_leaf.leaf
        parent = get_parentage(leaf).parent
        if isinstance(parent, Tuplet):
            return parent
        return None

    @property
    def is_start_of_tuplet(self) -> bool:
        if not self.metered_leaf or not self.tuplet:
            return False
        return self.tuplet.index(self.metered_leaf.leaf) == 0
