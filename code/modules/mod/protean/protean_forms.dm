/datum/species/protean/proc/grant_forms(mob/living/carbon/human/human)
	clear_forms()
	form_abilities = list(new /datum/action/innate/ability/humanoid_customization/protean(src), new /datum/action/innate/ability/slime_blobform/protean(src))
	for(var/datum/action/ability as anything in form_abilities)
		ability.Grant(human)

/datum/species/protean/proc/clear_forms()
	QDEL_LIST(form_abilities)

/datum/species/protean/proc/body_form_available(mob/living/carbon/human/human)
	var/obj/item/organ/brain/protean/brain = human?.getorganslot(ORGAN_SLOT_BRAIN)
	return human && human.dna?.species == src && istype(brain) && !brain.dead && !brain.transform_user && !brain.rebuilding && !busy_action && human.loc != get_protean_modsuit(human) && !human.incapacitated()

/datum/species/protean/proc/is_puddle()
	var/datum/action/innate/ability/slime_blobform/protean/puddle = locate() in form_abilities
	return puddle?.is_puddle

/datum/action/innate/ability/humanoid_customization/protean
	name = "Изменить тело"
	desc = "Изменить внешность своего тела."
	background_icon_state = "bg_tech_blue"

/datum/action/innate/ability/humanoid_customization/protean/IsAvailable(silent = FALSE)
	var/datum/species/protean/species = target
	return ..() && istype(species) && species.body_form_available(owner) && !species.is_puddle()

/datum/action/innate/ability/humanoid_customization/protean/change_form()
	. = ..()
	var/mob/living/carbon/human/human = owner
	if(QDELETED(src) || !isprotean(human))
		return
	var/obj/item/organ/brain/protean/brain = human.getorganslot(ORGAN_SLOT_BRAIN)
	if(istype(brain))
		brain.cache_limbs(human)

/datum/action/innate/ability/slime_blobform/protean
	name = "Форма лужи"
	desc = "Превратиться в лужу нанитов или восстановить тело."
	background_icon_state = "bg_tech_blue"
	puddle_icon = PROTEAN_ORGAN_SPRITE
	puddle_state = PROTEAN_PUDDLE_STATE
	puddle_state_alt = PROTEAN_PUDDLE_STATE
	puddle_into_effect = /obj/effect/temp_visual/protean_to_suit
	puddle_into_effect_alt = /obj/effect/temp_visual/protean_to_suit
	puddle_from_effect = /obj/effect/temp_visual/protean_from_puddle
	puddle_from_effect_alt = /obj/effect/temp_visual/protean_from_puddle

/datum/action/innate/ability/slime_blobform/protean/IsAvailable()
	var/datum/species/protean/species = target
	return ..() && istype(species) && species.body_form_available(owner)

/datum/action/innate/ability/slime_blobform/protean/get_puddle_color(mob/living/carbon/human/human)
	return BLOOD_COLOR_IRON

/datum/action/innate/ability/slime_blobform/protean/get_puddle_icon()
	var/static/icon/puddle_sprite
	if(!puddle_sprite)
		puddle_sprite = build_puddle_icon()
	return puddle_sprite

/datum/action/innate/ability/slime_blobform/protean/proc/build_puddle_icon()
	var/icon/animation = icon(PROTEAN_ORGAN_SPRITE, PROTEAN_PUDDLE_STATE)
	var/list/palette = get_puddle_palette()
	for(var/original_color in palette)
		animation.SwapColor(original_color, palette[original_color])
	var/icon/puddle_sprite = new()
	puddle_sprite.Insert(animation, PROTEAN_PUDDLE_STATE)
	return puddle_sprite

/datum/action/innate/ability/slime_blobform/protean/proc/get_puddle_palette()
	var/icon/original = icon(PROTEAN_ORGAN_SPRITE, PROTEAN_PUDDLE_STATE, frame = 1)
	var/icon/nanites = icon(PROTEAN_ORGAN_SPRITE, "puddle")
	var/list/palette = list()
	for(var/x in 1 to original.Width())
		for(var/y in 1 to original.Height())
			var/original_color = original.GetPixel(x, y)
			if(original_color)
				palette[original_color] = nanites.GetPixel(x, y)
	return palette

/obj/item/mod/control/pre_equipped/protean/relaymove(mob/living/carbon/human/user, direction)
	if(user != get_protean() || user.loc != src || !isturf(loc) || wearer || anchored || !direction || user.stat != CONSCIOUS)
		return FALSE
	var/obj/item/organ/brain/protean/brain = user.getorganslot(ORGAN_SLOT_BRAIN)
	if(!istype(brain) || brain.dead || brain.transform_user || brain.rebuilding || !COOLDOWN_FINISHED(src, movement_cooldown))
		return FALSE
	COOLDOWN_START(src, movement_cooldown, PROTEAN_MOD_MOVE_DELAY)
	return step(src, direction)

/datum/action/innate/ability/humanoid_customization/protean/Destroy()
	var/datum/species/protean/species = target
	if(istype(species))
		species.form_abilities -= src
	return ..()

/datum/action/innate/ability/slime_blobform/protean/Destroy()
	var/datum/species/protean/species = target
	if(istype(species))
		species.form_abilities -= src
	return ..()

/obj/effect/temp_visual/protean_from_puddle
	parent_type = /obj/effect/temp_visual/protean_from_suit
	duration = 0.7 SECONDS
