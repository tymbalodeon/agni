def get_frequency(multiplier, bass_multiple, melody):
    melody_multiple = melody * multiplier
    return bass_multiple + melody_multiple


def get_melody_columns(multiplier, columns, bass, melody):
    bass_multiple = bass * multiplier
    return [get_frequency(column, bass_multiple, melody) for column in columns]


def get_matrix(bass, melody, count=5):
    rows = range(count)
    return [get_melody_columns(row, rows, bass, melody) for row in rows]


def display_matrix(matrix):
    for row in matrix:
        print(row)


def get_sorted_pitches(matrix, limit=None):
    pitches = [frequency for row in matrix for frequency in row]
    pitches.sort()
    if not limit:
        return pitches
    return pitches[:limit]
