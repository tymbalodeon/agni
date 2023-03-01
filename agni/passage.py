from functools import cached_property
from pathlib import Path

from abjad import Duration, Note, Staff, Tuplet

from .helpers import InputPart
from .matrix import DisplayFormat, Matrix
from .matrix_leaf import MatrixLeaf
from .matrix_pitch import PitchType, Tuning
from .part import Part


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
        duration_seeked = shorter_duration
        shorter_part_current_index = shorter_part._current_index
        longer_part_has_shortest_sounding_note = False
        while (
            shorter_part.current_leaf_tie
            and duration_seeked
            and duration_seeked < longer_part.current_leaf_duration
        ):
            shorter_part.get_next_leaf()
            duration_seeked += shorter_part.current_leaf_duration
        longer_written_duration = longer_part.current_leaf_written_duration
        if (
            duration_seeked
            and duration_seeked >= longer_written_duration
            and longer_part.is_start_of_written_note
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

    @cached_property
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
                self._pitch_type,
                self._tuning,
                self._display_format,
            )
            leaves.append(matrix_leaf)
            for part, duration in decrement_durations.items():
                part.get_next_leaf(duration)
        return leaves

    @property
    def matrices(self) -> list[Matrix]:
        matrices = [
            matrix_leaf.matrix
            for matrix_leaf in self.matrix_leaves
            if matrix_leaf.matrix
        ]
        if self._as_set:
            return list(dict.fromkeys(matrices))
        if not self._adjacent_duplicates:
            return [
                matrix
                for index, matrix in enumerate(matrices)
                if index == 0 or index != matrices[index - 1]
            ]
        return matrices

    def display(self):
        for matrix in self.matrices:
            matrix.display()
