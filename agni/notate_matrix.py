from pathlib import Path

from abjad import (
    Chord,
    Component,
    Duration,
    LilyPondFile,
    NamedPitch,
    Note,
    Score,
    Staff,
    show,
)
from abjad.persist import as_pdf

from .matrix import Matrix
from .passage import remove_none_values


def sort_frequencies(matrix: Matrix, limit: int | None = None) -> list[float]:
    frequencies = [frequency for row in matrix for frequency in row]
    frequencies.sort()
    frequencies = frequencies[1:]
    if not limit:
        return frequencies
    return frequencies[:limit]


def get_note(frequency: float) -> Note:
    pitch = NamedPitch.from_hertz(frequency)
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
                \\header {{
                    tagline = ##f
                    title = "{title}"
                }}
                \\layout {{
                    \\context {{
                        \\Score
                        \\override SystemStartBar.stencil = ##f
                        \\override TimeSignature.stencil = ##f
                        \\override BarLine.stencil = ##f
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


def notate_matrix(*matrices: Matrix, as_chord=False, persist=False):
    preamble = get_lilypond_preamble(*matrices)
    score = Score()
    for matrix in matrices:
        frequencies = sort_frequencies(matrix)
        notes = [get_note(frequency) for frequency in frequencies]
        add_notes_to_score(notes, score, as_chord=as_chord)
    show_with_preamble(preamble, score, persist=persist)
