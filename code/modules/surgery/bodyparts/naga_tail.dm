#define NAGA_TAIL_BUFF_MULT 1.2
#define NAGA_TAIL_INJURY_CHANCE 50

// Хвост занимает одну запись bodyparts; обе зоны ног ссылаются на неё через get_bodypart().
/obj/item/bodypart/l_leg/naga_tail
	name = "supporting tail"
	desc = "Отделённый опорный хвост. Его можно пришить обратно хирургическим путём."
	icon = 'icons/obj/naga_tail_item.dmi'
	icon_state = "naga_tail"
	ru_name = "хвост"
	ru_name_v = "хвосте"
	ru_name_y = "хвост"
	ru_name_capital = "Хвост"
	// Анатомический флаг хвоста не меняется при выборе покрытия одежды через get_clothing_zone().
	body_part = GROIN
	// Запасы и восстановление равны двум обычным ногам с усилением
	max_damage = /obj/item/bodypart/l_leg::max_damage * 2 * NAGA_TAIL_BUFF_MULT
	max_stamina_damage = /obj/item/bodypart/l_leg::max_stamina_damage * 2 * NAGA_TAIL_BUFF_MULT
	disable_threshold = /obj/item/bodypart/l_leg::disable_threshold * 2 * NAGA_TAIL_BUFF_MULT
	stam_heal_tick = STAM_RECOVERY_LIMB * 2 * NAGA_TAIL_BUFF_MULT
	use_digitigrade = NOT_DIGITIGRADE
	px_x = 0
	px_y = 0
	dmg_overlay_type = ""
	w_class = WEIGHT_CLASS_NORMAL
	var/taur_style = "Naga"
	var/tail_item_icon = 'icons/obj/naga_tail_item.dmi'
	var/tail_item_state = "naga_tail"
	var/tail_item_color
	var/tail_item_extra_state = "naga_tail_cut"
	var/tail_item_extra2_state
	var/tail_item_extra_color = NONE
	var/tail_item_extra2_color

/obj/item/bodypart/l_leg/naga_tail/update_limb(dropping_limb, mob/living/carbon/source)
	. = ..()
	// Обычный спрайт ноги и её маски не должны появляться поверх таврического тела.
	dmg_overlay_type = ""
	use_digitigrade = NOT_DIGITIGRADE
	if(no_update)
		return
	var/mob/living/carbon/appearance_source = source || owner
	if(appearance_source?.dna)
		taur_style = appearance_source.dna.features["taur"]
		tail_item_color = "#[appearance_source.dna.features["mcolor"]]"
		var/datum/sprite_accessory/taur/taur = GLOB.taur_list[taur_style]
		if(taur)
			tail_item_icon = taur.severed_item_icon
			tail_item_state = taur.severed_item_state
			tail_item_extra_state = taur.severed_item_extra_state
			tail_item_extra2_state = taur.severed_item_extra2_state
			if(ishuman(appearance_source))
				var/mob/living/carbon/human/human = appearance_source
				// Цвета хранятся на предмете: после отсечения ему не нужна ссылка на донора.
				if(tail_item_icon != 'icons/obj/surgery.dmi' || tail_item_state != "severedtail")
					tail_item_color = taur.do_colouration ? taur.get_severed_color(human, taur.color_src, 1) : null
				if(isnull(taur.severed_item_extra_color_src))
					tail_item_extra_color = taur.get_severed_color(human, taur.extra_color_src, 2)
				else
					tail_item_extra_color = taur.get_severed_color(human, taur.severed_item_extra_color_src)
				if(isnull(taur.severed_item_extra2_color_src))
					tail_item_extra2_color = taur.get_severed_color(human, taur.extra2_color_src, 3)
				else
					tail_item_extra2_color = taur.get_severed_color(human, taur.severed_item_extra2_color_src)

/datum/sprite_accessory/taur/proc/get_severed_color(mob/living/carbon/human/human, source, channel = 0)
	if(!source)
		return null
	// Явный источник выбирает канал палитры; переданный канал сохраняет прежние настройки предмета.
	if(!channel)
		channel = source == MUTCOLORS2 ? 2 : (source == MUTCOLORS3 ? 3 : 1)
	var/datum/species/species = human.dna.species
	var/advanced = human.dna.features["color_scheme"] == ADVANCED_CHARACTER_COLORING
	var/primary = human.dna.features[advanced ? "taur_primary" : "mcolor"] || human.dna.features["mcolor"] || "FFFFFF"
	var/secondary = human.dna.features[advanced ? "taur_secondary" : "mcolor2"] || human.dna.features["mcolor2"] || "FFFFFF"
	var/tertiary = human.dna.features[advanced ? "taur_tertiary" : "mcolor3"] || human.dna.features["mcolor3"] || "FFFFFF"
	var/selected_color = channel == 1 ? primary : (channel == 2 ? secondary : tertiary)
	switch(source)
		if(SKINTONE)
			return SKINTONE2HEX(human.skin_tone)
		if(MUTCOLORS)
			return "#[species.fixed_mut_color || selected_color]"
		if(MUTCOLORS2)
			return "#[species.fixed_mut_color2 || selected_color]"
		if(MUTCOLORS3)
			return "#[species.fixed_mut_color3 || selected_color]"
		if(HAIR)
			return "#[human.hair_color == "mutcolor" ? human.dna.features["mcolor"] : human.hair_color]"
		if(FACEHAIR)
			return "#[human.facial_hair_color]"
		if(EYECOLOR)
			return "#[human.left_eye_color]"
		if(HORNCOLOR)
			return "#[human.dna.features["horns_color"]]"
		if(WINGCOLOR)
			return "#[human.dna.features["wings_color"]]"
		if(MATRIXED)
			var/list/red = ReadRGB("#[primary]")
			var/list/green = ReadRGB("#[secondary]")
			var/list/blue = ReadRGB("#[tertiary]")
			if(!(matrixed_sections == MATRIX_RED || matrixed_sections == MATRIX_RED_GREEN || matrixed_sections == MATRIX_RED_BLUE || matrixed_sections == MATRIX_ALL))
				red = list(0, 0, 0)
			if(!(matrixed_sections == MATRIX_GREEN || matrixed_sections == MATRIX_RED_GREEN || matrixed_sections == MATRIX_GREEN_BLUE || matrixed_sections == MATRIX_ALL))
				green = list(0, 0, 0)
			if(!(matrixed_sections == MATRIX_BLUE || matrixed_sections == MATRIX_RED_BLUE || matrixed_sections == MATRIX_GREEN_BLUE || matrixed_sections == MATRIX_ALL))
				blue = list(0, 0, 0)
			return rgb_construct_color_matrix(red[1] / 255, red[2] / 255, red[3] / 255, green[1] / 255, green[2] / 255, green[3] / 255, blue[1] / 255, blue[2] / 255, blue[3] / 255, 0, 0, 0)
	return null

/obj/item/bodypart/l_leg/naga_tail/get_clothing_zone()
	return BODY_ZONE_CHEST

/obj/item/bodypart/l_leg/naga_tail/try_dismember(wounding_type, wounding_dmg, wound_bonus, bare_wound_bonus)
	// Дополнительная проверка вдвое снижает итоговый шанс, даже если обычный уже достиг 100%.
	if(!prob(NAGA_TAIL_INJURY_CHANCE))
		return FALSE
	return ..()

/obj/item/bodypart/l_leg/naga_tail/check_woundings_mods(wounding_type, damage, wound_bonus, bare_wound_bonus)
	. = ..()
	// Броня и износ одежды рассчитываются всегда; в половине случаев сама рана не возникает.
	if(!prob(NAGA_TAIL_INJURY_CHANCE))
		return -INFINITY

/obj/item/bodypart/l_leg/naga_tail/get_limb_icon(dropped)
	if(!dropped)
		return list()
	icon_state = ""
	var/image/tail_image = image(tail_item_icon, tail_item_state)
	tail_image.color = tail_item_color
	. = list(tail_image)
	if(tail_item_extra_state)
		var/image/extra_image = image(tail_item_icon, tail_item_extra_state)
		extra_image.color = tail_item_extra_color
		. += extra_image
	if(tail_item_extra2_state)
		var/image/extra2_image = image(tail_item_icon, tail_item_extra2_state)
		extra2_image.color = tail_item_extra2_color
		. += extra2_image

/obj/item/bodypart/l_leg/naga_tail/is_disabled(silent = FALSE)
	if(!owner)
		return BODYPART_NOT_DISABLED
	if(HAS_TRAIT(owner, TRAIT_PARALYSIS) || HAS_TRAIT(owner, TRAIT_PARALYSIS_L_LEG) || HAS_TRAIT(owner, TRAIT_PARALYSIS_R_LEG))
		return BODYPART_DISABLED_PARALYSIS
	// Переломы позвонков ухудшают движение, но не отключают весь опорный хвост.
	for(var/datum/wound/wound as anything in wounds)
		if(wound.disabling && !istype(wound, /datum/wound/blunt))
			return BODYPART_DISABLED_WOUND
	return BODYPART_NOT_DISABLED

/mob/living/carbon/human/proc/can_receive_naga_tail()
	return (HAS_TRAIT(src, TRAIT_NAGA_ANATOMY) || !!dna?.species?.mutant_bodyparts["taur"]) && !get_bodypart(BODY_ZONE_L_LEG) && !get_bodypart(BODY_ZONE_R_LEG)

/obj/item/bodypart/l_leg/naga_tail/attach_limb(mob/living/carbon/C, special)
	if(!ishuman(C))
		return FALSE
	var/mob/living/carbon/human/human = C
	if(!human.can_receive_naga_tail())
		return FALSE
	var/converting_anatomy = !HAS_TRAIT(C, TRAIT_NAGA_ANATOMY)
	if(converting_anatomy)
		var/list/selected = C.dna.features["innate_features"]
		if(!islist(selected))
			selected = list()
		selected |= INNATE_NAGA_TAIL
		C.dna.features["innate_features"] = selected
		ADD_TRAIT(C, TRAIT_NAGA_ANATOMY, INNATE_NAGA_TAIL)
	C.dna.features["taur"] = taur_style
	. = ..()
	ADD_TRAIT(C, TRAIT_HARD_SOLES, INNATE_NAGA_TAIL)
	for(var/datum/wound/blunt/fracture as anything in wounds)
		fracture.update_inefficiencies()
	if(converting_anatomy)
		// Пришивается принесённая конечность; синхронизация не должна создавать новый хвост.
		human.sync_innate_features()
		human.remove_status_effect(/datum/status_effect/bola_snared)
		if(human.shoes)
			human.dropItemToGround(human.shoes, TRUE)
		if(human.w_socks)
			human.dropItemToGround(human.w_socks, TRUE)
		if(human.legcuffed)
			human.dropItemToGround(human.legcuffed, TRUE)
		human.hud_used?.update_locked_slots()
	human.update_inv_wear_suit()
	human.update_inv_belt()
	human.invalidate_naga_hud()
	return TRUE

/obj/item/bodypart/l_leg/naga_tail/drop_limb(special, dismembered)
	var/mob/living/carbon/human/human = owner
	if(human?.legcuffed)
		human.dropItemToGround(human.legcuffed, TRUE)
	. = ..()
	if(istype(human) && !QDELETED(human))
		REMOVE_TRAIT(human, TRAIT_HARD_SOLES, INNATE_NAGA_TAIL)
		human.invalidate_naga_hud()
		human.update_body()
		human.update_inv_wear_suit()
		human.update_inv_belt()

/obj/item/bodypart/l_leg/naga_tail/update_part_wound_overlay()
	// Эффект кровотечения ноги не подходит хвосту; само кровотечение рассчитывается штатно.
	bleed_overlay_icon = null
	return FALSE

/obj/item/bodypart/l_leg/naga_tail/Destroy()
	var/mob/living/carbon/human/human = owner
	if(human && !QDELETED(human) && human.legcuffed)
		human.dropItemToGround(human.legcuffed, TRUE)
	if(owner)
		REMOVE_TRAIT(owner, TRAIT_HARD_SOLES, INNATE_NAGA_TAIL)
	. = ..()
	if(human && !QDELETED(human))
		human.updatehealth()
		human.update_mobility()
		human.update_body()
		human.invalidate_naga_hud()

/mob/living/carbon/human/proc/invalidate_naga_hud()
	cached_health_hud_signature = null
	var/atom/movable/screen/healthdoll/doll = hud_used?.healthdoll
	if(doll)
		doll.doll_cache_key = null
	update_health_hud()

// Основа куклы и состояния хвоста хранятся в отдельном core-атласе.
GLOBAL_VAR_INIT(naga_doll_icon, 'icons/mob/naga_healthdoll.dmi')

// Вызывается при смене ДНК и применении настроек, а не в Life или обработчике движения.
/mob/living/carbon/human/proc/sync_naga_anatomy()
	if(!dna?.species)
		return
	var/list/selected = dna.features["innate_features"]
	var/datum/sprite_accessory/taur/taur = GLOB.taur_list[dna.features["taur"]]
	var/wanted = islist(selected) && (INNATE_NAGA_TAIL in selected) && istype(taur, /datum/sprite_accessory/taur/naga) && !!dna.species.mutant_bodyparts["taur"]
	if(wanted == HAS_TRAIT(src, TRAIT_NAGA_ANATOMY))
		return
	if(wanted)
		// Получаем обе исходные ноги до включения перенаправления зон.
		var/obj/item/bodypart/left = get_bodypart(BODY_ZONE_L_LEG)
		var/obj/item/bodypart/right = get_bodypart(BODY_ZONE_R_LEG)
		var/obj/item/bodypart/l_leg/naga_tail/tail = new
		tail.update_limb(FALSE, src)
		if(ROBOTIC_LIMBS in dna.species.species_traits)
			tail.change_bodypart_status(BODYPART_ROBOTIC)
		// Освобождаем зону для новой опоры до пересчётов движения в drop_limb().
		// Старые ноги пока сохраняют владельца для штатной очистки ран и подписок.
		bodyparts -= left
		ADD_TRAIT(src, TRAIT_NAGA_ANATOMY, INNATE_NAGA_TAIL)
		tail.attach_limb(src)
		left?.drop_limb(TRUE)
		right?.drop_limb(TRUE)
		qdel(left)
		qdel(right)
		remove_status_effect(/datum/status_effect/bola_snared)
		if(shoes)
			dropItemToGround(shoes, TRUE)
		if(w_socks)
			dropItemToGround(w_socks, TRUE)
		if(legcuffed)
			dropItemToGround(legcuffed, TRUE)
	else
		var/obj/item/bodypart/l_leg/naga_tail/tail = locate() in bodyparts
		bodyparts -= tail
		REMOVE_TRAIT(src, TRAIT_NAGA_ANATOMY, INNATE_NAGA_TAIL)
		regenerate_limb(BODY_ZONE_L_LEG)
		regenerate_limb(BODY_ZONE_R_LEG)
		tail?.drop_limb(TRUE)
		qdel(tail)
	update_body()
	update_mobility()
	invalidate_naga_hud()
	hud_used?.update_locked_slots()

/mob/living/carbon/human/newBodyPart(zone, robotic, fixed_icon)
	if(HAS_TRAIT(src, TRAIT_NAGA_ANATOMY) && (zone == BODY_ZONE_L_LEG || zone == BODY_ZONE_R_LEG))
		var/obj/item/bodypart/l_leg/naga_tail/tail = new
		tail.update_limb(fixed_icon, src)
		if(robotic)
			tail.change_bodypart_status(BODYPART_ROBOTIC)
		return tail
	return ..()

#undef NAGA_TAIL_BUFF_MULT
#undef NAGA_TAIL_INJURY_CHANCE
