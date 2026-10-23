/datum/action/item_action/mod
	required_mobility_flags = NONE
	background_icon_state = "bg_tech_blue"
	icon_icon = 'icons/mob/actions/actions_mod.dmi'
	check_flags = AB_CHECK_CONSCIOUS
	var/obj/item/mod/control/mod
	/// Whether this action is intended for the AI. Stuff breaks a lot if this is done differently.
	var/ai_action = FALSE

/datum/action/item_action/mod/New(Target)
	..()
	if(!istype(Target, /obj/item/mod/control))
		qdel(src)
		return
	if(ai_action)
		background_icon_state = "bg_tech"

/datum/action/item_action/mod/Grant(mob/user)
	mod = target
	if(ai_action && user != mod.ai)
		return
	else if(!ai_action && user == mod.ai)
		return
	return ..()

/datum/action/item_action/mod/Remove(mob/user)
	if(!QDELING(src) && !QDELETED(mod))
		if(ai_action && user != mod.ai)
			return
		else if(!ai_action && user == mod.ai)
			return
	return ..()

/datum/action/item_action/mod/Destroy()
	mod = null
	return ..()

/datum/action/item_action/mod/Trigger(trigger_flags)
	if(!IsAvailable())
		return FALSE
	if(mod.is_malfunctioning() && prob(MOD_BUTTON_MALFUNCTION_CHANCE))
		mod.balloon_alert(usr, "кнопка сбоит!")
		return FALSE
	return TRUE

/datum/action/item_action/mod/deploy
	name = "Deploy MODsuit"
	desc = "Развернуть/Скрыть часть MOD-костюма. На правую кнопку мыши будут развернуты/свернуты все части костюма."
	button_icon_state = "deploy"
	button_block_right_click_context_menu = TRUE

/datum/action/item_action/mod/deploy/Trigger(trigger_flags)
	if(!IsAvailable())
		return FALSE
	if(CHECK_BITFIELD(trigger_flags, TRIGGER_RIGHT_CLICK))
		return mod.quick_toggle_parts(mod.wearer)
	mod.choose_deploy(usr)
	return TRUE

/datum/action/item_action/mod/deploy/ai
	ai_action = TRUE

/datum/action/item_action/mod/activate
	name = "Activate MODsuit"
	desc = "Активировать/Деактивировать MOD-костюм. На правую кнопку мыши будут развернуты/свернуты все части костюма."
	button_icon_state = "activate"
	button_block_right_click_context_menu = TRUE

/datum/action/item_action/mod/activate/Trigger(trigger_flags)
	if(!IsAvailable())
		return FALSE
	if(CHECK_BITFIELD(trigger_flags, TRIGGER_RIGHT_CLICK))
		return mod.quick_toggle_parts(mod.wearer)
	mod.toggle_activate(usr)
	return TRUE

/datum/action/item_action/mod/activate/ai
	ai_action = TRUE

/datum/action/item_action/mod/module
	name = "Toggle Module"
	desc = "Переключить модуль MOD-костюма."
	button_icon_state = "module"
	button_block_right_click_context_menu = TRUE

/datum/action/item_action/mod/module/Trigger(trigger_flags)
	if(!IsAvailable())
		return FALSE
	mod.quick_module(usr, CHECK_BITFIELD(trigger_flags, TRIGGER_RIGHT_CLICK))
	return TRUE

/datum/action/item_action/mod/module/ai
	ai_action = TRUE

/datum/action/item_action/mod/panel
	name = "MODsuit Panel"
	desc = "Открыть панель MOD-костюма."
	button_icon_state = "panel"

/datum/action/item_action/mod/panel/Trigger(trigger_flags)
	if(!IsAvailable())
		return FALSE
	mod.ui_interact(usr)
	return TRUE

/datum/action/item_action/mod/panel/ai
	ai_action = TRUE

//Абилки для модулей. Grant находится в mod_control.dm, generate_ability_button()

/datum/action/cooldown/module_action
	name = "Generic MODsuit Module Action"
	button_block_right_click_context_menu = TRUE
	icon_icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	button_icon = 'icons/mob/actions/backgrounds.dmi'
	background_icon_state = "bg_tech_blue"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/cooldown/module_action/New(obj/item/mod/module/Target)
	. = ..()
	name = Target?.name
	cooldown_time = Target?.cooldown_time
	button_icon_state = Target?.icon_state
	icon_icon = Target?.icon
	if(Target?.hands_free_use)
		required_mobility_flags = NONE
	if(Target?.allowed_incapacitated)
		check_flags = NONE

/datum/action/cooldown/module_action/Trigger(trigger_flags, atom/target)
	var/obj/item/mod/module/target_module = src.target
	if(QDELETED(target_module) || QDELETED(target_module.mod) || (target_module.mod.wearer != owner && target_module.mod.ai != owner))
		to_chat(owner, span_danger("Модуль изъят!"))
		return qdel(src)
	if(CHECK_BITFIELD(trigger_flags, TRIGGER_RIGHT_CLICK))
		to_chat(owner, span_danger("Способность удалена с хотбара!"))
		qdel(src)
		return TRUE
	if(!IsAvailable())
		return FALSE
	target_module.on_select()
	StartCooldown(COOLDOWN_TIMELEFT(target_module, cooldown_current_timer))
	return TRUE
