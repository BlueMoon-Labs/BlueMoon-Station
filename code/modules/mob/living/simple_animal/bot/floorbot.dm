//Floorbot
/mob/living/simple_animal/bot/floorbot
	name = "\improper Floorbot"
	desc = "Небольшой робот, чинящий полы, в очень хорошем настроении!"
	icon = 'icons/mob/aibots.dmi'
	icon_state = "floorbot_base"
	density = FALSE
	anchored = FALSE
	health = 25
	maxHealth = 25
	spacewalk = TRUE

	radio_key = /obj/item/encryptionkey/headset_eng
	radio_channel = RADIO_CHANNEL_ENGINEERING
	bot_type = FLOOR_BOT
	model = "Floorbot"
	bot_core = /obj/machinery/bot_core/floorbot
	window_id = "autofloor"
	window_name = "Automatic Station Floor Repairer v1.1"
	path_image_color = "#FFA500"

	var/process_type //Determines what to do when process_scan() receives a target. See process_scan() for details.
	var/targetdirection
	var/replacetiles = 0
	var/placetiles = 0
	var/specialtiles = 0
	var/maxtiles = 100
	var/obj/item/stack/tile/tiletype
	var/fixfloors = 0
	var/autotile = 0
	var/max_targets = 50
	var/turf/target
	var/oldloc = null
	var/box_latches = "single_latch"

	var/toolbox = /obj/item/storage/toolbox/mechanical
	/// Цвет тулбокса для более явного хранения после инициализации
	var/base_color = "#068bec"

	var/upgrades = 0
	overlay_system = TRUE

	var/list/toolbox_upg = list()

	// Дробление на анимации в оверлеях плитки на спрайте
	var/mutable_appearance/tile_overlay
	var/mutable_appearance/box_overlay
	var/mutable_appearance/arms_overlay
	var/mutable_appearance/sensor_overlay
	var/mutable_appearance/upgrade_overlay
	var/mutable_appearance/latches_overlay

	#define HULL_BREACH			1
	#define LINE_SPACE_MODE		2
	#define FIX_TILE			3
	#define AUTO_TILE			4
	#define PLACE_TILE			5
	#define REPLACE_TILE		6
	#define TILE_EMAG			7

/mob/living/simple_animal/bot/floorbot/Initialize(mapload, received_toolbox_type, received_base_color, received_latches)
	. = ..()
	if(received_toolbox_type)
		toolbox = received_toolbox_type
	if(received_base_color)
		base_color = received_base_color
	if(received_latches)
		box_latches = received_latches
	determine_overlays()
	update_icon()

	var/datum/job/engineer/J = new/datum/job/engineer
	access_card.access += J.get_access()
	prev_access = access_card.access

/**
  * Присваивание флурботу оверлеев и их layer значения
  */
/mob/living/simple_animal/bot/floorbot/proc/determine_overlays()
	box_overlay = mutable_appearance(icon, "floorbot_box", FLOAT_LAYER)
	latches_overlay = mutable_appearance(icon, box_latches, FLOAT_LAYER + 0.01)
	tile_overlay = mutable_appearance(icon, "floorbot-tiles", FLOAT_LAYER + 0.01)
	arms_overlay = mutable_appearance(icon, "floorbot_arms", FLOAT_LAYER + 0.02)
	sensor_overlay = mutable_appearance(icon, "floorbot_sensor-1", FLOAT_LAYER + 0.03)

	determine_color()

	add_overlay(box_overlay)
	add_overlay(latches_overlay)
	add_overlay(tile_overlay)
	add_overlay(arms_overlay)
	add_overlay(sensor_overlay)

/**
  * Первичное определение цвета тулбокса на флурботе
  */
/mob/living/simple_animal/bot/floorbot/proc/determine_color()
	switch(base_color)
		if("red")
			box_overlay.color = "#b31004"
		if("yellow")
			box_overlay.color = "#ebb404"
		if("blue")
			box_overlay.color = "#068bec"
		else
			box_overlay.color = base_color

/**
  * Добавление флурботу оверлея скина
  */
/mob/living/simple_animal/bot/floorbot/proc/determine_skin(skin_name)
	if(!skin_name)
		return

	upgrade_overlay = mutable_appearance(icon, skin_name)
	upgrade_overlay.layer = FLOAT_LAYER
	upgrade_overlay.dir = dir
	add_overlay(upgrade_overlay)

/mob/living/simple_animal/bot/floorbot/turn_on()
	. = ..()
	update_icon()

/mob/living/simple_animal/bot/floorbot/turn_off()
	..()
	update_icon()

/mob/living/simple_animal/bot/floorbot/bot_reset()
	..()
	target = null
	oldloc = null
	ignore_list = list()
	anchored = FALSE
	update_icon()

/mob/living/simple_animal/bot/floorbot/examine(mob/user)
	. = ..()
	// Если планируются ещё улучшения (> 2), рекомендация использовать прок english_list() или написать отдельную строчку улучшения
	if(toolbox_upg && toolbox_upg.len)
		var/installed_toolboxes = jointext(toolbox_upg, " и ")
		. += span_info("Бот оболочен [installed_toolboxes].")

/mob/living/simple_animal/bot/floorbot/set_custom_texts()
	text_hack = "Вы взломали протоколы построек у [name]."
	text_dehack = "Вы заметили ошибки в программе [name] и сбросили их до заводских настроек."
	text_dehack_fail = "[name] не отвечает на запросы сброса настроек!"

/mob/living/simple_animal/bot/floorbot/attackby(obj/item/W , mob/user, params)
	if(istype(W, /obj/item/stack/tile/plasteel))
		to_chat(user, span_notice("Бот-полоукладчик может производить обычную плитку самостоятельно."))
		return
	if(specialtiles && istype(W, /obj/item/stack/tile))
		var/obj/item/stack/tile/usedtile = W
		if(usedtile.type != tiletype)
			to_chat(user, span_warning("В боте-полоукладчике уже есть пользовательские плитки."))
			return
	if(istype(W, /obj/item/stack/tile))
		if(specialtiles >= maxtiles)
			return
		var/obj/item/stack/tile/tiles = W //used only to get the amount
		tiletype = W.type
		var/loaded = min(maxtiles-specialtiles, tiles.amount)
		tiles.use(loaded)
		specialtiles += loaded
		if(loaded > 0)
			to_chat(user, span_notice("Вы загрузили [loaded] в бота-полоукладчика. Теперь в нём есть плитка: [specialtiles]."))
		else
			to_chat(user, "<span class='warning'>Нужен хотя бы один метр-на-метр плитки, чтобы вставить в [src]!</span>")

	else if(istype(W, /obj/item/storage/toolbox/artistic))
		if(!open)
			to_chat(user, span_notice("Панель [src] не открыта!"))
			return
		if(!bot_core.allowed(user))
			to_chat(user, span_notice("Панель доступов [src] заблокирована для вас!"))
			return
		if(W.contents.len)
			to_chat(user, span_notice("Ящик с инструментами должен быть пуст!"))
			return
		if(bot_core.allowed(user) && open && !(upgrades & UPGRADE_FLOOR_ARTBOX))
			to_chat(user, span_notice("Вы улучшили оболочку \the [src] для большей ёмкости!"))
			upgrades |= UPGRADE_FLOOR_ARTBOX
			maxtiles += 100 //Double the storage!
			toolbox_upg += "просторным корпусом"
			determine_skin("artistic_floorbot_upgrade")
			qdel(W)
		else
			to_chat(user, span_notice("[src] уже имеет просторную оболочку!"))

	else if(istype(W, /obj/item/storage/toolbox/syndicate))
		if(!open)
			to_chat(user, span_notice("Панель [src] не открыта!"))
			return
		if(!bot_core.allowed(user))
			to_chat(user, span_notice("Панель доступов [src] заблокирована для вас!"))
			return
		if(W.contents.len)
			to_chat(user, span_notice("Ящик с инструментами должен быть пуст!"))
			return
		if(bot_core.allowed(user) && open && !(upgrades & UPGRADE_FLOOR_SYNDIBOX))
			to_chat(user, span_notice("Вы улучшили корпус \the [src] для максимальной ёмкости!"))
			upgrades |= UPGRADE_FLOOR_SYNDIBOX
			maxtiles += 200 //Double bse storage
			base_speed = 1 //2x faster!
			toolbox_upg += "материалом синдикатовского качества"
			determine_skin("syndicate_floorbot_upgrade")
			qdel(W)
		else
			to_chat(user, span_notice("[src] уже имеет просторную оболочку!"))


	else
		..()

/mob/living/simple_animal/bot/floorbot/emag_act(mob/user)
	. = ..()
	if(emagged == 2)
		if(user)
			to_chat(user, "<span class='danger'>[src] жужжит и звенит.</span>")

// Variables sent to TGUI
/mob/living/simple_animal/bot/floorbot/ui_data(mob/user)
	var/list/data = ..()
	if(!locked || issilicon(user) || IsAdminGhost(user))
		data["custom_controls"]["tile_hull"] = autotile
		data["custom_controls"]["place_tiles"] =  placetiles
		data["custom_controls"]["place_custom"] = replacetiles
		data["custom_controls"]["repair_damage"] = fixfloors
		data["custom_controls"]["traction_magnets"] = anchored
		data["custom_controls"]["tile_stack"] = 0
		data["custom_controls"]["line_mode"] = FALSE
		if(specialtiles)
			data["custom_controls"]["tile_stack"] = specialtiles
		if(targetdirection)
			data["custom_controls"]["line_mode"] = dir2text(targetdirection)
	return data

// Actions received from TGUI
/mob/living/simple_animal/bot/floorbot/ui_act(action, params)
	. = ..()
	if(. || !hasSiliconAccessInArea(usr) && !IsAdminGhost(usr) && !(bot_core.allowed(usr) || !locked))
		return TRUE
	switch(action)
		if("place_custom")
			replacetiles = !replacetiles
		if("place_tiles")
			placetiles = !placetiles
		if("repair_damage")
			fixfloors = !fixfloors
		if("tile_hull")
			autotile = !autotile
		if("traction_magnets")
			anchored = !anchored
		if("eject_tiles")
			if(specialtiles && tiletype != null)
				empty_tiles()

		if("line_mode")
			var/setdir = input("Select construction direction:") as null|anything in list("north","east","south","west","disable")
			switch(setdir)
				if("north")
					targetdirection = 1
				if("south")
					targetdirection = 2
				if("east")
					targetdirection = 4
				if("west")
					targetdirection = 8
				if("disable")
					targetdirection = null
	return

/mob/living/simple_animal/bot/floorbot/proc/empty_tiles()
	new tiletype(drop_location(), specialtiles)
	specialtiles = 0
	tiletype = null

/mob/living/simple_animal/bot/floorbot/handle_automated_action()
	if(!..())
		return

	if(mode == BOT_REPAIRING)
		return

	if(prob(5))
		audible_message("[src] делает взволнованный звеняще-жужжащий звук!")

	//Normal scanning procedure. We have tiles loaded, are not emagged.
	if(!target && emagged < 2)
		if(targetdirection != null) //The bot is in line mode.
			var/turf/T = get_step(src, targetdirection)
			if(isspaceturf(T)) //Check for space
				target = T
				process_type = LINE_SPACE_MODE
			if(isfloorturf(T)) //Check for floor
				target = T

		if(!target)
			process_type = HULL_BREACH //Ensures the floorbot does not try to "fix" space areas or shuttle docking zones.
			target = scan(/turf/open/space)

		if(!target && placetiles) //Finds a floor without a tile and gives it one.
			process_type = PLACE_TILE //The target must be the floor and not a tile. The floor must not already have a floortile.
			target = scan(/turf/open/floor)

		if(!target && fixfloors) //Repairs damaged floors and tiles.
			process_type = FIX_TILE
			target = scan(/turf/open/floor)

		if(!target && replacetiles && specialtiles > 0) //Replace a floor tile with custom tile
			process_type = REPLACE_TILE //The target must be a tile. The floor must already have a floortile.
			target = scan(/turf/open/floor)

	if(!target && emagged == 2) //We are emagged! Time to rip up the floors!
		process_type = TILE_EMAG
		target = scan(/turf/open/floor)


	if(!target)

		if(auto_patrol)
			if(mode == BOT_IDLE || mode == BOT_START_PATROL)
				start_patrol()

			if(mode == BOT_PATROL)
				bot_patrol()

	if(target)
		if(loc == target || loc == get_turf(target))
			if(check_bot(target))	//Target is not defined at the parent
				shuffle = TRUE
				if(prob(50))	//50% chance to still try to repair so we dont end up with 2 floorbots failing to fix the last breach
					target = null
					path = list()
					return
			if(isturf(target) && emagged < 2)
				repair(target)
			else if(emagged == 2 && isfloorturf(target))
				var/turf/open/floor/F = target
				anchored = TRUE
				mode = BOT_REPAIRING
				F.ReplaceWithLattice()
				audible_message("<span class='danger'>[src] делает взволнованный звенящий звук.</span>")
				addtimer(CALLBACK(src, PROC_REF(floorbot_emagged_resume)), 5, TIMER_DELETE_ME)
			path = list()
			return
		if(path.len == 0)
			if(!isturf(target))
				var/turf/TL = get_turf(target)
				path = get_path_to(src, TL, 30, id=access_card,simulated_only = 0)
			else
				path = get_path_to(src, target, 30, id=access_card,simulated_only = 0)

			if(!bot_move(target))
				add_to_ignore(target)
				target = null
				mode = BOT_IDLE
				return
		else if(!bot_move(target))
			target = null
			mode = BOT_IDLE
			return



	oldloc = loc

/mob/living/simple_animal/bot/floorbot/proc/floorbot_emagged_resume()
	anchored = FALSE
	mode = BOT_IDLE
	target = null

/mob/living/simple_animal/bot/floorbot/proc/is_hull_breach(turf/t) //Ignore space tiles not considered part of a structure, also ignores shuttle docking areas.
	var/area/t_area = get_area(t)
	if(t_area && (t_area.name == "Space" || findtext(t_area.name, "huttle")))
		return FALSE
	else
		return TRUE

//Floorbots, having several functions, need sort out special conditions here.
/mob/living/simple_animal/bot/floorbot/process_scan(scan_target)
	var/result
	var/turf/open/floor/F
	switch(process_type)
		if(HULL_BREACH) //The most common job, patching breaches in the station's hull.
			if(is_hull_breach(scan_target)) //Ensure that the targeted space turf is actually part of the station, and not random space.
				result = scan_target
				anchored = TRUE //Prevent the floorbot being blown off-course while trying to reach a hull breach.
		if(LINE_SPACE_MODE) //Space turfs in our chosen direction are considered.
			if(get_dir(src, scan_target) == targetdirection)
				result = scan_target
				anchored = TRUE
		if(PLACE_TILE)
			F = scan_target
			if(isplatingturf(F)) //The floor must not already have a tile.
				result = F
		if(REPLACE_TILE)
			F = scan_target
			if(isfloorturf(F) && !isplatingturf(F)) //The floor must already have a tile.
				result = F
		if(FIX_TILE)	//Selects only damaged floors.
			F = scan_target
			if(istype(F) && (F.broken || F.burnt))
				result = F
		if(TILE_EMAG) //Emag mode! Rip up the floor and cause breaches to space!
			F = scan_target
			if(!isplatingturf(F))
				result = F
		else //If no special processing is needed, simply return the result.
			result = scan_target
	return result

/mob/living/simple_animal/bot/floorbot/proc/repair(turf/target_turf)

	if(check_bot_working(target_turf))
		add_to_ignore(target_turf)
		target = null
		playsound(src, 'sound/effects/whistlereset.ogg', 50, TRUE)
		return
	if(isspaceturf(target_turf))
		 //Must be a hull breach or in line mode to continue.
		if(!is_hull_breach(target_turf) && !targetdirection)
			target = null
			return
	else if(!isfloorturf(target_turf))
		return
	if(isspaceturf(target_turf)) //If we are fixing an area not part of pure space, it is
		anchored = TRUE
		visible_message(span_notice("[targetdirection ? "[src] начинает установку обшивки." : "[src] начинает латать пробоину."]"))
		mode = BOT_REPAIRING
		tile_change_animation("floorbot-tiling", FLOAT_LAYER + 0.01)
		sleep(50)
		tile_change_animation("floorbot-tiles", FLOAT_LAYER + 0.01)
		if(mode == BOT_REPAIRING && src.loc == target_turf)
			if(autotile) //Build the floor and include a tile.
				target_turf.PlaceOnTop(/turf/open/floor/plasteel, flags = CHANGETURF_INHERIT_AIR)
			else //Build a hull plating without a floor tile.
				target_turf.PlaceOnTop(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)

	else
		var/turf/open/floor/F = target_turf

		if(F.type != initial(tiletype.turf_type) && (F.broken || F.burnt || isplatingturf(F)) || F.type == (initial(tiletype.turf_type) && (F.broken || F.burnt)))
			anchored = TRUE
			mode = BOT_REPAIRING
			visible_message(span_notice("[src] чинит покрытие под собой."))
			tile_change_animation("floorbot-tiling", FLOAT_LAYER + 0.01)
			sleep(50)
			tile_change_animation("floorbot-tiles", FLOAT_LAYER + 0.01)
			if(mode == BOT_REPAIRING && F && src.loc == F)
				F.broken = 0
				F.burnt = 0
				F.PlaceOnTop(/turf/open/floor/plasteel, flags = CHANGETURF_INHERIT_AIR)

		if(replacetiles && F.type != initial(tiletype.turf_type) && specialtiles && !isplatingturf(F))
			anchored = TRUE
			mode = BOT_REPAIRING
			visible_message(span_notice("[src] заменяет плитку пола."))
			tile_change_animation("floorbot-tiling", FLOAT_LAYER + 0.01)
			sleep(50)
			tile_change_animation("floorbot-tiles", FLOAT_LAYER + 0.01)
			if(mode == BOT_REPAIRING && F && src.loc == F)
				F.broken = 0
				F.burnt = 0
				F.PlaceOnTop(initial(tiletype.turf_type), flags = CHANGETURF_INHERIT_AIR)
				specialtiles -= 1
				if(specialtiles == 0)
					speak("Запрос замены пользовательской плитки для возобновления работ.")
	mode = BOT_IDLE
	update_icon()
	anchored = FALSE
	target = null

/mob/living/simple_animal/bot/floorbot/update_icon()
	. = ..()
	determine_on_off()

	box_overlay.dir = dir
	if(upgrade_overlay)
		upgrade_overlay.dir = dir

/mob/living/simple_animal/bot/floorbot/proc/tile_change_animation(animation_state, layer_value)
	if(tile_overlay)
		cut_overlay(tile_overlay)
	tile_overlay = mutable_appearance(icon, animation_state)
	tile_overlay.layer = layer_value
	tile_overlay.dir = dir
	add_overlay(tile_overlay)

/mob/living/simple_animal/bot/floorbot/proc/determine_on_off()
	if(!sensor_overlay)
		return

	cut_overlay(sensor_overlay)
	sensor_overlay = mutable_appearance(icon, "floorbot_sensor-[on]")
	sensor_overlay.layer = FLOAT_LAYER + 0.03
	sensor_overlay.dir = dir
	add_overlay(sensor_overlay)

/mob/living/simple_animal/bot/floorbot/explode()
	on = FALSE
	visible_message("<span class='boldannounce'>[src] разлетается на части!</span>")
	var/atom/Tsec = drop_location()

	drop_part(toolbox, Tsec)

	new /obj/item/assembly/prox_sensor(Tsec)

	if(specialtiles && tiletype != null)
		empty_tiles()

	if(prob(50))
		drop_part(robot_arm, Tsec)

	new /obj/item/stack/tile/plasteel(Tsec, 1)

	do_sparks(3, TRUE, src)
	..()

/obj/machinery/bot_core/floorbot
	req_one_access = list(ACCESS_CONSTRUCTION, ACCESS_ROBOTICS)

/mob/living/simple_animal/bot/floorbot/UnarmedAttack(atom/A, proximity, intent = a_intent, flags = NONE)
	if(isturf(A))
		repair(A)
	else
		..()

/**
  * Checks a given turf to see if another floorbot is there, working as well.
  */
/mob/living/simple_animal/bot/floorbot/proc/check_bot_working(turf/active_turf)
	if(isturf(active_turf))
		for(var/mob/living/simple_animal/bot/floorbot/robot in active_turf)
			if(robot.mode == BOT_REPAIRING)
				return TRUE
	return FALSE

#undef HULL_BREACH
#undef LINE_SPACE_MODE
#undef FIX_TILE
#undef AUTO_TILE
#undef PLACE_TILE
#undef REPLACE_TILE
#undef TILE_EMAG
