/**
 * Borg private/donator skins registry.
 *
 * Инструкция:
 * 1. Для каждого приватного спрайта создавайте отдельный subtype от /datum/borg_donator_skin ниже.
 * 2. В module_type укажите модуль борга, в radial-меню которого должен появляться этот спрайт.
 * 3. В preview_icon/preview_icon_state укажите иконку и icon_state, которые будут показываться в превью radial-меню.
 * 4. В cyborg_base_icon и cyborg_icon_override укажите реальные спрайты, которые борг получит после выбора.
 * 5. Не забудьте добавить новый datum в GLOB.borg_donator_skins внизу файла.
 *
 * Правила доступа:
 * - ckey_whitelist проверяется без учёта регистра, но сами ckey всё равно лучше писать в lowercase.
 * - donator_group можно использовать вместо ckey_whitelist или вместе с ним.
 */

/proc/build_private_radial_preview(icon/icon_file, icon_state, pixel_x = 0, pixel_y = 0)
	var/image/preview = image(icon = icon_file, icon_state = icon_state)
	preview.pixel_x = pixel_x
	preview.pixel_y = pixel_y

	return preview

/datum/borg_donator_skin
	var/name = ""
	var/module_type = /obj/item/robot_module

	var/icon/preview_icon = 'icons/mob/robots.dmi'
	var/preview_icon_state = ""
	var/preview_pixel_x = 0
	var/preview_pixel_y = 0

	var/list/ckey_whitelist = list()
	var/donator_group = DONATOR_GROUP_NONE

	var/cyborg_base_icon = null
	var/icon/cyborg_icon_override = null
	var/special_light_key = null
	var/sleeper_overlay = null
	var/moduleselect_icon = null
	var/icon/moduleselect_alternate_icon = null
	var/hat_offset = null
	var/hasrest = null
	var/dogborg = null
	var/drakerest = null
	var/has_snowflake_deadsprite = null
	var/cyborg_pixel_offset = null

/datum/borg_donator_skin/proc/can_use(client/C)
	if(!C)
		return FALSE

	if(length(ckey_whitelist))
		var/user_ckey = lowertext(C.ckey)
		for(var/allowed_ckey in ckey_whitelist)
			if(lowertext("[allowed_ckey]") == user_ckey)
				return TRUE

	if(donator_group != DONATOR_GROUP_NONE && is_donator_group(C.ckey, donator_group))
		return TRUE

	return FALSE

/datum/borg_donator_skin/proc/is_available_for(obj/item/robot_module/module, client/C)
	return module && istype(module, module_type) && can_use(C)

/datum/borg_donator_skin/proc/build_preview()
	return build_private_radial_preview(preview_icon, preview_icon_state, preview_pixel_x, preview_pixel_y)

/datum/borg_donator_skin/proc/apply_to(obj/item/robot_module/module)
	if(isnull(cyborg_base_icon))
		CRASH("Borg donator skin [type] does not define cyborg_base_icon.")

	module.cyborg_base_icon = cyborg_base_icon

	if(!isnull(cyborg_icon_override))
		module.cyborg_icon_override = cyborg_icon_override
	if(!isnull(special_light_key))
		module.special_light_key = special_light_key
	if(!isnull(sleeper_overlay))
		module.sleeper_overlay = sleeper_overlay
	if(!isnull(moduleselect_icon))
		module.moduleselect_icon = moduleselect_icon
	if(!isnull(moduleselect_alternate_icon))
		module.moduleselect_alternate_icon = moduleselect_alternate_icon
	if(!isnull(hat_offset))
		module.hat_offset = hat_offset
	if(!isnull(hasrest))
		module.hasrest = hasrest
	if(!isnull(dogborg))
		module.dogborg = dogborg
	if(!isnull(drakerest))
		module.drakerest = drakerest
	if(!isnull(has_snowflake_deadsprite))
		module.has_snowflake_deadsprite = has_snowflake_deadsprite
	if(!isnull(cyborg_pixel_offset))
		module.cyborg_pixel_offset = cyborg_pixel_offset

/obj/item/robot_module/proc/get_selectable_borg_icons(list/base_icons, client/C)
	var/list/selectable_icons = base_icons.Copy()

	if(C)
		for(var/datum/borg_donator_skin/donor_skin in GLOB.borg_donator_skins)
			if(donor_skin.is_available_for(src, C))
				selectable_icons[donor_skin.name] = donor_skin.build_preview()

	return sort_list(selectable_icons)

/obj/item/robot_module/proc/apply_donator_borg_icon(selection_name, client/C)
	if(!selection_name || !C)
		return FALSE

	for(var/datum/borg_donator_skin/donor_skin in GLOB.borg_donator_skins)
		if(donor_skin.name != selection_name)
			continue
		if(!donor_skin.is_available_for(src, C))
			continue

		donor_skin.apply_to(src)
		return TRUE

	return FALSE

// РАБОЧИЙ ПРИМЕР
// /datum/borg_donator_skin/standard/pe4henika_debug
// 	name = "Debug MissM"
// 	module_type = /obj/item/robot_module/standard
// 	preview_icon = 'modular_splurt/icons/mob/robots.dmi'
// 	preview_icon_state = "missm_sd"
// 	ckey_whitelist = list("pe4henika")
// 	cyborg_base_icon = "missm_sd"
// 	cyborg_icon_override = 'modular_splurt/icons/mob/robots.dmi'
// 	hat_offset = 3

/datum/borg_donator_skin/syndicate/mekafl
	name = "ANI-Meka"
	module_type = /obj/item/robot_module/syndicate
	preview_icon = 'modular_splurt/icons/mob/robots_32x64.dmi'
	preview_icon_state = "mekafl"
	ckey_whitelist = list("foxrtotlimda")
	cyborg_base_icon = "mekafl"
	cyborg_icon_override = 'modular_splurt/icons/mob/robots_32x64.dmi'
	hat_offset = TALL_HAT_OFFSET
	hasrest = TRUE

GLOBAL_LIST_INIT_TYPED(borg_donator_skins, /datum/borg_donator_skin, list(
	// new /datum/borg_donator_skin/standard/pe4henika_debug
	new /datum/borg_donator_skin/syndicate/mekafl
))
