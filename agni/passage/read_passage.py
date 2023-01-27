from pathlib import Path
from typing import cast

from abjad import Block, Leaf, LilyPondFile, Staff, parse
from abjad.get import indicators as get_indicators
from abjad.indicators import TimeSignature
from abjad.score import Skip
from abjad.select import components as get_components
from abjad.select import leaves as get_leaves

from agni.matrix import Notation, NoteInMeasure, Passage


def get_time_signature(note: Leaf) -> TimeSignature | None:
    return next(
        (
            time_signature
            for time_signature in get_indicators(note, prototype=TimeSignature)
        ),
        None,
    )


def get_score_block(lilypond_input: str) -> Block:
    lilypond_file = cast(LilyPondFile, parse(lilypond_input))
    items = lilypond_file.items
    return next(block for block in items if block.name == "score")


def get_staves_and_structure(
    lilypond_input: str,
) -> tuple[list[Staff], list[Skip]]:
    score = get_score_block(lilypond_input)
    staves = cast(list[Staff], get_components(score.items, prototype=Staff))
    structure = cast(list[Skip], get_components(staves, prototype=Skip))
    return staves, structure


def get_notes_in_measure(notes: list[Leaf]) -> list[NoteInMeasure]:
    notes_in_measure = []
    current_time_signature = TimeSignature((4, 4))
    for note in notes:
        time_signature = get_time_signature(note)
        if time_signature:
            current_time_signature = time_signature
        notes_in_measure.append(NoteInMeasure(note, current_time_signature))
    return notes_in_measure


def get_staff_notes(staves: list[Staff], part: str) -> list[NoteInMeasure]:
    staff = Notation.get_staff_by_name(staves, part)
    if not staff:
        return []
    components = staff.components
    leaves = get_leaves(components)
    return get_notes_in_measure(leaves)


def get_header_item(lilypond_input: str, item: str) -> str:
    lines = lilypond_input.splitlines()
    matching_line = next((line for line in lines if item in line), None)
    if not matching_line:
        return ""
    return matching_line.split('"')[1]


def get_passage_from_input_file(input_file: Path) -> Passage:
    lilypond_input = input_file.read_text()
    title = get_header_item(lilypond_input, "title")
    composer = get_header_item(lilypond_input, "composer")
    staves, structure = get_staves_and_structure(lilypond_input)
    melody = get_staff_notes(staves, "melody")
    bass = get_staff_notes(staves, "bass")
    return Passage(title, composer, bass, melody, structure)
