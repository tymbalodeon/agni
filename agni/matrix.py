from functools import cached_property, lru_cache
from time import sleep

from abjad import NamedPitch
from rich.box import SIMPLE
from rich.console import Console
from rich.table import Table
from rich.theme import Theme
from supriya.patterns import EventPattern, SequencePattern

from .helpers import stylize
from .matrix_frequency import DisplayFormat, MatrixFrequency, PitchType, Tuning


class Matrix:
    def __init__(
        self,
        bass: str | NamedPitch,
        melody: str | NamedPitch,
        multiples: int,
        pitch_type: PitchType = PitchType.HERTZ,
        tuning: Tuning = Tuning.MICROTONAL,
        display_format: DisplayFormat = DisplayFormat.TABLE,
        midi_input=False,
    ):
        self._multiples = range(multiples)
        self._midi_input = midi_input
        self._pitch_type = self._get_pitch_type(bass, midi_input, pitch_type)
        self._tuning = tuning
        self._display_format = display_format
        self._bass = self._get_frequency_from_input(bass)
        self._melody = self._get_frequency_from_input(melody)

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
                    self._bass,
                    self._melody,
                    bass_multiplier,
                    melody_multiplier,
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

    def get_sorted_generated_frequencies(self) -> list[MatrixFrequency]:
        return [
            frequency
            for frequency in self.sorted_frequencies
            if frequency.frequency and not frequency.is_base_frequency
        ]

    @staticmethod
    def _get_multiplier_label(multiplier: int, pitch: str) -> str:
        multiplier_label = f"{multiplier} x {pitch}"
        return stylize(multiplier_label, "white", bold=False)

    def _get_display_table(self) -> Table:
        pitch_type = self._pitch_type
        title = f"Combination-Tone Matrix ({pitch_type.value.title()})"
        title = stylize(title, "cyan")
        return Table(title=title, show_header=False, box=SIMPLE)

    def _display_list(self):
        frequencies = [
            frequency.get_display(
                self._pitch_type, self._tuning, self._display_format
            )
            for frequency in self.sorted_frequencies
        ]
        frequencies = ", ".join(frequencies)
        console = Console(theme=Theme(inherit=False))
        console.print(frequencies)

    def _display_stack(self):
        table = self._get_display_table()
        for frequency in reversed(self.sorted_frequencies):
            frequency_display = frequency.get_display(
                self._pitch_type, self._tuning, self._display_format
            )
            table.add_row(frequency_display)
        Console().print(table)

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
                for frequency in self.frequencies
                if frequency.bass_multiplier == multiple
            ]
            bass_label = [self._get_multiplier_label(multiple, "bass")]
            formatted_row = bass_label + display_frequencies
            table.add_row(*formatted_row)
        Console().print(table)

    def display(self):
        display_format = self._display_format
        if display_format == DisplayFormat.LIST:
            self._display_list()
        elif display_format == DisplayFormat.STACK:
            self._display_stack()
        else:
            self._display_table()

    def play(self):
        pattern = EventPattern(
            frequency=SequencePattern(self.sorted_frequencies_in_hertz),
            delta=0.05,
        )
        pattern.play()
        sleep(5)
