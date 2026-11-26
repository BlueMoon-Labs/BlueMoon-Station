/obj/effect/proc_holder/spell
	/// Наручники не мешают этой способности; смирительная рубашка и щит разума мешают.
	var/heretic_breaks_cuffs = FALSE

/datum/eldritch_knowledge/spell/mansus_whisper
	name = "Шёпот изнанки"
	summary = "Голос прямо в голове любого члена экипажа из манифеста: без подписи или под любым именем."
	details = list(
		"Выберите имя из манифеста экипажа и напишите до 200 символов; расстояние не важно.",
		"Подпись по желанию: любое имя до 26 символов, иначе голос остаётся безымянным.",
		"Шёпот доходит только до живых; дошёл ли он, вам не сообщат.",
		"Шапочка из фольги и защита от магии глушат шёпот.",
		"Перезарядка 30 секунд; в наручниках и под щитом разума не работает.",
	)
	role = HERETIC_ROLE_SUPPORT
	gain_text = "Стены тонкие, а головы ещё тоньше. Стоит только наклониться поближе."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/self/mansus_whisper

/obj/effect/proc_holder/spell/self/mansus_whisper
	name = "Шёпот изнанки"
	desc = "Шепните сообщение прямо в голову члену экипажа из манифеста, без подписи или под любым именем. Фольга и защита от магии глушат шёпот, а дошёл ли он, вы не узнаете."
	summary = "Голос в голове любого члена экипажа, с подписью или без."
	charge_max = HERETIC_WHISPER_COOLDOWN
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_side_lore.dmi'
	action_icon_state = "heretic_whisper"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/mansus_whisper/cast(list/targets, mob/living/user)
	var/list/names = heretic_whisper_names()
	if(!length(names))
		heretic_revert_cast(user, "В манифесте экипажа пока никого нет.")
		return FALSE
	var/chosen = tgui_input_list(user, "Кому шепнуть?", name, names)
	if(!chosen || QDELETED(src))
		revert_cast(user)
		return FALSE
	var/sign_choice = tgui_alert(user, "Подписать шёпот чужим именем?", name, list("Без подписи", "Подписать"))
	if(!sign_choice || QDELETED(src))
		revert_cast(user)
		return FALSE
	var/signature = ""
	if(sign_choice == "Подписать")
		signature = tgui_input_text(user, "Чьим именем подписать шёпот?", name, max_length = HERETIC_WHISPER_NAME_LEN)
		if(!signature || QDELETED(src))
			revert_cast(user)
			return FALSE
	var/message = tgui_input_text(user, "Что прошептать [chosen]?", name, max_length = HERETIC_WHISPER_LEN)
	if(!message || QDELETED(src))
		revert_cast(user)
		return FALSE
	var/failure = heretic_whisper_send(user, chosen, signature, message)
	if(failure)
		heretic_revert_cast(user, failure)
		return FALSE
	return TRUE

/proc/heretic_whisper_names()
	. = list()
	for(var/datum/data/record/record as anything in GLOB.data_core.general)
		var/record_name = record.fields["name"]
		if(record_name)
			. |= record_name
	. = sort_list(.)

/proc/heretic_whisper_target(target_name)
	for(var/mob/living/carbon/human/candidate in GLOB.alive_mob_list)
		if(candidate.real_name == target_name && candidate.stat != DEAD)
			return candidate
	return null

/// Текст отказа или null, если шёпот ушёл; дошёл ли он, отправитель не узнаёт.
/proc/heretic_whisper_send(mob/living/user, target_name, signature, message)
	if(QDELETED(user) || user.stat != CONSCIOUS)
		return "Шептать можно только в сознании."
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	if(!user.can_speak_basic("[message]"))
		return "Сейчас вам нельзя говорить в игровом чате."
	message = trim(copytext_char("[message]", 1, HERETIC_WHISPER_LEN + 1))
	if(!message)
		return "Нечего шептать: сообщение пусто."
	if(CHAT_FILTER_CHECK(message))
		return "Мансус не передаст это: в сообщении запрещённое слово."
	signature = trim("[signature]")
	if(signature)
		signature = reject_bad_text(signature, HERETIC_WHISPER_NAME_LEN, ascii_only = FALSE)
		if(!signature || CHAT_FILTER_CHECK(signature) || heretic_echo_has_format_chars(signature))
			return "Подпись не подходит: до [HERETIC_WHISPER_NAME_LEN] символов, без угловых скобок, косых черт, невидимых символов и запрещённых слов."
		signature = sanitize(signature)
	message = sanitize(message)
	var/mob/living/carbon/human/target = heretic_whisper_target(target_name)
	user.log_talk(message, LOG_SAY, tag = "шёпот изнанки для [target_name][signature ? " под именем «[signature]»" : ""]")
	to_chat(user, span_notice("Вы шепчете в изнанку для [target_name]: «[message]»"))
	if(target && !heretic_magic_ward(user, target, 1, TRUE, FALSE))
		SEND_SOUND(target, sound('sound/effects/ghost2.ogg'))
		to_chat(target, span_warning("[signature ? "Голос «[signature]»" : "Чей-то голос"] шепчет прямо у вас в голове: «[message]»"))
	for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
		if(!ghost.client || !antag_training_observer_hears(ghost, user))
			continue
		if((get_dist(ghost, user) > 7 || ghost.z != user.z) && !(ghost.client.prefs.chat_toggles & CHAT_GHOSTEARS))
			continue
		to_chat(ghost, "[FOLLOW_LINK(ghost, user)] <span class='name'>[user]</span> шепчет через изнанку для [target ? FOLLOW_LINK(ghost, target) : ""] [target_name][signature ? " под именем «[signature]»" : ""]: «[message]»")
	return null

/datum/eldritch_knowledge/spell/wave_of_desperation
	name = "Волна отчаяния"
	summary = "Скованный, в захвате или лёжа, вы рвёте оковы волной и отбрасываете соседей, но вскоре засыпаете."
	details = list(
		"Колдуется, только когда вы в наручниках или путах, в крепком захвате или лежите.",
		"Стяжки и болы рвутся, металлические наручники падают на пол, захват разжимается, вы встаёте.",
		"Соседей отбрасывает на 2 клетки и валит на 2 секунды; союзников и защищённых магией - нет.",
		"Через 8 секунд вас смаривает сон на 4 секунды: бегите сразу.",
		"Смирительная рубашка и щит разума держат и против Волны; оглушённый её не соберёт.",
		"Перезарядка 5 минут.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "Когда руки связаны, кричит всё тело. Мансус слышит этот крик."
	cost = 2
	spell_to_add = /obj/effect/proc_holder/spell/self/wave_of_desperation

/obj/effect/proc_holder/spell/self/wave_of_desperation
	name = "Волна отчаяния"
	desc = "Скованным, в крепком захвате или лёжа рвите оковы волной: стяжки лопаются, наручники падают, соседей отбрасывает и валит. Через несколько секунд вас смаривает короткий сон. Смирительная рубашка и щит разума держат. Перезарядка 5 минут."
	summary = "Рвёт оковы и отбрасывает соседей; вскоре вы засыпаете."
	charge_max = HERETIC_WAVE_COOLDOWN
	clothes_req = FALSE
	invocation_type = "none"
	heretic_breaks_cuffs = TRUE
	usable_while_grabbed = TRUE
	action_icon = 'modular_bluemoon/icons/obj/heretic_side_lore.dmi'
	action_icon_state = "wave_of_desperation"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/wave_of_desperation/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/mob/living/living_user = user
	if(!heretic_check(user, isliving(user) && !heretic_wave_stunned(living_user), silent, "Оглушённый не соберёт сил на Волну: дождитесь, пока оглушение пройдёт."))
		return FALSE
	return heretic_check(user, heretic_wave_desperate(living_user), silent, "Рвать нечего: Волна колдуется, только когда вы скованы, в захвате или лежите.")

/proc/heretic_wave_stunned(mob/living/user)
	return user.stat != CONSCIOUS || user.IsUnconscious() || user.IsSleeping() || user.IsStun() || user.IsParalyzed() || IS_STAMCRIT(user)

/proc/heretic_wave_desperate(mob/living/user)
	if(iscarbon(user))
		var/mob/living/carbon/body = user
		if(body.handcuffed || body.legcuffed)
			return TRUE
	if(user.pulledby && user.pulledby.grab_state >= GRAB_AGGRESSIVE)
		return TRUE
	return !CHECK_MOBILITY(user, MOBILITY_STAND)

/obj/effect/proc_holder/spell/self/wave_of_desperation/cast(list/targets, mob/living/user)
	var/static/list/brittle_restraints = typecacheof(list(/obj/item/restraints/handcuffs/cable, /obj/item/restraints/handcuffs/sinew, /obj/item/restraints/legcuffs/bola))
	if(iscarbon(user))
		var/mob/living/carbon/body = user
		var/list/restraints = list(body.handcuffed, body.legcuffed) - null
		body.uncuff()
		for(var/obj/item/restraint as anything in restraints)
			if(is_type_in_typecache(restraint, brittle_restraints))
				qdel(restraint)
	user.pulledby?.stop_pulling()
	user.SetKnockdown(0)
	user.set_resting(FALSE, TRUE)
	for(var/mob/living/victim in orange(1, user))
		if(!heretic_can_affect(user, victim))
			continue
		var/direction = get_dir(user, victim) || pick(GLOB.alldirs)
		victim.Knockdown(HERETIC_WAVE_KNOCKDOWN)
		victim.safe_throw_at(get_ranged_target_turf(victim, direction, HERETIC_WAVE_THROW), HERETIC_WAVE_THROW, 1, user, force = MOVE_FORCE_STRONG)
		log_combat(user, victim, "repelled", src)
	new /obj/effect/temp_visual/gravpush(get_turf(user))
	playsound(user, 'sound/magic/Repulse.ogg', 60, TRUE)
	user.visible_message(span_danger("От [user] расходится волна, оковы лопаются, а всех вокруг отшвыривает!"), span_notice("Вы выплёскиваете отчаяние волной. Скоро силы кончатся: у вас [HERETIC_WAVE_GRACE / (1 SECONDS)] секунд, потом сон."))
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob/living, heretic_wave_collapse)), HERETIC_WAVE_GRACE)
	log_game("[key_name(user)] применил Волну отчаяния в [AREACOORD(user)].")
	return TRUE

/mob/living/proc/heretic_wave_collapse()
	if(stat == DEAD)
		return
	to_chat(src, span_warning("Отчаяние выгорело, и вас валит с ног сон."))
	Sleeping(HERETIC_WAVE_SLEEP)

/datum/eldritch_knowledge/spell/lights_out
	name = "Задуть огни"
	summary = "Лампы на виду в 5 клетках перегорают, а фонарики вокруг гаснут."
	details = list(
		"Лампы и трубки на виду в 5 клетках перегорают: их придётся менять.",
		"Фонарики, фальшфейеры и светящиеся палочки на полу и в руках у неверных гаснут.",
		"Свет союзников и тех, кого бережёт защита от магии, не трогается.",
		"Неверных на виду пробирает холодок: темнота пришла не сама.",
		"Перезарядка 60 секунд; до вознесения не колдуется под оглушением.",
	)
	role = HERETIC_ROLE_CONTROL
	gain_text = "Свет - это тоже дверь. Я просто прикрыл её за собой."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/self/lights_out

/obj/effect/proc_holder/spell/self/lights_out
	name = "Задуть огни"
	desc = "Лампы на виду в 5 клетках перегорают, фонарики, фальшфейеры и светящиеся палочки у неверных гаснут. Перезарядка 60 секунд."
	summary = "Лампы вокруг перегорают, фонарики у неверных гаснут."
	charge_max = HERETIC_LIGHTS_OUT_COOLDOWN
	clothes_req = FALSE
	invocation = "EX'TIN'GUO"
	invocation_type = "whisper"
	heretic_stun_check = TRUE
	action_icon = 'modular_bluemoon/icons/obj/heretic_side_lore.dmi'
	action_icon_state = "lights_out"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/lights_out/cast(list/targets, mob/living/user)
	var/list/seen = heretic_field_view(HERETIC_LIGHTS_OUT_RANGE, user)
	var/snuffed = 0
	for(var/obj/machinery/light/lamp in seen)
		if(lamp.status == LIGHT_OK && lamp.on)
			lamp.burn_out()
			snuffed++
	for(var/obj/item/flashlight/torch in seen)
		snuffed += heretic_snuff_torch(torch)
	for(var/mob/living/witness in seen)
		if(!heretic_can_affect(user, witness, chargecost = 0, notify = FALSE))
			continue
		for(var/obj/item/flashlight/torch in witness.GetAllContents())
			snuffed += heretic_snuff_torch(torch)
		to_chat(witness, span_warning("Свет вокруг гаснет разом, и по спине пробегает холодок: темнота пришла не сама."))
	playsound(user, 'sound/magic/Blind.ogg', 40, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	if(!snuffed)
		to_chat(user, span_notice("Гасить вокруг нечего."))
	log_game("[key_name(user)] задул огни ([snuffed]) в [AREACOORD(user)].")
	return TRUE

/proc/heretic_snuff_torch(obj/item/flashlight/torch)
	if(!torch.on)
		return 0
	if(istype(torch, /obj/item/flashlight/flare))
		var/obj/item/flashlight/flare/flare = torch
		flare.turn_off()
	else if(istype(torch, /obj/item/flashlight/glowstick))
		var/obj/item/flashlight/glowstick/glowstick = torch
		glowstick.turn_off()
	else
		torch.on = FALSE
		torch.update_brightness(ismob(torch.loc) ? torch.loc : null)
	return 1

/datum/eldritch_knowledge/spell/space_phase
	name = "Шаг в пустоту"
	summary = "Стоя в открытом космосе, вы растворяетесь в пустоте и плывёте сквозь неё невидимым."
	details = list(
		"Колдуется с клетки открытого космоса; повторное применение выводит вас обратно.",
		"В пустоте вы невидимы, не дышите, не мёрзнете и не страдаете от вакуума; пули и взрывы проходят мимо.",
		"Плыть можно только по клеткам космоса: пол, решётки и стены не пускают.",
		"Освящённая земля преграждает путь, а гибель или потеря знания выбрасывают вас наружу.",
		"Перезарядка 20 секунд начинается после выхода; до вознесения не колдуется под оглушением.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "За бортом не пусто. Там просто никто не смотрит."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/self/space_phase

/datum/eldritch_knowledge/spell/space_phase/on_body_lose(mob/living/user)
	var/obj/effect/dummy/phased_mob/spell_jaunt/heretic_void/holder = user?.loc
	if(istype(holder))
		qdel(holder)
	return ..()

/obj/effect/proc_holder/spell/self/space_phase
	name = "Шаг в пустоту"
	desc = "Стоя в открытом космосе, растворитесь в пустоте: невидимым плывите по клеткам космоса без воздуха и холода. Повторное применение выводит наружу. Перезарядка 20 секунд после выхода."
	summary = "Растворитесь в космосе и плывите сквозь него невидимым."
	charge_max = HERETIC_SPACE_PHASE_COOLDOWN
	clothes_req = FALSE
	invocation_type = "none"
	phase_allowed = TRUE
	heretic_stun_check = TRUE
	action_icon = 'modular_bluemoon/icons/obj/heretic_side_lore.dmi'
	action_icon_state = "space_phase"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/space_phase/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/phased = istype(user.loc, /obj/effect/dummy/phased_mob/spell_jaunt/heretic_void)
	return heretic_check(user, isliving(user) && (phased || (isturf(user.loc) && isspaceturf(user.loc))), silent, "Шагнуть в пустоту можно только с клетки открытого космоса.")

/obj/effect/proc_holder/spell/self/space_phase/cast(list/targets, mob/living/user)
	var/obj/effect/dummy/phased_mob/spell_jaunt/heretic_void/holder = user.loc
	if(istype(holder))
		qdel(holder)
		return TRUE
	holder = new(get_turf(user))
	holder.take(user)
	revert_cast(user)
	log_game("[key_name(user)] шагнул в пустоту в [AREACOORD(holder)].")
	return TRUE

/obj/effect/dummy/phased_mob/spell_jaunt/heretic_void
	name = "void"
	var/mob/living/passenger

/obj/effect/dummy/phased_mob/spell_jaunt/heretic_void/proc/take(mob/living/user)
	passenger = user
	user.ExtinguishMob()
	user.forceMove(src)
	user.reset_perspective(src)
	ADD_TRAIT(user, TRAIT_RESISTLOWPRESSURE, REF(src))
	ADD_TRAIT(user, TRAIT_RESISTCOLD, REF(src))
	ADD_TRAIT(user, TRAIT_NOBREATH, REF(src))
	RegisterSignal(user, COMSIG_LIVING_DEATH, PROC_REF(drop_passenger))
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(passenger_deleted))
	playsound(get_turf(src), 'sound/magic/Ethereal_Enter.ogg', 40, TRUE, SILENCED_SOUND_EXTRARANGE)
	user.visible_message(span_warning("[user] истончается и тает в пустоте."), span_notice("Вы растворяетесь в пустоте. Плыть можно только по открытому космосу."))

/obj/effect/dummy/phased_mob/spell_jaunt/heretic_void/proc/drop_passenger(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// Удаляемого пассажира не выносим наружу: оболочка уходит, когда он уже покинул её.
/obj/effect/dummy/phased_mob/spell_jaunt/heretic_void/proc/passenger_deleted(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	passenger = null
	QDEL_IN(src, 1)

/obj/effect/dummy/phased_mob/spell_jaunt/heretic_void/Destroy()
	var/mob/living/user = passenger
	passenger = null
	if(user)
		UnregisterSignal(user, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		REMOVE_TRAIT(user, TRAIT_RESISTLOWPRESSURE, REF(src))
		REMOVE_TRAIT(user, TRAIT_RESISTCOLD, REF(src))
		REMOVE_TRAIT(user, TRAIT_NOBREATH, REF(src))
		if(!QDELETED(user) && user.loc == src)
			user.forceMove(get_turf(src))
			user.reset_perspective()
			playsound(get_turf(user), 'sound/magic/Ethereal_Exit.ogg', 40, TRUE, SILENCED_SOUND_EXTRARANGE)
			user.visible_message(span_warning("[user] проступает из пустоты."), span_notice("Вы выходите из пустоты."))
	return ..()

/obj/effect/dummy/phased_mob/spell_jaunt/heretic_void/relaymove(mob/user, direction)
	if(movedelay > world.time || reappearing || !direction)
		return
	var/turf/next = get_step(src, direction)
	if(!isspaceturf(next))
		movedelay = world.time + movespeed
		balloon_alert(user, "дальше не пустота")
		return
	return ..()
