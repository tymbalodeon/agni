from functools import cached_property, lru_cache
from time import sleep
from typing import Any

from abjad import NamedPitch
from rich import print
from rich.box import SIMPLE
from rich.columns import Columns
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.theme import Theme
from supriya import Server
from supriya.patterns import EventPattern, SequencePattern

from .helpers import stylize

from .matrix_pitch import (
    DisplayColor,
    DisplayFormat,
    MatrixPitch,
    PitchType,
    Tuning,
)


class Matrix:
    DEFAULT_MULTIPLES = 4

    def __init__(
        self,
        bass: str | NamedPitch,
        melody: str | NamedPitch,
        multiples: int | None = None,
        pitch_type: PitchType = PitchType.HERTZ,
        tuning: Tuning = Tuning.MICROTONAL,
        display_format: DisplayFormat = DisplayFormat.TABLE,
        midi_input=False,
    ):
        if not multiples:
            multiples = self.DEFAULT_MULTIPLES
        self._multiples = range(multiples)
        self._midi_input = midi_input
        self._pitch_type = self._get_pitch_type(bass, midi_input, pitch_type)
        self._tuning = tuning
        self._display_format = display_format
        self.bass = self._get_frequency_from_input(bass)
        self.melody = self._get_frequency_from_input(melody)

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, type(self)):
            return NotImplemented
        return other.bass == self.bass and other.melody == self.melody

    def __hash__(self) -> int:
        return hash((self.bass, self.melody))

    def __repr__(self) -> str:
        return f"Matrix({self.bass}, {self.melody})"

    @staticmethod
    def _get_pitch_type(
        bass: str | NamedPitch,
        midi_input: bool,
        pitch_type: PitchType | None,
    ) -> PitchType:
        if pitch_type:
            return pitch_type
        if isinstance(bass, NamedPitch):
            return PitchType.LILYPOND
        if bass.isnumeric():
            if midi_input:
                return PitchType.MIDI
            return PitchType.HERTZ
        return PitchType.LILYPOND

    @staticmethod
    @lru_cache
    def _convert_midi_to_hertz(midi_number: float) -> float:
        return (2 ** ((midi_number - 69) / 12)) * 440

    def _get_frequency_from_input(self, pitch: str | NamedPitch) -> float:
        if isinstance(pitch, NamedPitch):
            return pitch.hertz
        try:
            frequency = float(pitch)
            if self._midi_input:
                return self._convert_midi_to_hertz(frequency)
            return frequency
        except ValueError:
            return NamedPitch(pitch).hertz

    @property
    def pitches(self) -> list[MatrixPitch]:
        frequencies = []
        multiples = self._multiples
        for bass_multiplier in multiples:
            for melody_multiplier in multiples:
                matrix_pitch = MatrixPitch(
                    self.bass,
                    self.melody,
                    bass_multiplier,
                    melody_multiplier,
                )
                frequencies.append(matrix_pitch)
        return frequencies

    @cached_property
    def sorted_pitches(self) -> list[MatrixPitch]:
        frequencies = sorted(
            self.pitches, key=MatrixPitch.get_sortable_frequency
        )
        return [frequency for frequency in frequencies if frequency.frequency]

    @cached_property
    def sorted_frequencies(self) -> list[float]:
        return [
            frequency.frequency
            for frequency in self.sorted_pitches
            if frequency.frequency
        ]

    @property
    def display_pitches(self) -> list[str]:
        return [
            frequency.get_display(
                self._pitch_type, self._tuning, self._display_format
            )
            for frequency in self.sorted_pitches
        ]

    @property
    def sorted_generated_pitches(self) -> list[MatrixPitch]:
        return [
            frequency
            for frequency in self.sorted_pitches
            if frequency.frequency and not frequency.is_base_frequency
        ]

    @staticmethod
    def _get_multiplier_label(multiplier: int, pitch: str) -> str:
        multiplier_label = f"{multiplier} x {pitch}"
        if multiplier == 1:
            color = DisplayColor.BASE_FREQUENCY
            bold = True
        elif multiplier > 1:
            if pitch == "bass":
                color = DisplayColor.BASS_MULTIPLE
            else:
                color = DisplayColor.MELODY_MULTIPLE
            bold = False
        else:
            color = DisplayColor.LABEL
            bold = False
        return stylize(multiplier_label, color, bold=bold)

    def _get_display_title(self) -> str:
        pitch_type = self._pitch_type
        title = f"Combination-Tone Matrix ({pitch_type.title()})"
        return stylize(title, "cyan")

    def _get_display_table(self) -> Table:
        title = self._get_display_title()
        return Table(title=title, show_header=False, box=SIMPLE)

    def _display_chord(self):
        table = self._get_display_table()
        for frequency in reversed(self.sorted_pitches):
            frequency_display = frequency.get_display(
                self._pitch_type, self._tuning, self._display_format
            )
            table.add_row(frequency_display)
        Console().print(table)

    def _display_list(self):
        frequencies = " ".join(self.display_pitches)
        console = Console(theme=Theme(inherit=False))
        console.print(frequencies)

    def _display_melody(self):
        labels = [
            frequency._get_display_label(display_format=DisplayFormat.MELODY)
            for frequency in self.sorted_pitches
        ]
        labeled_pitches = [
            Panel("\n".join(pitch), box=SIMPLE)
            for pitch in zip(labels, self.display_pitches)
        ]
        title = self._get_display_title()
        columns = Columns(labeled_pitches, title=title)
        print(columns)

    def _display_table(self):
        table = self._get_display_table()
        melody_header = [""] + [
            self._get_multiplier_label(multiplier, "melody")
            for multiplier in self._multiples
        ]
        table.add_row(*melody_header)
        for multiple in self._multiples:
            display_frequencies = [
                frequency.get_display(
                    self._pitch_type,
                    self._tuning,
                    self._display_format,
                )
                for frequency in self.pitches
                if frequency.bass_multiplier == multiple
            ]
            bass_label = [self._get_multiplier_label(multiple, "bass")]
            formatted_row = bass_label + display_frequencies
            table.add_row(*formatted_row)
        Console().print(table)

    def display(self):
        display_format = self._display_format
        if display_format == DisplayFormat.CHORD:
            self._display_chord()
        elif display_format == DisplayFormat.LIST:
            self._display_list()
        elif display_format == DisplayFormat.MELODY:
            self._display_melody()
        else:
            self._display_table()

    def play(self):
        EventPattern(
            frequency=SequencePattern(self.sorted_frequencies),
            delta=0.05,
        ).play(Server().boot())
        sleep(5)
