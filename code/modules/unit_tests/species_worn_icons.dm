/// Видовой набор одежды (тешари) рисует вещь своим спрайтом только там, где он есть.
/// Без спрайта BYOND показывает безымянный стейт файла: каску, бронежилет, комбинезон или ботинки.
/datum/unit_test/species_worn_icons
	var/list/states_by_file = list()

/datum/unit_test/species_worn_icons/proc/has_state(icon_file, state)
	var/key = "[icon_file]"
	var/list/states = states_by_file[key]
	if(!states)
		states = list()
		for(var/existing in icon_states(icon_file))
			states[existing] = TRUE
		states_by_file[key] = states
	return !isnull(state) && states[state]

/datum/unit_test/species_worn_icons/proc/teshari()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	wearer.set_species(/datum/species/mammal/teshari)
	wearer.dna.features["body_model"] = MALE
	return wearer

/datum/unit_test/species_worn_icons/Run()
	var/mob/living/carbon/human/wearer = teshari()
	var/datum/species/teshari = wearer.dna.species
	TEST_ASSERT(teshari.icon_uniform && teshari.icon_head && teshari.icon_feet, "test premise: у тешари свой набор одежды")

	var/list/missing = list(
		/obj/item/clothing/under/pants/jeans = list(ITEM_SLOT_ICLOTHING, UNIFORM_LAYER, teshari.icon_uniform),
		/obj/item/clothing/head/beanie = list(ITEM_SLOT_HEAD, HEAD_LAYER, teshari.icon_head),
		/obj/item/clothing/shoes/roman = list(ITEM_SLOT_FEET, SHOES_LAYER, teshari.icon_feet),
	)
	for(var/path in missing)
		var/list/spec = missing[path]
		var/obj/item/worn = allocate(path)
		TEST_ASSERT(!has_state(spec[3], worn.icon_state), "test premise: у [path] нет тешарьского спрайта")
		TEST_ASSERT(wearer.equip_to_slot_if_possible(worn, spec[1], disable_warning = TRUE), "test premise: [path] должен надеться")
		var/mutable_appearance/overlay = wearer.overlays_standing[spec[2]]
		TEST_ASSERT_NOTNULL(overlay, "[path] на тешари не нарисован")
		TEST_ASSERT_EQUAL(overlay.icon_state, worn.icon_state, "[path] на тешари рисуется чужим стейтом")
		TEST_ASSERT(has_state(overlay.icon, overlay.icon_state), "[path] на тешари берёт стейт [overlay.icon_state] из [overlay.icon], где его нет: виден безымянный стейт файла")

	var/obj/item/clothing/shoes/jackboots/boots = allocate(/obj/item/clothing/shoes/jackboots)
	wearer.dropItemToGround(wearer.shoes, TRUE)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(boots, ITEM_SLOT_FEET, disable_warning = TRUE), "test premise: берцы должны надеться")
	var/mutable_appearance/boots_overlay = wearer.overlays_standing[SHOES_LAYER]
	TEST_ASSERT_EQUAL("[boots_overlay.icon]", "[teshari.icon_feet]", "нарисованный для тешари спрайт берцев должен остаться")

	var/mob/living/carbon/human/hooded = teshari()
	var/obj/item/clothing/suit/hooded/teshari/cloak = allocate(/obj/item/clothing/suit/hooded/teshari)
	TEST_ASSERT(hooded.equip_to_slot_if_possible(cloak, ITEM_SLOT_OCLOTHING, disable_warning = TRUE), "test premise: плащ должен надеться")
	cloak.ui_action_click(hooded)
	TEST_ASSERT_EQUAL(hooded.head, cloak.hood, "test premise: капюшон должен натянуться")
	var/mutable_appearance/hood_overlay = hooded.overlays_standing[HEAD_LAYER]
	TEST_ASSERT(has_state(hood_overlay.icon, hood_overlay.icon_state), "капюшон тешари берёт стейт [hood_overlay.icon_state] из [hood_overlay.icon], где его нет")
	var/mutable_appearance/cloak_overlay = hooded.overlays_standing[SUIT_LAYER]
	TEST_ASSERT(has_state(cloak_overlay.icon, cloak_overlay.icon_state), "плащ тешари с капюшоном берёт стейт [cloak_overlay.icon_state] из [cloak_overlay.icon], где его нет")

	sweep(teshari())

/// Каждая вещь каждого слота проходит ту же пересборку оверлея, что при надевании.
/// Поля берутся из типа и кладутся в болванку слота: Initialize и equipped() тысяч вещей тут не нужны.
/datum/unit_test/species_worn_icons/proc/sweep(mob/living/carbon/human/wearer)
	var/datum/species/species = wearer.dna.species
	var/list/slots = list(
		list(ITEM_SLOT_HEAD, /obj/item/clothing/head, species.icon_head),
		list(ITEM_SLOT_OCLOTHING, /obj/item/clothing/suit, species.icon_suit),
		list(ITEM_SLOT_ICLOTHING, /obj/item/clothing/under, species.icon_uniform),
		list(ITEM_SLOT_FEET, /obj/item/clothing/shoes, species.icon_feet),
		list(ITEM_SLOT_GLOVES, /obj/item/clothing/gloves, species.icon_hands),
		list(ITEM_SLOT_EYES, /obj/item/clothing/glasses, species.icon_eyes),
		list(ITEM_SLOT_MASK, /obj/item/clothing/mask, species.icon_mask),
		list(ITEM_SLOT_EARS_LEFT, /obj/item/clothing/ears, species.icon_ears),
		list(ITEM_SLOT_NECK, /obj/item/clothing/neck, species.icon_neck),
		list(ITEM_SLOT_BACK, /obj/item, species.icon_back),
		list(ITEM_SLOT_BELT, /obj/item, species.icon_belt),
	)
	var/species_drawn = 0
	var/fallback = 0
	var/fallback_broken_for_all = 0
	var/list/wrong = list()
	var/own_sprite_shadowed = 0
	for(var/list/slot as anything in slots)
		var/obj/item/dummy = allocate(slot[2])
		var/species_file = slot[3]
		for(var/obj/item/path as anything in typesof(/obj/item))
			if(!(initial(path.slot_flags) & slot[1]) || !initial(path.icon_state))
				continue
			dummy.icon_state = initial(path.icon_state)
			dummy.item_state = initial(path.item_state)
			dummy.mob_overlay_icon = initial(path.mob_overlay_icon)
			dummy.anthro_mob_worn_overlay = initial(path.anthro_mob_worn_overlay)
			dummy.taur_mob_worn_overlay = initial(path.taur_mob_worn_overlay)
			dummy.mutantrace_variation = initial(path.mutantrace_variation)
			var/mutable_appearance/overlay = redraw(wearer, slot[1], dummy)
			if(!overlay)
				continue
			if("[overlay.icon]" == "[species_file]")
				species_drawn++
				if(!has_state(overlay.icon, overlay.icon_state))
					wrong += "[path] -> [overlay.icon_state]"
				else if(dummy.mob_overlay_icon && has_state(dummy.mob_overlay_icon, overlay.icon_state))
					own_sprite_shadowed++
			else
				fallback++
				if(!has_state(overlay.icon, overlay.icon_state))
					fallback_broken_for_all++
	log_test("species_worn_icons: тешарьским спрайтом [species_drawn] (из них поверх своего файла вещи [own_sprite_shadowed]), обычным спрайтом [fallback] (из них без спрайта у всех видов [fallback_broken_for_all])")
	TEST_ASSERT(species_drawn > 0, "test premise: обход не нашёл ни одной вещи с тешарьским спрайтом")
	if(length(wrong))
		TEST_FAIL("[length(wrong)] вещей на тешари берут отсутствующий стейт из видового файла и показывают его безымянный стейт: [jointext(wrong.Copy(1, min(length(wrong), 15) + 1), ", ")]")

/datum/unit_test/species_worn_icons/proc/redraw(mob/living/carbon/human/wearer, slot, obj/item/dummy)
	. = null
	switch(slot)
		if(ITEM_SLOT_HEAD)
			wearer.head = dummy
			wearer.update_inv_head()
			. = wearer.overlays_standing[HEAD_LAYER]
			wearer.head = null
		if(ITEM_SLOT_OCLOTHING)
			wearer.wear_suit = dummy
			wearer.update_inv_wear_suit()
			. = wearer.overlays_standing[SUIT_LAYER]
			wearer.wear_suit = null
		if(ITEM_SLOT_ICLOTHING)
			wearer.w_uniform = dummy
			wearer.update_inv_w_uniform()
			. = wearer.overlays_standing[UNIFORM_LAYER]
			wearer.w_uniform = null
		if(ITEM_SLOT_FEET)
			wearer.shoes = dummy
			wearer.update_inv_shoes()
			. = wearer.overlays_standing[SHOES_LAYER]
			wearer.shoes = null
		if(ITEM_SLOT_GLOVES)
			wearer.gloves = dummy
			wearer.update_inv_gloves()
			. = wearer.overlays_standing[GLOVES_LAYER]
			wearer.gloves = null
		if(ITEM_SLOT_EYES)
			wearer.glasses = dummy
			wearer.update_inv_glasses()
			. = wearer.overlays_standing[GLASSES_LAYER]
			wearer.glasses = null
		if(ITEM_SLOT_MASK)
			wearer.wear_mask = dummy
			wearer.update_inv_wear_mask()
			. = wearer.overlays_standing[FACEMASK_LAYER]
			wearer.wear_mask = null
		if(ITEM_SLOT_EARS_LEFT)
			wearer.ears = dummy
			wearer.update_inv_ears()
			. = wearer.overlays_standing[EAR_LEFT_LAYER]
			wearer.ears = null
		if(ITEM_SLOT_NECK)
			wearer.wear_neck = dummy
			wearer.update_inv_neck()
			. = wearer.overlays_standing[NECK_LAYER]
			wearer.wear_neck = null
		if(ITEM_SLOT_BACK)
			wearer.back = dummy
			wearer.update_inv_back()
			. = wearer.overlays_standing[BACK_LAYER]
			wearer.back = null
		if(ITEM_SLOT_BELT)
			wearer.belt = dummy
			wearer.update_inv_belt()
			. = wearer.overlays_standing[BELT_LAYER]
			wearer.belt = null
