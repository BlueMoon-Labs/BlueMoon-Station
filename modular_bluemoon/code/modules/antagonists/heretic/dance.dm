#define HERETIC_DANCE_DIAGRAM_CRAFT "dance_diagram"
#define HERETIC_DANCE_DIAGRAM_CLUE "Кто-то расчертил пол медными следами босых ног, как в старом самоучителе танцев. Пахнет медью. Швабра, мыло или нулевой жезл сотрут схему."
#define HERETIC_DANCE_COLOR "#c8553d"

/datum/heretic_path/dance
	id = PATH_DANCE
	deed_type = /datum/heretic_deed/dance
	name = "Пляска"
	tagline = "Бьёт в долю, меняет пять танцев и заводит заражённый экипаж в пляску до изнеможения."
	craft_summary = "Хватка в «Помощи» по полу рисует схему шагов: кто по ней пройдёт, подхватит навязчивый такт."
	capture_summary = "Приглашение ведёт заражённого к вам шаг в долю; дошедшего партнёра сердце уводит в изнанку."
	escape_summary = "Маскарад на 6 секунд прячет вас среди одинаковых танцоров в масках; из изнанки выходите к схеме."
	strength_points = list(
		"Любой удар копит Такт, а удар в долю копит больше: скилл заметно усиливает путь, но не обязателен.",
		"Пять стилей со своими пассивками, акцентами в сильную долю и фигурами из шагов.",
		"Приглашение тянет заражённого из толпы к вам, пока вы ждёте за углом.",
		"Маскарад делает вас и до 4 заражённых одинаковыми танцорами в масках.",
		"Пляска смерти заставляет толпу зеркалить ваши шаги и выматывает её.",
		"Номер - две фигуры через связку - захватывает, решает дуэль, держит толпу или уводит от погони; раз в 30 с.",
	)
	weakness_points = list(
		"Наушники-заглушки и глухота закрывают от Приглашения, Колокола и барабана.",
		"Дефибриллятор, сон, святая вода и нулевой жезл лечат навязчивый такт.",
		"Схемы шагов видны всем и стираются шваброй или мылом.",
		"Вне боя Такт быстро тает, а смена стиля мимо сильной доли ждёт следующей или делит его пополам.",
		"Вознёсшегося сбивает фальшивая нота: светошумовая, клаксон или горн рядом; пока Болеро молчит, бола держит.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_dance,
		/datum/eldritch_knowledge/dance_grasp,
		/datum/eldritch_knowledge/spell/dance_invite,
		/datum/eldritch_knowledge/dance_mark,
		/datum/eldritch_knowledge/spell/dance_drum,
		/datum/eldritch_knowledge/dance_blade_upgrade,
		/datum/eldritch_knowledge/spell/dance_masquerade,
		/datum/eldritch_knowledge/dance_heart,
		/datum/eldritch_knowledge/spell/dance_bell,
		/datum/eldritch_knowledge/final_eldritch/dance_final,
	)

/datum/eldritch_knowledge/base_dance
	name = "Первый такт"
	summary = "Главное - бить клинком, когда кольцо у ног сомкнётся. Даёт клинок-шпильку, Вальс и схемы шагов."
	details = list(
		"Начните с ударов: бейте, когда кольцо у ног сомкнётся. Любой удар даёт Такт, в долю - 2, точно - 3.",
		"Двойное кольцо и «1» на барабане справа - сильная доля: удар в неё даёт акцент стиля. Пинг до 0,3 секунды учтён.",
		"Нож и пара любой обуви на руне дают клинок «Алая шпилька».",
		"Хватка в любом намерении заражает человека (до 6, на 6 минут); в «Помощи» по полу рисует схему шагов (до 5).",
		"Фигура: пока играет музыка, идите на каждой доле туда, куда ведёт медный след. Клавишу можно не отпускать.",
		"Пропущенная доля начинает фигуру заново, один сбой после двух верных шагов прощается. Фигура без цели ждёт 4 доли.",
		"Смена стиля в сильную долю - связка: вход стиля и двойной акцент; три стиля за 20 секунд - Попурри.",
	)
	role = HERETIC_ROLE_CRAFT
	ritual_hint = "Подойдёт любая обувь, даже снятая с себя: положите её и нож на руну."
	gain_text = "Музыка началась задолго до меня. Я просто наконец услышал, что под неё можно двигаться."
	route = PATH_DANCE
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/clothing/shoes)
	result_atoms = list(/obj/item/melee/sickly_blade/dance)
	combat_resource = 0
	combat_resource_max = HERETIC_DANCE_TAKT_MAX
	combat_resource_name = "Такт"
	resource_rules = list(
		"Такт от 0 до 10: удар клинком или Хваткой по разумному врагу даёт 1 (раз в секунду), в долю - 2, точно - 3.",
		"С 4 Такта работает пассивка стиля, а каждый Такт сверх 4 добавляет удару клинком в долю 1 урон.",
		"Через 4 секунды без боя Такт тает по единице в секунду.",
		"Смена стиля в сильную долю сохраняет Такт и удваивает следующий акцент. Выбранный мимо неё стиль вступит на следующей сильной доле без потерь; повторный выбор меняет сразу, деля Такт пополам.",
		"Колокол тратит 4 Такта. Смерть и смена тела обнуляют Такт.",
	)
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_dance/style
	grasp_visual = /obj/effect/temp_visual/heretic_dance/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/dance_grasp.ogg'
	grasp_catchphrase = "SAL'TA DO'MOR"
	var/mob/living/dance_body
	var/style_id = HERETIC_DANCE_STYLE_WALTZ
	var/beat_ds = 8.5
	var/meter = 3
	var/beat_origin = 0
	var/beat_index = -1
	/// Доли подряд без сброса сменой стиля: по ним считаются перезарядки в долях.
	var/beat_total = 0
	var/beat_timer
	var/bar_world_start = 0
	var/bar_real_start = 0
	var/lag_grace_until = -1
	var/last_timing_strong = FALSE
	var/last_timing_beat = 0
	var/last_timing_early = FALSE
	var/pending_style_id
	var/previous_style_id
	var/music_channel
	var/link_bonus = FALSE
	var/passive_active = FALSE
	var/last_combat_at = -INFINITY
	var/decay_progress = 0
	var/list/figure_steps = list()
	var/last_step_beat = -1
	/// Направление доли last_step_beat записано в figure_steps, а не прощено.
	var/last_step_kept = FALSE
	var/figure_ready_beat = 0
	/// Собранная фигура без цели ждёт её до этой доли (по beat_total); -1 - не ждёт.
	var/held_figure_until = -1
	var/held_figure_style
	/// Одна ошибка шага на фигуру прощается: уклонение не рвёт весь рисунок.
	var/figure_slip_used = FALSE
	var/datum/weakref/last_struck
	var/last_phrase = 0
	/// Следующий такт начнёт музыку заново вступлением: после смены стиля или тишины.
	var/music_entry = TRUE
	var/phrase_step = 0
	var/datum/weakref/bite_target
	var/bite_chain = 0
	var/lunge_until = 0
	var/pending_accuracy = HERETIC_DANCE_MISS
	var/pending_strong = FALSE
	var/pending_at = -1
	/// Мобы, которые сейчас в танце еретика и слышат его музыку.
	var/list/mob/living/dancers = list()
	var/list/obj/effect/heretic_dance_diagram/diagrams = list()
	var/list/datum/status_effect/heretic_dance_earworm/earworms = list()
	var/list/datum/status_effect/heretic_dance/invited/invites = list()
	var/datum/atom_hud/alternate_appearance/basic/heretic_dance_skeleton/skeleton
	var/datum/status_effect/heretic_dance/masquerade/masquerade
	var/dance_failure
	COOLDOWN_DECLARE(takt_hit_gap)

/datum/eldritch_knowledge/base_dance/on_gain(mob/user)
	. = ..()
	var/datum/antag_training_session/session = GLOB.antag_training_sessions[user?.ckey]
	if(session?.current_body == user && !session.dance_lesson)
		to_chat(user, span_notice("Для Пляски на полигоне есть пошаговый урок: панель полигона, вкладка «Начать», раздел «2. Упражнение», кнопка «Урок Пляски»."))

/datum/eldritch_knowledge/base_dance/on_body_gain(mob/living/user)
	if(!user?.mind || dance_body == user)
		return
	if(dance_body)
		on_body_lose(dance_body)
	dance_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_body_moved))
	grant_combat_power(user)
	apply_tempo()
	restart_clock()
	update_style_status()
	update_ghosts()

/datum/eldritch_knowledge/base_dance/on_body_lose(mob/living/user)
	if(dance_body)
		UnregisterSignal(dance_body, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
		set_passive(FALSE)
		hide_aura()
		dance_body.remove_status_effect(/datum/status_effect/heretic_dance_style)
		dance_body.clear_alert("heretic_dance_beat")
		dance_body.vis_contents -= bolero_ghosts
		clear_hints()
	QDEL_LIST(bolero_ghosts)
	stop_clock()
	clear_dance()
	dance_body = null
	passive_active = FALSE
	combat_resource = 0
	remove_combat_power()
	notify_resource_changed()

/datum/eldritch_knowledge/base_dance/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(dance_body)

/datum/eldritch_knowledge/base_dance/proc/on_body_moved(atom/movable/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	if(forced || !isturf(old_loc) || !isturf(source.loc))
		return
	if(bolero_on)
		new /obj/effect/temp_visual/heretic_dance/parquet(old_loc)
	on_dance_step(dance_body, movement_dir || get_dir(old_loc, source.loc), old_loc)

/datum/eldritch_knowledge/base_dance/on_death(mob/user)
	set_passive(FALSE)
	clear_dance()
	clear_hints()
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_dance/Destroy()
	on_body_lose(dance_body)
	for(var/obj/effect/heretic_dance_diagram/diagram as anything in diagrams.Copy())
		qdel(diagram)
	diagrams.Cut()
	QDEL_LIST(earworms)
	if(music_channel)
		SSsounds.free_sound_channel(music_channel)
		music_channel = null
	return ..()

/// Снимает всё, что держится на живом танце: партнёров, приглашения, хоровод, маскарад и скелет.
/datum/eldritch_knowledge/base_dance/proc/clear_dance()
	QDEL_LIST(invites)
	QDEL_NULL(masquerade)
	hide_skeleton()
	for(var/mob/living/dancer as anything in dancers.Copy())
		for(var/datum/status_effect/heretic_dance/effect in dancer.status_effects)
			if(effect.dance_ref?.resolve() == src)
				qdel(effect)
	dancers.Cut()
	figure_steps.Cut()
	held_figure_until = -1
	link_bonus = FALSE
	lunge_until = 0
	pending_style_id = null
	routine_from = null
	armed_routine = null

/datum/eldritch_knowledge/base_dance/proc/can_use(mob/living/user, allow_incapacitated = FALSE, ignore_grab = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && user && user == dance_body && user.stat != DEAD && (allow_incapacitated || !user.incapacitated(ignore_grab = ignore_grab)) && isturf(user.loc) && heretic?.selected_path == PATH_DANCE && !heretic.role_removed && heretic.get_knowledge(type) == src

/datum/eldritch_knowledge/base_dance/combat_resource_state()
	var/datum/heretic_dance_style/style = current_style()
	. = "Стиль: [style.name][passive_active ? " (пассивка работает)" : ""]. Схем шагов: [length(diagrams)] из [HERETIC_DANCE_DIAGRAM_LIMIT], заражённых: [length(earworms)] из [HERETIC_DANCE_EARWORM_LIMIT]."
	if(link_bonus)
		. += " Следующий акцент удвоен связкой."

/datum/eldritch_knowledge/base_dance/proc/add_dancer(mob/living/dancer)
	if(!istype(dancer) || (dancer in dancers))
		return
	dancers += dancer

/datum/eldritch_knowledge/base_dance/proc/remove_dancer(mob/living/dancer)
	for(var/datum/status_effect/heretic_dance/effect in dancer?.status_effects)
		if(effect.dance_ref?.resolve() == src && !QDELETED(effect))
			return
	dancers -= dancer

/// Клинок передаёт точность удара до нанесения урона: доля считается по моменту клика.
/datum/eldritch_knowledge/base_dance/proc/prime_strike(mob/living/user)
	pending_accuracy = timing(user)
	pending_strong = last_timing_strong
	pending_at = world.time

/datum/eldritch_knowledge/base_dance/on_eldritch_blade_damage(mob/living/target, mob/living/user, strike_damage)
	if(pending_at != world.time)
		prime_strike(user)
	register_strike(user, target, pending_accuracy, pending_strong, TRUE)
	pending_at = -1

/datum/eldritch_knowledge/base_dance/on_mark_detonated(mob/living/user, mob/living/target)
	if(!can_use(user) || QDELETED(target))
		return
	gain_takt(1)
	var/datum/heretic_dance_style/style = current_style()
	style.accent(src, user, target, 2)
	accent_fx(user, target, style)

/datum/eldritch_knowledge/base_dance/on_ranged_attack_eldritch_blade(atom/target, mob/user, click_parameters)
	if(lunge_until < world.time || !isliving(target) || !can_use(user))
		return
	var/turf/here = get_turf(user)
	var/turf/there = get_turf(target)
	if(!here || !there || here.z != there.z || get_dist(here, there) != 2 || !heretic_edge_line_clear(here, there))
		return
	if(!heretic_dance_step_toward(user, target) || !user.Adjacent(target))
		return
	lunge_until = 0
	var/obj/item/melee/sickly_blade/dance/blade = user.get_active_held_item()
	if(istype(blade))
		user.visible_message(span_danger("[user] делает стремительный выпад к [target]!"))
		blade.melee_attack_chain(user, target, click_parameters)

/datum/eldritch_knowledge/base_dance/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_failure_reason = null
	if(!can_use(user) || QDELETED(target) || !proximity_flag)
		return FALSE
	var/accuracy = timing(user)
	var/strong = last_timing_strong
	if(user.a_intent == INTENT_HELP)
		if(isopenturf(target))
			return draw_diagram(user, target)
		if(ishuman(target) && user.Adjacent(target))
			return infect(user, target, TRUE)
		return FALSE
	if(!isliving(target) || !user.Adjacent(target) || !heretic_can_affect(user, target, chargecost = 0, notify = FALSE))
		return FALSE
	register_strike(user, target, accuracy, strong)
	var/mob/living/victim = target
	var/fresh = ishuman(victim) && !victim.has_status_effect(/datum/status_effect/heretic_dance_earworm)
	if(ishuman(victim) && infect(user, victim) && fresh)
		to_chat(user, span_eldritch("Хватка оставила в голове [victim] вашу мелодию. Заражённых: [length(earworms)] из [HERETIC_DANCE_EARWORM_LIMIT]."))
	return FALSE

/// Навязчивый такт на человеке: сам по себе безвреден, но открывает его Приглашению, Колоколу и барабану.
/datum/eldritch_knowledge/base_dance/proc/infect(mob/living/user, mob/living/carbon/human/victim, by_hand = FALSE)
	if(!istype(victim) || QDELETED(victim) || victim.stat == DEAD || !victim.mind || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
		if(by_hand)
			grasp_failure_reason = "Навязчивый такт подхватывают только живые люди с разумом."
		return FALSE
	if(!heretic_can_affect(user || dance_body, victim, chargecost = 0))
		if(by_hand)
			grasp_failure_reason = "[victim] под защитой от магии: мелодия не цепляется."
		return FALSE
	var/datum/status_effect/heretic_dance_earworm/existing = victim.has_status_effect(/datum/status_effect/heretic_dance_earworm)
	if(existing)
		if(existing.dance_ref?.resolve() != src)
			if(by_hand)
				grasp_failure_reason = "В голове [victim] уже звучит чужая мелодия."
			return FALSE
		existing.refresh_duration()
		if(by_hand)
			to_chat(user, span_eldritch("Мелодия в голове [victim] зазвучала заново: ещё [DisplayTimeText(HERETIC_DANCE_EARWORM_DURATION)]."))
		return TRUE
	while(length(earworms) >= HERETIC_DANCE_EARWORM_LIMIT)
		var/datum/status_effect/heretic_dance_earworm/oldest = earworms[1]
		earworms -= oldest
		qdel(oldest)
	var/datum/status_effect/heretic_dance_earworm/earworm = victim.apply_status_effect(/datum/status_effect/heretic_dance_earworm, src)
	if(!earworm)
		return FALSE
	if(by_hand)
		user.visible_message(span_notice("[user] легко касается плеча [victim], будто приглашая на танец."), span_eldritch("Мелодия перешла к [victim]. Заражённых: [length(earworms)] из [HERETIC_DANCE_EARWORM_LIMIT]."))
	log_combat(user || dance_body, victim, "заражает навязчивым тактом")
	notify_resource_changed()
	SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "infect", victim, by_hand)
	return TRUE

/datum/eldritch_knowledge/base_dance/proc/draw_diagram(mob/living/user, turf/place)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !istype(place))
		return FALSE
	if(locate(/obj/effect/heretic_dance_diagram) in place)
		grasp_failure_reason = "Здесь уже расчерчена схема шагов."
		return FALSE
	if(isgroundlessturf(place) || place.is_blocked_turf(exclude_mobs = TRUE) || !user.Adjacent(place))
		grasp_failure_reason = "Схема шагов ложится только на свободный пол рядом с вами."
		return FALSE
	var/counts_for_deed = is_station_level(place.z)
	var/deed_key = heretic.deed_key_for(place)
	var/wait = counts_for_deed ? heretic.deed_wait_reason(deed_key) : "Это вне станции: схема заражает, но в дело не идёт."
	while(length(diagrams) >= HERETIC_DANCE_DIAGRAM_LIMIT)
		var/obj/effect/heretic_dance_diagram/oldest = diagrams[1]
		log_game("[key_name(user)] теряет схему шагов в [AREACOORD(oldest)]: её вытеснила новая.")
		diagrams -= oldest
		qdel(oldest)
	var/obj/effect/heretic_dance_diagram/diagram = new(place, src, style_id)
	playsound(place, 'modular_bluemoon/sound/heretic/dance_grasp.ogg', 40, TRUE)
	to_chat(user, span_eldritch("Схема «[diagram.style_name]» расчерчена. Схем: [length(diagrams)] из [HERETIC_DANCE_DIAGRAM_LIMIT].[wait ? " [wait]" : ""]"))
	log_game("[key_name(user)] рисует схему шагов Пляски в [AREACOORD(place)].")
	if(!wait)
		heretic.advance_deed(deed_key, place)
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_dance/on_craft_removed(atom/crafted, craft_id)
	if(craft_id != HERETIC_DANCE_DIAGRAM_CRAFT)
		return
	diagrams -= crafted
	if(!QDELETED(crafted))
		qdel(crafted)
	notify_resource_changed()

/datum/eldritch_knowledge/base_dance/pocket_exits(mob/living/user)
	. = list()
	for(var/obj/effect/heretic_dance_diagram/diagram as anything in diagrams)
		heretic_add_pocket_exit(., "Схема шагов - [get_area_name(diagram, TRUE)]", heretic_pocket_landing(get_turf(diagram)))

/datum/eldritch_knowledge/base_dance/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	return list("name" = "в вальс", "text" = "[user] подхватывает [victim] за руку, и оба исчезают в вихре алых лент.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))

/// Цель - партнёр еретика после Приглашения или ведомая фигурой Вальса, еретик вплотную.
/datum/eldritch_knowledge/base_dance/proc/door_holds(mob/living/user, mob/living/victim)
	if(!can_use(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > 1)
		return FALSE
	for(var/datum/status_effect/heretic_dance/effect in victim.status_effects)
		if(effect.dance_ref?.resolve() == src && effect.opens_door)
			return TRUE
	return knocked_out_by_capture(victim)

/obj/effect/heretic_dance_diagram
	name = "dance steps"
	desc = "Медные следы босых ног выстроены в схему танцевальных шагов."
	icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi'
	icon_state = "dance_diagram_waltz"
	anchored = TRUE
	layer = TURF_DECAL_LAYER
	plane = FLOOR_PLANE
	var/datum/weakref/dance_ref
	var/style_name = "Вальс"
	var/charges = HERETIC_DANCE_DIAGRAM_CHARGES

/obj/effect/heretic_dance_diagram/Initialize(mapload, datum/eldritch_knowledge/base_dance/dance, style_id)
	. = ..()
	var/datum/heretic_dance_style/style = GLOB.heretic_dance_styles[style_id]
	if(style)
		icon_state = "dance_diagram_[style.id]"
		style_name = style.name
	if(!dance)
		return
	dance_ref = WEAKREF(dance)
	dance.diagrams += src
	AddComponent(/datum/component/heretic_craft, dance, HERETIC_DANCE_DIAGRAM_CRAFT, HERETIC_DANCE_DIAGRAM_CLUE)
	RegisterSignal(src, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(on_cleaned))
	AddElement(/datum/element/connect_loc, list(COMSIG_ATOM_ENTERED = PROC_REF(on_entered)))

/obj/effect/heretic_dance_diagram/Destroy()
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	dance?.diagrams -= src
	dance_ref = null
	return ..()

/obj/effect/heretic_dance_diagram/proc/on_cleaned(datum/source, strength)
	SIGNAL_HANDLER
	visible_message(span_notice("Медные следы стираются с пола."))
	qdel(src)

/obj/effect/heretic_dance_diagram/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	var/mob/living/carbon/human/walker = arrived
	if(!dance || !istype(walker) || walker.stat != CONSCIOUS || !walker.mind || IS_HERETIC(walker) || IS_HERETIC_MONSTER(walker))
		return
	if(walker.has_status_effect(/datum/status_effect/heretic_dance_earworm))
		return
	if(!dance.infect(null, walker))
		return
	to_chat(walker, span_warning("Ступни сами попадают в медные следы, и в голове начинает звучать мелодия."))
	if(--charges <= 0)
		fade()

/obj/effect/heretic_dance_diagram/proc/fade()
	new /obj/effect/temp_visual/heretic_dance_diagram_fade(get_turf(src))
	qdel(src)

/obj/effect/temp_visual/heretic_dance_diagram_fade
	icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi'
	icon_state = "dance_diagram_fade"
	duration = 1 SECONDS
	randomdir = FALSE
	layer = TURF_DECAL_LAYER
	plane = FLOOR_PLANE

/datum/heretic_deed/dance
	next_step = "В намерении «Помощь» коснитесь Хваткой Мансуса свободного пола в отделе, которого ещё нет в деле."
	name = "Танцплощадки"
	desc = "Рисуйте Хваткой Мансуса в намерении «Помощь» схемы танцевальных шагов на полу разных отделов. Каждый отдел засчитывается один раз."
	craft_wait_place = "схему в новом отделе"
	craft_wait = "не расчертить"
	hint = "Держатся 5 схем, новая стирает самую старую. Кто пройдёт по схеме, подхватит навязчивый такт; после трёх заражений схема блёкнет. Швабра, мыло и нулевой жезл стирают схемы."
	trace_name = "copper footprints"
	trace_desc = "Медные следы босых ног кружат на месте, будто кто-то танцевал здесь всю ночь."
	trace_state = "sigil_dance"

/obj/item/melee/sickly_blade/dance
	name = "scarlet stiletto"
	desc = "Длинный тонкий стилет. Гарда - крошечная алая туфелька на каблуке, с неё свисает лента. Клинок вздрагивает в такт музыке, которой никто не слышит."
	icon = 'modular_bluemoon/icons/obj/heretic_dance.dmi'
	icon_state = "dance_blade"
	item_state = "dance_blade"
	route = PATH_DANCE
	mark_type = /datum/status_effect/eldritch/dance

/obj/item/melee/sickly_blade/dance/attack(mob/living/target, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dance/dance = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dance)
	dance?.prime_strike(user)
	return ..()

/obj/item/heretic_path_relic/dance
	name = "drum of flayed skin"
	desc = "Ручной барабан с медным ободом. Натянутая кожа ещё тёплая и зашита грубыми стежками. Удар раз в 4 доли отыгрывает акцент текущего стиля по всем заражённым в 7 клеткам, которые слышат, и на 3 секунды показывает их сердцебиение сквозь стены; вне доли - вполсилы."
	icon = 'modular_bluemoon/icons/obj/heretic_dance.dmi'
	icon_state = "dance_relic"
	item_state = "dance_relic"
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_relics_dance_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_relics_dance_righthand.dmi'
	var/ready_beat = 0

/obj/item/heretic_path_relic/dance/attack_self(mob/living/user)
	return beat(user)

/// Барабан бьёт и из кармана или сумки: руки на него не нужны.
/obj/item/heretic_path_relic/dance/proc/carried_by_owner(mob/living/user)
	if(QDELETED(src) || !isliving(user) || !user.mind || user.mind != creator?.resolve() || user.incapacitated() || !(src in user.GetAllContents()))
		return FALSE
	var/datum/eldritch_knowledge/knowledge = knowledge_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return knowledge && heretic?.get_knowledge(knowledge.type) == knowledge

/obj/item/heretic_path_relic/dance/proc/beat(mob/living/user)
	if(!carried_by_owner(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dance/dance = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dance)
	if(!dance?.can_use(user))
		return FALSE
	var/pressed_beat = dance.timed_beat_total(dance.timing(user))
	if(pressed_beat < ready_beat)
		to_chat(user, span_warning("Кожа ещё гудит от прошлого удара: до следующего долей: [ready_beat - pressed_beat]."))
		return FALSE
	ready_beat = pressed_beat + HERETIC_DANCE_DRUM_BEATS
	flick("dance_relic_beat", src)
	dance.drum_pulse(user)
	return TRUE

#undef HERETIC_DANCE_DIAGRAM_CRAFT
#undef HERETIC_DANCE_DIAGRAM_CLUE
#undef HERETIC_DANCE_COLOR
