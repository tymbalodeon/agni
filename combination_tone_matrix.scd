(
	var get_pitch = {
		arg multiplier, bass_multiple, melody;
		var melody_multiple = melody * multiplier;
		bass_multiple + melody_multiple
	};

	var get_melody_column = {
		arg multiplier, columns, bass, melody;
		var bass_multiple = bass * multiplier;
		var melody_column = Array.newClear(columns);
		var add_pitch = {
			arg column;
			var pitch = get_pitch.value(column, bass_multiple, melody);
			melody_column.put(column, pitch);
		};
		columns.do(add_pitch);
		melody_column
	};

	var get_matrix = {
		arg bass, melody, count = 5;
		var bass_rows = Array.newClear(count);
		var add_column = {
			arg row;
			var column = get_melody_column.value(row, count, bass, melody);
			bass_rows.put(row, column);
		};
		bass = bass.midicps;
		melody = melody.midicps;
		count.do(add_column);
		bass_rows
	};

	var display_matrix = {
		arg matrix;
		var post_row = {
			arg item;
			item.postln;
		};
		matrix.do(post_row)
	};

	var get_sorted_pitches = {
		arg matrix, limit = 0;
		var pitches = matrix.flatten[1..];
		if (limit > 0) {
			pitches.sort[..limit]
		} {
			pitches.sort
		}
	};
)
