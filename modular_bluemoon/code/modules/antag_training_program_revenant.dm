#define ANTAG_TRAINING_REVENANT_LAMPS 3
#define ANTAG_TRAINING_REVENANT_LAMP_RANGE 2

/datum/antag_training_program/creature/revenant
	name = "Ревенант"
	category = "Существа"
	desc = "Тело ревенанта в тёмном секторе: невидимость, полёт сквозь стены, жатва эссенции, открытие и применение способностей, сборка из эктоплазмы после смерти без опроса призраков."
	icon = "ghost"
	color = "blue"
	learn = "Невидимость и полёт сквозь стены|Жатва эссенции|Открытие способностей|Сборка из эктоплазмы"
	difficulty = 2
	sector = "dark"
	mob_type = /mob/living/simple_animal/revenant/training
	antag_type = /datum/antagonist/revenant/training
	options = list("Эссенция до максимума", "Цель для жатвы", "Лампы для перегрузки")

/datum/antag_training_program/creature/revenant/New()
	. = ..()
	var/obj/effect/proc_holder/spell/aoe_turf/revenant/malfunction/priciest = /obj/effect/proc_holder/spell/aoe_turf/revenant/malfunction
	var/obj/effect/proc_holder/spell/aoe_turf/revenant/overload/overload = /obj/effect/proc_holder/spell/aoe_turf/revenant/overload
	option_hints = list(
		"Эссенция до максимума" = "Эссенция до предела и запас украденной эссенции на открытие любой способности (дороже всех - [initial(priciest.name)] за [initial(priciest.unlock_amount)]). Снимает раскрытие, оглушение и подавление, сбрасывает задержки способностей, а выпитые души снова можно жать. В раунде эссенция сама растёт только до предела, а способности открываются лишь украденной.",
		"Цель для жатвы" = "Рядом встанет манекен в критическом состоянии. Подлетите вплотную и кликните по нему: жатва длится несколько секунд, раскрывает и обездвиживает вас. Живая душа даёт больше эссенции и поднимает её предел, труп - меньше, а человек в сознании не поддаётся. В безопасном центре и переходах кнопка не работает.",
		"Лампы для перегрузки" = "Вокруг вас загорятся напольные лампы ([ANTAG_TRAINING_REVENANT_LAMPS] шт.): [initial(overload.name)] бьёт током людей рядом с горящими лампами. В тёмном секторе своих ламп нет. Лампы идут в лимит построек и убираются очисткой своих объектов.",
	)

/datum/antag_training_program/creature/revenant/refill(mob/living/simple_animal/revenant/training/body)
	body.fully_heal(TRUE)
	body.death_reset()
	body.drained_mobs.Cut()
	var/priciest_unlock = 0
	for(var/obj/effect/proc_holder/spell/power as anything in body.mob_spell_list)
		power.charge_counter = power.charge_max
		power.recharging = FALSE
		if(istype(power, /obj/effect/proc_holder/spell/aoe_turf/revenant))
			var/obj/effect/proc_holder/spell/aoe_turf/revenant/locked_power = power
			priciest_unlock = max(priciest_unlock, locked_power.unlock_amount)
	body.essence_excess = max(body.essence_excess, priciest_unlock + 1)
	body.update_spooky_icon()
	body.update_action_buttons_icon()

/datum/antag_training_program/creature/revenant/body_lost(datum/antag_training_session/session)
	var/mob/living/simple_animal/revenant/training/body = session.current_body
	if(!istype(body) || QDELETED(body) || body != body_ref?.resolve() || session.finished || session.resetting || session.arena?.resetting)
		return ..()
	if(!body.stasis)
		return TRUE
	var/obj/item/ectoplasm/revenant/training/residue = body.residue_ref?.resolve()
	if(QDELETED(residue) || !residue.reform(creature_spawn_turf(session)))
		return ..()
	refill(body)
	to_chat(body, span_notice("Вы собрались из эктоплазмы в центре сектора с полной эссенцией. Можно продолжать тренировку."))
	return TRUE

/datum/antag_training_program/creature/revenant/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/mob/living/simple_animal/revenant/training/body = user
	if(!istype(body) || body != body_ref?.resolve())
		to_chat(user, span_warning("Вы не в теле ревенанта. Начните программу заново, чтобы вернуть его."))
		return FALSE
	switch(option)
		if("Эссенция до максимума")
			refill(body)
			to_chat(body, span_notice("Эссенция восполнена, украденной хватит на открытие любой способности, задержки сброшены."))
		if("Цель для жатвы")
			return spawn_prey(session, body)
		if("Лампы для перегрузки")
			return place_lamps(session, body)
	return TRUE

/datum/antag_training_program/creature/revenant/proc/spawn_prey(datum/antag_training_session/session, mob/living/simple_animal/revenant/training/body)
	var/datum/antag_training_arena/arena = session.arena
	var/zone_id = arena.match_zone(body)
	if(!arena.zones[zone_id] || zone_id == "hub")
		to_chat(body, span_warning("Цель для жатвы встаёт рядом с вами, а в центре и переходах её нет: перейдите в сектор или на площадку."))
		return FALSE
	if(world.time < arena.next_spawn_at)
		to_chat(body, span_warning("Подождите секунду перед следующей целью."))
		return FALSE
	arena.next_spawn_at = world.time + 1 SECONDS
	var/mob/living/carbon/human/prey = arena.spawn_creature("human", zone_id, FALSE, session, get_turf(body))
	if(!prey)
		to_chat(body, span_warning(arena.has_target_room() ? "Рядом нет свободного места для цели. Отлетите от стен и препятствий." : arena.target_limit_refusal()))
		return FALSE
	prey.apply_damage(prey.health - (HEALTH_THRESHOLD_CRIT + HEALTH_THRESHOLD_FULLCRIT) / 2, BRUTE, BODY_ZONE_CHEST, forced = TRUE, wound_bonus = CANT_WOUND)
	to_chat(body, span_notice("[prey.real_name] лежит в критическом состоянии. Подлетите вплотную и кликните по нему, пока душа держится за тело."))
	return TRUE

/datum/antag_training_program/creature/revenant/proc/place_lamps(datum/antag_training_session/session, mob/living/simple_animal/revenant/training/body)
	var/datum/antag_training_arena/arena = session.arena
	var/zone_id = arena.match_zone(body)
	if(!arena.zones[zone_id] || zone_id == "hub")
		to_chat(body, span_warning("Лампы встают вокруг вас, а в центре и переходах их нет: перейдите в сектор или на площадку."))
		return FALSE
	if(world.time < session.next_supply_at)
		to_chat(body, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	arena.prune_supplies()
	var/placed = 0
	for(var/turf/open/spot in orange(ANTAG_TRAINING_REVENANT_LAMP_RANGE, body))
		if(placed >= ANTAG_TRAINING_REVENANT_LAMPS)
			break
		if(arena.construction_error(spot))
			continue
		var/obj/machinery/light/floor/lamp = new(spot)
		arena.track_supply(lamp, session)
		arena.placed_structures += WEAKREF(lamp)
		placed++
	if(!placed)
		to_chat(body, span_warning(arena.construction_error(get_step(body, body.dir)) || "Вокруг нет свободного пола. Отлетите от стен и вещей."))
		return FALSE
	to_chat(body, span_notice("Вокруг вас загорелись лампы ([placed] шт.). Перегрузка бьёт током людей рядом с ними."))
	return TRUE

/mob/living/simple_animal/revenant/training
	generated_objectives_and_spells = TRUE
	var/datum/weakref/residue_ref

/mob/living/simple_animal/revenant/training/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(!message)
		return
	log_talk(message, LOG_SAY)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena)
		return
	var/rendered = "<span class='revennotice'><b>[src]</b> говорит: \"[message]\"</span>"
	for(var/mob/listener as anything in GLOB.mob_list)
		if(isrevenant(listener))
			if(listener.training_origin == training_origin)
				to_chat(listener, rendered)
		else if(isobserver(listener) && arena.owns_area(get_area(listener)))
			to_chat(listener, "[FOLLOW_LINK(listener, src)] [rendered]")

/mob/living/simple_animal/revenant/training/Harvest(mob/living/carbon/human/target)
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(forget_drained), override = TRUE)
	return ..()

/mob/living/simple_animal/revenant/training/proc/forget_drained(mob/living/source)
	SIGNAL_HANDLER
	drained_mobs -= source

/mob/living/simple_animal/revenant/training/fully_heal(admin_revive = FALSE)
	var/obj/item/ectoplasm/revenant/training/residue = residue_ref?.resolve()
	residue?.reform()
	essence = max(essence, essence_regen_cap)
	update_health_hud()
	update_action_buttons_icon()

/mob/living/simple_animal/revenant/training/death()
	if(!revealed || stasis)
		return FALSE
	stasis = TRUE
	mob_transforming = TRUE
	to_chat(src, span_revendanger("Эссенция рассыпается. Через несколько секунд вы соберётесь в центре сектора."))
	playsound(src, 'sound/effects/screech.ogg', 100, TRUE)
	visible_message(span_warning("[src] рассыпается в мелкую синюю пыль."))
	var/obj/item/ectoplasm/revenant/training/residue = new(get_turf(src))
	residue.essence = essence_regen_cap
	residue.revenant = src
	residue_ref = WEAKREF(residue)
	revealed = FALSE
	invisibility = INVISIBILITY_ABSTRACT
	// Базовая смерть ревенанта не зовёт родителя и уходит в призрака: сеанс узнаёт о смерти этим сигналом.
	SEND_SIGNAL(src, COMSIG_MOB_DEATH, FALSE)
	return TRUE

/mob/living/simple_animal/revenant/training/Destroy()
	var/obj/item/ectoplasm/revenant/training/residue = residue_ref?.resolve()
	residue_ref = null
	if(residue)
		residue.revenant = null
		qdel(residue)
	return ..()

/obj/item/ectoplasm/revenant/training
	desc = "Мерцающая синяя пыль учебного ревенанта. Скоро он соберётся заново, а если рассеять её в руке - появится в центре новым телом."
	var/scattered = FALSE

/obj/item/ectoplasm/revenant/training/scatter()
	scattered = TRUE
	return ..()

/obj/item/ectoplasm/revenant/training/reform(turf/destination)
	if(QDELETED(src) || inert || !release_revenant(destination || drop_location()))
		return FALSE
	visible_message(span_revenboldnotice("[src] поднимается в воздух и тает."))
	qdel(src)
	return TRUE

/// Возвращает ревенанта к жизни с эссенцией эктоплазмы; без destination - там, где он сейчас.
/obj/item/ectoplasm/revenant/training/proc/release_revenant(turf/destination)
	var/mob/living/simple_animal/revenant/training/reformed = revenant
	if(QDELETED(reformed))
		return FALSE
	reforming = FALSE
	revenant = null
	reformed.residue_ref = null
	if(destination)
		reformed.forceMove(destination)
	reformed.essence = essence
	reformed.essence_regen_cap = essence
	reformed.death_reset()
	reformed.update_spooky_icon()
	reformed.update_health_hud()
	return TRUE

/obj/item/ectoplasm/revenant/training/Destroy()
	if(!scattered)
		release_revenant()
	return ..()

/datum/antagonist/revenant/training
	name = "Учебный ревенант"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	ui_name = null
	var/datum/antag_training_session/training

/datum/antagonist/revenant/training/attach_training(datum/antag_training_session/session)
	training = session
	return TRUE

/datum/antagonist/revenant/training/threat()
	return 0

/datum/antagonist/revenant/training/forge_objectives()
	return

/datum/antagonist/revenant/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/revenant/training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/revenant/training/proc/briefing()
	return jointext(list(
		span_boldnotice("Тренировка ревенанта."),
		span_notice("Вы невидимы и летите сквозь стены, но соль и благословлённый пол преграждают путь. Эссенция - и здоровье, и плата за способности; до предела она восстанавливается сама."),
		span_notice("Клик вплотную по человеку без сознания или трупу - жатва: несколько секунд вы раскрыты и обездвижены, зато эссенция растёт, а живая душа поднимает её предел. Человек в сознании не поддаётся, одну душу дважды не выпить."),
		span_notice("Способность сначала открывается украденной эссенцией (первое нажатие), затем каждое применение стоит эссенции и раскрывает вас. Раскрытого можно ранить, нуль-жезл подавляет способности. Перетащите предмет мышью на цель - бросок телекинезом."),
		span_notice("Кончилась эссенция у раскрытого - вы рассыпаетесь эктоплазмой и через несколько секунд собираетесь в центре сектора. Рассеянная эктоплазма - новое тело в центре."),
		span_notice("«Пульт полигона», раздел «Моя роль»: эссенция до максимума, манекен в крите для жатвы и лампы для перегрузки."),
	), "<br>")

/datum/antagonist/revenant/training/Destroy()
	training = null
	return ..()

#undef ANTAG_TRAINING_REVENANT_LAMPS
#undef ANTAG_TRAINING_REVENANT_LAMP_RANGE
