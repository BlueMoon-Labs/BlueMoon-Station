/obj/effect/particle_effect/smoke/aphrodisiac
	color = "#FFADFF"
	alpha = 100
	lifetime = 3
	opaque = FALSE

/obj/effect/particle_effect/smoke/aphrodisiac/smoke_mob(mob/living/carbon/C)
	. = ..()
	if(!.)
		return
	var/reagent_amount = C.reagents.get_reagent_amount(/datum/reagent/drug/aphrodisiac)
	if(reagent_amount < 10)
		C.reagents.add_reagent(/datum/reagent/drug/aphrodisiac, 10 - reagent_amount)

/datum/effect_system/smoke_spread/aphrodisiac
	effect_type = /obj/effect/particle_effect/smoke/aphrodisiac
