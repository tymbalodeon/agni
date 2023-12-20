from abjad import NamedPitch
from pytest import mark

from agni.matrix_leaf import MatrixLeaf

from .conftest import bass_frequency, melody_frequency

bass_named_pitch = NamedPitch.from_hertz(bass_frequency)
melody_named_pitch = NamedPitch.from_hertz(melody_frequency)


def test_matrix_leaf_matrix_rest():
    matrix_leaf = MatrixLeaf(_bass=None, _melody=None)
    assert matrix_leaf.matrix is None


def test_matrix_leaf_matrix_pitch():
    matrix_leaf = MatrixLeaf(
        _bass=bass_named_pitch, _melody=melody_named_pitch
    )
    expected_sorted_frequencies = [
        440.0,
        466.1637615180899,
        880.0,
        906.1637615180899,
        932.3275230361799,
        1320.0,
        1346.1637615180898,
        1372.3275230361799,
        1398.49128455427,
        1786.1637615180898,
        1812.3275230361799,
        1838.49128455427,
        2252.3275230361796,
        2278.49128455427,
        2718.49128455427,
    ]
    assert (
        matrix_leaf.matrix
        and matrix_leaf.matrix.sorted_frequencies
        == expected_sorted_frequencies
    )


expected_values = [
    (None, None, False),
    (
        bass_named_pitch,
        melody_named_pitch,
        True,
    ),
]


@mark.parametrize("bass, melody, expected", expected_values)
def test_matrix_leaf_contains_pitches(
    bass: NamedPitch, melody: NamedPitch, expected: bool
):
    matrix_leaf = MatrixLeaf(_bass=bass, _melody=melody)
    assert matrix_leaf.contains_pitches == expected


def test_matrix_leaf_generated_pitches_rest():
    matrix_leaf = MatrixLeaf(_bass=None, _melody=None)
    assert matrix_leaf.generated_pitches == []


def test_matrix_leaf_generated_pitches_pitch():
    matrix_leaf = MatrixLeaf(
        _bass=bass_named_pitch, _melody=melody_named_pitch
    )
    expected_sorted_frequencies = {
        880.0,
        906.1637615180899,
        932.3275230361799,
        1320.0,
        1346.1637615180898,
        1372.3275230361799,
        1398.49128455427,
        1786.1637615180898,
        1812.3275230361799,
        1838.49128455427,
        2252.3275230361796,
        2278.49128455427,
        2718.49128455427,
    }
    actual_frequencies = {
        matrix_pitch.frequency
        for matrix_pitch in matrix_leaf.generated_pitches
    }
    assert actual_frequencies == expected_sorted_frequencies


expected_instrument_names_multiples_4 = [
    "2B",
    "3B",
    "B + M",
    "2B + M",
    "3B + M",
    "2M",
    "B + 2M",
    "2B + 2M",
    "3B + 2M",
    "3M",
    "B + 3M",
    "2B + 3M",
    "3B + 3M",
]
expected_instrument_names_multiples_5 = [
    "2B",
    "3B",
    "4B",
    "B + M",
    "2B + M",
    "3B + M",
    "4B + M",
    "2M",
    "B + 2M",
    "2B + 2M",
    "3B + 2M",
    "4B + 2M",
    "3M",
    "B + 3M",
    "2B + 3M",
    "3B + 3M",
    "4B + 3M",
    "4M",
    "B + 4M",
    "2B + 4M",
    "3B + 4M",
    "4B + 4M",
]
expected_instrument_name_values = [
    (4, expected_instrument_names_multiples_4),
    (5, expected_instrument_names_multiples_5),
]


@mark.parametrize(
    "multiples, expected_instrument_names", expected_instrument_name_values
)
def test_matrix_leaf_instrument_names(
    multiples: int, expected_instrument_names: list[str]
):
    matrix_leaf = MatrixLeaf(_bass=None, _melody=None, _multiples=multiples)
    print(matrix_leaf.instrument_names)
    assert matrix_leaf.instrument_names == expected_instrument_names
