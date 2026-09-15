// TRAIT_DETECTIVES_TASTE (skillchip "Detectives Taste") lets the user identify the exact reagents (and blood types) by taste.
/mob/living/taste(datum/reagents/from)
	if(HAS_TRAIT(src, TRAIT_DETECTIVES_TASTE))
		return detectives_taste(from)
	return ..()

/// Precise tasting: reports the exact name of every reagent (or the blood type) being tasted.
/mob/living/proc/detectives_taste(datum/reagents/from)
	if(last_taste_time + 50 > world.time)
		return FALSE
	var/list/tastes = list()
	for(var/datum/reagent/R in from.reagent_list)
		if(!R.taste_mult || R.volume <= 0)
			continue
		if(istype(R, /datum/reagent/blood))
			var/blood_type = R.data?["blood_type"]
			tastes += blood_type ? "кровь группы [blood_type]" : "кровь неизвестной группы"
		else
			tastes += lowertext(R.name)
	var/text_output = tastes.len ? english_list(tastes, and_text = " и ", comma_text = ", ") : "нечто неописуемое"
	if(text_output != last_taste_text || last_taste_time + 100 < world.time)
		to_chat(src, "<span class='notice'>Вы чувствуете вкус: [text_output].</span>")
		last_taste_time = world.time
		last_taste_text = text_output
	return TRUE