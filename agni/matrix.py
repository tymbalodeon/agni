from collections.abc import Generator, Iterator
from dataclasses import dataclass
from enum import Enum
from functools import lru_cache
from math import log
from pathlib import Path
from time import sleep
from typing import Optional, TypeAlias, cast

from abjad import (
    Block,
    Chord,
    Clef,
    Component,
    Duration,
    InstrumentName,
    Leaf,
    LilyPondFile,
    NamedPitch,
    Note,
    NumberedPitch,
    Rest,
    Score,
    ShortInstrumentName,
    Skip,
    Staff,
    StaffGroup,
    Tie,
    TimeSignature,
    Tuplet,
    attach,
    parse,
    show,
)
from abjad.get import duration as get_duration
from abjad.get import indicators as get_indicators
from abjad.get import lineage as get_lineage
from abjad.persist import as_pdf
from abjad.select import components as get_components
from abjad.select import leaves as get_leaves
from abjad.select import logical_ties as get_logical_ties
from rich.box import SIMPLE
from rich.console import Console
from rich.progress import track
from rich.table import Table
from supriya.patterns import EventPattern, SequencePattern

Pitch: TypeAlias = NamedPitch | str | float


class InputType(Enum):
    HERTZ = "hertz"
    MIDI = "midi"


class OutputType(Enum):
    HERTZ = "hertz"
    MIDI = "midi"
    LILYPOND = "lilypond"
    ALL = "all"


class Tuning(Enum):
    MICROTONAL = "microtonal"
    EQUAL_TEMPERED = "equal-tempered"


def remove_none_values(collection: list) -> list:
    return [item for item in collection if item]


class Matrix:
    DEFAULT_MULTIPLES = 4

    def __init__(
        self,
        bass: Pitch,
        melody: Pitch,
        input_type: InputType,
        multiples: int | None = None,
    ):
        self.bass = self._get_frequency(bass, input_type)
        self.melody = self._get_frequency(melody, input_type)
        if multiples:
            self._multiples = multiples
        else:
            self._multiples = self.DEFAULT_MULTIPLES

    @staticmethod
    @lru_cache
    def _quantize_pitch(pitch: NamedPitch) -> NamedPitch:
        pitch_number = pitch.number
        if not isinstance(pitch_number, float):
            return pitch
        pitch_number = int(pitch_number)
        pitch_name = NumberedPitch(pitch_number).name
        return NamedPitch(pitch_name)

    @staticmethod
    @lru_cache
    def _convert_midi_to_frequency(midi_number: float) -> float:
        return (2 ** ((midi_number - 69) / 12)) * 440

    @classmethod
    @lru_cache
    def _get_frequency(cls, pitch: Pitch, input_type: InputType) -> float:
        if isinstance(pitch, NamedPitch):
            return pitch.hertz
        if input_type == InputType.MIDI:
            return cls._convert_midi_to_frequency(float(pitch))
        if isinstance(pitch, float):
            return pitch
        if pitch.isnumeric():
            return float(pitch)
        return NamedPitch(pitch).hertz

    @staticmethod
    @lru_cache
    def _get_sum_frequency(
        multiplier: int, bass_multiple: float, melody: float
    ) -> float:
        melody_multiple = melody * multiplier
        return bass_multiple + melody_multiple

    @classmethod
    @lru_cache
    def _get_melody_column(
        cls, multiplier: int, columns: range, bass: float, melody: float
    ) -> list[float]:
        bass_multiple = bass * multiplier
        return [
            cls._get_sum_frequency(column, bass_multiple, melody)
            for column in columns
        ]

    @lru_cache
    def get_frequencies(
        self, multiples: int | None = None
    ) -> list[list[float]]:
        if not multiples:
            multiples = self._multiples
        rows = range(multiples)
        return [
            self._get_melody_column(row, rows, self.bass, self.melody)
            for row in rows
        ]

    @lru_cache
    def get_sorted_frequencies(
        self, multiples: int | None = None, limit: int | None = None
    ) -> list[float]:
        if not multiples:
            multiples = self._multiples
        frequencies = [
            frequency
            for row in self.get_frequencies(multiples)
            for frequency in row
        ]
        frequencies.sort()
        frequencies = frequencies[1:]
        if not limit:
            return frequencies
        return frequencies[:limit]

    @staticmethod
    def _get_matrix_table(output_type: OutputType) -> Table:
        title = f"Combination-Tone Matrix ({output_type.value.title()})"
        return Table(title=title, show_header=False, box=SIMPLE)

    @staticmethod
    def _get_header_multipler(multiplier: int, pitch: str) -> str:
        return f"[bold cyan]{multiplier} * {pitch}[/bold cyan]"

    @property
    def _number_of_frequencies(self) -> int:
        return len(self.get_frequencies())

    def _get_melody_header(self) -> list[str]:
        header = [
            self._get_header_multipler(multiplier, "melody")
            for multiplier in range(self._number_of_frequencies)
        ]
        return [""] + header

    @property
    def _base_pitches(self) -> tuple[float, float]:
        return (self.bass, self.melody)

    @lru_cache
    def _get_named_pitch(self, frequency: float, tuning: Tuning) -> str | None:
        if not frequency:
            return None
        named_pitch = NamedPitch.from_hertz(frequency)
        if tuning == Tuning.EQUAL_TEMPERED:
            named_pitch = self._quantize_pitch(named_pitch)
        pitch_name = named_pitch.name
        if frequency in self._base_pitches:
            return self._bolden_pitch(pitch_name)
        return pitch_name

    @lru_cache
    def _get_midi_number(self, frequency: float, tuning: Tuning) -> str | None:
        if not frequency:
            return None
        frequency = frequency / 440
        logarithm = log(frequency, 2)
        midi_number = 12 * logarithm + 69
        if tuning == Tuning.MICROTONAL:
            midi_number = round(midi_number * 2) / 2
        else:
            midi_number = round(midi_number)
        if frequency in self._base_pitches:
            return self._bolden_pitch(midi_number)
        return str(midi_number)

    @lru_cache
    def _get_hertz(self, frequency: float, tuning: Tuning) -> str | None:
        if not frequency:
            return None
        if tuning == Tuning.MICROTONAL:
            decimals = 2
        else:
            decimals = None
        hertz = f"{round(frequency, decimals):,}"
        if frequency in self._base_pitches:
            return self._bolden_pitch(hertz)
        return hertz

    @lru_cache
    def _get_all_output_types(
        self, frequency: float, tuning: Tuning
    ) -> str | None:
        if not frequency:
            return None
        hertz = self._get_hertz(frequency, tuning)
        named_pitch = self._get_named_pitch(frequency, tuning)
        midi = self._get_midi_number(frequency, tuning)
        pitches = f"{hertz}\n{named_pitch}\n{midi}"
        if frequency in self._base_pitches:
            return self._bolden_pitch(pitches)
        return pitches

    def _get_output_pitches(
        self, row: list[float], tuning: Tuning, output_type: OutputType
    ) -> list[str | None]:
        if output_type == OutputType.LILYPOND:
            return [
                self._get_named_pitch(frequency, tuning) for frequency in row
            ]
        if output_type == OutputType.MIDI:
            return [
                self._get_midi_number(frequency, tuning) for frequency in row
            ]
        if output_type == OutputType.HERTZ:
            return [self._get_hertz(frequency, tuning) for frequency in row]
        if output_type == OutputType.ALL:
            return [
                self._get_all_output_types(frequency, tuning)
                for frequency in row
            ]
        return [self._get_hertz(frequency, tuning) for frequency in row]

    def _add_melody_header(self, table: Table):
        melody_header = self._get_melody_header()
        table.add_row(*melody_header)

    @staticmethod
    def _bolden_pitch(pitch: Pitch) -> str:
        return f"[bold yellow]{pitch}[/bold yellow]"

    @classmethod
    def _get_bass_header(cls, multiplier: int) -> list[str | None]:
        return [cls._get_header_multipler(multiplier, "bass")]

    def display(
        self,
        output_type: OutputType,
        tuning: Tuning,
        multiples: int | None = None,
    ):
        if not multiples:
            multiples = self._multiples
        table = self._get_matrix_table(output_type)
        self._add_melody_header(table)
        frequencies = self.get_frequencies(multiples)
        for multiplier, row in enumerate(frequencies):
            row_frequencies = self._get_output_pitches(
                row, tuning=tuning, output_type=output_type
            )
            bass_header = self._get_bass_header(multiplier)
            formatted_row = bass_header + row_frequencies
            table.add_row(*formatted_row)
        Console().print(table)

    @property
    def notation(self) -> "Notation":
        return Notation(self)

    def notate(
        self,
        tuning: Tuning,
        as_chord=False,
        persist=False,
        as_ensemble=False,
        multiples: int | None = None,
    ):
        if not multiples:
            multiples = self._multiples
        notation = self.notation
        notation.make_score(as_ensemble, tuning, persist, as_chord=as_chord)

    def play(self, multiples: int | None = None):
        if not multiples:
            multiples = self._multiples
        pattern = EventPattern(
            frequency=SequencePattern(self.get_sorted_frequencies()),
            delta=0.05,
        )
        pattern.play()
        sleep(5)


@dataclass
class LeafInMeasure:
    leaf: Leaf
    time_signature: TimeSignature


class Notation:
    def __init__(self, *matrices: Matrix):
        self.matrices = matrices

    @property
    def _number_of_matrices(self) -> int:
        return len(self.matrices)

    def _get_lilypond_preamble(
        self, full_score=False, passage: Optional["Passage"] = None
    ) -> str:
        if not passage:
            if self._number_of_matrices > 1:
                matrix_display = "Matrices"
            else:
                matrix_display = "Matrix"
            title = f"Combination-Tone {matrix_display}"
            composer = ""
        else:
            title = passage.title
            composer = passage.composer
        if not full_score:
            stencils = """
                \\override TimeSignature.stencil = ##f
                \\override BarLine.stencil = ##f
                \\override Stem.stencil = ##f
            """
        else:
            stencils = ""
        return f"""
                    \\header {{
                        tagline = ##f
                        title = "{title}"
                        composer = "{composer}"
                    }}

                    \\paper {{
                        #(set-paper-size "letter")
                        left-margin = 0.75\\in
                        right-margin = 0.75\\in
                        top-margin = 0.5\\in
                        bottom-margin = 0.5\\in
                    }}

                    \\layout {{
                        \\context {{
                            \\Score
                            \\numericTimeSignature
                            {stencils}
                        }}
                    }}
                """

    def _show_with_preamble(
        self, container: Component, persist: bool, full_score: bool
    ):
        lilypond_file = LilyPondFile(
            [self._get_lilypond_preamble(full_score), container]
        )
        if persist:
            pdf_file_path = Path("examples") / "matrix.pdf"
            as_pdf(lilypond_file, pdf_file_path=pdf_file_path, remove_ly=True)
        else:
            show(lilypond_file)

    def _pair_matrices_to_melody_notes(
        self, melody_passage: list[LeafInMeasure]
    ) -> list[tuple[Matrix, LeafInMeasure]]:
        pairs = []
        matrix_iterator = iter(self.matrices)
        current_matrix = None
        for note_in_measure in melody_passage:
            note = note_in_measure.leaf
            if not current_matrix or get_logical_ties(note):
                current_matrix = next(matrix_iterator, None)
                if not current_matrix:
                    break
            pair = (current_matrix, note_in_measure)
            pairs.append(pair)
        return pairs

    @staticmethod
    def _get_previous_note(
        part: list[LeafInMeasure], index: int
    ) -> LeafInMeasure | None:
        try:
            return part[index - 1]
        except Exception:
            return None

    @staticmethod
    def _get_melody_note_duration(
        note_in_measure: LeafInMeasure | None,
    ) -> Duration:
        if not note_in_measure:
            return Duration(1, 4)
        return note_in_measure.leaf.written_duration

    @staticmethod
    def _get_tie(note: Leaf | None) -> Tie | None:
        if not note:
            return None
        return next((tie for tie in get_indicators(note, prototype=Tie)), None)

    @classmethod
    def _get_melody_note_tie(
        cls, note_in_measure: LeafInMeasure | None
    ) -> Tie | None:
        if not note_in_measure:
            return None
        return cls._get_tie(note_in_measure.leaf)

    @staticmethod
    def _get_note(
        frequency: float, tuning: Tuning, duration=Duration(1, 4)
    ) -> Note:
        pitch = NamedPitch.from_hertz(frequency)
        if tuning == Tuning.EQUAL_TEMPERED:
            pitch = Matrix._quantize_pitch(pitch)
        return Note(pitch, duration)

    @classmethod
    def _get_matrix_note_from_melody_note(
        cls,
        matrix_frequency: float,
        melody_note: LeafInMeasure | None,
        tuning: Tuning,
    ) -> Note:
        duration = cls._get_melody_note_duration(melody_note)
        tie = cls._get_melody_note_tie(melody_note)
        note = cls._get_note(matrix_frequency, tuning, duration=duration)
        if tie:
            attach(tie, note)
        return note

    @staticmethod
    def _get_melody_note_time_signature(
        note: LeafInMeasure | None,
    ) -> TimeSignature | None:
        if not note:
            return None
        return note.time_signature

    @staticmethod
    def _get_clef_by_octave(octave: int) -> Clef:
        if octave < 1:
            return Clef("bass_15")
        if octave < 2:
            return Clef("bass_8")
        if octave < 4:
            return Clef("bass")
        if octave < 5:
            return Clef("treble")
        if octave < 6:
            return Clef("treble^8")
        return Clef("treble^15")

    @classmethod
    def _set_clef(cls, note: Note) -> Clef | None:
        written_pitch = note.written_pitch
        if not written_pitch:
            return None
        octave = written_pitch.octave.number
        clef = cls._get_clef_by_octave(octave)
        attach(clef, note)
        return clef

    @classmethod
    def _set_clefs(cls, notes: list[Note]):
        first_note = notes[0]
        current_clef = cls._set_clef(first_note)
        for note in notes[1:]:
            written_pitch = note.written_pitch
            if not written_pitch:
                continue
            octave = written_pitch.octave.number
            new_clef = cls._get_clef_by_octave(octave)
            if new_clef != current_clef:
                cls._set_clef(note)

    @staticmethod
    def _get_staff_name(name: str | None) -> str:
        staff_name = name or ""
        if staff_name == "0":
            staff_name = "bass"
        elif staff_name == "3":
            staff_name = "melody"
        return f"\\markup {staff_name}"

    @classmethod
    def _get_staff(
        cls, index: int, time_signature: TimeSignature | None, note: Note
    ) -> Staff:
        staff = Staff([note], name=str(index))
        staff_name = cls._get_staff_name(staff.name)
        first_leaf = staff[0]
        attach(InstrumentName(staff_name), first_leaf)
        attach(ShortInstrumentName(staff_name), first_leaf)
        if time_signature:
            attach(time_signature, first_leaf)
        return staff

    @classmethod
    def _add_new_staff(
        cls,
        staff_group: StaffGroup,
        index: int,
        note: Note,
        time_signature: TimeSignature | None,
    ):
        cls._set_clefs([note])
        staff = cls._get_staff(index, time_signature, note)
        staff_group.insert(0, staff)

    @staticmethod
    def get_staff_by_name(
        staves: StaffGroup | list[Staff], name: str
    ) -> Staff | None:
        return next((staff for staff in staves if staff.name == name), None)

    @staticmethod
    def _add_time_signature_to_note(
        note: Note,
        time_signature: TimeSignature | None,
        previous_note: LeafInMeasure | None,
    ):
        if previous_note and previous_note.time_signature != time_signature:
            attach(time_signature, note)

    @staticmethod
    def _get_tuplet(component: Component | None) -> Tuplet | None:
        if not component:
            return None
        return next(
            (
                parent
                for parent in get_lineage(component)
                if isinstance(parent, Tuplet)
            ),
            None,
        )

    @classmethod
    def _get_melody_note_tuplet(
        cls, note_in_measure: LeafInMeasure | None
    ) -> Tuplet | None:
        if not note_in_measure:
            return None
        return cls._get_tuplet(note_in_measure.leaf)

    @staticmethod
    def _is_incomplete_tuplet(component: Component) -> bool:
        previous_note_duration = get_duration(component)
        return not previous_note_duration.is_assignable

    @classmethod
    def _add_note_or_tuplet_to_staff(
        cls, melody_note: LeafInMeasure, matrix_note: Note, staff: Staff
    ):
        tuplet = cls._get_melody_note_tuplet(melody_note)
        if not tuplet:
            staff.append(matrix_note)
            return
        previous_component = staff[-1]
        if isinstance(
            previous_component, Tuplet
        ) and cls._is_incomplete_tuplet(previous_component):
            previous_component.append(matrix_note)
            staff[-1] = previous_component
            return
        multiplier = tuplet.colon_string
        new_tuplet = Tuplet(multiplier, [matrix_note])
        staff.append(new_tuplet)

    @classmethod
    def _add_matrix_to_staff_group(
        cls,
        matrix: Matrix,
        staff_group: StaffGroup,
        tuning: Tuning,
        melody_note: LeafInMeasure | None = None,
        previous_note: LeafInMeasure | None = None,
    ):
        for index, frequency in enumerate(matrix.get_sorted_frequencies()):
            matrix_note = cls._get_matrix_note_from_melody_note(
                frequency, melody_note, tuning
            )
            staff_names = [staff.name for staff in staff_group]
            staff_name = str(index)
            time_signature = cls._get_melody_note_time_signature(melody_note)
            if staff_name not in staff_names:
                cls._add_new_staff(
                    staff_group, index, matrix_note, time_signature
                )
                continue
            staff = cls.get_staff_by_name(staff_group, staff_name)
            if not staff:
                continue
            if melody_note:
                cls._add_time_signature_to_note(
                    matrix_note, time_signature, previous_note
                )
                cls._add_note_or_tuplet_to_staff(
                    melody_note, matrix_note, staff
                )
                continue
            staff.append(matrix_note)

    def _make_ensemble_score(
        self,
        tuning: Tuning,
        persist: bool,
        full_score=False,
        passage: Optional["Passage"] = None,
    ):
        staff_group = StaffGroup()
        description = "Notating matrices..."
        if passage:
            matrix_melody_note_pairs = self._pair_matrices_to_melody_notes(
                passage.melody
            )
            for index, (matrix, melody_note) in track(
                enumerate(matrix_melody_note_pairs),
                description=description,
                total=self._number_of_matrices,
            ):
                previous_note = self._get_previous_note(passage.melody, index)
                self._add_matrix_to_staff_group(
                    matrix,
                    staff_group,
                    tuning=tuning,
                    melody_note=melody_note,
                    previous_note=previous_note,
                )
        else:
            for matrix in track(self.matrices, description=description):
                self._add_matrix_to_staff_group(
                    matrix, staff_group, tuning=tuning
                )
        score = Score([staff_group])
        self._show_with_preamble(score, persist=persist, full_score=full_score)

    @staticmethod
    def _set_bass_and_melody_noteheads(notes: list[Note]) -> list[Note]:
        for note in notes[:2]:
            note.written_duration = Duration(1, 2)
        return notes

    @staticmethod
    def _get_note_name(note: Note) -> str | None:
        if not note.written_pitch:
            return None
        return note.written_pitch.name

    @classmethod
    def _get_chord_notes(cls, notes: list[Note]) -> str:
        note_names = [cls._get_note_name(note) for note in notes]
        pitched_note_names = remove_none_values(note_names)
        chord_notes = " ".join(pitched_note_names)
        return f"<{chord_notes}>"

    @classmethod
    def _add_notes_to_score(
        cls, notes: list[Note], score: Score, as_chord: bool
    ):
        notes = cls._set_bass_and_melody_noteheads(notes)
        if as_chord:
            chord_notes = cls._get_chord_notes(notes)
            components = [Chord(chord_notes)]
        else:
            components = notes
        staff = Staff(components)
        score.append(staff)

    def _make_reference_score(
        self, tuning: Tuning, as_chord: bool, persist: bool, full_score=False
    ):
        score = Score()
        for matrix in track(self.matrices, description="Notating matrices..."):
            notes = [
                self._get_note(frequency, tuning)
                for frequency in matrix.get_sorted_frequencies()
            ]
            self._set_clefs(notes)
            self._add_notes_to_score(notes, score, as_chord=as_chord)
        self._show_with_preamble(score, persist=persist, full_score=full_score)

    def make_score(
        self,
        as_ensemble: bool,
        tuning: Tuning,
        persist: bool,
        as_chord=False,
        full_score=False,
        passage: Optional["Passage"] = None,
    ):
        if as_ensemble:
            self._make_ensemble_score(
                tuning, persist=persist, full_score=full_score, passage=passage
            )
        else:
            self._make_reference_score(
                tuning,
                persist=persist,
                as_chord=as_chord,
                full_score=full_score,
            )


@dataclass
class SoundingLeaves:
    named_pitch: NamedPitch | None
    duration: Duration
    time_signature: TimeSignature

    @staticmethod
    def _get_named_pitch(leaf: Leaf) -> NamedPitch | None:
        if isinstance(leaf, Note):
            return leaf.written_pitch
        else:
            return None

    @staticmethod
    def _get_sounding_duration(leaf: Leaf) -> Duration | None:
        logical_tie = get_logical_ties(leaf)
        if not logical_tie:
            return None
        return get_duration(logical_tie)

    @classmethod
    def from_leaves_in_measure(cls, leaf_in_measure: LeafInMeasure):
        leaf = leaf_in_measure.leaf
        named_pitch = cls._get_named_pitch(leaf)
        duration = cls._get_sounding_duration(leaf_in_measure.leaf)
        if not duration:
            return None
        time_signature = leaf_in_measure.time_signature
        return cls(named_pitch, duration, time_signature)


class Part:
    def __init__(self, name: str, leaves: list[LeafInMeasure]):
        self.name = name
        self.leaves = self._get_leaves(leaves)
        self.current_leaf = self._get_next_leaf(self.leaves)

    @staticmethod
    def _get_leaves(
        leaves: list[LeafInMeasure],
    ) -> Generator[SoundingLeaves, None, None]:
        sounding_leaves = (
            SoundingLeaves.from_leaves_in_measure(leaf) for leaf in leaves
        )
        return (leaf for leaf in sounding_leaves if leaf)

    def _get_next_leaf(
        self, leaves: Iterator[SoundingLeaves] | None = None
    ) -> SoundingLeaves | None:
        if not leaves:
            leaves = self.leaves
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

    def _get_current_pitch(self) -> NamedPitch | None:
        if not self.current_leaf or isinstance(self.current_leaf, Rest):
            return None
        return self.current_leaf.named_pitch

    def _matches_duration(self, duration: float) -> bool:
        if not self.current_leaf:
            return False
        current_duration = self._get_current_duration()
        return current_duration == duration


class Passage:
    def __init__(self, input_file: Path):
        lilypond_input = input_file.read_text()
        self.title = self._get_header_item(lilypond_input, "title")
        self.composer = self._get_header_item(lilypond_input, "composer")
        staves, structure = self._get_staves_and_structure(lilypond_input)
        self.structure = structure
        self.bass = self._get_staff_leaves(staves, "bass")
        self.melody = self._get_staff_leaves(staves, "melody")

    @staticmethod
    def _get_header_item(lilypond_input: str, item: str) -> str:
        lines = lilypond_input.splitlines()
        matching_line = next((line for line in lines if item in line), None)
        if not matching_line:
            return ""
        return matching_line.split('"')[1]

    @staticmethod
    def _get_score_block(lilypond_input: str) -> Block:
        lilypond_file = cast(LilyPondFile, parse(lilypond_input))
        items = lilypond_file.items
        return next(block for block in items if block.name == "score")

    @classmethod
    def _get_staves_and_structure(
        cls,
        lilypond_input: str,
    ) -> tuple[list[Staff], list[Skip]]:
        score = cls._get_score_block(lilypond_input)
        staves = cast(
            list[Staff], get_components(score.items, prototype=Staff)
        )
        structure = cast(list[Skip], get_components(staves, prototype=Skip))
        return staves, structure

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
    def _get_notes_in_measure(cls, notes: list[Leaf]) -> list[LeafInMeasure]:
        notes_in_measure = []
        current_time_signature = TimeSignature((4, 4))
        for note in notes:
            time_signature = cls._get_time_signature(note)
            if time_signature:
                current_time_signature = time_signature
            notes_in_measure.append(
                LeafInMeasure(note, current_time_signature)
            )
        return notes_in_measure

    @classmethod
    def _get_staff_leaves(
        cls, staves: list[Staff], part: str
    ) -> list[LeafInMeasure]:
        staff = Notation.get_staff_by_name(staves, part)
        if not staff:
            return []
        components = staff.components
        leaves = get_leaves(components)
        return cls._get_notes_in_measure(leaves)

    @property
    def parts(self) -> list[Part]:
        bass = self.bass
        melody = self.melody
        parts = bass, melody
        return [Part(str(index), part) for index, part in enumerate(parts)]

    def _get_current_pitches(self) -> list[NamedPitch]:
        current_pitches = [part._get_current_pitch() for part in self.parts]
        return remove_none_values(current_pitches)

    def _is_end_of_passage(self) -> bool:
        current_notes = [part.current_leaf for part in self.parts]
        return not any(current_notes)

    def _get_shortest_duration(self) -> float:
        current_durations = [
            part._get_current_duration() for part in self.parts
        ]
        durations = remove_none_values(current_durations)
        return min(durations)

    def _get_parts_matching_shortest_duration(
        self, shortest_duration
    ) -> list[Part]:
        return [
            part
            for part in self.parts
            if part._matches_duration(shortest_duration)
        ]

    def _get_parts_with_longer_durations(
        self, shortest_duration
    ) -> list[Part]:
        return [
            part
            for part in self.parts
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

    @classmethod
    def _should_add_pitches(
        cls,
        adjacent_duplicates: bool,
        new_pitches: list[NamedPitch],
        old_pitches: list[list[NamedPitch]],
    ) -> bool:
        if not new_pitches:
            return False
        if adjacent_duplicates:
            return True
        return not cls._are_same_pitches(new_pitches, old_pitches)

    @staticmethod
    def _get_ordered_unique_pitch_sets(
        pitches: list[list[NamedPitch]],
    ) -> list[list[NamedPitch]]:
        pitch_sets = [tuple(pitch_set) for pitch_set in pitches]
        pitch_sets = list(dict.fromkeys(pitch_sets))
        return [list(pitch_set) for pitch_set in pitch_sets]

    def _get_simultaneous_pitches(
        self, as_set=True, adjacent_duplicates=False
    ) -> list[list[NamedPitch]]:
        pitches = [self._get_current_pitches()]
        while not self._is_end_of_passage():
            new_pitches = self._get_next_pitches()
            if self._should_add_pitches(
                adjacent_duplicates, new_pitches, pitches
            ):
                pitches.append(new_pitches)
        if as_set:
            return self._get_ordered_unique_pitch_sets(pitches)
        return pitches

    def get_matrices(
        self, multiples: int, as_set: bool, adjacent_duplicates: bool
    ) -> list[Matrix]:
        simultaneous_pitches = self._get_simultaneous_pitches(
            as_set=as_set,
            adjacent_duplicates=adjacent_duplicates,
        )
        matrices = []
        for pitches in simultaneous_pitches:
            if not len(pitches) == 2:
                continue
            bass, melody = pitches
            matrix = Matrix(
                bass, melody, input_type=InputType.HERTZ, multiples=multiples
            )
            matrices.append(matrix)
        return matrices

    def _get_notation(
        self, multiples: int, as_set: bool, adjacent_duplicates: bool
    ) -> Notation:
        return Notation(
            *self.get_matrices(multiples, as_set, adjacent_duplicates)
        )

    def display(
        self,
        output_type: OutputType,
        tuning: Tuning,
        multiples: int,
        as_set: bool,
        adjacent_duplicates: bool,
    ):
        for matrix in self.get_matrices(
            multiples, as_set, adjacent_duplicates
        ):
            matrix.display(output_type, tuning)

    def notate(
        self,
        tuning: Tuning,
        multiples: int,
        as_chord: bool,
        persist: bool,
        as_ensemble: bool,
        as_set: bool,
        adjacent_duplicates: bool,
        full_score: bool,
    ):
        if not full_score:
            passage = None
        else:
            passage = self
        notation = self._get_notation(multiples, as_set, adjacent_duplicates)
        notation.make_score(
            as_ensemble,
            tuning,
            persist,
            as_chord=as_chord,
            full_score=full_score,
            passage=passage,
        )
