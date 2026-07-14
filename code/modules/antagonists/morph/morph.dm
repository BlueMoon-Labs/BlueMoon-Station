#define MORPH_COOLDOWN 50

/mob/living/simple_animal/hostile/morph
	name = "morph"
	real_name = "morph"
	desc = "A revolting, pulsating pile of flesh."
	speak_emote = list("gurgles")
	emote_hear = list("gurgles")
	icon = 'icons/mob/animal.dmi'
	icon_state = "morph"
	icon_living = "morph"
	icon_dead = "morph_dead"
	speed = 2
	a_intent = INTENT_HARM
	stop_automated_movement = 1
	status_flags = CANPUSH
	pass_flags = PASSTABLE
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxHealth = 500
	health = 500
	healable = 0
	obj_damage = 50
	melee_damage_lower = 20
	melee_damage_upper = 20
	var/eaten_count = 0
	see_in_dark = 8
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	vision_range = 1 // Only attack when target is close
	wander = FALSE
	attack_verb_continuous = "glomps"
	attack_verb_simple = "glomp"
	attack_sound = 'sound/effects/blobattack.ogg'
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 2)

	var/morphed = FALSE
	var/melee_damage_disguised = 0
	var/eat_while_disguised = FALSE
	var/atom/movable/form = null
	var/morph_time = 0
	var/static/list/blacklist_typecache = typecacheof(list(
	/atom/movable/screen,
	/mob/living/simple_animal/hostile/morph,
	/obj/effect,
	/mob/camera
	))

	var/playstyle_string = "<span class='big bold'>You are a morph,</span></b> an abomination of science created primarily with changeling cells. \
							You may take the form of anything nearby by shift-clicking it. This process will alert any nearby \
							observers, and can only be performed once every five seconds. While morphed, you move faster, but do \
							less damage. In addition, anyone within three tiles will note an uncanny wrongness if examining you. \
							You can attack any item or dead creature to consume it - creatures will fully restore your health. \
							Swallowed <b>items</b> (not living prey) can be brought back up from the toolbar action <b>Сплюнуть предмет</b>. \
							Finally, you can restore yourself to your original form while morphed by shift-clicking yourself.</b>"

/mob/living/simple_animal/hostile/morph/Initialize(mapload)
	. = ..()
	src.AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)
	var/datum/action/morph_swallow_inventory/spitter = new(src)
	spitter.Grant(src)

/mob/living/simple_animal/hostile/morph/examine(mob/user)
	if(morphed)
		. = form.examine(user)
		if(get_dist(user,src)<=3)
			. += "<span class='warning'>Выглядит как-то неправильно...</span>"
	else
		. = ..()

/mob/living/simple_animal/hostile/morph/med_hud_set_health()
	if(morphed && !isliving(form))
		var/image/holder = hud_list[HEALTH_HUD]
		holder.icon_state = null
		return //we hide medical hud while morphed
	..()

/mob/living/simple_animal/hostile/morph/med_hud_set_status()
	if(morphed && !isliving(form))
		var/image/holder = hud_list[STATUS_HUD]
		holder.icon_state = null
		return //we hide medical hud while morphed
	..()

/mob/living/simple_animal/hostile/morph/proc/allowed(atom/movable/A) // make it into property/proc ? not sure if worth it
	return !is_type_in_typecache(A, blacklist_typecache) && (isobj(A) || ismob(A))

/// How much swallowed matter boosts stats / heals for one eat (mirror in regurgitate)
/mob/living/simple_animal/hostile/morph/proc/swallow_bonus_for(atom/movable/A)
	var/bonus = 1
	if(istype(A, /mob/living/carbon))
		bonus = 10
	return bonus

/mob/living/simple_animal/hostile/morph/proc/eat(atom/movable/A)
	if(morphed && !eat_while_disguised)
		to_chat(src, "<span class='warning'>You can not eat anything while you are disguised!</span>")
		return FALSE
	if(A && A.loc != src)
		visible_message("<span class='warning'>[src] swallows [A] whole!</span>")
		A.forceMove(src)
		var/eat_bonus = swallow_bonus_for(A)
		eaten_count += eat_bonus
		melee_damage_lower += 0.1 * eat_bonus
		melee_damage_upper += 0.1 * eat_bonus
		maxHealth += eat_bonus
		adjustHealth(-eat_bonus)
		// With autoupdate off, datum/ui_update() does nothing useful; refresh open stomach UIs now.
		SStgui.update_uis(src)
		return TRUE
	return FALSE

/// Matches combat / health scaling from swallowed matter when eaten_count changes.
/mob/living/simple_animal/hostile/morph/proc/recalc_swallow_derived_stats()
	maxHealth = initial(maxHealth) + eaten_count
	health = min(health, maxHealth)
	if(!morphed)
		melee_damage_lower = initial(melee_damage_lower) + eaten_count * 0.1
		melee_damage_upper = initial(melee_damage_upper) + eaten_count * 0.1
	med_hud_set_health()

/// Returns one swallowed item matching display name at a time for the vending UI logic.
/mob/living/simple_animal/hostile/morph/proc/regurgitate_item_by_name(atom/destination, desired_name)
	if(!desired_name || stat == DEAD)
		return FALSE
	for(var/obj/item/I in contents)
		if(I.name == desired_name)
			var/expel_bonus = swallow_bonus_for(I)
			I.forceMove(destination)
			if(isliving(src) && stat != DEAD && prob(40))
				step(I, pick(GLOB.cardinals))
			to_chat(src, "<span class='notice'>You expel [I]!</span>")
			visible_message("<span class='warning'>[src] disgorges [I]!</span>", ignored_mobs = list(src))
			log_game("[key_name(src)] морф выплюнул [I] ([I.type]).")
			eaten_count = max(eaten_count - expel_bonus, 0)
			recalc_swallow_derived_stats()
			adjustHealth(expel_bonus)
			return TRUE
	return FALSE

/mob/living/simple_animal/hostile/morph/ui_state(mob/user)
	return GLOB.self_state

/mob/living/simple_animal/hostile/morph/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SmartVend", "Желудок морфа")
		ui.set_autoupdate(FALSE)
		ui.open()

/mob/living/simple_animal/hostile/morph/ui_data(mob/user)
	. = list()
	var/list/listofitems = list()
	for(var/obj/item/O in contents)
		if(QDELETED(O))
			continue
		var/md5name = md5(O.name)
		if(listofitems[md5name])
			listofitems[md5name]["amount"]++
		else
			listofitems[md5name] = list(
				"name" = O.name,
				"type" = "[O.type]",
				"amount" = 1
			)
	sort_list(listofitems)
	.["contents"] = listofitems
	.["name"] = "[name]"
	.["verb"] = "Выплюнуть"
	.["searchable"] = TRUE
	.["isdryer"] = FALSE

/mob/living/simple_animal/hostile/morph/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("Release")
			if(src != usr)
				return
			var/turf/dropspot = drop_location()
			if(!dropspot || QDELETED(usr))
				return

			var/desired = params["amount"] ? floor(text2num(params["amount"])) : null

			if(isnull(desired))
				desired = input(usr, "Сколько одноимённых предметов выплюнуть?", "Желудок морфа", 1) as num|null

			if(isnull(desired))
				return TRUE

			desired = floor(desired)
			if(desired < 1)
				return TRUE

			var/param_name = params["name"]

			while(desired > 0)
				if(QDELETED(src) || stat == DEAD)
					break
				if(!regurgitate_item_by_name(dropspot, param_name))
					break
				desired--
			return TRUE
	return FALSE

/// Opens searchable list of swallowed /obj/item (living prey must still come out via death/other means).
/datum/action/morph_swallow_inventory
	name = "Сплюнуть предмет"
	desc = "Список поглощённых предметов с поиском. Сплюнуть предмет под вас на пол."
	icon_icon = 'icons/mob/animal.dmi'
	button_icon_state = "morph"
	check_flags = AB_CHECK_ALIVE | AB_CHECK_CONSCIOUS

/datum/action/morph_swallow_inventory/Trigger()
	if(!..())
		return FALSE
	var/mob/living/simple_animal/hostile/morph/body = owner
	if(!istype(body))
		return FALSE
	body.ui_interact(owner)
	return TRUE

/mob/living/simple_animal/hostile/morph/ShiftClickOn(atom/movable/A)
	if(morph_time <= world.time && !stat)
		if(A == src)
			restore()
			return
		if(istype(A) && allowed(A))
			assume(A)
	else
		to_chat(src, "<span class='warning'>Your chameleon skin is still repairing itself!</span>")
		..()

/mob/living/simple_animal/hostile/morph/proc/assume(atom/movable/target)
	if(morphed)
		to_chat(src, "<span class='warning'>You must restore to your original form first!</span>")
		return
	morphed = TRUE
	form = target

	visible_message("<span class='warning'>[src] suddenly twists and changes shape, becoming a copy of [target]!</span>", \
					"<span class='notice'>You twist your body and assume the form of [target].</span>")
	appearance = target.appearance
	copy_overlays(target)
	alpha = max(alpha, 150)	//fucking chameleons
	transform = initial(transform)
	pixel_y = initial(pixel_y)
	pixel_x = initial(pixel_x)

	//Morphed is weaker
	melee_damage_lower = melee_damage_disguised
	melee_damage_upper = melee_damage_disguised
	speed = 0

	morph_time = world.time + MORPH_COOLDOWN
	med_hud_set_health()
	med_hud_set_status() //we're an object honest
	return

/mob/living/simple_animal/hostile/morph/proc/restore()
	if(!morphed)
		to_chat(src, "<span class='warning'>You're already in your normal form!</span>")
		return
	morphed = FALSE
	form = null
	alpha = initial(alpha)
	color = initial(color)
	maptext = null

	visible_message("<span class='warning'>[src] suddenly collapses in on itself, dissolving into a pile of green flesh!</span>", \
					"<span class='notice'>You reform to your normal body.</span>")
	name = initial(name)
	icon = initial(icon)
	icon_state = initial(icon_state)
	cut_overlays()

	melee_damage_lower = initial(melee_damage_lower) + eaten_count * 0.1
	melee_damage_upper = initial(melee_damage_upper) + eaten_count * 0.1
	maxHealth = initial(maxHealth) + eaten_count
	health = min(health, maxHealth)
	speed = initial(speed)

	morph_time = world.time + MORPH_COOLDOWN
	med_hud_set_health()
	med_hud_set_status() //we are not an object

/mob/living/simple_animal/hostile/morph/death(gibbed)
	if(morphed)
		visible_message("<span class='warning'>[src] twists and dissolves into a pile of green flesh!</span>", \
						"<span class='userdanger'>Your skin ruptures! Your flesh breaks apart! No disguise can ward off de--</span>")
		restore()
	barf_contents()
	..()

/mob/living/simple_animal/hostile/morph/proc/barf_contents()
	for(var/atom/movable/AM in src)
		AM.forceMove(loc)
		if(prob(90))
			step(AM, pick(GLOB.alldirs))

/mob/living/simple_animal/hostile/morph/wabbajack_act(mob/living/new_mob)
	barf_contents()
	. = ..()

/mob/living/simple_animal/hostile/morph/Aggro() // automated only
	..()
	restore()

/mob/living/simple_animal/hostile/morph/LoseAggro()
	vision_range = initial(vision_range)

/mob/living/simple_animal/hostile/morph/AIShouldSleep(var/list/possible_targets)
	. = ..()
	if(.)
		var/list/things = list()
		for(var/atom/movable/A in view(src))
			if(allowed(A))
				things += A
		if(things)
			var/atom/movable/T = pick(things)
			assume(T)

/mob/living/simple_animal/hostile/morph/can_track(mob/living/user)
	if(morphed)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/morph/AttackingTarget() /// Blumoon_change
	if(morphed && !melee_damage_disguised && !/mob/living/simple_animal/hostile/morph/sandman)
		to_chat(src, "<span class='warning'>You can not attack while disguised!</span>")
		return
	if(isliving(target)) //Eat Corpses to regen health
		var/mob/living/L = target
		if(L.stat == DEAD)
			if(do_after(src, 30, target = L))
				if(eat(L))
					adjustHealth(-50)
			return
	else if(isitem(target)) //Eat items just to be annoying
		var/obj/item/I = target
		if(!I.anchored)
			if(do_after(src, 20, target = I))
				eat(I)
			return
	else if(istype(target, /obj/machinery/ore_silo))
		to_chat(src, "<span class='warning'>You cannot damage the ore silo!</span>")
		return
	return ..()

//Spawn Event

/datum/round_event_control/morph
	name = "Spawn Morph"
	typepath = /datum/round_event/ghost_role/morph
	weight = 8
	max_occurrences = 1
	min_players = 20
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_GHOST // форс-запуск обязан считаться антаг-нагрузкой
	cost = 10
	intensity = 15
	director_ghost_jobban = ROLE_ALIEN
	director_ghost_preference = ROLE_ALIEN
	family = "morph" // с рулсетом-двойником динамика: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_TEAMBASED)
	description = "Spawns a hungry shapeshifting blobby creature."

/datum/round_event_control/morph/director_preflight()
	if(!length(GLOB.xeno_spawn))
		director_preflight_failure = "на карте нет точек xeno_spawn для морфа"
		return FALSE
	return ..()

/datum/round_event/ghost_role/morph
	minimum_required = 1
	role_name = "morphling"

/datum/round_event/ghost_role/morph/spawn_role()
	var/list/candidates = get_candidates(ROLE_ALIEN, null, ROLE_ALIEN)
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected = pick_n_take(candidates)

	var/datum/mind/player_mind = new /datum/mind(selected.key)
	player_mind.active = 1
	if(!GLOB.xeno_spawn)
		return MAP_ERROR
	var/mob/living/simple_animal/hostile/morph/S = new /mob/living/simple_animal/hostile/morph(pick(GLOB.xeno_spawn))
	player_mind.transfer_to(S)
	player_mind.assigned_role = "Morph"
	player_mind.special_role = "Morph"
	player_mind.add_antag_datum(/datum/antagonist/morph)
	to_chat(S, S.playstyle_string)
	SEND_SOUND(S, sound('sound/magic/mutate.ogg'))
	message_admins("[ADMIN_LOOKUPFLW(S)] has been made into a morph by an event.")
	log_game("[key_name(S)] was spawned as a morph by an event.")
	spawned_mobs += S
	return SUCCESSFUL_SPAWN
