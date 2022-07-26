def get_pitch(multiplier, bass_multiple, melody):
    melody_multiple = melody * multiplier
    return bass_multiple + melody_multiple


def get_melody_column(multiplier, columns, bass, melody):
    bass_multiple = bass * multiplier
    return [get_pitch(column, bass_multiple, melody) for column in columns]


def get_matrix(bass, melody, count=5):
    rows = range(count)
    return [get_melody_column(row, rows, bass, melody) for row in rows]


def display_matrix(matrix):
    for row in matrix:
        print(row)


def get_sorted_pitches(matrix, limit=None):
    pitches = [pitch for row in matrix for pitch in row]
    pitches.sort()
    pitches = pitches[1:]
    if not limit:
        return pitches
    return pitches[:limit]
