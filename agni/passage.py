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
        return any([part.metered_leaf for part in self._parts])

    @property
    def _leaves_are_notes(self) -> bool:
        bass_metered_leaf = self._bass.metered_leaf
        melody_metered_leaf = self._melody.metered_leaf
        if (
            bass_metered_leaf
            and melody_metered_leaf
            and isinstance(bass_metered_leaf.leaf, Note)
            and isinstance(melody_metered_leaf.leaf, Note)
        ):
            return True
        return False

    @property
    def _leaves_are_notes_of_different_durations(self) -> bool:
        bass_duration = self._bass.remaining_duration
        melody_duration = self._melody.remaining_duration
        if (
            self._leaves_are_notes
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
        bass_duration = bass.remaining_duration
        melody_duration = melody.remaining_duration
        if (
            self._leaves_are_notes_of_different_durations
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
            not self._leaves_are_notes_of_different_durations
            or not shorter_part.tie
            or longer_part.tie
        ):
            return False
        shorter_duration = shorter_part.remaining_duration
        duration_seeked = shorter_duration
        shorter_part_index = shorter_part._index
        longer_part_has_shortest_sounding_note = False
        while (
            shorter_part.tie
            and duration_seeked
            and duration_seeked < longer_part.remaining_duration
        ):
            shorter_part.get_next_metered_leaf()
            duration_seeked += shorter_part.remaining_duration
        longer_written_duration = longer_part.written_duration
        if (
            duration_seeked
            and duration_seeked >= longer_written_duration
            and longer_part.is_start_of_written_note
        ):
            longer_part_has_shortest_sounding_note = True
        shorter_part.seek(shorter_part_index)
        shorter_part.remaining_duration = shorter_duration
        return longer_part_has_shortest_sounding_note

    @property
    def _is_multi_measure_rest(self) -> bool:
        return (
            self._bass.is_multi_measure_rest
            and self._melody.is_multi_measure_rest
        )

    @property
    def _both_parts_are_tied(self) -> bool:
        bass_tie = self._bass.tie
        melody_tie = self._melody.tie
        return bass_tie and melody_tie

    @property
    def _shorter_note_is_tied(self) -> bool:
        bass_duration = self._bass.remaining_duration
        melody_duration = self._melody.remaining_duration
        bass_tie = self._bass.tie
        melody_tie = self._melody.tie
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
        next_leaf_instructions: dict[Part, Duration | None],
    ) -> set[float | None]:
        next_metered_leaves = [
            part.peek(duration)
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
    def _hertz(self) -> set[float | None]:
        bass_hertz = self._bass.hertz
        melody_hertz = self._melody.hertz
        return {bass_hertz, melody_hertz}

    def _next_matrix_is_same(
        self, next_leaf_instructions: dict[Part, Duration | None]
    ) -> bool:
        next_hertz_values = self._get_next_hertz_values(next_leaf_instructions)
        return self._hertz == next_hertz_values

    def _get_tie(
        self, next_leaf_instructions: dict[Part, Duration | None]
    ) -> bool:
        return (
            self._both_parts_are_tied
            or self._shorter_note_is_tied
            and self._next_matrix_is_same(next_leaf_instructions)
        )

    @property
    def _tuplet(self) -> Tuplet | None:
        shorter_part = self._shorter_part
        longer_part = self._longer_part
        shorter_part_tuplet = shorter_part.tuplet
        longer_part_tuplet = longer_part.tuplet
        if not shorter_part_tuplet and longer_part_tuplet:
            return longer_part_tuplet
        return shorter_part_tuplet

    @property
    def _is_start_of_tuplet(self) -> bool:
        shorter_part = self._shorter_part
        longer_part = self._longer_part
        if not shorter_part.tuplet and longer_part.tuplet:
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
                longer_duration = longer_part.written_duration
                matrix_duration = longer_duration
                decrement_durations[shorter_part] = longer_duration
            else:
                matrix_duration = shorter_part.matrix_duration
                if self._leaves_are_notes_of_different_durations:
                    decrement_durations[
                        longer_part
                    ] = shorter_part.remaining_duration
            matrix_leaf = MatrixLeaf(
                _bass=bass.named_pitch,
                _melody=melody.named_pitch,
                duration=matrix_duration,
                is_multi_measure_rest=self._is_multi_measure_rest,
                tie=self._get_tie(decrement_durations),
                tuplet=self._tuplet,
                is_start_of_tuplet=self._is_start_of_tuplet,
                _multiples=self._multiples,
                _pitch_type=self._pitch_type,
                _tuning=self._tuning,
                _display_format=self._display_format,
            )
            leaves.append(matrix_leaf)
            for part, duration in decrement_durations.items():
                part.get_next_metered_leaf(duration)
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
