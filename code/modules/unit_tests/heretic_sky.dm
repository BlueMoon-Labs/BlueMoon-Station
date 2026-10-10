/// Снимает все голоса неба сразу, без спада.
/proc/heretic_sky_test_clear()
	for(var/datum/heretic_sky_voice/voice as anything in GLOB.heretic_sky.voices.Copy())
		GLOB.heretic_sky.remove_voice(voice)

/proc/heretic_sky_test_role_alpha(z, role)
	var/datum/parallax/template = SSparallax.get_parallax_template(z)
	for(var/atom/movable/screen/parallax_layer/heretic_sky/layer in template.objects)
		if(layer.sky_role == role)
			return layer.alpha
	return -1

/proc/heretic_sky_test_station_turf()
	return locate(1, 1, SSmapping.levels_by_trait(ZTRAIT_STATION)[1])

/proc/heretic_sky_test_station_hits()
	. = list()
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		if(SSparallax.find_modifier(station_z, HERETIC_SKY_TOKEN))
			. += station_z

/datum/unit_test/parallax_modifier_on_build
	var/list/built = list()

/datum/unit_test/parallax_modifier_on_build/proc/record(datum/parallax/template)
	built += template

/// Модификатор с callback сборки получает каждый новый шаблон своего z.
/datum/unit_test/parallax_modifier_on_build/Run()
	var/test_z = run_loc_floor_bottom_left.z
	SSparallax.add_layers(test_z, "unit_test_on_build", list(/atom/movable/screen/parallax_layer/heretic_sky/flash), PARALLAX_PRIORITY_ANTAG, 0, CALLBACK(src, PROC_REF(record)))
	var/datum/parallax/template = SSparallax.get_parallax_template(test_z)
	SSparallax.remove_modifier(test_z, "unit_test_on_build")
	TEST_ASSERT(template in built, "Сборка шаблона не позвала callback модификатора")

/// Группа неба по месту: станция целиком, полигон отдельно, прочее - ничего.
/datum/unit_test/heretic_sky_groups/Run()
	TEST_ASSERT_EQUAL(heretic_sky_group_for(heretic_sky_test_station_turf()), HERETIC_SKY_GROUP_STATION, "Станционный турф не дал группу станции")
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	var/list/group_levels = heretic_sky_group_levels(HERETIC_SKY_GROUP_STATION)
	TEST_ASSERT_EQUAL(length(group_levels), length(station_levels), "Группа станции не покрывает все станционные уровни")
	TEST_ASSERT_NULL(heretic_sky_group_for(run_loc_floor_bottom_left), "Резерв без трейта полигона получил небо")
	var/datum/space_level/level = SSmapping.z_list[run_loc_floor_bottom_left.z]
	level.traits[ZTRAIT_ANTAG_TRAINING] = TRUE
	var/group = heretic_sky_group_for(run_loc_floor_bottom_left)
	level.traits -= ZTRAIT_ANTAG_TRAINING
	TEST_ASSERT_EQUAL(group, "z[run_loc_floor_bottom_left.z]", "Полигон не получил собственную группу")
	var/list/training_levels = heretic_sky_group_levels(group)
	TEST_ASSERT(length(training_levels) == 1 && training_levels[1] == run_loc_floor_bottom_left.z, "Группа полигона захватила чужие уровни")

/// Учебное вознесение ставит небо только на свой полигон и снимает его вместе с ролью.
/datum/unit_test/heretic_sky_training_isolation/Run()
	var/datum/space_level/level = SSmapping.z_list[run_loc_floor_bottom_left.z]
	level.traits[ZTRAIT_ANTAG_TRAINING] = TRUE
	var/datum/eldritch_knowledge/final_eldritch/dance_final/final = allocate(/datum/eldritch_knowledge/final_eldritch/dance_final)
	GLOB.heretic_sky.begin(final, run_loc_floor_bottom_left, 30 SECONDS)
	GLOB.heretic_sky.ascend(final, run_loc_floor_bottom_left)
	GLOB.heretic_sky.tier(final, 3)
	var/on_training = SSparallax.find_modifier(run_loc_floor_bottom_left.z, HERETIC_SKY_TOKEN)
	var/list/station_hits = heretic_sky_test_station_hits()
	var/datum/heretic_sky_voice/voice = GLOB.heretic_sky.voice_of(final)
	GLOB.heretic_sky.end(final)
	var/released = isnull(GLOB.heretic_sky.voice_of(final))
	GLOB.heretic_sky.remove_voice(voice)
	var/left_behind = SSparallax.find_modifier(run_loc_floor_bottom_left.z, HERETIC_SKY_TOKEN)
	level.traits -= ZTRAIT_ANTAG_TRAINING
	TEST_ASSERT(on_training, "Небо учебного вознесения не легло на полигон")
	TEST_ASSERT(!length(station_hits), "Учебное вознесение тронуло станционные уровни [station_hits.Join(", ")]")
	TEST_ASSERT(released, "Координатор держит снятое знание")
	TEST_ASSERT_NULL(left_behind, "Снятая роль оставила небо на полигоне")

/// Три вознесения на станции: один модификатор, разные слоты, бюджет туманности, одно затемнение и одно затмение.
/datum/unit_test/heretic_sky_composition/Run()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/turf/station_turf = heretic_sky_test_station_turf()
	var/list/finals = list(
		allocate(/datum/eldritch_knowledge/final_eldritch/moon_final),
		allocate(/datum/eldritch_knowledge/final_eldritch/dance_final),
		allocate(/datum/eldritch_knowledge/final_eldritch/blade_final),
	)
	var/list/slots = list()
	for(var/datum/eldritch_knowledge/final_eldritch/final as anything in finals)
		var/datum/heretic_sky_voice/voice = GLOB.heretic_sky.ascend(final, station_turf)
		slots |= voice?.slot
	var/datum/parallax/template = SSparallax.get_parallax_template(station_z)
	var/tokens = 0
	for(var/datum/parallax_modifier/modifier as anything in SSparallax.modifiers_by_z["[station_z]"])
		if(modifier.token == HERETIC_SKY_TOKEN)
			tokens++
	var/tiled = 0
	var/dims = 0
	var/eclipses = 0
	var/tints = 0
	var/crowded_tint_ok = TRUE
	var/crowded_scale_ok = TRUE
	for(var/atom/movable/screen/parallax_layer/heretic_sky/layer in template.objects)
		if(layer.layer_mode == PARALLAX_MODE_TILED)
			tiled++
		if(layer.sky_role == HERETIC_SKY_ROLE_DIM)
			dims++
		if(layer.sky_role == HERETIC_SKY_ROLE_ECLIPSE)
			eclipses++
		if(layer.sky_role == HERETIC_SKY_ROLE_TINT)
			tints++
			var/datum/heretic_sky_voice/voice = GLOB.heretic_sky.slot_voice(HERETIC_SKY_GROUP_STATION, layer.sky_slot)
			if(voice.path_id != PATH_DANCE && layer.alpha != round(voice.path().sky_tint_alpha * 0.6))
				crowded_tint_ok = FALSE
		if(layer.sky_role == HERETIC_SKY_ROLE_PRESENCE && (layer.sky_slot == 1) != (layer.base_scale == initial(layer.base_scale)))
			crowded_scale_ok = FALSE
	heretic_sky_test_clear()
	TEST_ASSERT_EQUAL(tokens, 1, "Три вознесения завели [tokens] модификаторов вместо одного")
	TEST_ASSERT_EQUAL(length(slots), 3, "Знаки вознесений делят слот")
	TEST_ASSERT(tiled <= 2, "Небо держит [tiled] тайлящихся слоёв при бюджете 2")
	TEST_ASSERT_EQUAL(dims, 1, "Затемнений [dims] вместо одного")
	TEST_ASSERT_EQUAL(eclipses, 1, "Затмений [eclipses] вместо одного")
	TEST_ASSERT_EQUAL(tints, 3, "Тонировок [tints] вместо трёх")
	TEST_ASSERT(crowded_tint_ok, "Тонировка при нескольких вознесениях не приглушена")
	TEST_ASSERT(crowded_scale_ok, "Затмевающий Знак должен остаться крупным, остальные - уменьшиться")
	TEST_ASSERT_NULL(SSparallax.find_modifier(station_z, HERETIC_SKY_TOKEN), "После снятия всех голосов небо осталось")

/// Стадии ведут alpha шаблона и переживают пересборку чужим модификатором.
/datum/unit_test/heretic_sky_stages/Run()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/turf/station_turf = heretic_sky_test_station_turf()
	var/datum/eldritch_knowledge/final_eldritch/moon_final/final = allocate(/datum/eldritch_knowledge/final_eldritch/moon_final)
	GLOB.heretic_sky.begin(final, station_turf, 30 SECONDS)
	var/omen_alpha = heretic_sky_test_role_alpha(station_z, HERETIC_SKY_ROLE_GLOW)
	GLOB.heretic_sky.ascend(final, station_turf)
	var/ascended_alpha = heretic_sky_test_role_alpha(station_z, HERETIC_SKY_ROLE_GLOW)
	GLOB.heretic_sky.fall(final)
	var/fallen_alpha = heretic_sky_test_role_alpha(station_z, HERETIC_SKY_ROLE_GLOW)
	SSparallax.add_layers(station_z, "unit_test_rebuild", list(/atom/movable/screen/parallax_layer/tint/molecular_cloud))
	var/rebuilt_alpha = heretic_sky_test_role_alpha(station_z, HERETIC_SKY_ROLE_GLOW)
	SSparallax.remove_modifier(station_z, "unit_test_rebuild")
	GLOB.heretic_sky.rise(final)
	var/risen_alpha = heretic_sky_test_role_alpha(station_z, HERETIC_SKY_ROLE_GLOW)
	heretic_sky_test_clear()
	TEST_ASSERT(omen_alpha > 0 && omen_alpha < ascended_alpha, "Предзнаменование не слабее вознесения ([omen_alpha] / [ascended_alpha])")
	TEST_ASSERT(fallen_alpha < ascended_alpha, "Смерть вознёсшегося не пригасила небо")
	TEST_ASSERT_EQUAL(rebuilt_alpha, fallen_alpha, "Пересборка шаблона сбросила стадию")
	TEST_ASSERT_EQUAL(risen_alpha, ascended_alpha, "Оживление не вернуло небо")

/// Реакция неба только у вознёсшегося и не чаще кулдауна.
/datum/unit_test/heretic_sky_event_cooldown/Run()
	var/turf/station_turf = heretic_sky_test_station_turf()
	var/datum/eldritch_knowledge/final_eldritch/blade_final/final = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	GLOB.heretic_sky.begin(final, station_turf, 30 SECONDS)
	var/during_omen = GLOB.heretic_sky.event(final)
	GLOB.heretic_sky.ascend(final, station_turf)
	var/first = GLOB.heretic_sky.event(final)
	var/second = GLOB.heretic_sky.event(final)
	heretic_sky_test_clear()
	TEST_ASSERT(!during_omen, "Реакция неба сработала до вознесения")
	TEST_ASSERT(first, "Первая реакция неба не сработала")
	TEST_ASSERT(!second, "Реакция неба не держит кулдаун")

/// Громкость лупа по стадии и смешиванию; канал освобождается вместе с голосом.
/datum/unit_test/heretic_sky_loop_volume/Run()
	var/turf/station_turf = heretic_sky_test_station_turf()
	var/datum/eldritch_knowledge/final_eldritch/moon_final/final = allocate(/datum/eldritch_knowledge/final_eldritch/moon_final)
	var/datum/heretic_sky_voice/voice = GLOB.heretic_sky.begin(final, station_turf, 30 SECONDS)
	var/full = voice.path().sky_loop_volume
	var/omen = voice.loop_target(1)
	GLOB.heretic_sky.ascend(final, station_turf)
	var/ascended = voice.loop_target(1)
	var/crowd = voice.loop_target(0.7)
	var/channel = voice.channel
	heretic_sky_test_clear()
	TEST_ASSERT_EQUAL(omen, round(full * 0.35), "Луп предзнаменования не на 35%")
	TEST_ASSERT_EQUAL(ascended, full, "Луп вознесения не на полной громкости")
	TEST_ASSERT_EQUAL(crowd, round(full * 0.7), "Смешивание голосов не приглушает луп")
	TEST_ASSERT(channel, "Голос не получил звуковой канал")
	TEST_ASSERT(!SSsounds.using_channels["[channel]"], "Канал голоса не освободился")

/// Ступени учебного Болеро не трогают станционное небо.
/datum/unit_test/heretic_sky_simulated_bolero/Run()
	var/datum/space_level/level = SSmapping.z_list[run_loc_floor_bottom_left.z]
	level.traits[ZTRAIT_ANTAG_TRAINING] = TRUE
	var/datum/eldritch_knowledge/final_eldritch/dance_final/final = allocate(/datum/eldritch_knowledge/final_eldritch/dance_final)
	final.finished = TRUE
	final.simulated = TRUE
	GLOB.heretic_sky.ascend(final, run_loc_floor_bottom_left)
	final.show_bolero_scene(HERETIC_DANCE_BOLERO_STAGES + 1)
	var/tier = GLOB.heretic_sky.voice_of(final)?.tier
	var/list/station_hits = list()
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		var/list/stack = SSparallax.modifiers_by_z["[station_z]"]
		for(var/datum/parallax_modifier/modifier as anything in stack?.Copy())
			if(!findtext(modifier.token, "heretic"))
				continue
			station_hits |= station_z
			SSparallax.remove_modifier(station_z, modifier.token)
	heretic_sky_test_clear()
	level.traits -= ZTRAIT_ANTAG_TRAINING
	TEST_ASSERT(!length(station_hits), "Учебное Болеро тронуло станционное небо: z [station_hits.Join(", ")]")
	TEST_ASSERT_EQUAL(tier, 3, "Финал Болеро не поднял ярус неба")

/// Громкость неба - отдельная настройка игрока, по умолчанию 100.
/datum/unit_test/heretic_sky_pref/Run()
	var/datum/preferences/prefs = new
	var/initial_volume = prefs.get_sound_volume("heretic_sky")
	prefs.vars["sound_volume_heretic_sky"] = 40
	var/set_volume = prefs.get_sound_volume("heretic_sky")
	qdel(prefs)
	TEST_ASSERT_EQUAL(initial_volume, 100, "Настройка громкости неба не на 100 по умолчанию")
	TEST_ASSERT_EQUAL(set_volume, 40, "Громкость неба не читается из настройки")

/// Снятая роль уводит голос по таймеру спада, после полного цикла стадий.
/datum/unit_test/heretic_sky_retire_timer/Run()
	var/turf/station_turf = heretic_sky_test_station_turf()
	var/datum/eldritch_knowledge/final_eldritch/blade_final/final = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	GLOB.heretic_sky.begin(final, station_turf, 10 SECONDS)
	var/datum/heretic_sky_voice/voice = GLOB.heretic_sky.ascend(final, station_turf)
	GLOB.heretic_sky.event(final)
	GLOB.heretic_sky.fall(final)
	GLOB.heretic_sky.rise(final)
	GLOB.heretic_sky.end(final)
	var/stage = voice.stage
	var/left = timeleft(voice.retire_timer)
	var/count = length(GLOB.heretic_sky.voices)
	heretic_sky_test_clear()
	TEST_ASSERT_EQUAL(stage, HERETIC_SKY_ENDING, "Снятая роль не перевела голос в спад")
	TEST_ASSERT(left > 0, "Таймер снятия голоса не заведён ([left])")
	TEST_ASSERT_EQUAL(count, 1, "Голосов [count] вместо одного")

/// У каждого пути небо собрано целиком: Знак, туманность, частицы, луп и реакция; общие акценты на месте.
/datum/unit_test/heretic_sky_style_catalog/Run()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		TEST_ASSERT(path.sky_tint, "Путь [path_id] без тонировки неба")
		TEST_ASSERT(ispath(path.sky_particles, /particles/heretic_sky), "Путь [path_id] без частиц неба")
		TEST_ASSERT(path.sky_icon, "Путь [path_id] без листа неба")
		var/list/states = icon_states(path.sky_icon)
		TEST_ASSERT("presence" in states, "В листе неба пути [path_id] нет Знака")
		TEST_ASSERT(path.sky_texture_count() >= 2, "Путь [path_id] без двух ярусов туманности")
		for(var/state in path.sky_texture_states)
			TEST_ASSERT(state in states, "В листе неба пути [path_id] нет фактуры [state]")
		TEST_ASSERT(isfile(path.sky_loop), "Путь [path_id] без лупа неба")
		TEST_ASSERT(isfile(path.sky_event_sound), "Путь [path_id] без звука реакции неба")
	for(var/list/veil as anything in GLOB.heretic_sky_veils)
		TEST_ASSERT(veil[2] in icon_states(veil[1]), "Нет облаков туманности [veil[2]]")
	var/datum/heretic_sky/sky = GLOB.heretic_sky
	TEST_ASSERT(isfile(sky.omen_sound) && isfile(sky.fall_sound) && isfile(sky.rise_sound) && isfile(sky.release_sound), "Нет общих акцентов неба")

/// Первый Знак затмевает станционную планету: стоит перед центром диска, силуэт гасит её, корона горит за краем,
/// туманность и материал пути - за планетой.
/datum/unit_test/heretic_sky_eclipses_planet/Run()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	// Погода (ледяной шторм FestiveStation) ставит планетарный профиль без планеты.
	var/list/weather_modifiers = SSparallax.modifiers_by_z["[station_z]"]
	SSparallax.modifiers_by_z -= "[station_z]"
	var/datum/eldritch_knowledge/final_eldritch/moon_final/final = allocate(/datum/eldritch_knowledge/final_eldritch/moon_final)
	GLOB.heretic_sky.ascend(final, heretic_sky_test_station_turf())
	var/datum/parallax/template = SSparallax.get_parallax_template(station_z)
	var/atom/movable/screen/parallax_layer/anchor = heretic_sky_find_anchor(template)
	var/list/by_role = list()
	for(var/atom/movable/screen/parallax_layer/heretic_sky/layer in template.objects)
		by_role[layer.sky_role] = layer
	var/atom/movable/screen/parallax_layer/heretic_sky/presence = by_role[HERETIC_SKY_ROLE_PRESENCE]
	var/atom/movable/screen/parallax_layer/heretic_sky/glow = by_role[HERETIC_SKY_ROLE_GLOW]
	var/atom/movable/screen/parallax_layer/heretic_sky/corona = by_role[HERETIC_SKY_ROLE_CORONA]
	var/atom/movable/screen/parallax_layer/heretic_sky/eclipse = by_role[HERETIC_SKY_ROLE_ECLIPSE]
	var/atom/movable/screen/parallax_layer/heretic_sky/veil = by_role[HERETIC_SKY_ROLE_TEXTURE]
	var/atom/movable/screen/parallax_layer/heretic_sky/field = by_role[HERETIC_SKY_ROLE_FIELD]
	var/distance = -1
	var/corona_reach = FALSE
	if(anchor && presence)
		var/list/disc = GLOB.heretic_sky_anchors[anchor.type]
		corona_reach = corona && corona.base_scale * corona.tile_size / 2 > disc[1] * anchor.base_scale
		var/mid_x = world.maxx / 2
		var/mid_y = world.maxy / 2
		var/disc_x = -(anchor.center_x + anchor.speed * mid_x) + anchor.pixel_x + (disc[2] - anchor.tile_size / 2) * anchor.base_scale
		var/disc_y = -(anchor.center_y + anchor.speed * mid_y) + anchor.pixel_y + (disc[3] - anchor.tile_size / 2) * anchor.base_scale
		var/sign_x = -(presence.center_x + presence.speed * mid_x) + presence.pixel_x
		var/sign_y = -(presence.center_y + presence.speed * mid_y) + presence.pixel_y
		distance = sqrt((sign_x - disc_x) ** 2 + (sign_y - disc_y) ** 2)
	var/sign_front = presence && anchor && presence.layer > anchor.layer && presence.speed > anchor.speed
	var/halo_between = glow && anchor && presence && glow.layer > anchor.layer && glow.layer < presence.layer
	var/shadow_on_disc = eclipse && anchor && eclipse.layer > anchor.layer && eclipse.layer < glow?.layer && eclipse.alpha > 0 		&& eclipse.icon_state == anchor.icon_state && eclipse.base_scale == anchor.base_scale && eclipse.speed == anchor.speed 		&& eclipse.center_x == anchor.center_x && eclipse.center_y == anchor.center_y && eclipse.pixel_x == anchor.pixel_x && eclipse.pixel_y == anchor.pixel_y
	var/corona_behind = corona && anchor && corona.layer < anchor.layer && corona.alpha > 0 && corona_reach
	var/veil_behind = veil && anchor && veil.layer < anchor.layer && islist(veil.color) && veil.alpha > 0
	var/field_behind = field && anchor && field.layer < anchor.layer && field.particles
	heretic_sky_test_clear()
	if(length(weather_modifiers))
		SSparallax.modifiers_by_z["[station_z]"] = weather_modifiers
		SSparallax.invalidate_z(station_z)
	TEST_ASSERT_NOTNULL(anchor, "В станционной сцене не нашлась планета")
	TEST_ASSERT(distance >= 0 && distance < 1, "Первый Знак не в центре диска планеты: [distance] px")
	TEST_ASSERT(sign_front, "Знак не перед планетой")
	TEST_ASSERT(halo_between, "Ореол Знака не между планетой и Знаком")
	TEST_ASSERT(shadow_on_disc, "Тень затмения не легла силуэтом на планету")
	TEST_ASSERT(corona_behind, "Корона затмения не охватывает диск из-за планеты")
	TEST_ASSERT(veil_behind, "Туманность пути не за планетой или не окрашена")
	TEST_ASSERT(field_behind, "Материал пути не заполняет небо за планетой")

/// Без планеты (полигон) затмевать нечего: тень и корона гаснут, Знак встаёт в свой угол экрана.
/datum/unit_test/heretic_sky_no_planet_no_eclipse/Run()
	var/datum/eldritch_knowledge/final_eldritch/blade_final/final = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	var/datum/heretic_sky_voice/voice = GLOB.heretic_sky.ascend(final, heretic_sky_test_station_turf())
	var/atom/movable/screen/parallax_layer/heretic_sky/eclipse/eclipse = allocate(/atom/movable/screen/parallax_layer/heretic_sky/eclipse)
	var/atom/movable/screen/parallax_layer/heretic_sky/glow/corona/corona = allocate(/atom/movable/screen/parallax_layer/heretic_sky/glow/corona/slot1)
	var/atom/movable/screen/parallax_layer/heretic_sky/presence/presence = allocate(/atom/movable/screen/parallax_layer/heretic_sky/presence/slot1)
	eclipse.apply_group(null)
	corona.apply_voice(voice, null)
	presence.apply_voice(voice, null)
	var/eclipse_alpha = eclipse.target_alpha(GLOB.heretic_sky, voice.group)
	var/corona_alpha = corona.target_alpha(GLOB.heretic_sky, voice.group)
	var/presence_alpha = presence.target_alpha(GLOB.heretic_sky, voice.group)
	var/list/offset = GLOB.heretic_sky_slot_offsets[1]
	var/sign_x = -(presence.center_x + presence.speed * world.maxx / 2)
	var/sign_y = -(presence.center_y + presence.speed * world.maxy / 2)
	heretic_sky_test_clear()
	TEST_ASSERT_EQUAL(eclipse_alpha, 0, "Тень затмения видна без планеты")
	TEST_ASSERT_EQUAL(corona_alpha, 0, "Корона видна без планеты")
	TEST_ASSERT(presence_alpha > 0, "Знак не виден без планеты")
	TEST_ASSERT(abs(sign_x - offset[1]) < 1 && abs(sign_y - offset[2]) < 1, "Знак без планеты не в своём углу: [sign_x], [sign_y]")
