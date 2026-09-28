#define DANCE_GRASP_STAMINA 10
#define DANCE_BLADE_LIFESTEAL 3
#define DANCE_BLADE_CHAIN 3
#define DANCE_HEARTBEAT_TIME (3 SECONDS)
#define DANCE_LEAD_CAPTURE "dance_lead"
#define DANCE_INVITE_CAPTURE "dance_invite"

/datum/eldritch_knowledge/dance_grasp
	name = "Хватка в долю"
	summary = "Хватка крадёт у врага 10 выносливости, в долю - 20, и отдаёт её вам; открывает Танго."
	details = list(
		"Украденная выносливость восстанавливает вашу на столько же.",
		"Танго: доля 0,75 с, удары в долю +6 ушибов, акцент валит цель на 1,5 секунды, фигура - выпад с 2 клеток.",
	)
	role = HERETIC_ROLE_GRASP
	gain_text = "Я взял чужую руку, и её сила перешла ко мне вместе с ритмом."
	cost = 1
	route = PATH_DANCE

/datum/eldritch_knowledge/dance_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dance/dance = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dance)
	if(!proximity_flag || user.a_intent == INTENT_HELP || !dance?.can_use(user) || !isliving(target) || !user.Adjacent(target) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	var/stolen = dance.timing(user) == HERETIC_DANCE_MISS ? DANCE_GRASP_STAMINA : DANCE_GRASP_STAMINA * 2
	victim.adjustStaminaLoss(stolen)
	var/mob/living/living_user = user
	living_user.adjustStaminaLoss(-stolen)
	return TRUE

/datum/eldritch_knowledge/spell/dance_invite
	name = "Приглашение"
	summary = "Заражённый человек, который слышит музыку, против воли идёт к вам шаг в долю."
	details = list(
		"Вальс, Тарантелла и Канкан: из 7 клеток, до 8 долей, по пути в обход стен.",
		"Танго: через 2 доли цель из 3 клеток одним рывком оказывается рядом и падает на секунду.",
		"Пляска смерти: из 12 клеток, медленно, до 10 долей.",
		"Дошедший 4 секунды - ваш партнёр: живое сердце уведёт цель охоты в изнанку, фигура Вальса поведёт за собой.",
		"Срывают: схватить, повалить, пристегнуть, растолкать за 2 секунды, заглушки, нулевой жезл, святая вода.",
		"Сорвалось на первой доле - перезарядка возвращается. Перезарядка 45 секунд.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Я не звал их. Я только начал играть, и они пришли сами."
	cost = 1
	route = PATH_DANCE
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_dance/invite

/datum/eldritch_knowledge/dance_mark
	name = "Метка пляски"
	summary = "Хватка ставит метку; удар шпилькой взрывает её двойным акцентом текущего стиля и даёт 1 Такт."
	details = list(
		"Двойной акцент работает в любую долю: Вальс переставляет и путает цель, Танго валит на 2,5 секунды.",
		"Тарантелла взрывает тарантизм вдвое сильнее, Канкан отбрасывает на 3 клетки, Пляска смерти бьёт колоколом дважды.",
	)
	role = HERETIC_ROLE_MARK
	gain_text = "Каждый, кого я коснулся, теперь должен мне танец."
	cost = 2
	route = PATH_DANCE

/datum/eldritch_knowledge/dance_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dance/dance = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dance)
	if(!proximity_flag || user.a_intent == INTENT_HELP || !dance?.can_use(user) || !isliving(target) || !user.Adjacent(target) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/dance)
	return TRUE

/datum/status_effect/eldritch/dance
	id = "dance_mark"
	mark_name = "Метка пляски"
	mark_alert_state = "sigil_dance"
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi'
	effect_sprite = "dance_mark"
	detonation_sound = 'modular_bluemoon/sound/heretic/dance_cast.ogg'

/datum/eldritch_knowledge/spell/dance_drum
	name = "Барабан из кожи"
	summary = "Кожа и сердце дают барабан: раз в 4 доли он бьёт акцентом стиля по заражённым рядом; открывает Тарантеллу."
	details = list(
		"Барабан бьёт из руки или кармана кнопкой «Ударить в барабан»; вне доли - только сердцебиение и 5 выносливости.",
		"Заражённые в 7 клетках, которые слышат, получают ослабленный акцент, а вы 3 секунды видите их сердца сквозь стены.",
		"Тарантелла: доля 0,5 с, самый трудный темп; точные действия лечат 2, удары в долю копят тарантизм.",
		"Стак отнимает 4 выносливости в такт; пять стаков срывают цель в пляску на 3 секунды. Фигура - 4 точных удара подряд.",
	)
	role = HERETIC_ROLE_RELIC
	ritual_hint = "Кожу даёт кожевенный станок или шкура животного; сердце - любое извлечённое сердце."
	gain_text = "Кожа помнила каждый удар сердца, которое под ней билось. Теперь она помнит мои."
	cost = 1
	route = PATH_DANCE
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_dance/drum
	required_atoms = list(/obj/item/stack/sheet/leather, /obj/item/organ/heart)
	result_atoms = list(/obj/item/heretic_path_relic/dance)

/datum/eldritch_knowledge/spell/dance_drum/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/spell/dance_drum/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/dance)

/datum/eldritch_knowledge/dance_blade_upgrade
	name = "Шпилька в доле"
	summary = "Удары шпилькой в долю лечат 3, а третий подряд удар в долю по одной цели ставит на неё метку."
	details = list(
		"Серия рвётся от удара мимо доли или по другой цели.",
		"Метка от серии взрывается следующим ударом, как обычная Метка пляски.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Сталь научилась ждать сильной доли."
	cost = 2
	route = PATH_DANCE
	var/datum/weakref/chain_target
	var/chain = 0

/datum/eldritch_knowledge/dance_blade_upgrade/on_eldritch_blade_damage(mob/living/target, mob/living/user, strike_damage)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dance/dance = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dance)
	if(!dance?.can_use(user))
		return
	var/accuracy = dance.pending_at == world.time ? dance.pending_accuracy : dance.timing(user)
	if(accuracy == HERETIC_DANCE_MISS)
		chain = 0
		chain_target = null
		return
	heretic_heal_pool(user, DANCE_BLADE_LIFESTEAL)
	if(chain_target?.resolve() != target)
		chain_target = WEAKREF(target)
		chain = 0
	if(++chain >= DANCE_BLADE_CHAIN)
		chain = 0
		if(!target.has_status_effect(/datum/status_effect/eldritch/dance))
			target.apply_status_effect(/datum/status_effect/eldritch/dance)

/datum/eldritch_knowledge/spell/dance_masquerade
	name = "Маскарад"
	summary = "6 секунд вы и до 4 заражённых в 7 клетках - одинаковые танцоры в масках; открывает Канкан."
	details = list(
		"Имена скрыты, заражённые под масками переминаются каждую долю; вы вырываетесь из хватки и быстрее.",
		"Попадание разбивает маску того, в кого попали; работает и в чужой хватке. В сильную долю маскарад длится 8 секунд.",
		"Канкан: доля 0,6 с, столы вас не задерживают, акцент отбрасывает на 2 клетки.",
		"Фигура Канкана - два шага вперёд и два назад: ленты слепят всех в 2 клетках, а вы проходите 3 клетки сквозь толпу.",
		"Перезарядка 60 секунд.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "На балу у всех одно лицо. Попробуй найди среди них того, кто пришёл с ножом."
	cost = 1
	route = PATH_DANCE
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_dance/masquerade

/datum/eldritch_knowledge/dance_heart
	name = "Сердце не останавливается"
	summary = "Ваше сердце не встаёт, Такт тает медленнее, а с 4 Такта вы быстрее встаёте после сбивания с ног."
	details = list(
		"Остановка сердца вам не грозит.",
		"Уровни: Такт тает раз в 1,5 / 2 / 3 секунды, сбивание с ног короче на 25 / 40 / 50%.",
	)
	role = HERETIC_ROLE_PASSIVE
	gain_text = "Оно билось, пока играла музыка. А музыка не кончится никогда."
	cost = 2
	route = PATH_DANCE
	passive_values = list(1.5 SECONDS, 2 SECONDS, 3 SECONDS)
	passive_desc = "Такт тает раз в 1,5 / 2 / 3 секунды; сбивание с ног с 4 Такта короче на 25 / 40 / 50%."
	var/mob/living/heart_body
	var/reentry = FALSE

/datum/eldritch_knowledge/dance_heart/on_body_gain(mob/living/user)
	if(heart_body == user)
		return
	on_body_lose(heart_body)
	heart_body = user
	ADD_TRAIT(user, TRAIT_STABLEHEART, REF(src))
	RegisterSignal(user, COMSIG_LIVING_STATUS_KNOCKDOWN, PROC_REF(shorten_knockdown))

/datum/eldritch_knowledge/dance_heart/on_body_lose(mob/living/user)
	if(!heart_body)
		return
	REMOVE_TRAIT(heart_body, TRAIT_STABLEHEART, REF(src))
	UnregisterSignal(heart_body, COMSIG_LIVING_STATUS_KNOCKDOWN)
	heart_body = null

/datum/eldritch_knowledge/dance_heart/on_lose(mob/user)
	on_body_lose(heart_body)
	return ..()

/datum/eldritch_knowledge/dance_heart/Destroy()
	on_body_lose(heart_body)
	return ..()

/datum/eldritch_knowledge/dance_heart/proc/knockdown_share()
	return list(0.75, 0.6, 0.5)[clamp(passive_level, 1, 3)]

/datum/eldritch_knowledge/dance_heart/proc/shorten_knockdown(datum/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	var/datum/antagonist/heretic/heretic = IS_HERETIC(heart_body)
	var/datum/eldritch_knowledge/base_dance/dance = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dance)
	if(reentry || amount <= 0 || !dance || dance.combat_resource < HERETIC_DANCE_PASSIVE_TAKT)
		return NONE
	reentry = TRUE
	heart_body.Knockdown(amount * knockdown_share(), updating, ignore_canstun)
	reentry = FALSE
	return COMPONENT_NO_STUN

/datum/eldritch_knowledge/spell/dance_bell
	name = "Пляска смерти"
	summary = "Колокол за 4 Такта: враги в 3 клетках 5 секунд повторяют ваши шаги и выматываются; открывает стиль."
	details = list(
		"Лежачих, сидящих, пристёгнутых, схваченных, глухих, в заглушках и с защитой от магии хоровод не берёт.",
		"Хоровод отнимает не больше 42 выносливости. Лечь, сесть или схватить втянутого - танец отпустит; потом 20 секунд покоя.",
		"Стиль Пляска смерти: доля 1,2 с, заражённые видят вместо вас скелет, враги в 5 клетках вязнут на каждой доле.",
		"Акцент - колокол: каждый заражённый в 7 клетках делает шаг к вам; фигура - 4 шага прямо, хоровод на 3 секунды.",
		"Без 4 Такта колокол не звонит. Перезарядка 40 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Колокол ударил один раз, и все, кто его слышал, взялись за руки."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_DANCE
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_dance/bell

/datum/heretic_dance_style/tango
	unlock = /datum/eldritch_knowledge/dance_grasp

/datum/heretic_dance_style/tarantella
	unlock = /datum/eldritch_knowledge/spell/dance_drum

/datum/heretic_dance_style/cancan
	unlock = /datum/eldritch_knowledge/spell/dance_masquerade

/datum/heretic_dance_style/macabre
	unlock = /datum/eldritch_knowledge/spell/dance_bell

/datum/eldritch_knowledge/base_dance/proc/invite_block_reason(mob/living/user, atom/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/dance_invite)
	if(!can_use(user) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_capture_block_reason(user, target, DANCE_INVITE_CAPTURE)
	if(reason)
		return reason
	var/mob/living/victim = target
	var/datum/status_effect/heretic_dance_earworm/earworm = victim.has_status_effect(/datum/status_effect/heretic_dance_earworm)
	if(earworm?.dance_ref?.resolve() != src)
		return "Приглашение слышат только заражённые вашей мелодией: сначала схема шагов или Хватка в «Помощи»."
	if(!heretic_dance_can_hear(victim))
		return "[victim] не слышит музыку: глухота или наушники-заглушки."
	if(victim.has_status_effect(/datum/status_effect/heretic_dance/invited) || victim.has_status_effect(/datum/status_effect/heretic_dance/partner))
		return "[victim] уже танцует с вами."
	var/range = invite_range()
	if(!isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > range)
		return "Цель должна стоять на полу не дальше [range] клеток от вас."
	return null

/datum/eldritch_knowledge/base_dance/proc/invite_range()
	switch(style_id)
		if(HERETIC_DANCE_STYLE_TANGO)
			return HERETIC_DANCE_INVITE_TANGO_RANGE
		if(HERETIC_DANCE_STYLE_MACABRE)
			return HERETIC_DANCE_INVITE_MACABRE_RANGE
	return HERETIC_DANCE_INVITE_RANGE

/datum/eldritch_knowledge/base_dance/proc/invite(mob/living/user, mob/living/victim)
	dance_failure = invite_block_reason(user, victim)
	if(dance_failure)
		return FALSE
	last_combat_at = world.time
	if(!victim.apply_status_effect(/datum/status_effect/heretic_dance/invited, src, style_id))
		dance_failure = "Мелодия не подхватила [victim]."
		return FALSE
	to_chat(user, span_eldritch("Вы приглашаете [victim] на танец. Ждите: со следующей доли цель пойдёт к вам."))
	return TRUE

/// Фигура Вальса: соседний враг 4 секунды повторяет ваши шаги.
/datum/eldritch_knowledge/base_dance/proc/start_lead(mob/living/user)
	var/mob/living/partner
	for(var/mob/living/carbon/candidate in orange(1, user))
		if(!heretic_dance_can_sway(user, candidate) || heretic_capture_block_reason(user, candidate, DANCE_LEAD_CAPTURE))
			continue
		if(candidate.has_status_effect(/datum/status_effect/heretic_dance/partner) || !partner)
			partner = candidate
	if(!partner)
		return FALSE
	partner.remove_status_effect(/datum/status_effect/heretic_dance/partner)
	if(!partner.apply_status_effect(/datum/status_effect/heretic_dance/lead, src))
		return FALSE
	partner.visible_message(span_danger("[user] подхватывает [partner] в вальс, и [partner] кружится следом, шаг в шаг!"), span_userdanger("Вас подхватили в вальс: вы повторяете каждый шаг партнёра!"))
	log_combat(user, partner, "ведёт в вальсе")
	return TRUE

/// Фигура Канкана: ленты слепят соседей, еретик рывком проходит сквозь толпу.
/datum/eldritch_knowledge/base_dance/proc/cancan_dash(mob/living/user)
	for(var/mob/living/carbon/victim in orange(2, user))
		if(heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
			victim.blur_eyes(4)
			victim.confused = max(victim.confused, 2)
	new /obj/effect/temp_visual/heretic_dance/confetti(get_turf(user))
	user.pulledby?.stop_pulling()
	for(var/step_index in 1 to 3)
		var/turf/next = get_step(user, user.dir)
		if(!next || isgroundlessturf(next) || !heretic_tile_passable(next) || !heretic_step_open(get_turf(user), next))
			break
		new /obj/effect/temp_visual/decoy/fading(get_turf(user), user)
		user.forceMove(next)
	return TRUE

/datum/eldritch_knowledge/base_dance/proc/start_horovod(mob/living/user, time, limit, range)
	var/count = 0
	for(var/mob/living/carbon/victim in range(range, user))
		if(count >= limit)
			break
		if(!heretic_edge_line_clear(user, victim))
			continue
		if(victim.has_status_effect(/datum/status_effect/heretic_dance_horovod_rest) || victim.has_status_effect(/datum/status_effect/heretic_dance/horovod))
			continue
		if(!heretic_dance_can_sway(user, victim))
			continue
		if(victim.apply_status_effect(/datum/status_effect/heretic_dance/horovod, src, time))
			count++
			log_combat(user, victim, "втягивает в хоровод")
	if(count)
		new /obj/effect/temp_visual/heretic_dance/horovod(get_turf(user), user, time)
	return count > 0

/datum/eldritch_knowledge/base_dance/proc/toll_bell(mob/living/user, steps = 1)
	new /obj/effect/temp_visual/heretic_dance/bell(get_turf(user))
	playsound(user, HERETIC_DANCE_BELL_SOUND, 70, TRUE)
	for(var/datum/status_effect/heretic_dance_earworm/earworm as anything in earworms)
		var/mob/living/victim = earworm.owner
		if(victim.z != user.z || get_dist(victim, user) > HERETIC_DANCE_BELL_RANGE || !heretic_dance_can_sway(user, victim))
			continue
		victim.setDir(get_dir(victim, user))
		heretic_dance_hop(victim, TRUE, TRUE)
		for(var/step_index in 1 to steps)
			heretic_dance_step_toward(victim, user)

/datum/eldritch_knowledge/base_dance/proc/ring_bell(mob/living/user)
	if(!can_use(user))
		return FALSE
	if(combat_resource < HERETIC_DANCE_BELL_COST)
		dance_failure = "Колоколу нужно [HERETIC_DANCE_BELL_COST] Такта, сейчас [combat_resource]."
		return FALSE
	if(!start_horovod(user, HERETIC_DANCE_HOROVOD_TIME, INFINITY, HERETIC_DANCE_HOROVOD_RANGE))
		dance_failure = "Рядом нет никого, кого хоровод мог бы подхватить: лежачие, схваченные и глухие не пляшут."
		return FALSE
	spend_combat_resource(HERETIC_DANCE_BELL_COST)
	update_passive()
	last_combat_at = world.time
	new /obj/effect/temp_visual/heretic_dance/bell(get_turf(user))
	playsound(user, HERETIC_DANCE_BELL_SOUND, 80, TRUE)
	user.visible_message(span_danger("Где-то бьёт погребальный колокол, и все вокруг [user] берутся за руки в хоровод!"))
	return TRUE

/datum/eldritch_knowledge/base_dance/proc/start_masquerade(mob/living/user)
	if(!can_use(user, ignore_grab = TRUE))
		dance_failure = "Вы не можете действовать: дождитесь конца оглушения и выйдите на пол."
		return FALSE
	if(!QDELETED(masquerade))
		dance_failure = "Маскарад уже идёт."
		return FALSE
	var/accuracy = timing(user)
	var/time = HERETIC_DANCE_MASQUERADE_TIME + (accuracy != HERETIC_DANCE_MISS && last_timing_strong ? 2 SECONDS : 0)
	if(!user.apply_status_effect(/datum/status_effect/heretic_dance/masquerade, src, time))
		dance_failure = "Маски не легли."
		return FALSE
	last_combat_at = world.time
	log_game("[key_name(user)] начинает Маскарад в [AREACOORD(user)].")
	return TRUE

/datum/eldritch_knowledge/base_dance/proc/drum_pulse(mob/living/user)
	var/accuracy = timing(user)
	var/datum/heretic_dance_style/style = current_style()
	playsound(user, pick('modular_bluemoon/sound/heretic/dance/drum_1.ogg', 'modular_bluemoon/sound/heretic/dance/drum_2.ogg', 'modular_bluemoon/sound/heretic/dance/drum_3.ogg'), 70, TRUE)
	new /obj/effect/temp_visual/heretic_dance/ring(get_turf(user), accuracy == HERETIC_DANCE_PERFECT)
	var/list/hearts = list()
	for(var/datum/status_effect/heretic_dance_earworm/earworm as anything in earworms.Copy())
		var/mob/living/victim = earworm.owner
		if(victim.z != user.z || get_dist(victim, user) > HERETIC_DANCE_DRUM_RANGE || !heretic_dance_can_hear(victim) || !heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
			continue
		hearts += victim
		if(accuracy == HERETIC_DANCE_MISS)
			victim.adjustStaminaLoss(5)
			continue
		style.accent(src, user, victim, 0.5)
	if(accuracy != HERETIC_DANCE_MISS)
		last_combat_at = world.time
		beat_fx(user, accuracy)
	show_heartbeats(user, hearts)
	return TRUE

/datum/eldritch_knowledge/base_dance/proc/show_heartbeats(mob/living/user, list/hearts)
	if(!user.client || !length(hearts))
		return
	var/list/image/shown = list()
	for(var/mob/living/victim as anything in hearts)
		var/image/heart = image('modular_bluemoon/icons/obj/heretic_dance_marks.dmi', victim, "dance_note", ABOVE_LIGHTING_LAYER)
		heart.plane = ABOVE_LIGHTING_PLANE
		heart.appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
		shown += heart
	user.client.images |= shown
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dance_hide_images), WEAKREF(user), shown), DANCE_HEARTBEAT_TIME)

/proc/heretic_dance_hide_images(datum/weakref/user_ref, list/image/shown)
	var/mob/living/user = user_ref?.resolve()
	user?.client?.images -= shown

/obj/effect/temp_visual/heretic_dance/horovod
	icon_state = "dance_horovod"
	duration = 5 SECONDS
	var/datum/weakref/leader_ref

/obj/effect/temp_visual/heretic_dance/horovod/Initialize(mapload, mob/living/leader, time)
	if(time)
		duration = time
	. = ..()
	if(!leader)
		return
	leader_ref = WEAKREF(leader)
	RegisterSignal(leader, COMSIG_MOVABLE_MOVED, PROC_REF(follow_leader))

/obj/effect/temp_visual/heretic_dance/horovod/proc/follow_leader(atom/movable/source)
	SIGNAL_HANDLER
	var/turf/place = get_turf(source)
	if(place)
		forceMove(place)

/obj/effect/temp_visual/heretic_dance/horovod/Destroy()
	var/mob/living/leader = leader_ref?.resolve()
	if(leader)
		UnregisterSignal(leader, COMSIG_MOVABLE_MOVED)
	leader_ref = null
	return ..()

/obj/effect/proc_holder/spell/self/heretic_dance
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_dance/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dance/dance = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dance)
	return ..() && heretic_check(user, dance?.can_use(user, ignore_grab = usable_while_grabbed), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_dance/proc/dance_of(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_dance)

/obj/effect/proc_holder/spell/self/heretic_dance/style
	name = "Сменить стиль"
	desc = "Выберите танец из выученных. Смена в сильную долю сохраняет Такт и удваивает следующий акцент. Выбранный мимо неё стиль вступит на следующей сильной доле без потерь; выбор его ещё раз меняет сразу, деля Такт пополам."
	summary = "Выбор танца; в сильную долю - связка, мимо - вступит со следующей сильной доли."
	action_icon_state = "dance_style"
	charge_max = 1 SECONDS
	usable_while_grabbed = TRUE

/obj/effect/proc_holder/spell/self/heretic_dance/style/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dance/dance = dance_of(user)
	if(!dance?.open_style_menu(user))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_dance/drum
	name = "Ударить в барабан"
	desc = "Ударьте в барабан из кожи, если он у вас в руке, кармане или сумке. Раз в 4 доли: заражённые в 7 клетках получают ослабленный акцент стиля, а вы видите их сердца сквозь стены. Вне доли - только сердцебиение и 5 выносливости."
	summary = "Барабан из руки или кармана: ослабленный акцент стиля по заражённым в 7 клетках."
	action_icon_state = "dance_drum"
	charge_max = 1 SECONDS

/obj/effect/proc_holder/spell/self/heretic_dance/drum/cast(list/targets, mob/living/user)
	var/obj/item/heretic_path_relic/dance/drum = locate() in user.GetAllContents()
	if(!drum)
		heretic_revert_cast(user, "Барабана из кожи нет при вас.")
		return
	if(!drum.beat(user))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_dance/masquerade
	name = "Маскарад"
	desc = "На 6 секунд вы и до 4 заражённых в 7 клетках выглядите одинаковыми танцорами в масках, имена скрыты. Заражённые под масками переминаются каждую долю. Вы вырываетесь из хватки и становитесь быстрее. Попадание разбивает маску. В сильную долю маскарад длится 8 секунд. Перезарядка 60 секунд."
	summary = "6 секунд вы и до 4 заражённых - одинаковые танцоры в масках."
	action_icon_state = "dance_masquerade"
	charge_max = HERETIC_DANCE_MASQUERADE_COOLDOWN
	usable_while_grabbed = TRUE

/obj/effect/proc_holder/spell/self/heretic_dance/masquerade/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dance/dance = dance_of(user)
	if(!dance?.start_masquerade(user))
		heretic_revert_cast(user, dance?.dance_failure)

/obj/effect/proc_holder/spell/self/heretic_dance/bell
	name = "Колокол"
	desc = "За 4 Такта враги в 3 клетках 5 секунд повторяют каждый ваш шаг и теряют 6 выносливости за шаг, всего не больше 42. Лежачих, сидящих, пристёгнутых, схваченных, глухих, в заглушках и под защитой от магии хоровод не берёт. Перезарядка 40 секунд."
	summary = "За 4 Такта враги в 3 клетках 5 секунд повторяют ваши шаги."
	action_icon_state = "dance_bell"
	charge_max = HERETIC_DANCE_BELL_COOLDOWN

/obj/effect/proc_holder/spell/self/heretic_dance/bell/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dance/dance = dance_of(user)
	if(!dance?.ring_bell(user))
		heretic_revert_cast(user, dance?.dance_failure)

/obj/effect/proc_holder/spell/pointed/heretic_dance/invite
	name = "Приглашение"
	desc = "Заражённый человек, который слышит музыку, против воли идёт к вам шаг в долю: в Вальсе, Тарантелле и Канкане из 7 клеток, в Танго одним рывком из 3, в Пляске смерти медленно из 12. Дошедший 4 секунды остаётся вашим партнёром. Схватить, повалить, пристегнуть, растолкать, заглушки, нулевой жезл и святая вода срывают танец. Перезарядка 45 секунд."
	summary = "Заражённый идёт к вам шаг в долю и становится партнёром."
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "dance_invite"
	action_background_icon_state = "bg_ecult"
	range = HERETIC_DANCE_INVITE_MACABRE_RANGE
	selection_type = "range"
	aim_assist = FALSE
	charge_max = HERETIC_DANCE_INVITE_COOLDOWN
	active_msg = "Укажите заражённого, которого пригласите на танец."
	deactive_msg = "Музыка стихает."

/obj/effect/proc_holder/spell/pointed/heretic_dance/invite/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dance/dance = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/reason = dance ? dance.invite_block_reason(user, target) : "Способность недоступна вашему пути."
	return heretic_check(user, !reason, silent, reason, target = target)

/obj/effect/proc_holder/spell/pointed/heretic_dance/invite/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dance/dance = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dance)
	if(!length(targets) || !isliving(targets[1]) || !dance?.invite(user, targets[1]))
		heretic_revert_cast(user, dance?.dance_failure)

#undef DANCE_GRASP_STAMINA
#undef DANCE_BLADE_LIFESTEAL
#undef DANCE_BLADE_CHAIN
#undef DANCE_HEARTBEAT_TIME
#undef DANCE_LEAD_CAPTURE
#undef DANCE_INVITE_CAPTURE
