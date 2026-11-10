/datum/looping_sound/swarmer_analyzer
	start_sound = 'sound/machines/swarmer/analyzer_start.ogg'
	start_length = 1 SECONDS
	mid_sounds = list('sound/machines/swarmer/analyzer_loop_1.ogg', 'sound/machines/swarmer/analyzer_loop_2.ogg', 'sound/machines/swarmer/analyzer_loop_3.ogg')
	mid_length = 3.3 SECONDS
	end_sound = 'sound/machines/swarmer/analyzer_end.ogg'
	volume = 70
	vary = FALSE
	falloff_distance = 0
	falloff_exponent = 4
	extra_range = -10

/datum/looping_sound/swarmer_processer
	mid_sounds = 'sound/machines/swarmer/processer_loop.ogg'
	mid_length = 0.6 SECONDS
	volume = 50
	vary = FALSE
	falloff_distance = 0
	falloff_exponent = 4
	extra_range = -10
