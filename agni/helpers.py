from enum import Enum

from abjad import Staff, StaffGroup


class InputPart(Enum):
    BASS = "bass"
    MELODY = "melody"


def _get_part_label(multiple: int, input_part: InputPart) -> str:
    if multiple == 0:
        return ""
    if multiple == 1:
        multiplier = ""
    else:
        multiplier = str(multiple)
    if input_part == InputPart.BASS:
        part_abbreviation = "B"
    else:
        part_abbreviation = "M"
    return f"{multiplier}{part_abbreviation}"


def get_instrument_name(bass_multiple: int, melody_multiple: int) -> str:
    bass_label = _get_part_label(bass_multiple, InputPart.BASS)
    melody_label = _get_part_label(melody_multiple, InputPart.MELODY)
    if not bass_label:
        return melody_label
    if not melody_label:
        return bass_label
    return f"{bass_label} + {melody_label}"


def get_staff_by_name(
    staves: StaffGroup | list[Staff], name: str
) -> Staff | None:
    return next((staff for staff in staves if staff.name == name), None)


def remove_none_values(collection: list) -> list:
    return [item for item in collection if item is not None]


def stylize(text: str, color: str, bold: bool = False) -> str:
    text = f"[{color}]{text}[/{color}]"
    if bold:
        text = f"[bold]{text}[/bold]"
    return text
