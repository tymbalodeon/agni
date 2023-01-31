from enum import Enum
from functools import cached_property
from math import log

from abjad import NamedPitch, NumberedPitch


class OutputType(Enum):
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
    def _is_base_frequency(self) -> bool:
        return self._is_bass_frequency or self._is_melody_frequency

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

    def get_display(self, output_type: OutputType, tuning: Tuning) -> str:
        if not self.frequency:
            return ""
        display_pitch = ""
        if output_type == OutputType.LILYPOND:
            display_pitch = self._get_lilypond_display_pitch(tuning)
        elif output_type == OutputType.MIDI:
            display_pitch = self._get_midi_display_pitch(tuning)
        elif output_type == OutputType.HERTZ:
            display_pitch = self._get_hertz_display_pitch(tuning)
        elif output_type == OutputType.ALL:
            hertz = self._get_hertz_display_pitch(tuning)
            lilypond = self._get_lilypond_display_pitch(tuning)
            midi = self._get_midi_display_pitch(tuning)
            display_pitch = f"{hertz}\n{lilypond}\n{midi}"
        if self._is_base_frequency:
            display_pitch = f"[bold yellow]{display_pitch}[/bold yellow]"
        return display_pitch
