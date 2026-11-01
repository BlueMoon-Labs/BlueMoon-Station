/obj/item/summon_chalk
	name = "summon chalk"
	desc = "A weird chalk covered in ectoplasm."
	icon = 'modular_bluemoon/icons/obj/lewd_items/qareen_chalk.dmi'
	icon_state = "chalk_pink"
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_TINY

/obj/item/summon_chalk/afterattack(atom/target, mob/user as mob, proximity)
	if(!proximity || !istype(target, /turf/open/floor))
		return
	if(!(GLOB.master_mode in list(ROUNDTYPE_EXTENDED, ROUNDTYPE_DYNAMIC_LIGHT)))
		to_chat(user, "<span class='warning'>Unfortunately, magic does not work.</span>") //*boowomp
		return

	visible_message("<span class='notice'>[user] starts scribe some kind of runes!</span>")
	if(do_after(user, 1.5 SECONDS, target))
		new /obj/effect/summon_rune(target)
		qdel(src)

/obj/effect/summon_rune
	name = "Lewd summon rune"
	desc = "It is believed this rune is capable of summoning horny creatures!"
	icon = 'modular_bluemoon/icons/obj/lewd_items/qareen_chalk.dmi'
	icon_state = "rune_pink"
	light_color = LIGHT_COLOR_PINK
	anchored = TRUE
	var/cooldown = 0

/obj/effect/summon_rune/Initialize(mapload)
	. = ..()
	set_light(2)

/obj/effect/summon_rune/Destroy(force)
	//в руне лежат отобранные у призванного рюкзак и пояс: родитель удалил бы их вместе с ней
	var/turf/stash_turf = stash_fallback_turf()
	if(stash_turf)
		for(var/obj/item/stashed in contents)
			stashed.forceMove(stash_turf)
	return ..()

/obj/effect/summon_rune/proc/stash_fallback_turf()
	return get_turf(src)

/obj/effect/summon_rune/attack_hand(mob/living/carbon/M)
	if(cooldown > world.time)// ~
		to_chat(M, span_userdanger("Need to wait before new rite!"))
		return

	if(tgui_alert(M, "Do you want to attempt to summon?", "Attempt to summon?", list("Yes", "No")) != "Yes")
		return
	if(cooldown > world.time) // Двойная проверка на случай если сразу двое тыкнуть по руне
		to_chat(M, span_userdanger("Someone started the rite!"))
		return

	cooldown = world.time + 40 SECONDS

	var/list/candidates = summon_candidates()
	if(!length(candidates))
		to_chat(M, span_userdanger("Nobody to summon!"))
		return
	var/target_info = input(M, "Please, select a person to summon!", "Select") as null|anything in candidates
	if(!target_info)
		return
	try_summon(M, candidates[target_info])

/obj/effect/summon_rune/proc/can_be_summoned(mob/living/carbon/human/candidate)
	if(QDELETED(candidate) || !candidate.client)
		return FALSE
	if(!HAS_TRAIT(candidate, TRAIT_LEWD_SUMMON) || HAS_TRAIT(candidate, TRAIT_LEWD_SUMMONED))
		return FALSE
	return !iszombie_infectious(candidate)

/// Подпись -> моб. Одинаковые подписи нумеруются: раньше выбор по индексу уходил не тому человеку.
/obj/effect/summon_rune/proc/summon_candidates()
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in GLOB.carbon_list)
		if(!can_be_summoned(H))
			continue
		var/species = "[H.dna.species]"
		if(H.dna.custom_species)
			species = "[H.dna.custom_species]"
		var/label = "[H.gender] [species]"
		if(H.client.prefs?.summon_nickname)
			label = "[H.client.prefs.summon_nickname], [label]"
		var/unique_label = label
		var/same_label_count = 1
		while(candidates[unique_label])
			unique_label = "[label] ([++same_label_count])"
		candidates[unique_label] = H
	return candidates

/obj/effect/summon_rune/proc/try_summon(mob/living/summoner, mob/living/carbon/human/target)
	if(QDELETED(target) || HAS_TRAIT(target, TRAIT_LEWD_SUMMONED)) // Двойная проверка на случай если призываемого уже призвали
		to_chat(summoner, span_userdanger("It seems that this soul has already been called by someone else!"))
		return FALSE
	if(!ask_summon_consent(summoner, target))
		return FALSE
	if(QDELETED(src) || QDELETED(summoner) || QDELETED(target))
		return FALSE
	if(HAS_TRAIT(target, TRAIT_LEWD_SUMMONED)) // пока цель отвечала, её мог призвать кто-то другой
		to_chat(summoner, span_userdanger("It seems that this soul has already been called by someone else!"))
		return FALSE

	if(istype(get_area(src), /area/hilbertshotelstorage)) // Отель свернулся = телепортация в подсобку 3 на 3 без воможности выбраться = плохо
		to_chat(target, span_warning("The hotel administration apologizes, the room you tried to teleport already been collapsed."))
		return FALSE

	var/old_pos = get_turf(target)
	if(istype(get_area(target), /area/hilbertshotel)) // Отель сворачивается когда в нём нету людей = телепортация в космос = плохо
		var/area/hilbertshotel/Hhotel = get_area(target)
		if(Hhotel.parentSphere)
			old_pos = get_turf(Hhotel.parentSphere)

	to_chat(summoner, span_lewd("Something is happening!"))
	var/summon_nickname = summoner.client?.prefs?.summon_nickname || "unus ex satellitibus tuis"
	if(!teleport_summoned(target, loc, TRUE, TRUE))
		to_chat(summoner, span_userdanger("Something went wrong in summoning ritual!"))
		new /obj/effect/temp_visual/yellowsparkles(loc)
		return FALSE
	summoner.say(pick("O magne Asmodee! Quaeso inducere [summon_nickname] ad me!", \
				"Coniuro te, daemon luxuriae! Utinam [summon_nickname] mea vota persolvat!", \
				"Cupidus meus ardet, magne! Amor [summon_nickname] me moveat affectus!"))
	to_chat(target, span_hypnophrase("You are turning on!"))
	new /obj/effect/summon_rune/return_rune(loc, target, old_pos, src)
	qdel(src)
	return TRUE

/// Согласие даёт только игрок в теле: агостнувшийся, гост и SSD не отвечают, и тело без них не уходит.
/obj/effect/summon_rune/proc/ask_summon_consent(mob/living/summoner, mob/living/carbon/human/target)
	if(!target.client)
		to_chat(summoner, span_userdanger("Душа не откликается: хозяина этого тела сейчас нет в нём."))
		return FALSE
	var/massage_time = world.time + 1 SECONDS //Поглощаем энтропию и теорио вероятности тыкнуть энтер в момент появления
	var/summoned_approve = TRUE
	var/summoner_info = "[summoner.gender]"
	var/mob/living/carbon/carbon_summoner = summoner
	if(istype(carbon_summoner) && carbon_summoner.dna)
		var/summoner_species = "[carbon_summoner.dna.species]"
		if(carbon_summoner.dna.custom_species)
			summoner_species = "[carbon_summoner.dna.custom_species]"
		summoner_info += " [summoner_species]"
	if(tgui_alert(target, "You have been summoned by [summoner_info]! Do you want to answer?", "Do you want to answer?", list("Yes", "No")) != "Yes")
		summoned_approve = FALSE
	else if(massage_time > world.time)
		if(tgui_alert(target, "Too quick! You are really want to answer?", "Do you really want to answer the summon?", list("Yes", "No")) != "Yes")
			summoned_approve = FALSE
	if(!target.client) // ответ дан уже не из тела: вышел в гост или агост, пока висело окно
		to_chat(summoner, span_userdanger("Душа не откликается: хозяина этого тела сейчас нет в нём."))
		return FALSE
	if(!summoned_approve)
		var/excuses = tgui_input_text(target, "Do you want to tell the summoner the reason for the refusal?", "Say Text", "", MAX_MESSAGE_LEN)
		to_chat(summoner, span_userdanger((excuses ? "You can hear at the edge of your hearing, it says, \"[excuses]\"" : "It refuses to answer!")))
		return FALSE
	return TRUE

/obj/effect/summon_rune/proc/teleport_summoned(mob/living/carbon/target, pos_to_teleport, switch_summoned = FALSE, transfer_target_items = TRUE)
	if(!target || !pos_to_teleport)
		return FALSE
	var/summoning = switch_summoned && !HAS_TRAIT_FROM(target, TRAIT_LEWD_SUMMONED, TRAIT_LEWD_SUMMONED)
	var/datum/antagonist/ghost_role/ghost_cafe/cafe_visitor = target.mind?.has_antag_datum(/datum/antagonist/ghost_role/ghost_cafe)
	if(summoning && cafe_visitor)
		target.ghost_cafe_traits(FALSE) // до прыжка: посетителя кафе испепеляет на выходе из своих зон

	//руну может уже уносить Destroy, поэтому эффекты рождаем на drop_location():
	//у выпотрошенного атома loc пуст, и spawn в null оставлял мусор в nullspace
	var/atom/rune_location = drop_location()
	var/turf/departure = get_turf(target)
	if(transfer_target_items)
		before_teleport_items(target)
	if(!do_teleport(target, pos_to_teleport, channel = TELEPORT_CHANNEL_MAGIC, forced = TRUE))
		if(summoning && cafe_visitor)
			target.ghost_cafe_traits(TRUE, cafe_visitor.adittonal_allowed_area)
		return FALSE

	if(switch_summoned)
		if(summoning)
			ADD_TRAIT(target, TRAIT_LEWD_SUMMONED, TRAIT_LEWD_SUMMONED)
		else
			REMOVE_TRAIT(target, TRAIT_LEWD_SUMMONED, TRAIT_LEWD_SUMMONED)
	if(transfer_target_items)
		after_teleport_items(target)
	if(switch_summoned && !summoning && cafe_visitor)
		target.ghost_cafe_traits(TRUE, cafe_visitor.adittonal_allowed_area) // Выдаём и забираем трэйты в разных места для ситуаций ухода госта обратно домой

	playsound(rune_location, 'modular_bluemoon/sound/effects/spook.ogg', 50, 1)
	if(departure)
		new /obj/effect/temp_visual/yellowsparkles(departure)
	if(rune_location)
		new /obj/effect/temp_visual/yellowsparkles(rune_location)
	return TRUE

/obj/effect/summon_rune/proc/before_teleport_items(mob/living/carbon/human/target)
	return

//Проклятые техники телепортации
//Призванный приходит без "нежелательного" (контейнеров): они ложатся в руну призыва, затем переезжают в руну возврата (return_rune/Initialize) и возвращаются хозяину вместе с ним
/obj/effect/summon_rune/proc/after_teleport_items(mob/living/carbon/human/target)
	// Деактивируем модсьют во избежание багов
	var/obj/item/mod/control/modsuit = target.get_item_by_slot(ITEM_SLOT_BACK)
	if(modsuit && istype(modsuit) && modsuit.is_active())
		modsuit.toggle_activate(target, TRUE)
		modsuit.conceal(target, target.shoes)
		modsuit.conceal(target, target.wear_suit)
		modsuit.conceal(target, target.gloves)
		if(istype(target.head, /obj/item/clothing/mod_part/head))
			modsuit.conceal(target, target.head)
		target.transferItemToLoc(modsuit, src, TRUE)

	if(target.back && istype(target.back, /obj/item/storage))
		target.transferItemToLoc(target.back, src, TRUE)
	if(target.belt && istype(target.belt, /obj/item/storage))
		target.transferItemToLoc(target.belt, src, TRUE)

/obj/effect/summon_rune/return_rune
	var/mob/living/carbon/returner
	var/return_pos
	var/list/listed_items = list() // Вещи призванного: вернутся с ним, где бы ни лежали

/obj/effect/summon_rune/return_rune/Initialize(mapload, mob/living/carbon/mob_to_return, var/pos_to_return, obj/effect/summon_rune/OldRune)
	. = ..()
	returner = mob_to_return
	return_pos = pos_to_return
	//вложенные тоже: ствол, вынутый из ботинок, иначе считался чужим и оставался у призывателя
	for(var/obj/item/I in mob_to_return.GetAllContents(/obj/item))
		listed_items += I
	for(var/obj/item/I in OldRune.contents)
		listed_items += I
		I.forceMove(src)
	for(var/obj/item/listed as anything in listed_items)
		RegisterSignal(listed, COMSIG_PARENT_QDELETING, PROC_REF(forget_item))
	START_PROCESSING(SSobj, src)

/obj/effect/summon_rune/return_rune/proc/forget_item(obj/item/source)
	SIGNAL_HANDLER
	listed_items -= source

/obj/effect/summon_rune/return_rune/process()
	if(!returner)
		new /obj/effect/temp_visual/yellowsparkles(drop_location())
		qdel(src)
		return

	if(QDELETED(returner) || !returner.loc)
		qdel(src)
		return

	if(!isturf(loc)) // руну убрали с пола (комната инфинити ушла в сток): тянуть к ней - значит запереть в подсобке, отпускаем домой
		qdel(src)
		return

	var/xdiff=abs(returner.x-src.x)
	var/ydiff=abs(returner.y-src.y)
	if(xdiff>=3 || ydiff>=3) // не отходим далеко от руны
		teleport_summoned(returner, src.loc, FALSE, FALSE)

/obj/effect/summon_rune/return_rune/attack_hand(mob/living/carbon/M)
	if(returner != M)
		return
	if(tgui_alert(M, "Do you want to attempt to return?", "Attempt to return?", list("Yes", "No")) != "Yes")
		return
	if(QDELETED(src) || returner != M)
		return
	if(!teleport_summoned(M, return_pos, TRUE))
		to_chat(M, span_warning("Руна мигает и гаснет: обратный путь сейчас закрыт. Попробуйте ещё раз."))
		return
	returner = null
	qdel(src)

/obj/effect/summon_rune/return_rune/Destroy(force)
	//возврат обязан отработать ДО родителя: ..() уносит руну в nullspace
	STOP_PROCESSING(SSobj, src)
	var/mob/living/carbon/returning = returner
	returner = null
	if(!QDELETED(returning) && !teleport_summoned(returning, return_pos, TRUE))
		REMOVE_TRAIT(returning, TRAIT_LEWD_SUMMONED, TRAIT_LEWD_SUMMONED) // руны больше нет - не держим призванным навсегда
	. = ..()
	return_pos = null
	listed_items = null

/obj/effect/summon_rune/return_rune/stash_fallback_turf()
	return get_turf(return_pos) || get_turf(src)

/obj/effect/summon_rune/return_rune/before_teleport_items(mob/living/carbon/human/target)
	// Деактивируем модсьют во избежание багов
	var/obj/item/mod/control/modsuit = target.get_item_by_slot(ITEM_SLOT_BACK)
	if(modsuit && istype(modsuit) && modsuit.is_active())
		modsuit.toggle_activate(target, TRUE)
		modsuit.conceal(target, target.shoes)
		modsuit.conceal(target, target.wear_suit)
		modsuit.conceal(target, target.gloves)
		if(istype(target.head, /obj/item/clothing/mod_part/head))
			modsuit.conceal(target, target.head)

	// взятое у призывателя остаётся у него
	for(var/obj/item/I in target.contents)
		if(!(I in listed_items))
			target.dropItemToGround(I, TRUE)

/// После прыжка домой: всё своё, где бы оно ни осталось, ложится к ногам хозяина.
/obj/effect/summon_rune/return_rune/after_teleport_items(mob/living/carbon/human/target)
	var/turf/home = get_turf(target)
	for(var/obj/item/stashed in contents)
		stashed.forceMove(home)
	for(var/obj/item/owned as anything in listed_items.Copy())
		if(QDELETED(owned))
			continue
		var/atom/holder = owned.loc
		if(holder == home || holder == target || (holder in listed_items))
			continue // на хозяине или в другой его вещи - едет вместе с ней
		if(ismob(holder))
			var/mob/wearer = holder
			wearer.transferItemToLoc(owned, home, TRUE)
		else
			owned.forceMove(home)
