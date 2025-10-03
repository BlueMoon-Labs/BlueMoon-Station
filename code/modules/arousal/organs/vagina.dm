/obj/item/organ/genital/vagina
	name = "vagina"
	ru_name = "вагина" // BLUEMOON ADD
	ru_name_v = "вагине" // BLUEMOON ADD
	ru_name_capital = "Вагина" // BLUEMOON ADD
	desc = "A female reproductive organ."
	icon = 'icons/obj/genitals/vagina.dmi'
	icon_state = ORGAN_SLOT_VAGINA
	zone = BODY_ZONE_PRECISE_GROIN
	slot = ORGAN_SLOT_VAGINA
	linked_organ_slot = ORGAN_SLOT_WOMB // BLUEMOON ADD
	size = 1 //There is only 1 size right now
	shape = DEF_VAGINA_SHAPE
	genital_flags = CAN_MASTURBATE_WITH|CAN_CLIMAX_WITH|GENITAL_CAN_AROUSE|GENITAL_UNDIES_HIDDEN|CAN_CUM_INTO|HAS_EQUIPMENT
	masturbation_verb = "мастурбировать"
	arousal_verb = "Вы чувствуете сильную влагу в вашей промежности"
	unarousal_verb = "Возбуждение пропадает, влаги становится меньше"
	fluid_transfer_factor = 0.1 //Yes, some amount is exposed to you, go get your AIDS
	layer_index = VAGINA_LAYER_INDEX
	var/cap_length = 8//D   E   P   T   H (cap = capacity)
	var/cap_girth = 12
	var/cap_girth_ratio = 1.5
	var/clits = 1
	var/clit_diam = 0.25
	var/clit_len = 0.25
	var/list/vag_types = list("tentacle", "dentata", "hairy", "gaping", "spade", "furred", "cloaca", "equine", "cervine", "sergal", "feline", "hemi", "puffy", "cloaca_teshari")

/obj/item/organ/genital/vagina/update_appearance()
	. = ..()
	icon_state = "vagina"
	var/lowershape = lowertext(shape)
	var/details

	switch(lowershape)
		if("tentacle")
			details = "Отверстие закрыто половыми губами, оно покрыто несколькими щупальцами и они "
		if("dentata")
			details = "Внутри и снаружи есть зубы, и они "
		if("hairy")
			details = "На ней довольно много волос и они "
		if("human")
			details = "Она подтянута, не имеет на своей поверхности сильно много волос, обладает особо гладкой и нежной кожей, и её губы "
		if("gaping")
			details = "Она слегка приоткрыта, не имеет большой растительности и её половые губы "
		if("spade")
			details = "По форме она похожа на собачью лопатку и её половые губы "
		if("furred")
			details = "Она имеет аккуратно ухоженный мех вокруг половых губок, которые "
		if("cloaca")
			details = "Это узкое, небольшое горизонтальное отверстие и внешние губы "
		if("equine")
			details = "Она по форме напоминает конические очертания, не имеет рядом густой растительности, губы крайне выраженны и "
		if("cervine")
			details = "Она по форме напоминает конические очертания, и сама по себе выглядит чуть утонченней губками, они "
		if("sergal")
			details = "Она по форме ничем не отличается от обычных половых губ, однако над клитором, заметна толстенькая тентакля что свободно двигается и "
		if("feline")
			details = "Это узкое, малые шириной и длинной кошачья киска и внешние губы "
		if("hemi")
			details = "Она подтянута, виднеется два половых отверстия и обладает особо гладкой и нежной кожей, и её губы "
		if("puffy")
			details = "Она имеет крайне пушыстую и аккуратно ухоженную вокруг половых губок мех, которые "
		if("teshari")
			details = "Это узкое, небольшое горизонтальное отверстие миниатюрного как и владелец отверстие, и внешние губы "
		else
			details = "Она имеет экзотическую форму и её губы "
	if(aroused_state)
		details += "пропитаны женскими секретами."
	else
		details += "кажутся сухими."

	desc = "Вы наблюдаете вагину. [details]"

	if(owner)
		if(owner.dna.species.use_skintones && owner.dna.features["genitals_use_skintone"])
			if(ishuman(owner)) // Check before recasting type, although someone fucked up if you're not human AND have use_skintones somehow...
				var/mob/living/carbon/human/H = owner // only human mobs have skin_tone, which we need.
				color = SKINTONE2HEX(H.skin_tone)
				if(!H.dna.skin_tone_override)
					icon_state += "_s"
		else
			color = "#[owner.dna.features["vag_color"]]"
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.update_genitals()

/obj/item/organ/genital/vagina/get_features(mob/living/carbon/human/H)
	var/datum/dna/D = H.dna
	if(D.species.use_skintones && D.features["genitals_use_skintone"])
		color = SKINTONE2HEX(H.skin_tone)
	else
		color = "[D.features["vag_color"]]"
	shape = "[D.features["vag_shape"]]"
	toggle_visibility(D.features["vag_visibility"], FALSE)
	if(D.features["vag_stuffing"])
		toggle_visibility(GEN_ALLOW_EGG_STUFFING, FALSE)
	if(D.features["vag_accessible"])
		toggle_accessibility(TRUE)
