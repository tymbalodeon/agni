from dataclasses import dataclass, field
from functools import cached_property

from abjad import Duration, NamedPitch, Tuplet

from .helpers import get_instrument_name

from .matrix import Matrix
from .matrix_pitch import DisplayFormat, MatrixPitch, PitchType, Tuning


def get_default_duration() -> Duration:
    return Duration((1, 4))


@dataclass
class MatrixLeaf:
    _bass: NamedPitch | None
    _melody: NamedPitch | None
    duration: Duration | None = field(default_factory=get_default_duration)
    is_multi_measure_rest: bool = False
    tie: bool = False
    tuplet: Tuplet | None = None
    is_start_of_tuplet: bool = False
    _multiples: int = Matrix.DEFAULT_MULTIPLES
    _pitch_type: PitchType = PitchType.LILYPOND
    _tuning: Tuning = Tuning.MICROTONAL
    _display_format: DisplayFormat = DisplayFormat.TABLE

    @property
    def matrix(self) -> Matrix | None:
        if not self._bass or not self._melody:
            return None
        return Matrix(
            self._bass,
            self._melody,
            self._multiples,
            self._pitch_type,
            self._tuning,
            self._display_format,
        )

    @property
    def contains_pitches(self) -> bool:
        return all([self._bass, self._melody])

    @cached_property
    def generated_pitches(self) -> list[MatrixPitch]:
        bass = self._bass
        melody = self._melody
        duration = self.duration
        if not bass or not melody or not duration:
            return []
        matrix = Matrix(bass.name, melody.name, self._multiples)
        return matrix.sorted_generated_pitches

    @cached_property
    def instrument_names(self) -> list[str]:
        multiples = range(self._multiples)
        staff_names = []
        for melody_multiple in multiples:
            for bass_multiple in multiples:
                if (
                    bass_multiple == 0
                    and melody_multiple == 0
                    or bass_multiple == 1
                    and melody_multiple == 0
                    or bass_multiple == 0
                    and melody_multiple == 1
                ):
                    continue
                instrument_name = get_instrument_name(
                    bass_multiple, melody_multiple
                )
                staff_names.append(instrument_name)
        return staff_names
