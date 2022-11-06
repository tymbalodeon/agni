from pathlib import Path

from abjad import (
    Chord,
    Clef,
    Component,
    Duration,
    LilyPondFile,
    NamedPitch,
    Note,
    Score,
    Staff,
    StaffGroup,
    attach,
    show,
)
from abjad.get import effective as get_effective
from abjad.indicators import Tie, TimeSignature
from abjad.persist import as_pdf

from agni.passage.read_passage import (
    Passage,
    PassageDurations,
    PassageTies,
    PassageTimeSignatures,
    get_passage_durations,
    get_passage_ties,
    get_passage_time_signatures,
    get_staff_by_name,
)

from .matrix import Matrix, Tuning, quantize_pitch
from .passage.passage import remove_none_values


def sort_frequencies(matrix: Matrix, limit: int | None = None) -> list[float]:
    frequencies = [frequency for row in matrix for frequency in row]
    frequencies.sort()
    frequencies = frequencies[1:]
    if not limit:
        return frequencies
    return frequencies[:limit]


def get_note(
    frequency: float, tuning: Tuning, duration=Duration(1, 4)
) -> Note:
    pitch = NamedPitch.from_hertz(frequency)
    if tuning == Tuning.EQUAL_TEMPERED:
        pitch = quantize_pitch(pitch)
    return Note(pitch, duration)


def get_note_name(note: Note) -> str | None:
    if not note.written_pitch:
        return None
    return note.written_pitch.name


def get_chord_notes(notes: list[Note]) -> str:
    note_names = [get_note_name(note) for note in notes]
    pitched_note_names = remove_none_values(note_names)
    chord_notes = " ".join(pitched_note_names)
    return f"<{chord_notes}>"


def get_lilypond_preamble(
    *matrices,
    disable_stems=True,
    disable_time_signatures=True,
    disable_bar_lines=True,
) -> str:
    if len(matrices) > 1:
        matrix_display = "Matrices"
    else:
        matrix_display = "Matrix"
    title = f"Combination-Tone {matrix_display}"
    if disable_stems:
        stem_stencil = "\\override Stem.stencil = ##f"
    else:
        stem_stencil = ""
    if disable_time_signatures:
        time_signature_stencil = "\\override TimeSignature.stencil = ##f"
    else:
        time_signature_stencil = ""
    if disable_bar_lines:
        bar_lines_stencil = "\\override BarLine.stencil = ##f"
    else:
        bar_lines_stencil = ""
    return f"""
                #(set-default-paper-size "letter")
                \\header {{
                    tagline = ##f
                    title = "{title}"
                }}
                \\layout {{
                    \\context {{
                        \\Score
                        \\numericTimeSignature
                        {time_signature_stencil}
                        {bar_lines_stencil}
                        {stem_stencil}
                    }}
                }}
            """


def show_with_preamble(preamble: str, container: Component, persist: bool):
    lilypond_file = LilyPondFile([preamble, container])
    if persist:
        pdf_file_path = Path.home() / "Desktop" / "matrix.pdf"
        as_pdf(lilypond_file, pdf_file_path=pdf_file_path, remove_ly=True)
    else:
        show(lilypond_file)


def set_bass_and_melody_noteheads(notes: list[Note]) -> list[Note]:
    for note in notes[:2]:
        note.written_duration = Duration(1, 2)
    return notes


def add_notes_to_score(notes: list[Note], score: Score, as_chord: bool):
    notes = set_bass_and_melody_noteheads(notes)
    if as_chord:
        chord_notes = get_chord_notes(notes)
        components = [Chord(chord_notes)]
    else:
        components = notes
    staff = Staff(components)
    score.append(staff)


def get_clef_by_octave(octave: int) -> Clef:
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


def set_clef(note: Note) -> Clef | None:
    written_pitch = note.written_pitch
    if not written_pitch:
        return None
    octave = written_pitch.octave.number
    clef = get_clef_by_octave(octave)
    attach(clef, note)
    return clef


def set_clefs(notes: list[Note]):
    first_note = notes[0]
    current_clef = set_clef(first_note)
    for note in notes[1:]:
        written_pitch = note.written_pitch
        if not written_pitch:
            continue
        octave = written_pitch.octave.number
        new_clef = get_clef_by_octave(octave)
        if new_clef != current_clef:
            set_clef(note)


def add_matrix_to_staff_group(
    matrix: Matrix,
    staff_group: StaffGroup,
    tuning: Tuning,
    duration=Duration(1, 4),
    tie: Tie | None = None,
    time_signature: TimeSignature | None = None,
    matrix_number: int = 0,
):
    frequencies = sort_frequencies(matrix)
    frequencies.reverse()
    for index, frequency in enumerate(frequencies):
        note = get_note(frequency, tuning, duration=duration)
        if tie:
            attach(tie, note)
        staff_names = [staff.name for staff in staff_group]
        staff_name = str(index)
        if staff_name in staff_names:
            staff = get_staff_by_name(staff_group, staff_name)
            if staff:
                staff.append(note)
                current_note = staff[matrix_number]
                current_time_signature = get_effective(
                    current_note, TimeSignature
                )
                if not current_time_signature == time_signature:
                    attach(time_signature, staff[matrix_number])
        else:
            set_clefs([note])
            staff = Staff([note], name=str(index))
            attach(time_signature, staff[0])
            staff_group.append(staff)


def get_ensemble_score(
    *matrices: Matrix,
    tuning: Tuning,
    durations: PassageDurations | None,
    ties: PassageTies | None,
    time_signatures: PassageTimeSignatures | None,
) -> Score:
    staff_group = StaffGroup()
    if durations and ties and time_signatures:
        score_data = zip(matrices, durations[1], ties[1], time_signatures[1])
        for matrix_number, (
            matrix,
            duration,
            tie,
            time_signature,
        ) in enumerate(score_data):
            add_matrix_to_staff_group(
                matrix,
                staff_group,
                tuning=tuning,
                duration=duration,
                tie=tie,
                time_signature=time_signature,
                matrix_number=matrix_number,
            )
    else:
        for matrix in matrices:
            add_matrix_to_staff_group(matrix, staff_group, tuning=tuning)
    return Score([staff_group])


def get_reference_score(
    *matrices: Matrix, tuning: Tuning, as_chord: bool
) -> Score:
    score = Score()
    for matrix in matrices:
        frequencies = sort_frequencies(matrix)
        notes = [get_note(frequency, tuning) for frequency in frequencies]
        set_clefs(notes)
        add_notes_to_score(notes, score, as_chord=as_chord)
    return score


def notate_matrix(
    *matrices: Matrix,
    tuning: Tuning,
    as_chord=False,
    persist=False,
    as_ensemble=False,
    as_set=True,
    adjacent_duplicates=False,
    passage: Passage | None = None,
):
    full_score = not as_set and adjacent_duplicates
    if not full_score:
        passage = None
    disable_stencils = not full_score
    preamble = get_lilypond_preamble(
        *matrices,
        disable_stems=disable_stencils,
        disable_time_signatures=disable_stencils,
        disable_bar_lines=disable_stencils,
    )
    if as_ensemble:
        durations = get_passage_durations(passage)
        ties = get_passage_ties(passage)
        time_signatures = get_passage_time_signatures(passage)
        score = get_ensemble_score(
            *matrices,
            tuning=tuning,
            durations=durations,
            ties=ties,
            time_signatures=time_signatures,
        )
    else:
        score = get_reference_score(
            *matrices, tuning=tuning, as_chord=as_chord
        )
    show_with_preamble(preamble, score, persist=persist)
