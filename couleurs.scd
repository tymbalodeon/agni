(
	var post_sum_and_difference_tones = {
		arg modulator,
			carrier,
			number_of_harmonics,
			number_of_carrier_harmonics;

		var get_carrier_harmonic = {
			arg carrier, harmonic = 0, with_harmonics = false;

			if (with_harmonics) {
				harmonic = harmonic + 1;
				carrier * harmonic
			} {
				carrier
			};
		};

		var get_sum_or_difference = {
			arg modulator, carrier, subtract = false;

			if (subtract) {
				modulator - carrier
			} {
				modulator + carrier
			};
		};

		var get_sum_and_difference_tones = {
			var get_modulate_function = {
				arg subtract = false, with_harmonics = false, carrier_harmonic = 0;

				{
					arg harmonic;
					var pitch, modulator_pitch, carrier_pitch;

					harmonic = harmonic + 1;
					modulator_pitch = modulator * harmonic;
					carrier_pitch = get_carrier_harmonic.value(
						carrier, carrier_harmonic, with_harmonics
					);
					pitch = get_sum_or_difference.value(
						modulator_pitch, carrier_pitch, subtract
					);
					pitch.abs.cpsmidi
				}
			};

			var get_carrier_harmonics_function = {
				arg modulator_harmonic;

				{
					arg carrier_harmonic;

					add_pitch = get_modulate_function.value(
						with_harmonics: true, carrier_harmonic: carrier_harmonic
					);
					subtract_pitch = get_modulate_function.value(
						subtract: true,
						with_harmonics: true,
						carrier_harmonic: carrier_harmonic
					);
					[
						add_pitch.value(modulator_harmonic),
						subtract_pitch.value(modulator_harmonic)
					]
				}
			};

			var get_modulator_harmonics = {
				arg modulator_harmonic;

				var get_carrier_harmonics = get_carrier_harmonics_function.value(
					modulator_harmonic
				);

				Array.fill(number_of_carrier_harmonics, get_carrier_harmonics)
			};

			var add_pitch = get_modulate_function.value;
			var subtract_pitch = get_modulate_function.value(subtract: true);

			var add_and_subtract_pitch = {
				arg harmonic;

				var added_pitch = add_pitch.value(harmonic);
				var subtracted_pitch = subtract_pitch.value(harmonic);

				[added_pitch, subtracted_pitch]
			};

			var additive_ring_modulator = Array.fill(number_of_harmonics, add_pitch);
			var subtractive_ring_modulator = Array.fill(
				number_of_harmonics, subtract_pitch
			);
			var add_and_subtract_ring_modulator = Array.fill(
				number_of_harmonics, add_and_subtract_pitch
			);
			var both_with_carrier_ring_modulator = Array.fill(
				number_of_harmonics, get_modulator_harmonics
			);

			var post_with_message = {
				arg message, ring_modulator;

				message.postln;
				ring_modulator.postln;
				"\n".post;
			};

			post_with_message.value("Sum:", additive_ring_modulator);
			post_with_message.value("Difference:", subtractive_ring_modulator);
			post_with_message.value(
				"Sum and difference, modulator harmonics:",
				add_and_subtract_ring_modulator
			);
			post_with_message.value(
				"Sum and difference, modulator and carrier harmonics: ",
				both_with_carrier_ring_modulator
			);
		};

		"MODULATOR: ".post; modulator.postln;
		"CARRIER: ".post; carrier.postln;
		"NUMBER OF HARMONICS ".post; number_of_harmonics.postln;
		"NUMBER OF CARRIER HARMONICS ".post; number_of_carrier_harmonics.postln;
		"\n".post;

		get_sum_and_difference_tones.value();
	};

    var modulator = 60.midicps;
    var carrier = 21.midicps;
    var modulator_harmonics = 3;
    var carrier_harmonics = 2;

	post_sum_and_difference_tones.value(
		modulator, carrier, modulator_harmonics, carrier_harmonics
	);
)