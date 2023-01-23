from pathlib import Path

from abjad import (
    Chord,
    Clef,
    Component,
    Duration,
    InstrumentName,
    LilyPondFile,
    NamedPitch,
    Note,
    Score,
    ShortInstrumentName,
    Staff,
    StaffGroup,
    TimeSignature,
    Tuplet,
    attach,
    show,
)
from abjad.get import duration as get_duration
from abjad.persist import as_pdf
from rich.progress import track

from agni.passage.read_passage import (
    NoteInMeasure,
    Passage,
    get_staff_by_name,
    get_tie,
    get_tuplet,
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
    *matrices, full_score=False, passage: Passage | None = None
) -> str:
    if not passage:
        if len(matrices) > 1:
            matrix_display = "Matrices"
        else:
            matrix_display = "Matrix"
        title = f"Combination-Tone {matrix_display}"
        composer = None
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


def show_with_preamble(preamble: str, container: Component, persist: bool):
    lilypond_file = LilyPondFile([preamble, container])
    if persist:
        pdf_file_path = Path("examples") / "matrix.pdf"
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


def get_staff_name(name: str | None) -> str:
    staff_name = name or ""
    if staff_name == "0":
        staff_name = "bass"
    elif staff_name == "3":
        staff_name = "melody"
    return f"\\markup {staff_name}"


def get_staff(
    frequency_number: int, time_signature: TimeSignature | None, note: Note
) -> Staff:
    staff = Staff([note], name=str(frequency_number))
    staff_name = get_staff_name(staff.name)
    first_leaf = staff[0]
    attach(InstrumentName(staff_name), first_leaf)
    attach(ShortInstrumentName(staff_name), first_leaf)
    attach(time_signature, first_leaf)
    return staff


def add_matrix_to_staff_group(
    matrix: Matrix,
    staff_group: StaffGroup,
    tuning: Tuning,
    melody_note: NoteInMeasure | None = None,
    previous_note: NoteInMeasure | None = None,
):
    frequencies = sort_frequencies(matrix)
    for frequency_number, frequency in enumerate(frequencies):
        if melody_note:
            duration = melody_note.note.written_duration
            tuplet = get_tuplet(melody_note.note)
            time_signature = melody_note.time_signature
            tie = get_tie(melody_note.note)
        else:
            tuplet = None
            duration = Duration(1, 4)
            time_signature = None
            tie = None
        note = get_note(frequency, tuning, duration=duration)
        if tie:
            attach(tie, note)
        staff_names = [staff.name for staff in staff_group]
        staff_name = str(frequency_number)
        if staff_name in staff_names:
            staff = get_staff_by_name(staff_group, staff_name)
            if not staff:
                continue
            if melody_note:
                if (
                    previous_note
                    and not previous_note.time_signature == time_signature
                ):
                    attach(time_signature, note)
                if tuplet and previous_note:
                    in_progress_tuplet = get_tuplet(previous_note.note)
                    if in_progress_tuplet:
                        in_progress_tuplet_duration = get_duration(
                            in_progress_tuplet
                        )
                        is_complete_tuplet = (
                            in_progress_tuplet_duration.is_assignable
                        )
                        if not is_complete_tuplet:
                            in_progress_tuplet.append(note)
                            continue
                    multiplier = tuplet.colon_string
                    note = Tuplet(multiplier, [note])
            staff.append(note)
        else:
            set_clefs([note])
            staff = get_staff(frequency_number, time_signature, note)
            staff_group.insert(0, staff)


def get_ensemble_score(
    *matrices: Matrix, tuning: Tuning, passage: Passage | None
) -> Score:
    staff_group = StaffGroup()
    description = "Notating matrices..."
    if passage:
        for index, data in track(
            enumerate(zip(matrices, passage.melody)),
            description=description,
            total=len(matrices),
        ):
            matrix, melody_note = data
            try:
                previous_note = passage.melody[index - 1]
            except Exception:
                previous_note = None
            add_matrix_to_staff_group(
                matrix,
                staff_group,
                tuning=tuning,
                melody_note=melody_note,
                previous_note=previous_note,
            )
    else:
        for matrix in track(matrices, description=description):
            add_matrix_to_staff_group(matrix, staff_group, tuning=tuning)
    return Score([staff_group])


def get_reference_score(
    *matrices: Matrix, tuning: Tuning, as_chord: bool
) -> Score:
    score = Score()
    for matrix in track(matrices, description="Notating matrices..."):
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
    full_score=False,
    passage: Passage | None = None,
):
    preamble = get_lilypond_preamble(
        *matrices, full_score=full_score, passage=passage
    )
    if as_ensemble:
        score = get_ensemble_score(*matrices, tuning=tuning, passage=passage)
    else:
        score = get_reference_score(
            *matrices, tuning=tuning, as_chord=as_chord
        )
    show_with_preamble(preamble, score, persist=persist)
