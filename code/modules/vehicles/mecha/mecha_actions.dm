/***************** MECHA ACTIONS *****************/

/obj/vehicle/sealed/mecha/generate_action_type()
	. = ..()
	if(istype(., /datum/action/vehicle/sealed/mecha))
		var/datum/action/vehicle/sealed/mecha/mecha = .
		mecha.chassis = src


/datum/action/vehicle/sealed/mecha
	icon_icon = 'icons/mob/actions/actions_mecha.dmi'
	var/obj/vehicle/sealed/mecha/chassis

/datum/action/vehicle/sealed/mecha/Destroy()
	chassis = null
	return ..()

// Модули имеют отдельное действие на каждого оператора, в том числе в двухместных мехах.
/datum/action/vehicle/sealed/mecha/module
	var/obj/item/mecha_parts/mecha_equipment/equipment
	button_block_right_click_context_menu = TRUE

/datum/action/vehicle/sealed/mecha/module/Destroy()
	if(equipment && owner)
		equipment.pilot_actions -= owner
	equipment = null
	return ..()

/datum/action/vehicle/sealed/mecha/module/IsAvailable(silent = FALSE)
	return owner && equipment?.chassis == chassis && (chassis?.occupants[owner] & VEHICLE_CONTROL_EQUIPMENT) && !owner.incapacitated()

/datum/action/vehicle/sealed/mecha/module/Trigger(trigger_flags)
	if(!..())
		return FALSE
	if(equipment.ui_toggle_action)
		equipment.handle_ui_act(equipment.ui_toggle_action, list())
	else if(trigger_flags & TRIGGER_RIGHT_CLICK)
		chassis.selected_right = chassis.selected_right == equipment ? null : equipment
	else
		chassis.selected = chassis.selected == equipment ? null : equipment
	equipment.update_equip_info()
	return TRUE

/datum/action/vehicle/sealed/mecha/module/UpdateButton(atom/movable/screen/movable/action_button/button, status_only = FALSE, force = FALSE)
	. = ..()
	if(!button || !equipment || !chassis || !IsAvailable(TRUE))
		return
	if(!equipment.ui_toggle_action && chassis.selected_right == equipment)
		button.color = COLOR_GOLD
	else if(equipment.ui_toggle_action ? equipment.is_ui_active() : chassis.selected == equipment)
		button.color = "#aaffaa"
	button.desc = equipment.ui_toggle_action ? "Включить или выключить модуль." : "ЛКМ: выбрать модуль для ЛКМ. ПКМ: выбрать модуль для ПКМ. Повторное нажатие снимает выбор. Колесо мыши: сменить модуль для ЛКМ; Shift + колесо: для ПКМ."

/obj/vehicle/sealed/mecha/add_control_flags(mob/controller, flags)
	. = ..()
	if(.)
		for(var/obj/item/mecha_parts/mecha_equipment/module as anything in equipment)
			module.grant_pilot_action(controller)

/obj/vehicle/sealed/mecha/remove_control_flags(mob/controller, flags)
	. = ..()
	if(. && !(occupants[controller] & VEHICLE_CONTROL_EQUIPMENT))
		for(var/obj/item/mecha_parts/mecha_equipment/module as anything in equipment)
			module.remove_pilot_action(controller)

/datum/action/vehicle/sealed/mecha/mech_eject
	name = "Выйти из меха"
	button_icon_state = "mech_eject"

/datum/action/vehicle/sealed/mecha/mech_eject/Trigger()
	if(!owner)
		return
	if(!chassis || !(owner in chassis.occupants))
		return
	chassis.container_resist(owner)

/datum/action/vehicle/sealed/mecha/mech_toggle_internals
	name = "Переключить источник воздуха"
	button_icon_state = "mech_internals_off"

/datum/action/vehicle/sealed/mecha/mech_toggle_internals/Trigger()
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.use_internal_tank = !chassis.use_internal_tank
	button_icon_state = "mech_internals_[chassis.use_internal_tank ? "on" : "off"]"
	to_chat(chassis.occupants, "[icon2html(chassis, owner)][span_notice("Источник воздуха: [chassis.use_internal_tank ? "внутренний баллон" : "окружающая среда"].")]")
	chassis.log_message("Источник воздуха: [chassis.use_internal_tank ? "внутренний баллон" : "окружающая среда"].", LOG_MECHA)
	UpdateButtons()

/datum/action/vehicle/sealed/mecha/mech_toggle_lights
	name = "Переключить освещение"
	button_icon_state = "mech_lights_off"

/datum/action/vehicle/sealed/mecha/mech_toggle_lights/Trigger()
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	if(!(chassis.mecha_flags & HAS_LIGHTS))
		to_chat(owner, span_warning("Осветители меха уничтожены!"))
		return
	chassis.mecha_flags ^= LIGHTS_ON
	if(chassis.mecha_flags & LIGHTS_ON)
		button_icon_state = "mech_lights_on"
		chassis.set_light(5, 5)
	else
		button_icon_state = "mech_lights_off"
		chassis.set_light(0)
	to_chat(owner, "[icon2html(chassis, owner)][span_notice("Освещение [(chassis.mecha_flags & LIGHTS_ON) ? "включено" : "выключено"].")]")
	chassis.log_message("Освещение [(chassis.mecha_flags & LIGHTS_ON) ? "включено" : "выключено"].", LOG_MECHA)
	UpdateButtons()

/datum/action/vehicle/sealed/mecha/mech_view_stats
	name = "Панель меха"
	button_icon_state = "mech_view_stats"

/datum/action/vehicle/sealed/mecha/mech_view_stats/Trigger()
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.ui_interact(owner)


/datum/action/vehicle/sealed/mecha/strafe
	name = "Боковое движение"
	desc = "Позволяет двигаться боком. Отключается при зажатом Alt."
	button_icon_state = "strafe"

/datum/action/vehicle/sealed/mecha/strafe/Trigger()
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.toggle_strafe()

/obj/vehicle/sealed/mecha/AltClick(mob/living/user)
	if(!is_occupant(user))
		open_maintenance_panel(user.get_idcard(TRUE), user)
		return
	if(!user.canUseTopic(src))
		return
	if(!(user in return_controllers_with_flag(VEHICLE_CONTROL_DRIVE)))
		to_chat(user, span_warning("С этого места нельзя управлять движением."))
		return

	toggle_strafe()

/obj/vehicle/sealed/mecha/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(is_occupant(user))
		if(occupants[user] & VEHICLE_CONTROL_DRIVE)
			LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, "Переключить боковое движение")
			return CONTEXTUAL_SCREENTIP_SET
		return
	LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, "Панель обслуживания (ID)")
	if(held_item?.GetID())
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Панель обслуживания")
	else if(held_item && user.a_intent != INTENT_HARM)
		var/tool_hint
		switch(held_item.tool_behaviour)
			if(TOOL_WRENCH)
				if(construction_state == MECHA_SECURE_BOLTS)
					tool_hint = "Ослабить болты"
				else if(construction_state == MECHA_LOOSE_BOLTS)
					tool_hint = "Затянуть болты"
			if(TOOL_CROWBAR)
				if(construction_state == MECHA_LOOSE_BOLTS)
					tool_hint = "Открыть люк"
				else if(construction_state == MECHA_OPEN_HATCH)
					tool_hint = "Закрыть люк"
		if(tool_hint)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, tool_hint)
	return CONTEXTUAL_SCREENTIP_SET

/obj/vehicle/sealed/mecha/proc/toggle_strafe()
	strafe = !strafe

	to_chat(occupants, "[icon2html(src, occupants)][span_notice("Боковое движение [strafe ? "включено" : "выключено"].")]")
	log_message("Боковое движение [strafe ? "включено" : "выключено"].", LOG_MECHA)

	for(var/occupant in occupants)
		var/datum/action/action = LAZYACCESSASSOC(occupant_actions, occupant, /datum/action/vehicle/sealed/mecha/strafe)
		action?.UpdateButtons()

/datum/action/vehicle/sealed/mecha/toggle_stabilizers
	name = "Стабилизаторы"
	desc = "Останавливают дрейф в космосе. Нужны работающие двигатели и питание."
	button_icon_state = "mech_thrusters_off"

/datum/action/vehicle/sealed/mecha/toggle_stabilizers/Trigger()
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.toggle_stabilizers()

/obj/vehicle/sealed/mecha/proc/toggle_stabilizers()
	stabilizers = !stabilizers
	to_chat(occupants, "[icon2html(src, occupants)][span_notice("Стабилизаторы двигателей [stabilizers ? "включены" : "выключены"].")]")
	log_message("Стабилизаторы двигателей [stabilizers ? "включены" : "выключены"].", LOG_MECHA)

	for(var/occupant in occupants)
		var/datum/action/vehicle/sealed/mecha/toggle_stabilizers/action = LAZYACCESSASSOC(occupant_actions, occupant, /datum/action/vehicle/sealed/mecha/toggle_stabilizers)
		if(action)
			action.button_icon_state = "mech_thrusters_[stabilizers ? "on" : "off"]"
			action.UpdateButtons()

//////////////////////////////////////// Specific Ability Actions  ///////////////////////////////////////////////
//Need to be granted by the mech type, Not default abilities.

/datum/action/vehicle/sealed/mecha/mech_defense_mode
	name = "Энергетический щит"
	desc = "Блокирует атаки спереди, расходуя большое количество энергии."
	button_icon_state = "mech_defense_mode_off"

///Кнопка зовёт Trigger(trigger_flags) позиционно, поэтому silent - только именованный флаг.
///Щит переключается всегда: вызывающий, которому нужно включить, проверяет defense_mode сам.
/datum/action/vehicle/sealed/mecha/mech_defense_mode/Trigger(trigger_flags, silent = FALSE)
	SEND_SIGNAL(chassis, COMSIG_MECHA_ACTION_TRIGGER, owner, list(silent)) //Signal sent to the mech, to be handed to the shield. See durand.dm for more details

/datum/action/vehicle/sealed/mecha/mech_overload_mode
	name = "Форсаж приводов"
	button_icon_state = "mech_overload_off"

///Кнопка нового пассажира обязана показывать состояние шасси, а не типовое "выключено"
/datum/action/vehicle/sealed/mecha/mech_overload_mode/Grant(mob/grant_to)
	button_icon_state = "mech_overload_[chassis?.leg_overload_mode ? "on" : "off"]"
	return ..()

///Кнопка зовёт Trigger(trigger_flags) позиционно, поэтому целевое состояние - только
///именованный forced_state: null - переключить, иначе выставить.
/datum/action/vehicle/sealed/mecha/mech_overload_mode/Trigger(trigger_flags, forced_state = null)
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	var/wanted_state = isnull(forced_state) ? !chassis.leg_overload_mode : forced_state
	if(!chassis.set_leg_overload(wanted_state))
		if(wanted_state && !chassis.leg_overload_mode)
			to_chat(owner, "[icon2html(chassis, owner)][span_warning("Недостаточно энергии для форсажа ножных приводов.")]")
		return
	if(chassis.leg_overload_mode)
		to_chat(owner, "[icon2html(chassis, owner)][span_danger("Вы включаете форсаж ножных приводов.")]")
	else
		to_chat(owner, "[icon2html(chassis, owner)][span_notice("Вы выключаете форсаж ножных приводов.")]")

/datum/action/vehicle/sealed/mecha/mech_smoke
	name = "Дымовая завеса"
	button_icon_state = "mech_smoke"

/datum/action/vehicle/sealed/mecha/mech_smoke/Trigger()
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	if(!TIMER_COOLDOWN_CHECK(src, COOLDOWN_MECHA_SMOKE) && chassis.smoke_charges>0)
		chassis.smoke_system.start()
		chassis.smoke_charges--
		TIMER_COOLDOWN_START(src, COOLDOWN_MECHA_SMOKE, chassis.smoke_cooldown)


/datum/action/vehicle/sealed/mecha/mech_zoom
	name = "Увеличение обзора"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"

/datum/action/vehicle/sealed/mecha/mech_zoom/Trigger()
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	if(owner.client)
		chassis.zoom_mode = !chassis.zoom_mode
		chassis.log_message("Переключён режим увеличения обзора.", LOG_MECHA)
		to_chat(owner, "[icon2html(chassis, owner)][chassis.zoom_mode ? span_blue("Режим увеличения обзора включён.") : span_red("Режим увеличения обзора выключен.")]")
		if(chassis.zoom_mode)
			owner.client.view_size.setTo(4.5)
			SEND_SOUND(owner, sound('sound/mecha/imag_enh.ogg',volume=50))
		else
			owner.client.view_size.resetToDefault() //Let's not let this stack shall we?
		UpdateButtons()

/datum/action/vehicle/sealed/mecha/mech_switch_damtype
	name = "Сменить тип урона"
	button_icon_state = "mech_damtype_brute"

/datum/action/vehicle/sealed/mecha/mech_switch_damtype/Trigger()
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	var/new_damtype
	switch(chassis.damtype)
		if("tox")
			new_damtype = "brute"
			to_chat(owner, "[icon2html(chassis, owner)][span_notice("Манипуляторы экзокостюма сжимаются в кулаки.")]")
		if("brute")
			new_damtype = "fire"
			to_chat(owner, "[icon2html(chassis, owner)][span_notice("Из манипулятора экзокостюма выдвигается раскалённая докрасна горелка.")]")
		if("fire")
			new_damtype = "tox"
			to_chat(owner, "[icon2html(chassis, owner)][span_notice("Из ладони экзокостюма выдвигается пугающе толстая пласталевая игла.")]")
	chassis.damtype = new_damtype
	button_icon_state = "mech_damtype_[new_damtype]"
	playsound(chassis, 'sound/mecha/mechmove01.ogg', 50, TRUE)
	UpdateButtons()

///swap seats, for two person mecha
/datum/action/vehicle/sealed/mecha/swap_seat
	name = "Сменить место"
	button_icon_state = "mech_seat_swap"

/datum/action/vehicle/sealed/mecha/swap_seat/Trigger()
	if(!owner || !chassis || !(owner in chassis.occupants))
		return

	if(chassis.occupants.len == chassis.max_occupants)
		to_chat(owner, "Другое место занято!")
		return
	var/list/drivers = chassis.return_drivers()
	to_chat(owner, "Пересадка на другое место...")
	chassis.is_currently_ejecting = TRUE
	if(!do_after(owner, chassis.has_gravity() ? chassis.exit_delay : 0 , target = chassis))
		chassis.is_currently_ejecting = FALSE
		return
	chassis.is_currently_ejecting = FALSE
	if(owner in drivers)
		to_chat(owner, "Вы пересаживаетесь на место стрелка!")
		chassis.remove_control_flags(owner, VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_SETTINGS)
		chassis.add_control_flags(owner, VEHICLE_CONTROL_MELEE|VEHICLE_CONTROL_EQUIPMENT)
	else
		to_chat(owner, "Вы пересаживаетесь на место пилота!")
		chassis.remove_control_flags(owner, VEHICLE_CONTROL_MELEE|VEHICLE_CONTROL_EQUIPMENT)
		chassis.add_control_flags(owner, VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_SETTINGS)
	chassis.update_icon_state()

/datum/action/vehicle/sealed/mecha/mech_toggle_phasing
	name = "Фазовый модуль"
	button_icon_state = "mech_phasing_off"

/datum/action/vehicle/sealed/mecha/mech_toggle_phasing/Trigger()
	if(!owner || !chassis || !(owner in chassis.occupants))
		return
	chassis.phasing = !chassis.phasing
	button_icon_state = "mech_phasing_[chassis.phasing ? "on" : "off"]"
	to_chat(owner, "[icon2html(chassis, owner)][chassis.phasing ? span_blue("Фазовый режим включён.") : span_red("Фазовый режим выключен.")]")
	UpdateButtons()

//

/datum/action/vehicle/sealed/mecha/syndicate

/obj/vehicle/sealed/mecha/syndicate/generate_action_type()
	. = ..()
	if(istype(., /datum/action/vehicle/sealed/mecha))
		var/datum/action/vehicle/sealed/mecha/mecha = .
		mecha.chassis = src

/datum/action/vehicle/sealed/mecha/syndicate/mech_zoom
	name = "Увеличение обзора"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"

/datum/action/vehicle/sealed/mecha/syndicate/mech_zoom/Trigger()
	if(owner.client)
		chassis.zoom_mode = !chassis.zoom_mode
		chassis.log_message("Переключён режим увеличения обзора.", LOG_MECHA)
		to_chat(owner, "[icon2html(chassis, owner)][chassis.zoom_mode ? span_blue("Режим увеличения обзора включён.") : span_red("Режим увеличения обзора выключен.")]")
		if(chassis.zoom_mode)
			owner.client.view_size.setTo(4.5)
			SEND_SOUND(owner, sound('sound/mecha/imag_enh_syndicate.ogg',volume=50))
		else
			owner.client.view_size.resetToDefault()
		UpdateButton()

///

/datum/action/vehicle/sealed/mecha/russian

/obj/vehicle/sealed/mecha/russian/generate_action_type()
	. = ..()
	if(istype(., /datum/action/vehicle/sealed/mecha))
		var/datum/action/vehicle/sealed/mecha/mecha = .
		mecha.chassis = src

/datum/action/vehicle/sealed/mecha/russian/mech_zoom
	name = "Увеличение обзора"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"

/datum/action/vehicle/sealed/mecha/russian/mech_zoom/Trigger()
	if(owner.client)
		chassis.zoom_mode = !chassis.zoom_mode
		chassis.log_message("Переключён режим увеличения обзора.", LOG_MECHA)
		to_chat(owner, "[icon2html(chassis, owner)][chassis.zoom_mode ? span_blue("Режим увеличения обзора включён.") : span_red("Режим увеличения обзора выключен.")]")
		if(chassis.zoom_mode)
			owner.client.view_size.setTo(4.5)
			SEND_SOUND(owner, sound('sound/mecha/imag_enh_russian.ogg',volume=50))
		else
			owner.client.view_size.resetToDefault()
		UpdateButton()

//

/datum/action/vehicle/sealed/mecha/sol

/obj/vehicle/sealed/mecha/sol/generate_action_type()
	. = ..()
	if(istype(., /datum/action/vehicle/sealed/mecha))
		var/datum/action/vehicle/sealed/mecha/mecha = .
		mecha.chassis = src

/datum/action/vehicle/sealed/mecha/sol/mech_zoom
	name = "Увеличение обзора"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"

/datum/action/vehicle/sealed/mecha/sol/mech_zoom/Trigger()
	if(owner.client)
		chassis.zoom_mode = !chassis.zoom_mode
		chassis.log_message("Переключён режим увеличения обзора.", LOG_MECHA)
		to_chat(owner, "[icon2html(chassis, owner)][chassis.zoom_mode ? span_blue("Режим увеличения обзора включён.") : span_red("Режим увеличения обзора выключен.")]")
		if(chassis.zoom_mode)
			owner.client.view_size.setTo(4.5)
			SEND_SOUND(owner, sound('modular_bluemoon/kovac_shitcode/sound/mecha/imag_enh_sol.ogg',volume=50))
		else
			owner.client.view_size.resetToDefault()
		UpdateButton()

///
