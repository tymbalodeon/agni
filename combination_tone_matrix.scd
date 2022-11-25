(
~get_frequency = {
    arg multiplier, bass_multiple, melody;
    var melody_multiple = melody * multiplier;
    bass_multiple + melody_multiple;
};

~get_melody_column = {
    arg multiplier, columns, bass, melody;
    var bass_multiple = bass * multiplier;
    var melody_column = Array.newClear(columns);
    var add_frequency = {
        arg column;
        var frequency = ~get_frequency.value(column, bass_multiple, melody);
        melody_column.put(column, frequency);
    };
    columns.do(add_frequency);
    melody_column;
};

~get_matrix = {
    arg bass, melody, count = 5;
    var bass_rows = Array.newClear(count);
    var add_column = {
        arg row;
        var column = ~get_melody_column.value(row, count, bass, melody);
        bass_rows.put(row, column);
    };
    bass = bass.midicps;
    melody = melody.midicps;
    count.do(add_column);
    bass_rows;
};

~display_matrix = {
    arg matrix;
    var post_row = {
        arg item;
        item.postln;
    };
    matrix.do(post_row);
};

~sort_frequencies = {
    arg matrix, limit = 0;
    var frequencies = matrix.flatten[1..].sort;
    if (limit > 0) {
        frequencies[..limit]
    } {
        frequencies
    };
};

~play_matrix = {
    arg matrix, as_chord = false;
    var frequencies = ~sort_frequencies.value(matrix);
    var amplitude = 0.1;
    if (as_chord) {
        amplitude = amplitude / frequencies.size;
        frequencies = [frequencies];
    };
    Pbind(
        \freq, Pseq(frequencies),
        \dur, 0.2,
        \amp, amplitude
    ).play;
};
)
