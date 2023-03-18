from enum import StrEnum, auto
from functools import cached_property
from math import log
from typing import Any

from abjad import Duration, NamedPitch, Note, NumberedPitch, Tie, attach

from .helpers import get_instrument_name, stylize


class PitchType(StrEnum):
    ALL = auto()
    HERTZ = auto()
    MIDI = auto()
    LILYPOND = auto()


class Tuning(StrEnum):
    @staticmethod
    def _generate_next_value_(name, *_):
        return name.lower().replace("_", "-")

    EQUAL_TEMPERED = auto()
    MICROTONAL = auto()


class DisplayFormat(StrEnum):
    CHORD = auto()
    LIST = auto()
    MELODY = auto()
    TABLE = auto()


class DisplayColor(StrEnum):
    BASE_FREQUENCY = "bright_white"
    BASS_MULTIPLE = "dark_orange3"
    MELODY_MULTIPLE = "yellow"
    LABEL = "white"


class MatrixPitch:
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
        self._melody_multiplier = melody_multiplier
        frequency = bass_frequency + melody_frequency
        self.frequency = frequency or None

    def __str__(self) -> str:
        if self.frequency is not None:
            frequency_display = f"{self.frequency:,}"
        else:
            frequency_display = str(self.frequency)
        return f"MatrixPitch({frequency_display})"

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, type(self)):
            return NotImplemented
        return (
            other.bass_multiplier == self.bass_multiplier
            and other._melody_multiplier == self._melody_multiplier
            and other.frequency == self.frequency
        )

    @staticmethod
    def get_sortable_frequency(matrix_pitch: "MatrixPitch") -> float:
        return matrix_pitch.frequency or 0

    @cached_property
    def _is_bass_frequency(self) -> bool:
        if self.bass_multiplier == 1 and self._melody_multiplier == 0:
            return True
        return False

    @cached_property
    def _is_melody_frequency(self) -> bool:
        if self.bass_multiplier == 0 and self._melody_multiplier == 1:
            return True
        return False

    @cached_property
    def is_base_frequency(self) -> bool:
        return self._is_bass_frequency or self._is_melody_frequency

    @cached_property
    def _is_bass_multiple(self) -> bool:
        if self.bass_multiplier > 1 and self._melody_multiplier == 0:
            return True
        return False

    @cached_property
    def _is_melody_multiple(self) -> bool:
        if self._melody_multiplier > 1 and self.bass_multiplier == 0:
            return True
        return False

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
        return stylize(text, DisplayColor.BASE_FREQUENCY, bold=True)

    @staticmethod
    def _stylize_bass_multiple(text: str) -> str:
        return stylize(text, DisplayColor.BASS_MULTIPLE)

    @staticmethod
    def _stylize_melody_multiple(text: str) -> str:
        return stylize(text, DisplayColor.MELODY_MULTIPLE)

    def _get_bass_label(self, abbreviated=False) -> str:
        if abbreviated:
            return f"{self.bass_multiplier}B"
        return f"({self.bass_multiplier} x bass)"

    def _get_melody_label(self, abbreviated=False) -> str:
        if abbreviated:
            return f"{self._melody_multiplier}M"
        return f"({self._melody_multiplier} x melody)"

    def _get_display_label(self, display_format=DisplayFormat.CHORD) -> str:
        if display_format == DisplayFormat.MELODY:
            abbreviated = True
        else:
            abbreviated = False
        bass_multiplier = self._get_bass_label(abbreviated)
        melody_multiplier = self._get_melody_label(abbreviated)
        if self._is_bass_frequency:
            bass_multiplier = self._stylize_base_frequency(bass_multiplier)
        elif self._is_melody_frequency:
            melody_multiplier = self._stylize_base_frequency(melody_multiplier)
        elif self._is_bass_multiple:
            bass_multiplier = self._stylize_bass_multiple(bass_multiplier)
        elif self._is_melody_multiple:
            melody_multiplier = self._stylize_melody_multiple(
                melody_multiplier
            )
        label = f"{bass_multiplier} + {melody_multiplier}"
        if display_format == DisplayFormat.CHORD:
            label = f"{label} = "
        return stylize(label, DisplayColor.LABEL)

    def get_display(
        self,
        pitch_type: PitchType,
        tuning: Tuning,
        display_format: DisplayFormat,
    ) -> str:
        if not self.frequency:
            return ""
        display_pitch = ""
        if pitch_type == PitchType.LILYPOND:
            display_pitch = self._get_lilypond_display_pitch(tuning)
        elif pitch_type == PitchType.MIDI:
            display_pitch = self._get_midi_display_pitch(tuning)
        elif pitch_type == PitchType.HERTZ:
            display_pitch = self._get_hertz_display_pitch(tuning)
        elif pitch_type == PitchType.ALL:
            hertz = self._get_hertz_display_pitch(tuning)
            lilypond = self._get_lilypond_display_pitch(tuning)
            midi = self._get_midi_display_pitch(tuning)
            display_pitch = f"{hertz}\n{lilypond}\n{midi}"
        if self.is_base_frequency:
            display_pitch = self._stylize_base_frequency(display_pitch)
        if self._is_melody_multiple:
            display_pitch = self._stylize_melody_multiple(display_pitch)
        elif self._is_bass_multiple:
            display_pitch = self._stylize_bass_multiple(display_pitch)
        if display_format == DisplayFormat.CHORD:
            display_label = self._get_display_label()
            display_pitch = f"{display_label}{display_pitch}"
        return display_pitch

    def get_instrument_name(self) -> str:
        return get_instrument_name(
            self.bass_multiplier, self._melody_multiplier
        )

    def get_note(self, duration: Duration, tie: bool) -> Note | None:
        if not self.frequency:
            return None
        named_pitch = NamedPitch.from_hertz(self.frequency)
        note = Note.from_pitch_and_duration(named_pitch, duration)
        if tie:
            attach(Tie(), note)
        return note
