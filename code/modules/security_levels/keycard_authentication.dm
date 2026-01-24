GLOBAL_DATUM_INIT(keycard_events, /datum/events, new)

#define KEYCARD_RED_ALERT "Red Alert"
#define KEYCARD_EMERGENCY_MAINTENANCE_ACCESS "Emergency Maintenance Access"
#define KEYCARD_BSA_UNLOCK "Bluespace Artillery Unlock"

#define ACCESS_GRANTING_COOLDOWN (30 SECONDS)

/obj/machinery/keycard_auth
	name = "Keycard Authentication Device"
	desc = "This device is used to trigger station functions, which require more than one ID card to authenticate."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "auth_off"
	plane = GAME_PLANE
	use_power = IDLE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 6
	power_channel = ENVIRON
	req_access = list(ACCESS_KEYCARD_AUTH)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	ui_x = 375
	ui_y = 125

	var/datum/callback/ev
	var/event = ""
	var/obj/machinery/keycard_auth/event_source
	var/mob/triggerer = null
	var/obj/item/card/id/first_id = null
	var/waiting = 0

	COOLDOWN_DECLARE(access_grant_cooldown)

/obj/machinery/keycard_auth/Initialize(mapload)
	. = ..()
	ev = GLOB.keycard_events.addEvent("triggerEvent", CALLBACK(src, PROC_REF(triggerEvent)))

/obj/machinery/keycard_auth/Destroy()
	GLOB.keycard_events.clearEvent("triggerEvent", ev)
	QDEL_NULL(ev)
	return ..()

/obj/machinery/keycard_auth/ui_state(mob/user)
	return GLOB.physical_state

/obj/machinery/keycard_auth/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "KeycardAuth", name)
		ui.open()

/obj/machinery/keycard_auth/ui_data()
	var/list/data = list()
	data["waiting"] = waiting
	data["auth_required"] = event_source ? event_source.event : 0
	data["red_alert"] = (SECLEVEL2NUM(NUM2SECLEVEL(GLOB.security_level)) >= SEC_LEVEL_RED) ? 1 : 0
	data["emergency_maint"] = GLOB.emergency_access
	data["bsa_unlock"] = GLOB.bsa_unlock
	return data

/obj/machinery/keycard_auth/ui_status(mob/user)
	if(isanimal(user))
		var/mob/living/simple_animal/A = user
		if(!A.dextrous)
			to_chat(user, "<span class='warning'>You are too primitive to use this device!</span>")
			return UI_CLOSE
	return ..()

/obj/machinery/keycard_auth/ui_act(action, params, mob/user)
	if(..() || waiting)
		return
	var/obj/item/card/id/ID = usr.get_idcard(TRUE)
	if(!ID || !istype(ID))
		return
	if(!check_access(ID))
		return
	switch(action)
		if("red_alert")
			if(!event_source)
				sendEvent(KEYCARD_RED_ALERT, ID)
				playsound(get_turf(user), 'sound/machines/auth.ogg', 75, 1, 1)
				. = TRUE
		if("emergency_maint")
			if(!event_source)
				sendEvent(KEYCARD_EMERGENCY_MAINTENANCE_ACCESS, ID)
				playsound(get_turf(user), 'sound/machines/auth.ogg', 75, 1, 1)
				. = TRUE
		if("auth_swipe")
			if(event_source && ID != first_id && first_id)
				event_source.trigger_event(usr)
				event_source = null
				playsound(get_turf(user), 'sound/machines/auth.ogg', 75, 1, 1)
				. = TRUE
		if("bsa_unlock")
			if(!event_source)
				sendEvent(KEYCARD_BSA_UNLOCK, ID)
				playsound(get_turf(user), 'sound/machines/auth.ogg', 75, 1, 1)
				. = TRUE
		if("give_janitor_access")
			if(!COOLDOWN_FINISHED(src, access_grant_cooldown))
				balloon_alert(usr, "on cooldown!")
				return TRUE

			var/list/region_access = list()
			var/region = 0 // check get_region_accesses(code)
			for(var/i in list(ACCESS_CAPTAIN, ACCESS_HOP, ACCESS_HOS, ACCESS_CMO, ACCESS_RD, ACCESS_CE, ACCESS_QM))
				if(i in ID.access)
					region_access += region
					if(region == 0)
						break
				region++
			if(region_access.len)
				COOLDOWN_START(src, access_grant_cooldown, ACCESS_GRANTING_COOLDOWN)
				SEND_GLOBAL_SIGNAL(COMSIG_ON_DEPARTMENT_ACCESS, region_access)
				balloon_alert(usr, "key access sent")
			return

/obj/machinery/keycard_auth/proc/sendEvent(event_type, trigger_id)
	triggerer = usr
	event = event_type
	waiting = 1
	GLOB.keycard_events.fireEvent("triggerEvent", src, trigger_id)
	addtimer(CALLBACK(src, PROC_REF(eventSent)), 20)

/obj/machinery/keycard_auth/proc/eventSent()
	triggerer = null
	event = ""
	waiting = 0

/obj/machinery/keycard_auth/proc/triggerEvent(source, trigger_id)
	icon_state = "auth_on"
	first_id = trigger_id
	event_source = source
	addtimer(CALLBACK(src, PROC_REF(eventTriggered)), 20)

/obj/machinery/keycard_auth/proc/eventTriggered()
	icon_state = "auth_off"
	event_source = null
	first_id = null

/obj/machinery/keycard_auth/proc/trigger_event(confirmer)
	log_game("[key_name(triggerer)] triggered and [key_name(confirmer)] confirmed event [event]")
	message_admins("[ADMIN_LOOKUPFLW(triggerer)] triggered and [ADMIN_LOOKUPFLW(confirmer)] confirmed event [event]")

	var/area/A1 = get_area(triggerer)
	deadchat_broadcast(" triggered [event] at [span_name("[A1.name]")].", span_name("[triggerer]"), triggerer, message_type=DEADCHAT_ANNOUNCEMENT)

	var/area/A2 = get_area(confirmer)
	deadchat_broadcast(" confirmed [event] at [span_name("[A2.name]")].", span_name("[confirmer]"), confirmer, message_type=DEADCHAT_ANNOUNCEMENT)
	switch(event)
		if(KEYCARD_RED_ALERT)
			set_security_level(SEC_LEVEL_RED)
		if(KEYCARD_EMERGENCY_MAINTENANCE_ACCESS)
			make_maint_all_access()
		if(KEYCARD_BSA_UNLOCK)
			toggle_bluespace_artillery()

GLOBAL_VAR_INIT(emergency_access, FALSE)
/proc/make_maint_all_access()
	for(var/area/maintenance/A in world)
		for(var/obj/machinery/door/airlock/D in A)
			D.emergency = TRUE
			D.update_icon(ALL, 0)
	minor_announce("Ограничения на доступ в тоннели и внешние шлюзы были сняты.", "Внимание! Объявлен режим ЧС!",1)
	GLOB.emergency_access = TRUE
	SSblackbox.record_feedback("nested tally", "keycard_auths", 1, list("emergency maintenance access", "enabled"))

/proc/revoke_maint_all_access()
	for(var/area/maintenance/A in world)
		for(var/obj/machinery/door/airlock/D in A)
			D.emergency = FALSE
			D.update_icon(ALL, 0)
	minor_announce("Ограничения на доступ в тоннели технического обслуживания были восстановлены.", "Внимание! Режим ЧС на станции был отменён:")
	GLOB.emergency_access = FALSE
	SSblackbox.record_feedback("nested tally", "keycard_auths", 1, list("emergency maintenance access", "disabled"))

/proc/toggle_bluespace_artillery()
	GLOB.bsa_unlock = !GLOB.bsa_unlock
	minor_announce("Протоколы стрельбы Блюспейс Артиллерии были [GLOB.bsa_unlock? "разблокированы" : "заблокированы"]", "Оружейные системы:")
	SSblackbox.record_feedback("nested tally", "keycard_auths", 1, list("bluespace artillery", GLOB.bsa_unlock? "unlocked" : "locked"))

#undef ACCESS_GRANTING_COOLDOWN
#undef KEYCARD_RED_ALERT
#undef KEYCARD_EMERGENCY_MAINTENANCE_ACCESS
#undef KEYCARD_BSA_UNLOCK
