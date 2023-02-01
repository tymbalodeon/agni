from functools import cached_property, lru_cache
from time import sleep

from abjad import NamedPitch
from rich.box import SIMPLE
from rich.console import Console
from rich.table import Table
from supriya.patterns import EventPattern, SequencePattern

from .matrix_frequency import DisplayType, MatrixFrequency, Tuning


class Matrix:
    def __init__(
        self,
        bass: str | NamedPitch,
        melody: str | NamedPitch,
        multiples: int,
        display_type: DisplayType,
        tuning: Tuning,
        midi_input=False,
    ):
        self._multiples = range(multiples)
        self._midi_input = midi_input
        self._display_type = self._get_display_type(
            bass, midi_input, display_type
        )
        self._tuning = tuning
        self.bass = self._get_frequency_from_input(bass)
        self.melody = self._get_frequency_from_input(melody)

    @staticmethod
    def _get_display_type(
        bass: str, midi_input: bool, display_type: DisplayType | None
    ) -> DisplayType:
        if display_type:
            return display_type
        if midi_input:
            return DisplayType.MIDI
        if bass.isnumeric():
            return DisplayType.HERTZ
        return DisplayType.LILYPOND

    @staticmethod
    @lru_cache
    def _convert_midi_to_hertz(midi_number: float | str) -> float:
        if isinstance(midi_number, str):
            midi_number = float(midi_number)
        return (2 ** ((midi_number - 69) / 12)) * 440

    def _get_frequency_from_input(self, pitch: str | NamedPitch) -> float:
        if isinstance(pitch, NamedPitch):
            return pitch.hertz
        if pitch.isnumeric():
            if self._midi_input:
                return self._convert_midi_to_hertz(pitch)
            return float(pitch)
        return NamedPitch(pitch).hertz

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
        frequencies = sorted(
            self.frequencies, key=MatrixFrequency.get_sortable_frequency
        )
        return [frequency for frequency in frequencies if frequency.frequency]

    @cached_property
    def sorted_frequencies_in_hertz(self) -> list[float]:
        return [
            frequency.frequency
            for frequency in self.sorted_frequencies
            if frequency.frequency
        ]

    @staticmethod
    def _get_multiplier_label(multiplier: int, pitch: str) -> str:
        return f"[bold cyan]{multiplier} * {pitch}[/bold cyan]"

    def _display_table(self):
        display_type = self._display_type
        title = f"Combination-Tone Matrix ({display_type.value.title()})"
        table = Table(title=title, show_header=False, box=SIMPLE)
        melody_header = [""] + [
            self._get_multiplier_label(multiplier, "melody")
            for multiplier in self._multiples
        ]
        table.add_row(*melody_header)
        for multiple in self._multiples:
            display_frequencies = [
                frequency.get_display(display_type, self._tuning, table=True)
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
                self._display_type, self._tuning, table=False
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
