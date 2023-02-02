from abjad import Staff, StaffGroup


def remove_none_values(collection: list) -> list:
    return [item for item in collection if item is not None]


def get_staff_by_name(
    staves: StaffGroup | list[Staff], name: str
) -> Staff | None:
    return next((staff for staff in staves if staff.name == name), None)


def stylize(text: str, color: str, bold: bool = False) -> str:
    text = f"[{color}]{text}[/{color}]"
    if bold:
        text = f"[bold]{text}[/bold]"
    return text
