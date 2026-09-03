
/mob/living/carbon/human/dummy
	real_name = "Test Dummy"
	status_flags = GODMODE|CANPUSH
	mouse_drag_pointer = MOUSE_INACTIVE_POINTER
	var/in_use = FALSE
	vore_flags = NO_VORE

/mob/living/carbon/human/vore
	vore_flags = DEVOURABLE | DIGESTABLE | FEEDING

INITIALIZE_IMMEDIATE(/mob/living/carbon/human/dummy)

/mob/living/carbon/human/dummy/Destroy()
	in_use = FALSE
	for(var/key in GLOB.human_dummy_list)
		if(GLOB.human_dummy_list[key] == src)
			GLOB.human_dummy_list -= key
			break
	GLOB.dummy_mob_list -= src
	return ..()

/mob/living/carbon/human/dummy/Life()
	return

/mob/living/carbon/human/dummy/update_mobility()
	return

/mob/living/carbon/human/dummy/proc/wipe_state()
	delete_equipment()
	icon_render_key = null
	cut_overlays(TRUE)
	// Манекен из GLOB.human_dummy_list переиспользуется всем сервером, а размер считается
	// МУЛЬТИПЛИКАТИВНО: update_transform() домножает уже стоящую матрицу на resize, где
	// resize - это отношение features["body_size"] к предыдущему размеру. Инвариант тут
	// один: масштаб transform обязан совпадать с features["body_size"]. Стоит его нарушить,
	// и каждый следующий рендер умножает матрицу заново - кукла в редакторе персонажа растёт
	// с каждым кликом в геометрической прогрессии, пока не превращается в пятно.
	//
	// Нарушить инвариант просто: delete_equipment() зовёт qdel надетых вещей напрямую, а
	// dropped() у надетого не срабатывает, поэтому нормализатор размера остаётся висеть на
	// манекене и вклинивает свой update_size() между сбросом и применением префа. Снимаем
	// такие компоненты первыми - их UnregisterFromParent() сам двигает размер.
	for(var/datum/component/size_normalized/leftover as anything in GetComponents(/datum/component/size_normalized))
		qdel(leftover)
	transform = matrix()
	pixel_y = 0
	resize = RESIZE_DEFAULT_SIZE
	size_multiplier = RESIZE_NORMAL
	maptext_height = 32
	if(dna?.features)
		dna.features["body_size"] = RESIZE_DEFAULT_SIZE
	// cut_overlays() чистит сами оверлеи, но не послойный кэш, из которого apply_overlay()
	// раскладывает их обратно - иначе слои предыдущего персонажа доезжают до следующего.
	for(var/index in 1 to length(overlays_standing))
		overlays_standing[index] = null

/mob/living/carbon/human/dummy/setup_human_dna()
	create_dna(src)
	randomize_human(src)
	dna.initialize_dna(skip_index = TRUE) //Skip stuff that requires full round init.

/// Provides a dummy that is consistently bald, white, naked, etc.
/mob/living/carbon/human/dummy/consistent

/mob/living/carbon/human/dummy/consistent/setup_human_dna()
	create_dna(src)
	dna.initialize_dna(skip_index = TRUE)
	dna.features["body_markings"] = "None"
	dna.features["ears"] = "Cat"
	dna.features["ethcolor"] = COLOR_WHITE
	dna.features["frills"] = "None"
	dna.features["horns"] = "None"
	dna.features["mcolor"] = COLOR_LIME
	dna.features["moth_antennae"] = "Plain"
	dna.features["moth_markings"] = "None"
	dna.features["moth_wings"] = "Plain"
	dna.features["snout"] = "Round"
	dna.features["spines"] = "None"
	dna.features["tail_human"] = "Cat"
	dna.features["tail_lizard"] = "Smooth"


//Inefficient pooling/caching way.
GLOBAL_LIST_EMPTY(human_dummy_list)
GLOBAL_LIST_EMPTY(dummy_mob_list)

/**
  * Выдаёт манекен из слота, дожидаясь освобождения.
  *
  * regenerate - восстанавливать ли иконки, срезанные в wipe_state(). Вызывающий,
  * который сразу же одевает манекен и сам зовёт regenerate_icons()/updateappearance,
  * должен передать FALSE: иначе манекен рендерится дважды подряд, а полная
  * перерисовка гуманоида стоит ~3мс.
  */
/proc/generate_or_wait_for_human_dummy(slotkey, regenerate = TRUE)
	if(!slotkey)
		return new /mob/living/carbon/human/dummy
	var/mob/living/carbon/human/dummy/D = GLOB.human_dummy_list[slotkey]
	if(istype(D))
		UNTIL(!D.in_use)
	else
		pass()
	if(QDELETED(D))
		D = new
		GLOB.human_dummy_list[slotkey] = D
		GLOB.dummy_mob_list += D
	else if(regenerate)
		D.regenerate_icons() //they were cut in wipe_state()
	D.in_use = TRUE
	return D

/proc/generate_dummy_lookalike(slotkey, mob/target)
	if(!istype(target))
		return generate_or_wait_for_human_dummy(slotkey)

	var/mob/living/carbon/human/dummy/copycat = generate_or_wait_for_human_dummy(slotkey)

	if(iscarbon(target))
		var/mob/living/carbon/carbon_target = target
		carbon_target.dna.transfer_identity(copycat, transfer_SE = TRUE)

		if(ishuman(target))
			var/mob/living/carbon/human/human_target = target
			if(human_target?.client)
				SSquirks.AssignQuirks(human_target, human_target.client, TRUE, TRUE, null, FALSE, human_target)
			human_target.copy_clothing_prefs(copycat)

			if(human_target.client?.prefs)
				// Прописываю правильно для подключенных киентов.
				human_target.client.prefs.copy_to(copycat, icon_updates = TRUE, roundstart_checks = FALSE)
			else
				// Синхронизируем ДНА к мобам не на Z-левеле. Т.е. для тех, кто не на уровне map. Чиним превью в тгуи.
				// На всякий случай оставлю else как заглушку, по идее она должна отрабатываться когда моб без клиента, либо он отключен.
				copycat.hair_style = human_target.hair_style
				copycat.facial_hair_style = human_target.facial_hair_style
				copycat.grad_style = human_target.grad_style
				copycat.grad_color = human_target.grad_color
				copycat.left_eye_color = human_target.left_eye_color
				copycat.right_eye_color = human_target.right_eye_color
				copycat.updateappearance(icon_update=TRUE, mutcolor_update=TRUE, mutations_overlay_update=TRUE)
		else
			copycat.updateappearance(icon_update=TRUE, mutcolor_update=TRUE, mutations_overlay_update=TRUE)
	else
		//even if target isn't a carbon, if they have a client we can make the
		//dummy look like what their human would look like based on their prefs
		target?.client?.prefs?.copy_to(copycat, icon_updates=TRUE, roundstart_checks=FALSE)

	return copycat

/proc/unset_busy_human_dummy(slotkey)
	if(!slotkey)
		return
	var/mob/living/carbon/human/dummy/D = GLOB.human_dummy_list[slotkey]
	if(istype(D))
		D.wipe_state()
		D.in_use = FALSE

/proc/clear_human_dummy(slotkey)
	if(!slotkey)
		return

	var/mob/living/carbon/human/dummy/dummy = GLOB.human_dummy_list[slotkey]

	GLOB.human_dummy_list -= slotkey
	if(istype(dummy))
		GLOB.dummy_mob_list -= dummy
		qdel(dummy)
