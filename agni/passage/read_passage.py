from pathlib import Path
from typing import cast

from abjad import Block, Duration, LilyPondFile, Note, Staff, StaffGroup, parse
from abjad.select import components as get_components
from abjad.select import leaves as get_leaves

Passage = tuple[list[Note], list[Note]]


def get_score_block(lilypond_input: str) -> Block:
    lilypond_file = cast(LilyPondFile, parse(lilypond_input))
    items = lilypond_file.items
    return next(block for block in items if block.name == "score")


def get_staves_from_lilypond_input(lilypond_input: str) -> list[Staff]:
    score = get_score_block(lilypond_input)
    components = get_components(score.items)
    return list(
        component for component in components if isinstance(component, Staff)
    )


def get_staff_by_name(
    staves: StaffGroup | list[Staff], name: str
) -> Staff | None:
    return next((staff for staff in staves if staff.name == name), None)


def get_staff_notes(staves: list[Staff], part: str) -> list[Note]:
    staff = get_staff_by_name(staves, part)
    if not staff:
        return []
    components = staff.components
    leaves = get_leaves(components)
    notes = [leaf for leaf in leaves if isinstance(leaf, Note)]
    return notes


def get_passage_from_input_file(
    input_file: Path,
) -> Passage:
    lilypond_input = input_file.read_text()
    staves = get_staves_from_lilypond_input(lilypond_input)
    melody = get_staff_notes(staves, "melody")
    bass = get_staff_notes(staves, "bass")
    return bass, melody


def get_part_durations(part: list[Note]) -> list[Duration]:
    return [note.written_duration for note in part]


def get_passage_durations(
    passage: Passage,
) -> tuple[list[Duration], list[Duration]]:
    bass_durations = get_part_durations(passage[0])
    melody_durations = get_part_durations(passage[1])
    return bass_durations, melody_durations
