/*

Miscellaneous traitor devices

BATTERER

RADIOACTIVE MICROLASER

*/

/*

The Batterer, like a flashbang but 50% chance to knock people over. Can be either very
effective or pretty fucking useless.

*/

/obj/item/batterer
	name = "mind batterer"
	desc = "A strange device with twin antennas."
	icon = 'icons/obj/device.dmi'
	icon_state = "batterer"
	throwforce = 5
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	flags_1 = CONDUCT_1
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'

	var/times_used = 0 //Number of times it's been used.
	var/max_uses = 2


/obj/item/batterer/attack_self(mob/living/carbon/user, flag = 0, emp = 0)
	if(!user) 	return
	if(times_used >= max_uses)
		to_chat(user, "<span class='danger'>The mind batterer has been burnt out!</span>")
		return

	log_combat(user, null, "knocked down people in the area", src)

	for(var/mob/living/carbon/human/M in urange(10, user, 1))
		if(prob(50))

			M.DefaultCombatKnockdown(rand(200,400))
			to_chat(M, "<span class='userdanger'>You feel a tremendous, paralyzing wave flood your mind.</span>")

		else
			to_chat(M, "<span class='userdanger'>You feel a sudden, electric jolt travel through your head.</span>")

	playsound(src.loc, 'sound/misc/interference.ogg', 50, 1)
	to_chat(user, "<span class='notice'>You trigger [src].</span>")
	times_used += 1
	if(times_used >= max_uses)
		icon_state = "battererburnt"

/*
		The radioactive microlaser, a device disguised as a health analyzer used to irradiate people.

		The strength of the radiation is determined by the 'intensity' setting, while the delay between
	the scan and the irradiation kicking in is determined by the wavelength.

		Each scan will cause the microlaser to have a brief cooldown period. Higher intensity will increase
	the cooldown, while higher wavelength will decrease it.

		Wavelength is also slightly increased by the intensity as well.
*/

/obj/item/healthanalyzer/rad_laser
	var/irradiate = TRUE
	var/intensity = 10 // how much damage the radiation does
	var/wavelength = 10 // time it takes for the radiation to kick in, in seconds
	var/used = 0 // is it cooling down?
	var/stealth = FALSE

	var/ui_x = 320
	var/ui_y = 335

/obj/item/healthanalyzer/rad_laser/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/identification/syndicate, ID_COMPONENT_DEL_ON_IDENTIFY, ID_COMPONENT_EFFECT_NO_ACTIONS, ID_COMPONENT_IDENTIFY_WITH_DECONSTRUCTOR)

/obj/item/healthanalyzer/rad_laser/attack(mob/living/M, mob/living/user)
	if(!stealth || !irradiate)
		return ..()
	var/knowledge = SEND_SIGNAL(src, COMSIG_IDENTIFICATION_KNOWLEDGE_CHECK, user) == ID_COMPONENT_KNOWLEDGE_FULL
	if(!irradiate)
		return
	if(!used)
		log_combat(user, M, "[knowledge? "" : "unknowingly "]irradiated", src)
		var/cooldown = get_cooldown()
		used = TRUE
		icon_state = "health1"
		addtimer(VARSET_CALLBACK(src, used, FALSE), cooldown)
		addtimer(VARSET_CALLBACK(src, icon_state, "health"), cooldown)
		if(knowledge)
			to_chat(user, "<span class='warning'>Successfully irradiated [M].</span>")
		addtimer(CALLBACK(src, PROC_REF(radiation_aftereffect), M, intensity), (wavelength+(intensity*4))*5)
	else
		if(knowledge)
			to_chat(user, "<span class='warning'>The radioactive microlaser is still recharging.</span>")

/obj/item/healthanalyzer/rad_laser/proc/radiation_aftereffect(mob/living/M, passed_intensity)
	if(QDELETED(M) || !ishuman(M) || HAS_TRAIT(M, TRAIT_RADIMMUNE))
		return
	if(passed_intensity >= 5)
		M.apply_effect(round(passed_intensity/0.075), EFFECT_UNCONSCIOUS) //to save you some math, this is a round(intensity * (4/3)) second long knockout
	M.rad_act(passed_intensity*10)

/obj/item/healthanalyzer/rad_laser/proc/get_cooldown()
	return round(max(10, (stealth*30 + intensity*5 - wavelength/4)))

/obj/item/healthanalyzer/rad_laser/attack_self(mob/user)
	interact(user)

/obj/item/healthanalyzer/rad_laser/interact(mob/user)
	var/knowledge = SEND_SIGNAL(src, COMSIG_IDENTIFICATION_KNOWLEDGE_CHECK, user) == ID_COMPONENT_KNOWLEDGE_FULL
	if(knowledge)
		ui_interact(user)

/obj/item/healthanalyzer/rad_laser/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/healthanalyzer/rad_laser/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RadioactiveMicrolaser")
		ui.open()

/obj/item/healthanalyzer/rad_laser/ui_data(mob/user)
	var/list/data = list()
	data["irradiate"] = irradiate
	data["stealth"] = stealth
	data["scanmode"] = scanmode
	data["intensity"] = intensity
	data["wavelength"] = wavelength
	data["on_cooldown"] = used
	data["cooldown"] = DisplayTimeText(get_cooldown())
	return data

/obj/item/healthanalyzer/rad_laser/ui_act(action, params)
	if(..())
		return

	switch(action)
		if("irradiate")
			irradiate = !irradiate
			. = TRUE
		if("stealth")
			stealth = !stealth
			. = TRUE
		if("scanmode")
			scanmode = !scanmode
			. = TRUE
		if("radintensity")
			var/target = params["target"]
			var/adjust = text2num(params["adjust"])
			if(target == "min")
				target = 1
				. = TRUE
			else if(target == "max")
				target = 20
				. = TRUE
			else if(adjust)
				target = intensity + adjust
				. = TRUE
			else if(text2num(target) != null)
				target = text2num(target)
				. = TRUE
			if(.)
				target = round(target)
				intensity = clamp(target, 1, 20)
		if("radwavelength")
			var/target = params["target"]
			var/adjust = text2num(params["adjust"])
			if(target == "min")
				target = 0
				. = TRUE
			else if(target == "max")
				target = 120
				. = TRUE
			else if(adjust)
				target = wavelength + adjust
				. = TRUE
			else if(text2num(target) != null)
				target = text2num(target)
				. = TRUE
			if(.)
				target = round(target)
				wavelength = clamp(target, 0, 120)

/obj/item/shadowcloak
	name = "Cloaker Belt"
	desc = "Makes you invisible for short periods of time. Recharges in darkness."
	icon = 'icons/obj/clothing/belts.dmi'
	icon_state = "utilitybelt"
	item_state = "utility"
	slot_flags = ITEM_SLOT_BELT
	attack_verb = list("whipped", "lashed", "disciplined")

	var/mob/living/carbon/human/user = null
	var/charge = 3000
	var/max_charge = 3000
	var/on = FALSE
	var/old_alpha = 50
	actions_types = list(/datum/action/item_action/toggle)

/obj/item/shadowcloak/ui_action_click(mob/user)
	if(user.get_item_by_slot(ITEM_SLOT_BELT) == src)
		if(!on)
			Activate(usr)
		else
			Deactivate()
	return

/obj/item/shadowcloak/item_action_slot_check(slot, mob/user, datum/action/A)
	if(slot == ITEM_SLOT_BELT)
		return TRUE

/obj/item/shadowcloak/proc/Activate(mob/living/carbon/human/user)
	if(!user)
		return
	to_chat(user, "<span class='notice'>Вы активировали [src].</span>")
	src.user = user
	START_PROCESSING(SSobj, src)
	old_alpha = user.alpha
	on = TRUE

/obj/item/shadowcloak/proc/Deactivate()
	to_chat(user, "<span class='notice'>Вы дезактивировали [src].</span>")
	STOP_PROCESSING(SSobj, src)
	if(user)
		user.alpha = old_alpha
	on = FALSE
	user = null

/obj/item/shadowcloak/dropped(mob/user)
	..()
	if(user && user.get_item_by_slot(ITEM_SLOT_BELT) != src)
		Deactivate()

/obj/item/shadowcloak/process()
	if(user.get_item_by_slot(ITEM_SLOT_BELT) != src)
		Deactivate()
		return
	var/turf/T = get_turf(src)
	if(on)
		var/lumcount = T.get_lumcount()
		if(lumcount > 0.3)
			charge = max(0,charge - 25)//Quick decrease in light
		else
			charge = min(max_charge,charge + 50) //Charge in the dark
		animate(user,alpha = clamp(255 - charge,0,255),time = 10)

/obj/item/shadowcloak/run_block(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = ATTACK_TYPE_MELEE)
	. = ..()
	if(on)
		charge = max(0, charge - 1500)

/obj/item/shadowcloak/check_block(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = ATTACK_TYPE_MELEE)
	. = ..()
	if(on)
		charge = max(0, charge - 1500)

/obj/item/jammer
	name = "radio jammer"
	desc = "Device used to disrupt nearby radio communication."
	icon = 'icons/obj/device.dmi'
	icon_state = "jammer"
	var/active = FALSE
	var/range = 12

/obj/item/jammer/attack_self(mob/user)
	to_chat(user,"<span class='notice'>You [active ? "deactivate" : "activate"] [src].</span>")
	active = !active
	if(active)
		GLOB.active_jammers |= src
	else
		GLOB.active_jammers -= src
	update_icon()

/*portable turret*/
/obj/item/storage/toolbox/emergency/turret
	desc = "You feel a strange urge to hit this with a wrench."

/obj/item/storage/toolbox/emergency/turret/PopulateContents()
	new /obj/item/screwdriver(src)
	new /obj/item/wrench(src)
	new /obj/item/weldingtool(src)
	new /obj/item/crowbar(src)
	new /obj/item/analyzer(src)
	new /obj/item/wirecutters(src)

/obj/item/storage/toolbox/emergency/turret/attackby(obj/item/I, mob/living/user, params)
    if(I.tool_behaviour == TOOL_WRENCH && user.a_intent == INTENT_HARM)
        user.visible_message("<span class='danger'>[user] бьёт [src] усилием [I]!</span>", \
            "<span class='danger'>Вы бьёте [src] усилием [I]!</span>", null, COMBAT_MESSAGE_RANGE)
        playsound(src, pick('sound/items/drill1.ogg', 'sound/items/drill2.ogg', 'sound/items/drill3.ogg', 'sound/items/drill4.ogg', 'sound/items/drill5.ogg'), 80, TRUE, -1)
        var/obj/machinery/porta_turret/syndicate/pod/toolbox/turret = new(get_turf(loc))
        turret.faction = list("[REF(user)]")
        qdel(src)
        return

    ..()

/obj/item/headsetupgrader
	name = "headset upgrader"
	desc = "A tool that can be used to upgrade a normal headset to be able to protect from flashbangs."
	icon = 'icons/obj/device.dmi'
	icon_state = "headset_upgrade"

/obj/item/syndicate_teleporter
	name = "Experimental Teleporter"
	desc = "A reverse-engineered version of the Nanotrasen portable handheld teleporter. Lacks the advanced safety features of its counterpart. A three-headed serpent can be seen on the back."
	icon = 'icons/obj/device.dmi'
	icon_state = "syndi-tele"
	item_state = "electronic"
	throwforce = 5
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 4
	throw_range = 10
	flags_1 = CONDUCT_1
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	//Uses of the device left
	var/charges = 4
	//The maximum number of stored uses
	var/max_charges = 4
	///Minimum distance to teleport user forward
	var/minimum_teleport_distance = 4
	///Maximum distance to teleport user forward
	var/maximum_teleport_distance = 8
	//How far the emergency teleport checks for a safe position
	var/parallel_teleport_distance = 3

/obj/item/syndicate_teleporter/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/syndicate_teleporter/Destroy(force)
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/syndicate_teleporter/examine(mob/user)
	. = ..()
	. += span_notice("[src] has <b>[charges]</b> out of [max_charges] charges left.")

/obj/item/syndicate_teleporter/attack_self(mob/user)
	. = ..()
	if(.)
		return
	attempt_teleport(user = user, triggered_by_emp = FALSE)
	return TRUE

/obj/item/syndicate_teleporter/process(delta_time, times_fired)
	if(DT_PROB(10, delta_time) && charges < max_charges)
		charges++
		if(ishuman(loc))
			var/mob/living/carbon/human/holder = loc
			balloon_alert(holder, "teleporter beeps")
		playsound(src, 'sound/machines/twobeep.ogg', 10, TRUE, extrarange = SILENCED_SOUND_EXTRARANGE, falloff_distance = 0)

/obj/item/syndicate_teleporter/emp_act(severity)
	var/teleported_something = FALSE
	if(prob(50/severity))
		if(ishuman(loc))
			var/mob/living/carbon/human/holder = loc
			balloon_alert(holder, "teleporter buzzes!")
			attempt_teleport(user = holder, triggered_by_emp = TRUE)
		else
			var/turf/teleport_turf = get_turf(src)
			for(var/mob/living/mob_on_same_tile in teleport_turf)
				if(!teleported_something)
					teleported_something = TRUE
				attempt_teleport(user = mob_on_same_tile, triggered_by_emp = TRUE, not_holding_tele = TRUE)
			if(!teleported_something)
				visible_message(span_danger("[src] blinks out of existence!"))
				do_sparks(2, 1, src)
				qdel(src)

/**
 * Tries to teleport the user forward based on random number between min/max teleport distance vars.
 * If destination is closed turf, try to save user from gibbing via a panic teleport.
 * Wearing bag of holding or triggering teleport via EMP removes panic teleport, higher chance of being gibbed.
 * Mobs on same tile as destination get telefragged.
 **/
/obj/item/syndicate_teleporter/proc/attempt_teleport(mob/user, triggered_by_emp = FALSE, not_holding_tele = FALSE)
	if(!charges && !triggered_by_emp)
		balloon_alert(user, "recharging!")
		return

	var/turf/current_location = get_turf(user)

	if(malfunctioning(user, current_location, not_holding_tele))
		return

	var/teleport_distance = rand(minimum_teleport_distance, maximum_teleport_distance)
	var/turf/destination = get_teleport_loc(current_location, user, teleport_distance)
	var/bagholdingcheck = FALSE
	if(iscarbon(user))
		var/mob/living/carbon/teleporting_guy = user
		if(locate(/obj/item/storage/backpack/holding) in teleporting_guy.get_all_gear())
			bagholdingcheck = TRUE

	if(isclosedturf(destination))
		if(!triggered_by_emp && !bagholdingcheck)
			panic_teleport(user, destination) //We're in a wall, engage emergency parallel teleport.
		else
			if(bagholdingcheck && !not_holding_tele)
				to_chat(user, span_warning("The bluespace interface on your bag of holding interferes with the teleport!"))
			get_fragged(user, destination, not_holding_tele) //EMP teleported you into a wall? Wearing a BoH? You're dead.
	else
		telefrag(destination, user)
		do_teleport(user, destination, channel = TELEPORT_CHANNEL_FREE)
		charges = max(charges - 1, 0)
		new /obj/effect/temp_visual/teleport_abductor/syndi_teleporter(current_location)
		new /obj/effect/temp_visual/teleport_abductor/syndi_teleporter(destination)
		playsound(current_location, get_sfx("sparks"), 50, 1, SHORT_RANGE_SOUND_EXTRARANGE)
		playsound(destination, 'sound/effects/phasein.ogg', 25, 1, SHORT_RANGE_SOUND_EXTRARANGE)
		playsound(destination, get_sfx("sparks"), 50, 1, SHORT_RANGE_SOUND_EXTRARANGE)

/obj/item/syndicate_teleporter/proc/malfunctioning(mob/guy_teleporting, turf/current_location, not_holding_tele = FALSE)
	var/area/current_area = get_area(current_location)
	. = FALSE
	if(!current_location)
		. = TRUE
	if(current_area.area_flags & NOTELEPORT)
		. = TRUE
	if(is_away_level(current_location.z))
		. = TRUE
	if(is_centcom_level(current_location.z))
		. = TRUE
	if(is_reserved_level(current_location.z))
		. = TRUE
	if(!isturf(guy_teleporting.loc))
		. = TRUE
	if(. && !not_holding_tele)
		balloon_alert(guy_teleporting, "malfunctioning!")

/**
 * Checks parallel_teleport_distance amount of tiles parallel to user's teleport destination.
 * If no valid closed turfs found, gib user.
 **/
/obj/item/syndicate_teleporter/proc/panic_teleport(mob/user, turf/destination)
	var/turf/mobloc = get_turf(user)
	var/turf/emergency_destination = get_teleport_loc(destination, user, distance = 0, closed_turf_check = TRUE, errorx = parallel_teleport_distance)

	if(emergency_destination)
		telefrag(emergency_destination, user)
		do_teleport(user, emergency_destination, channel = TELEPORT_CHANNEL_FREE)
		charges = max(charges - 1, 0)
		new /obj/effect/temp_visual/teleport_abductor/syndi_teleporter(mobloc)
		new /obj/effect/temp_visual/teleport_abductor/syndi_teleporter(emergency_destination)
		balloon_alert(user, "emergency teleport triggered!")
		playsound(mobloc, get_sfx("sparks"), 50, 1, SHORT_RANGE_SOUND_EXTRARANGE)
		playsound(emergency_destination, 'sound/effects/phasein.ogg', 25, 1, SHORT_RANGE_SOUND_EXTRARANGE)
		playsound(emergency_destination, get_sfx("sparks"), 50, 1, SHORT_RANGE_SOUND_EXTRARANGE)
	else //We tried to save. We failed. Death time.
		get_fragged(user, destination)

///Force move victim to destination, explode destination, drop all victim's items, gib them
/obj/item/syndicate_teleporter/proc/get_fragged(mob/living/victim, turf/destination, not_holding_tele = FALSE)
	var/turf/mobloc = get_turf(victim)
	victim.forceMove(destination)
	new /obj/effect/temp_visual/teleport_abductor/syndi_teleporter(mobloc)
	new /obj/effect/temp_visual/teleport_abductor/syndi_teleporter(destination)
	playsound(mobloc, get_sfx("sparks"), 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	playsound(destination, get_sfx("sparks"), 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	playsound(destination, "sound/magic/disintegrate.ogg", 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	if(!not_holding_tele)
		to_chat(victim, span_userdanger("You teleport into [destination], [src] tries to save you, but..."))
	else
		to_chat(victim, span_userdanger("You teleport into [destination]."))
	destination.ex_act(EXPLODE_HEAVY)
	victim.unequip_everything()
	victim.gib()

/obj/item/syndicate_teleporter/proc/telefrag(turf/fragging_location, mob/user)
	for(var/mob/living/M in fragging_location)//Hit everything in the turf
		M.apply_damage(20, BRUTE)
		M.Knockdown(6 SECONDS)
		to_chat(M, "<span_class='warning'>[user] телепортируется в вас, откидывая блюспейс-потоком!</span>")

/obj/item/paper/teleporter
	name = "Teleporter Guide"
	default_raw_text = {"<b>Инструкции по работе с новым прототипом телепорта Синдиката</b><br>
	<br>
	Этот телепортатор перемещает пользователя на 4-8 метров в том направлении, куда он смотрит. В отличии от подобного Искажателя Реальности Кровавых Культистов, вы не можете тащить за собой людей.<br>
	<br>
	У него 4 заряда и он будет перезаряжаться с течением времени. Нет, если засунуть телепортатор в теслу, БТР, микроволновку или наэлектризованную дверь, он не будет заряжаться быстрее.<br>
	<br>
	<b>ВНИМАНИЕ:</b> Телепортация в стены активирует безотказную телепортацию параллельно на расстояние до 3 метров, однако в редком случае пользователь будет разорван на части и впечатан в стену.<br>
	<br>
	Не подвергайте телепортатор воздействию электромагнитных импульсов и не пытайтесь использовать его с Блюспейс-Сумками, возможны нежелательные сбои в работе.
"}
/obj/item/storage/box/syndie_kit/teleporter
	name = "Syndicate Teleporter Kit"

/obj/item/storage/box/syndie_kit/teleporter/PopulateContents()
	new /obj/item/syndicate_teleporter(src)
	new /obj/item/paper/teleporter(src)

/obj/effect/temp_visual/teleport_abductor/syndi_teleporter
	duration = 5
