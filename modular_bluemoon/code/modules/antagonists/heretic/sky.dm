#define HERETIC_SKY_ABORT_TIME (6 SECONDS)
#define HERETIC_SKY_CLIMAX_TIME (4 SECONDS)
#define HERETIC_SKY_FALL_TIME (5 SECONDS)
#define HERETIC_SKY_RISE_TIME (4 SECONDS)
#define HERETIC_SKY_END_TIME (8 SECONDS)
#define HERETIC_SKY_TIER_TIME (4 SECONDS)
#define HERETIC_SKY_FRESH_FADE (6 SECONDS)
#define HERETIC_SKY_EVENT_COOLDOWN (20 SECONDS)
#define HERETIC_SKY_TEXTURE_BUDGET 2
#define HERETIC_SKY_MAX_LOOPS 3
#define HERETIC_SKY_ACCENT_VOLUME 45
#define HERETIC_SKY_CLIMAX_FLASH 35
#define HERETIC_SKY_EVENT_FLASH 25

GLOBAL_DATUM_INIT(heretic_sky, /datum/heretic_sky, new)

/// Множитель alpha роли слоя на стадии голоса. Роли без записи на стадии не видны.
GLOBAL_LIST_INIT(heretic_sky_stage_alpha, list(
	HERETIC_SKY_OMEN = list(
		HERETIC_SKY_ROLE_DIM = 0.5,
		HERETIC_SKY_ROLE_TINT = 0.5,
		HERETIC_SKY_ROLE_TEXTURE = 0.4,
		HERETIC_SKY_ROLE_TEXTURE_NEAR = 0.4,
		HERETIC_SKY_ROLE_GLOW = 0.45,
		HERETIC_SKY_ROLE_CORONA = 0.4,
		HERETIC_SKY_ROLE_ECLIPSE = 0.35,
		HERETIC_SKY_ROLE_PRESENCE = 0.25,
		HERETIC_SKY_ROLE_PARTICLES = 0.3,
		HERETIC_SKY_ROLE_FIELD = 0.3,
	),
	HERETIC_SKY_ASCENDED = list(
		HERETIC_SKY_ROLE_DIM = 1,
		HERETIC_SKY_ROLE_TINT = 1,
		HERETIC_SKY_ROLE_TEXTURE = 1,
		HERETIC_SKY_ROLE_TEXTURE_NEAR = 1,
		HERETIC_SKY_ROLE_GLOW = 1,
		HERETIC_SKY_ROLE_CORONA = 1,
		HERETIC_SKY_ROLE_ECLIPSE = 1,
		HERETIC_SKY_ROLE_PRESENCE = 1,
		HERETIC_SKY_ROLE_PARTICLES = 1,
		HERETIC_SKY_ROLE_FIELD = 1,
	),
	HERETIC_SKY_FALLEN = list(
		HERETIC_SKY_ROLE_DIM = 0.5,
		HERETIC_SKY_ROLE_TINT = 0.4,
		HERETIC_SKY_ROLE_TEXTURE = 0.5,
		HERETIC_SKY_ROLE_TEXTURE_NEAR = 0.5,
		HERETIC_SKY_ROLE_GLOW = 0.25,
		HERETIC_SKY_ROLE_CORONA = 0.25,
		HERETIC_SKY_ROLE_ECLIPSE = 0.3,
		HERETIC_SKY_ROLE_PRESENCE = 0.35,
		HERETIC_SKY_ROLE_PARTICLES = 0.3,
		HERETIC_SKY_ROLE_FIELD = 0.3,
	),
	HERETIC_SKY_ENDING = list(),
))

GLOBAL_LIST_INIT(heretic_sky_stage_volume, list(
	HERETIC_SKY_OMEN = 0.35,
	HERETIC_SKY_ASCENDED = 1,
	HERETIC_SKY_FALLEN = 0.3,
	HERETIC_SKY_ENDING = 0,
))

/// Приглушение ролей, когда в группе несколько Знаков: зарево каждого остаётся своим, общая заливка - нет.
GLOBAL_LIST_INIT(heretic_sky_crowd_alpha, list(
	HERETIC_SKY_ROLE_TINT = 0.6,
	HERETIC_SKY_ROLE_PARTICLES = 0.7,
	HERETIC_SKY_ROLE_FIELD = 0.6,
))

/// Громкость лупа при одном, двух и трёх звучащих голосах.
GLOBAL_LIST_INIT(heretic_sky_loop_mix, list(1, 0.8, 0.7))

/// Центры Знаков в пикселях от центра экрана, если в сцене нет планеты, из-за которой им восходить.
GLOBAL_LIST_INIT(heretic_sky_slot_offsets, list(
	list(130, 100),
	list(-150, 95),
	list(140, -115),
	list(-140, -125),
))

/// Места Знаков слотов на диске планеты: угол против часовой от востока и расстояние от центра в долях радиуса.
/// Планета занимает почти весь кадр, поэтому первый Знак закрывает её собой, остальные встают на левый и нижний
/// край - он в кадре почти из любой точки станции.
GLOBAL_LIST_INIT(heretic_sky_sign_spots, list(
	list(0, 0),
	list(200, 0.95),
	list(145, 0.95),
	list(250, 0.95),
))

/// Облака изнанки из погоды параллакса - дальний и ближний ярус туманности пути - и сила маски "яркость -> прозрачность".
GLOBAL_LIST_INIT(heretic_sky_veils, list(
	list('icons/effects/parallax/goon/weather/void_clouds_1.dmi', "void_clouds_1", 1.6),
	list('icons/effects/parallax/goon/weather/void_clouds_2.dmi', "void_clouds_2", 1.5),
))

/// Слои-планеты, которые затмевают Знаки: радиус диска и его центр в пикселях картинки слоя.
GLOBAL_LIST_INIT(heretic_sky_anchors, list(
	/atom/movable/screen/parallax_layer/space/planet = list(98, 240, 240),
))

/// Группа неба по месту обряда: станция целиком, отдельный полигон или ничего.
/proc/heretic_sky_group_for(turf/place)
	if(!place)
		return null
	if(is_station_level(place.z))
		return HERETIC_SKY_GROUP_STATION
	if(SSmapping.level_trait(place.z, ZTRAIT_ANTAG_TRAINING))
		return "z[place.z]"
	return null

/proc/heretic_sky_group_levels(group)
	if(group == HERETIC_SKY_GROUP_STATION)
		return SSmapping.levels_by_trait(ZTRAIT_STATION)
	var/level = text2num(copytext(group, 2))
	return level ? list(level) : list()

/proc/heretic_sky_hears(client/listener, list/levels)
	var/mob/viewer = listener?.mob
	if(!viewer || isnewplayer(viewer))
		return FALSE
	var/turf/place = get_turf(viewer)
	return place && (place.z in levels)

/// Реакция неба на удар вознёсшегося, если у него есть это финальное знание.
/proc/heretic_sky_event_for(mob/user, final_type)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return GLOB.heretic_sky.event(heretic?.get_knowledge(final_type))

/proc/heretic_sky_pref(client/listener)
	var/volume = listener?.prefs?.get_sound_volume("heretic_sky")
	return isnull(volume) ? 1 : volume / 100

/**
 * Небо вознесений: голоса всех вознёсшихся и сцена каждой группы уровней.
 *
 * На группу кладётся один модификатор параллакса со слотовыми слоями; при каждой сборке
 * шаблона z координатор красит и расставляет их по голосам. Стадии и реакции анимируют
 * живые слои, поэтому смена стадии не пересобирает сцену и не роняет чужие анимации.
 */
/datum/heretic_sky
	var/list/datum/heretic_sky_voice/voices = list()
	/// Финальное знание -> голос. Ключ снимается в retire(), чтобы не держать удаляемое знание.
	var/list/voices_by_source = list()
	var/omen_sound
	var/fall_sound
	var/rise_sound
	var/release_sound

/datum/heretic_sky/proc/voice_of(datum/eldritch_knowledge/final_eldritch/final)
	RETURN_TYPE(/datum/heretic_sky_voice)
	if(!final)
		return null
	return voices_by_source[final]

/datum/heretic_sky/proc/begin(datum/eldritch_knowledge/final_eldritch/final, turf/ritual_turf, duration = 0)
	RETURN_TYPE(/datum/heretic_sky_voice)
	var/datum/heretic_sky_voice/voice = voice_of(final)
	if(voice)
		return voice
	var/group = heretic_sky_group_for(ritual_turf)
	if(!group || !final || !GLOB.heretic_paths[final.route])
		return null
	voice = new(final, group)
	voice.set_stage(HERETIC_SKY_OMEN, duration)
	voice.fade_until = world.time + max(duration, HERETIC_SKY_FRESH_FADE)
	voice.slot = free_slot(group)
	voices += voice
	voices_by_source[final] = voice
	compose(group)
	voice.play_accent(omen_sound)
	START_PROCESSING(SSprocessing, src)
	return voice

/datum/heretic_sky/proc/abort(datum/eldritch_knowledge/final_eldritch/final)
	var/datum/heretic_sky_voice/voice = voice_of(final)
	if(voice?.stage == HERETIC_SKY_OMEN)
		retire(voice, HERETIC_SKY_ABORT_TIME)

/datum/heretic_sky/proc/ascend(datum/eldritch_knowledge/final_eldritch/final, turf/place)
	RETURN_TYPE(/datum/heretic_sky_voice)
	var/datum/heretic_sky_voice/voice = voice_of(final) || begin(final, place)
	if(!voice)
		return null
	voice.set_stage(HERETIC_SKY_ASCENDED, HERETIC_SKY_CLIMAX_TIME)
	sync_group(voice.group, HERETIC_SKY_CLIMAX_TIME)
	flash(voice, HERETIC_SKY_CLIMAX_FLASH)
	return voice

/datum/heretic_sky/proc/fall(datum/eldritch_knowledge/final_eldritch/final)
	var/datum/heretic_sky_voice/voice = voice_of(final)
	if(voice?.stage != HERETIC_SKY_ASCENDED)
		return
	voice.set_stage(HERETIC_SKY_FALLEN, HERETIC_SKY_FALL_TIME)
	sync_group(voice.group, HERETIC_SKY_FALL_TIME)
	voice.play_accent(fall_sound)

/datum/heretic_sky/proc/rise(datum/eldritch_knowledge/final_eldritch/final)
	var/datum/heretic_sky_voice/voice = voice_of(final)
	if(voice?.stage != HERETIC_SKY_FALLEN)
		return
	voice.set_stage(HERETIC_SKY_ASCENDED, HERETIC_SKY_RISE_TIME)
	sync_group(voice.group, HERETIC_SKY_RISE_TIME)
	voice.play_accent(rise_sound)

/datum/heretic_sky/proc/end(datum/eldritch_knowledge/final_eldritch/final)
	var/datum/heretic_sky_voice/voice = voice_of(final)
	if(!voice)
		return
	if(voice.stage != HERETIC_SKY_OMEN)
		voice.play_accent(release_sound)
	retire(voice, HERETIC_SKY_END_TIME)

/datum/heretic_sky/proc/tier(datum/eldritch_knowledge/final_eldritch/final, new_tier)
	var/datum/heretic_sky_voice/voice = voice_of(final)
	if(!voice || voice.tier == new_tier)
		return
	voice.tier = new_tier
	sync_group(voice.group, HERETIC_SKY_TIER_TIME)

/// Небо откликается на главный удар вознёсшегося. TRUE, если отклик прошёл.
/datum/heretic_sky/proc/event(datum/eldritch_knowledge/final_eldritch/final)
	var/datum/heretic_sky_voice/voice = voice_of(final)
	if(voice?.stage != HERETIC_SKY_ASCENDED || world.time < voice.next_event_at)
		return FALSE
	voice.next_event_at = world.time + HERETIC_SKY_EVENT_COOLDOWN
	flash(voice, HERETIC_SKY_EVENT_FLASH)
	voice.play_accent(voice.path().sky_event_sound)
	return TRUE

/datum/heretic_sky/proc/retire(datum/heretic_sky_voice/voice, time)
	for(var/source in voices_by_source.Copy())
		if(voices_by_source[source] == voice)
			voices_by_source -= source
	voice.set_stage(HERETIC_SKY_ENDING, time)
	sync_group(voice.group, time)
	deltimer(voice.retire_timer)
	voice.retire_timer = addtimer(CALLBACK(src, PROC_REF(remove_voice), voice), time, TIMER_STOPPABLE)

/datum/heretic_sky/proc/remove_voice(datum/heretic_sky_voice/voice)
	if(!(voice in voices))
		return
	voices -= voice
	for(var/source in voices_by_source.Copy())
		if(voices_by_source[source] == voice)
			voices_by_source -= source
	var/group = voice.group
	qdel(voice)
	compose(group)
	if(!length(voices))
		STOP_PROCESSING(SSprocessing, src)

/datum/heretic_sky/proc/free_slot(group)
	var/list/taken = list()
	for(var/datum/heretic_sky_voice/voice as anything in voices)
		if(voice.group == group && voice.slot)
			taken += voice.slot
	for(var/slot in 1 to HERETIC_SKY_MAX_SLOTS)
		if(!(slot in taken))
			return slot
	return 0

/datum/heretic_sky/proc/slot_voice(group, slot)
	RETURN_TYPE(/datum/heretic_sky_voice)
	if(!slot)
		return null
	for(var/datum/heretic_sky_voice/voice as anything in voices)
		if(voice.group == group && voice.slot == slot)
			return voice
	return null

/datum/heretic_sky/proc/crowded(group)
	var/visible = 0
	for(var/datum/heretic_sky_voice/voice as anything in voices)
		if(voice.group == group && voice.slot)
			visible++
	return visible > 1

/datum/heretic_sky/proc/group_role_alpha(group, role)
	. = 0
	for(var/datum/heretic_sky_voice/voice as anything in voices)
		if(voice.group == group && voice.slot)
			. = max(., voice.role_alpha(role))

/datum/heretic_sky/proc/group_fade(group)
	. = 0
	for(var/datum/heretic_sky_voice/voice as anything in voices)
		if(voice.group == group)
			. = max(., voice.remaining_fade())

/// Кладёт сцену группы заново: набор голосов изменился.
/datum/heretic_sky/proc/compose(group)
	var/list/scene = scene_layers(group)
	for(var/z in heretic_sky_group_levels(group))
		if(!length(scene))
			SSparallax.remove_modifier(z, HERETIC_SKY_TOKEN)
			continue
		SSparallax.add_layers(z, HERETIC_SKY_TOKEN, scene, PARALLAX_PRIORITY_ANTAG, 0, CALLBACK(src, PROC_REF(style_template), group))

/// Слои сцены группы: свежие голоса первыми, чтобы бюджет туманности достался им.
/datum/heretic_sky/proc/scene_layers(group)
	. = list()
	var/static/list/texture_types = list(/atom/movable/screen/parallax_layer/heretic_sky/texture, /atom/movable/screen/parallax_layer/heretic_sky/texture/near)
	var/budget = HERETIC_SKY_TEXTURE_BUDGET
	var/dimmed = FALSE
	for(var/index in length(voices) to 1 step -1)
		var/datum/heretic_sky_voice/voice = voices[index]
		if(voice.group != group || !voice.slot)
			continue
		var/datum/heretic_path/path = voice.path()
		. += heretic_sky_slot_type(/atom/movable/screen/parallax_layer/heretic_sky/tint, voice.slot)
		. += heretic_sky_slot_type(/atom/movable/screen/parallax_layer/heretic_sky/glow, voice.slot)
		. += heretic_sky_slot_type(/atom/movable/screen/parallax_layer/heretic_sky/glow/corona, voice.slot)
		. += heretic_sky_slot_type(/atom/movable/screen/parallax_layer/heretic_sky/particles, voice.slot)
		. += heretic_sky_slot_type(/atom/movable/screen/parallax_layer/heretic_sky/field, voice.slot)
		if(path.sky_icon)
			. += heretic_sky_slot_type(/atom/movable/screen/parallax_layer/heretic_sky/presence, voice.slot)
		for(var/texture_index in 1 to min(path.sky_texture_count(), length(texture_types)))
			if(budget <= 0)
				break
			. += heretic_sky_slot_type(texture_types[texture_index], voice.slot)
			budget--
		if(path.sky_dim)
			dimmed = TRUE
	if(!length(.))
		return
	if(dimmed)
		. += /atom/movable/screen/parallax_layer/heretic_sky/dim
	. += /atom/movable/screen/parallax_layer/heretic_sky/eclipse
	. += /atom/movable/screen/parallax_layer/heretic_sky/flash

/proc/heretic_sky_slot_type(base_type, slot)
	return text2path("[base_type]/slot[slot]")

/// Планета сцены, которую затмевают Знаки, или null.
/proc/heretic_sky_find_anchor(datum/parallax/template)
	for(var/atom/movable/screen/parallax_layer/layer as anything in template?.objects)
		if(GLOB.heretic_sky_anchors[layer.type])
			return layer
	return null

/// Callback сборки шаблона: каждый слой неба получает свой голос, стадию и остаток проявления.
/datum/heretic_sky/proc/style_template(group, datum/parallax/template)
	var/atom/movable/screen/parallax_layer/anchor = heretic_sky_find_anchor(template)
	for(var/atom/movable/screen/parallax_layer/heretic_sky/layer in template.objects)
		var/datum/heretic_sky_voice/voice = slot_voice(group, layer.sky_slot)
		if(voice)
			layer.apply_voice(voice, anchor)
		else
			layer.apply_group(anchor)
		layer.sync_alpha(src, group, 0)
		layer.fade_in_time = voice ? voice.remaining_fade() : group_fade(group)

/// Доводит alpha слоёв группы до стадий голосов: шаблон сразу, живые слои анимацией.
/datum/heretic_sky/proc/sync_group(group, time)
	for(var/z in heretic_sky_group_levels(group))
		var/datum/parallax/template = SSparallax.parallax_templates_by_z["[z]"]
		for(var/atom/movable/screen/parallax_layer/heretic_sky/layer in template?.objects)
			layer.sync_alpha(src, group, 0)
		for(var/atom/movable/screen/parallax_layer/heretic_sky/layer in SSparallax.live_layers_on_z(z))
			layer.sync_alpha(src, group, time)

/datum/heretic_sky/proc/flash(datum/heretic_sky_voice/voice, peak)
	var/flash_color = voice.glow_color()
	for(var/z in heretic_sky_group_levels(voice.group))
		for(var/atom/movable/screen/parallax_layer/heretic_sky/layer in SSparallax.live_layers_on_z(z))
			if(layer.sky_role == HERETIC_SKY_ROLE_FLASH || (voice.slot && layer.sky_slot == voice.slot))
				layer.flash(flash_color, peak)
		var/datum/parallax/template = SSparallax.parallax_templates_by_z["[z]"]
		for(var/atom/movable/screen/parallax_layer/heretic_sky/particles/emitter in template?.objects)
			if(voice.slot && emitter.sky_slot == voice.slot)
				emitter.burst()

/datum/heretic_sky/process(delta_time)
	var/list/groups = list()
	for(var/datum/heretic_sky_voice/voice as anything in voices)
		groups |= voice.group
	for(var/group in groups)
		var/list/audible = audible_voices(group)
		var/mix = length(audible) ? GLOB.heretic_sky_loop_mix[length(audible)] : 0
		for(var/datum/heretic_sky_voice/voice as anything in voices)
			if(voice.group == group)
				voice.update_sound((voice in audible) ? mix : 0)

/// Три самых свежих голоса группы звучат, остальные молчат.
/datum/heretic_sky/proc/audible_voices(group)
	. = list()
	for(var/index in length(voices) to 1 step -1)
		var/datum/heretic_sky_voice/voice = voices[index]
		if(voice.group != group)
			continue
		. += voice
		if(length(.) >= HERETIC_SKY_MAX_LOOPS)
			return

/// Одно вознесение в небе: стадия, слот Знака и звук.
/datum/heretic_sky_voice
	var/datum/weakref/source
	var/path_id
	var/group
	var/stage = HERETIC_SKY_OMEN
	/// Ярус стиля: у Пляски - ступень Болеро, у остальных всегда 0.
	var/tier = 0
	/// 0 - Знаков в группе уже четыре, голос только звучит.
	var/slot = 0
	var/fade_until = 0
	/// За сколько громкость лупа доходит до цели текущей стадии.
	var/ramp_time = 1 SECONDS
	var/next_event_at = 0
	var/channel
	/// client -> громкость лупа, которую он сейчас слышит.
	var/list/listeners = list()
	var/retire_timer

/datum/heretic_sky_voice/New(datum/eldritch_knowledge/final_eldritch/final, group)
	source = WEAKREF(final)
	path_id = final.route
	src.group = group
	channel = SSsounds.reserve_sound_channel(src)

/datum/heretic_sky_voice/Destroy()
	deltimer(retire_timer)
	silence()
	SSsounds.free_datum_channels(src)
	return ..()

/datum/heretic_sky_voice/proc/path()
	RETURN_TYPE(/datum/heretic_path)
	return GLOB.heretic_paths[path_id]

/datum/heretic_sky_voice/proc/set_stage(new_stage, time)
	stage = new_stage
	ramp_time = max(1 SECONDS, time)

/datum/heretic_sky_voice/proc/remaining_fade()
	return max(0, fade_until - world.time)

/datum/heretic_sky_voice/proc/glow_color()
	var/datum/heretic_path/path = path()
	return path.sky_glow || path.book_ink

/datum/heretic_sky_voice/proc/role_alpha(role)
	var/datum/heretic_path/path = path()
	var/list/stage_alpha = GLOB.heretic_sky_stage_alpha[stage]
	var/alpha = path.sky_base_alpha(role) * stage_alpha[role] * path.sky_tier_alpha(role, tier)
	if(GLOB.heretic_sky.crowded(group))
		alpha *= GLOB.heretic_sky_crowd_alpha[role] || 1
	return clamp(round(alpha), 0, 255)

/datum/heretic_sky_voice/proc/loop_target(mix)
	return round(path().sky_loop_volume * mix * GLOB.heretic_sky_stage_volume[stage])

/// Ведёт луп у слушателей группы к громкости стадии; новым - запуск с нуля, ушедшим - стоп.
/datum/heretic_sky_voice/proc/update_sound(mix)
	var/datum/heretic_path/path = path()
	if(!path.sky_loop)
		return
	var/list/levels = heretic_sky_group_levels(group)
	for(var/client/listener as anything in listeners.Copy())
		if(!heretic_sky_hears(listener, levels))
			stop_for(listener)
	var/full = loop_target(mix)
	var/step = max(1, path.sky_loop_volume / max(1, ramp_time / (1 SECONDS)))
	for(var/client/listener as anything in GLOB.clients)
		if(!heretic_sky_hears(listener, levels))
			continue
		var/target = round(full * heretic_sky_pref(listener))
		var/current = listeners[listener]
		if(isnull(current))
			if(!target)
				continue
			start_for(listener, path.sky_loop)
			current = 0
		if(current == target)
			if(!target)
				stop_for(listener)
			continue
		var/next = current < target ? min(target, current + step) : max(target, current - step)
		listeners[listener] = next
		listener.mob.set_sound_channel_volume(channel, next)

/datum/heretic_sky_voice/proc/start_for(client/listener, loop_file)
	var/sound/loop = sound(loop_file, repeat = TRUE, wait = FALSE, volume = 0, channel = channel)
	loop.status = SOUND_STREAM
	SEND_SOUND(listener, loop)
	listeners[listener] = 0

/datum/heretic_sky_voice/proc/stop_for(client/listener)
	listeners -= listener
	listener?.mob?.stop_sound_channel(channel)

/datum/heretic_sky_voice/proc/silence()
	for(var/client/listener as anything in listeners.Copy())
		stop_for(listener)

/// Разовый звук неба всем, кто в группе, с учётом громкости неба у каждого.
/datum/heretic_sky_voice/proc/play_accent(sound_file, volume = HERETIC_SKY_ACCENT_VOLUME)
	if(!sound_file)
		return
	var/list/levels = heretic_sky_group_levels(group)
	var/sound/accent = sound(sound_file)
	for(var/client/listener as anything in GLOB.clients)
		if(!heretic_sky_hears(listener, levels))
			continue
		accent.volume = round(volume * heretic_sky_pref(listener))
		if(accent.volume > 0)
			SEND_SOUND(listener, accent)

#undef HERETIC_SKY_ABORT_TIME
#undef HERETIC_SKY_CLIMAX_TIME
#undef HERETIC_SKY_FALL_TIME
#undef HERETIC_SKY_RISE_TIME
#undef HERETIC_SKY_END_TIME
#undef HERETIC_SKY_TIER_TIME
#undef HERETIC_SKY_FRESH_FADE
#undef HERETIC_SKY_EVENT_COOLDOWN
#undef HERETIC_SKY_TEXTURE_BUDGET
#undef HERETIC_SKY_MAX_LOOPS
#undef HERETIC_SKY_ACCENT_VOLUME
#undef HERETIC_SKY_CLIMAX_FLASH
#undef HERETIC_SKY_EVENT_FLASH
