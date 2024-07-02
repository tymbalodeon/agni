from pytest import mark

from agni.matrix import Matrix
from agni.matrix_pitch import MatrixPitch

from .conftest import bass_frequency, call_command, melody_frequency

matrix_command_name = ["matrix"]
bass = "440"
melody = "466"
bass_midi = "69"
melody_midi = "70"
bass_lilypond = "a'"
melody_lilypond = "bf'"
matrix_command = matrix_command_name + [bass, melody]
matrix_command_midi = [matrix_command_name, bass_midi, melody_midi]
matrix_command_lilypond = [matrix_command_name, bass_lilypond, melody_lilypond]
multiples_option = "--multiples"
pitch_type_option = "--pitch-type"
tuning_option = "--tuning"
display_option = "--display-format"


@mark.parametrize("arg", ["--help", "-h"])
def test_matrix_help(arg: str):
    matrix_help_text = "Create combination-tone matrix from two pitches."
    output = call_command(matrix_command_name + [arg])
    assert matrix_help_text in output


def test_matrix_sorted_frequencies():
    matrix = Matrix(bass, melody)
    expected_rounded_frequencies = [
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
    assert matrix.sorted_frequencies == expected_rounded_frequencies


def test_matrix_get_sorted_generated_frequencies():
    expected_multipliers = [
        (2, 0),
        (1, 1),
        (0, 2),
        (3, 0),
        (2, 1),
        (1, 2),
        (0, 3),
        (3, 1),
        (2, 2),
        (1, 3),
        (3, 2),
        (2, 3),
        (3, 3),
    ]
    expected_pitches = [
        MatrixPitch(
            bass_frequency,
            melody_frequency,
            bass_multiplier,
            melody_multiplier,
        )
        for bass_multiplier, melody_multiplier in expected_multipliers
    ]
    matrix = Matrix(bass, melody)
    assert matrix.sorted_generated_pitches == expected_pitches


def get_stripped_lines(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines()]


def assert_lines_match(actual_output: str, expected_output: str):
    expected_lines = get_stripped_lines(expected_output)
    actual_lines = get_stripped_lines(actual_output)
    for actual_line, expected_line in zip(actual_lines, expected_lines):
        assert actual_line == expected_line


def test_matrix_command():
    expected_output = """\
                    Combination-Tone Matrix (Hertz)

                0 x melody   1 x melody   2 x melody   3 x melody
    0 x bass                466.0        932.0        1,398.0
    1 x bass   440.0        906.0        1,372.0      1,838.0
    2 x bass   880.0        1,346.0      1,812.0      2,278.0
    3 x bass   1,320.0      1,786.0      2,252.0      2,718.0
    """
    actual_output = call_command(matrix_command)
    assert_lines_match(actual_output, expected_output)


def test_matrix_command_lilypond():
    expected_output = """\
                    Combination-Tone Matrix (Lilypond)

                0 x melody   1 x melody   2 x melody   3 x melody
    0 x bass                bf'          bf''         f'''
    1 x bass   a'           aqs''        f'''         bf'''
    2 x bass   a''          e'''         aqs'''       dqf''''
    3 x bass   e'''         a'''         cs''''       eqs''''
    """
    actual_output = call_command(matrix_command_lilypond)
    assert_lines_match(actual_output, expected_output)


def test_matrix_multiples_3():
    expected_output = """\
                    Combination-Tone Matrix (Hertz)

                0 x melody   1 x melody   2 x melody
    0 x bass                466.0        932.0
    1 x bass   440.0        906.0        1,372.0
    2 x bass   880.0        1,346.0      1,812.0
    """
    actual_output = call_command(matrix_command + [multiples_option, "3"])
    assert_lines_match(actual_output, expected_output)


def test_matrix_multiples_4():
    expected_output = """\
                    Combination-Tone Matrix (Hertz)

                0 x melody   1 x melody   2 x melody   3 x melody
    0 x bass                466.0        932.0        1,398.0
    1 x bass   440.0        906.0        1,372.0      1,838.0
    2 x bass   880.0        1,346.0      1,812.0      2,278.0
    3 x bass   1,320.0      1,786.0      2,252.0      2,718.0
    """
    actual_output = call_command(matrix_command + [multiples_option, "4"])
    assert_lines_match(actual_output, expected_output)


def test_matrix_pitch_type_all():
    expected_output = """\
                    Combination-Tone Matrix (All)

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
    actual_output = call_command(matrix_command + [pitch_type_option, "all"])
    assert_lines_match(actual_output, expected_output)


def test_matrix_pitch_type_hertz():
    expected_output = """\
                    Combination-Tone Matrix (Hertz)

                0 x melody   1 x melody   2 x melody   3 x melody
    0 x bass                466.0        932.0        1,398.0
    1 x bass   440.0        906.0        1,372.0      1,838.0
    2 x bass   880.0        1,346.0      1,812.0      2,278.0
    3 x bass   1,320.0      1,786.0      2,252.0      2,718.0
    """
    actual_output = call_command(matrix_command + [pitch_type_option, "hertz"])
    assert_lines_match(actual_output, expected_output)


def test_matrix_pitch_type_midi():
    expected_output = """\
                    Combination-Tone Matrix (Midi)

                0 x melody   1 x melody   2 x melody   3 x melody
    0 x bass                70.0         82.0         89.0
    1 x bass   69.0         81.5         88.5         94.0
    2 x bass   81.0         88.5         93.5         97.5
    3 x bass   88.0         93.5         97.5         100.5
    """
    actual_output = call_command(matrix_command + [pitch_type_option, "midi"])
    assert_lines_match(actual_output, expected_output)


def test_matrix_pitch_type_lilypond():
    expected_output = """\
                    Combination-Tone Matrix (Lilypond)

                0 x melody   1 x melody   2 x melody   3 x melody
    0 x bass                bf'          bf''         f'''
    1 x bass   a'           aqs''        f'''         bf'''
    2 x bass   a''          e'''         aqs'''       dqf''''
    3 x bass   e'''         a'''         cs''''       eqs''''
    """
    actual_output = call_command(
        matrix_command + [pitch_type_option, "lilypond"]
    )
    assert_lines_match(actual_output, expected_output)


def test_matrix_tuning_equal_tempered():
    expected_output = """\
                    Combination-Tone Matrix (Hertz)

                0 x melody   1 x melody   2 x melody   3 x melody
    0 x bass                466          932          1,398
    1 x bass   440          906          1,372        1,838
    2 x bass   880          1,346        1,812        2,278
    3 x bass   1,320        1,786        2,252        2,718
    """
    actual_output = call_command(
        matrix_command + [tuning_option, "equal_tempered"]
    )
    assert_lines_match(actual_output, expected_output)


def test_matrix_tuning_microtonal():
    expected_output = """\
                    Combination-Tone Matrix (Hertz)

                0 x melody   1 x melody   2 x melody   3 x melody
    0 x bass                466.0        932.0        1,398.0
    1 x bass   440.0        906.0        1,372.0      1,838.0
    2 x bass   880.0        1,346.0      1,812.0      2,278.0
    3 x bass   1,320.0      1,786.0      2,252.0      2,718.0
    """
    actual_output = call_command(
        matrix_command + [tuning_option, "microtonal"]
    )
    assert_lines_match(actual_output, expected_output)


def test_matrix_midi_input():
    expected_output = """\
                    Combination-Tone Matrix (Midi)

                0 x melody   1 x melody   2 x melody   3 x melody
    0 x bass                70.0         82.0         89.0
    1 x bass   69.0         81.5         88.5         94.0
    2 x bass   81.0         88.5         93.5         97.5
    3 x bass   88.0         93.5         97.5         100.5
    """
    actual_output = call_command(matrix_command_midi + ["--midi-input"])
    assert_lines_match(actual_output, expected_output)


def test_matrix_display_chord():
    expected_output = """\
      Combination-Tone Matrix (Hertz)

    (3 x bass) + (3 x melody) = 2,718.0
    (2 x bass) + (3 x melody) = 2,278.0
    (3 x bass) + (2 x melody) = 2,252.0
    (1 x bass) + (3 x melody) = 1,838.0
    (2 x bass) + (2 x melody) = 1,812.0
    (3 x bass) + (1 x melody) = 1,786.0
    (0 x bass) + (3 x melody) = 1,398.0
    (1 x bass) + (2 x melody) = 1,372.0
    (2 x bass) + (1 x melody) = 1,346.0
    (3 x bass) + (0 x melody) = 1,320.0
    (0 x bass) + (2 x melody) = 932.0
    (1 x bass) + (1 x melody) = 906.0
    (2 x bass) + (0 x melody) = 880.0
    (0 x bass) + (1 x melody) = 466.0
    (1 x bass) + (0 x melody) = 440.0
    """
    actual_output = call_command(matrix_command + [display_option, "chord"])
    assert_lines_match(actual_output, expected_output)


def test_matrix_display_list():
    expected_output = (
        "440.0 466.0 880.0 906.0 932.0 1,320.0 1,346.0 1,372.0"
        " 1,398.0 1,786.0 1,812.0 1,838.0 2,252.0 2,278.0 2,718.0"
    )
    actual_output = call_command(matrix_command + [display_option, "list"])
    actual_output = actual_output.replace("\n", "").strip()
    assert expected_output == actual_output


def test_matrix_display_melody():
    expected_output = """\
                    Combination-Tone Matrix (Hertz)

    1B + 0M     0B + 1M     2B + 0M     1B + 1M     0B + 2M     3B + 0M
    440.0       466.0       880.0       906.0       932.0       1,320.0


    2B + 1M     1B + 2M     0B + 3M     3B + 1M     2B + 2M     1B + 3M
    1,346.0     1,372.0     1,398.0     1,786.0     1,812.0     1,838.0


    3B + 2M     2B + 3M     3B + 3M
    2,252.0     2,278.0     2,718.0
    """
    actual_output = call_command(matrix_command + [display_option, "melody"])
    assert_lines_match(actual_output, expected_output)


def test_matrix_display_table():
    expected_output = """\
                    Combination-Tone Matrix (Hertz)

                0 x melody   1 x melody   2 x melody   3 x melody
    0 x bass                466.0        932.0        1,398.0
    1 x bass   440.0        906.0        1,372.0      1,838.0
    2 x bass   880.0        1,346.0      1,812.0      2,278.0
    3 x bass   1,320.0      1,786.0      2,252.0      2,718.0
    """
    actual_output = call_command(matrix_command + [display_option, "table"])
    assert_lines_match(actual_output, expected_output)
