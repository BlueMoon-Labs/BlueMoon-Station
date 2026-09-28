#define DANCE_TAKT_ANY 1
#define DANCE_TAKT_BEAT 2
#define DANCE_TAKT_PERFECT 3
#define DANCE_TAKT_HIT_GAP (1 SECONDS)
#define DANCE_FIGURE_COOLDOWN_BEATS 16
#define DANCE_MUSIC_VOLUME 40
#define DANCE_BEAT_VOLUME 25
#define DANCE_HUD_ALERT "heretic_dance_beat"

GLOBAL_LIST_INIT(heretic_dance_styles, init_heretic_dance_styles())

/proc/init_heretic_dance_styles()
	. = list()
	for(var/style_type in list(/datum/heretic_dance_style/waltz, /datum/heretic_dance_style/tango, /datum/heretic_dance_style/tarantella, /datum/heretic_dance_style/cancan, /datum/heretic_dance_style/macabre))
		var/datum/heretic_dance_style/style = new style_type
		.[style.id] = style

/datum/heretic_dance_style
	var/id
	var/name
	var/beat_ds = 8
	var/meter = 4
	var/color = "#c8553d"
	/// Знание, открывающее стиль; null - доступен сразу.
	var/unlock
	/// Шаги фигуры поворотами от направления первого шага; null - фигура не из шагов.
	var/list/figure
	var/figure_name
	var/passive_text
	var/accent_text
	var/figure_text
	/// Тактовые фразы стиля, каждая ровно в один такт.
	var/list/phrases
	var/list/accent_sounds
	var/list/perfect_sounds
	var/list/step_sounds
	var/switch_sound

/datum/heretic_dance_style/proc/phrase(index)
	return phrases[clamp(index, 1, length(phrases))]

/datum/heretic_dance_style/proc/passive_on(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	return

/datum/heretic_dance_style/proc/passive_off(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	return

/// power: 1 - акцент, 2 - взрыв метки или связка, 0.5 - барабан.
/datum/heretic_dance_style/proc/accent(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, power = 1)
	return

/datum/heretic_dance_style/proc/flourish(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	return FALSE

/datum/heretic_dance_style/proc/on_beat(datum/eldritch_knowledge/base_dance/dance, mob/living/user, strong)
	return

/datum/heretic_dance_style/proc/on_strike(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, accuracy, blade)
	return

/datum/heretic_dance_style/waltz
	phrases = list('modular_bluemoon/sound/heretic/dance/waltz_1.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_2.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_3.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_4.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_5.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_6.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_7.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_8.ogg')
	accent_sounds = list('modular_bluemoon/sound/heretic/dance/accent_waltz_1.ogg', 'modular_bluemoon/sound/heretic/dance/accent_waltz_2.ogg', 'modular_bluemoon/sound/heretic/dance/accent_waltz_3.ogg')
	perfect_sounds = list('modular_bluemoon/sound/heretic/dance/perfect_waltz_1.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_waltz_2.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_waltz_3.ogg')
	step_sounds = list('modular_bluemoon/sound/heretic/dance/step_waltz_1.ogg', 'modular_bluemoon/sound/heretic/dance/step_waltz_2.ogg', 'modular_bluemoon/sound/heretic/dance/step_waltz_3.ogg')
	switch_sound = 'modular_bluemoon/sound/heretic/dance/switch_waltz.ogg'
	id = HERETIC_DANCE_STYLE_WALTZ
	name = "Вальс"
	beat_ds = 8.5
	meter = 3
	color = "#e0b27a"
	figure = list(0, -90, 180, 90)
	figure_name = "квадрат"
	passive_text = "шаги скользят: вы быстрее"
	accent_text = "цель перелетает на другую сторону от вас и теряет ориентацию на секунду"
	figure_text = "шаг вперёд, вправо, назад, влево - 4 секунды ведёте соседнего врага: он повторяет каждый ваш шаг"

/datum/heretic_dance_style/waltz/passive_on(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	user.add_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_waltz)

/datum/heretic_dance_style/waltz/passive_off(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	user.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_waltz)

/datum/heretic_dance_style/waltz/accent(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, power = 1)
	victim.confused = max(victim.confused, power >= 1 ? 2 : 1)
	if(power < 1)
		victim.setDir(turn(victim.dir, 180))
		return
	heretic_dance_turn_partner(user, victim)

/datum/heretic_dance_style/waltz/flourish(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	return dance.start_lead(user)

/datum/heretic_dance_style/tango
	phrases = list('modular_bluemoon/sound/heretic/dance/tango_1.ogg', 'modular_bluemoon/sound/heretic/dance/tango_2.ogg', 'modular_bluemoon/sound/heretic/dance/tango_3.ogg', 'modular_bluemoon/sound/heretic/dance/tango_4.ogg', 'modular_bluemoon/sound/heretic/dance/tango_5.ogg', 'modular_bluemoon/sound/heretic/dance/tango_6.ogg', 'modular_bluemoon/sound/heretic/dance/tango_7.ogg', 'modular_bluemoon/sound/heretic/dance/tango_8.ogg')
	accent_sounds = list('modular_bluemoon/sound/heretic/dance/accent_tango_1.ogg', 'modular_bluemoon/sound/heretic/dance/accent_tango_2.ogg', 'modular_bluemoon/sound/heretic/dance/accent_tango_3.ogg')
	perfect_sounds = list('modular_bluemoon/sound/heretic/dance/perfect_tango_1.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_tango_2.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_tango_3.ogg')
	step_sounds = list('modular_bluemoon/sound/heretic/dance/step_tango_1.ogg', 'modular_bluemoon/sound/heretic/dance/step_tango_2.ogg', 'modular_bluemoon/sound/heretic/dance/step_tango_3.ogg')
	switch_sound = 'modular_bluemoon/sound/heretic/dance/switch_tango.ogg'
	id = HERETIC_DANCE_STYLE_TANGO
	name = "Танго"
	beat_ds = 7.5
	meter = 4
	color = "#d13b3b"
	figure = list(0, 180, 0)
	figure_name = "очо"
	passive_text = "удары в долю +6 ушибов, точные - полторы выносливости"
	accent_text = "кортэ: цель падает на 1,5 секунды, не чаще раза в 10 секунд"
	figure_text = "шаг в сторону, обратно, снова в сторону - следующий удар клинком выпадом с 2 клеток"

/datum/heretic_dance_style/tango/on_strike(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, accuracy, blade)
	if(!blade || accuracy == HERETIC_DANCE_MISS || !dance.passive_active)
		return
	victim.adjustBruteLoss(HERETIC_DANCE_TANGO_BONUS)
	if(accuracy == HERETIC_DANCE_PERFECT)
		victim.adjustStaminaLoss(HERETIC_DANCE_TANGO_BONUS * 2)

/datum/heretic_dance_style/tango/accent(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, power = 1)
	if(power < 1)
		victim.adjustStaminaLoss(15)
		victim.apply_status_effect(/datum/status_effect/heretic_dance_stumble)
		return
	if(victim.has_status_effect(/datum/status_effect/heretic_dance_dipped))
		victim.adjustStaminaLoss(15)
		return
	victim.apply_status_effect(/datum/status_effect/heretic_dance_dipped)
	victim.Knockdown(power >= 2 ? 2.5 SECONDS : 1.5 SECONDS)

/datum/heretic_dance_style/tango/flourish(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	dance.lunge_until = world.time + 3 SECONDS
	user.balloon_alert(user, "выпад готов")
	return TRUE

/datum/heretic_dance_style/tarantella
	phrases = list('modular_bluemoon/sound/heretic/dance/tarantella_1.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_2.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_3.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_4.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_5.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_6.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_7.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_8.ogg')
	accent_sounds = list('modular_bluemoon/sound/heretic/dance/accent_tarantella_1.ogg', 'modular_bluemoon/sound/heretic/dance/accent_tarantella_2.ogg', 'modular_bluemoon/sound/heretic/dance/accent_tarantella_3.ogg')
	perfect_sounds = list('modular_bluemoon/sound/heretic/dance/perfect_tarantella_1.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_tarantella_2.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_tarantella_3.ogg')
	step_sounds = list('modular_bluemoon/sound/heretic/dance/step_tarantella_1.ogg', 'modular_bluemoon/sound/heretic/dance/step_tarantella_2.ogg', 'modular_bluemoon/sound/heretic/dance/step_tarantella_3.ogg')
	switch_sound = 'modular_bluemoon/sound/heretic/dance/switch_tarantella.ogg'
	id = HERETIC_DANCE_STYLE_TARANTELLA
	name = "Тарантелла"
	beat_ds = 5
	meter = 6
	color = "#8f1d21"
	figure_name = "укус"
	passive_text = "каждое точное действие лечит 2"
	accent_text = "стаки тарантизма взрываются: 5 ушибов за стак"
	figure_text = "4 точных удара подряд по одной цели - она 4 секунды пляшет, не владея ногами"

/datum/heretic_dance_style/tarantella/on_strike(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, accuracy, blade)
	if(accuracy == HERETIC_DANCE_MISS)
		dance.bite_chain = 0
		return
	victim.apply_status_effect(/datum/status_effect/heretic_dance/tarantism, dance)
	if(accuracy == HERETIC_DANCE_PERFECT && dance.passive_active)
		heretic_heal_pool(user, 2)
	if(!blade)
		return
	if(accuracy != HERETIC_DANCE_PERFECT || dance.bite_target?.resolve() != victim)
		dance.bite_target = WEAKREF(victim)
		dance.bite_chain = accuracy == HERETIC_DANCE_PERFECT ? 1 : 0
		return
	if(++dance.bite_chain >= HERETIC_DANCE_BITE_HITS)
		dance.bite_chain = 0
		victim.apply_status_effect(/datum/status_effect/heretic_dance/frenzy, dance, 4 SECONDS)
		dance.flourish_fx(user, src)

/datum/heretic_dance_style/tarantella/accent(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, power = 1)
	var/datum/status_effect/heretic_dance/tarantism/bite = victim.has_status_effect(/datum/status_effect/heretic_dance/tarantism)
	if(power < 1)
		victim.apply_status_effect(/datum/status_effect/heretic_dance/tarantism, dance)
		return
	if(!bite)
		return
	victim.adjustBruteLoss(bite.stacks * 5 * power)
	qdel(bite)

/datum/heretic_dance_style/cancan
	phrases = list('modular_bluemoon/sound/heretic/dance/cancan_1.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_2.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_3.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_4.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_5.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_6.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_7.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_8.ogg')
	accent_sounds = list('modular_bluemoon/sound/heretic/dance/accent_cancan_1.ogg', 'modular_bluemoon/sound/heretic/dance/accent_cancan_2.ogg', 'modular_bluemoon/sound/heretic/dance/accent_cancan_3.ogg')
	perfect_sounds = list('modular_bluemoon/sound/heretic/dance/perfect_cancan_1.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_cancan_2.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_cancan_3.ogg')
	step_sounds = list('modular_bluemoon/sound/heretic/dance/step_cancan_1.ogg', 'modular_bluemoon/sound/heretic/dance/step_cancan_2.ogg', 'modular_bluemoon/sound/heretic/dance/step_cancan_3.ogg')
	switch_sound = 'modular_bluemoon/sound/heretic/dance/switch_cancan.ogg'
	id = HERETIC_DANCE_STYLE_CANCAN
	name = "Канкан"
	beat_ds = 6
	meter = 4
	color = "#f07a3a"
	figure = list(0, 0, 180, 180)
	figure_name = "линия"
	passive_text = "столы и лежачие не задерживают вас"
	accent_text = "мах ногой: отброс на 2 клетки и 20 выносливости"
	figure_text = "два шага вперёд, два назад - медные ленты слепят всех в 2 клетках, а вы рывком проходите 3 клетки сквозь толпу"

/datum/heretic_dance_style/cancan/passive_on(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	ADD_TRAIT(user, TRAIT_FREERUNNING, HERETIC_DANCE_STYLE_CANCAN)

/datum/heretic_dance_style/cancan/passive_off(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	REMOVE_TRAIT(user, TRAIT_FREERUNNING, HERETIC_DANCE_STYLE_CANCAN)

/datum/heretic_dance_style/cancan/accent(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, power = 1)
	var/distance = power >= 2 ? 3 : (power < 1 ? 1 : 2)
	victim.adjustStaminaLoss(power < 1 ? 10 : 20 * power)
	if(victim.anchored || victim.buckled || !isturf(victim.loc))
		return
	var/turf/target = get_ranged_target_turf(victim, get_dir(user, victim) || user.dir, distance)
	victim.throw_at(target, distance, 1, user, spin = FALSE)

/datum/heretic_dance_style/cancan/flourish(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	return dance.cancan_dash(user)

/datum/heretic_dance_style/macabre
	phrases = list('modular_bluemoon/sound/heretic/dance/macabre_1.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_2.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_3.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_4.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_5.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_6.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_7.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_8.ogg')
	accent_sounds = list('modular_bluemoon/sound/heretic/dance/accent_macabre_1.ogg', 'modular_bluemoon/sound/heretic/dance/accent_macabre_2.ogg', 'modular_bluemoon/sound/heretic/dance/accent_macabre_3.ogg')
	perfect_sounds = list('modular_bluemoon/sound/heretic/dance/perfect_macabre_1.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_macabre_2.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_macabre_3.ogg')
	step_sounds = list('modular_bluemoon/sound/heretic/dance/step_macabre_1.ogg', 'modular_bluemoon/sound/heretic/dance/step_macabre_2.ogg', 'modular_bluemoon/sound/heretic/dance/step_macabre_3.ogg')
	switch_sound = 'modular_bluemoon/sound/heretic/dance/switch_macabre.ogg'
	id = HERETIC_DANCE_STYLE_MACABRE
	name = "Пляска смерти"
	beat_ds = 12
	meter = 4
	color = "#e8dccb"
	figure = list(0, 0, 0, 0)
	figure_name = "процессия"
	passive_text = "заражённые видят вместо вас скелет, враги в 5 клетках вязнут на каждой доле"
	accent_text = "колокол: каждый заражённый в 7 клетках делает шаг к вам"
	figure_text = "четыре шага по прямой - хоровод на 3 секунды"

/datum/heretic_dance_style/macabre/passive_on(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	dance.show_skeleton(user)

/datum/heretic_dance_style/macabre/passive_off(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	dance.hide_skeleton()

/datum/heretic_dance_style/macabre/on_beat(datum/eldritch_knowledge/base_dance/dance, mob/living/user, strong)
	if(!dance.passive_active)
		return
	for(var/mob/living/carbon/victim in range(5, user))
		if(heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
			victim.apply_status_effect(/datum/status_effect/heretic_dance_dread)

/datum/heretic_dance_style/macabre/accent(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, power = 1)
	if(power < 1)
		heretic_dance_step_toward(victim, user)
		return
	dance.toll_bell(user, power >= 2 ? 2 : 1)

/datum/heretic_dance_style/macabre/flourish(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	return dance.start_horovod(user, 3 SECONDS, 3, HERETIC_DANCE_FIGURE_HOROVOD_RANGE)

/datum/movespeed_modifier/heretic_dance_waltz
	multiplicative_slowdown = -0.25

/// Переставляет цель на клетку по другую сторону от ведущего, как в повороте вальса.
/proc/heretic_dance_turn_partner(mob/living/user, mob/living/victim)
	var/turf/center = get_turf(user)
	var/turf/from = get_turf(victim)
	if(!center || !from || victim.anchored || victim.buckled || victim.pulledby || center.z != from.z)
		return FALSE
	var/turf/landing = locate(center.x * 2 - from.x, center.y * 2 - from.y, center.z)
	if(!landing || !heretic_tile_passable(landing) || landing.is_blocked_turf(exclude_mobs = FALSE))
		return FALSE
	victim.forceMove(landing)
	victim.setDir(get_dir(landing, center))
	return TRUE

/// Видимый такт на теле: подскок на сильную долю, покачивание на слабых; jerky - рывок марионетки в раже.
/proc/heretic_dance_hop(mob/living/dancer, strong, jerky = FALSE)
	if(QDELETED(dancer) || dancer.stat != CONSCIOUS || !isturf(dancer.loc) || dancer.resting)
		return
	var/lift = strong ? 3 : 1
	var/sway = jerky ? pick(-2, 2) : 0
	animate(dancer, pixel_z = lift, pixel_w = sway, time = 1, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_RELATIVE | ANIMATION_PARALLEL)
	animate(pixel_z = -lift, pixel_w = -sway, time = strong ? 3 : 2, easing = BOUNCE_EASING, flags = ANIMATION_RELATIVE)

/// Один шаг к цели, без прохода сквозь стены и без шага в пропасть.
/proc/heretic_dance_step_toward(mob/living/walker, atom/goal)
	var/turf/here = get_turf(walker)
	var/turf/there = get_turf(goal)
	if(!here || !there || here.z != there.z || get_dist(here, there) <= 1 || !isturf(walker.loc) || walker.buckled || walker.anchored || walker.pulledby)
		return FALSE
	var/direction = get_dir(here, there)
	for(var/step_direction in list(direction, turn(direction, 45), turn(direction, -45)))
		var/turf/next = get_step(here, step_direction)
		if(!next || isgroundlessturf(next) || get_dist(next, there) >= get_dist(here, there) || next.is_blocked_turf(exclude_mobs = TRUE))
			continue
		if(walker.Move(next, step_direction))
			return TRUE
	return FALSE

/// Слух для чар Пляски: глухота и наушники-заглушки закрывают от музыки, шлемы и гарнитуры - нет.
/proc/heretic_dance_can_hear(mob/living/victim)
	if(!istype(victim) || victim.stat != CONSCIOUS || HAS_TRAIT(victim, TRAIT_DEAF))
		return FALSE
	var/mob/living/carbon/carbon = victim
	if(!istype(carbon))
		return TRUE
	var/obj/item/organ/ears/ears = carbon.getorganslot(ORGAN_SLOT_EARS)
	if(!ears || ears.deaf)
		return FALSE
	var/mob/living/carbon/human/human = carbon
	if(istype(carbon.ears, /obj/item/clothing/ears/earmuffs) || (istype(human) && istype(human.ears_extra, /obj/item/clothing/ears/earmuffs)))
		return FALSE
	return TRUE

/// Точность действия по доле: промах, в долю или точно; strong_ref получает TRUE для сильной доли.
/datum/eldritch_knowledge/base_dance/proc/timing(mob/living/user, time = world.time)
	var/latency = 0
	if(user?.client?.avgping_rtt)
		latency = clamp(user.client.avgping_rtt / 100, 0, HERETIC_DANCE_LATENCY_CAP)
	var/elapsed = time - latency - beat_origin
	var/nearest = round(elapsed / beat_ds + 0.5)
	var/offset = abs(elapsed - nearest * beat_ds)
	last_timing_strong = (nearest % meter) == 0
	var/datum/heretic_dance_style/style = current_style()
	var/scale = style?.id == HERETIC_DANCE_STYLE_TARANTELLA ? 0.6 : 1
	if(offset <= HERETIC_DANCE_PERFECT_WINDOW * scale + 0.01)
		return HERETIC_DANCE_PERFECT
	if(offset <= HERETIC_DANCE_BEAT_WINDOW * scale + 0.01)
		return HERETIC_DANCE_ON_BEAT
	return HERETIC_DANCE_MISS

/datum/eldritch_knowledge/base_dance/proc/current_style()
	return GLOB.heretic_dance_styles[style_id]

/datum/eldritch_knowledge/base_dance/proc/style_known(style_id_to_check)
	var/datum/heretic_dance_style/style = GLOB.heretic_dance_styles[style_id_to_check]
	if(!style)
		return FALSE
	if(!style.unlock)
		return TRUE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(dance_body)
	return !isnull(heretic?.get_knowledge(style.unlock))

/datum/eldritch_knowledge/base_dance/proc/known_styles()
	. = list()
	for(var/id in GLOB.heretic_dance_styles)
		if(style_known(id))
			. += id

/// Сменить стиль; в сильную долю Такт сохраняется и следующий акцент удваивается, иначе Такт делится пополам.
/datum/eldritch_knowledge/base_dance/proc/switch_style(mob/living/user, new_style_id)
	if(!can_use(user) || !style_known(new_style_id))
		return FALSE
	if(new_style_id == style_id)
		return FALSE
	var/accuracy = timing(user)
	var/linked = accuracy != HERETIC_DANCE_MISS && last_timing_strong
	set_passive(FALSE)
	style_id = new_style_id
	var/datum/heretic_dance_style/style = current_style()
	beat_ds = style.beat_ds
	meter = style.meter
	if(linked)
		link_bonus = TRUE
		user.balloon_alert(user, "связка!")
	else
		combat_resource = round(combat_resource / 2)
	figure_steps.Cut()
	restart_clock()
	update_passive()
	refresh_bolero_passives()
	if(linked)
		style_entrance(user)
	update_style_status()
	notify_resource_changed()
	playsound(user, style.switch_sound, 45, TRUE)
	to_chat(user, span_eldritch("Стиль: [style.name]. [linked ? "Связка в сильную долю: Такт сохранён, следующий акцент удвоен." : "Такт делится пополам: меняйте стиль в сильную долю, чтобы его сохранить."]"))
	return TRUE

/datum/eldritch_knowledge/base_dance/proc/open_style_menu(mob/living/user)
	if(!can_use(user, ignore_grab = TRUE))
		return FALSE
	var/list/choices = list()
	for(var/id in known_styles())
		var/datum/heretic_dance_style/style = GLOB.heretic_dance_styles[id]
		choices[style.name] = image(icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi', icon_state = "dance_style_[id]")
	if(length(choices) < 2)
		to_chat(user, span_warning("Пока вы знаете только Вальс: новые стили откроются по ходу пути."))
		return FALSE
	var/choice = show_radial_menu(user, user, choices, tooltips = TRUE)
	if(!choice)
		return FALSE
	for(var/id in GLOB.heretic_dance_styles)
		var/datum/heretic_dance_style/style = GLOB.heretic_dance_styles[id]
		if(style.name == choice)
			return switch_style(user, id)
	return FALSE

/datum/eldritch_knowledge/base_dance/proc/restart_clock()
	beat_origin = world.time
	beat_index = -1
	deltimer(beat_timer)
	beat_timer = null
	on_beat()

/datum/eldritch_knowledge/base_dance/proc/stop_clock()
	deltimer(beat_timer)
	beat_timer = null

/datum/eldritch_knowledge/base_dance/proc/on_beat()
	beat_timer = null
	if(QDELETED(src) || QDELETED(dance_body))
		return
	beat_index++
	var/strong = (beat_index % meter) == 0
	var/datum/heretic_dance_style/style = current_style()
	if(dance_body.stat != DEAD)
		decay_takt()
		pulse_hud(strong)
		if(strong)
			play_bar(style)
		style.on_beat(src, dance_body, strong)
		if(combat_resource >= HERETIC_DANCE_RAGE_TAKT)
			heretic_dance_hop(dance_body, strong, TRUE)
		bolero_beat(strong)
		SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_BEAT, beat_index, strong)
	var/next_at = beat_origin + (beat_index + 1) * beat_ds
	beat_timer = addtimer(CALLBACK(src, PROC_REF(on_beat)), max(world.tick_lag, next_at - world.time), TIMER_STOPPABLE)

/datum/eldritch_knowledge/base_dance/proc/in_combat()
	return world.time - last_combat_at < HERETIC_DANCE_COMBAT_WINDOW

/datum/eldritch_knowledge/base_dance/proc/decay_takt()
	if(in_combat() || combat_resource <= 0)
		decay_progress = 0
		return
	decay_progress += beat_ds
	var/interval = decay_interval()
	if(decay_progress < interval)
		return
	decay_progress -= interval
	combat_resource--
	update_passive()
	notify_resource_changed()

/datum/eldritch_knowledge/base_dance/proc/decay_interval()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(dance_body)
	var/datum/eldritch_knowledge/dance_heart/heart = heretic?.get_knowledge(/datum/eldritch_knowledge/dance_heart)
	return heart ? heart.passive_values[heart.passive_level] : 1 SECONDS

/// Музыка звучит, пока идёт бой или держится Такт; вне боя - только тихий удар сердца в сильную долю.
/datum/eldritch_knowledge/base_dance/proc/play_bar(datum/heretic_dance_style/style)
	if(bolero_on && !bolero_active())
		return
	var/list/listeners = list(dance_body)
	for(var/mob/living/dancer as anything in dancers)
		if(!QDELETED(dancer))
			listeners |= dancer
	if(!in_combat() && combat_resource <= 0 && length(listeners) <= 1 && !bolero_active())
		dance_body.playsound_local(get_turf(dance_body), 'modular_bluemoon/sound/heretic/dance/beat.ogg', DANCE_BEAT_VOLUME, FALSE)
		return
	var/sound_file = bolero_active() ? bolero_phrase() : next_phrase(style)
	for(var/mob/living/listener as anything in listeners)
		if(listener.client && heretic_dance_can_hear(listener))
			listener.playsound_local(get_turf(listener), sound_file, DANCE_MUSIC_VOLUME, FALSE)

/datum/eldritch_knowledge/base_dance/proc/next_phrase(datum/heretic_dance_style/style)
	var/index = rand(1, HERETIC_DANCE_PHRASES)
	if(index == last_phrase)
		index = (index % HERETIC_DANCE_PHRASES) + 1
	last_phrase = index
	return style.phrase(index)

/datum/eldritch_knowledge/base_dance/proc/bolero_active()
	return FALSE

/datum/eldritch_knowledge/base_dance/proc/bolero_phrase()
	return null

/// Удар или Хватка по живому врагу: Такт, акцент в сильную долю, приём стиля.
/datum/eldritch_knowledge/base_dance/proc/register_strike(mob/living/user, mob/living/victim, accuracy, strong, blade = FALSE)
	if(!can_use(user) || !heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
		return
	last_combat_at = world.time
	var/datum/heretic_dance_style/style = current_style()
	if(accuracy == HERETIC_DANCE_MISS)
		if(COOLDOWN_FINISHED(src, takt_hit_gap))
			COOLDOWN_START(src, takt_hit_gap, DANCE_TAKT_HIT_GAP)
			gain_takt(DANCE_TAKT_ANY)
	else
		gain_takt(accuracy == HERETIC_DANCE_PERFECT ? DANCE_TAKT_PERFECT : DANCE_TAKT_BEAT)
		beat_fx(user, accuracy)
	if(blade && entrance_strike_until >= world.time)
		entrance_strike_until = 0
		victim.adjustBruteLoss(entrance_strike_bonus)
	style.on_strike(src, user, victim, accuracy, blade)
	if(accuracy != HERETIC_DANCE_MISS && strong && !QDELETED(victim))
		var/power = link_bonus ? 2 : 1
		link_bonus = FALSE
		style.accent(src, user, victim, power)
		accent_fx(user, victim, style)

/datum/eldritch_knowledge/base_dance/proc/gain_takt(amount)
	gain_combat_resource(amount)
	update_passive()

/datum/eldritch_knowledge/base_dance/proc/update_passive()
	set_passive(combat_resource >= HERETIC_DANCE_PASSIVE_TAKT || bolero_keeps_passive(style_id))

/datum/eldritch_knowledge/base_dance/proc/bolero_keeps_passive(id)
	return FALSE

/datum/eldritch_knowledge/base_dance/proc/set_passive(active)
	if(passive_active == active || QDELETED(dance_body))
		passive_active = active && !QDELETED(dance_body)
		return
	passive_active = active
	var/datum/heretic_dance_style/style = current_style()
	if(active)
		style.passive_on(src, dance_body)
		show_aura()
	else
		style.passive_off(src, dance_body)
		hide_aura()

/// Шаг еретика: фигуры считают только шаги в долю, по одному на долю.
/datum/eldritch_knowledge/base_dance/proc/on_dance_step(mob/living/user, direction)
	if(!can_use(user) || !direction)
		return
	var/accuracy = timing(user)
	var/step_beat = round((world.time - beat_origin) / beat_ds + 0.5)
	if(accuracy == HERETIC_DANCE_MISS || step_beat == last_step_beat)
		figure_steps.Cut()
		last_step_beat = step_beat
		return
	if(length(figure_steps) && step_beat - last_step_beat > 1)
		figure_steps.Cut()
	last_step_beat = step_beat
	figure_steps += direction
	if(in_combat() || combat_resource > 0)
		var/datum/heretic_dance_style/step_style = current_style()
		playsound(user, pick(step_style.step_sounds), 20, TRUE, SILENCED_SOUND_EXTRARANGE)
	if(in_combat() && combat_resource >= HERETIC_DANCE_PASSIVE_TAKT)
		heretic_heal_pool(user, HERETIC_DANCE_STEP_HEAL)
	check_figure(user)

/datum/eldritch_knowledge/base_dance/proc/check_figure(mob/living/user)
	var/datum/heretic_dance_style/style = current_style()
	var/list/pattern = style.figure
	if(!length(pattern) || length(figure_steps) < length(pattern))
		return FALSE
	var/list/tail = figure_steps.Copy(length(figure_steps) - length(pattern) + 1)
	var/first = tail[1]
	for(var/index in 1 to length(pattern))
		if(tail[index] != turn(first, pattern[index]))
			return FALSE
	figure_steps.Cut()
	if(beat_index < figure_ready_beat)
		return FALSE
	if(!style.flourish(src, user))
		return FALSE
	figure_ready_beat = beat_index + DANCE_FIGURE_COOLDOWN_BEATS
	flourish_fx(user, style)
	return TRUE

/datum/eldritch_knowledge/base_dance/proc/beat_fx(mob/living/user, accuracy)
	var/turf/place = get_turf(user)
	if(!place)
		return
	new /obj/effect/temp_visual/heretic_dance/ring(place, accuracy == HERETIC_DANCE_PERFECT)
	user.balloon_alert(user, accuracy == HERETIC_DANCE_PERFECT ? "точно" : "в долю")
	if(accuracy == HERETIC_DANCE_PERFECT)
		var/datum/heretic_dance_style/style = current_style()
		user.playsound_local(place, pick(style.perfect_sounds), 45, FALSE)

/datum/eldritch_knowledge/base_dance/proc/accent_fx(mob/living/user, mob/living/victim, datum/heretic_dance_style/style)
	var/turf/place = get_turf(victim) || get_turf(user)
	if(!place)
		return
	new /obj/effect/temp_visual/heretic_dance/accent(place, style.id)
	playsound(place, pick(style.accent_sounds), 55, TRUE)

/datum/eldritch_knowledge/base_dance/proc/flourish_fx(mob/living/user, datum/heretic_dance_style/style)
	var/turf/place = get_turf(user)
	if(!place)
		return
	new /obj/effect/temp_visual/heretic_dance/accent(place, style.id)
	playsound(place, 'modular_bluemoon/sound/heretic/dance/figure.ogg', 55, TRUE)
	to_chat(user, span_eldritch("Фигура «[style.figure_name]»!"))

/datum/eldritch_knowledge/base_dance/proc/pulse_hud(strong)
	var/atom/movable/screen/alert/heretic_dance_beat/drum = dance_body.alerts[DANCE_HUD_ALERT]
	if(!istype(drum))
		drum = dance_body.throw_alert(DANCE_HUD_ALERT, /atom/movable/screen/alert/heretic_dance_beat)
		if(!drum)
			return
		drum.dance_ref = WEAKREF(src)
	var/datum/heretic_dance_style/style = current_style()
	drum.update_style(style, combat_resource, strong)

/atom/movable/screen/alert/heretic_dance_beat
	name = "Такт"
	desc = "Барабан Пляски бьёт долю. Нажмите, чтобы сменить стиль."
	icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi'
	icon_state = "dance_hud_drum"
	var/datum/weakref/dance_ref

/atom/movable/screen/alert/heretic_dance_beat/proc/update_style(datum/heretic_dance_style/style, takt, strong)
	color = style.color
	icon_state = strong ? "dance_hud_drum_strong" : "dance_hud_drum"
	desc = "[style.name], доля [style.beat_ds / 10] с, [style.meter] в такте. Такт [takt] из [HERETIC_DANCE_TAKT_MAX]. Нажмите, чтобы сменить стиль."
	transform = strong ? matrix() * 1.3 : matrix() * 1.12
	animate(src, transform = matrix(), time = min(style.beat_ds * 0.6, 4), easing = SINE_EASING | EASE_OUT)

/atom/movable/screen/alert/heretic_dance_beat/Click(location, control, params)
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	if(dance && usr == dance.dance_body)
		INVOKE_ASYNC(dance, TYPE_PROC_REF(/datum/eldritch_knowledge/base_dance, open_style_menu), usr)
	return TRUE

/obj/effect/temp_visual/heretic_dance
	icon = 'modular_bluemoon/icons/obj/heretic_dance_effects.dmi'
	icon_state = "dance_beat_ring"
	duration = 0.6 SECONDS
	pixel_x = -16
	pixel_y = -16
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_dance/ring/Initialize(mapload, perfect = FALSE)
	if(perfect)
		icon_state = "dance_beat_ring_perfect"
	return ..()

/obj/effect/temp_visual/heretic_dance/accent
	duration = 0.8 SECONDS

/obj/effect/temp_visual/heretic_dance/accent/Initialize(mapload, style_id)
	icon_state = "dance_accent_[style_id || HERETIC_DANCE_STYLE_WALTZ]"
	return ..()

/obj/effect/temp_visual/heretic_dance/ribbons
	icon_state = "dance_ribbons"
	duration = 1 SECONDS

/obj/effect/temp_visual/heretic_dance/confetti
	icon_state = "dance_confetti"
	duration = 1 SECONDS

/obj/effect/temp_visual/heretic_dance/bell
	icon_state = "dance_bell"
	duration = 1.2 SECONDS

/obj/effect/temp_visual/heretic_dance/grasp
	icon_state = "dance_grasp"

/obj/effect/temp_visual/heretic_dance/bolero
	icon_state = "dance_bolero_pulse"
	duration = 1 SECONDS

/obj/effect/temp_visual/heretic_dance/parquet
	icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi'
	icon_state = "dance_parquet_a"
	duration = 3 SECONDS
	pixel_x = 0
	pixel_y = 0
	layer = ABOVE_OPEN_TURF_LAYER
	alpha = 170

/obj/effect/temp_visual/heretic_dance/parquet/Initialize(mapload)
	var/turf/place = get_turf(src)
	if(place && ISODD(place.x + place.y))
		icon_state = "dance_parquet_b"
	. = ..()
	animate(src, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

#undef DANCE_TAKT_ANY
#undef DANCE_TAKT_BEAT
#undef DANCE_TAKT_PERFECT
#undef DANCE_TAKT_HIT_GAP
#undef DANCE_FIGURE_COOLDOWN_BEATS
#undef DANCE_MUSIC_VOLUME
#undef DANCE_BEAT_VOLUME
#undef DANCE_HUD_ALERT
