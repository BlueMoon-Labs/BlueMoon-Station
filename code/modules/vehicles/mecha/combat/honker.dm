/obj/vehicle/sealed/mecha/combat/honker
	name = "\improper H.O.N.K"
	desc = "Произведён \"Tyranny of Honk, INC\", этот экзокостюм разработан как тяжёлая поддержка клоунов. Используется для распространения веселья и радости жизни. ХОНК!"
	icon_state = "honker"
	movedelay = 3
	max_integrity = 140
	deflect_chance = 60
	internal_damage_threshold = 60
	armor_type = /datum/armor/honker
	max_temperature = 25000
	operation_req_access = list(ACCESS_THEATRE)
	internals_req_access = list(ACCESS_ROBOTICS, ACCESS_THEATRE)
	wreckage = /obj/structure/mecha_wreckage/honker
	mecha_flags = CANSTRAFE | IS_ENCLOSED | HAS_LIGHTS
	max_equip = 3
	mecha_type = MECHA_TYPE_COMBAT | MECHA_TYPE_HONKER
	ui_theme = "abductor"
	var/squeak = TRUE

/obj/vehicle/sealed/mecha/combat/honker/play_stepsound()
	// Same as the base: thrust / push-off and drift-loop moves aren't footsteps, so don't squeak on them.
	if(step_silent)
		step_silent = FALSE
		return
	if(inertia_moving)
		return
	if(squeak)
		playsound(src, "clownstep", 70, 1)
	squeak = !squeak

/obj/vehicle/sealed/mecha/combat/honker/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || action != "play_sound" || ui_status(ui.user, state) != UI_INTERACTIVE || !(occupants[ui.user] & VEHICLE_CONTROL_SETTINGS))
		return
	if(params["sound"])
		switch(params["sound"])
			if("sadtrombone")
				playsound(src, 'sound/misc/sadtrombone.ogg', 50)
			if("bikehorn")
				playsound(src, 'sound/items/bikehorn.ogg', 50)
			if("airhorn2")
				playsound(src, 'sound/items/airhorn2.ogg', 40) // Запись громче остальных.
			if("carhorn")
				playsound(src, 'sound/items/carhorn.ogg', 80) // Запись тише остальных.
			if("party_horn")
				playsound(src, 'sound/items/party_horn.ogg', 50)
			if("reee")
				playsound(src, 'sound/effects/reee.ogg', 50)
			if("weeoo1")
				playsound(src, 'sound/items/weeoo1.ogg', 50)
			if("hiss1")
				playsound(src, 'sound/voice/hiss1.ogg', 50)
			if("armbomb")
				playsound(src, 'sound/weapons/armbomb.ogg', 50)
			if("saberon")
				playsound(src, 'sound/weapons/saberon.ogg', 50)
			if("airlock_alien_prying")
				playsound(src, 'sound/machines/airlock_alien_prying.ogg', 50)
			if("lightningbolt")
				playsound(src, 'sound/magic/lightningbolt.ogg', 50)
			if("explosionfar")
				playsound(src, 'sound/effects/explosionfar.ogg', 50)
	return TRUE
