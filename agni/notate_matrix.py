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
from abjad.persist import as_pdf

from .matrix import Matrix, Tuning, quantize_pitch
from .passage.passage import remove_none_values


def sort_frequencies(matrix: Matrix, limit: int | None = None) -> list[float]:
    frequencies = [frequency for row in matrix for frequency in row]
    frequencies.sort()
    frequencies = frequencies[1:]
    if not limit:
        return frequencies
    return frequencies[:limit]


def get_note(frequency: float, tuning: Tuning) -> Note:
    pitch = NamedPitch.from_hertz(frequency)
    if tuning == Tuning.EQUAL_TEMPERED:
        pitch = quantize_pitch(pitch)
    duration = Duration(1, 4)
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


def show_with_preamble(preamble: str, container: Component, persist: bool):
    lilypond_file = LilyPondFile([preamble, container])
    if persist:
        pdf_file_path = Path.home() / "Desktop" / "matrix.pdf"
        as_pdf(lilypond_file, pdf_file_path=pdf_file_path, remove_ly=True)
    else:
        show(lilypond_file)


def get_lilypond_preamble(*matrices) -> str:
    if len(matrices) > 1:
        matrix_display = "Matrices"
    else:
        matrix_display = "Matrix"
    title = f"Combination-Tone {matrix_display}"
    return f"""
                #(set-default-paper-size "letter")
                \\header {{
                    tagline = ##f
                    title = "{title}"
                }}
                \\layout {{
                    \\context {{
                        \\Score
                        \\override TimeSignature.stencil = ##f
                        \\override BarLine.stencil = ##f
                        \\override SpanBar.stencil = ##f
                        \\override Stem.stencil = ##f
                    }}
                }}
            """


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


def notate_matrix(
    *matrices: Matrix, tuning: Tuning, as_chord=False, persist=False, as_ensemble=False
):
    preamble = get_lilypond_preamble(*matrices)
    if as_ensemble:
        staff_group = StaffGroup()
        for matrix in matrices:
            frequencies = sort_frequencies(matrix)
            frequencies.reverse()
            for index, frequency in enumerate(frequencies):
                note = get_note(frequency, tuning)
                set_clefs([note])
                staff_names = [staff.name for staff in staff_group]
                staff_name = str(index)
                if staff_name in staff_names:
                    staff = next(
                        staff for staff in staff_group if staff.name == staff_name
                    )
                    staff.append(note)
                else:
                    staff = Staff([note], name=str(index))
                    staff_group.append(staff)
        score = Score([staff_group])
    else:
        score = Score()
        for matrix in matrices:
            frequencies = sort_frequencies(matrix)
            notes = [get_note(frequency, tuning) for frequency in frequencies]
            set_clefs(notes)
            add_notes_to_score(notes, score, as_chord=as_chord)
    show_with_preamble(preamble, score, persist=persist)
