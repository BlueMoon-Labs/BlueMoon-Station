/// Ties the target's shoes
/datum/smite/knot_shoes
	name = "Knot Shoes"

/datum/smite/knot_shoes/effect(client/user, mob/living/target)
	. = ..()
	if (!iscarbon(target))
		to_chat(user, span_warning("This must be used on a carbon mob."), confidential = TRUE)
		return
	var/mob/living/carbon/dude = target
	var/obj/item/clothing/shoes/sick_kicks = dude.shoes
	// МОД-ботинки лежат в том же слоте, но это /obj/item/clothing/mod_part/shoes - у них нет can_be_tied.
	if (!istype(sick_kicks) || !sick_kicks.can_be_tied)
		to_chat(user, span_warning("[dude] does not have knottable shoes!"), confidential = TRUE)
		return
	sick_kicks.adjust_laces(SHOES_KNOTTED)
