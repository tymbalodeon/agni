from dataclasses import dataclass
from pathlib import Path
from typing import cast

from abjad import (
    Block,
    Component,
    Duration,
    LilyPondFile,
    Note,
    Staff,
    StaffGroup,
    Tie,
    Tuplet,
    parse,
)
from abjad.get import duration as get_duration
from abjad.get import effective as get_effective
from abjad.get import indicators as get_indicators
from abjad.get import lineage as get_lineage
from abjad.indicators import TimeSignature
from abjad.score import Skip
from abjad.select import components as get_components
from abjad.select import notes as get_notes

PassageDurations = tuple[list[Duration], list[Duration]]
PassageTies = tuple[list[Tie | None], list[Tie | None]]
PassageTimeSignatures = tuple[
    list[TimeSignature | None], list[TimeSignature | None]
]


@dataclass
class Passage:
    title: str | None
    composer: str | None
    bass: list[Note]
    melody: list[Note]
    structure: list[Skip]


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


def get_staff_by_name(
    staves: StaffGroup | list[Staff], name: str
) -> Staff | None:
    return next((staff for staff in staves if staff.name == name), None)


def get_staff_notes(staves: list[Staff], part: str) -> list[Note]:
    staff = get_staff_by_name(staves, part)
    if not staff:
        return []
    components = staff.components
    return get_notes(components)


def get_header_item(lilypond_input: str, item: str) -> str | None:
    for line in lilypond_input.splitlines():
        if item in line:
            words = line.split('"')
            return words[1]
    return None


def get_passage_from_input_file(input_file: Path) -> Passage:
    lilypond_input = input_file.read_text()
    title = get_header_item(lilypond_input, "title")
    composer = get_header_item(lilypond_input, "composer")
    staves, structure = get_staves_and_structure(lilypond_input)
    melody = get_staff_notes(staves, "melody")
    bass = get_staff_notes(staves, "bass")
    return Passage(title, composer, bass, melody, structure)


def get_part_durations(part: list[Note]) -> list[Duration]:
    return [get_duration(note) for note in part]


def get_passage_durations(passage: Passage | None) -> PassageDurations | None:
    if not passage:
        return None
    bass_durations = get_part_durations(passage.bass)
    melody_durations = get_part_durations(passage.melody)
    return bass_durations, melody_durations


def get_tie(note: Note | None) -> Tie | None:
    if not note:
        return None
    return next((tie for tie in get_indicators(note, prototype=Tie)), None)


def get_tuplet(component: Component | None) -> Tuplet | None:
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


def get_part_ties(part: list[Note]) -> list[Tie | None]:
    return [get_tie(note) for note in part]


def get_passage_ties(passage: Passage | None) -> PassageTies | None:
    if not passage:
        return None
    bass_ties = get_part_ties(passage.bass)
    melody_ties = get_part_ties(passage.melody)
    return bass_ties, melody_ties


def get_part_time_signatures(part: list[Note]) -> list[TimeSignature | None]:
    return [get_effective(note, TimeSignature) for note in part]


def get_passage_time_signatures(
    passage: Passage | None,
) -> PassageTimeSignatures | None:
    if not passage:
        return None
    bass_time_signatures = get_part_time_signatures(passage.bass)
    melody_time_signatures = get_part_time_signatures(passage.melody)
    return bass_time_signatures, melody_time_signatures
