#define DANCE_TAKT_ANY 1
#define DANCE_TAKT_BEAT 2
#define DANCE_TAKT_PERFECT 3
#define DANCE_TAKT_HIT_GAP (1 SECONDS)
#define DANCE_FIGURE_COOLDOWN_BEATS 16
#define DANCE_MUSIC_VOLUME 40
#define DANCE_BEAT_VOLUME 25
#define DANCE_SPECTATOR_VOLUME 20
#define DANCE_SPECTATOR_RANGE 7
#define DANCE_SPECTATOR_FULL_RANGE 3
#define DANCE_SPECTATOR_FALLOFF_EXPONENT 1
#define DANCE_HUD_ALERT "heretic_dance_beat"
#define DANCE_SWITCH_LINKED 1
#define DANCE_SWITCH_QUEUED 2
#define DANCE_SWITCH_RUSHED 3
#define DANCE_FIGURE_HOLD_BEATS 4
#define DANCE_SLIP_MIN_PROGRESS 2
#define DANCE_PHRASE_FILL 7
#define DANCE_PHRASE_ENTRY 8

GLOBAL_LIST_INIT(heretic_dance_styles, init_heretic_dance_styles())
/// Период тактов стиля: куплет 1-4, вариация 5, ответ 6, сбивка 7 возвращает к началу. Такт 8 с тишиной на сильной доле - вступление.
GLOBAL_LIST_INIT(heretic_dance_phrase_period, list(1, 2, 3, 4, 5, 6, 7))

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
	var/figure_sound
	var/role

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

/// Тело танцора на завершённой фигуре: своё движение у каждого стиля.
/datum/heretic_dance_style/proc/figure_pose(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	heretic_dance_hop(user, TRUE)

/// Последняя доля перед сильной: стиль готовит акцент телом.
/datum/heretic_dance_style/proc/before_strong(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	return

/datum/heretic_dance_style/proc/on_strike(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, accuracy, blade)
	return

/// Удар при работающей пассивке стиля: текущего или удержанного Болеро.
/datum/heretic_dance_style/proc/passive_strike(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, accuracy, blade)
	return

/// Шаг ведущего в долю: след стиля на полу.
/datum/heretic_dance_style/proc/on_step(datum/eldritch_knowledge/base_dance/dance, mob/living/user, turf/old_loc, direction)
	return

/datum/heretic_dance_style/proc/passive_beat(datum/eldritch_knowledge/base_dance/dance, mob/living/user, strong)
	return

/datum/heretic_dance_style/waltz
	phrases = list('modular_bluemoon/sound/heretic/dance/waltz_1.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_2.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_3.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_4.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_5.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_6.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_7.ogg', 'modular_bluemoon/sound/heretic/dance/waltz_8.ogg')
	accent_sounds = list('modular_bluemoon/sound/heretic/dance/accent_waltz_1.ogg', 'modular_bluemoon/sound/heretic/dance/accent_waltz_2.ogg', 'modular_bluemoon/sound/heretic/dance/accent_waltz_3.ogg')
	perfect_sounds = list('modular_bluemoon/sound/heretic/dance/perfect_waltz_1.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_waltz_2.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_waltz_3.ogg')
	step_sounds = list('modular_bluemoon/sound/heretic/dance/step_waltz_1.ogg', 'modular_bluemoon/sound/heretic/dance/step_waltz_2.ogg', 'modular_bluemoon/sound/heretic/dance/step_waltz_3.ogg')
	switch_sound = 'modular_bluemoon/sound/heretic/dance/switch_waltz.ogg'
	figure_sound = 'modular_bluemoon/sound/heretic/dance/figure_waltz.ogg'
	id = HERETIC_DANCE_STYLE_WALTZ
	role = "ведёт врага за собой"
	name = "Вальс"
	beat_ds = 8.5
	meter = 3
	color = "#e0b27a"
	figure = list(0, -90, 180, 90)
	figure_name = "квадрат"
	passive_text = "шаги скользят: вы быстрее"
	accent_text = "цель перелетает на другую сторону от вас, теряет ориентацию на 2-4 секунды и 15 выносливости"
	figure_text = "шаг вперёд, вправо, назад, влево - 4 секунды ведёте соседнего врага: он повторяет каждый ваш шаг"

/datum/heretic_dance_style/waltz/passive_on(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	user.add_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_waltz)

/datum/heretic_dance_style/waltz/passive_off(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	user.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_waltz)

/datum/heretic_dance_style/waltz/accent(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, power = 1)
	victim.confused = max(victim.confused, power >= 1 ? 2 : 1)
	victim.adjustStaminaLoss(HERETIC_DANCE_ACCENT_STAMINA * power)
	if(power < 1)
		victim.setDir(turn(victim.dir, 180))
		return
	heretic_dance_turn_partner(user, victim)

/datum/heretic_dance_style/waltz/flourish(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	return dance.start_lead(user)

/datum/heretic_dance_style/waltz/figure_pose(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	if(!user.resting)
		user.SpinAnimation(6, 1)

/datum/heretic_dance_style/tango
	phrases = list('modular_bluemoon/sound/heretic/dance/tango_1.ogg', 'modular_bluemoon/sound/heretic/dance/tango_2.ogg', 'modular_bluemoon/sound/heretic/dance/tango_3.ogg', 'modular_bluemoon/sound/heretic/dance/tango_4.ogg', 'modular_bluemoon/sound/heretic/dance/tango_5.ogg', 'modular_bluemoon/sound/heretic/dance/tango_6.ogg', 'modular_bluemoon/sound/heretic/dance/tango_7.ogg', 'modular_bluemoon/sound/heretic/dance/tango_8.ogg')
	accent_sounds = list('modular_bluemoon/sound/heretic/dance/accent_tango_1.ogg', 'modular_bluemoon/sound/heretic/dance/accent_tango_2.ogg', 'modular_bluemoon/sound/heretic/dance/accent_tango_3.ogg')
	perfect_sounds = list('modular_bluemoon/sound/heretic/dance/perfect_tango_1.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_tango_2.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_tango_3.ogg')
	step_sounds = list('modular_bluemoon/sound/heretic/dance/step_tango_1.ogg', 'modular_bluemoon/sound/heretic/dance/step_tango_2.ogg', 'modular_bluemoon/sound/heretic/dance/step_tango_3.ogg')
	switch_sound = 'modular_bluemoon/sound/heretic/dance/switch_tango.ogg'
	figure_sound = 'modular_bluemoon/sound/heretic/dance/figure_tango.ogg'
	id = HERETIC_DANCE_STYLE_TANGO
	role = "урон и сбивание с ног"
	name = "Танго"
	beat_ds = 7.5
	meter = 4
	color = "#d13b3b"
	figure = list(0, 180, 0)
	figure_name = "очо"
	passive_text = "удары в долю +6 ушибов, точные ещё и 12 урона выносливости"
	accent_text = "кортэ: цель падает на 1,5 секунды, не чаще раза в 6 секунд, иначе теряет 15 выносливости"
	figure_text = "шаг в сторону, обратно, снова в сторону - следующий удар клинком выпадом с 2 клеток"

/datum/heretic_dance_style/tango/passive_strike(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, accuracy, blade)
	if(!blade || accuracy == HERETIC_DANCE_MISS)
		return
	victim.adjustBruteLoss(HERETIC_DANCE_TANGO_BONUS)
	if(accuracy == HERETIC_DANCE_PERFECT)
		victim.adjustStaminaLoss(HERETIC_DANCE_TANGO_BONUS * 2)

/datum/heretic_dance_style/tango/accent(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, power = 1)
	if(power < 1)
		victim.adjustStaminaLoss(HERETIC_DANCE_ACCENT_STAMINA)
		victim.apply_status_effect(/datum/status_effect/heretic_dance_stumble)
		return
	if(victim.has_status_effect(/datum/status_effect/heretic_dance_dipped))
		victim.adjustStaminaLoss(HERETIC_DANCE_ACCENT_STAMINA)
		return
	victim.apply_status_effect(/datum/status_effect/heretic_dance_dipped)
	heretic_dance_lunge(user, victim)
	heretic_dance_dip(victim, user)
	victim.Knockdown(power >= 2 ? 2.5 SECONDS : 1.5 SECONDS)

/datum/heretic_dance_style/tango/before_strong(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	var/mob/living/partner = dance.nearest_enemy(user)
	if(partner)
		heretic_dance_lean_back(user, partner, dance.beat_ds)

/datum/heretic_dance_style/tango/flourish(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	dance.lunge_until = world.time + 3 SECONDS
	user.balloon_alert(user, "выпад готов")
	return TRUE

/datum/heretic_dance_style/tango/figure_pose(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	heretic_dance_lean_back(user, dance.nearest_enemy(user) || get_step(user, user.dir), 6)

/datum/heretic_dance_style/tarantella
	phrases = list('modular_bluemoon/sound/heretic/dance/tarantella_1.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_2.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_3.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_4.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_5.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_6.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_7.ogg', 'modular_bluemoon/sound/heretic/dance/tarantella_8.ogg')
	accent_sounds = list('modular_bluemoon/sound/heretic/dance/accent_tarantella_1.ogg', 'modular_bluemoon/sound/heretic/dance/accent_tarantella_2.ogg', 'modular_bluemoon/sound/heretic/dance/accent_tarantella_3.ogg')
	perfect_sounds = list('modular_bluemoon/sound/heretic/dance/perfect_tarantella_1.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_tarantella_2.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_tarantella_3.ogg')
	step_sounds = list('modular_bluemoon/sound/heretic/dance/step_tarantella_1.ogg', 'modular_bluemoon/sound/heretic/dance/step_tarantella_2.ogg', 'modular_bluemoon/sound/heretic/dance/step_tarantella_3.ogg')
	switch_sound = 'modular_bluemoon/sound/heretic/dance/switch_tarantella.ogg'
	figure_sound = 'modular_bluemoon/sound/heretic/dance/figure_tarantella.ogg'
	id = HERETIC_DANCE_STYLE_TARANTELLA
	role = "яд и лечение вплотную"
	name = "Тарантелла"
	beat_ds = 5
	meter = 6
	color = "#8f1d21"
	figure_name = "укус"
	passive_text = "каждое точное действие лечит 2"
	accent_text = "5 ушибов за стак тарантизма, стаки остаются; двойной акцент бьёт вдвое и сжигает их"
	figure_text = "4 точных удара подряд по одной цели - она 4 секунды пляшет, не владея ногами"

/datum/heretic_dance_style/tarantella/on_strike(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, accuracy, blade)
	if(accuracy == HERETIC_DANCE_MISS)
		dance.bite_chain = 0
		return
	victim.apply_status_effect(/datum/status_effect/heretic_dance/tarantism, dance)
	if(!blade || (accuracy != HERETIC_DANCE_PERFECT && dance.lag_forgiving()))
		return
	if(accuracy != HERETIC_DANCE_PERFECT || dance.bite_target?.resolve() != victim)
		dance.bite_target = WEAKREF(victim)
		dance.bite_chain = accuracy == HERETIC_DANCE_PERFECT ? 1 : 0
		return
	if(++dance.bite_chain < HERETIC_DANCE_BITE_HITS)
		victim.balloon_alert(user, "укус [dance.bite_chain] из [HERETIC_DANCE_BITE_HITS]")
		return
	if(dance.bite_chain >= HERETIC_DANCE_BITE_HITS)
		dance.bite_chain = 0
		if(dance.try_routine(user, victim))
			return
		victim.apply_status_effect(/datum/status_effect/heretic_dance/frenzy, dance, 4 SECONDS)
		dance.flourish_fx(user, src, victim)

/datum/heretic_dance_style/tarantella/passive_strike(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, accuracy, blade)
	if(accuracy == HERETIC_DANCE_PERFECT)
		heretic_heal_pool(user, 2)

/datum/heretic_dance_style/tarantella/accent(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, power = 1)
	var/datum/status_effect/heretic_dance/tarantism/bite = victim.has_status_effect(/datum/status_effect/heretic_dance/tarantism)
	if(power < 1)
		victim.apply_status_effect(/datum/status_effect/heretic_dance/tarantism, dance)
		return
	if(!bite)
		return
	victim.adjustBruteLoss(bite.stacks * 5 * power)
	if(power >= 2)
		qdel(bite)

/datum/heretic_dance_style/cancan
	phrases = list('modular_bluemoon/sound/heretic/dance/cancan_1.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_2.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_3.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_4.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_5.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_6.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_7.ogg', 'modular_bluemoon/sound/heretic/dance/cancan_8.ogg')
	accent_sounds = list('modular_bluemoon/sound/heretic/dance/accent_cancan_1.ogg', 'modular_bluemoon/sound/heretic/dance/accent_cancan_2.ogg', 'modular_bluemoon/sound/heretic/dance/accent_cancan_3.ogg')
	perfect_sounds = list('modular_bluemoon/sound/heretic/dance/perfect_cancan_1.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_cancan_2.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_cancan_3.ogg')
	step_sounds = list('modular_bluemoon/sound/heretic/dance/step_cancan_1.ogg', 'modular_bluemoon/sound/heretic/dance/step_cancan_2.ogg', 'modular_bluemoon/sound/heretic/dance/step_cancan_3.ogg')
	switch_sound = 'modular_bluemoon/sound/heretic/dance/switch_cancan.ogg'
	figure_sound = 'modular_bluemoon/sound/heretic/dance/figure_cancan.ogg'
	id = HERETIC_DANCE_STYLE_CANCAN
	role = "отброс и прорыв"
	name = "Канкан"
	beat_ds = 6
	meter = 4
	color = "#f07a3a"
	figure = list(0, 0, 180, 180)
	figure_name = "линия"
	passive_text = "столы и лежачие не задерживают вас"
	accent_text = "мах ногой: 20 выносливости и отброс на 2 клетки, одну цель не чаще раза в 6 секунд"
	figure_text = "два шага вперёд, два назад - медные ленты слепят всех в 2 клетках, а вы рывком проходите 3 клетки сквозь толпу"

/datum/heretic_dance_style/cancan/passive_on(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	ADD_TRAIT(user, TRAIT_FREERUNNING, HERETIC_DANCE_STYLE_CANCAN)

/datum/heretic_dance_style/cancan/passive_off(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	REMOVE_TRAIT(user, TRAIT_FREERUNNING, HERETIC_DANCE_STYLE_CANCAN)

/datum/heretic_dance_style/cancan/accent(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, power = 1)
	var/distance = power >= 2 ? 3 : (power < 1 ? 1 : 2)
	victim.adjustStaminaLoss(power < 1 ? 10 : 20 * power)
	if(power >= 1)
		heretic_dance_kick(user, victim)
	if(victim.anchored || victim.buckled || !isturf(victim.loc) || victim.has_status_effect(/datum/status_effect/heretic_dance_kicked))
		return
	victim.apply_status_effect(/datum/status_effect/heretic_dance_kicked)
	var/turf/target = get_ranged_target_turf(victim, get_dir(user, victim) || user.dir, distance)
	victim.throw_at(target, distance, 1, user, spin = FALSE)

/datum/heretic_dance_style/cancan/flourish(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	return dance.cancan_dash(user)

/datum/heretic_dance_style/cancan/figure_pose(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	heretic_dance_kick(user, get_step(user, user.dir))

/datum/heretic_dance_style/macabre
	phrases = list('modular_bluemoon/sound/heretic/dance/macabre_1.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_2.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_3.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_4.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_5.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_6.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_7.ogg', 'modular_bluemoon/sound/heretic/dance/macabre_8.ogg')
	accent_sounds = list('modular_bluemoon/sound/heretic/dance/accent_macabre_1.ogg', 'modular_bluemoon/sound/heretic/dance/accent_macabre_2.ogg', 'modular_bluemoon/sound/heretic/dance/accent_macabre_3.ogg')
	perfect_sounds = list('modular_bluemoon/sound/heretic/dance/perfect_macabre_1.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_macabre_2.ogg', 'modular_bluemoon/sound/heretic/dance/perfect_macabre_3.ogg')
	step_sounds = list('modular_bluemoon/sound/heretic/dance/step_macabre_1.ogg', 'modular_bluemoon/sound/heretic/dance/step_macabre_2.ogg', 'modular_bluemoon/sound/heretic/dance/step_macabre_3.ogg')
	switch_sound = 'modular_bluemoon/sound/heretic/dance/switch_macabre.ogg'
	figure_sound = 'modular_bluemoon/sound/heretic/dance/figure_macabre.ogg'
	id = HERETIC_DANCE_STYLE_MACABRE
	role = "толпа вязнет и тянется к вам"
	name = "Пляска смерти"
	beat_ds = 12
	meter = 4
	color = "#e8dccb"
	figure = list(0, 0, 0, 0)
	figure_name = "процессия"
	passive_text = "заражённые видят вместо вас скелет, враги в 5 клетках вязнут на каждой доле"
	accent_text = "колокол: цель теряет 15 выносливости, она и каждый заражённый в 7 клетках делают шаг к вам"
	figure_text = "четыре шага по прямой - хоровод на 3 секунды"

/datum/heretic_dance_style/macabre/passive_on(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	dance.show_skeleton(user)

/datum/heretic_dance_style/macabre/passive_off(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	dance.hide_skeleton()

/datum/heretic_dance_style/macabre/on_step(datum/eldritch_knowledge/base_dance/dance, mob/living/user, turf/old_loc, direction)
	if(dance.passive_active || (id in dance.bolero_passives))
		new /obj/effect/temp_visual/heretic_dance_bone_steps(old_loc, direction)

/datum/heretic_dance_style/macabre/passive_beat(datum/eldritch_knowledge/base_dance/dance, mob/living/user, strong)
	for(var/mob/living/carbon/victim in range(5, user))
		if(heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
			victim.apply_status_effect(/datum/status_effect/heretic_dance_dread)

/datum/heretic_dance_style/macabre/accent(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/victim, power = 1)
	if(power < 1)
		heretic_dance_step_toward(victim, user)
		return
	victim.adjustStaminaLoss(HERETIC_DANCE_ACCENT_STAMINA * power)
	if(heretic_dance_can_sway(user, victim))
		heretic_dance_step_toward(victim, user)
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
	var/shift_x = (from.x - landing.x) * world.icon_size
	var/shift_y = (from.y - landing.y) * world.icon_size
	victim.forceMove(landing)
	victim.setDir(get_dir(landing, center))
	heretic_dance_swing_arc(victim, shift_x, shift_y)
	new /obj/effect/temp_visual/heretic_dance/ribbons(center)
	return TRUE

/proc/heretic_dance_swing_arc(atom/movable/dancer, shift_x, shift_y)
	var/length = sqrt(shift_x ** 2 + shift_y ** 2)
	if(!length)
		return
	var/bulge_x = -shift_y / length * (world.icon_size / 2)
	var/bulge_y = shift_x / length * (world.icon_size / 2)
	var/base_x = dancer.pixel_x
	var/base_y = dancer.pixel_y
	dancer.pixel_x = base_x + shift_x
	dancer.pixel_y = base_y + shift_y
	animate(dancer, pixel_x = base_x + shift_x / 2 + bulge_x, pixel_y = base_y + shift_y / 2 + bulge_y, time = 1.5, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
	animate(pixel_x = base_x, pixel_y = base_y, time = 1.5, easing = SINE_EASING | EASE_IN)

/// Танго: выпад к цели и возврат; тело смещается к цели и отдёргивается.
/proc/heretic_dance_lunge(mob/living/dancer, atom/target, reach = 8)
	if(QDELETED(dancer) || !target)
		return
	var/direction = get_dir(dancer, target) || dancer.dir
	var/shift_x = (direction & EAST) ? reach : ((direction & WEST) ? -reach : 0)
	var/shift_y = (direction & NORTH) ? reach : ((direction & SOUTH) ? -reach : 0)
	animate(dancer, pixel_x = shift_x, pixel_y = shift_y, time = 1, easing = CUBIC_EASING | EASE_OUT, flags = ANIMATION_RELATIVE | ANIMATION_PARALLEL)
	animate(pixel_x = -shift_x, pixel_y = -shift_y, time = 3, easing = SINE_EASING, flags = ANIMATION_RELATIVE)

/// Танго: вдох перед акцентом - корпус отклоняется от цели и замирает.
/proc/heretic_dance_lean_back(mob/living/dancer, atom/target, time)
	if(QDELETED(dancer) || !target || dancer.resting)
		return
	var/direction = get_dir(dancer, target) || dancer.dir
	var/shift_x = (direction & EAST) ? -3 : ((direction & WEST) ? 3 : 0)
	var/shift_y = (direction & NORTH) ? -2 : ((direction & SOUTH) ? 2 : 0)
	animate(dancer, pixel_x = shift_x, pixel_y = shift_y, time = time * 0.6, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_RELATIVE | ANIMATION_PARALLEL)
	animate(pixel_x = -shift_x, pixel_y = -shift_y, time = time * 0.4, easing = CUBIC_EASING | EASE_IN, flags = ANIMATION_RELATIVE)

/// Кортэ: партнёр прогибается назад по дуге и опускается.
/proc/heretic_dance_dip(mob/living/partner, atom/leader)
	if(QDELETED(partner) || !leader)
		return
	var/direction = get_dir(leader, partner) || partner.dir
	var/shift_x = (direction & EAST) ? 6 : ((direction & WEST) ? -6 : 0)
	animate(partner, pixel_x = shift_x, pixel_z = 4, time = 1.5, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_RELATIVE | ANIMATION_PARALLEL)
	animate(pixel_x = -shift_x, pixel_z = -4, time = 4, easing = BOUNCE_EASING | EASE_OUT, flags = ANIMATION_RELATIVE)

/// Канкан: мах ногой - подскок вверх и отклонение корпуса назад.
/proc/heretic_dance_kick(mob/living/dancer, atom/target)
	if(QDELETED(dancer) || dancer.resting)
		return
	var/direction = get_dir(dancer, target) || dancer.dir
	var/lean = (direction & EAST) ? -2 : ((direction & WEST) ? 2 : 0)
	animate(dancer, pixel_z = 5, pixel_x = lean, time = 1, easing = CUBIC_EASING | EASE_OUT, flags = ANIMATION_RELATIVE | ANIMATION_PARALLEL)
	animate(pixel_z = -5, pixel_x = -lean, time = 3, easing = BOUNCE_EASING | EASE_OUT, flags = ANIMATION_RELATIVE)

/// Видимый такт на теле: подскок на сильную долю, покачивание на слабых; jerky - рывок марионетки в раже.
/proc/heretic_dance_hop(mob/living/dancer, strong, jerky = FALSE, tremor = 2)
	if(QDELETED(dancer) || dancer.stat != CONSCIOUS || !isturf(dancer.loc) || dancer.resting)
		return
	var/lift = strong ? 3 : 1
	var/sway = jerky ? pick(-tremor, tremor) : 0
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

/// Громкость музыки Пляски с поправкой на ползунок слушателя в настройках звука.
/proc/heretic_dance_music_volume(mob/listener, base)
	var/datum/preferences/prefs = listener?.client?.prefs
	return prefs ? base * prefs.get_sound_volume("heretic_dance") / 100 : base

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

/// Монотонные часы в децисекундах: в отличие от world.time идут и во время фриза сервера, как музыка у клиента.
/proc/heretic_dance_real_time()
	return SStick_spikes.now_ms() / 100

/// Точность по отклонению от доли в дс: scale сужает окна (Тарантелла), slack расширяет их на разброс пинга.
/proc/heretic_dance_grade(offset, scale = 1, slack = 0)
	offset = abs(offset)
	if(offset <= HERETIC_DANCE_PERFECT_WINDOW * scale + slack + 0.01)
		return HERETIC_DANCE_PERFECT
	if(offset <= HERETIC_DANCE_BEAT_WINDOW * scale + slack + 0.01)
		return HERETIC_DANCE_ON_BEAT
	return HERETIC_DANCE_MISS

/// Запас окна в дс по джиттеру клиента в мс.
/proc/heretic_dance_jitter_slack(jitter_ms)
	return clamp((jitter_ms || 0) / 200, 0, HERETIC_DANCE_JITTER_SLACK_CAP)

/// Точность действия по доле: промах, в долю или точно; last_timing_* получают номер доли, сторону и сильную долю.
/datum/eldritch_knowledge/base_dance/proc/timing(mob/living/user, time = world.time)
	follow_music()
	var/latency = 0
	var/slack = 0
	if(user?.client?.avgping_rtt)
		latency = clamp(user.client.avgping_rtt / 100, 0, HERETIC_DANCE_LATENCY_CAP)
		slack = heretic_dance_jitter_slack(user.client.avgping_jitter)
	var/elapsed = time - latency - beat_origin
	var/nearest = round(elapsed / beat_ds + 0.5)
	var/signed_offset = elapsed - nearest * beat_ds
	var/offset = abs(signed_offset)
	last_timing_beat = nearest
	last_timing_early = signed_offset < 0
	last_timing_strong = (nearest % meter) == 0
	var/datum/heretic_dance_style/style = current_style()
	var/scale = style?.id == HERETIC_DANCE_STYLE_TARANTELLA && !bolero_on ? 0.6 : 1
	var/accuracy = heretic_dance_grade(offset, scale, slack)
	if(accuracy == HERETIC_DANCE_MISS && lag_forgiving())
		return HERETIC_DANCE_ON_BEAT
	return accuracy

/// Фраза такта играет у клиента в реальном времени: отставшую из-за лага сетку долей двигаем вслед за музыкой.
/datum/eldritch_knowledge/base_dance/proc/follow_music()
	if(QDELETED(dance_body))
		return
	var/position = world.time - bar_world_start
	var/drift = (heretic_dance_real_time() - bar_real_start) - position
	if(abs(drift) < HERETIC_DANCE_LAG_MIN)
		return
	if(abs(drift) >= HERETIC_DANCE_STALL)
		lag_grace_until = world.time + HERETIC_DANCE_LAG_GRACE
	drift = clamp(drift, -position, beat_ds * meter - position)
	beat_origin -= drift
	bar_world_start -= drift
	if(beat_timer)
		schedule_beat()

/// Сразу после фриза сервера нельзя знать, когда игрок на самом деле нажал: промах не засчитывается.
/datum/eldritch_knowledge/base_dance/proc/lag_forgiving()
	return world.time <= lag_grace_until

/datum/eldritch_knowledge/base_dance/proc/sync_bar()
	bar_world_start = world.time
	bar_real_start = heretic_dance_real_time()

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

/// В сильную долю стиль меняется сразу связкой; мимо неё ждёт следующей сильной доли с сохранением Такта. Повторный выбор ждущего стиля меняет сразу, деля Такт.
/datum/eldritch_knowledge/base_dance/proc/switch_style(mob/living/user, new_style_id)
	if(!can_use(user) || !style_known(new_style_id))
		return FALSE
	if(new_style_id == style_id)
		if(!pending_style_id)
			return FALSE
		pending_style_id = null
		user.balloon_alert(user, "остаёмся в стиле")
		pulse_hud(FALSE, FALSE)
		return TRUE
	var/accuracy = timing(user)
	if(accuracy != HERETIC_DANCE_MISS && last_timing_strong)
		return apply_style(user, new_style_id, DANCE_SWITCH_LINKED)
	if(pending_style_id == new_style_id)
		return apply_style(user, new_style_id, DANCE_SWITCH_RUSHED)
	pending_style_id = new_style_id
	var/datum/heretic_dance_style/style = GLOB.heretic_dance_styles[new_style_id]
	user.balloon_alert(user, "[lowertext(style.name)] с сильной доли")
	SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "switch_queued", user, new_style_id)
	to_chat(user, span_eldritch("[style.name] вступит на следующей сильной доле, Такт сохранится. Выберите стиль ещё раз, чтобы сменить сразу ценой половины Такта."))
	pulse_hud(FALSE, FALSE)
	return TRUE

/datum/eldritch_knowledge/base_dance/proc/apply_style(mob/living/user, new_style_id, mode)
	pending_style_id = null
	set_passive(FALSE)
	if(style_id != new_style_id)
		previous_style_id = style_id
	style_id = new_style_id
	var/datum/heretic_dance_style/style = current_style()
	apply_tempo()
	switch(mode)
		if(DANCE_SWITCH_LINKED)
			link_bonus = TRUE
			user.balloon_alert(user, "связка!")
		if(DANCE_SWITCH_RUSHED)
			combat_resource = round(combat_resource / 2)
	figure_steps.Cut()
	held_figure_until = -1
	music_entry = TRUE
	restart_clock()
	update_passive()
	refresh_bolero_passives()
	if(mode == DANCE_SWITCH_LINKED)
		style_entrance(user)
	arm_routine(user, mode != DANCE_SWITCH_RUSHED)
	update_style_status()
	notify_resource_changed()
	refresh_hints()
	playsound(user, style.switch_sound, 45, TRUE)
	switch(mode)
		if(DANCE_SWITCH_LINKED)
			to_chat(user, span_eldritch("Стиль: [style.name]. Связка в сильную долю: Такт сохранён, следующий акцент удвоен."))
		if(DANCE_SWITCH_QUEUED)
			to_chat(user, span_eldritch("Стиль: [style.name]. Вступление в сильную долю сохранило Такт."))
		else
			to_chat(user, span_eldritch("Стиль: [style.name]. Смена мимо сильной доли разделила Такт пополам."))
	SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "switch", user, mode == DANCE_SWITCH_LINKED ? "linked" : (mode == DANCE_SWITCH_QUEUED ? "queued" : "rushed"))
	return TRUE

/// Болеро держит свой темп поверх любого стиля: под него записаны все его фразы.
/datum/eldritch_knowledge/base_dance/proc/apply_tempo()
	var/datum/heretic_dance_style/style = current_style()
	beat_ds = bolero_on ? HERETIC_DANCE_BOLERO_BEAT : style.beat_ds
	meter = bolero_on ? HERETIC_DANCE_BOLERO_METER : style.meter

/// Подпись стиля в меню -> его id: имя и роль.
/datum/eldritch_knowledge/base_dance/proc/style_choices()
	. = list()
	for(var/id in known_styles())
		var/datum/heretic_dance_style/style = GLOB.heretic_dance_styles[id]
		.["[style.name] - [style.role]"] = id

/// Ни боя, ни Такта, ни партнёров, ни Болеро: звучит только сердце, шаги не складываются в фигуры.
/datum/eldritch_knowledge/base_dance/proc/music_silent()
	if(in_combat() || combat_resource > 0 || bolero_active())
		return FALSE
	for(var/mob/living/dancer as anything in dancers)
		if(!QDELETED(dancer))
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_dance/proc/open_style_menu(mob/living/user)
	if(!can_use(user, ignore_grab = TRUE))
		return FALSE
	var/list/styles = style_choices()
	var/list/choices = list()
	for(var/label in styles)
		choices[label] = image(icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi', icon_state = "dance_style_[styles[label]]")
	var/hints_choice = beat_hints ? "Скрыть подсказки такта" : "Показать подсказки такта"
	choices[hints_choice] = image(icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi', icon_state = "dance_next_step")
	var/choice = show_radial_menu(user, user, choices, tooltips = TRUE)
	if(!choice)
		return FALSE
	if(choice == hints_choice)
		toggle_hints(user)
		return TRUE
	return styles[choice] ? switch_style(user, styles[choice]) : FALSE

/datum/eldritch_knowledge/base_dance/proc/restart_clock()
	beat_origin = world.time
	beat_index = -1
	last_step_beat = -1
	deltimer(beat_timer)
	beat_timer = null
	sync_bar()
	on_beat()

/datum/eldritch_knowledge/base_dance/proc/stop_clock()
	deltimer(beat_timer)
	beat_timer = null

/datum/eldritch_knowledge/base_dance/proc/schedule_beat()
	deltimer(beat_timer)
	var/next_at = beat_origin + (beat_index + 1) * beat_ds
	beat_timer = addtimer(CALLBACK(src, PROC_REF(on_beat)), max(world.tick_lag, next_at - world.time), TIMER_STOPPABLE)

/datum/eldritch_knowledge/base_dance/proc/on_beat()
	beat_timer = null
	if(QDELETED(src) || QDELETED(dance_body))
		return
	follow_music()
	beat_index = max(beat_index + 1, round((world.time - beat_origin) / beat_ds + 0.01))
	if(length(figure_steps) && beat_index - last_step_beat > 2)
		lose_figure(dance_body, "пропущена доля")
	var/strong = (beat_index % meter) == 0
	if(strong && pending_style_id && dance_body.stat != DEAD && style_known(pending_style_id))
		apply_style(dance_body, pending_style_id, DANCE_SWITCH_QUEUED)
		return
	beat_total++
	if(strong)
		beat_origin = world.time - beat_index * beat_ds
		sync_bar()
	var/datum/heretic_dance_style/style = current_style()
	if(dance_body.stat != DEAD)
		decay_takt()
		pulse_hud(strong)
		bolero_beat(strong)
		if(strong)
			play_bar(style)
		for(var/datum/heretic_dance_style/passive as anything in passive_styles())
			passive.passive_beat(src, dance_body, strong)
		if(combat_resource >= HERETIC_DANCE_RAGE_TAKT)
			heretic_dance_hop(dance_body, strong, TRUE)
		if((beat_index + 1) % meter == 0 && in_combat())
			style.before_strong(src, dance_body)
		if(held_figure_until >= 0)
			try_held_figure(dance_body)
		SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_BEAT, beat_index, strong)
	schedule_beat()
	if(dance_body.stat != DEAD)
		update_cue()
		refresh_hints()

/datum/eldritch_knowledge/base_dance/proc/nearest_enemy(mob/living/user)
	for(var/mob/living/carbon/candidate in orange(1, user))
		if(candidate.stat != DEAD && heretic_can_affect(user, candidate, chargecost = 0, notify = FALSE))
			return candidate
	return null

/// Стили, чьи пассивки сейчас работают: текущий с 4 Такта и удержанные Болеро.
/datum/eldritch_knowledge/base_dance/proc/passive_styles()
	. = list()
	if(passive_active)
		. += current_style()
	for(var/id in bolero_passives)
		. |= GLOB.heretic_dance_styles[id]

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
	if(music_silent())
		music_entry = TRUE
		dance_body.playsound_local(get_turf(dance_body), 'modular_bluemoon/sound/heretic/dance/beat.ogg', heretic_dance_music_volume(dance_body, DANCE_BEAT_VOLUME), FALSE)
		return
	var/sound_file = bolero_active() ? bolero_phrase() : next_phrase(style)
	var/channel = dance_channel()
	for(var/mob/living/listener as anything in listeners)
		if(listener.client && heretic_dance_can_hear(listener))
			listener.playsound_local(get_turf(listener), sound_file, heretic_dance_music_volume(listener, DANCE_MUSIC_VOLUME), FALSE, channel = channel)
	if(!bolero_active())
		play_to_spectators(sound_file, listeners, channel)

/// Зрители рядом, включая призраков, слышат ту же фразу тише и оттуда, где танцуют.
/datum/eldritch_knowledge/base_dance/proc/play_to_spectators(sound_file, list/listeners, channel)
	var/turf/stage = get_turf(dance_body)
	if(!stage || !SSspatial_grid.initialized)
		return
	for(var/mob/spectator as anything in SSspatial_grid.orthogonal_range_search(stage, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, DANCE_SPECTATOR_RANGE))
		if((spectator in listeners) || spectator.z != stage.z || !(spectator.client?.prefs?.toggles & SOUND_INSTRUMENTS))
			continue
		spectator.playsound_local(stage, sound_file, heretic_dance_music_volume(spectator, DANCE_SPECTATOR_VOLUME), FALSE, falloff_exponent = DANCE_SPECTATOR_FALLOFF_EXPONENT, channel = channel, max_distance = DANCE_SPECTATOR_RANGE, falloff_distance = DANCE_SPECTATOR_FULL_RANGE, distance_multiplier = 1)

/// Один канал на танец: новая фраза обрывает прежнюю, а не звучит поверх.
/datum/eldritch_knowledge/base_dance/proc/dance_channel()
	if(!music_channel)
		music_channel = SSsounds.reserve_sound_channel(src)
	return music_channel

/// Музыка идёт периодом, а не случайными тактами: вступление, куплет, вариация, ответ, сбивка. Перед сменой стиля звучит сбивка.
/datum/eldritch_knowledge/base_dance/proc/next_phrase(datum/heretic_dance_style/style)
	var/index
	if(music_entry)
		music_entry = FALSE
		phrase_step = 0
		index = DANCE_PHRASE_ENTRY
	else if(pending_style_id)
		index = DANCE_PHRASE_FILL
	else
		var/list/period = GLOB.heretic_dance_phrase_period
		phrase_step = phrase_step % length(period) + 1
		index = period[phrase_step]
	last_phrase = index
	return style.phrase(index)

/// Удар или Хватка по живому врагу: Такт, акцент в сильную долю, приём стиля.
/datum/eldritch_knowledge/base_dance/proc/register_strike(mob/living/user, mob/living/victim, accuracy, strong, blade = FALSE)
	if(!can_use(user) || !heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
		return
	last_combat_at = world.time
	last_struck = WEAKREF(victim)
	var/datum/heretic_dance_style/style = current_style()
	var/crescendo = blade && accuracy != HERETIC_DANCE_MISS ? max(0, combat_resource - HERETIC_DANCE_PASSIVE_TAKT) : 0
	if(crescendo)
		victim.adjustBruteLoss(crescendo)
	SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "strike", victim, accuracy)
	if(accuracy == HERETIC_DANCE_MISS)
		user.balloon_alert(user, last_timing_early ? "раньше доли" : "позже доли")
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
	for(var/datum/heretic_dance_style/passive as anything in passive_styles())
		passive.passive_strike(src, user, victim, accuracy, blade)
	if(accuracy != HERETIC_DANCE_MISS && strong && !QDELETED(victim))
		var/power = link_bonus ? 2 : 1
		link_bonus = FALSE
		style.accent(src, user, victim, power)
		accent_fx(user, victim, style)
	if(held_figure_until >= 0)
		try_held_figure(user)
	refresh_hints()

/datum/eldritch_knowledge/base_dance/proc/gain_takt(amount)
	gain_combat_resource(amount)
	update_passive()

/datum/eldritch_knowledge/base_dance/proc/update_passive()
	set_passive(combat_resource >= HERETIC_DANCE_PASSIVE_TAKT || bolero_keeps_passive(style_id))

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

/// Шаг еретика под музыку: каждая доля даёт фигуре одно направление, шаги между долями её не трогают.
/datum/eldritch_knowledge/base_dance/proc/on_dance_step(mob/living/user, direction, turf/old_loc)
	if(!can_use(user) || !direction)
		return
	if(music_silent())
		SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "step_silent", user, direction)
		return
	if(timing(user) == HERETIC_DANCE_MISS)
		return
	var/step_beat = last_timing_beat
	var/forgiving = lag_forgiving()
	if(forgiving && step_beat <= last_step_beat)
		step_beat = last_step_beat + 1
	if(step_beat == last_step_beat)
		retake_step(user, direction)
		return
	var/progress = figure_progress()
	if(length(figure_steps) && step_beat - last_step_beat > 1 && !forgiving)
		if(step_beat - last_step_beat > 2 || !forgive_slip(user, progress))
			lose_figure(user, "пропущена доля")
			progress = 0
	last_step_beat = step_beat
	last_step_kept = place_step(user, direction, progress)
	var/new_progress = figure_progress()
	if(old_loc)
		for(var/datum/heretic_dance_style/step_style as anything in passive_styles() | current_style())
			step_style.on_step(src, user, old_loc, direction)
	var/datum/heretic_dance_style/style = current_style()
	playsound(user, pick(style.step_sounds), 20, TRUE, SILENCED_SOUND_EXTRARANGE)
	if(in_combat() && combat_resource >= HERETIC_DANCE_PASSIVE_TAKT)
		heretic_heal_pool(user, HERETIC_DANCE_STEP_HEAL)
	if(check_figure(user))
		return
	refresh_hints()
	SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "step", user, direction)
	if(new_progress >= 2 && new_progress > progress)
		user.balloon_alert(user, "шаг [new_progress] из [length(style.figure)]")

/// FALSE - шаг не по рисунку прощён и не записан.
/datum/eldritch_knowledge/base_dance/proc/place_step(mob/living/user, direction, progress)
	figure_steps += direction
	var/new_progress = figure_progress()
	if(new_progress != progress + 1 && forgive_slip(user, progress))
		figure_steps.len--
		return FALSE
	if(new_progress == 1)
		figure_slip_used = FALSE
	return TRUE

/// Ещё шаг в ту же долю заменяет её направление, только если ложится в рисунок лучше.
/datum/eldritch_knowledge/base_dance/proc/retake_step(mob/living/user, direction)
	if(last_step_kept && !length(figure_steps))
		return
	var/progress = figure_progress()
	var/old_direction = last_step_kept ? figure_steps[length(figure_steps)] : null
	if(old_direction)
		figure_steps[length(figure_steps)] = direction
	else
		figure_steps += direction
	if(figure_progress() <= progress)
		if(old_direction)
			figure_steps[length(figure_steps)] = old_direction
		else
			figure_steps.len--
		return
	last_step_kept = TRUE
	var/new_progress = figure_progress()
	if(new_progress == 1)
		figure_slip_used = FALSE
	if(check_figure(user))
		return
	refresh_hints()
	if(new_progress >= 2)
		var/datum/heretic_dance_style/style = current_style()
		user.balloon_alert(user, "шаг [new_progress] из [length(style.figure)]")

/// Сбой шага после двух верных шагов прощается один раз на фигуру.
/datum/eldritch_knowledge/base_dance/proc/forgive_slip(mob/living/user, progress)
	if(figure_slip_used || progress < DANCE_SLIP_MIN_PROGRESS)
		return FALSE
	figure_slip_used = TRUE
	user.balloon_alert(user, "сбой прощён, фигура держится")
	SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "figure_slip", user, progress)
	return TRUE

/datum/eldritch_knowledge/base_dance/proc/figure_progress()
	var/datum/heretic_dance_style/style = current_style()
	var/list/pattern = style.figure
	var/steps = length(figure_steps)
	if(!length(pattern) || !steps)
		return 0
	for(var/count in min(length(pattern), steps) to 1 step -1)
		var/first = figure_steps[steps - count + 1]
		var/matched = TRUE
		for(var/index in 1 to count)
			if(figure_steps[steps - count + index] != turn(first, pattern[index]))
				matched = FALSE
				break
		if(matched)
			return count
	return 0

/datum/eldritch_knowledge/base_dance/proc/lose_figure(mob/living/user, reason)
	var/progress = figure_progress()
	if(progress >= 1)
		SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "figure_lost", user, reason)
	if(progress >= 2)
		user.balloon_alert(user, "фигура сбита: [reason]")
	figure_steps.Cut()
	refresh_hints()

/// Счёт долей для перезарядок: попадание чуть раньше доли, которая ещё не пробила, уже считается ею.
/datum/eldritch_knowledge/base_dance/proc/timed_beat_total(accuracy)
	return beat_total + (accuracy != HERETIC_DANCE_MISS && last_timing_early ? 1 : 0)

/datum/eldritch_knowledge/base_dance/proc/check_figure(mob/living/user)
	var/datum/heretic_dance_style/style = current_style()
	var/list/pattern = style.figure
	if(!length(pattern) || figure_progress() < length(pattern))
		return FALSE
	figure_steps.Cut()
	if(try_routine(user))
		figure_ready_beat = beat_total + DANCE_FIGURE_COOLDOWN_BEATS
		refresh_hints()
		return TRUE
	var/step_beat = timed_beat_total(HERETIC_DANCE_ON_BEAT)
	if(step_beat < figure_ready_beat)
		user.balloon_alert(user, "до фигуры долей: [figure_ready_beat - step_beat]")
		SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "figure_cooldown", user, figure_ready_beat - step_beat)
		return FALSE
	if(!style.flourish(src, user))
		held_figure_until = beat_total + DANCE_FIGURE_HOLD_BEATS
		held_figure_style = style_id
		user.balloon_alert(user, "фигура ждёт цели")
		user.playsound_local(get_turf(user), 'modular_bluemoon/sound/heretic/dance/figure.ogg', 35, FALSE)
		SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "figure_held", user, DANCE_FIGURE_HOLD_BEATS)
		refresh_hints()
		return FALSE
	finish_figure(user, style)
	return TRUE

/datum/eldritch_knowledge/base_dance/proc/figure_held()
	return held_figure_until >= beat_total && held_figure_style == style_id

/// Удержанная фигура срабатывает, как только цель рядом: на доле или после удара.
/datum/eldritch_knowledge/base_dance/proc/try_held_figure(mob/living/user)
	if(!figure_held())
		held_figure_until = -1
		user.balloon_alert(user, "фигура рассыпалась")
		SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "figure", user, FALSE)
		refresh_hints()
		return FALSE
	if(!can_use(user))
		return FALSE
	if(try_routine(user))
		held_figure_until = -1
		figure_ready_beat = beat_total + DANCE_FIGURE_COOLDOWN_BEATS
		refresh_hints()
		return TRUE
	var/datum/heretic_dance_style/style = current_style()
	if(!style.flourish(src, user))
		return FALSE
	held_figure_until = -1
	finish_figure(user, style)
	return TRUE

/datum/eldritch_knowledge/base_dance/proc/finish_figure(mob/living/user, datum/heretic_dance_style/style)
	held_figure_until = -1
	figure_ready_beat = beat_total + DANCE_FIGURE_COOLDOWN_BEATS
	flourish_fx(user, style)
	SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "figure", user, TRUE)
	open_routine(user, style)
	refresh_hints()

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

/// Кульминация фигуры видна и слышна всем рядом: свой рисунок, свой инструмент и движение тела; focus - на ком она случилась.
/datum/eldritch_knowledge/base_dance/proc/flourish_fx(mob/living/user, datum/heretic_dance_style/style, atom/focus)
	var/turf/place = get_turf(focus || user)
	if(!place)
		return
	new /obj/effect/temp_visual/heretic_dance/figure(place, style.id, user.dir)
	playsound(place, style.figure_sound, 60, FALSE)
	style.figure_pose(src, user)
	user.visible_message(span_danger("[user] завершает фигуру «[style.figure_name]»!"), span_eldritch("Фигура «[style.figure_name]»!"))

/// pulse - удар барабана в долю; без него только обновляются подписи.
/datum/eldritch_knowledge/base_dance/proc/pulse_hud(strong, pulse = TRUE)
	var/atom/movable/screen/alert/heretic_dance_beat/drum = dance_body.alerts[DANCE_HUD_ALERT]
	if(!istype(drum))
		drum = dance_body.throw_alert(DANCE_HUD_ALERT, /atom/movable/screen/alert/heretic_dance_beat)
		if(!drum)
			return
		drum.dance_ref = WEAKREF(src)
	drum.update_style(src, strong, pulse)

/atom/movable/screen/alert/heretic_dance_beat
	name = "Такт"
	desc = "Барабан Пляски бьёт долю. Нажмите, чтобы сменить стиль; Ctrl+клик - вернуться к прошлому стилю."
	icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi'
	icon_state = "dance_hud_drum"
	var/datum/weakref/dance_ref

/atom/movable/screen/alert/heretic_dance_beat/proc/update_style(datum/eldritch_knowledge/base_dance/dance, strong, pulse = TRUE)
	var/datum/heretic_dance_style/style = dance.current_style()
	var/datum/heretic_dance_style/pending = dance.pending_style_id && GLOB.heretic_dance_styles[dance.pending_style_id]
	var/count = (max(dance.beat_index, 0) % dance.meter) + 1
	var/on_strong = count == 1
	var/figure_wait = max(dance.figure_ready_beat - dance.beat_total, 0)
	var/datum/heretic_dance_routine/offered = dance.offered_routine()
	var/datum/heretic_dance_style/offered_style = offered && GLOB.heretic_dance_styles[offered.to_style]
	color = style.color
	desc = "[style.name], доля [dance.beat_ds / 10] с, [dance.meter] в такте, сейчас [count]-я. Такт [dance.combat_resource] из [HERETIC_DANCE_TAKT_MAX].[pending ? " С сильной доли вступит [pending.name]." : ""][length(style.figure) ? " Фигура [figure_wait ? "готова через [figure_wait]" : "готова"]." : ""][offered ? " Номер «[offered.name]»: связка в [offered_style.name]." : ""] Нажмите, чтобы сменить стиль; Ctrl+клик - прошлый стиль."
	cut_overlays()
	var/mutable_appearance/counter = mutable_appearance(appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART)
	counter.maptext = MAPTEXT("<span style='color:[on_strong ? "#ffe9b0" : "#d8c8b8"]'>[on_strong ? "<b>[count]</b>" : count]/[dance.meter]</span>")
	counter.maptext_width = 32
	counter.maptext_y = -2
	add_overlay(counter)
	if(pending)
		var/mutable_appearance/next = mutable_appearance('modular_bluemoon/icons/obj/heretic_actions.dmi', "dance_style_[pending.id]", appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART)
		next.transform = matrix(0.5, 0, 8, 0, 0.5, 8)
		add_overlay(next)
	if(offered)
		var/mutable_appearance/routine_style = mutable_appearance('modular_bluemoon/icons/obj/heretic_actions.dmi', "dance_style_[offered.to_style]", appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART)
		routine_style.transform = matrix(0.5, 0, -8, 0, 0.5, 8)
		add_overlay(routine_style)
	if(!pulse)
		return
	icon_state = strong ? "dance_hud_drum_strong" : "dance_hud_drum"
	transform = strong ? matrix() * 1.3 : matrix() * 1.12
	animate(src, transform = matrix(), time = min(dance.beat_ds * 0.6, 4), easing = SINE_EASING | EASE_OUT)

/atom/movable/screen/alert/heretic_dance_beat/Click(location, control, params)
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	if(!dance || usr != dance.dance_body)
		return TRUE
	if(LAZYACCESS(params2list(params), CTRL_CLICK))
		dance.hotkey_style(usr, null)
		return TRUE
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

/obj/effect/temp_visual/heretic_dance/figure
	duration = 1.3 SECONDS

/obj/effect/temp_visual/heretic_dance/figure/Initialize(mapload, style_id, facing)
	icon_state = "dance_figure_[style_id || HERETIC_DANCE_STYLE_WALTZ]"
	if(style_id == HERETIC_DANCE_STYLE_CANCAN && facing)
		dir = facing
	return ..()

/obj/effect/temp_visual/heretic_dance/potpourri
	icon_state = "dance_potpourri"
	duration = 1.1 SECONDS

/obj/effect/temp_visual/heretic_dance/rescue
	icon_state = "dance_rescue_snap"
	duration = 0.9 SECONDS

/obj/effect/temp_visual/heretic_dance/false_note
	icon_state = "dance_false_note"
	duration = 1 SECONDS

/obj/effect/temp_visual/heretic_dance/orchestra_return
	icon_state = "dance_orchestra_return"
	duration = 1 SECONDS

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
#undef DANCE_SWITCH_LINKED
#undef DANCE_SWITCH_QUEUED
#undef DANCE_SWITCH_RUSHED
#undef DANCE_FIGURE_HOLD_BEATS
#undef DANCE_SLIP_MIN_PROGRESS
#undef DANCE_PHRASE_FILL
#undef DANCE_PHRASE_ENTRY
#undef DANCE_SPECTATOR_VOLUME
#undef DANCE_SPECTATOR_RANGE
#undef DANCE_SPECTATOR_FULL_RANGE
#undef DANCE_SPECTATOR_FALLOFF_EXPONENT

/obj/effect/temp_visual/heretic_dance_bone_steps
	icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi'
	icon_state = "dance_bone_steps"
	duration = 1.2 SECONDS
	randomdir = FALSE
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/heretic_dance_bone_steps/Initialize(mapload, step_dir)
	if(step_dir)
		dir = step_dir
	return ..()
