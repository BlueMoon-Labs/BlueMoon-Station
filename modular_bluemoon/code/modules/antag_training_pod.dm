/obj/machinery/antag_training_pod
	name = "training pod"
	desc = "Капсула погружения в тренировочный полигон. Место одно, но только на время выбора программы: когда тренировка началась, тело засыпает в спальном отсеке капсулы и место освобождается для следующего."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	state_open = TRUE
	density = FALSE
	use_power = NO_POWER_USE
	init_process = FALSE
	interaction_flags_atom = NONE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	flags_1 = DEFAULT_RICOCHET_1 | NODECONSTRUCT_1
	occupant_typecache = list(/mob/living/carbon/human)
	/// Сеанс -> list(weakref спящего тела, был ли у тела GODMODE до капсулы).
	var/list/sessions = list()
	var/datum/weakref/catalog_ref

/obj/machinery/antag_training_pod/Initialize(mapload)
	. = ..()
	update_icon()

/obj/machinery/antag_training_pod/Destroy()
	for(var/datum/antag_training_session/training as anything in sessions.Copy())
		training.finish()
		release(training)
	return ..()

/obj/machinery/antag_training_pod/update_icon_state()
	icon_state = "[initial(icon_state)][state_open ? "-open" : ""]"
	return ..()

/obj/machinery/antag_training_pod/examine(mob/user)
	. = ..()
	if(length(sessions))
		. += span_notice("В спальном отсеке спят участники полигона: [length(sessions)].")
	. += span_notice("Посетитель Гост-Кафе ложится в капсулу рукой или перетащив себя на неё и выбирает программу полигона. Выход с полигона будит рядом с капсулой.")

/obj/machinery/antag_training_pod/proc/sleeper_of(datum/antag_training_session/training)
	var/list/record = sessions[training]
	var/datum/weakref/body_ref = record?[1]
	return body_ref?.resolve()

/obj/machinery/antag_training_pod/proc/is_sleeper(atom/movable/thing)
	for(var/datum/antag_training_session/training as anything in sessions)
		if(sleeper_of(training) == thing)
			return TRUE
	return FALSE

/obj/machinery/antag_training_pod/proc/can_enter(mob/living/user)
	if(!ishuman(user) || !user.client)
		return FALSE
	if(!user.mind?.has_antag_datum(/datum/antagonist/ghost_role/ghost_cafe))
		to_chat(user, span_warning("Капсула принимает только посетителей Гост-Кафе."))
		return FALSE
	if(!SSticker.HasRoundStarted())
		to_chat(user, span_warning("Полигон откроется после начала раунда."))
		return FALSE
	if(antag_training_round_over(user))
		return FALSE
	if(jobban_isbanned(user, ROLE_GHOSTROLE))
		to_chat(user, span_warning("Вам закрыты гост-роли, полигон недоступен."))
		return FALSE
	if(GLOB.antag_training_sessions[user.ckey] || (user.ckey in GLOB.antag_training_pending))
		to_chat(user, span_warning("Ваш сеанс полигона уже идёт или готовится."))
		return FALSE
	return TRUE

/obj/machinery/antag_training_pod/attack_hand(mob/living/user, act_intent, attackchain_flags)
	. = ..()
	try_enter(user)

/obj/machinery/antag_training_pod/MouseDrop_T(atom/dropping, mob/user)
	if(dropping == user)
		try_enter(user)

/obj/machinery/antag_training_pod/proc/try_enter(mob/living/user)
	if(!istype(user) || user == occupant || is_sleeper(user) || user.incapacitated() || !Adjacent(user))
		return FALSE
	if(occupant || !state_open)
		to_chat(user, span_warning("Капсулой сейчас пользуется другой посетитель: он выбирает программу. Подождите несколько секунд."))
		return FALSE
	if(!can_enter(user))
		return FALSE
	close_machine(user)
	if(occupant != user)
		open_machine()
		return FALSE
	var/datum/antag_training_catalog/catalog = new(user, src)
	if(!SStgui.get_open_ui(user, catalog))
		qdel(catalog)
		open_machine()
		return FALSE
	catalog_ref = WEAKREF(catalog)
	return TRUE

/obj/machinery/antag_training_pod/proc/begin_training(mob/user, program_type, use_character, role_id)
	if(user != occupant)
		return null
	catalog_ref = null
	if(!can_enter(user))
		open_machine()
		return null
	. = start_antag_training(user, program_type, use_character, src, role_id)
	if(!. && user == occupant)
		open_machine()

/obj/machinery/antag_training_pod/proc/catalog_closed(mob/viewer)
	if(viewer == occupant)
		open_machine()

/obj/machinery/antag_training_pod/open_machine(drop = TRUE)
	var/datum/antag_training_catalog/catalog = catalog_ref?.resolve()
	catalog_ref = null
	qdel(catalog)
	return ..()

/// Спящие остаются в отсеке, наружу выходит только тот, кто сейчас выбирает программу.
/obj/machinery/antag_training_pod/dropContents(list/subset = null)
	var/list/awake = list()
	for(var/atom/movable/thing in contents)
		if(!is_sleeper(thing) && (!subset || (thing in subset)))
			awake += thing
	return ..(awake)

/obj/machinery/antag_training_pod/relaymove(mob/living/user, direction)
	if(user == occupant)
		leave(user)

/obj/machinery/antag_training_pod/container_resist(mob/living/user)
	leave(user)

/obj/machinery/antag_training_pod/proc/leave(mob/living/user)
	if(is_sleeper(user))
		to_chat(user, span_warning("Сеанс идёт: выйдите через пульт полигона."))
		return FALSE
	if(user != occupant)
		return FALSE
	open_machine()
	return TRUE

/obj/machinery/antag_training_pod/Exited(atom/movable/gone, atom/newloc)
	var/left_closed = gone == occupant && !state_open
	. = ..()
	if(left_closed)
		open_machine()

/// Сеанс начался: тело засыпает в спальном отсеке, место освобождается для следующего посетителя.
/obj/machinery/antag_training_pod/proc/hold(mob/living/body, datum/antag_training_session/training)
	sessions[training] = list(WEAKREF(body), !!(body.status_flags & GODMODE))
	ADD_TRAIT(body, TRAIT_TRAINING_DREAMER, REF(src))
	body.status_flags |= GODMODE
	if(occupant == body)
		set_occupant(null)
	state_open = TRUE
	density = FALSE
	update_icon()

/// Будит тело сеанса рядом с капсулой.
/obj/machinery/antag_training_pod/proc/release(datum/antag_training_session/training)
	var/list/record = sessions[training]
	if(!record)
		return
	sessions -= training
	var/datum/weakref/body_ref = record[1]
	var/mob/living/body = body_ref.resolve()
	if(!body)
		return
	REMOVE_TRAIT(body, TRAIT_TRAINING_DREAMER, REF(src))
	if(!record[2])
		body.status_flags &= ~GODMODE
	if(body.loc == src)
		body.forceMove(get_turf(src))
		body.update_mobility()


/proc/antag_training_send_to_cafe(mob/dead/observer/observer)
	if(QDELETED(observer) || !observer.ckey)
		return FALSE
	for(var/obj/effect/mob_spawn/human/ghostcafe/spawner in GLOB.poi_list)
		if(!spawner.loc || !spawner.uses || !spawner.ghost_usable)
			continue
		if(jobban_isbanned(observer, spawner.banType))
			to_chat(observer, span_warning("Вход в Гост-Кафе для вас закрыт, вы остаётесь призраком."))
			return FALSE
		var/player = key_name(observer)
		if(!spawner.create(ckey = observer.ckey))
			to_chat(observer, span_warning("Не удалось прийти в Гост-Кафе, вы остаётесь призраком."))
			return FALSE
		log_game("[player] уходит с тренировочного полигона в Гост-Кафе.")
		return TRUE
	to_chat(observer, span_warning("Гост-Кафе сейчас недоступно, вы остаётесь призраком."))
	return FALSE
