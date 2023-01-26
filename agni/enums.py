from enum import Enum


class InputType(Enum):
    HERTZ = "hertz"
    MIDI = "midi"


class OutputType(Enum):
    HERTZ = "hertz"
    MIDI = "midi"
    LILYPOND = "lilypond"
    ALL = "all"


class Tuning(Enum):
    MICROTONAL = "microtonal"
    EQUAL_TEMPERED = "equal-tempered"
