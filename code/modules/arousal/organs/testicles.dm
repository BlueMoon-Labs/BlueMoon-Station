/obj/item/organ/genital/testicles
	name = "testicles"
	ru_name = "яйца" // BLUEMOON ADD
	ru_name_v = "яйцах" // BLUEMOON ADD
	ru_name_capital = "Яйца" // BLUEMOON ADD
	desc = "A male reproductive organ."
	icon_state = "testicles"
	icon = 'icons/obj/genitals/testicles.dmi'
	zone = BODY_ZONE_PRECISE_GROIN
	slot = ORGAN_SLOT_TESTICLES
	size = BALLS_SIZE_MIN
	arousal_verb = "Твои яйца немного болят от переполненности"
	unarousal_verb = "Твои яйца наконец-то перестают болеть от переполненности"
	linked_organ_slot = ORGAN_SLOT_PENIS
	genital_flags = CAN_MASTURBATE_WITH|MASTURBATE_LINKED_ORGAN|GENITAL_FUID_PRODUCTION|UPDATE_OWNER_APPEARANCE|GENITAL_UNDIES_HIDDEN|CAN_CUM_INTO|HAS_EQUIPMENT
	var/size_name = "average"
	shape = DEF_BALLS_SHAPE
	fluid_id = /datum/reagent/consumable/semen
	masturbation_verb = "massage"
	layer_index = TESTICLES_LAYER_INDEX

/obj/item/organ/genital/testicles/generate_fluid()
	if(!linked_organ && !update_link())
		return FALSE
	return ..()
	// in memoriam "Your balls finally feel full, again." ??-2020

/obj/item/organ/genital/testicles/upon_link()
	update_size()
	update_appearance()

/obj/item/organ/genital/testicles/update_size(modified = FALSE)
	switch(size)
		if(BALLS_SIZE_MIN)
			size_name = "среднего"
		if(BALLS_SIZE_DEF)
			size_name = "сжимательного"
		if(BALLS_SIZE_2)
			size_name = "большого"
		if(BALLS_SIZE_3)
			size_name = "массивного"
		if(BALLS_SIZE_MAX)
			size_name = pick(list("гигантского", "экстремального", "невероятного", "абсолютно огромного"))
		else
			size_name = "плоского"

/obj/item/organ/genital/testicles/update_appearance()
	. = ..()

	var/datum/sprite_accessory/S = GLOB.balls_shapes_list[shape]
	var/icon_shape = S ? S.icon_state : "single"
	var/lovershape = lowertext(S ? S.icon_state : "single")

	icon_state = "testicles_[icon_shape]_[size]"

	switch(lovershape)
		if("single")
			lovershape = "два семенника [size_name] размера."
		if("sheath")
			lovershape = "два семенника [size_name] размера и генитальные ножны повыше."
		else
			lovershape = "пустоту где вы могли ожидать Яйца"

	if(owner)
		if(owner.dna.species.use_skintones && owner.dna.features["genitals_use_skintone"])
			if(ishuman(owner))
				var/mob/living/carbon/human/H = owner
				color = SKINTONE2HEX(H.skin_tone)
				if(!H.dna.skin_tone_override)
					icon_state += "_s"
		else
			color = "#[owner.dna.features["balls_color"]]"

	desc = "Вы наблюдаете [lovershape]"

	if(owner)
		if(owner.dna.species.use_skintones && owner.dna.features["genitals_use_skintone"])
			if(ishuman(owner)) // Check before recasting type, although someone fucked up if you're not human AND have use_skintones somehow...
				var/mob/living/carbon/human/H = owner // only human mobs have skin_tone, which we need.
				color = SKINTONE2HEX(H.skin_tone)
				if(!H.dna.skin_tone_override)
					icon_state += "_s"
		else
			color = "#[owner.dna.features["balls_color"]]"

/obj/item/organ/genital/testicles/get_features(mob/living/carbon/human/H)
	var/datum/dna/D = H.dna
	if(D.species.use_skintones && D.features["genitals_use_skintone"])
		color = SKINTONE2HEX(H.skin_tone)
	else
		color = "#[D.features["balls_color"]]"
	shape = D.features["balls_shape"]
	size = D.features["balls_size"]
	fluid_rate = D.features["balls_cum_rate"]
	fluid_mult = D.features["balls_cum_mult"]
	fluid_efficiency = D.features["balls_efficiency"]
	toggle_visibility(D.features["balls_visibility"], FALSE)
	if(D.features["balls_stuffing"])
		toggle_visibility(GEN_ALLOW_EGG_STUFFING, FALSE)
	if(D.features["inert_eggs"])
		AddComponent(/datum/component/ovipositor)
	if(D.features["balls_accessible"])
		toggle_accessibility(TRUE)
