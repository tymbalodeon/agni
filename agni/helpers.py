from functools import lru_cache
from abjad import NamedPitch, NumberedPitch


@lru_cache
def quantize_pitch(pitch: NamedPitch) -> NamedPitch:
    pitch_number = pitch.number
    if not isinstance(pitch_number, float):
        return pitch
    pitch_number = int(pitch_number)
    pitch_name = NumberedPitch(pitch_number).name
    return NamedPitch(pitch_name)
