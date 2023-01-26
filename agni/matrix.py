from functools import lru_cache
from time import sleep
from typing import TypeAlias

from abjad import NamedPitch
from rich.console import Console
from supriya.patterns import EventPattern, SequencePattern

from agni.passage.passage import get_simultaneous_pitches
from agni.passage.read_passage import Passage

from .display import (
    add_melody_header,
    bolden_base_frequency,
    get_bass_header,
    get_matrix_table,
    get_row_frequencies,
)
from .enums import InputType, OutputType, Tuning
from .notate_matrix import notate_matrix, sort_frequencies

Pitch: TypeAlias = NamedPitch | str | float


class Matrix:
    DEFAULT_MULTIPLES = 4

    def __init__(
        self,
        bass: Pitch,
        melody: Pitch,
        input_type: InputType,
        multiples: int | None = None,
    ):
        self.bass = get_frequency(bass, input_type)
        self.melody = get_frequency(melody, input_type)
        if multiples:
            self.multiples = multiples
        else:
            self.multiples = self.DEFAULT_MULTIPLES

    def get_frequencies(
        self, multiples: int | None = None
    ) -> list[list[float]]:
        if not multiples:
            multiples = self.multiples
        rows = range(multiples)
        return [
            get_melody_column(row, rows, self.bass, self.melody)
            for row in rows
        ]

    def display(
        self,
        output_type: OutputType,
        tuning: Tuning,
        multiples: int | None = None,
    ):
        if not multiples:
            multiples = self.multiples
        table = get_matrix_table(output_type)
        frequencies = self.get_frequencies(multiples)
        add_melody_header(table, frequencies)
        for multiplier, row in enumerate(frequencies):
            row_frequencies = get_row_frequencies(
                row, tuning=tuning, output_type=output_type
            )
            bolden_base_frequency(multiplier, row_frequencies)
            bass_header = get_bass_header(multiplier)
            formatted_row = bass_header + row_frequencies
            table.add_row(*formatted_row)
        Console().print(table)

    def notate(
        self,
        tuning: Tuning,
        as_chord=False,
        persist=False,
        as_ensemble=False,
        multiples: int | None = None,
    ):
        if not multiples:
            multiples = self.multiples
        frequencies = self.get_frequencies(multiples)
        notate_matrix(
            frequencies,
            tuning=tuning,
            as_chord=as_chord,
            persist=persist,
            as_ensemble=as_ensemble,
        )

    def play(self, multiples: int | None = None):
        if not multiples:
            multiples = self.multiples
        frequencies = sort_frequencies(self.get_frequencies(multiples))
        pattern = EventPattern(
            frequency=SequencePattern(frequencies), delta=0.05
        )
        pattern.play()
        sleep(5)


@lru_cache
def convert_midi_to_frequency(midi_number: float) -> float:
    return (2 ** ((midi_number - 69) / 12)) * 440


@lru_cache
def get_frequency(pitch: Pitch, input_type: InputType) -> float:
    if isinstance(pitch, NamedPitch):
        return pitch.hertz
    if input_type == InputType.MIDI:
        return convert_midi_to_frequency(float(pitch))
    if isinstance(pitch, float):
        return pitch
    if pitch.isnumeric():
        return float(pitch)
    return NamedPitch(pitch).hertz


@lru_cache
def get_sum_frequency(
    multiplier: int, bass_multiple: float, melody: float
) -> float:
    melody_multiple = melody * multiplier
    return bass_multiple + melody_multiple


@lru_cache
def get_melody_column(
    multiplier: int, columns: range, bass: float, melody: float
) -> list[float]:
    bass_multiple = bass * multiplier
    return [
        get_sum_frequency(column, bass_multiple, melody) for column in columns
    ]


@lru_cache
def get_matrix(
    bass: Pitch, melody: Pitch, input_type=InputType.HERTZ, multiples: int = 4
) -> list[list[float]]:
    bass_frequency = get_frequency(bass, input_type=input_type)
    melody_frequency = get_frequency(melody, input_type=input_type)
    rows = range(multiples)
    return [
        get_melody_column(row, rows, bass_frequency, melody_frequency)
        for row in rows
    ]


def get_passage_matrices(
    passage: Passage,
    multiples: int,
    as_set: bool,
    adjacent_duplicates: bool,
) -> list[list[list[float]]]:
    simultaneous_pitches = get_simultaneous_pitches(
        passage,
        as_set=as_set,
        adjacent_duplicates=adjacent_duplicates,
    )
    matrices = []
    for pitches in simultaneous_pitches:
        if not len(pitches) == 2:
            continue
        bass, melody = pitches
        matrix = get_matrix(bass, melody, multiples=multiples)
        matrices.append(matrix)
    return matrices
