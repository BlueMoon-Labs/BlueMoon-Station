#ifdef ROUND_10294_BENCHMARK

#define PROFILE_BENCHMARK_REPEATS 1000
#define TEXT_BENCHMARK_REPEATS 100
#define FLAT_ICON_BENCHMARK_REPEATS 200

/// Парные замеры повторного превью, форматирования и первого кадра сложной анимации.
/datum/unit_test/round_10294_profile_icon_benchmark/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human/dummy/consistent)
	var/datum/description_profile/profile = allocate(/datum/description_profile, subject)
	var/atom/movable/screen/map_view/examine_panel_screen/screen = allocate(/atom/movable/screen/map_view/examine_panel_screen)
	var/flavor_text = ""
	for(var/paragraph_index in 1 to 20)
		flavor_text += "**Описание персонажа [paragraph_index]**. *Детали внешности*, -=ff8800=-цвет-=RESET=- и <экранируемый текст>.\n"
	profile.format_text("flavortext", flavor_text)
	screen.update_character(subject)

	var/icon/animated = new
	for(var/frame_index in 1 to 16)
		var/icon/frame = icon('icons/effects/effects.dmi', "nothing")
		frame.DrawBox(rgb(frame_index * 15, 100, 200), 1, 1, 32, 32)
		animated.Insert(frame, "test", SOUTH, frame_index, FALSE)
	var/image/composite = image(animated, icon_state = "test")
	for(var/layer_index in 1 to 12)
		var/image/overlay = image(animated, icon_state = "test", layer = -1)
		overlay.pixel_x = layer_index % 4
		overlay.pixel_y = layer_index % 3
		overlay.alpha = 180
		composite.overlays += overlay
	getFlatIcon(composite)
	getFlatIcon(composite, no_anim = TRUE)

	for(var/sample_index in 1 to 3)
		for(var/cached_path in (sample_index % 2 ? list(FALSE, TRUE) : list(TRUE, FALSE)))
			var/mode = cached_path ? "cached" : "legacy"
			var/start = TICK_USAGE_REAL
			for(var/repeat_index in 1 to PROFILE_BENCHMARK_REPEATS)
				if(cached_path)
					screen.update_character(subject)
				else
					legacy_preview(screen, subject)
			var/preview_ms = TICK_USAGE_TO_MS(start)
			start = TICK_USAGE_REAL
			for(var/repeat_index in 1 to TEXT_BENCHMARK_REPEATS)
				if(cached_path)
					profile.format_text("flavortext", flavor_text)
				else
					format_flavor_for_tgui(flavor_text)
			var/text_ms = TICK_USAGE_TO_MS(start)
			start = TICK_USAGE_REAL
			for(var/repeat_index in 1 to FLAT_ICON_BENCHMARK_REPEATS)
				var/icon/flat = getFlatIcon(composite, no_anim = cached_path)
				flat = icon(flat, "", SOUTH, 1, FALSE)
			var/flat_ms = TICK_USAGE_TO_MS(start)
			log_world("ROUND_10294_BENCHMARK profile_icons sample=[sample_index] mode=[mode] preview_repeats=[PROFILE_BENCHMARK_REPEATS] preview_ms=[preview_ms] text_repeats=[TEXT_BENCHMARK_REPEATS] text_ms=[text_ms] flat_repeats=[FLAT_ICON_BENCHMARK_REPEATS] flat_ms=[flat_ms]")

/datum/unit_test/round_10294_profile_icon_benchmark/proc/legacy_preview(atom/movable/screen/map_view/examine_panel_screen/screen, mob/target)
	var/mutable_appearance/current_mob_appearance = new(target)
	current_mob_appearance.setDir(SOUTH)
	current_mob_appearance.transform = matrix()
	current_mob_appearance.pixel_x = 0
	current_mob_appearance.pixel_y = 0
	screen.cut_overlays()
	screen.add_overlay(current_mob_appearance)

#undef PROFILE_BENCHMARK_REPEATS
#undef TEXT_BENCHMARK_REPEATS
#undef FLAT_ICON_BENCHMARK_REPEATS

#endif
