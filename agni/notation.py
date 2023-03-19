from collections.abc import Iterable
from functools import cached_property
from pathlib import Path
from statistics import mode
from typing import cast

from abjad import (
    BarLine,
    Chord,
    Clef,
    Component,
    Duration,
    InstrumentName,
    Leaf,
    LilyPondFile,
    LilyPondLiteral,
    MultimeasureRest,
    NamedPitch,
    Note,
    NumberedPitch,
    Rest,
    Score,
    ShortInstrumentName,
    Staff,
    StaffGroup,
    Tie,
    TimeSignature,
    Tuplet,
    attach,
    show,
)
from abjad.get import duration as get_duration
from abjad.get import indicators as get_indicators
from abjad.get import lineage as get_lineage
from abjad.persist import as_pdf
from abjad.select import leaves as get_leaves
from abjad.select import notes as get_notes
from abjad.select import tuplets as get_tuplets
from abjadext.rmakers import multiplied_duration
from rich.progress import Progress, track

from .helpers import get_staff_by_name, remove_none_values
from .matrix import Matrix
from .matrix_leaf import MatrixLeaf
from .matrix_pitch import MatrixPitch, Tuning
from .part import MeteredLeaf
from .passage import Passage


class Notation:
    PROGRESS_DESCRIPTION = "Generating matrices..."

    def __init__(
        self,
        input: Matrix | Passage,
        as_ensemble: bool,
        tuning: Tuning,
        save: bool,
        as_chord: bool,
        output_directory: Path,
        full_score: bool = False,
    ):
        if isinstance(input, Matrix):
            matrices = [input]
            self._passage = None
        else:
            matrices = input.matrices
            self._passage = input
        self._number_of_matrices = len(matrices)
        self._matrices = track(matrices, description=self.PROGRESS_DESCRIPTION)
        self._as_ensemble = as_ensemble
        self._tuning = tuning
        self._save = save
        self._as_chord = as_chord
        self._full_score = full_score
        self._output_directory = output_directory

    @staticmethod
    def _get_first_staff_leaf(staff: Staff) -> Leaf | None:
        leaves = get_leaves(staff)
        if not leaves:
            return None
        return leaves[0]

    @classmethod
    def _set_staff_instrument_name(
        cls, staff: Staff, name: str | int | None = None
    ):
        name = name or staff.name or ""
        if isinstance(name, str):
            name = name.title()
        instrument_name = cls._make_markup(name)
        first_leaf = cls._get_first_staff_leaf(staff)
        attach(InstrumentName(instrument_name), first_leaf)
        attach(ShortInstrumentName(instrument_name), first_leaf)

    @property
    def _matrix_leaves(self) -> Iterable[MatrixLeaf]:
        passage = self._passage
        if not passage:
            return []
        matrix_leaves = passage.matrix_leaves
        return track(matrix_leaves, description=self.PROGRESS_DESCRIPTION)

    @property
    def _input_staves(self) -> list[Staff]:
        passage = self._passage
        if not passage:
            return []
        bass = passage.bass_staff
        melody = passage.melody_staff
        for staff in bass, melody:
            self._set_staff_instrument_name(staff)
        return [bass, melody]

    @staticmethod
    def _make_markup(text: str | int) -> str:
        if isinstance(text, str) and "\\markup" in text:
            return text
        command = "\\markup"
        return f"{command} {{ {text} }}"

    @classmethod
    def _add_leaf_to_staff(
        cls,
        staff_group: StaffGroup,
        instrument_name: str,
        leaf: Leaf,
        tuplet: Tuplet | None,
        is_start_of_tuplet: bool,
    ):
        if tuplet and is_start_of_tuplet:
            multiplier = tuplet.multiplier
            component: Leaf | Tuplet = Tuplet(multiplier, components=[leaf])
        else:
            component = leaf
        staff = next(
            (staff for staff in staff_group if staff.name == instrument_name),
            None,
        )
        if staff:
            if tuplet and not is_start_of_tuplet:
                parent = get_tuplets(staff)[-1]
            else:
                parent = staff
            parent.append(component)
        else:
            staff = Staff([component], name=instrument_name)
            instrument_name_markup = cls._make_markup(instrument_name)
            instrument_name_markup = instrument_name_markup.replace("'", "")
            first_leaf = staff[0]
            attach(InstrumentName(instrument_name_markup), first_leaf)
            attach(ShortInstrumentName(instrument_name_markup), first_leaf)
            staff_group.insert(0, staff)

    @classmethod
    def _add_notes_to_staff(
        cls, matrix_leaf: MatrixLeaf, staff_group: StaffGroup
    ):
        duration = matrix_leaf.duration
        if not duration:
            return
        for matrix_pitch in matrix_leaf.generated_pitches:
            note = matrix_pitch.get_note(duration, matrix_leaf.tie)
            if not note:
                continue
            instrument_names = matrix_pitch.instrument_name
            cls._add_leaf_to_staff(
                staff_group,
                instrument_names,
                note,
                matrix_leaf.tuplet,
                matrix_leaf.is_start_of_tuplet,
            )

    @classmethod
    def _get_rest(
        cls, duration: Duration, is_multi_measure_rest: bool
    ) -> Rest | MultimeasureRest:
        if is_multi_measure_rest:
            return cast(
                MultimeasureRest,
                multiplied_duration([duration], MultimeasureRest)[0],
            )
        return Rest(duration)

    @classmethod
    def _add_rests_to_staff(
        cls, matrix_leaf: MatrixLeaf, staff_group: StaffGroup
    ):
        duration = matrix_leaf.duration
        if not duration:
            return
        for instrument_names in matrix_leaf.instrument_names:
            rest = cls._get_rest(duration, matrix_leaf.is_multi_measure_rest)
            cls._add_leaf_to_staff(
                staff_group,
                instrument_names,
                rest,
                matrix_leaf.tuplet,
                matrix_leaf.is_start_of_tuplet,
            )

    @staticmethod
    def _get_melody_note_duration(
        metered_leaf: MeteredLeaf | None,
    ) -> Duration:
        if not metered_leaf:
            return Duration(1, 4)
        return metered_leaf.leaf.written_duration

    @staticmethod
    def _get_tie(note: Leaf | None) -> Tie | None:
        if not note:
            return None
        return next(iter(get_indicators(note, prototype=Tie)), None)

    @classmethod
    def _get_melody_note_tie(
        cls, metered_leaf: MeteredLeaf | None
    ) -> Tie | None:
        if not metered_leaf:
            return None
        return cls._get_tie(metered_leaf.leaf)

    def _get_note(
        self,
        frequency: float,
        duration: Duration | None = None,
        is_base_frequency=False,
    ) -> Note:
        if not duration:
            if is_base_frequency:
                duration = Duration(1, 2)
            else:
                duration = Duration(1, 4)
        pitch = NamedPitch.from_hertz(frequency)
        if self._tuning == Tuning.EQUAL_TEMPERED:
            pitch_number = pitch.number
            if isinstance(pitch_number, float):
                pitch_number = int(pitch_number)
                pitch_name = NumberedPitch(pitch_number).name
                pitch = NamedPitch(pitch_name)
        return Note(pitch, duration)

    def _get_matrix_note_from_melody_note(
        self, matrix_pitch: MatrixPitch, melody_note: MeteredLeaf | None
    ) -> Note:
        duration = self._get_melody_note_duration(melody_note)
        tie = self._get_melody_note_tie(melody_note)
        note = self._get_note(matrix_pitch.frequency or 0, duration=duration)
        if tie:
            attach(tie, note)
        return note

    @staticmethod
    def _get_melody_note_time_signature(
        note: MeteredLeaf | None,
    ) -> TimeSignature | None:
        if not note:
            return None
        return note.time_signature

    @staticmethod
    def _get_clef(octave: int) -> Clef:
        if octave < 1:
            return Clef("bass_15")
        if octave < 2:
            return Clef("bass_8")
        if octave < 4:
            return Clef("bass")
        if octave < 6:
            return Clef("treble")
        if octave < 7:
            return Clef("treble^8")
        return Clef("treble^15")

    @classmethod
    def _set_clef(cls, note: Note, clef: Clef | None = None) -> Clef | None:
        if clef is None:
            written_pitch = note.written_pitch
            if not written_pitch:
                return None
            octave = written_pitch.octave.number
            clef = cls._get_clef(octave)
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
            new_clef = cls._get_clef(octave)
            if new_clef != current_clef:
                cls._set_clef(note, new_clef)
            current_clef = new_clef

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
    def _add_time_signature_to_note(
        note: Note,
        time_signature: TimeSignature | None,
        previous_note: MeteredLeaf | None,
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
        cls, metered_leaf: MeteredLeaf | None
    ) -> Tuplet | None:
        if not metered_leaf:
            return None
        return cls._get_tuplet(metered_leaf.leaf)

    @staticmethod
    def _is_incomplete_tuplet(component: Component) -> bool:
        previous_note_duration = get_duration(component)
        return not previous_note_duration.is_assignable

    @classmethod
    def _add_note_or_tuplet_to_staff(
        cls, melody_note: MeteredLeaf, matrix_note: Note, staff: Staff
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

    def _add_matrix_to_staff_group(
        self,
        matrix: Matrix,
        staff_group: StaffGroup,
        melody_note: MeteredLeaf | None = None,
        previous_note: MeteredLeaf | None = None,
    ):
        for index, frequency in enumerate(matrix.sorted_pitches):
            matrix_note = self._get_matrix_note_from_melody_note(
                frequency, melody_note
            )
            staff_names = [staff.name for staff in staff_group]
            staff_name = str(index)
            time_signature = self._get_melody_note_time_signature(melody_note)
            if staff_name not in staff_names:
                self._add_new_staff(
                    staff_group, index, matrix_note, time_signature
                )
                continue
            staff = get_staff_by_name(staff_group, staff_name)
            if not staff:
                continue
            if melody_note:
                self._add_time_signature_to_note(
                    matrix_note, time_signature, previous_note
                )
                self._add_note_or_tuplet_to_staff(
                    melody_note, matrix_note, staff
                )
                continue
            staff.append(matrix_note)

    @staticmethod
    def _add_double_bar_lines(staff_group: StaffGroup):
        for staff in staff_group:
            leaves = get_leaves(staff)
            if not leaves:
                return
            last_leaf = leaves[-1]
            attach(BarLine("|."), last_leaf)

    @classmethod
    def _set_staff_group_clefs(cls, staff_group: StaffGroup):
        staves = [
            staff
            for staff in staff_group
            if staff.name not in ["bass", "melody"]
        ]
        for staff in staves:
            written_pitches = [note.written_pitch for note in get_notes(staff)]
            pitches = [note for note in written_pitches if note]
            octaves = [pitch.octave.number for pitch in pitches]
            octave = mode(octaves)
            clef = cls._get_clef(octave)
            leaves = get_leaves(staff)
            if not leaves:
                continue
            first_leaf = leaves[0]
            attach(clef, first_leaf)

    def _get_ensemble_score(self) -> Score:
        staff_group = StaffGroup()
        passage = self._passage
        if passage:
            for staff in reversed(self._input_staves):
                staff_group.append(staff)
            for matrix_leaf in self._matrix_leaves:
                duration = matrix_leaf.duration
                if not duration:
                    continue
                if matrix_leaf.contains_pitches:
                    self._add_notes_to_staff(matrix_leaf, staff_group)
                else:
                    self._add_rests_to_staff(matrix_leaf, staff_group)
        else:
            for matrix in self._matrices:
                self._add_matrix_to_staff_group(matrix, staff_group)
        self._add_double_bar_lines(staff_group)
        self._set_staff_group_clefs(staff_group)
        score = Score([staff_group])
        attach(LilyPondLiteral(r"\compressMMRests"), score)
        return score

    def _get_matrix_notes(self, matrix: Matrix) -> list[Note]:
        notes = [
            self._get_note(
                frequency.frequency,
                is_base_frequency=frequency.is_base_frequency,
            )
            for frequency in matrix.sorted_pitches
            if frequency.frequency
        ]
        self._set_clefs(notes)
        return notes

    @staticmethod
    def _get_note_name(note: Note) -> str | None:
        if not note.written_pitch:
            return None
        return note.written_pitch.name

    @classmethod
    def _get_chord(cls, notes: list[Note]) -> Chord:
        note_names = [cls._get_note_name(note) for note in notes]
        pitched_note_names = remove_none_values(note_names)
        chord_notes = " ".join(pitched_note_names)
        return Chord(f"<{chord_notes}>")

    def _get_matrix_score(self, matrix: Matrix) -> Score:
        notes = self._get_matrix_notes(matrix)
        if self._as_chord:
            components: list[Chord] | list[Note] = [self._get_chord(notes)]
        else:
            components = notes
        return Score([Staff(components)])

    def _get_reference_score(self) -> list[Score]:
        scores = [self._get_matrix_score(matrix) for matrix in self._matrices]
        for index, score in enumerate(scores):
            staff = next(iter(score.components), None)
            if staff:
                name = index + 1
                self._set_staff_instrument_name(staff, name=name)
        return scores

    @property
    def _scores(self) -> list[Score]:
        if self._as_ensemble:
            return [self._get_ensemble_score()]
        return self._get_reference_score()

    @cached_property
    def _title(self) -> str:
        if not self._passage:
            if self._number_of_matrices > 1:
                matrix_display = "Matrices"
            else:
                matrix_display = "Matrix"
            return f"Combination-Tone {matrix_display}"
        return self._passage.title

    @cached_property
    def _composer(self) -> str:
        if not self._passage:
            return ""
        return self._passage.composer

    @property
    def _stencils(self) -> str:
        if self._full_score:
            return ""
        return """
            \\override TimeSignature.stencil = ##f
            \\override BarLine.stencil = ##f
            \\override Stem.stencil = ##f
        """

    @property
    def _indent(self) -> str:
        if self._full_score:
            return ""
        return "indent = 0"

    @property
    def _lilypond_preamble(self) -> str:
        return f"""
                    \\header {{
                        tagline = ##f
                        title = "{self._title}"
                        composer = "{self._composer}"
                    }}

                    \\paper {{
                        #(set-paper-size "letter")
                        left-margin = 1.25\\in
                        right-margin = 0.75\\in
                        top-margin = 0.5\\in
                        bottom-margin = 0.5\\in
                    }}

                    \\layout {{
                        {self._indent}
                        \\context {{
                            \\Score
                            \\numericTimeSignature
                            {self._stencils}
                        }}
                    }}
                """

    @staticmethod
    def _format_for_filename(text: str) -> str:
        return text.lower().replace(" ", "-")

    @property
    def _output_type(self) -> str:
        if self._as_ensemble:
            return "ensemble"
        return "reference"

    def notate(self):
        lilypond_file = LilyPondFile([self._lilypond_preamble] + self._scores)
        if self._save:
            composer = self._format_for_filename(self._composer)
            title = self._format_for_filename(self._title)
            output_type = self._output_type
            pdf_file_path = (
                self._output_directory
                / f"{composer}-{title}-{output_type}-matrices.pdf"
            )
            with Progress() as progress:
                progress.add_task("Engraving score...", total=None)
                as_pdf(
                    lilypond_file, pdf_file_path=pdf_file_path, remove_ly=True
                )
            print(f"Score saved to: {pdf_file_path}")
        else:
            with Progress() as progress:
                progress.add_task("Engraving score...", total=None)
                show(lilypond_file)
