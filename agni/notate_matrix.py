from pathlib import Path

from abjad import (
    Chord,
    Component,
    Container,
    Duration,
    LilyPondFile,
    NamedPitch,
    Note,
    Score,
    show,
)
from abjad.persist import as_pdf

from .combination_tone_matrix import Matrix, remove_none_values


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


def notate_matrix(*matrices: Matrix, as_chord=False, persist=False):
    preamble = r"""
                    \header { tagline = ##f }
                    \layout {
                        \context {
                            \Score
                            \override SystemStartBar.stencil = ##f
                            \override TimeSignature.stencil = ##f
                            \override BarLine.stencil = ##f
                            \override Stem.stencil = ##f
                        }
                    }
                """
    score = Score()
    for matrix in matrices:
        frequencies = sort_frequencies(matrix)
        notes = [get_note(frequency) for frequency in frequencies]
        if as_chord:
            chord_notes = get_chord_notes(notes)
            chord = Chord(chord_notes)
            score.append(chord)
        else:
            container = Container(notes)
            score.append(container)
    show_with_preamble(preamble, score, persist=persist)
