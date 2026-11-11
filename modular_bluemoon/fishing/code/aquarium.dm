// Простой, но полноценный аквариум. Внутри живёт рыба, ей нужны подходящая вода
// и температура, её можно кормить, и она размножается, если резервуар здоров.
/obj/structure/aquarium
	name = "aquarium"
	desc = "Стеклянный резервуар с водой, ждущий рыбы."
	icon = 'modular_bluemoon/fishing/icons/obj/aquarium/tanks.dmi'
	icon_state = "aquarium_base"
	density = TRUE
	anchored = TRUE
	max_integrity = 200
	var/capacity = 10
	var/bottomless = FALSE
	var/fluid_type = AQUARIUM_FLUID_FRESHWATER
	var/fluid_temp = DEFAULT_AQUARIUM_TEMP
	var/allow_breeding = TRUE
	var/auto_mode = FALSE
	var/beauty = 0
	var/glass_color = "#cfe8ff"
	var/list/tracked_fish = list()
	/// Связка рыбы и её плавающего визуала в vis_contents.
	var/list/fish_visuals = list()
	/// Связка декора и его статичного визуала в vis_contents.
	var/list/prop_visuals = list()

/obj/structure/aquarium/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_IS_AQUARIUM, AQUARIUM_TRAIT)
	RegisterSignal(src, COMSIG_AQUARIUM_GET_REPRODUCTION_CANDIDATES, PROC_REF(get_reproduction_candidates))
	RegisterSignal(src, COMSIG_AQUARIUM_CHECK_EVOLUTION_CONDITIONS, PROC_REF(check_evolution))
	update_icon()
	START_PROCESSING(SSobj, src)

/obj/structure/aquarium/proc/get_reproduction_candidates(datum/source, obj/item/fish/parent, list/candidates)
	SIGNAL_HANDLER
	if(!allow_breeding)
		return
	for(var/obj/item/fish/fish in tracked_fish)
		if(fish == parent)
			continue
		if(fish.type == parent.type || (fish.type in parent.compatible_types) || HAS_TRAIT(fish, TRAIT_FISH_CROSSBREEDER) || HAS_TRAIT(parent, TRAIT_FISH_CROSSBREEDER))
			candidates += fish

/// Бросает шанс эволюции при размножении и проверяет нужную температуру.
/obj/structure/aquarium/proc/check_evolution(datum/source, obj/item/fish/fish, obj/item/fish/mate, datum/fish_evolution/evolution)
	SIGNAL_HANDLER
	var/real_probability = (isnull(mate) || (evolution.type in mate.evolution_types)) ? evolution.probability : evolution.probability * 0.5
	if(HAS_TRAIT(fish, TRAIT_FISH_MUTAGENIC) || (mate && HAS_TRAIT(mate, TRAIT_FISH_MUTAGENIC)))
		real_probability *= 3
	if(!prob(real_probability))
		return NONE
	if(!ISINRANGE(fluid_temp, evolution.required_temperature_min, evolution.required_temperature_max))
		return NONE
	return COMPONENT_ALLOW_EVOLUTION

/obj/structure/aquarium/Destroy()
	STOP_PROCESSING(SSobj, src)
	REMOVE_TRAIT(src, TRAIT_IS_AQUARIUM, AQUARIUM_TRAIT)
	for(var/obj/item/fish/fish in tracked_fish.Copy())
		if(QDELETED(fish))
			continue
		REMOVE_TRAIT(fish, TRAIT_FISH_STASIS, REF(src))
		fish.forceMove(drop_location())
	for(var/atom/movable/prop in contents.Copy())
		if(!isfish(prop))
			prop.forceMove(drop_location())
	for(var/fish_ref in fish_visuals)
		qdel(fish_visuals[fish_ref])
	fish_visuals.Cut()
	for(var/prop_ref in prop_visuals)
		qdel(prop_visuals[prop_ref])
	prop_visuals.Cut()
	tracked_fish.Cut()
	return ..()

/obj/structure/aquarium/update_overlays()
	. = ..()
	var/mutable_appearance/sand = mutable_appearance(icon, "sand", layer = layer + AQUARIUM_BELOW_GLASS_LAYER)
	sand.pixel_y = -6
	. += sand
	. += mutable_appearance(icon, "rocks", layer = layer + AQUARIUM_BELOW_GLASS_LAYER)
	var/glass = fluid_type == AQUARIUM_FLUID_AIR ? "aquarium_glass_air" : "aquarium_glass_water"
	. += mutable_appearance(icon, glass, layer = layer + AQUARIUM_GLASS_LAYER)
	. += mutable_appearance(icon, "aquarium_borders", layer = layer + AQUARIUM_BORDERS_LAYER)

/obj/structure/aquarium/examine(mob/user)
	. = ..()
	. += span_notice("It contains [length(tracked_fish)] / [capacity] fish.")
	. += span_notice("Water type: [fluid_type]. Temperature: [round(fluid_temp - T0C, 0.1)] C.")
	. += span_notice("Beauty score: [beauty].")
	if(!length(tracked_fish))
		. += span_info("Use a fish on it to add it, or use a fish feed to feed the inhabitants.")
	. += span_info("Drag any other item onto it to use it as a decoration.")
	if(bottomless)
		. += span_notice("The tank has been expanded with bluespace crystals and is effectively bottomless.")

/obj/structure/aquarium/attackby(obj/item/item, mob/living/user, params)
	if(istype(item, /obj/item/aquarium_kit))
		to_chat(user, span_warning("There's already an aquarium here."))
		return TRUE
	if(istype(item, /obj/item/fish))
		var/obj/item/fish/fish = item
		if(length(tracked_fish) >= capacity)
			to_chat(user, span_warning("[src] is already full."))
			return TRUE
		if(!user.transferItemToLoc(fish, src))
			return TRUE
		add_fish(fish)
		user.visible_message(span_notice("[user] puts [fish] into [src]."), span_notice("You put [fish] into [src]."))
		return TRUE
	if(istype(item, /obj/item/reagent_containers/cup/fish_feed))
		if(!item.reagents?.total_volume)
			to_chat(user, span_warning("[item] is empty."))
			return TRUE
		for(var/obj/item/fish/fish in tracked_fish)
			fish.feed(item.reagents)
		to_chat(user, span_notice("You feed the fish in [src]."))
		return TRUE
	if(istype(item, /obj/item/aquarium_conductivity_kit))
		ADD_TRAIT(src, TRAIT_BIOELECTRIC_GENERATOR, AQUARIUM_TRAIT)
		to_chat(user, span_notice("Вы подключаете электропроводность аквариума. Электрические рыбы теперь смогут питать окружение."))
		qdel(item)
		return TRUE
	if(istype(item, /obj/item/stack/ore/bluespace_crystal) || istype(item, /obj/item/stack/sheet/bluespace_crystal))
		if(bottomless)
			to_chat(user, span_warning("[src] уже бездонный."))
			return TRUE
		var/obj/item/stack/crystals = item
		if(!crystals.use(1))
			return TRUE
		bottomless = TRUE
		capacity = 999
		user.visible_message(span_notice("[user] вставляет блюспейс-кристалл в [src]."), span_notice("Вы вставляете блюспейс-кристалл в [src]. Теперь он бездонный."))
		return TRUE
	return ..()

/obj/structure/aquarium/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/structure/aquarium/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if(istype(arrived, /obj/item/fish) && !(arrived in tracked_fish))
		add_fish(arrived)
	else if(isitem(arrived) && !prop_visuals[arrived])
		add_prop_visual(arrived)

/obj/structure/aquarium/Exited(atom/movable/gone, direction)
	. = ..()
	if(istype(gone, /obj/item/fish))
		var/obj/item/fish/fish = gone
		fish.aquarium_pixel_x = null
		fish.aquarium_pixel_y = null
		remove_fish_visual(fish)
		tracked_fish -= gone
		recalculate_beauty()
		update_icon()
	else
		remove_prop_visual(gone)

/obj/structure/aquarium/proc/add_fish(obj/item/fish/fish)
	if(QDELETED(fish) || (fish in tracked_fish))
		return
	tracked_fish += fish
	fish.last_feeding = world.time
	fish.forceMove(src)
	update_fish_state(fish)
	add_fish_visual(fish)
	recalculate_beauty()
	update_icon()

/obj/structure/aquarium/proc/remove_fish(obj/item/fish/fish, mob/user)
	if(!(fish in tracked_fish))
		return
	tracked_fish -= fish
	remove_fish_visual(fish)
	fish.forceMove(user ? user.loc : drop_location())
	recalculate_beauty()
	update_icon()

/// Заводит анимированный визуал для рыбы, плавающей внутри аквариума.
/obj/structure/aquarium/proc/add_fish_visual(obj/item/fish/fish)
	if(QDELETED(fish) || fish_visuals[fish])
		return
	var/obj/effect/aquarium_fish/visual = new
	visual.name = ""
	visual.layer = layer + min(AQUARIUM_MAX_OFFSET, AQUARIUM_MIN_OFFSET + AQUARIUM_LAYER_STEP * (length(fish_visuals) + 1))
	visual.fish = fish
	fish_visuals[fish] = visual
	vis_contents += visual
	visual.set_bounds()
	visual.pixel_x = rand(visual.min_x, visual.max_x)
	visual.pixel_y = rand(visual.min_y, visual.max_y)
	sync_fish_visual(fish)

/obj/structure/aquarium/proc/remove_fish_visual(obj/item/fish/fish)
	var/obj/effect/aquarium_fish/visual = fish_visuals[fish]
	if(!visual)
		return
	fish_visuals -= fish
	vis_contents -= visual
	qdel(visual)

/// Добавляет статичный визуал декору, который перетащили в аквариум.
/obj/structure/aquarium/proc/add_prop_visual(atom/movable/prop)
	if(!isitem(prop) || prop_visuals[prop])
		return
	var/obj/item/item = prop
	var/obj/effect/aquarium_prop/visual = new
	visual.name = ""
	visual.icon = item.icon
	visual.icon_state = item.icon_state
	visual.color = item.color
	visual.layer = layer + AQUARIUM_MIN_OFFSET
	visual.transform = matrix().Scale(0.5, 0.5)
	visual.pixel_x = rand(-12, 12)
	visual.pixel_y = rand(-5, -1)
	prop_visuals[prop] = visual
	vis_contents += visual

/obj/structure/aquarium/proc/remove_prop_visual(atom/movable/prop)
	var/obj/effect/aquarium_prop/visual = prop_visuals[prop]
	if(!visual)
		return
	prop_visuals -= prop
	vis_contents -= visual
	qdel(visual)

/// Подгоняет визуал рыбы под её иконку, масштаб и состояние жизни.
/obj/structure/aquarium/proc/sync_fish_visual(obj/item/fish/fish)
	var/obj/effect/aquarium_fish/visual = fish_visuals[fish]
	if(QDELETED(fish) || QDELETED(visual))
		return
	var/fish_icon = fish.dedicated_in_aquarium_icon || fish.icon
	var/fish_state = fish.dedicated_in_aquarium_icon_state || "[fish.icon_state]_small"
	if(!(fish_state in icon_states(fish_icon)))
		fish_state = fish.icon_state
	visual.icon = fish_icon
	visual.icon_state = fish_state
	visual.color = fish.aquarium_vc_color || fish.color || null
	visual.alpha = fish.status == FISH_DEAD ? 180 : 255
	// Малые состояния уже нарисованы под масштаб аквариума, полные спрайты приходится уменьшать.
	visual.base_scale = (fish_state == fish.icon_state && !fish.dedicated_in_aquarium_icon_state) ? 0.4 : 1
	visual.set_bounds()
	visual.apply_transform(visual.flip)
	if(fish.status == FISH_DEAD)
		visual.stop_swimming()
		visual.pixel_y = visual.min_y
		visual.apply_transform(visual.flip)
	else
		visual.start_swimming()

/obj/structure/aquarium/proc/update_fish_visuals()
	for(var/obj/item/fish/fish in tracked_fish)
		sync_fish_visual(fish)

/obj/structure/aquarium/proc/update_fish_state(obj/item/fish/fish)
	var/list/compatible = GLOB.fish_compatible_fluid_types[fish.required_fluid_type] || list(fish.required_fluid_type)
	fish.fish_flags &= ~(FISH_FLAG_SAFE_FLUID|FISH_FLAG_SAFE_TEMPERATURE|FISH_FLAG_OVERPOPULATED)
	if(fluid_type in compatible)
		fish.fish_flags |= FISH_FLAG_SAFE_FLUID
	if(ISINRANGE(fluid_temp, fish.required_temperature_min, fish.required_temperature_max))
		fish.fish_flags |= FISH_FLAG_SAFE_TEMPERATURE
	if(length(tracked_fish) > AQUARIUM_MAX_BREEDING_POPULATION)
		fish.fish_flags |= FISH_FLAG_OVERPOPULATED

/obj/structure/aquarium/proc/recalculate_beauty()
	beauty = 0
	for(var/obj/item/fish/fish in tracked_fish.Copy())
		if(QDELETED(fish))
			tracked_fish -= fish
			continue
		beauty += fish.get_aquarium_beauty()

/obj/structure/aquarium/process(seconds_per_tick)
	if(!length(tracked_fish))
		return
	if(auto_mode)
		var/list/fluids = list()
		var/min_temp = INFINITY
		var/max_temp = -INFINITY
		for(var/obj/item/fish/fish in tracked_fish)
			fluids |= GLOB.fish_compatible_fluid_types[fish.required_fluid_type] || list(fish.required_fluid_type)
			min_temp = min(min_temp, fish.required_temperature_min)
			max_temp = max(max_temp, fish.required_temperature_max)
		if(length(fluids))
			fluid_type = fluids[1]
		if(min_temp != INFINITY && min_temp <= max_temp)
			fluid_temp = clamp(fluid_temp, min_temp, max_temp)
	beauty = 0
	for(var/obj/item/fish/fish in tracked_fish.Copy())
		if(QDELETED(fish))
			tracked_fish -= fish
			continue
		update_fish_state(fish)
		beauty += fish.get_aquarium_beauty()
	update_fish_visuals()
	update_icon()

/obj/structure/aquarium/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Aquarium", name)
		ui.open()

/obj/structure/aquarium/ui_data(mob/user)
	var/list/data = list()
	data["fluidType"] = fluid_type
	data["temperature"] = round(fluid_temp, 1)
	data["minTemperature"] = MIN_AQUARIUM_TEMP
	data["maxTemperature"] = MAX_AQUARIUM_TEMP
	data["fluidTypes"] = list(AQUARIUM_FLUID_FRESHWATER, AQUARIUM_FLUID_SALTWATER, AQUARIUM_FLUID_SULPHWATEVER, AQUARIUM_FLUID_AIR)
	data["allowBreeding"] = allow_breeding
	data["autoMode"] = auto_mode
	data["beauty"] = beauty
	data["capacity"] = capacity
	data["fishCount"] = length(tracked_fish)
	var/list/fish_data = list()
	for(var/obj/item/fish/fish in tracked_fish)
		if(QDELETED(fish))
			continue
		fish_data += list(list(
			"fish_ref" = REF(fish),
			"fish_name" = fish.name,
			"fish_happiness" = fish.get_happiness_value(),
			"fish_icon" = get_icon_url(fish, user),
			"fish_alive" = fish.status == FISH_ALIVE,
			"fish_health" = round(fish.get_health_percentage() * 100, 1),
			"fish_size" = fish.size,
			"fish_weight" = fish.weight,
			"fish_beauty" = fish.beauty,
		))
	data["fishData"] = fish_data
	var/list/prop_data = list()
	for(var/atom/movable/prop in contents)
		if(isfish(prop))
			continue
		prop_data += list(list(
			"prop_ref" = REF(prop),
			"prop_name" = prop.name,
			"prop_icon" = get_icon_url(prop, user),
		))
	data["propData"] = prop_data
	return data

/// Достаёт URL иконки атома для интерфейса аквариума.
/obj/structure/aquarium/proc/get_icon_url(atom/target, mob/user)
	if(!target || !user?.client)
		return ""
	return icon2html(target, user.client, target.icon_state, target.dir, 1, FALSE, TRUE)

/obj/structure/aquarium/ui_act(action, params)
	. = ..()
	if(.)
		return
	var/mob/user = usr
	switch(action)
		if("temperature")
			var/new_temp = text2num(params["temperature"])
			if(!isnull(new_temp))
				fluid_temp = clamp(new_temp, MIN_AQUARIUM_TEMP, MAX_AQUARIUM_TEMP)
		if("fluid")
			var/new_fluid = params["fluid"]
			if(new_fluid in list(AQUARIUM_FLUID_FRESHWATER, AQUARIUM_FLUID_SALTWATER, AQUARIUM_FLUID_SULPHWATEVER, AQUARIUM_FLUID_AIR) && new_fluid != fluid_type)
				fluid_type = new_fluid
				for(var/obj/item/fish/fish in tracked_fish)
					update_fish_state(fish)
		if("toggle_breeding")
			allow_breeding = !allow_breeding
		if("toggle_auto")
			auto_mode = !auto_mode
		if("pet_fish")
			var/obj/item/fish/fish = locate(params["fish_reference"]) in tracked_fish
			if(istype(fish) && fish.loc == src && fish.status != FISH_DEAD)
				fish.pet_fish(user, TRUE)
		if("rename_fish")
			var/obj/item/fish/fish = locate(params["fish_reference"]) in tracked_fish
			var/new_name = sanitize_name(params["chosen_name"])
			if(istype(fish) && new_name && new_name != fish.name)
				fish.name = new_name
		if("remove_item")
			var/atom/movable/item = locate(params["item_reference"]) in contents
			if(!item)
				return FALSE
			if(isfish(item))
				remove_fish(item, user)
			else
				item.forceMove(drop_location())
			to_chat(user, span_notice("You take out [item] from [src]."))
		if("remove_fish")
			var/obj/item/fish/fish = locate(params["ref"] || params["fish_reference"]) in tracked_fish
			if(istype(fish))
				remove_fish(fish, user)
		if("set_temp")
			var/new_temp = text2num(params["temp"])
			if(!isnull(new_temp))
				fluid_temp = clamp(new_temp + T0C, MIN_AQUARIUM_TEMP, MAX_AQUARIUM_TEMP)
		if("set_fluid")
			var/new_fluid = params["fluid"]
			if(new_fluid in list(AQUARIUM_FLUID_FRESHWATER, AQUARIUM_FLUID_SALTWATER, AQUARIUM_FLUID_SULPHWATEVER, AQUARIUM_FLUID_AIR))
				fluid_type = new_fluid
		else
			return FALSE
	update_icon()
	. = TRUE

/// Декор в аквариуме. При желании сюда можно засунуть почти что угодно.
/obj/structure/aquarium/MouseDrop_T(atom/dropping, mob/user)
	if(!istype(dropping, /obj/item) || istype(dropping, /obj/item/fish) || istype(dropping, /obj/item/reagent_containers/cup/fish_feed))
		return ..()
	if(!user.Adjacent(src))
		return
	var/obj/item/item = dropping
	if(!user.transferItemToLoc(item, src))
		return
	user.visible_message(span_notice("[user] places [item] inside [src]."), span_notice("You place [item] inside [src]."))
	update_icon()

/obj/structure/aquarium/verb/toggle_breeding()
	set name = "Toggle Aquarium Breeding"
	set category = "Object"
	set src in view(1)
	allow_breeding = !allow_breeding
	to_chat(usr, span_notice("Breeding is now [allow_breeding ? "enabled" : "disabled"] in [src]."))

/obj/structure/aquarium/verb/change_water()
	set name = "Change Aquarium Water"
	set category = "Object"
	set src in view(1)
	var/choice = input(usr, "Choose water type", "Aquarium") as null|anything in list(AQUARIUM_FLUID_FRESHWATER, AQUARIUM_FLUID_SALTWATER, AQUARIUM_FLUID_SULPHWATEVER, AQUARIUM_FLUID_AIR)
	if(choice)
		fluid_type = choice
		update_icon()

/// Живой визуал рыбы, которая плавает внутри аквариума.
/obj/effect/aquarium_fish
	name = ""
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = KEEP_TOGETHER
	vis_flags = VIS_INHERIT_PLANE
	var/obj/item/fish/fish
	var/base_scale = 1
	var/flip = 1
	var/min_x = -12
	var/max_x = 12
	var/min_y = -4
	var/max_y = 10
	var/swim_timer
	var/swimming = FALSE

/obj/effect/aquarium_fish/proc/set_bounds()
	if(!fish)
		return
	var/avg_w = max(round(fish.sprite_width * 0.5), 2)
	var/avg_h = max(round(fish.sprite_height * 0.5), 2)
	min_x = -14 + avg_w
	max_x = max(min_x, 15 - avg_w)
	min_y = -6 + avg_h
	max_y = max(min_y, 12 - avg_h)

/obj/effect/aquarium_fish/proc/apply_transform(new_flip)
	flip = new_flip
	var/matrix/m = matrix()
	m.Scale(base_scale * flip, base_scale)
	transform = m

/obj/effect/aquarium_fish/proc/start_swimming()
	if(swimming || QDELETED(src) || QDELETED(fish) || fish.status == FISH_DEAD)
		return
	swimming = TRUE
	swim_step()

/obj/effect/aquarium_fish/proc/stop_swimming()
	swimming = FALSE
	if(swim_timer && swim_timer != -1)
		deltimer(swim_timer)
		swim_timer = null

/obj/effect/aquarium_fish/proc/swim_step()
	if(!swimming || QDELETED(src) || QDELETED(fish))
		return
	if(fish.status == FISH_DEAD)
		stop_swimming()
		apply_transform(flip)
		pixel_y = min_y
		return
	var/target_x = rand(min_x, max_x)
	var/target_y = rand(min_y, max_y)
	var/distance = abs(target_x - pixel_x) + abs(target_y - pixel_y)
	var/travel_time = clamp(distance * 2, 8, 40)
	apply_transform(target_x >= pixel_x ? -1 : 1)
	animate(src, pixel_x = target_x, pixel_y = target_y, time = travel_time)
	swim_timer = addtimer(CALLBACK(src, PROC_REF(swim_step)), travel_time + rand(2, 10))

/obj/effect/aquarium_fish/Destroy()
	stop_swimming()
	fish = null
	return ..()

/// Неподвижный визуал декора внутри аквариума.
/obj/effect/aquarium_prop
	name = ""
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = KEEP_TOGETHER
	vis_flags = VIS_INHERIT_PLANE

/obj/effect/aquarium_prop/singularity_pull()
	return

/obj/effect/aquarium_prop/singularity_act()
	return


/obj/structure/aquarium/filled
	name = "populated aquarium"
	desc = "Стеклянный резервуар с водой и уже плавающей в нём рыбой."

/obj/structure/aquarium/filled/Initialize(mapload)
	. = ..()
	var/list/starting_fish = list(
		/obj/item/fish/goldfish,
		/obj/item/fish/guppy,
		/obj/item/fish/angelfish,
		/obj/item/fish/plasmatetra,
		/obj/item/fish/catfish,
		/obj/item/fish/perch,
	)
	for(var/fish_type in starting_fish)
		var/obj/item/fish/fish = new fish_type(src)
		add_fish(fish)
		update_fish_state(fish)


/obj/item/aquarium_kit
	name = "aquarium kit"
	desc = "Разборный аквариум, готовый к воде и рыбе."
	icon = 'modular_bluemoon/fishing/icons/obj/aquarium/supplies.dmi'
	icon_state = "construction_kit"
	w_class = WEIGHT_CLASS_BULKY
	/// Сразу заселять аквариум рыбой вместо пустого резервуара.
	var/prefilled = FALSE

/obj/item/aquarium_kit/attack_self(mob/user)
	. = ..()
	var/turf/target = get_step(user, user.dir)
	if(!target || target.density)
		target = get_turf(user)
	if(locate(/obj/structure/aquarium) in target)
		to_chat(user, span_warning("There's already an aquarium there."))
		return
	var/aquarium_type = prefilled ? /obj/structure/aquarium/filled : /obj/structure/aquarium
	new aquarium_type(target)
	user.visible_message(span_notice("[user] unfolds [src] into an aquarium."), span_notice("You unfold [src] into an aquarium."))
	qdel(src)

/obj/item/aquarium_kit/filled
	name = "pre-filled aquarium kit"
	desc = "Разборный аквариум с водой и уже плавающей в нём рыбой."
	prefilled = TRUE

/obj/item/aquarium_conductivity_kit
	name = "aquarium conductivity kit"
	desc = "Набор для подключения электрических рыб к энергосети аквариума."
	icon = 'modular_bluemoon/fishing/icons/obj/aquarium/supplies.dmi'
	icon_state = "bioelec_kit"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/aquarium_kit/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag)
		return ..()
	if(istype(target, /obj/structure/aquarium))
		var/obj/structure/aquarium/aquarium = target
		if(length(aquarium.contents))
			to_chat(user, span_warning("Empty the aquarium first."))
			return
		new /obj/item/aquarium_kit(get_turf(aquarium))
		qdel(aquarium)
		return
	return ..()
