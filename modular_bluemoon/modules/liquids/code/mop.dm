// Remove liquids from a turf using a mop.
/obj/item/mop/attack_liquids_turf(turf/target_turf, mob/living/user, obj/effect/abstract/liquid_turf/liquids)
	if(!in_range(user, target_turf))
		return FALSE

	var/free_space = reagents.maximum_volume - reagents.total_volume
	if(free_space <= 0)
		to_chat(user, span_warning("Your [src] can't absorb any more liquid!"))
		return TRUE

	var/datum/reagents/tempr = liquids.take_reagents_flat(free_space)
	tempr.trans_to(reagents, tempr.total_volume)
	to_chat(user, span_notice("You soak \the [src] with some liquids."))
	qdel(tempr)
	user.changeNext_move(CLICK_CD_MELEE)
	return TRUE
