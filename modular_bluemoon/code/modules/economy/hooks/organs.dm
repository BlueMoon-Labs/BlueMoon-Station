/obj/item/organ
	/// Вырос в существе из кубика: NT такие органы не покупает
	var/econ_cube_grown = FALSE

/obj/item/organ/examine(mob/user)
	. = ..()
	if(econ_cube_grown)
		. += span_notice("Орган существа, выросшего из кубика: NT такие органы не покупает.")

/datum/export/organs/get_cost(obj/O, allowed_categories = NONE, apply_elastic = TRUE)
	var/obj/item/organ/organ = O
	if(istype(organ) && organ.econ_cube_grown)
		return 0
	return ..()

/proc/econ_mark_cube_grown(mob/living/creature)
	if(!iscarbon(creature))
		return
	var/mob/living/carbon/body = creature
	for(var/obj/item/organ/organ as anything in body.internal_organs)
		organ.econ_cube_grown = TRUE

/obj/item/reagent_containers/food/snacks/cube/examine(mob/user)
	. = ..()
	if(ispath(dried_being, /mob/living/carbon))
		. += span_notice("Органы выросшего из кубика существа NT не покупает.")
