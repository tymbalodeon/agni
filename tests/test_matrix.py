from pytest import mark

from agni.matrix import Matrix
from tests.conftest import call_command

matrix_command = "matrix"


@mark.parametrize("arg", ["--help", "-h"])
def test_matrix_help(arg: str):
    matrix_help_text = "Create combination-tone matrix from two pitches."
    output = call_command([matrix_command, arg])
    assert matrix_help_text in output


def test_matrix_sorted_frequencies_in_hertz():
    bass = "440"
    melody = "466"
    expected_frequencies = [
        440.0,
        466.0,
        880.0,
        906.0,
        932.0,
        1_320.0,
        1_346.0,
        1_372.0,
        1_398.0,
        1_786.0,
        1_812.0,
        1_838.0,
        2_252.0,
        2_278.0,
        2_718.0,
    ]
    matrix = Matrix(bass, melody)
    assert matrix.sorted_frequencies_in_hertz == expected_frequencies


def test_matrix_command():
    bass = "440"
    melody = "466"
    expected_text = """Combination-Tone Matrix (Hertz)

             0 x melody   1 x melody   2 x melody   3 x melody
  0 x bass                466.0        932.0        1,398.0
  1 x bass   440.0        906.0        1,372.0      1,838.0
  2 x bass   880.0        1,346.0      1,812.0      2,278.0
  3 x bass   1,320.0      1,786.0      2,252.0      2,718.0
    """
    actual_output = call_command([matrix_command, bass, melody])
    expected_lines = expected_text.split("\n")
    actual_lines = actual_output.split("\n")
    for display_line, expected_line in zip(expected_lines, actual_lines):
        assert display_line.strip() == expected_line.strip()


def test_matrix_multiples_3():
    bass = "440"
    melody = "466"
    multiples = "3"
    expected_text = """Combination-Tone Matrix (Hertz)

             0 x melody   1 x melody   2 x melody
  0 x bass                466.0        932.0
  1 x bass   440.0        906.0        1,372.0
  2 x bass   880.0        1,346.0      1,812.0
    """
    actual_output = call_command(
        [matrix_command, bass, melody, "--multiples", multiples]
    )
    expected_lines = expected_text.split("\n")
    actual_lines = actual_output.split("\n")
    for display_line, expected_line in zip(expected_lines, actual_lines):
        assert display_line.strip() == expected_line.strip()


def test_matrix_pitch_type_lilypond():
    bass = "440"
    melody = "466"
    pitch_type = "lilypond"
    expected_text = """Combination-Tone Matrix (Lilypond)

             0 x melody   1 x melody   2 x melody   3 x melody
  0 x bass                bf'          bf''         f'''
  1 x bass   a'           aqs''        f'''         bf'''
  2 x bass   a''          e'''         aqs'''       dqf''''
  3 x bass   e'''         a'''         cs''''       eqs''''
    """
    actual_output = call_command(
        [matrix_command, bass, melody, "--pitch-type", pitch_type]
    )
    expected_lines = expected_text.split("\n")
    actual_lines = actual_output.split("\n")
    for display_line, expected_line in zip(expected_lines, actual_lines):
        assert display_line.strip() == expected_line.strip()


def test_matrix_pitch_type_midi():
    bass = "440"
    melody = "466"
    pitch_type = "midi"
    expected_text = """Combination-Tone Matrix (Midi)

             0 x melody   1 x melody   2 x melody   3 x melody
  0 x bass                70.0         82.0         89.0
  1 x bass   69.0         81.5         88.5         94.0
  2 x bass   81.0         88.5         93.5         97.5
  3 x bass   88.0         93.5         97.5         100.5
    """
    actual_output = call_command(
        [matrix_command, bass, melody, "--pitch-type", pitch_type]
    )
    expected_lines = expected_text.split("\n")
    actual_lines = actual_output.split("\n")
    for display_line, expected_line in zip(expected_lines, actual_lines):
        assert display_line.strip() == expected_line.strip()


def test_matrix_pitch_type_all():
    bass = "440"
    melody = "466"
    pitch_type = "all"
    expected_text = """Combination-Tone Matrix (All)

             0 x melody   1 x melody   2 x melody   3 x melody
  0 x bass                466.0        932.0        1,398.0
                          bf'          bf''         f'''
                          70.0         82.0         89.0
  1 x bass   440.0        906.0        1,372.0      1,838.0
             a'           aqs''        f'''         bf'''
             69.0         81.5         88.5         94.0
  2 x bass   880.0        1,346.0      1,812.0      2,278.0
             a''          e'''         aqs'''       dqf''''
             81.0         88.5         93.5         97.5
  3 x bass   1,320.0      1,786.0      2,252.0      2,718.0
             e'''         a'''         cs''''       eqs''''
             88.0         93.5         97.5         100.5
    """
    actual_output = call_command(
        [matrix_command, bass, melody, "--pitch-type", pitch_type]
    )
    expected_lines = expected_text.split("\n")
    actual_lines = actual_output.split("\n")
    for display_line, expected_line in zip(expected_lines, actual_lines):
        assert display_line.strip() == expected_line.strip()


def test_matrix_tuning_equal_tempered():
    bass = "440"
    melody = "466"
    tuning = "equal-tempered"
    expected_text = """Combination-Tone Matrix (Hertz)

             0 x melody   1 x melody   2 x melody   3 x melody
  0 x bass                466          932          1,398
  1 x bass   440          906          1,372        1,838
  2 x bass   880          1,346        1,812        2,278
  3 x bass   1,320        1,786        2,252        2,718
    """
    actual_output = call_command(
        [matrix_command, bass, melody, "--tuning", tuning]
    )
    expected_lines = expected_text.split("\n")
    actual_lines = actual_output.split("\n")
    for display_line, expected_line in zip(expected_lines, actual_lines):
        assert display_line.strip() == expected_line.strip()


def test_matrix_midi_input():
    bass = "440"
    melody = "466"
    expected_text = """Combination-Tone Matrix (Midi)

             0 x melody   1 x melody   2 x melody   3 x melody
  0 x bass                466.0        478.0        485.0
  1 x bass   440.0        469.5        480.0        486.5
  2 x bass   452.0        472.5        481.5        487.5
  3 x bass   459.0        475.0        483.0        488.5
    """
    actual_output = call_command(
        [matrix_command, bass, melody, "--midi-input"]
    )
    expected_lines = expected_text.split("\n")
    actual_lines = actual_output.split("\n")
    for display_line, expected_line in zip(expected_lines, actual_lines):
        assert display_line.strip() == expected_line.strip()
