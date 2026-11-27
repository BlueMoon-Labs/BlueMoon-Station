// ПЕРЕМЕННЫЕ ДЛЯ МОБОВ

/mob/living
	var/can_pull_superheavy_entities = FALSE // сокращаем количество проверок

/mob/living/carbon/alien // Чужие могут тянуть сверхтяжёлых персонажей
	can_pull_superheavy_entities = TRUE

/mob/living/silicon // Киборгам хватает сил тянуть сверхтяжей
	can_pull_superheavy_entities = TRUE

/mob/living/silicon/pai // Это наследник киборгов, ему нельзя тянуть сверхтяжей. ПИИ-мышка, нет-нет
	can_pull_superheavy_entities = FALSE

/mob/living/simple_animal/slaughter // Демон резни должен мочь тянуть, чтобы затаскивать их в кровь
	can_pull_superheavy_entities = TRUE

// Общая проверка силы: используется и при начале захвата, и при снятии РИГа.
/mob/living/proc/can_pull_superheavy_mob()
	if(can_pull_superheavy_entities || mob_weight > MOB_WEIGHT_NORMAL)
		return TRUE
	var/datum/martial_art/puller_martial_art = mind?.martial_art
	if(puller_martial_art && (puller_martial_art.id in list(MARTIALART_SLEEPINGCARP, MARTIALART_CQC, MARTIALART_PLASMAFIST, MARTIALART_BOUNCER, MARTIALART_RISINGBASS)))
		if(puller_martial_art.can_use(src))
			return TRUE
	if(!ishuman(src))
		return FALSE
	var/mob/living/carbon/human/human_pulling = src
	if(mind?.antag_datums && !mind.has_antag_datum(/datum/antagonist/ghost_role))
		return TRUE
	if(human_pulling.dna?.check_mutation(HULK))
		return TRUE
	if(istype(human_pulling.back, /obj/item/mod/control))
		var/obj/item/mod/control/mod = human_pulling.back
		if(mod.is_active() && istype(mod.selected_module, /obj/item/mod/module/clamp))
			return TRUE
	return !!get_rig_pull_support()

/// Only an actually equipped, live, assisting RIG qualifies.
/mob/living/proc/get_rig_pull_support()
	return null

/mob/living/carbon/human/get_rig_pull_support()
	var/obj/item/clothing/suit/space/hardsuit/rig = wear_suit
	if(istype(rig) && !QDELETED(rig) && rig.loc == src && rig.rig_support_wearer == src && rig.rig_superheavy_pull_slowdown >= 0)
		return rig

/mob/can_be_pulled(user)
	if(isliving(user) && mob_weight > MOB_WEIGHT_HEAVY)
		var/mob/living/user_mob = user
		if(!user_mob.can_pull_superheavy_mob())
			user_mob.visible_message("[user] пробует потянуть [src] за собой, но это безуспешно!", span_warning("[src] ощущается слишком грузно, переместить в таком виде будет невозможно!"))
			to_chat(user, span_warning(span_small("Для перемещения сверхтяжёлого нужна достаточная сила, подходящее боевое искусство, активная клешня MOD или РИГ с усиленным каркасом.")))
			playsound(src.loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
			stop_pulling()
			return FALSE
	return ..()
