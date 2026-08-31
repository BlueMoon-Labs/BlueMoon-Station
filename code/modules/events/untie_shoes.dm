/datum/round_event_control/untied_shoes
	name = "Untied Shoes"
	typepath = /datum/round_event/untied_shoes
	// Роняет игроков на пол: физическая помеха, а не фон - в мягких профилях режется.
	weight = 50
	max_occurrences = 25
	alert_observers = TRUE
	category = EVENT_CATEGORY_FRIENDLY
	disruption = DIRECTOR_DISRUPTION_MILD

/datum/round_event/untied_shoes
	fakeable = FALSE

/datum/round_event/untied_shoes/start()
	var/budget = rand(5 SECONDS,20 SECONDS)
	for(var/mob/living/carbon/C in shuffle(GLOB.alive_mob_list))
		if(!C.client)
			continue
		if(C.stat == DEAD)
			continue
		if (HAS_TRAIT(C,TRAIT_EXEMPT_HEALTH_EVENTS))
			continue
		// В слот обуви попадают и МОД-ботинки (/obj/item/clothing/mod_part/shoes),
		// а они не наследуются от /obj/item/clothing/shoes и шнурков не имеют:
		// объявленный тип переменной слота не гарантирует фактический.
		var/obj/item/clothing/shoes/worn_shoes = C.shoes
		if(!istype(worn_shoes) || !worn_shoes.can_be_tied || worn_shoes.tied != SHOES_TIED || worn_shoes.lace_time > budget)
			continue
		if(!is_station_level(C.z) && prob(50))
			continue
		if(prob(5))
			worn_shoes.adjust_laces(SHOES_KNOTTED)
			budget -= worn_shoes.lace_time // doubling up on the budget removal on purpose
		else
			worn_shoes.adjust_laces(SHOES_UNTIED)
		budget -= worn_shoes.lace_time
		if(budget < 5 SECONDS)
			return
