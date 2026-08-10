#define HOOKAH_MAX_BURN_TIME 3000
#define HOOKAH_PASSIVE_SOUND_COOLDOWN (15 SECONDS)
#define GAS_HOOKAH_VAPOR "hookah_vapor"

// Газ кальяна как water_vapor, но пол не мокнет
/datum/gas/hookah_vapor
	id = GAS_HOOKAH_VAPOR
	specific_heat = 40
	name = "Hookah Steam"
	gas_overlay = "water_vapor"
	moles_visible = 0.01

/datum/gas/hookah_vapor/generate_TLV()
	return new/datum/tlv/no_checks

// Постепенное развеивание
/datum/gas_reaction/hookah_vapor_dissipation
	priority = 0
	name = "Hookah Vapor Dissipation"
	id = "hookah_dissipation"

/datum/gas_reaction/hookah_vapor_dissipation/init_reqs()
	min_requirements = list(GAS_HOOKAH_VAPOR = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/hookah_vapor_dissipation/react(datum/gas_mixture/air, datum/holder)
	var/turf/open/location = holder
	if(!istype(location))
		return NO_REACTION
	var/current = air.get_moles(GAS_HOOKAH_VAPOR)
	if(current < MINIMUM_MOLE_COUNT)
		return NO_REACTION
	// Never remove more than present — negative moles crash auxmos (native illegal op).
	var/remove_amount = min(current, max(current * 0.1, MINIMUM_MOLE_COUNT))
	if(remove_amount <= 0)
		return NO_REACTION
	air.adjust_moles(GAS_HOOKAH_VAPOR, -remove_amount)
	if(air.get_moles(GAS_HOOKAH_VAPOR) < MINIMUM_MOLE_COUNT)
		air.set_moles(GAS_HOOKAH_VAPOR, 0)
	return NO_REACTION

// Кальян структура
/obj/structure/hookah
	name = "Hookah"
	desc = "Кальянчик. Можно расслабиться и немного покурить с друзьями."
	icon = 'modular_bluemoon/icons/obj/hookah.dmi'
	icon_state = "kalik_truba"
	density = TRUE
	anchored = FALSE
	resistance_flags = FIRE_PROOF
	move_resist = MOVE_RESIST_DEFAULT
	max_integrity = 150
	var/lit = FALSE
	var/burn_time = 0
	var/range = 2
	var/obj/item/clothing/mask/hookah_hose/hose = null
	var/smoke_cycle = 0
	var/last_burn_sound = 0
	var/mutable_appearance/flame_overlay
	var/mutable_appearance/liquid_overlay
	var/mutable_appearance/liquid_active_overlay

/obj/structure/hookah/Initialize(mapload)
	. = ..()
	anchored = TRUE
	create_reagents(200, OPENCONTAINER)
	if(!hose)
		hose = new(src)
		hose.hookah = src
	update_icon()

/obj/structure/hookah/on_reagent_change(changetype)
	return

/obj/structure/hookah/update_icon(updates=ALL)
	. = ..()
	refresh_overlays()

/obj/structure/hookah/proc/refresh_overlays()
	cut_overlay(flame_overlay)
	cut_overlay(liquid_overlay)
	cut_overlay(liquid_active_overlay)
	if(reagents.total_volume > 0)
		var/mutable_appearance/new_liquid = mutable_appearance(icon, "hookah_liquid")
		new_liquid.color = mix_color_from_reagents(reagents.reagent_list)
		add_overlay(new_liquid)
		liquid_overlay = new_liquid
		if(lit)
			var/mutable_appearance/new_active = mutable_appearance(icon, "hookah_liquid_active")
			add_overlay(new_active)
			liquid_active_overlay = new_active
	if(lit)
		var/mutable_appearance/new_flame = mutable_appearance(icon, "hookah_fire")
		new_flame.appearance_flags = RESET_COLOR
		add_overlay(new_flame)
		flame_overlay = new_flame

/obj/structure/hookah/Destroy()
	flame_overlay = null
	liquid_overlay = null
	liquid_active_overlay = null
	if(hose)
		hose.hookah = null
		qdel(hose)
		hose = null
	if(lit)
		STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/hookah/update_icon_state()
	if(hose && hose.loc == src)
		icon_state = "kalik_truba"
	else
		icon_state = "kalik"

/obj/structure/hookah/examine(mob/user)
	. = ..()
	if(reagents.total_volume)
		. += span_notice("В колбе [reagents.total_volume] единиц жидкости.")
	else
		. += span_notice("Колба пуста.")
	if(lit)
		. += span_warning("Угли раскалены и готовы к курению.")
	else
		. += span_notice("Угли не зажжены.")
	if(hose)
		if(hose.loc == src)
			. += span_notice("Шланг свисает с кальяна.")
		else
			. += span_notice("Шланг у кого-то в руках.")
	. += span_notice("Интенты: Disarm — потушить | Grab — собрать | Harm — вылить")

/obj/structure/hookah/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/clothing/mask/hookah_hose))
		var/obj/item/clothing/mask/hookah_hose/HH = I
		if(HH.hookah == src)
			user.transferItemToLoc(HH, src)
			HH.hookah = src
			HH.update_beam()
			user.visible_message(span_notice("[user] возвращает шланг к [src]."), span_notice("Вы возвращаете шланг к [src]."))
			playsound(src, 'sound/items/handling/toolbox_pickup.ogg', 20, TRUE)
			update_icon()
			return TRUE
		else
			balloon_alert(user, "Это не от этого кальяна!")
			return TRUE

	if(!lit && I.get_temperature())
		if(reagents.total_volume <= 0)
			balloon_alert(user, "Нечего курить!")
			return TRUE
		light(user)
		return TRUE

	if(istype(I, /obj/item/reagent_containers))
		var/obj/item/reagent_containers/RC = I
		if(lit)
			balloon_alert(user, "Сначала потушите!")
			return TRUE
		if(reagents.total_volume >= reagents.maximum_volume)
			balloon_alert(user, "Полная колба!")
			return TRUE
		if(!RC.reagents || !RC.reagents.total_volume)
			balloon_alert(user, "Пустая ёмкость!")
			return TRUE
		var/amount = RC.reagents.trans_to(src, RC.amount_per_transfer_from_this)
		if(amount)
			user.visible_message(span_notice("[user] наливает что-то в колбу [src]."), span_notice("Вы наливаете жидкость в колбу [src]."))
			playsound(src, 'sound/effects/bubbles.ogg', 20, TRUE)
			update_icon()
		else
			balloon_alert(user, "Невозможно залить!")
		return TRUE

	// Продлить
	if(istype(I, /obj/item/lighter) || istype(I, /obj/item/match))
		if(!lit)
			light(user) // Зажечь
			return TRUE
		else
			// Продлить время горения (макс 2x от базового)
			if(burn_time < HOOKAH_MAX_BURN_TIME * 2)
				burn_time = min(burn_time + 600, HOOKAH_MAX_BURN_TIME * 2)
				user.visible_message(span_notice("[user] поправляет угли [src]."), span_notice("Вы поправляете угли [src]."))
				playsound(src, 'sound/effects/comfyfire.ogg', 30, TRUE)
				return TRUE
			else
				balloon_alert(user, "Угли и так раскалены!")
				return TRUE

	return ..()

/obj/structure/hookah/attack_hand(mob/user)
	. = ..()
	if(.)
		return

	switch(user.a_intent)
		// Help - взять/вернуть шланг
		if(INTENT_HELP)
			if(!user.CanReach(src))
				return
			if(!hose)
				hose = new(src)
				hose.hookah = src
				if(!user.put_in_hands(hose))
					hose.forceMove(get_turf(src))
				user.visible_message(span_notice("[user] берет шланг от [src]."), span_notice("Вы берете шланг от [src]."))
				playsound(src, 'sound/items/handling/toolbox_pickup.ogg', 20, TRUE)
				hose.update_beam()
				update_icon()
				return
			if(hose.loc == src)
				if(!user.put_in_hands(hose))
					hose.forceMove(get_turf(src))
				user.visible_message(span_notice("[user] берет шланг от [src]."), span_notice("Вы берете шланг от [src]."))
				playsound(src, 'sound/items/handling/toolbox_pickup.ogg', 20, TRUE)
				hose.update_beam()
				update_icon()
				return
			if(hose.loc == user)
				if(hose.hookah != src)
					balloon_alert(user, "Это не от этого кальяна!")
					return
				user.transferItemToLoc(hose, src)
				hose.hookah = src
				hose.update_beam()
				user.visible_message(span_notice("[user] возвращает шланг к [src]."), span_notice("Вы возвращаете шланг к [src]."))
				playsound(src, 'sound/items/handling/toolbox_pickup.ogg', 20, TRUE)
				update_icon()
				return
			if(isturf(hose.loc) && get_dist(hose, src) <= 1)
				hose.forceMove(src)
				hose.hookah = src
				hose.update_beam()
				user.visible_message(span_notice("[user] возвращает шланг к [src]."), span_notice("Вы возвращаете шланг к [src]."))
				playsound(src, 'sound/items/handling/toolbox_pickup.ogg', 20, TRUE)
				update_icon()
				return
			if(ismob(hose.loc) && hose.loc != user)
				balloon_alert(user, "Шланг у кого-то другого!")
				return

		// Disarm - потушить угли
		if(INTENT_DISARM)
			if(!lit)
				balloon_alert(user, "Угли и так не горят!")
				return
			user.visible_message(span_notice("[user] тушит угли [src]."), span_notice("Вы тушите угли [src]."))
			hookah_extinguish()
			return

		// Grab - собрать в переносной
		if(INTENT_GRAB)
			if(lit)
				balloon_alert(user, "Сначала потушите!")
				return
			if(reagents.total_volume > 0)
				balloon_alert(user, "Сначала вылейте содержимое!")
				return
			if(hose && hose.loc != src)
				balloon_alert(user, "Сначала верните шланг!")
				return
			user.visible_message(span_notice("[user] собирает [src]."), span_notice("Вы собираете [src]."))
			playsound(src, 'sound/items/ratchet.ogg', 30, TRUE)
			new /obj/item/hookah(get_turf(src))
			qdel(src)
			return

		// Harm - вылить содержимое
		if(INTENT_HARM)
			if(reagents.total_volume <= 0)
				balloon_alert(user, "Колба пуста!")
				return
			if(lit)
				balloon_alert(user, "Сначала потушите!")
				return
			user.visible_message(span_warning("[user] выливает содержимое [src]."), span_warning("Вы выливаете содержимое [src]."))
			reagents.clear_reagents()
			playsound(src, 'sound/effects/splash.ogg', 30, TRUE)
			update_icon()
			return

/obj/structure/hookah/proc/light(mob/user)
	if(lit)
		return
	lit = TRUE
	burn_time = HOOKAH_MAX_BURN_TIME
	START_PROCESSING(SSobj, src)
	update_icon()
	user.visible_message(span_notice("[user] зажигает угли [src]."), span_notice("Вы зажигаете угли [src]."))
	playsound(src, 'modular_bluemoon/sound/items/hookah/ugli.ogg', 50, TRUE)

/obj/structure/hookah/proc/hookah_extinguish()
	if(!lit)
		return
	lit = FALSE
	STOP_PROCESSING(SSobj, src)
	update_icon()
	visible_message(span_notice("[src] тухнет."))
	playsound(src, 'modular_bluemoon/sound/items/hookah/fire_phh.ogg', 50, TRUE)

/obj/structure/hookah/process()
	if(!lit)
		return

	burn_time--
	smoke_cycle++

	// Пассивный звук горения
	if(world.time > last_burn_sound + HOOKAH_PASSIVE_SOUND_COOLDOWN)
		playsound(src, 'sound/effects/comfyfire.ogg', 10, TRUE, -5)
		last_burn_sound = world.time

	if(reagents.total_volume > 0)
		reagents.remove_all(0.08)
		if(!reagents.total_volume)
			refresh_overlays()

	// Дым
	if(smoke_cycle >= 2)
		smoke_cycle = 0
		var/turf/center = get_turf(src)
		if(reagents.total_volume > 0)
			var/mixcolor = mix_color_from_reagents(reagents.reagent_list)
			var/obj/effect/temp_visual/small_smoke/S = new(center)
			if(mixcolor)
				S.color = mixcolor
			S.alpha = 120
			S.pixel_x = rand(-8, 8)
			S.pixel_y = rand(0, 8)
			var/turf/open/pos = center
			if(istype(pos))
				pos.atmos_spawn_air("[GAS_HOOKAH_VAPOR]=35;TEMP=[T20C]")
		else
			for(var/i in 1 to 2)
				var/obj/effect/temp_visual/small_smoke/halfsecond/S = new(center)
				S.alpha = 50
				S.pixel_x = rand(-8, 8)
				S.pixel_y = rand(0, 8)

	if(hose && hose.loc != src && get_dist(hose, src) > range)
		var/mob/living/carbon/C = hose.loc
		if(istype(C))
			C.dropItemToGround(hose, TRUE)
			to_chat(C, span_warning("Шланг вырвался из ваших рук!"))

	if(hose && hose.loc != src && get_dist(hose, src) <= range)
		var/mob/living/carbon/C = hose.loc
		if(istype(C) && hose == C.wear_mask && prob(30))
			var/turf/user_turf = get_turf(C)
			new /obj/effect/particle_effect/smoke/cigsmoke(user_turf)

	if(hose && hose.loc != src && reagents.total_volume > 0 && get_dist(hose, src) <= range)
		var/mob/living/carbon/C = hose.loc
		if(istype(C) && hose == C.wear_mask)
			var/fraction = min(REAGENTS_METABOLISM / reagents.total_volume, 1)
			reagents.reaction(C, INGEST, fraction)
			reagents.trans_to(C, REAGENTS_METABOLISM)

	if(reagents.total_volume <= 0 && prob(1))
		var/turf/T = get_turf(src)
		do_sparks(1, TRUE, T)
		visible_message(span_warning("Угли [src] трещат от перегрева."))

	if(burn_time <= 0 || (reagents.total_volume <= 0 && prob(3)))
		hookah_extinguish()

#undef HOOKAH_MAX_BURN_TIME
#undef HOOKAH_PASSIVE_SOUND_COOLDOWN
#undef GAS_HOOKAH_VAPOR
