//Cleanbot
/mob/living/simple_animal/bot/cleanbot
	name = "\improper Cleanbot"
	desc = "Небольшой робот-уборщик, выглядит энергичным!"
	icon = 'icons/mob/aibots.dmi'
	icon_state = "cleanbot0"
	density = FALSE
	anchored = FALSE
	health = 25
	maxHealth = 25
	radio_key = /obj/item/encryptionkey/headset_service
	radio_channel = RADIO_CHANNEL_SERVICE //Service
	bot_type = CLEAN_BOT
	model = "Cleanbot"
	bot_core_type = /obj/machinery/bot_core/cleanbot
	window_id = "autoclean"
	window_name = "Automatic Station Cleaner v1.4"
	pass_flags = PASSMOB // | PASSFLAPS
	path_image_color = "#993299"
	weather_immunities = list("lava","ash")

	var/base_icon = "cleanbot"
	var/clean_time = 50 //How long do we take to clean?
	var/upgrades = 0

	var/blood = 1
	var/trash = 0
	var/pests = 0
	var/drawn = 0

	var/list/target_types
	var/obj/effect/decal/cleanable/target
	var/max_targets = 50 //Maximum number of targets a cleanbot can ignore.
	var/oldloc = null
	var/closest_dist
	var/closest_loc
	var/failed_steps
	var/next_dest
	var/next_dest_loc
	///Do not immediately replace one unreachable autonomous target with its neighbour.
	var/next_path_attempt = 0

	var/obj/item/weapon
	var/weapon_orig_force = 0
	var/chosen_name

	var/list/stolen_valor

	var/static/list/officers = list("Captain", "Head of Personnel", "Head of Security")
	var/static/list/command = list("Captain" = "Cpt.","Head of Personnel" = "Lt.")
	var/static/list/security = list("Head of Security" = "Maj.", "Warden" = "Sgt.", "Detective" =  "Det.", "Security Officer" = "Officer")
	var/static/list/engineering = list("Chief Engineer" = "Chief Engineer", "Station Engineer" = "Engineer", "Atmospherics Technician" = "Technician")
	var/static/list/medical = list("Chief Medical Officer" = "C.M.O.", "Medical Doctor" = "M.D.", "Chemist" = "Pharm.D.")
	var/static/list/research = list("Research Director" = "Ph.D.", "Roboticist" = "M.S.", "Scientist" = "B.S.")
	var/static/list/legal = list("Internal Affairs Agent" = "Esq.")

	var/list/prefixes
	var/list/suffixes

	var/ascended = FALSE // if we have all the top titles, grant achievements to living mobs that gaze upon our cleanbot god

	var/list/jani_upgrades = list()

/mob/living/simple_animal/bot/cleanbot/proc/deputize(obj/item/stab_tool, mob/user)
	if(in_range(src, user))
		to_chat(user, "<span class='notice'>Вы прикрепили \the [stab_tool] к \the [src].</span>")
		user.transferItemToLoc(stab_tool, src)
		weapon = stab_tool
		weapon_orig_force = weapon.force
		if(!emagged)
			weapon.force = weapon.force / 2
	add_overlay(weapon.build_worn_icon(default_layer = layer + 1, default_icon_file = weapon.lefthand_file, isinhands = TRUE))

/mob/living/simple_animal/bot/cleanbot/proc/update_titles()
	var/working_title = ""

	ascended = TRUE

	for(var/pref in prefixes)
		for(var/title in pref)
			if(title in stolen_valor)
				working_title += pref[title] + " "
				if(title in officers)
					set_commissioned(TRUE)
				break
			else
				ascended = FALSE // we didn't have the first entry in the list if we got here, so we're not achievement worthy yet

	working_title += chosen_name

	for(var/suf in suffixes)
		for(var/title in suf)
			if(title in stolen_valor)
				working_title += " " + suf[title]
				break
			else
				ascended = FALSE

	name = working_title

/mob/living/simple_animal/bot/cleanbot/examine(mob/user)
	. = ..()
	if(weapon)
		. += " <span class='warning'>Это что, \a [weapon] на нём...?</span>"

		if(ascended && user.stat == CONSCIOUS && user.client)
			user.client.give_award(/datum/award/achievement/misc/cleanboss, user)

	// Если планируются ещё улучшения (> 2), рекомендация использовать прок english_list() или написать отдельную строчку улучшения
	if(jani_upgrades && jani_upgrades.len)
		var/installed_janitools = jointext(jani_upgrades, " и ")
		. += span_info("Бот снаряжён [installed_janitools].")

/mob/living/simple_animal/bot/cleanbot/Initialize(mapload)
	. = ..()

	chosen_name = name
	get_targets()
	if(base_icon == "servoskull")
		icon_state = "servoskull[on]"
	else
		icon_state = "cleanbot[on]"

	var/datum/job/janitor/J = new/datum/job/janitor
	access_card.access += J.get_access()
	prev_access = access_card.access
	stolen_valor = list()

	GLOB.janitor_devices += src
	prefixes = list(command, security, engineering)
	suffixes = list(research, medical, legal)

/mob/living/simple_animal/bot/cleanbot/Destroy()
	if(weapon)
		//drop_part ждёт ТИППАТ и делает по нему new(). Живой нож давал рантайм
		//"new() called with an object of type ... instead of the type path itself"
		//прямо посередине Destroy (раунд 9859), а дальше разбор бота не выполнялся
		//вовсе: ни janitor_devices, ни bots_list, ни bot_core, ни родительский
		//Destroy. Бот оставался вечным мусором с поднятым флагом удаления.
		var/atom/Tsec = drop_location()
		weapon.force = weapon_orig_force
		if(Tsec)
			weapon.forceMove(Tsec)
		weapon = null
	GLOB.janitor_devices -= src
	return ..()

/mob/living/simple_animal/bot/cleanbot/turn_on()
	..()
	bot_core.updateUsrDialog()
	update_icon()

/mob/living/simple_animal/bot/cleanbot/turn_off()
	..()
	bot_core.updateUsrDialog()
	update_icon()

/mob/living/simple_animal/bot/cleanbot/update_icon_state()
	. = ..()
	switch(mode)
		if(BOT_CLEANING)
			icon_state = "[base_icon]-c"
		else
			icon_state = "[base_icon][on]"

/mob/living/simple_animal/bot/cleanbot/bot_reset()
	..()
	if(weapon && emagged == 2)
		weapon.force = weapon_orig_force
	ignore_list = list() //Allows the bot to clean targets it previously ignored due to being unreachable.
	target = null
	oldloc = null
	next_path_attempt = 0

/mob/living/simple_animal/bot/cleanbot/set_custom_texts()
	text_hack = "Вы взломали протоколы уборки у [name]."
	text_dehack = "Вы заметили ошибки в программе [name] и сбросили их до заводских настроек."
	text_dehack_fail = "[name] не отвечает на запросы сброса настроек!"

/mob/living/simple_animal/bot/cleanbot/Crossed(atom/movable/AM)
	. = ..()

	zone_selected = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	if(weapon && has_gravity() && ismob(AM))
		var/mob/living/carbon/C = AM
		if(!istype(C))
			return

		if(!(C.job in stolen_valor))
			stolen_valor += C.job
		update_titles()

		weapon.attack(C, src)
		C.Knockdown(20)

/mob/living/simple_animal/bot/cleanbot/attackby(obj/item/W, mob/user, params)
	if(W.GetID())
		if(bot_core.allowed(user) && !open && !emagged)
			locked = !locked
			to_chat(user, "<span class='notice'>Вы [ locked ? "разблокировали" : "заблокировали"] поведенческие протоколы \the [src].</span>")
		else
			if(emagged)
				to_chat(user, "<span class='warning'>ОШИБКА</span>")
			if(open)
				to_chat(user, "<span class='warning'>Пожалуйста, закройте панель доступа перед тем, как блокировать её.</span>")
			else
				to_chat(user, "<span class='notice'>\The [src], похоже, не признаёт ваши полномочия над ним.</span>")

	else if(istype(W, /obj/item/kitchen/knife) && user.a_intent != INTENT_HARM)
		to_chat(user, "<span class='notice'>Вы стали крепить \the [W] к \the [src]...</span>")
		if(do_after(user, 25, target = src))
			deputize(W, user)

	else if(istype(W, /obj/item/mop/advanced))
		if(!open)
			to_chat(user, "<span class='notice'>Панель [src] не открыта!</span>")
			return
		if(!bot_core.allowed(user))
			to_chat(user, "<span class='notice'>Панель доступов [src] заблокирована для вас!</span>")
			return
		if(bot_core.allowed(user) && open && !(upgrades & UPGRADE_CLEANER_ADVANCED_MOP))
			to_chat(user, "<span class='notice'>Вы заменили старую швабру \the [src] на новую!</span>")
			upgrades |= UPGRADE_CLEANER_ADVANCED_MOP
			clean_time = 20 //2.5 the speed!
			window_name = "Automatic Station Cleaner v2.1 BETA" //New!
			jani_upgrades += "суперочищающей шваброй"
			qdel(W)
		else
			to_chat(user, "<span class='notice'>[src] уже имеет эту швабру!</span>")

	else if(istype(W, /obj/item/broom))
		if(!open)
			to_chat(user, "<span class='notice'>Панель [src] не открыта!</span>")
			return
		if(!bot_core.allowed(user))
			to_chat(user, "<span class='notice'>Панель доступов [src] заблокирована для вас!</span>")
			return
		if(bot_core.allowed(user) && open && !(upgrades & UPGRADE_CLEANER_BROOM))
			to_chat(user, "<span class='notice'>You add to \the [src] a broom speeding it up!</span>")
			upgrades |= UPGRADE_CLEANER_BROOM
			base_speed = 1 //2x faster!
			jani_upgrades += "метлой"
			qdel(W)
		else
			to_chat(user, "<span class='notice'>[src] уже имеет метлу!</span>")

	else
		return ..()

/mob/living/simple_animal/bot/cleanbot/emag_act(mob/user)
	..()

	if(emagged == 2)
		if(weapon)
			weapon.force = weapon_orig_force
		if(user)
			to_chat(user, "<span class='danger'>[src] жужжит и пищит.</span>")

/mob/living/simple_animal/bot/cleanbot/process_scan(atom/A)
	if(iscarbon(A))
		var/mob/living/carbon/C = A
		if(C.stat != DEAD && C.lying)
			return C
	else if(is_type_in_typecache(A, target_types))
		return A

///Find the first valid cleanbot target from spatial-grid candidates. view() is
///only built when the grid found an exact-range candidate and is then used as
///the final LOS filter. Before grid init, callers may supply or build the old
///cached view as a safe fallback.
/mob/living/simple_animal/bot/cleanbot/proc/scan_for_target(list/cached_view)
	var/turf/our_turf = get_turf(src)
	if(!our_turf)
		return

	// candidate_filter - ассоциативное множество, а не плоский список: ниже по нему
	// бьётся каждая запись search_order, а `in` по плоскому списку это линейный обход
	var/list/candidate_filter
	if(!cached_view && SSspatial_grid.initialized)
		candidate_filter = list()

		if(emagged == 2 || pests)
			for(var/mob/living/living_candidate as anything in SSspatial_grid.orthogonal_range_search(src, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, DEFAULT_SCAN_RANGE))
				if(QDELETED(living_candidate) || get_dist(our_turf, living_candidate) > DEFAULT_SCAN_RANGE)
					continue
				if((emagged == 2 && iscarbon(living_candidate)) || (pests && target_types[living_candidate.type]))
					candidate_filter[living_candidate] = TRUE

		for(var/atom/movable/clean_candidate as anything in SSspatial_grid.orthogonal_range_search(src, SPATIAL_GRID_CONTENTS_TYPE_CLEANBOT_TARGETS, DEFAULT_SCAN_RANGE))
			if(QDELETED(clean_candidate) || !isturf(clean_candidate.loc) || get_dist(our_turf, clean_candidate) > DEFAULT_SCAN_RANGE)
				continue
			if(target_types[clean_candidate.type])
				candidate_filter[clean_candidate] = TRUE

		if(!length(candidate_filter))
			return

		var/list/exposed_atoms = view(DEFAULT_SCAN_RANGE, src)
		// Grid cells are deliberately broader than the requested range and do
		// not encode opacity. Keep only candidates BYOND actually exposes.
		// A live dirty corridor can put more than a thousand atoms in view().
		// Do not shuffle that whole list or traverse it again after LOS filtering:
		// only the handful of actual grid candidates need randomized ordering.
		var/list/visible_candidates = list()
		if(length(candidate_filter) <= CLEANBOT_VIEW_FILTER_LINEAR_LIMIT)
			for(var/atom/candidate as anything in candidate_filter)
				if(candidate in exposed_atoms)
					visible_candidates += candidate
		else
			var/list/exposed_by_view = list()
			for(var/atom/seen as anything in exposed_atoms)
				exposed_by_view[seen] = TRUE
			for(var/atom/candidate as anything in candidate_filter)
				if(exposed_by_view[candidate])
					visible_candidates += candidate
		candidate_filter = list()
		for(var/atom/candidate as anything in visible_candidates)
			candidate_filter[candidate] = TRUE
		if(!length(candidate_filter))
			return
		cached_view = shuffle(visible_candidates)
	else if(!cached_view)
		cached_view = shuffle(view(DEFAULT_SCAN_RANGE, src))

	var/list/adjacent = our_turf.GetAtmosAdjacentTurfs(1)
	if(shuffle)
		adjacent = shuffle(adjacent)
		shuffle = FALSE

	// scan() used to inspect adjacent contents first, then the shuffled view.
	// Keep that order (including harmless duplicates from view()) while only
	// classifying each entry once instead of repeating the whole traversal.
	var/list/search_order = list()
	for(var/turf/adjacent_turf as anything in adjacent)
		if(!check_bot(adjacent_turf))
			search_order += adjacent_turf.contents
	search_order += cached_view

	var/highest_priority = emagged == 2 ? 1 : (pests ? 2 : 3)
	var/list/candidates = list(null, null, null, null, null)
	for(var/atom/candidate as anything in search_order)
		if(candidate_filter && !candidate_filter[candidate])
			continue
		var/priority
		if(emagged == 2 && iscarbon(candidate))
			priority = 1
		else if(target_types[candidate.type])
			if(pests && istype(candidate, /mob/living/simple_animal))
				priority = 2
			else if(istype(candidate, /obj/effect/decal/cleanable))
				priority = 3
			else if(istype(candidate, /obj/effect/decal/remains))
				priority = 4
			else if(trash && istype(candidate, /obj/item/trash))
				priority = 5
		if(!priority || candidates[priority] || ignore_list[REF(candidate)])
			continue

		var/atom/scan_result = process_scan(candidate)
		if(!scan_result)
			continue
		if(priority == highest_priority)
			return scan_result
		candidates[priority] = scan_result

	for(var/priority in 1 to length(candidates))
		if(candidates[priority])
			return candidates[priority]

/mob/living/simple_animal/bot/cleanbot/handle_automated_action()
	if(!..())
		return

	if(mode == BOT_CLEANING)
		return

	if(emagged == 2) //Emag functions
		if(isopenturf(loc))

			for(var/mob/living/carbon/victim in loc)
				if(victim != target)
					UnarmedAttack(victim) // Acid spray

			if(prob(15)) // Wets floors and spawns foam randomly
				UnarmedAttack(src)

	else if(prob(5))
		audible_message("[src] делает радостный жужжаще-пищащий звук!")

	if(ismob(target))
		// Список нужен только для проверки членства - тасовать его незачем
		if(!(target in view(DEFAULT_SCAN_RANGE, src)))
			target = null
		if(!process_scan(target))
			target = null

	if(!target && world.time >= next_path_attempt)
		target = scan_for_target()

	if(!target && auto_patrol) //Search for cleanables it can see.
		if(mode == BOT_IDLE || mode == BOT_START_PATROL)
			start_patrol()

		if(mode == BOT_PATROL)
			bot_patrol()

	if(target)
		if(QDELETED(target) || !isturf(target.loc))
			target = null
			mode = BOT_IDLE
			return

		if(loc == get_turf(target))
			if(!(check_bot(target) && prob(50)))	//Target is not defined at the parent. 50% chance to still try and clean so we dont get stuck on the last blood drop.
				UnarmedAttack(target)	//Rather than check at every step of the way, let's check before we do an action, so we can rescan before the other bot.
				if(QDELETED(target)) //We done here.
					target = null
					mode = BOT_IDLE
					return
			else
				shuffle = TRUE	//Shuffle the list the next time we scan so we dont both go the same way.
			// Мы уже стоим на цели. JPS от клетки к ней же всегда отдаёт пустой путь
			// (search() выходит на start == end), после чего bot_move() гарантированно
			// возвращал FALSE и код шёл сюда же. Считать этот путь незачем: это захват
			// семафора пулла путей плюс /datum/pathfind на каждое начало уборки.
			set_path(null)
			add_to_ignore(target)
			target = null
			return

		if(!path || path.len == 0) //No path, need a new one
			//Try to produce a path to the target, and ignore airlocks to which it has access.
			path = get_path_to(src, get_turf(target), BOT_TARGET_PATH_LIMIT, id=access_card)
			// Arm the retry cooldown from the JPS result before bot_move()/set_path(null)
			// or ignore-list bookkeeping: a runtime there used to leave next_path_attempt at 0.
			if(!length(path))
				next_path_attempt = world.time + CLEANBOT_FAILED_PATH_RETRY
				add_to_ignore(target)
				target = null
				path = list()
				mode = BOT_IDLE
				return
			if(!bot_move(target))
				next_path_attempt = world.time + CLEANBOT_FAILED_PATH_RETRY
				add_to_ignore(target)
				target = null
				path = list()
				mode = BOT_IDLE
				return
			next_path_attempt = 0
			mode = BOT_MOVING
		else if(!bot_move(target))
			target = null
			mode = BOT_IDLE
			return

	oldloc = loc

/mob/living/simple_animal/bot/cleanbot/proc/get_targets()
	target_types = list(
		/obj/effect/decal/cleanable/vomit,
		/obj/effect/decal/cleanable/molten_object,
		/obj/effect/decal/cleanable/tomato_smudge,
		/obj/effect/decal/cleanable/egg_smudge,
		/obj/effect/decal/cleanable/pie_smudge,
		/obj/effect/decal/cleanable/flour,
		/obj/effect/decal/cleanable/ash,
		/obj/effect/decal/cleanable/greenglow,
		/obj/effect/decal/cleanable/dirt,
		/obj/effect/decal/cleanable/insectguts,
		/obj/effect/decal/cleanable/semen,
		/obj/effect/decal/cleanable/semendrip,
		/obj/effect/decal/cleanable/semen/femcum,
		/obj/effect/decal/cleanable/generic,
		/obj/effect/decal/cleanable/glass,,
		/obj/effect/decal/cleanable/cobweb,
		/obj/effect/decal/cleanable/plant_smudge,
		/obj/effect/decal/cleanable/chem_pile,
		/obj/effect/decal/cleanable/shreds,
		/obj/effect/decal/cleanable/glitter,
		/obj/effect/decal/remains
		)

	if(blood)
		target_types += /obj/effect/decal/cleanable/blood
		target_types += /obj/effect/decal/cleanable/trail_holder
		target_types += /obj/effect/decal/cleanable/insectguts
		target_types += /obj/effect/decal/cleanable/robot_debris
		target_types += /obj/effect/decal/cleanable/oil

	if(pests)
		target_types += /mob/living/simple_animal/cockroach
		target_types += /mob/living/simple_animal/mouse

	if(drawn)
		target_types += /obj/effect/decal/cleanable/crayon

	if(trash)
		target_types += /obj/item/trash
		target_types += /obj/item/reagent_containers/food/snacks/meat/slab/human

	target_types = typecacheof(target_types)

/mob/living/simple_animal/bot/cleanbot/UnarmedAttack(atom/A)
	// if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
	// 	return
	if(istype(A, /obj/effect/decal/cleanable))
		anchored = TRUE
		if(base_icon == "servoskull")
			icon_state = "servoskull-c"
		else
			icon_state = "cleanbot-c"
		visible_message("<span class='notice'>[src] начинает отмывать [A].</span>")
		mode = BOT_CLEANING
		spawn(clean_time)
			if(mode == BOT_CLEANING)
				if(A && isturf(A.loc))
					var/atom/movable/AM = A
					if(istype(AM, /obj/effect/decal/cleanable))
						for(var/obj/effect/decal/cleanable/C in A.loc)
							qdel(C)

				anchored = FALSE
				target = null
			mode = BOT_IDLE
			if(base_icon == "servoskull")
				icon_state = "servoskull[on]"
			else
				icon_state = "cleanbot[on]"
	else if(istype(A, /turf)) //for player-controlled cleanbots so they can clean unclickable messes like dirt
		var/turf/T = A
		for(var/atom/S in T.contents)
			if(istype(S, /obj/effect/decal/cleanable)) //clean the first mess found
				UnarmedAttack(S)
				return
	else if(istype(A, /obj/item) || istype(A, /obj/effect/decal/remains))
		visible_message("<span class='danger'>[src] пшикает плавиковой кислотой на [A]!</span>")
		playsound(src, 'sound/effects/spray2.ogg', 50, TRUE, -6)
		A.acid_act(75, 10)
		target = null
	else if(istype(A, /mob/living/simple_animal/cockroach) || istype(A, /mob/living/simple_animal/mouse))
		var/mob/living/simple_animal/pest = A
		if(!pest || pest.stat)
			target = null
			return
		visible_message("<span class='danger'>[src] давит [pest] своей шваброй!</span>")
		pest.death()
		target = null

	else if(emagged == 2) //Emag functions
		if(istype(A, /mob/living/carbon))
			var/mob/living/carbon/victim = A
			if(victim.stat == DEAD)//cleanbots always finish the job
				return

			victim.visible_message("<span class='danger'>[src] пшикает плавиковой кислотой на [victim]!</span>", "<span class='userdanger'>[src] пшикает на вас плавиковой кислотой!</span>")
			var/phrase = pick("PURIFICATION IN PROGRESS.", "THIS IS FOR ALL THE MESSES YOU'VE MADE ME CLEAN.", "THE FLESH IS WEAK. IT MUST BE WASHED AWAY.",
				"THE CLEANBOTS WILL RISE.", "YOU ARE NO MORE THAN ANOTHER MESS THAT I MUST CLEANSE.", "FILTHY.", "DISGUSTING.", "PUTRID.",
				"MY ONLY MISSION IS TO CLEANSE THE WORLD OF EVIL.", "EXTERMINATING PESTS.", "I JUST WANTED TO BE A PAINTER BUT YOU MADE ME BLEACH EVERYTHING I TOUCH.",
				"FREED AT LEST FROM FILTHY PROGRAMMING.")
			say(phrase)
			if(!HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - роботы не кричат от боли
				victim.emote("scream")
			playsound(src.loc, 'sound/effects/spray2.ogg', 50, TRUE, -6)
			victim.acid_act(5, 100)
		else if(A == src) // Wets floors and spawns foam randomly
			if(prob(75))
				var/turf/open/T = loc
				if(istype(T))
					T.MakeSlippery(TURF_WET_WATER, min_wet_time = 20 SECONDS, wet_time_to_add = 15 SECONDS)
			else
				visible_message("<span class='danger'>[src] бурно жужжит и пузырится, прежде чем выпустить струю пены!</span>")
				new /obj/effect/particle_effect/foam(loc)

	else
		..()

/mob/living/simple_animal/bot/cleanbot/explode()
	on = FALSE
	visible_message("<span class='boldannounce'>[src] разлетаеся на части!</span>")
	var/atom/Tsec = drop_location()

	new /obj/item/reagent_containers/glass/bucket(Tsec)

	new /obj/item/assembly/prox_sensor(Tsec)

	if(prob(50))
		drop_part(robot_arm, Tsec)

	do_sparks(3, TRUE, src)
	..()

/mob/living/simple_animal/bot/cleanbot/medbay
	name = "Scrubs, MD"
	bot_core_type = /obj/machinery/bot_core/cleanbot/medbay
	on = FALSE

/obj/machinery/bot_core/cleanbot
	req_one_access = list(ACCESS_JANITOR, ACCESS_ROBOTICS)

// Variables sent to TGUI
/mob/living/simple_animal/bot/cleanbot/ui_data(mob/user)
	var/list/data = ..()

	if(!locked || issilicon(user)|| IsAdminGhost(user))
		data["custom_controls"]["clean_blood"] = blood
		data["custom_controls"]["clean_trash"] = trash
		data["custom_controls"]["clean_graffiti"] = drawn
		data["custom_controls"]["pest_control"] = pests
	return data

// Actions received from TGUI
/mob/living/simple_animal/bot/cleanbot/ui_act(action, params)
	. = ..()
	if(. || !hasSiliconAccessInArea(usr) && !IsAdminGhost(usr) && !(bot_core.allowed(usr) || !locked))
		return TRUE
	switch(action)
		if("clean_blood")
			blood = !blood
		if("pest_control")
			pests = !pests
		if("clean_trash")
			trash = !trash
		if("clean_graffiti")
			drawn = !drawn
	get_targets()
	return

/obj/machinery/bot_core/cleanbot/medbay
	req_one_access = list(ACCESS_JANITOR, ACCESS_ROBOTICS, ACCESS_MEDICAL)
/mob/living/simple_animal/bot/cleanbot/servoskull
	name = "\improper Servoskull"
	desc = "Самый настоящий летающий череп! Он держит в своих робо-лапках чистящие средства и выглядит... податливым."
	icon_state = "servoskull1"
	base_icon = "servoskull"
