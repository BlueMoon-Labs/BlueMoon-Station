// TRAIT_REMOTE_TASTING (skillchip "What's This?" / "Чтоо это?") lets you sample reagents by simply examining containers, food and the supermatter.
/obj/item/reagent_containers/examine(mob/user)
	. = ..()
	if(isliving(user) && HAS_TRAIT(user, TRAIT_REMOTE_TASTING))
		var/mob/living/living_user = user
		living_user.taste(reagents)
		if(!reagents.get_reagent_amount(/datum/reagent/consumable/sodiumchloride))
			. += span_notice("Не хватает щепотки поваренной соли...")

/datum/component/edible/examine(datum/source, mob/user, list/examine_list)
	. = ..(source, user, examine_list)
	if(!HAS_TRAIT(user, TRAIT_REMOTE_TASTING))
		return
	var/atom/parent_item = parent
	var/fraction = min(bite_consumption / parent_item.reagents.total_volume, 1)
	checkLiked(fraction, user)
	if(!parent_item.reagents.get_reagent_amount(/datum/reagent/consumable/sodiumchloride))
		examine_list += span_notice("Не хватает щепотки поваренной соли...")
	if(isliving(user))
		var/mob/living/living_user = user
		living_user.taste(parent_item.reagents)

/obj/machinery/power/supermatter_crystal/examine(mob/user)
	. = ..()
	if(isliving(user) && HAS_TRAIT(user, TRAIT_REMOTE_TASTING))
		to_chat(user, span_warning("Вкус ошеломляющий и неописуемый!"))
		var/mob/living/living_user = user
		living_user.electrocute_act(shock_damage = 15, source = src, flags = SHOCK_NOGLOVES)
		. += span_notice("Не хватает щепотки поваренной соли...")