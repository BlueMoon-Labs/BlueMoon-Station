/*
A mob of type /mob/camera/disease is an overmind coordinating at least one instance of /datum/disease/advance/sentient_disease
that has infected a host. All instances in a host will be synchronized with the stats of the overmind's disease_template. Any
samples outside of a host will retain the stats they had when they left the host, but infecting a new host will cause
the new instance inside the host to be updated to the template's stats.
*/

/mob/camera/disease
	name = "Sentient Disease"
	real_name = "Sentient Disease"
	desc = ""
	icon = 'icons/mob/cameramob.dmi'
	icon_state = "marker"
	mouse_opacity = MOUSE_OPACITY_ICON
	move_on_shuttle = FALSE
	see_in_dark = 8
	invisibility = INVISIBILITY_OBSERVER
	layer = BELOW_MOB_LAYER
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	sight = SEE_SELF|SEE_THRU
	initial_language_holder = /datum/language_holder/universal

	var/freemove = TRUE
	var/freemove_end = 0
	var/const/freemove_time = 1200
	var/freemove_end_timerid

	var/datum/action/innate/disease_adapt/adaptation_menu_action

	var/mob/living/following_host
	var/list/disease_instances
	var/list/hosts //this list is associative, affected_mob -> disease_instance
	var/datum/disease/advance/sentient_disease/disease_template

	var/total_points = 0
	var/points = 0

	var/last_move_tick = 0
	var/move_delay = 1

	var/next_adaptation_time = 0
	var/adaptation_cooldown = 600

	var/list/purchased_abilities
	var/list/unpurchased_abilities

/mob/camera/disease/Initialize(mapload)
	.= ..()

	disease_instances = list()
	hosts = list()

	purchased_abilities = list()
	unpurchased_abilities = list()

	disease_template = new /datum/disease/advance/sentient_disease()
	disease_template.overmind = src
	qdel(SSdisease.archive_diseases[disease_template.GetDiseaseID()])
	SSdisease.archive_diseases[disease_template.GetDiseaseID()] = disease_template //important for stuff that uses disease IDs

	var/datum/atom_hud/my_hud = GLOB.huds[DATA_HUD_SENTIENT_DISEASE]
	my_hud.add_hud_to(src)

	freemove_end = world.time + freemove_time
	freemove_end_timerid = addtimer(CALLBACK(src, PROC_REF(infect_random_patient_zero)), freemove_time, TIMER_STOPPABLE)

/mob/camera/disease/Destroy()
	. = ..()
	QDEL_NULL(adaptation_menu_action)
	for(var/V in GLOB.sentient_disease_instances)
		var/datum/disease/advance/sentient_disease/S = V
		if(S.overmind == src)
			var/old_id = S.GetDiseaseID()
			S.overmind = null
			// Re-register in archive under new ID so antibodies/vaccines still work (cured patients get "...|null" in resistances)
			SSdisease.archive_diseases -= old_id
			SSdisease.archive_diseases[S.GetDiseaseID()] = S

/mob/camera/disease/Login()
	..()
	if(freemove)
		to_chat(src, "<span class='warning'>You have [DisplayTimeText(freemove_end - world.time)] to select your first host. Click on a human to select your host.</span>")


/mob/camera/disease/get_status_tab_items()
	..()
	if(freemove)
		. += "Host Selection Time: [round((freemove_end - world.time)/10)]s"
	else
		. += "Adaptation Points: [points]/[total_points]"
		. += "Hosts: [disease_instances.len]"
		var/adapt_ready = next_adaptation_time - world.time
		if(adapt_ready > 0)
			. += "Adaptation Ready: [round(adapt_ready/10, 0.1)]s"


/mob/camera/disease/examine(mob/user)
	. = ..()
	if(isobserver(user))
		. += "<span class='notice'>[src] has [points]/[total_points] adaptation points.</span>"
		. += "<span class='notice'>[src] has the following unlocked:</span>"
		for(var/A in purchased_abilities)
			var/datum/disease_ability/B = A
			if(istype(B))
				. += "<span class='notice'>[B.name]</span>"

/mob/camera/disease/say(message, bubble_type, var/list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	return

/mob/camera/disease/Move(NewLoc, Dir = 0)
	if(freemove)
		forceMove(NewLoc)
	else
		if(world.time > (last_move_tick + move_delay))
			follow_next(Dir & NORTHWEST)
			last_move_tick = world.time

/mob/camera/disease/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	. = ..()
	var/atom/movable/to_follow = speaker
	if(radio_freq)
		var/atom/movable/virtualspeaker/V = speaker
		to_follow = V.source
	var/link
	if(to_follow in hosts)
		link = FOLLOW_LINK(src, to_follow)
	else
		link = ""
	// Create map text prior to modifying message for goonchat
	if (client?.prefs.chat_on_map && (client.prefs.see_chat_non_mob || ismob(speaker)))
		create_chat_message(speaker, message_language, raw_message, spans, message_mode)
	// Recompose the message, because it's scrambled by default
	message = compose_message(speaker, message_language, raw_message, radio_freq, spans, message_mode, FALSE, source)
	to_chat(src, "[link] [message]")


/mob/camera/disease/mind_initialize()
	. = ..()
	if(!mind.has_antag_datum(/datum/antagonist/disease))
		mind.add_antag_datum(/datum/antagonist/disease)
	var/datum/atom_hud/medsensor = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	medsensor.add_hud_to(src)

/mob/camera/disease/proc/pick_name()
	var/static/list/taken_names
	if(!taken_names)
		taken_names = list("Unknown" = TRUE)
		for(var/T in (subtypesof(/datum/disease) - /datum/disease/advance))
			var/datum/disease/D = T
			taken_names[initial(D.name)] = TRUE
	var/set_name
	while(!set_name)
		var/input = stripped_input(src, "Select a name for your disease", "Select Name", "", MAX_NAME_LEN)
		if(!input)
			set_name = "Sentient Virus"
			break
		if(taken_names[input])
			to_chat(src, "<span class='notice'>You cannot use the name of such a well-known disease!</span>")
		else
			set_name = input
	real_name = "[set_name] (Sentient Disease)"
	name = "[set_name] (Sentient Disease)"
	disease_template.AssignName(set_name)
	var/datum/antagonist/disease/A = mind.has_antag_datum(/datum/antagonist/disease)
	if(A)
		A.disease_name = set_name

/mob/camera/disease/ui_state(mob/user)
	if(user == src)
		return GLOB.always_state
	return GLOB.never_state

/mob/camera/disease/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SentientDisease", "Меню адаптации вируса")
		ui.open()

/mob/camera/disease/proc/get_ability_tier(datum/disease_ability/A)
	if(istype(A, /datum/disease_ability/action))
		return "action"
	if(istype(A, /datum/disease_ability/symptom/mild))
		return "weak"
	if(istype(A, /datum/disease_ability/symptom/medium/heal))
		return "support"
	if(istype(A, /datum/disease_ability/symptom/powerful/heal))
		return "support_advanced"
	if(istype(A, /datum/disease_ability/symptom/powerful))
		return "strong"
	if(istype(A, /datum/disease_ability/symptom/medium))
		return "standard"
	return "unknown"

/mob/camera/disease/proc/get_ability_stat_data(datum/disease_ability/A)
	var/list/data = list(
		"resistance" = 0,
		"stealth" = 0,
		"stage_speed" = 0,
		"transmission" = 0,
	)
	if(!A.symptoms)
		return data
	for(var/T in A.symptoms)
		var/datum/symptom/S = T
		data["resistance"] += initial(S.resistance)
		data["stealth"] += initial(S.stealth)
		data["stage_speed"] += initial(S.stage_speed)
		data["transmission"] += initial(S.transmittable)
	return data

/mob/camera/disease/proc/get_host_status_text(mob/living/L)
	if(!L)
		return "Потерян"
	if(L.stat == DEAD)
		return "Мёртв"
	if(L.stat == UNCONSCIOUS)
		return "Без сознания"
	return "Активен"

/mob/camera/disease/ui_data(mob/user)
	. = ..()
	var/list/data = .
	if(!islist(data))
		data = list()
	. = data
	var/datum/disease/advance/sentient_disease/DT = disease_template

	data["disease_name"] = DT ? DT.name : "Разумный вирус"
	data["points"] = points
	data["total_points"] = total_points
	data["host_count"] = disease_instances.len
	data["purchased_count"] = purchased_abilities.len
	data["can_adapt"] = world.time >= next_adaptation_time
	data["adaptation_ready_in"] = max(0, next_adaptation_time - world.time)
	data["cure"] = DT ? DT.cure_text : "Не определено"
	data["stats"] = list(
		"resistance" = DT ? DT.totalResistance() : 0,
		"stealth" = DT ? DT.totalStealth() : 0,
		"stage_speed" = DT ? DT.totalStageSpeed() : 0,
		"transmission" = DT ? DT.totalTransmittable() : 0,
	)

	if(following_host)
		data["following_host"] = list(
			"ref" = REF(following_host),
			"name" = following_host.real_name,
			"health" = round(following_host.health),
			"maxHealth" = round(following_host.maxHealth),
			"status" = get_host_status_text(following_host),
		)

	data["hosts"] = list()
	for(var/datum/disease/advance/sentient_disease/V as anything in disease_instances)
		var/mob/living/L = V.affected_mob
		if(!L)
			continue
		data["hosts"] += list(list(
			"ref" = REF(L),
			"name" = L.real_name,
			"health" = round(L.health),
			"maxHealth" = round(L.maxHealth),
			"status" = get_host_status_text(L),
			"is_following" = L == following_host,
		))

	data["abilities"] = list()
	for(var/datum/disease_ability/A as anything in GLOB.disease_ability_singletons)
		var/list/stat_data = get_ability_stat_data(A)
		data["abilities"] += list(list(
			"id" = REF(A),
			"path" = "[A.type]",
			"name" = A.name,
			"short_desc" = A.short_desc,
			"long_desc" = A.long_desc,
			"cost" = A.cost,
			"unlock" = A.required_total_points,
			"category" = A.category,
			"tier" = get_ability_tier(A),
			"purchased" = !!purchased_abilities[A],
			"can_buy" = A.CanBuy(src),
			"can_refund" = A.CanRefund(src),
			"resistance" = stat_data["resistance"],
			"stealth" = stat_data["stealth"],
			"stage_speed" = stat_data["stage_speed"],
			"transmission" = stat_data["transmission"],
		))

/mob/camera/disease/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(usr != src)
		return TRUE
	switch(action)
		if("follow_host")
			var/mob/living/L = locate(params["host"])
			if(L && hosts[L])
				set_following(L)
			. = TRUE
		if("buy_ability")
			var/datum/disease_ability/A = locate(params["ability"])
			if(istype(A) && A.CanBuy(src))
				A.Buy(src)
			. = TRUE
		if("refund_ability")
			var/datum/disease_ability/A = locate(params["ability"])
			if(istype(A) && A.CanRefund(src))
				A.Refund(src)
			. = TRUE
	if(.)
		SStgui.update_uis(src)

/mob/camera/disease/proc/infect_random_patient_zero(del_on_fail = TRUE)
	if(!freemove)
		return FALSE
	var/list/possible_hosts = list()
	var/list/afk_possible_hosts = list()
	for(var/mob/living/carbon/human/H in GLOB.carbon_list)
		var/turf/T = get_turf(H)
		if((H.stat != DEAD) && T && is_station_level(T.z) && H.CanContractDisease(disease_template))
			if(H.client && !H.client.is_afk())
				possible_hosts += H
			else
				afk_possible_hosts += H

	shuffle_inplace(possible_hosts)
	shuffle_inplace(afk_possible_hosts)
	possible_hosts += afk_possible_hosts //ideally we want a not-afk person, but we will settle for an afk one if there are no others (mostly for testing)

	while(possible_hosts.len)
		var/mob/living/carbon/human/target = possible_hosts[1]
		if(force_infect(target))
			return TRUE
		possible_hosts.Cut(1, 2)

	if(del_on_fail)
		to_chat(src, "<span class=userdanger'>No hosts were available for your disease to infect.</span>")
		qdel(src)
	return FALSE

/mob/camera/disease/proc/force_infect(mob/living/L)
	var/datum/disease/advance/sentient_disease/V = disease_template.Copy()
	var/result = L.ForceContractDisease(V, FALSE, TRUE)
	if(result && freemove)
		end_freemove()
	return result

/mob/camera/disease/proc/end_freemove()
	if(!freemove)
		return
	freemove = FALSE
	move_on_shuttle = TRUE
	adaptation_menu_action = new /datum/action/innate/disease_adapt()
	adaptation_menu_action.Grant(src)
	for(var/V in GLOB.disease_ability_singletons)
		unpurchased_abilities[V] = TRUE
		var/datum/disease_ability/A = V
		if(A.start_with && A.CanBuy(src))
			A.Buy(src, TRUE, FALSE)
	if(freemove_end_timerid)
		deltimer(freemove_end_timerid)
	sight = SEE_SELF

/mob/camera/disease/proc/add_infection(datum/disease/advance/sentient_disease/V)
	disease_instances += V
	hosts[V.affected_mob] = V
	total_points = max(total_points, disease_instances.len)
	points += 1

	var/image/holder = V.affected_mob.hud_list[SENTIENT_DISEASE_HUD]
	var/mutable_appearance/MA = new /mutable_appearance(holder)
	MA.icon_state = "virus_infected"
	MA.layer = BELOW_MOB_LAYER
	MA.color = COLOR_GREEN_GRAY
	MA.alpha = 200
	holder.appearance = MA
	var/datum/atom_hud/my_hud = GLOB.huds[DATA_HUD_SENTIENT_DISEASE]
	my_hud.add_to_hud(V.affected_mob)

	to_chat(src, "<span class='notice'>A new host, <b>[V.affected_mob.real_name]</b>, has been infected.</span>")

	if(!following_host)
		set_following(V.affected_mob)
	refresh_adaptation_menu()

/mob/camera/disease/proc/remove_infection(datum/disease/advance/sentient_disease/V)
	if(QDELETED(src))
		disease_instances -= V
		hosts -= V.affected_mob
	else
		to_chat(src, "<span class='notice'>One of your hosts, <b>[V.affected_mob.real_name]</b>, has been purged of your infection.</span>")

		var/datum/atom_hud/my_hud = GLOB.huds[DATA_HUD_SENTIENT_DISEASE]
		my_hud.remove_from_hud(V.affected_mob)

		if(following_host == V.affected_mob)
			follow_next()

		disease_instances -= V
		hosts -= V.affected_mob

		if(!disease_instances.len)
			to_chat(src, "<span class='userdanger'>The last of your infection has disappeared.</span>")
			set_following(null)
			qdel(src)
		refresh_adaptation_menu()

/mob/camera/disease/proc/set_following(mob/living/L)
	if(following_host)
		UnregisterSignal(following_host, COMSIG_MOVABLE_MOVED)
	if(!L)
		following_host = null
		return
	RegisterSignal(L, COMSIG_MOVABLE_MOVED, PROC_REF(follow_mob))
	following_host = L
	follow_mob()

/mob/camera/disease/proc/follow_next(reverse = FALSE)
	var/index = hosts.Find(following_host)
	if(index)
		if(reverse)
			index = index == 1 ? hosts.len : index - 1
		else
			index = index == hosts.len ? 1 : index + 1
		set_following(hosts[index])

/mob/camera/disease/proc/follow_mob(datum/source, newloc, dir)
	var/turf/T = get_turf(following_host)
	if(T)
		forceMove(T)

/mob/camera/disease/DblClickOn(var/atom/A, params)
	if(hosts[A])
		set_following(A)
	else
		..()

/mob/camera/disease/ClickOn(var/atom/A, params)
	if(freemove && ishuman(A))
		confirm_initial_infection(A)
	else
		..()

/mob/camera/disease/proc/confirm_initial_infection(mob/living/carbon/human/H)
	set waitfor = FALSE
	if(alert(src, "Select [H.name] as your initial host?", "Select Host", "Yes", "No") != "Yes")
		return
	if(!freemove)
		return
	if(QDELETED(H) || !force_infect(H))
		to_chat(src, "<span class='warning'>[H ? H.name : "Host"] cannot be infected.</span>")

/mob/camera/disease/proc/adapt_cooldown()
	to_chat(src, "<span class='notice'>You have altered your genetic structure. You will be unable to adapt again for [DisplayTimeText(adaptation_cooldown)].</span>")
	next_adaptation_time = world.time + adaptation_cooldown
	addtimer(CALLBACK(src, PROC_REF(notify_adapt_ready)), adaptation_cooldown)

/mob/camera/disease/proc/notify_adapt_ready()
	to_chat(src, "<span class='notice'>You are now ready to adapt again.</span>")
	refresh_adaptation_menu()

/mob/camera/disease/proc/refresh_adaptation_menu()
	SStgui.update_uis(src)

/mob/camera/disease/proc/adaptation_menu()
	ui_interact(src)


/datum/action/innate/disease_adapt
	name = "Меню адаптации"
	icon_icon = 'icons/mob/actions/actions_minor_antag.dmi'
	button_icon_state = "disease_menu"

/datum/action/innate/disease_adapt/Activate()
	var/mob/camera/disease/D = owner
	D.adaptation_menu()
