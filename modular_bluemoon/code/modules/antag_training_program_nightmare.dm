#define ANTAG_TRAINING_NIGHTMARE_LAMPS 3
#define ANTAG_TRAINING_NIGHTMARE_LAMP_RANGE 2
/// Ударов сердца тьмы до подъёма, как HEART_RESPAWN_THRESHHOLD в shadowpeople.dm: удар - один фаер Life тела в темноте.
#define ANTAG_TRAINING_NIGHTMARE_HEART_BEATS 40
#define ANTAG_TRAINING_NIGHTMARE_LAMP_SPACING 3
/// Клетки от горящей лампы сектора, ближе которых цель охоты не ставится.
#define ANTAG_TRAINING_NIGHTMARE_LIGHT_CLEARANCE 5
/// Освещение клеток догоняет погашенные лампы не сразу: первые шаги после них не выдают участника.
#define ANTAG_TRAINING_NIGHTMARE_GRACE (1 SECONDS)

/datum/antag_training_program/antag/nightmare
	name = "Кошмар"
	category = "Существа"
	desc = "Тело кошмара в тёмном секторе: пожиратель света из сердца тьмы, шаг в тени, Великая тьма, уворот и лечение в темноте, возрождение сердцем."
	icon = "moon"
	color = "purple"
	learn = "Пожиратель света: лампы и чужие фонари|Шаг в тени|Великая тьма|Уворот и лечение в темноте|Сердце тьмы: возрождение"
	difficulty = 2
	sector = "dark"
	antag_type = /datum/antagonist/nightmare/training
	options = list("Цель во тьме", "Лампы для пожирателя", "Здоровье и Великая тьма")
	var/heart_timer
	/// Тело, которое ждёт сердце тьмы: его подъём снимает ожидание.
	var/datum/weakref/heart_body_ref
	/// Сердце уже не подняло тело: следующая потеря тела идёт обычным восстановлением в хабе.
	var/heart_gave_up = FALSE

/datum/antag_training_program/antag/nightmare/New()
	. = ..()
	var/datum/action/cooldown/nightmare/darkness/darkness = /datum/action/cooldown/nightmare/darkness
	option_hints = list(
		"Цель во тьме" = "Рядом встанет манекен с горящим фонарём в руке. [antag_training_nightmare_torch_rule()] Погасите фонарь Великой тьмой или ударом пожирателя света вплотную. Из безопасного центра манекен встаёт в лаборатории.",
		"Лампы для пожирателя" = "Вокруг вас загорятся напольные лампы ([ANTAG_TRAINING_NIGHTMARE_LAMPS] шт.). Удар пожирателем света ломает лампу, Великая тьма гасит все сразу. Свет хаба общий: лампы бьют и гасят только в секторе или на площадке, где вы стоите. Лампы идут в лимит построек и убираются очисткой своих объектов.",
		"Здоровье и Великая тьма" = "Здоровье до максимума и сброс задержки Великой тьмы. В раунде она перезаряжается [initial(darkness.cooldown_time) / (1 SECONDS)] с, а раны затягивает только темнота. Во время упражнения «[/datum/antag_training_exercise/drill/dark/nightmare_hunt::name]» кнопка не работает.",
	)

/datum/antag_training_program/antag/nightmare/Destroy()
	stop_heart_wait()
	return ..()

/// Как светит фонарь цели и откуда его гасить: числа из фонаря и Великой тьмы.
/proc/antag_training_nightmare_torch_rule()
	var/obj/item/flashlight/torch = /obj/item/flashlight
	var/reach = CEILING(initial(torch.brightness_on), 1)
	var/radius = /datum/action/cooldown/nightmare/darkness::aoe_radius
	return "Фонарь в руке освещает все клетки в [reach] клетках вокруг цели, которые она видит, и за спиной тоже: подойти к ней с горящим фонарём нельзя. Великая тьма гасит свет в [radius] клетках и сквозь стены: встаньте в [reach + 1]-[radius] клетках от цели или за стеной рядом с ней."

/// Сколько сеанс ждёт сердце тьмы: удары идут раз в фаер SSmobs, у тела без клиента - через фаер.
/proc/antag_training_nightmare_heart_wait()
	return ANTAG_TRAINING_NIGHTMARE_HEART_BEATS * SSmobs.wait * 2

/datum/antag_training_program/antag/nightmare/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	if(!role(session) || !ishuman(user))
		to_chat(user, span_warning("Вы не кошмар. Начните программу заново, чтобы вернуть тело."))
		return FALSE
	switch(option)
		if("Цель во тьме")
			return place_lit_dummy(session, user)
		if("Лампы для пожирателя")
			return place_lamps(session, user)
		if("Здоровье и Великая тьма")
			var/datum/antag_training_exercise_run/run = session.exercise_run
			if(run && !run.ended && istype(run.exercise, /datum/antag_training_exercise/drill/dark/nightmare_hunt))
				to_chat(user, span_warning("Идёт упражнение «[run.exercise.name]»: здоровье и Великую тьму оно не восполняет. Закончите или прервите его."))
				return FALSE
			user.revive(full_heal = TRUE, admin_revive = TRUE)
			var/datum/action/cooldown/nightmare/darkness/darkness = locate() in user.actions
			if(darkness)
				darkness.next_use_time = 0
				darkness.UpdateButtons()
			to_chat(user, span_notice("Здоровье восполнено, Великую тьму можно звать сразу."))
	return TRUE

/datum/antag_training_program/antag/nightmare/proc/place_lit_dummy(datum/antag_training_session/session, mob/living/user)
	var/mob/living/carbon/human/dummy = place_practice_dummy(session, user)
	if(!dummy)
		return FALSE
	antag_training_light_torch(dummy)
	to_chat(user, span_notice("[dummy.real_name] стоит в зоне «[dummy_zone_name(session, dummy)]» с горящим фонарём."))
	return TRUE

/datum/antag_training_program/antag/nightmare/proc/place_lamps(datum/antag_training_session/session, mob/living/user)
	var/datum/antag_training_arena/arena = session.arena
	var/zone_id = arena.match_zone(user)
	if(!arena.zones[zone_id] || zone_id == "hub")
		to_chat(user, span_warning("Лампы встают вокруг вас, а в центре и переходах их нет: перейдите в сектор или на площадку."))
		return FALSE
	if(world.time < session.next_supply_at)
		to_chat(user, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	arena.prune_supplies()
	var/placed = 0
	for(var/turf/open/spot in orange(ANTAG_TRAINING_NIGHTMARE_LAMP_RANGE, user))
		if(placed >= ANTAG_TRAINING_NIGHTMARE_LAMPS)
			break
		if(arena.construction_error(spot, session))
			continue
		var/obj/machinery/light/floor/lamp = new(spot)
		arena.track_supply(lamp, session)
		arena.placed_structures += WEAKREF(lamp)
		placed++
	if(!placed)
		to_chat(user, span_warning(arena.construction_error(get_step(user, user.dir), session) || "Вокруг нет свободного пола. Отойдите от стен и вещей."))
		return FALSE
	to_chat(user, span_notice("Вокруг вас загорелись лампы ([placed] шт.). Выпустите пожиратель света кнопкой сердца тьмы и бейте их вплотную."))
	return TRUE

/// Убитого в темноте кошмара поднимает сердце тьмы: сеанс ждёт его, а не переносит тело в хаб.
/datum/antag_training_program/antag/nightmare/body_lost(datum/antag_training_session/session)
	var/mob/living/carbon/human/body = session.current_body
	if(heart_gave_up || heart_timer || !istype(body) || QDELETED(body) || body.stat != DEAD || !istype(body.getorganslot(ORGAN_SLOT_HEART), /obj/item/organ/heart/nightmare))
		heart_gave_up = FALSE
		return FALSE
	var/turf/spot = get_turf(body)
	if(!spot || spot.get_lumcount() >= SHADOW_SPECIES_LIGHT_THRESHOLD)
		return FALSE
	var/wait = antag_training_nightmare_heart_wait()
	heart_timer = addtimer(CALLBACK(src, PROC_REF(heart_failed), session), wait, TIMER_STOPPABLE)
	heart_body_ref = WEAKREF(body)
	RegisterSignal(body, COMSIG_MOB_STATCHANGE, PROC_REF(on_heart_body_stat))
	to_chat(body, span_notice("Сердце тьмы бьётся: тело в темноте встанет само. Если за [wait / (1 SECONDS)] с этого не случится, вы восстановитесь в хабе."))
	return TRUE

/// Тело встало - сердцем, лечением или восстановлением: ожидание сердца снято, следующая смерть ждёт его заново.
/datum/antag_training_program/antag/nightmare/proc/on_heart_body_stat(mob/living/source, new_stat)
	SIGNAL_HANDLER
	if(new_stat != DEAD)
		stop_heart_wait()

/datum/antag_training_program/antag/nightmare/proc/stop_heart_wait()
	deltimer(heart_timer)
	heart_timer = null
	var/mob/living/body = heart_body_ref?.resolve()
	if(body)
		UnregisterSignal(body, COMSIG_MOB_STATCHANGE)
	heart_body_ref = null

/datum/antag_training_program/antag/nightmare/proc/heart_failed(datum/antag_training_session/session)
	stop_heart_wait()
	if(QDELETED(session) || session.finished || session.program != src)
		return
	var/mob/living/body = session.current_body
	if(!isliving(body) || body.stat != DEAD)
		return
	heart_gave_up = TRUE
	session.recover()

/// Включает фонарь в руке манекена: свет, который кошмару нужно погасить.
/proc/antag_training_light_torch(mob/living/carbon/human/holder)
	var/obj/item/flashlight/torch = new(get_turf(holder))
	if(!holder.put_in_hands(torch))
		qdel(torch)
		return null
	torch.on = TRUE
	torch.update_brightness(holder)
	return torch

/// Сердце учебного кошмара выпускает пожиратель, который не трогает чужое на полигоне.
/obj/item/organ/heart/nightmare/training

/obj/item/organ/heart/nightmare/training/ui_action_click(mob/living/carbon/M, action)
	if(QDELETED(blade))
		blade = new /obj/item/light_eater/training(src)
	return ..()

/obj/item/light_eater/training

/obj/item/light_eater/training/pre_attack(atom/A, mob/living/user, params, attackchain_flags, damage_multiplier)
	var/refusal = training_refusal(A, user, FALSE)
	if(refusal)
		to_chat(user, span_warning(refusal))
		return STOP_ATTACK_PROC_CHAIN
	return ..()

/obj/item/light_eater/training/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(proximity_flag && isliving(target) && training_refusal(target, user, TRUE))
		to_chat(user, span_warning("Свет на другом участнике полигона и его вещах пожиратель не трогает."))
		return
	return ..()

/// Почему пожирателю нельзя тронуть цель; живых проверяет только с with_living: драться участникам можно, гасить их свет - нет.
/obj/item/light_eater/training/proc/training_refusal(atom/target, mob/user, with_living)
	if(!is_antag_training_atom(target))
		return "За пределами полигона учебный пожиратель света не действует."
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(arena && !isliving(target) && antag_training_nightmare_breaks(target))
		var/home = arena.nightmare_light_zone(user)
		if(!home || arena.nightmare_light_zone(target) != home)
			return "Свет хаба и переходов общий: учебный пожиратель ломает свет только в секторе или на площадке, где вы стоите."
	if(isturf(target) || (isliving(target) && !with_living))
		return null
	var/datum/antag_training_session/session = arena?.session_of(user)
	if(!session)
		return null
	return arena.foreign_part_refusal(target, session, user)

/datum/antagonist/nightmare/training
	name = "Учебный кошмар"
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

/datum/antagonist/nightmare/training/threat()
	return 0

/datum/antagonist/nightmare/training/on_gain()
	var/mob/living/carbon/human/body = owner.current
	if(ishuman(body))
		become_nightmare(body)
	return ..()

/// Тело как у кошмара раунда: без одежды, вид кошмара, но сердце учебное.
/datum/antagonist/nightmare/training/proc/become_nightmare(mob/living/carbon/human/body)
	body.delete_equipment()
	var/datum/species/shadow/nightmare/form = new
	form.mutant_organs = list(/obj/item/organ/heart/nightmare/training)
	body.set_species(form)
	var/datum/action/cooldown/nightmare/darkness/darkness = locate() in body.actions
	if(darkness)
		RegisterSignal(darkness, COMSIG_ACTION_TRIGGER, PROC_REF(on_darkness))

/datum/antagonist/nightmare/training/proc/on_darkness(datum/action/cooldown/nightmare/darkness/source)
	SIGNAL_HANDLER
	var/refusal = darkness_refusal(source)
	if(!refusal)
		return NONE
	to_chat(source.owner, span_warning(refusal))
	return COMPONENT_ACTION_BLOCK_TRIGGER

/// Великая тьма гасит всё в радиусе: на полигоне она срабатывает только в секторе или на площадке участника и не трогает свет других участников.
/datum/antagonist/nightmare/training/proc/darkness_refusal(datum/action/cooldown/nightmare/darkness/darkness)
	var/mob/living/user = darkness.owner
	var/datum/antag_training_arena/arena = training?.arena
	if(!arena || !user)
		return "Учебная Великая тьма работает только на полигоне."
	var/home = arena.nightmare_light_zone(user)
	if(!home)
		return "Свет хаба и переходов общий: Великая тьма работает только в секторе или на площадке, где вы стоите."
	for(var/atom/movable/thing in range(darkness.aoe_radius, user))
		if(thing == user || !antag_training_bears_light(thing))
			continue
		if(!arena.owns_area(get_area(thing)))
			return "Великая тьма задела бы свет за пределами полигона: отойдите от его края."
		if(arena.nightmare_light_zone(thing) != home)
			return "Великая тьма задела бы свет за стеной, в хабе или соседней зоне: отойдите от края своего сектора или площадки."
		var/refusal = arena.foreign_part_refusal(thing, training, user)
		if(refusal)
			return "Великая тьма погасила бы свет другого участника полигона ([refusal]) Отойдите от него дальше."
	return null

/// Зона, свет которой учебный кошмар может гасить: сектор, зона ядра или площадка хаба. null - общий свет хаба и переходов.
/datum/antag_training_arena/proc/nightmare_light_zone(atom/thing)
	var/turf/tile = get_turf(thing)
	var/area/antag_training/place = tile?.loc
	if(!istype(place) || place.arena != src)
		return null
	if(istype(place, /area/antag_training/hub/pad))
		var/datum/antag_training_hub_pad/pad = hub?.pad_at(tile)
		return pad?.id
	if(istype(place, /area/antag_training/hub))
		return null
	var/zone_id = match_zone(tile)
	return (zone_id == "hub" || zone_id == "corridor") ? null : zone_id

/// Что погасит или сломает Великая тьма: исправная лампа (и выключенная), фонарь на оружии (и выключенный), любой другой горящий свет, кроме заряженного в оружие выстрела.
/proc/antag_training_bears_light(atom/movable/thing)
	for(var/atom/movable/part as anything in thing.GetAllContents())
		if(istype(part, /obj/machinery/light))
			var/obj/machinery/light/lamp = part
			if(lamp.status == LIGHT_OK)
				return TRUE
		else if(istype(part, /obj/item/gun))
			var/obj/item/gun/weapon = part
			if(weapon.gun_light)
				return TRUE
		else if(part.light_on && part.light_range && part.light_power && !istype(part, /obj/item/projectile))
			return TRUE
	return FALSE

/// Что сломает удар пожирателя по предмету или полу: то же, что Великая тьма, и светящийся пол.
/proc/antag_training_nightmare_breaks(atom/target)
	if(isturf(target))
		return target.light_range && !isspaceturf(target)
	return antag_training_bears_light(target)

/datum/antagonist/nightmare/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/nightmare/training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/nightmare/training/proc/briefing()
	var/datum/action/cooldown/nightmare/darkness/darkness = /datum/action/cooldown/nightmare/darkness
	return jointext(list(
		span_boldnotice("Тренировка кошмара."),
		span_notice("Кнопка сердца тьмы (heart of darkness) выпускает и прячет пожиратель света вместо руки. Удар им ломает лампы, гасит фонари и свет в руках у живых и сносит светящийся пол. Других участников полигона, их вещи и общий свет хаба учебный пожиратель не трогает."),
		span_notice("На тёмной клетке вы уворачиваетесь от пуль и лечитесь, на свету теряете здоровье. Shadow Walk растворяет вас в темноте: проходите где угодно, кроме космоса, пока яркий свет не вытолкнет наружу."),
		span_notice("Great Darkness гасит весь свет в [darkness.aoe_radius] клетках вокруг, затем ждёт [initial(darkness.cooldown_time) / (1 SECONDS)] с. На полигоне она работает только в секторе или на площадке, где вы стоите, и не срабатывает, если задела бы свет хаба, соседней зоны или другого участника."),
		span_notice("Сердце тьмы поднимает убитого кошмара, пока тело лежит в темноте. Сердце бьётся раз в [SSmobs.wait / (1 SECONDS)] с, пока вокруг тела темно, и после [ANTAG_TRAINING_NIGHTMARE_HEART_BEATS] ударов тело встаёт. На полигоне сеанс ждёт его до [antag_training_nightmare_heart_wait() / (1 SECONDS)] с, потом восстанавливает вас в хабе."),
		span_notice("«Пульт полигона», раздел «Моя роль»: цель во тьме с фонарём, лампы для пожирателя, здоровье со сбросом Великой тьмы. Упражнение «Охота во тьме» - на вкладке упражнений в тёмном секторе."),
	), "<br>")

/datum/antagonist/nightmare/training/Destroy()
	training = null
	return ..()

/datum/antag_training_exercise/drill/dark/nightmare_hunt
	id = "nightmare_hunt"
	name = "Охота во тьме"
	program = /datum/antag_training_program/antag/nightmare
	human_only = TRUE
	difficulty = 3
	par_time = 90 SECONDS
	steps = list(/datum/antag_training_exercise_step/drill/nightmare_lamps, /datum/antag_training_exercise_step/drill/nightmare_stalk, /datum/antag_training_exercise_step/drill/nightmare_kill)

/datum/antag_training_exercise/drill/dark/nightmare_hunt/New()
	. = ..()
	desc = "У входа в тёмный сектор горят [ANTAG_TRAINING_NIGHTMARE_LAMPS] лампы, а в одной из комнат стоит цель с фонарём. Погасите лампы, подкрадитесь к цели, ни разу не выйдя на свет, и убейте её. Фонарь цели освещает всё вокруг неё, и за спиной тоже: гасите его Великой тьмой издалека. Шаг на освещённую клетку - вас увидели, упражнение провалено. Убить цель раньше, чем вы к ней подкрались, - тоже провал."

/datum/antag_training_exercise/drill/dark/nightmare_hunt/setup(datum/antag_training_session/session)
	var/datum/antag_training_sector/dark_sector = session.arena.sectors[sector]
	var/turf/entry = dark_sector?.spawn_turf()
	if(!entry || !target_slot_free(session))
		return FALSE
	var/list/rooms = rooms(dark_sector)
	var/list/lamp_spots = lamp_spots(rooms[1], entry)
	var/turf/hideout = hunt_spot(dark_sector, rooms)
	if(length(lamp_spots) < ANTAG_TRAINING_NIGHTMARE_LAMPS || !hideout)
		return "в секторе нет места для ламп или цели, сбросьте его"
	var/datum/antag_training_exercise_run/run = session.exercise_run
	for(var/turf/spot as anything in lamp_spots)
		var/obj/machinery/light/floor/lamp = new(spot)
		// Разбитая насовсем лампа исчезает без рамки и проводов.
		lamp.flags_1 |= NODECONSTRUCT_1
		run.add_prop(lamp, FALSE)
	prepare_target(session, "human", hideout)
	return TRUE

/// Свободные клетки коридора входа, по одной на лампу, не ближе двух клеток ко входу и друг к другу.
/datum/antag_training_exercise/drill/dark/nightmare_hunt/proc/lamp_spots(list/hall, turf/entry)
	. = list()
	var/list/candidates = list()
	for(var/turf/tile as anything in hall)
		if(get_dist(tile, entry) >= 2 && !tile.is_blocked_turf(exclude_mobs = FALSE))
			candidates[tile] = get_dist(tile, entry)
	sortTim(candidates, GLOBAL_PROC_REF(cmp_numeric_asc), TRUE)
	for(var/turf/tile as anything in candidates)
		var/spaced = TRUE
		for(var/turf/taken as anything in .)
			if(get_dist(tile, taken) < ANTAG_TRAINING_NIGHTMARE_LAMP_SPACING)
				spaced = FALSE
				break
		if(spaced)
			. += tile
			if(length(.) >= ANTAG_TRAINING_NIGHTMARE_LAMPS)
				return

/// Клетка в комнате за дверями коридора входа, вдали от горящих ламп сектора.
/datum/antag_training_exercise/drill/dark/nightmare_hunt/proc/hunt_spot(datum/antag_training_sector/dark_sector, list/rooms)
	var/list/lit = list()
	for(var/turf/tile as anything in dark_sector.turfs)
		for(var/obj/machinery/light/lamp in tile)
			if(lamp.status == LIGHT_OK)
				lit += tile
	var/list/candidates = list()
	for(var/index in 2 to length(rooms))
		var/list/spots = list()
		for(var/turf/tile as anything in rooms[index])
			if(tile.is_blocked_turf(exclude_mobs = FALSE))
				continue
			var/clear = TRUE
			for(var/turf/lamp_spot as anything in lit)
				if(get_dist(tile, lamp_spot) <= ANTAG_TRAINING_NIGHTMARE_LIGHT_CLEARANCE)
					clear = FALSE
					break
			if(clear)
				spots += tile
		if(length(spots))
			candidates += list(spots)
	return length(candidates) ? pick(pick(candidates)) : null

/datum/antag_training_exercise/drill/dark/nightmare_hunt/target_ready(datum/antag_training_exercise_run/run, mob/living/target)
	run.add_prop(antag_training_light_torch(target), FALSE)

/datum/antag_training_exercise_step/drill/nightmare_lamps
	name = "Погасите лампы у входа"
	hint = "Кнопка сердца тьмы (heart of darkness) выпускает пожиратель света: подойдите к лампе на полу и ударьте её. Great Darkness гасит все лампы рядом сразу, но потом долго перезаряжается, а она ещё понадобится для фонаря цели."
	target_death = "цель убита раньше, чем вы к ней подкрались"

/datum/antag_training_exercise_step/drill/nightmare_lamps/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	for(var/obj/machinery/light/lamp in owner.props)
		RegisterSignals(lamp, list(COMSIG_PARENT_QDELETING, COMSIG_ATOM_UPDATED_ICON), PROC_REF(on_lamp_changed))
	on_lamp_changed()

/datum/antag_training_exercise_step/drill/nightmare_lamps/proc/on_lamp_changed()
	SIGNAL_HANDLER
	if(done || !run || run.ended)
		return
	for(var/obj/machinery/light/lamp in run.props)
		if(!QDELETED(lamp) && lamp.status == LIGHT_OK && lamp.on)
			return
	complete()

/datum/antag_training_exercise_step/drill/nightmare_stalk
	name = "Подкрадитесь к цели в темноте"
	hint = "Погасите фонарь цели Великой тьмой издалека и подойдите к ней по темноте."
	target_death = "цель убита раньше, чем вы к ней подкрались"
	var/grace_until = 0

/datum/antag_training_exercise_step/drill/nightmare_stalk/New()
	. = ..()
	hint = "Цель стоит в одной из комнат. [antag_training_nightmare_torch_rule()] Шаг на освещённую клетку выдаёт вас. Когда фонарь погас, подойдите к цели вплотную по темноте. В Shadow Walk вас не видно, пока клетка тёмная."

/datum/antag_training_exercise_step/drill/nightmare_stalk/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	grace_until = world.time + ANTAG_TRAINING_NIGHTMARE_GRACE
	var/mob/living/body = participant()
	if(body)
		RegisterSignal(body, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/antag_training_exercise_step/drill/nightmare_stalk/proc/on_moved(mob/living/source)
	SIGNAL_HANDLER
	var/turf/spot = source.loc
	if(source != participant() || !isturf(spot))
		return
	// Перенос пультом или платформой уводит из сектора: это не выход на свет.
	if(run.session.arena.match_zone(spot) != run.exercise.sector)
		run.finish(FALSE, "вы покинули тёмный сектор")
		return
	if(world.time >= grace_until && spot.get_lumcount() >= SHADOW_SPECIES_LIGHT_THRESHOLD)
		run.finish(FALSE, "вас увидели: вы вышли на свет")
		return
	var/mob/living/target = exercise_target()
	if(target && target.stat != DEAD && antag_training_reached(source, target))
		complete()

/datum/antag_training_exercise_step/drill/nightmare_kill
	name = "Убейте цель"
	hint = "Бейте цель пожирателем света вплотную. Если её фонарь ещё горит, удар пожирателем гасит и его."
	target_death = null
	var/check_timer

/datum/antag_training_exercise_step/drill/nightmare_kill/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/target = exercise_target()
	if(target)
		RegisterSignal(target, COMSIG_MOB_DEATH, PROC_REF(check_kill))
	deltimer(check_timer)
	check_timer = addtimer(CALLBACK(src, PROC_REF(check_kill)), 0, TIMER_STOPPABLE)

/datum/antag_training_exercise_step/drill/nightmare_kill/detach()
	deltimer(check_timer)
	check_timer = null
	return ..()

/datum/antag_training_exercise_step/drill/nightmare_kill/proc/check_kill()
	SIGNAL_HANDLER
	check_timer = null
	var/mob/living/target = exercise_target()
	if(target && target.stat == DEAD)
		complete()

#undef ANTAG_TRAINING_NIGHTMARE_LAMPS
#undef ANTAG_TRAINING_NIGHTMARE_LAMP_RANGE
#undef ANTAG_TRAINING_NIGHTMARE_HEART_BEATS
#undef ANTAG_TRAINING_NIGHTMARE_LAMP_SPACING
#undef ANTAG_TRAINING_NIGHTMARE_LIGHT_CLEARANCE
#undef ANTAG_TRAINING_NIGHTMARE_GRACE
