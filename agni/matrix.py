from enum import Enum
from functools import cached_property, lru_cache
from time import sleep
from typing import TypeAlias

from abjad import NamedPitch
from rich.box import SIMPLE
from rich.console import Console
from rich.table import Table
from supriya.patterns import EventPattern, SequencePattern

from .helpers import remove_none_values
from .matrix_frequency import MatrixFrequency, OutputType, Tuning

Pitch: TypeAlias = NamedPitch | str | float


class InputType(Enum):
    HERTZ = "hertz"
    MIDI = "midi"


class Matrix:
    def __init__(
        self,
        bass: Pitch,
        melody: Pitch,
        input_type: InputType,
        multiples: int,
        output_type: OutputType,
        tuning: Tuning,
    ):
        self.input_type = input_type
        self.output_type = output_type
        self.tuning = tuning
        self._multiples = range(multiples)
        self.bass = self._get_frequency_from_input(bass)
        self.melody = self._get_frequency_from_input(melody)

    @staticmethod
    @lru_cache
    def _convert_midi_to_frequency(midi_number: float | str) -> float:
        if isinstance(midi_number, str):
            midi_number = float(midi_number)
        return (2 ** ((midi_number - 69) / 12)) * 440

    def _get_frequency_from_input(self, pitch: Pitch) -> float:
        if isinstance(pitch, NamedPitch):
            return pitch.hertz
        if self.input_type == InputType.MIDI and (
            isinstance(pitch, float)
            or isinstance(pitch, str)
            and pitch.isnumeric()
        ):
            return self._convert_midi_to_frequency(pitch)
        if isinstance(pitch, str):
            if pitch.isnumeric():
                return float(pitch)
            return NamedPitch(pitch).hertz
        return pitch

    @cached_property
    def frequencies(self) -> list[MatrixFrequency]:
        frequencies = []
        multiples = self._multiples
        for bass_multiplier in multiples:
            for melody_multiplier in multiples:
                matrix_frequency = MatrixFrequency(
                    self.bass, self.melody, bass_multiplier, melody_multiplier
                )
                frequencies.append(matrix_frequency)
        return frequencies

    @cached_property
    def sorted_frequencies(self) -> list[MatrixFrequency]:
        return sorted(
            self.frequencies, key=MatrixFrequency.get_sortable_frequency
        )

    @cached_property
    def sorted_frequencies_in_hertz(self) -> list[float]:
        sorted_frequencies = sorted(
            self.frequencies, key=MatrixFrequency.get_sortable_frequency
        )
        sorted_frequencies_in_hertz = [
            frequency.frequency for frequency in sorted_frequencies
        ]
        return remove_none_values(sorted_frequencies_in_hertz)

    @staticmethod
    def _get_multiplier_label(multiplier: int, pitch: str) -> str:
        return f"[bold]{multiplier} * {pitch}[/bold]"

    def _display_table(self):
        output_type = self.output_type
        title = f"Combination-Tone Matrix ({output_type.value.title()})"
        table = Table(title=title, show_header=False, box=SIMPLE)
        melody_header = [""] + [
            self._get_multiplier_label(multiplier, "melody")
            for multiplier in self._multiples
        ]
        table.add_row(*melody_header)
        for multiple in self._multiples:
            display_frequencies = [
                frequency.get_display(output_type, self.tuning, table=True)
                for frequency in self.frequencies
                if frequency.bass_multiplier == multiple
            ]
            bass_label = [self._get_multiplier_label(multiple, "bass")]
            formatted_row = bass_label + display_frequencies
            table.add_row(*formatted_row)
        Console().print(table)

    def _display_sorted(self):
        console = Console()
        for frequency in reversed(self.sorted_frequencies):
            frequency_display = frequency.get_display(
                self.output_type, self.tuning, table=False
            )
            if frequency._is_base_frequency or frequency._is_base_multiple:
                console.print(frequency_display)
            else:
                print(frequency_display)

    def display(self, sorted: bool):
        if sorted:
            self._display_sorted()
        else:
            self._display_table()

    def play(self):
        pattern = EventPattern(
            frequency=SequencePattern(self.sorted_frequencies_in_hertz),
            delta=0.05,
        )
        pattern.play()
        sleep(5)
