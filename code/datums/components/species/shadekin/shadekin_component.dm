#define BLUE_EYES 1
#define RED_EYES 2
#define PURPLE_EYES 3
#define YELLOW_EYES 4
#define GREEN_EYES 5
#define ORANGE_EYES 6

#define DARK_ENERGY_BLOCK_SOURCE_SUIT "dark_stop_suit"

#define NUTRITION_ENERGY_CONVERSION (0 << 1)

/datum/component/shadekin

	var/mob/living/carbon/human/owner
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/flags = NUTRITION_ENERGY_CONVERSION

	var/dark_energy = 100
	var/max_dark_energy = 100

	var/passive_heal_in_dark = 0.1

	var/list/action_templates = list(/datum/action/shadekin/phase_shift)
	var/list/hud_templates = list(/atom/movable/screen/shadekin/dark_energy_level)

	var/datum/shadekin_eye_model/eye_type = /datum/shadekin_eye_model/blue

/datum/component/shadekin/Initialize(...)
	to_chat(world, "[parent?.type]    [parent]")
	if(!ishuman(parent) || isnull(parent))
		return COMPONENT_INCOMPATIBLE
	owner = parent

	eye_type = set_shadekin_eyecolor()
	append_actions_from_templates()

	use_energy(0) //Пинаем по яицами все action
	huds_ping(0)

/datum/component/shadekin/RegisterWithParent()
	RegisterSignal(owner, COMSIG_SHADEKIN_GET_DARK_ENERGY, PROC_REF(get_energy))
	RegisterSignal(owner, COMSIG_SHADEKIN_GET_MAX_ENERGY_LEVEL, PROC_REF(get_max_energy))
	RegisterSignal(owner, COMSIG_ADJUST_DARK_ENERGY, PROC_REF(signal_use_energy))
	RegisterSignal(owner, COMSIG_LIVING_LIFE, PROC_REF(handle_life))
	RegisterSignal(owner, COMSIG_MOB_ITEM_EQUIPPED, PROC_REF(equip_item_reaction))
	RegisterSignal(owner, COMSIG_MOB_ITEM_DROPPED, PROC_REF(unequip_item_reaction))
	RegisterSignal(owner, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(rebuild_shadekin_screens))

/datum/component/shadekin/UnregisterFromParent()
	UnregisterSignal(owner, list(
		COMSIG_SHADEKIN_GET_MAX_ENERGY_LEVEL,
		COMSIG_SHADEKIN_GET_DARK_ENERGY,
		COMSIG_ADJUST_DARK_ENERGY,
		COMSIG_LIVING_LIFE,
		COMSIG_MOB_ITEM_EQUIPPED,
		COMSIG_MOB_ITEM_DROPPED,
		COMSIG_MOB_CLIENT_LOGIN
	))

//Хуйня конечно, но как говорится мы это хаваем
/datum/component/shadekin/proc/rebuild_shadekin_screens(datum/source, client/hud_client)
	SIGNAL_HANDLER
	append_screens_from_templates(hud_client)

/datum/component/shadekin/proc/set_shadekin_eyecolor()

	var/eyecolor_rgb = BlendRGB(owner.left_eye_color, owner.right_eye_color, 0.5)

	var/list/hsv_color = rgb2num(eyecolor_rgb, COLORSPACE_HSV)
	var/eyecolor_hue = hsv_color[1]
	var/eyecolor_sat = hsv_color[2]
	var/eyecolor_val = hsv_color[3]

	//First, clamp the saturation/value to prevent black/grey/white eyes
	if(eyecolor_sat < 10)
		eyecolor_sat = 10
	if(eyecolor_val < 40)
		eyecolor_val = 40

	var/new_eyecolor_rgb = sanitize_hexcolor(rgb(eyecolor_hue, eyecolor_sat, eyecolor_val, space=COLORSPACE_HSV), 6)

	owner.left_eye_color = new_eyecolor_rgb
	owner.right_eye_color = new_eyecolor_rgb
	owner.update_body()

	var/datum/shadekin_eye_model/eye_type_color = /datum/shadekin_eye_model/blue
	//Now determine what color we fall into.
	switch(eyecolor_hue)
		if(0 to 20)
			eye_type_color = /datum/shadekin_eye_model/red
		if(21 to 50)
			eye_type_color = /datum/shadekin_eye_model/orange
		if(51 to 70)
			eye_type_color = /datum/shadekin_eye_model/yellow
		if(71 to 160)
			eye_type_color = /datum/shadekin_eye_model/green
		if(161 to 260)
			eye_type_color = /datum/shadekin_eye_model/blue
		if(261 to 340)
			eye_type_color = /datum/shadekin_eye_model/purple
		if(341 to 360)
			eye_type_color = /datum/shadekin_eye_model/red

	return eye_type_color


/datum/component/shadekin/proc/get_energy(datum/source)
	SIGNAL_HANDLER
	return dark_energy

/datum/component/shadekin/proc/get_max_energy(datum/source)
	SIGNAL_HANDLER
	return max_dark_energy

/datum/component/shadekin/proc/use_energy(amount)
	var/temp = min(dark_energy - amount, max_dark_energy)
	if(temp < 0 || temp > max_dark_energy)
		return FALSE
	dark_energy = temp
	SEND_SIGNAL(owner, COMSIG_INFORM_NEW_ENERGY_LEVEL, dark_energy)
	return TRUE

/datum/component/shadekin/proc/signal_use_energy(datum/source, amount)
	SIGNAL_HANDLER
	return use_energy(amount)

/datum/component/shadekin/proc/append_actions_from_templates()
	if(!owner)
		return

	SEND_SIGNAL(owner, COMSIG_SHADEKIN_ACTION_DELETE)
	for(var/template in action_templates)
		var/datum/action/shadekin/temp = new template(owner)
		temp.Grant(owner)

/datum/component/shadekin/proc/append_screens_from_templates(client/client_to_append)
	if(!owner?.mind)
		return

	SEND_SIGNAL(owner, COMSIG_SHADEKIN_SCREEN_QDEL)
	for(var/template in hud_templates)
		var/atom/movable/screen/shadekin/shadekin_screen = new template()
		shadekin_screen.set_owner(client_to_append, owner)

/datum/component/shadekin/proc/check_is_dark()
	var/turf/T = get_turf(owner)
	var/darkness = 1
	if(!T)
		return FALSE

	var/brightness = T.get_lumcount()
	darkness = 1-brightness
	if(darkness >= 0.5)
		return darkness
	return FALSE

/datum/component/shadekin/proc/equip_item_reaction(datum/source, obj/item/W, slot)
	if((slot == ITEM_SLOT_SUITSTORE) && (!HAS_TRAIT_FROM(owner, TRAIT_DARK_ENERGY_BLOCKED, DARK_ENERGY_BLOCK_SOURCE_SUIT)) && istype(W, /obj/item/clothing/suit))
		to_chat(owner, span_warning("Вы чувствуете, что ваша энергия иссякает, а тяжелое снаряжение, которое вы носите, блокирует ваши силы!"))
		ADD_TRAIT(owner, TRAIT_DARK_ENERGY_BLOCKED, DARK_ENERGY_BLOCK_SOURCE_SUIT)
		use_energy(dark_energy)
		return

/datum/component/shadekin/proc/unequip_item_reaction(datum/source, obj/item/W, slot)
	if(((slot == ITEM_SLOT_SUITSTORE) && (HAS_TRAIT_FROM(owner, TRAIT_DARK_ENERGY_BLOCKED, DARK_ENERGY_BLOCK_SOURCE_SUIT))) && istype(W, /obj/item/clothing/suit))
		REMOVE_TRAIT(owner, TRAIT_DARK_ENERGY_BLOCKED, DARK_ENERGY_BLOCK_SOURCE_SUIT)
		return

/datum/component/shadekin/proc/nutriment_dark_gauns_modifer(energy_to_add)
	if(!(flags & NUTRITION_ENERGY_CONVERSION))
		return energy_to_add
	if(dark_energy == 100 && energy_to_add > 0)
		owner.nutrition += energy_to_add * 5 * eye_type::nutrition_conversion_scaling
	else if(dark_energy < 50 && owner.nutrition > 500)
		owner.nutrition -= eye_type::nutrition_conversion_scaling * 50
		energy_to_add += eye_type::nutrition_conversion_scaling

	return energy_to_add

/datum/component/shadekin/proc/passive_dark_heal(dark_level)
	owner.adjustFireLoss((eye_type::passive_heal_in_dark * -1)*dark_level)
	owner.adjustBruteLoss((eye_type::passive_heal_in_dark * -1)*dark_level)
	owner.adjustToxLoss((eye_type::passive_heal_in_dark * -1)*dark_level)

/datum/component/shadekin/proc/huds_ping(light_level)
	SEND_SIGNAL(owner, COMSIG_SHADEKIN_ENERGY_LIGTH_LEVEL, dark_energy, light_level)

/datum/component/shadekin/proc/handle_life(...)
	SIGNAL_HANDLER

	if(QDELETED(parent))
		return
	if(owner.stat == DEAD)
		return
	if(HAS_TRAIT(owner, TRAIT_DARK_ENERGY_BLOCKED))
		return

	var/energy_to_add = 0
	var/dark_level = check_is_dark()

	if(!HAS_TRAIT(owner, TRAIT_IN_PHASE_SHIFT))
		energy_to_add = dark_level ? eye_type::gain_in_dark : eye_type::gain_in_light

	passive_dark_heal(dark_level)

	energy_to_add = nutriment_dark_gauns_modifer(energy_to_add)

	use_energy(-1 * energy_to_add)

	huds_ping(dark_level) //Увы?
