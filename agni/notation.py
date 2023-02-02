from pathlib import Path

from abjad import (
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
from abjad.select import logical_ties as get_logical_ties
from rich.progress import track

from .helpers import get_staff_by_name, remove_none_values
from .matrix import Matrix
from .matrix_frequency import MatrixFrequency, Tuning
from .passage import MeteredLeaf, Passage


class Notation:
    def __init__(self, *matrices: Matrix):
        self.matrices = matrices

    @property
    def _number_of_matrices(self) -> int:
        return len(self.matrices)

    def _get_lilypond_preamble(
        self, full_score=False, passage: Passage | None = None
    ) -> str:
        if passage:
            title = passage._title
            composer = passage._composer
        else:
            if self._number_of_matrices > 1:
                matrix_display = "Matrices"
            else:
                matrix_display = "Matrix"
            title = f"Combination-Tone {matrix_display}"
            composer = ""
        if full_score:
            stencils = ""
        else:
            stencils = """
                \\override TimeSignature.stencil = ##f
                \\override BarLine.stencil = ##f
                \\override Stem.stencil = ##f
            """
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
        self, container: Component, save: bool, full_score: bool
    ):
        lilypond_file = LilyPondFile(
            [self._get_lilypond_preamble(full_score), container]
        )
        if save:
            pdf_file_path = Path("examples") / "matrix.pdf"
            as_pdf(lilypond_file, pdf_file_path=pdf_file_path, remove_ly=True)
        else:
            show(lilypond_file)

    def _pair_matrices_to_melody_notes(
        self, melody_passage: list[MeteredLeaf]
    ) -> list[tuple[Matrix, MeteredLeaf]]:
        pairs = []
        matrix_iterator = iter(self.matrices)
        current_matrix = None
        for metered_leaf in melody_passage:
            note = metered_leaf.leaf
            if not current_matrix or get_logical_ties(note):
                current_matrix = next(matrix_iterator, None)
                if not current_matrix:
                    break
            pair = (current_matrix, metered_leaf)
            pairs.append(pair)
        return pairs

    @staticmethod
    def _get_previous_note(
        part: list[MeteredLeaf], index: int
    ) -> MeteredLeaf | None:
        try:
            return part[index - 1]
        except Exception:
            return None

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
        return next((tie for tie in get_indicators(note, prototype=Tie)), None)

    @classmethod
    def _get_melody_note_tie(
        cls, metered_leaf: MeteredLeaf | None
    ) -> Tie | None:
        if not metered_leaf:
            return None
        return cls._get_tie(metered_leaf.leaf)

    @staticmethod
    def _get_note(
        frequency: float, tuning: Tuning, duration=Duration(1, 4)
    ) -> Note:
        pitch = NamedPitch.from_hertz(frequency)
        if tuning == Tuning.EQUAL_TEMPERED:
            pitch_number = pitch.number
            if isinstance(pitch_number, float):
                pitch_number = int(pitch_number)
                pitch_name = NumberedPitch(pitch_number).name
                pitch = NamedPitch(pitch_name)
        return Note(pitch, duration)

    @classmethod
    def _get_matrix_note_from_melody_note(
        cls,
        matrix_frequency: MatrixFrequency,
        melody_note: MeteredLeaf | None,
        tuning: Tuning,
    ) -> Note:
        duration = cls._get_melody_note_duration(melody_note)
        tie = cls._get_melody_note_tie(melody_note)
        note = cls._get_note(
            matrix_frequency.frequency or 0, tuning, duration=duration
        )
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

    @classmethod
    def _add_matrix_to_staff_group(
        cls,
        matrix: Matrix,
        staff_group: StaffGroup,
        tuning: Tuning,
        melody_note: MeteredLeaf | None = None,
        previous_note: MeteredLeaf | None = None,
    ):
        for index, frequency in enumerate(matrix.sorted_frequencies):
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
            staff = get_staff_by_name(staff_group, staff_name)
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
        save: bool,
        full_score=False,
        passage: Passage | None = None,
    ):
        staff_group = StaffGroup()
        description = "Generating matrices..."
        if passage:
            matrix_melody_note_pairs = self._pair_matrices_to_melody_notes(
                passage._melody_leaves
            )
            for index, (matrix, melody_note) in track(
                enumerate(matrix_melody_note_pairs),
                description=description,
                total=self._number_of_matrices,
            ):
                previous_note = self._get_previous_note(
                    passage._melody_leaves, index
                )
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
        self._show_with_preamble(score, save=save, full_score=full_score)

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
        self, tuning: Tuning, as_chord: bool, save: bool, full_score=False
    ):
        score = Score()
        for matrix in track(
            self.matrices, description="Generating matrices..."
        ):
            notes = [
                self._get_note(frequency, tuning)
                for frequency in matrix.sorted_frequencies_in_hertz
            ]
            self._set_clefs(notes)
            self._add_notes_to_score(notes, score, as_chord=as_chord)
        self._show_with_preamble(score, save=save, full_score=full_score)

    def make_score(
        self,
        as_ensemble: bool,
        tuning: Tuning,
        save: bool,
        as_chord: bool,
        full_score=False,
        passage: Passage | None = None,
    ):
        if as_ensemble:
            self._make_ensemble_score(
                tuning, save=save, full_score=full_score, passage=passage
            )
        else:
            self._make_reference_score(
                tuning,
                save=save,
                as_chord=as_chord,
                full_score=full_score,
            )


def notate_matrix(
    matrix: Matrix,
    as_ensemble: bool,
    tuning: Tuning,
    save: bool,
    as_chord: bool,
):
    notation = Notation(matrix)
    notation.make_score(as_ensemble, tuning, save, as_chord)


def notate_passage(
    passage: Passage,
    as_ensemble: bool,
    tuning: Tuning,
    save: bool,
    as_chord: bool,
    full_score: bool,
):
    notation = Notation(*passage.matrices)
    notation.make_score(
        as_ensemble,
        tuning,
        save,
        as_chord,
        full_score=full_score,
        passage=passage,
    )
