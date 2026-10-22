/datum/blood_oath/heist
	name = "Добыча"
	key = "heist"
	summary = "украсть две ценности и спрятать их"
	weight = 10
	capstone_type = /datum/action/cooldown/blood_bond/capstone/stash
	kit_items = list(BROTHER_KIT_BREAKIN)
	var/list/datum/objective_item/loot = list()

/datum/blood_oath/heist/Destroy()
	loot.Cut()
	return ..()

/datum/blood_oath/heist/prepare(datum/team/brother_team/for_team)
	. = ..()
	loot = add_loot_steps(for_team)
	if(!loot)
		loot = list()
		return FALSE
	add_step(new /datum/blood_oath_step/heist_stash)
	var/list/loot_names = loot_step_names()
	story = "Вам нужны деньги на новую жизнь: добудьте [loot_names[1]] и [loot_names[2]] и спрячьте так, чтобы никто не нашёл."
	return TRUE

/// Два шага «взять ценность» с разными целями кражи; возвращает ценности или null
/datum/blood_oath/proc/add_loot_steps(datum/team/brother_team/for_team)
	var/datum/objective_item/first_loot = brother_steal_pick(for_team)
	if(!first_loot)
		return null
	var/datum/objective_item/second_loot = brother_steal_pick(for_team, list(first_loot.targetitem))
	if(!second_loot)
		return null
	. = list(first_loot, second_loot)
	for(var/datum/objective_item/loot_info as anything in .)
		var/datum/blood_oath_step/heist_item/item_step = add_step(new /datum/blood_oath_step/heist_item)
		item_step.set_loot(loot_info)

/datum/blood_oath/proc/loot_step_names()
	. = list()
	for(var/datum/blood_oath_step/heist_item/item_step in steps)
		. += item_step.item_name

/datum/blood_oath_step/heist_item
	var/item_type
	var/item_name
	var/datum/objective_item/item_info

/datum/blood_oath_step/heist_item/Destroy()
	item_info = null
	return ..()

/datum/blood_oath_step/heist_item/proc/set_loot(datum/objective_item/loot_info)
	item_info = loot_info
	item_type = loot_info.targetitem
	item_name = brother_item_name(loot_info)
	name = "Взять: [item_name]"
	desc = "Добудьте [item_name] и держите при себе: в руках, в сумке или в кармане."

/datum/blood_oath_step/heist_item/can_seal(mob/living/sealer)
	if(brother_team_holds(oath.team, item_type, item_info))
		return TRUE
	return "никто из братьев не несёт [item_name]"

/datum/blood_oath_step/heist_item/condition_text(mob/living/viewer, sealable)
	return "на брате: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/heist_stash
	name = "Спрятать добычу"
	desc = "Обе вещи в одном ящике, шкафу или сумке на полу в техтоннелях. Скрепить, стоя рядом со схроном."

/datum/blood_oath_step/heist_stash/can_seal(mob/living/sealer)
	if(find_stash(sealer))
		return TRUE
	return "нужен схрон в техтоннелях рядом: ящик или сумка с добычей"

/datum/blood_oath_step/heist_stash/condition_text(mob/living/viewer, sealable)
	return "рядом схрон с добычей: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/heist_stash/proc/find_stash(mob/living/sealer)
	var/turf/sealer_turf = get_turf(sealer)
	var/datum/blood_oath/heist/heist_oath = oath
	if(!sealer_turf || !istype(heist_oath) || !length(heist_oath.loot))
		return null
	for(var/obj/container in range(BROTHER_HEIST_STASH_RANGE, sealer_turf))
		if(!isturf(container.loc) || !(istype(container, /obj/structure/closet) || istype(container, /obj/item/storage)))
			continue
		if(!brother_area_is(container, list(/area/maintenance)))
			continue
		if(stash_holds_loot(container, heist_oath.loot))
			return container
	return null

/datum/blood_oath_step/heist_stash/proc/stash_holds_loot(obj/container, list/datum/objective_item/loot)
	for(var/datum/objective_item/loot_info as anything in loot)
		if(!brother_holder_has(container, loot_info))
			return FALSE
	return TRUE
