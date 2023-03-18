from pytest import mark
from abjad import Staff, StaffGroup

from agni.helpers import (
    InputPart,
    _get_part_label,
    get_instrument_name,
    get_staff_by_name,
    remove_none_values,
    stylize,
)

expected_part_labels = [
    (0, InputPart.BASS, ""),
    (1, InputPart.BASS, "B"),
    (1, InputPart.MELODY, "M"),
    (2, InputPart.BASS, "2B"),
    (3, InputPart.MELODY, "3M"),
]


@mark.parametrize(
    "multiple, input_part, expected_part_label", expected_part_labels
)
def test_get_part_label(
    multiple: int, input_part: InputPart, expected_part_label: str
):
    assert _get_part_label(multiple, input_part) == expected_part_label


expected_instrument_names = [
    (1, 0, "B"),
    (0, 1, "M"),
    (1, 2, "B + 2M"),
    (2, 3, "2B + 3M"),
]


@mark.parametrize(
    "bass_multiple, melody_multiple, expected_instrument_name",
    expected_instrument_names,
)
def test_get_instrument_name(
    bass_multiple: int, melody_multiple: int, expected_instrument_name: str
):
    assert (
        get_instrument_name(bass_multiple, melody_multiple)
        == expected_instrument_name
    )


def test_get_staff_by_name_found():
    bass_staff = Staff(name="bass")
    melody_staff = Staff(name="melody")
    staff_group = StaffGroup([bass_staff, melody_staff])
    found_staff = get_staff_by_name(staff_group, "bass")
    assert found_staff == bass_staff


def test_get_staff_by_name_not_found():
    bass_staff = Staff(name="bass")
    melody_staff = Staff(name="melody")
    staff_group = StaffGroup([bass_staff, melody_staff])
    found_staff = get_staff_by_name(staff_group, "bad")
    assert found_staff is None


def test_remove_none_values():
    collection = [1, 2, None, 3, 4, None]
    assert remove_none_values(collection) == [1, 2, 3, 4]


expected_styles = [
    ("text", "blue", False, "[blue]text[/blue]"),
    ("text", "yellow", True, "[bold][yellow]text[/yellow][/bold]"),
]


@mark.parametrize("text, color, bold, expected_text", expected_styles)
def test_stylize(text: str, color: str, bold: bool, expected_text: str):
    styled_text = stylize(text, color, bold=bold)
    assert styled_text == expected_text
