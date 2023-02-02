from enum import Enum
from functools import cached_property
from math import log

from abjad import NamedPitch, NumberedPitch

from agni.helpers import stylize


class DisplayType(Enum):
    HERTZ = "hertz"
    MIDI = "midi"
    LILYPOND = "lilypond"
    ALL = "all"


class Tuning(Enum):
    MICROTONAL = "microtonal"
    EQUAL_TEMPERED = "equal-tempered"


class MatrixFrequency:
    def __init__(
        self,
        bass: float,
        melody: float,
        bass_multiplier: int,
        melody_multiplier: int,
    ):
        bass_frequency = bass * bass_multiplier
        melody_frequency = melody * melody_multiplier
        self.bass_multiplier = bass_multiplier
        self.melody_multiplier = melody_multiplier
        frequency = bass_frequency + melody_frequency
        self.frequency = frequency or None

    @staticmethod
    def get_sortable_frequency(matrix_frequency: "MatrixFrequency") -> float:
        return matrix_frequency.frequency or 0

    @cached_property
    def _is_bass_frequency(self) -> bool:
        if self.bass_multiplier == 1 and self.melody_multiplier == 0:
            return True
        return False

    @cached_property
    def _is_melody_frequency(self) -> bool:
        if self.bass_multiplier == 0 and self.melody_multiplier == 1:
            return True
        return False

    @cached_property
    def is_base_frequency(self) -> bool:
        return self._is_bass_frequency or self._is_melody_frequency

    @cached_property
    def _is_bass_multiple(self) -> bool:
        if self.bass_multiplier > 1 and self.melody_multiplier == 0:
            return True
        return False

    @cached_property
    def _is_melody_multiple(self) -> bool:
        if self.melody_multiplier > 1 and self.bass_multiplier == 0:
            return True
        return False

    @cached_property
    def is_base_multiple(self) -> bool:
        return self._is_bass_multiple or self._is_melody_multiple

    def _get_lilypond_display_pitch(self, tuning: Tuning) -> str:
        if not self.frequency:
            return ""
        named_pitch = NamedPitch.from_hertz(self.frequency)
        if tuning == Tuning.EQUAL_TEMPERED:
            pitch_number = named_pitch.number
            if isinstance(pitch_number, float):
                pitch_number = int(pitch_number)
                pitch_name = NumberedPitch(pitch_number).name
                named_pitch = NamedPitch(pitch_name)
        return named_pitch.name

    def _get_midi_display_pitch(self, tuning: Tuning) -> str:
        if not self.frequency:
            return ""
        frequency = self.frequency / 440
        logarithm = log(frequency, 2)
        midi_number = 12 * logarithm + 69
        if tuning == Tuning.MICROTONAL:
            midi_number = round(midi_number * 2) / 2
        else:
            midi_number = round(midi_number)
        return str(midi_number)

    def _get_hertz_display_pitch(self, tuning: Tuning) -> str:
        if not self.frequency:
            return ""
        if tuning == Tuning.MICROTONAL:
            decimals = 2
        else:
            decimals = None
        return f"{round(self.frequency, decimals):,}"

    @staticmethod
    def _stylize_base_frequency(text: str) -> str:
        return stylize(text, "orange1", bold=True)

    @staticmethod
    def _stylize_bass_multiple(text: str) -> str:
        return stylize(text, "dark_orange3")

    @staticmethod
    def _stylize_multiple(text: str) -> str:
        return stylize(text, "yellow")

    @staticmethod
    def _stylize_combination(text: str) -> str:
        return stylize(text, "white")

    def _get_display_label(self) -> str:
        bass_multiplier = f"({self.bass_multiplier} x bass)"
        melody_multiplier = f"({self.melody_multiplier} x melody)"
        if self._is_bass_frequency:
            bass_multiplier = self._stylize_base_frequency(bass_multiplier)
            melody_multiplier = self._stylize_combination(melody_multiplier)
        elif self._is_melody_frequency:
            melody_multiplier = self._stylize_base_frequency(melody_multiplier)
            bass_multiplier = self._stylize_combination(bass_multiplier)
        elif self._is_bass_multiple:
            bass_multiplier = self._stylize_bass_multiple(bass_multiplier)
            melody_multiplier = self._stylize_combination(melody_multiplier)
        elif self._is_melody_multiple:
            melody_multiplier = self._stylize_multiple(melody_multiplier)
            bass_multiplier = self._stylize_combination(bass_multiplier)
        else:
            bass_multiplier = self._stylize_combination(bass_multiplier)
            melody_multiplier = self._stylize_combination(melody_multiplier)
        return f"{bass_multiplier} + {melody_multiplier} = "

    def get_display(
        self, display_type: DisplayType, tuning: Tuning, table: bool
    ) -> str:
        if not self.frequency:
            return ""
        display_pitch = ""
        if display_type == DisplayType.LILYPOND:
            display_pitch = self._get_lilypond_display_pitch(tuning)
        elif display_type == DisplayType.MIDI:
            display_pitch = self._get_midi_display_pitch(tuning)
        elif display_type == DisplayType.HERTZ:
            display_pitch = self._get_hertz_display_pitch(tuning)
        elif display_type == DisplayType.ALL:
            hertz = self._get_hertz_display_pitch(tuning)
            lilypond = self._get_lilypond_display_pitch(tuning)
            midi = self._get_midi_display_pitch(tuning)
            display_pitch = f"{hertz}\n{lilypond}\n{midi}"
        if self.is_base_frequency:
            display_pitch = self._stylize_base_frequency(display_pitch)
        if table and self.is_base_multiple or self._is_melody_multiple:
            display_pitch = self._stylize_multiple(display_pitch)
        elif self._is_bass_multiple:
            display_pitch = self._stylize_bass_multiple(display_pitch)
        if not table:
            display_label = self._get_display_label()
            display_pitch = f"{display_label}{display_pitch}"
        return display_pitch
