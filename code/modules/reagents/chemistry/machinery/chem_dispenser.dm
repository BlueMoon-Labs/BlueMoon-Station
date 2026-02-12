/proc/translate_legacy_chem_id(id)
	switch (id)
		if ("sacid")
			return "sulphuricacid"
		if ("facid")
			return "fluorosulfuricacid"
		if ("co2")
			return "carbondioxide"
		if ("mine_salve")
			return "minerssalve"
		else
			return ckey(id)

/obj/machinery/chem_dispenser
	name = "Chem Dispenser"
	desc = "Создаёт и выдаёт препараты."
	density = TRUE
	icon = 'icons/obj/chemical.dmi'
	icon_state = "dispenser"
	use_power = IDLE_POWER_USE
	idle_power_usage = 40
	active_power_usage = 1000
	interaction_flags_machine = INTERACT_MACHINE_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OFFLINE
	resistance_flags = FIRE_PROOF | ACID_PROOF
	circuit = /obj/item/circuitboard/machine/chem_dispenser
	var/obj/item/stock_parts/cell/cell
	var/powerefficiency = CHEM_DISPENSER_BASE_EFFICIENCY
	var/dispenseUnit = 5
	var/amount = 30
	var/recharge_amount = CHEM_DISPENSER_BASE_RECHARGE
	var/recharge_counter = 0
	var/canStore = TRUE // Whether this dispenser can store reagents.
	var/mutable_appearance/beaker_overlay
	var/working_state = "dispenser_working"
	var/nopower_state = "dispenser_nopower"
	var/has_panel_overlay = TRUE
	var/obj/item/reagent_containers/beaker = null
	var/list/dispensable_reagents = list(
		/datum/reagent/hydrogen,
		/datum/reagent/lithium,
		/datum/reagent/carbon,
		/datum/reagent/nitrogen,
		/datum/reagent/oxygen,
		/datum/reagent/fluorine,
		/datum/reagent/sodium,
		/datum/reagent/aluminium,
		/datum/reagent/silicon,
		/datum/reagent/phosphorus,
		/datum/reagent/sulfur,
		/datum/reagent/chlorine,
		/datum/reagent/potassium,
		/datum/reagent/iron,
		/datum/reagent/copper,
		/datum/reagent/mercury,
		/datum/reagent/radium,
		/datum/reagent/water,
		/datum/reagent/consumable/ethanol,
		/datum/reagent/consumable/sugar,
		/datum/reagent/toxin/acid,
		/datum/reagent/fuel,
		/datum/reagent/silver,
		/datum/reagent/iodine,
		/datum/reagent/bromine,
		/datum/reagent/stable_plasma
	)
	// Available after stock-part upgrades.
	var/list/upgrade_reagents = list(
		/datum/reagent/oil,
		/datum/reagent/ammonia,
		/datum/reagent/ash
	)

	var/list/upgrade_reagents2 = list(
		/datum/reagent/acetone,
		/datum/reagent/phenol,
		/datum/reagent/diethylamine
	)

	var/list/upgrade_reagents3 = list(
		/datum/reagent/medicine/mine_salve,
		/datum/reagent/toxin
	)

	var/list/emagged_reagents = list(
		/datum/reagent/drug/space_drugs,
		/datum/reagent/toxin/plasma,
		/datum/reagent/consumable/frostoil,
		/datum/reagent/toxin/carpotoxin,
		/datum/reagent/toxin/histamine,
		/datum/reagent/medicine/morphine
	)
	var/list/recording_recipe

	var/list/saved_recipes = list()

	/// Shared cache of game recipe data.
	var/static/list/cached_game_recipes_data
	/// Maps result reagent type to recipes that produce it.
	var/static/list/recipes_by_result
	/// Maps recipe datum to its normalized_chemical_reactions_list name.
	var/static/list/recipe_to_name
	/// Maps "recipe_name|alt_index" to alt recipe datum.
	var/static/list/alt_recipe_datums

	/// Cached game recipes for this dispenser's current reagent set.
	var/list/cached_dispenser_game_recipes
	/// Hash of dispensable_reagents used to validate the instance cache.
	var/cached_dispensable_reagents_hash = ""
	/// Current manipulator tier (1-6).
	var/manipulator_tier = 1
	/// Cached capacitor rating used for beaker pH display precision.
	var/capacitor_rating = 1
	/// Dispenser type bitflag (CHEM, SODA, BOOZE).
	var/dispenser_type = DISPENSER_TYPE_CHEM
	/// Cooldown for recipe-dispense actions.
	COOLDOWN_DECLARE(dispense_cooldown)

	/// Shared cache: reagent hash -> computed dispenser recipe data.
	var/static/list/shared_dispenser_recipe_caches

	/// Maps reagent type to dispenser type bitflags that can provide it.
	var/static/list/reagent_to_dispenser_type
	/// Base reagents available from soda dispensers.
	var/static/list/soda_dispenser_reagents
	/// Base reagents available from booze dispensers.
	var/static/list/booze_dispenser_reagents

/proc/should_skip_recipe_for_dispenser(datum/chemical_reaction/R)
	if(R.is_secret)
		return TRUE
	if(ispath(R.required_container, /obj/item/slime_extract))
		return TRUE
	return FALSE

/// Builds reagent -> dispenser-type mapping used by recipe analysis.
/obj/machinery/chem_dispenser/proc/build_reagent_dispenser_mapping()
	if(reagent_to_dispenser_type)
		return

	reagent_to_dispenser_type = list()

	// Must match /obj/machinery/chem_dispenser/drinks
	soda_dispenser_reagents = list(
		/datum/reagent/water,
		/datum/reagent/consumable/ice,
		/datum/reagent/consumable/coffee,
		/datum/reagent/consumable/cream,
		/datum/reagent/consumable/tea,
		/datum/reagent/consumable/icetea,
		/datum/reagent/consumable/space_cola,
		/datum/reagent/consumable/spacemountainwind,
		/datum/reagent/consumable/dr_gibb,
		/datum/reagent/consumable/space_up,
		/datum/reagent/consumable/tonic,
		/datum/reagent/consumable/sodawater,
		/datum/reagent/consumable/lemon_lime,
		/datum/reagent/consumable/pwr_game,
		/datum/reagent/consumable/shamblers,
		/datum/reagent/consumable/sugar,
		/datum/reagent/consumable/pineapplejuice,
		/datum/reagent/consumable/orangejuice,
		/datum/reagent/consumable/grenadine,
		/datum/reagent/consumable/limejuice,
		/datum/reagent/consumable/tomatojuice,
		/datum/reagent/consumable/lemonjuice,
		/datum/reagent/consumable/menthol,
		/datum/reagent/consumable/synthdrink,
		/datum/reagent/consumable/banana,
		/datum/reagent/consumable/berryjuice,
		/datum/reagent/consumable/strawberryjuice,
		/datum/reagent/consumable/applejuice,
		/datum/reagent/consumable/carrotjuice,
		/datum/reagent/consumable/pumpkinjuice,
		/datum/reagent/consumable/watermelonjuice,
		/datum/reagent/consumable/melonjuice,
		/datum/reagent/drug/mushroomhallucinogen,
		/datum/reagent/consumable/nothing,
		/datum/reagent/consumable/peachjuice,
		/datum/reagent/consumable/blumpkinjuice,
		/datum/reagent/consumable/coco,
		/datum/reagent/toxin/mindbreaker,
		/datum/reagent/toxin/staminatoxin,
		/datum/reagent/medicine/cryoxadone,
		/datum/reagent/iron
	)

	// Must match /obj/machinery/chem_dispenser/drinks/beer
	booze_dispenser_reagents = list(
		/datum/reagent/consumable/ethanol/beer,
		/datum/reagent/consumable/ethanol/kahlua,
		/datum/reagent/consumable/ethanol/whiskey,
		/datum/reagent/consumable/ethanol/wine,
		/datum/reagent/consumable/ethanol/vodka,
		/datum/reagent/consumable/ethanol/gin,
		/datum/reagent/consumable/ethanol/rum,
		/datum/reagent/consumable/ethanol/tequila,
		/datum/reagent/consumable/ethanol/vermouth,
		/datum/reagent/consumable/ethanol/cognac,
		/datum/reagent/consumable/ethanol/ale,
		/datum/reagent/consumable/ethanol/absinthe,
		/datum/reagent/consumable/ethanol/hcider,
		/datum/reagent/consumable/ethanol/creme_de_menthe,
		/datum/reagent/consumable/ethanol/creme_de_cacao,
		/datum/reagent/consumable/ethanol/creme_de_coconut,
		/datum/reagent/consumable/ethanol/triple_sec,
		/datum/reagent/consumable/ethanol/sake,
		/datum/reagent/consumable/ethanol/applejack,
		/datum/reagent/consumable/ethanol,
		/datum/reagent/consumable/ethanol/fernet,
		/datum/reagent/consumable/synthdrink/synthanol,
		/datum/reagent/consumable/ethanol/alexander,
		/datum/reagent/consumable/clownstears,
		/datum/reagent/toxin/minttoxin,
		/datum/reagent/consumable/ethanol/atomicbomb,
		/datum/reagent/consumable/ethanol/thirteenloko,
		/datum/reagent/consumable/ethanol/changelingsting
	)

	for(var/reagent_type in soda_dispenser_reagents)
		if(!reagent_to_dispenser_type[reagent_type])
			reagent_to_dispenser_type[reagent_type] = 0
		reagent_to_dispenser_type[reagent_type] |= DISPENSER_TYPE_SODA

	for(var/reagent_type in booze_dispenser_reagents)
		if(!reagent_to_dispenser_type[reagent_type])
			reagent_to_dispenser_type[reagent_type] = 0
		reagent_to_dispenser_type[reagent_type] |= DISPENSER_TYPE_BOOZE


/// Builds the shared game-recipe cache on first access.
/obj/machinery/chem_dispenser/proc/build_game_recipes_cache()
	if(cached_game_recipes_data)
		return

	cached_game_recipes_data = list()
	alt_recipe_datums = list()
	build_recipes_by_result_cache()
	build_reagent_dispenser_mapping()

	var/list/processed_reactions = list()

	for(var/recipe_name in GLOB.normalized_chemical_reactions_list)
		var/datum/chemical_reaction/R = GLOB.normalized_chemical_reactions_list[recipe_name]
		if(R.is_secret)
			continue
		if(!length(R.results))
			continue

		processed_reactions[R] = TRUE

		var/recipe_category = "other"
		var/recipe_desc = ""
		var/result_amount = 1
		var/result_type = R.results[1]
		result_amount = R.results[result_type] || 1
		var/datum/reagent/result_reagent = GLOB.chemical_reagents_list[result_type]
		if(result_reagent)
			recipe_desc = result_reagent.description
		recipe_category = get_reagent_category(result_type)

		var/is_extract_recipe = FALSE
		var/extract_container_name = ""
		if(ispath(R.required_container, /obj/item/slime_extract))
			is_extract_recipe = TRUE
			recipe_category = "slime_extracts"
			var/obj/item/slime_extract/extract_type = R.required_container
			extract_container_name = initial(extract_type.name)

		var/list/required = list()
		for(var/reagent_type in R.required_reagents)
			var/datum/reagent/reagent = GLOB.chemical_reagents_list[reagent_type]
			var/reagent_name = reagent ? reagent.name : "[reagent_type]"
			required[reagent_name] = R.required_reagents[reagent_type]

		var/list/sub_recipes = list()
		for(var/reagent_type in R.required_reagents)
			var/datum/reagent/reagent = GLOB.chemical_reagents_list[reagent_type]
			var/reagent_name = reagent ? reagent.name : "[reagent_type]"

			var/list/producing_recipes = recipes_by_result[reagent_type]
			if(length(producing_recipes))
				for(var/datum/chemical_reaction/sub_R as anything in producing_recipes)
					if(should_skip_recipe_for_dispenser(sub_R))
						continue
					var/list/sub_required = list()
					for(var/sub_reagent_type in sub_R.required_reagents)
						var/datum/reagent/sub_reagent = GLOB.chemical_reagents_list[sub_reagent_type]
						var/sub_reagent_name = sub_reagent ? sub_reagent.name : "[sub_reagent_type]"
						sub_required[sub_reagent_name] = sub_R.required_reagents[sub_reagent_type]
					var/sub_recipe_name = recipe_to_name[sub_R]
					sub_recipes[reagent_name] = list(
						"recipe_name" = sub_recipe_name,
						"required" = sub_required,
						"temp" = sub_R.required_temp,
						"is_cold" = sub_R.is_cold_recipe
					)
					break

		var/list/catalysts = list()
		for(var/reagent_type in R.required_catalysts)
			var/datum/reagent/reagent = GLOB.chemical_reagents_list[reagent_type]
			var/reagent_name = reagent ? reagent.name : "[reagent_type]"
			catalysts[reagent_name] = R.required_catalysts[reagent_type]

		var/list/alt_recipes = list()
		var/list/alt_producing = recipes_by_result[result_type]
		if(length(alt_producing))
			var/alt_index = 1
			for(var/datum/chemical_reaction/alt_R as anything in alt_producing)
				if(alt_R == R || should_skip_recipe_for_dispenser(alt_R) || processed_reactions[alt_R])
					continue
				if(!length(alt_R.results))
					continue
				processed_reactions[alt_R] = TRUE

				var/list/alt_required = list()
				for(var/reagent_type in alt_R.required_reagents)
					var/datum/reagent/reagent = GLOB.chemical_reagents_list[reagent_type]
					var/reagent_name = reagent ? reagent.name : "[reagent_type]"
					alt_required[reagent_name] = alt_R.required_reagents[reagent_type]

				var/list/alt_sub_recipes = list()
				for(var/reagent_type in alt_R.required_reagents)
					var/datum/reagent/reagent = GLOB.chemical_reagents_list[reagent_type]
					var/reagent_name = reagent ? reagent.name : "[reagent_type]"
					var/list/alt_producing_sub = recipes_by_result[reagent_type]
					if(length(alt_producing_sub))
						for(var/datum/chemical_reaction/alt_sub_R as anything in alt_producing_sub)
							if(should_skip_recipe_for_dispenser(alt_sub_R))
								continue
							var/list/alt_sub_required = list()
							for(var/sub_reagent_type in alt_sub_R.required_reagents)
								var/datum/reagent/sub_reagent = GLOB.chemical_reagents_list[sub_reagent_type]
								var/sub_reagent_name = sub_reagent ? sub_reagent.name : "[sub_reagent_type]"
								alt_sub_required[sub_reagent_name] = alt_sub_R.required_reagents[sub_reagent_type]
							var/alt_sub_recipe_name = recipe_to_name[alt_sub_R]
							alt_sub_recipes[reagent_name] = list(
								"recipe_name" = alt_sub_recipe_name,
								"required" = alt_sub_required,
								"temp" = alt_sub_R.required_temp,
								"is_cold" = alt_sub_R.is_cold_recipe
							)
							break

				var/list/alt_catalysts = list()
				for(var/reagent_type in alt_R.required_catalysts)
					var/datum/reagent/reagent = GLOB.chemical_reagents_list[reagent_type]
					var/reagent_name = reagent ? reagent.name : "[reagent_type]"
					alt_catalysts[reagent_name] = alt_R.required_catalysts[reagent_type]

				alt_recipes += list(list(
					"required" = alt_required,
					"catalysts" = alt_catalysts,
					"temp" = alt_R.required_temp,
					"is_cold" = alt_R.is_cold_recipe,
					"result_amount" = alt_R.results[result_type] || 1,
					"sub_recipes" = alt_sub_recipes,
					"is_fermichem" = alt_R.FermiChem,
					"optimal_temp_min" = alt_R.OptimalTempMin,
					"optimal_temp_max" = alt_R.OptimalTempMax,
					"explode_temp" = alt_R.ExplodeTemp,
					"optimal_ph_min" = alt_R.OptimalpHMin,
					"optimal_ph_max" = alt_R.OptimalpHMax,
					"react_ph_lim" = alt_R.ReactpHLim,
					"purity_min" = alt_R.PurityMin,
					"thermic_constant" = alt_R.ThermicConstant,
					"h_ion_release" = alt_R.HIonRelease,
					"fermi_explode" = alt_R.FermiExplode
				))
				alt_recipe_datums["[recipe_name]|[alt_index]"] = alt_R
				alt_index++

		cached_game_recipes_data[recipe_name] = list(
			"required" = required,
			"catalysts" = catalysts,
			"category" = recipe_category,
			"temp" = R.required_temp,
			"is_cold" = R.is_cold_recipe,
			"desc" = recipe_desc,
			"result_amount" = result_amount,
			"sub_recipes" = sub_recipes,
			"is_fermichem" = R.FermiChem,
			"optimal_temp_min" = R.OptimalTempMin,
			"optimal_temp_max" = R.OptimalTempMax,
			"explode_temp" = R.ExplodeTemp,
			"optimal_ph_min" = R.OptimalpHMin,
			"optimal_ph_max" = R.OptimalpHMax,
			"react_ph_lim" = R.ReactpHLim,
			"purity_min" = R.PurityMin,
			"thermic_constant" = R.ThermicConstant,
			"h_ion_release" = R.HIonRelease,
			"fermi_explode" = R.FermiExplode,
			"is_extract_recipe" = is_extract_recipe,
			"extract_container_name" = extract_container_name,
			"alt_recipes" = alt_recipes
		)

/// Builds reverse index: reagent type -> recipes that produce it.
/obj/machinery/chem_dispenser/proc/build_recipes_by_result_cache()
	if(recipes_by_result)
		return
	recipes_by_result = list()
	recipe_to_name = list()

	var/list/all_reactions = list()
	for(var/reagent_id in GLOB.chemical_reactions_list)
		for(var/datum/chemical_reaction/R as anything in GLOB.chemical_reactions_list[reagent_id])
			if(all_reactions[R])
				continue
			all_reactions[R] = TRUE
			if(R.id && !R.is_secret && ispath(R.id, /datum/reagent))
				var/datum/reagent/r = R.id
				var/rname = initial(r.name)
				if(!recipe_to_name[R])
					recipe_to_name[R] = rname
			if(R.is_secret)
				continue
			for(var/result_type in R.results)
				if(!recipes_by_result[result_type])
					recipes_by_result[result_type] = list()
				if(!(R in recipes_by_result[result_type]))
					recipes_by_result[result_type] += R

/// Calculates the minimum manipulator tier needed for auto-dispense.
/obj/machinery/chem_dispenser/proc/calculate_recipe_tier(datum/chemical_reaction/R, list/reagent_tiers, list/checked)
	if(!checked)
		checked = list()
	if(R in checked)
		return 1
	checked += R

	var/is_drink = (dispenser_type & DISPENSER_TYPE_DRINKS)

	var/max_depth = 0
	build_recipes_by_result_cache()
	for(var/reagent_type in R.required_reagents)
		var/best_depth = CHEM_RECIPE_MAX_TIER
		if(reagent_type in reagent_tiers)
			best_depth = reagent_tiers[reagent_type] - 1
		// Drink dispensers: external ingredients don't contribute to tier
		if(is_drink && best_depth >= (CHEM_RECIPE_MAX_TIER - 1))
			if(!(reagent_type in dispensable_reagents))
				continue
		var/list/producing_recipes = recipes_by_result[reagent_type]
		if(length(producing_recipes))
			for(var/datum/chemical_reaction/sub_R as anything in producing_recipes)
				if(should_skip_recipe_for_dispenser(sub_R))
					continue
				var/sub_depth = calculate_recipe_tier(sub_R, reagent_tiers, checked)
				best_depth = min(best_depth, sub_depth)
				break
		if(best_depth < CHEM_RECIPE_MAX_TIER)
			max_depth = max(max_depth, best_depth)

	return clamp(max_depth + 1, 1, CHEM_RECIPE_MAX_TIER)

/obj/machinery/chem_dispenser/Initialize(mapload)
	. = ..()
	dispensable_reagents = sort_list(dispensable_reagents, GLOBAL_PROC_REF(cmp_reagents_asc))
	if(emagged_reagents)
		emagged_reagents = sort_list(emagged_reagents, GLOBAL_PROC_REF(cmp_reagents_asc))
	if(upgrade_reagents)
		upgrade_reagents = sort_list(upgrade_reagents, GLOBAL_PROC_REF(cmp_reagents_asc))
	if(upgrade_reagents2)
		upgrade_reagents2 = sort_list(upgrade_reagents2, GLOBAL_PROC_REF(cmp_reagents_asc))
	if(upgrade_reagents3)
		upgrade_reagents3 = sort_list(upgrade_reagents3, GLOBAL_PROC_REF(cmp_reagents_asc))
	if(upgrade_reagents4)
		upgrade_reagents4 = sort_list(upgrade_reagents4, GLOBAL_PROC_REF(cmp_reagents_asc))
	create_reagents(CHEM_DISPENSER_BASE_STORAGE, NO_REACT)
	update_icon()
	build_game_recipes_cache()
	build_dispenser_recipes_cache()

/obj/machinery/chem_dispenser/Destroy()
	QDEL_NULL(beaker)
	QDEL_NULL(cell)
	return ..()

/obj/machinery/chem_dispenser/examine(mob/user)
	. = ..()
	if(panel_open)
		. += "<span class='notice'>Технический люк [src] открыт!</span>"
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>Статус-дисплей сообщает:\n\
		- Перезаряжается <b>[recharge_amount]</b> ед. заряда в цикл.\n\
		- Энергоэффективность повышена на <b>[round((powerefficiency*1000)-100, 1)]%</b>.</span>"

/obj/machinery/chem_dispenser/process()
	if (recharge_counter >= CHEM_DISPENSER_RECHARGE_INTERVAL)
		if(!is_operational() || !cell)
			if(use_power == ACTIVE_POWER_USE)
				use_power = IDLE_POWER_USE
			return
		var/usedpower = cell.give(recharge_amount)
		if(usedpower)
			use_power = ACTIVE_POWER_USE
		else
			use_power = IDLE_POWER_USE
		recharge_counter = 0
		return
	recharge_counter++

/obj/machinery/chem_dispenser/proc/display_beaker()
	var/mutable_appearance/b_o = beaker_overlay || mutable_appearance(icon, "disp_beaker")
	b_o.pixel_y = -4
	b_o.pixel_x = -7
	return b_o

/obj/machinery/chem_dispenser/proc/work_animation()
	if(working_state)
		flick(working_state,src)

/obj/machinery/chem_dispenser/power_change()
	..()
	icon_state = "[(nopower_state && !powered()) ? nopower_state : initial(icon_state)]"

/obj/machinery/chem_dispenser/update_overlays()
	. = ..()
	if(has_panel_overlay && panel_open)
		. += mutable_appearance(icon, "[initial(icon_state)]_panel-o")

	if(beaker)
		beaker_overlay = display_beaker()
		. += beaker_overlay

/obj/machinery/chem_dispenser/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		to_chat(user, "<span class='warning'>Протоколы [src] уже выведены из строя.</span>")
		return
	to_chat(user, "<span class='notice'>Вы взломали протоколы безопасности [src].</span>")
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	dispensable_reagents |= emagged_reagents // Include emagged reagents in the available list.
	obj_flags |= EMAGGED
	update_static_data_for_all_viewers()
	return TRUE

/obj/machinery/chem_dispenser/ex_act(severity, target, origin)
	if(severity < 3)
		..()

/obj/machinery/chem_dispenser/contents_explosion(severity, target, origin)
	..()
	if(beaker)
		beaker.ex_act(severity, target, origin)

/obj/machinery/chem_dispenser/Exited(atom/movable/A, atom/newloc)
	. = ..()
	if(A == beaker)
		beaker = null
		update_icon()

/obj/machinery/chem_dispenser/ui_interact(mob/user, datum/tgui/ui)
	if(HAS_TRAIT(user, TRAIT_PACIFISM) && !istype(src, /obj/machinery/chem_dispenser/drinks) && !istype(src, /obj/machinery/chem_dispenser/mutagen) && !istype(src, /obj/machinery/chem_dispenser/mutagensaltpeter))
		to_chat(user, span_notice("Я боюсь использовать [src]... Вдруг это приведёт к катастрофическим последствиям?"))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ChemDispenser", name)
		if(user.hallucinating())
			ui.set_autoupdate(FALSE) // Preserve immersion by keeping fake chemicals stable.
		ui.open()

		var/client/client = user.client
		if (CONFIG_GET(flag/use_exp_tracking) && client && client.get_exp_living(TRUE) < CHEM_DISPENSER_GRIEF_PLAYTIME_THRESHOLD)
			if(client.next_chem_grief_warning < world.time)
				if(!istype(src, /obj/machinery/chem_dispenser/drinks) && !istype(src, /obj/machinery/chem_dispenser/mutagen) && !istype(src, /obj/machinery/chem_dispenser/mutagensaltpeter) && !istype(src, /obj/machinery/chem_dispenser/abductor)) // These types are not used for grief.
					var/turf/T = get_turf(src)
					client.next_chem_grief_warning = world.time + CHEM_DISPENSER_GRIEF_ALERT_COOLDOWN
					message_antigrif("New player [ADMIN_LOOKUPFLW(user)] used \a [src] at [ADMIN_VERBOSEJMP(T)].")
					client.used_chem_dispenser = TRUE

/// Resolves ingredients to base reagents using all drink-dispenser reagent lists.
/obj/machinery/chem_dispenser/proc/get_global_base_ingredients(list/required_reagents, multiplier = 1, list/already_checked)
	if(!already_checked)
		already_checked = list()

	build_reagent_dispenser_mapping()

	var/list/result = list()
	for(var/reagent_type in required_reagents)
		var/needed_amount = required_reagents[reagent_type] * multiplier

		if((reagent_type in soda_dispenser_reagents) || (reagent_type in booze_dispenser_reagents))
			if(result[reagent_type])
				result[reagent_type] += needed_amount
			else
				result[reagent_type] = needed_amount
			continue

		if(reagent_type in already_checked)
			continue
		already_checked += reagent_type

		build_recipes_by_result_cache()
		var/list/recipes = recipes_by_result[reagent_type]
		if(length(recipes))
			for(var/recipe in recipes)
				var/datum/chemical_reaction/sub_R = recipe
				if(should_skip_recipe_for_dispenser(sub_R))
					continue
				var/yield_per_reaction = sub_R.results[reagent_type] || 1
				var/reactions_needed = CEILING(needed_amount / yield_per_reaction, 1)

				var/list/sub_ingredients = get_global_base_ingredients(sub_R.required_reagents, reactions_needed, already_checked)
				for(var/sub_type in sub_ingredients)
					if(result[sub_type])
						result[sub_type] += sub_ingredients[sub_type]
					else
						result[sub_type] = sub_ingredients[sub_type]
				break
		else
			if(result[reagent_type])
				result[reagent_type] += needed_amount
			else
				result[reagent_type] = needed_amount

	return result

/// Resolves ingredients to base reagents dispensable by this machine.
/obj/machinery/chem_dispenser/proc/get_base_ingredients(list/required_reagents, multiplier = 1, list/already_checked)
	if(!already_checked)
		already_checked = list()

	var/list/result = list()
	for(var/reagent_type in required_reagents)
		var/needed_amount = required_reagents[reagent_type] * multiplier

		if(reagent_type in dispensable_reagents)
			if(result[reagent_type])
				result[reagent_type] += needed_amount
			else
				result[reagent_type] = needed_amount
			continue

		if(reagent_type in already_checked)
			continue
		already_checked += reagent_type

		build_recipes_by_result_cache()
		var/list/recipes = recipes_by_result[reagent_type]
		if(length(recipes))
			for(var/recipe in recipes)
				var/datum/chemical_reaction/sub_R = recipe
				if(should_skip_recipe_for_dispenser(sub_R))
					continue
				// Drink dispensers: skip recipes with no locally available ingredients
				if(dispenser_type & DISPENSER_TYPE_DRINKS)
					var/any_local = FALSE
					for(var/req_type in sub_R.required_reagents)
						if((req_type in dispensable_reagents) || (emagged_reagents && (req_type in emagged_reagents)))
							any_local = TRUE
							break
					if(!any_local)
						continue
				var/yield_per_reaction = sub_R.results[reagent_type] || 1
				var/reactions_needed = CEILING(needed_amount / yield_per_reaction, 1)

				var/list/sub_ingredients = get_base_ingredients(sub_R.required_reagents, reactions_needed, already_checked)
				for(var/sub_type in sub_ingredients)
					if(result[sub_type])
						result[sub_type] += sub_ingredients[sub_type]
					else
						result[sub_type] = sub_ingredients[sub_type]
				break

	return result

/obj/machinery/chem_dispenser/proc/get_recipe_base_ingredients_data(datum/chemical_reaction/R)
	var/list/base = list()          // reagent_type -> total amount for 1x
	var/list/yield_info = list()    // reagent_type -> list(need, yield, input) for scaling
	var/list/checked = list()
	var/list/intermediates = list() // tree: list of list(name, amount, yield, parent) where parent is 1-indexed or 0 for top-level

	for(var/reagent_type in R.required_reagents)
		var/amount = R.required_reagents[reagent_type]
		resolve_to_base_with_yield(reagent_type, amount, base, yield_info, checked, 0, 1, 0, intermediates, 0)

	var/list/ingredients = list()
	build_reagent_dispenser_mapping()
	for(var/reagent_type in base)
		var/datum/reagent/reagent = GLOB.chemical_reagents_list[reagent_type]
		var/reagent_name = reagent ? reagent.name : "[reagent_type]"
		var/can_dispense = (reagent_type in dispensable_reagents)
		var/list/info = yield_info[reagent_type]
		var/source_flags = reagent_to_dispenser_type ? reagent_to_dispenser_type[reagent_type] : 0
		ingredients[reagent_name] = list(
			"amount" = base[reagent_type],
			"can_dispense" = can_dispense,
			"need" = info ? info["need"] : base[reagent_type],
			"yield" = info ? info["yield"] : 1,
			"input" = info ? info["input"] : base[reagent_type],
			"source_dispenser" = source_flags || 0
		)

	return list("ingredients" = ingredients, "intermediate_yields" = intermediates)

/// Returns multipliers (1..max_check) that produce no intermediate waste.
/obj/machinery/chem_dispenser/proc/compute_clean_batches(list/intermediate_yields, max_check = 100, max_clean = 4)
	if(!length(intermediate_yields))
		return null // No intermediates means all batches are clean.

	var/list/clean_batches = list()
	for(var/m in 1 to max_check)
		if(length(clean_batches) >= max_clean)
			break

		var/has_waste = FALSE
		var/list/reactions = list()

		for(var/i in 1 to length(intermediate_yields))
			var/list/entry = intermediate_yields[i]
			var/total_needed
			if(entry["parent"] == 0)
				total_needed = entry["amount"] * m
			else
				total_needed = reactions[entry["parent"]] * entry["amount"]

			var/reaction_count = CEILING(total_needed / entry["yield"], 1)
			reactions += reaction_count

			var/produced = reaction_count * entry["yield"]
			if(produced > total_needed)
				has_waste = TRUE
				break

		if(!has_waste)
			clean_batches += m

	return length(clean_batches) ? clean_batches : null

/obj/machinery/chem_dispenser/proc/resolve_to_base_with_yield(reagent_type, amount, list/base, list/yield_info, list/checked, parent_need = 0, parent_yield = 1, parent_input = 0, list/intermediates = null, parent_intermediate_idx = 0)
	if(reagent_type in dispensable_reagents)
		if(base[reagent_type])
			base[reagent_type] += amount
		else
			base[reagent_type] = amount
		if(parent_yield > 1)
			if(!yield_info[reagent_type])
				yield_info[reagent_type] = list("need" = parent_need, "yield" = parent_yield, "input" = parent_input)
		else
			if(!yield_info[reagent_type])
				yield_info[reagent_type] = list("need" = 1, "yield" = 1, "input" = amount)
		return TRUE

	if(reagent_type in checked)
		return FALSE
	checked += reagent_type

	build_recipes_by_result_cache()
	var/list/recipes = recipes_by_result[reagent_type]
	if(length(recipes))
		for(var/recipe in recipes)
			var/datum/chemical_reaction/sub_R = recipe
			if(should_skip_recipe_for_dispenser(sub_R))
				continue
			// Drink dispensers: skip recipes with no locally available ingredients
			if(dispenser_type & DISPENSER_TYPE_DRINKS)
				var/any_local = FALSE
				for(var/req_type in sub_R.required_reagents)
					if((req_type in dispensable_reagents) || (emagged_reagents && (req_type in emagged_reagents)))
						any_local = TRUE
						break
				if(!any_local)
					continue
			var/yield_per_reaction = sub_R.results[reagent_type] || 1
			var/reactions_needed = CEILING(amount / yield_per_reaction, 1)

			var/my_intermediate_idx = 0
			if(intermediates && yield_per_reaction > 1)
				var/datum/reagent/inter_reagent = GLOB.chemical_reagents_list[reagent_type]
				var/inter_name = inter_reagent ? inter_reagent.name : "[reagent_type]"
				intermediates += list(list("name" = inter_name, "amount" = amount, "yield" = yield_per_reaction, "parent" = parent_intermediate_idx))
				my_intermediate_idx = length(intermediates)

			for(var/sub_type in sub_R.required_reagents)
				var/sub_amount = sub_R.required_reagents[sub_type] * reactions_needed
				var/input_per_reaction = sub_R.required_reagents[sub_type]
				resolve_to_base_with_yield(sub_type, sub_amount, base, yield_info, checked, amount, yield_per_reaction, input_per_reaction, intermediates, my_intermediate_idx)
			return TRUE

	if(base[reagent_type])
		base[reagent_type] += amount
	else
		base[reagent_type] = amount
	if(!yield_info[reagent_type])
		yield_info[reagent_type] = list("need" = 1, "yield" = 1, "input" = amount)
	return FALSE

/obj/machinery/chem_dispenser/ui_static_data(mob/user)
	var/list/data = list()
	build_game_recipes_cache()
	build_dispenser_recipes_cache()
	data["gameRecipes"] = cached_dispenser_game_recipes

	data["dispenserType"] = dispenser_type
	data["isDrinkDispenser"] = !!(dispenser_type & DISPENSER_TYPE_DRINKS)

	var/chemicals[0]
	for(var/re in dispensable_reagents)
		var/datum/reagent/temp = GLOB.chemical_reagents_list[re]
		if(temp)
			var/category = get_reagent_category(re)
			chemicals.Add(list(list("title" = temp.name, "id" = ckey(temp.name), "pH" = temp.pH, "pHCol" = ConvertpHToCol(temp.pH), "reagentColor" = temp.color, "category" = category)))
	data["chemicals"] = chemicals

	var/datum/reagent/best_acid = null
	var/datum/reagent/best_base = null
	for(var/re in dispensable_reagents)
		var/datum/reagent/temp = GLOB.chemical_reagents_list[re]
		if(!temp)
			continue
		if(!best_acid || temp.pH < best_acid.pH)
			best_acid = temp
		if(!best_base || temp.pH > best_base.pH)
			best_base = temp
	data["phAcidName"] = best_acid?.name
	data["phAcidPH"] = best_acid?.pH
	data["phBaseName"] = best_base?.name
	data["phBasePH"] = best_base?.pH

	return data

/obj/machinery/chem_dispenser/ui_data(mob/user)
	var/data = list()
	data["amount"] = amount
	data["manipulatorTier"] = manipulator_tier
	data["isEmagged"] = !!(obj_flags & EMAGGED)
	data["energy"] = (cell && cell.charge) ? cell.charge * powerefficiency : 0
	data["maxEnergy"] = (cell && cell.maxcharge) ? cell.maxcharge * powerefficiency : 0
	data["storedVol"] = reagents.total_volume
	data["maxVol"] = reagents.maximum_volume
	data["isBeakerLoaded"] = beaker ? 1 : 0
	data["stepAmount"] = dispenseUnit
	data["canStore"] = canStore

	var/beakerContents[0]
	var/beakerCurrentVolume = 0
	if(beaker && beaker.reagents && beaker.reagents.reagent_list.len)
		for(var/datum/reagent/R in beaker.reagents.reagent_list)
			beakerContents.Add(list(list("name" = R.name, "id" = R.type, "volume" = round(R.volume, 0.01), "pH" = R.pH, "pHCol" = ConvertpHToCol(R.pH), "reagentColor" = R.color))) // Nested list prevents BYOND from merging the first entry.
			beakerCurrentVolume += R.volume
	data["beakerContents"] = beakerContents

	if (beaker)
		data["beakerCurrentVolume"] = round(beakerCurrentVolume, 0.01)
		data["beakerMaxVolume"] = beaker.volume
		data["beakerTransferAmounts"] = beaker.possible_transfer_amounts
		// pH precision scales with capacitor rating.
		var/rounded_ph = round(beaker.reagents.pH, 10**-(capacitor_rating+1))
		data["beakerCurrentpH"] = rounded_ph
		data["beakerCurrentpHCol"] = ConvertpHToCol(rounded_ph)

	else
		data["beakerCurrentVolume"] = null
		data["beakerMaxVolume"] = null
		data["beakerTransferAmounts"] = null
		data["beakerCurrentpH"] = null
		data["beakerCurrentpHCol"] = null

	if(user.hallucinating())
		var/chemicals[0]
		for(var/re in dispensable_reagents)
			var/datum/reagent/temp = GLOB.chemical_reagents_list[re]
			if(temp)
				var/chemname = temp.name
				if(prob(5))
					chemname = "[pick_list_replacements("hallucination.json", "chemicals")]"
				var/category = get_reagent_category(re)
				chemicals.Add(list(list("title" = chemname, "id" = ckey(temp.name), "pH" = temp.pH, "pHCol" = ConvertpHToCol(temp.pH), "reagentColor" = temp.color, "category" = category)))
		data["chemicals"] = chemicals

	var/mob/living/L = user
	if(istype(L) && L.client && L.client.prefs)
		data["classicView"] = L.client.prefs.chem_dispenser_classic_view
		data["useReagentColor"] = L.client.prefs.chem_dispenser_use_reagent_color
		data["showIcons"] = L.client.prefs.chem_dispenser_show_icons
		data["alphabeticalSort"] = L.client.prefs.chem_dispenser_alphabetical_sort
	else
		data["classicView"] = TRUE
		data["useReagentColor"] = TRUE
		data["showIcons"] = TRUE
		data["alphabeticalSort"] = TRUE

	data["recipes"] = saved_recipes

	data["recordingRecipe"] = recording_recipe

	var/storedContents[0]
	if(reagents.total_volume)
		for(var/datum/reagent/N in reagents.reagent_list)
			storedContents.Add(list(list("name" = N.name, "id" = N.type, "volume" = N.volume, "pH" = N.pH, "pHCol" = ConvertpHToCol(N.pH), "reagentColor" = N.color)))
	data["storedContents"] = storedContents

	return data

/// Determines which dispenser types are needed for a recipe.
/obj/machinery/chem_dispenser/proc/analyze_recipe_dispenser_requirements(datum/chemical_reaction/R)
	var/list/result = list(
		"requires_soda" = FALSE,
		"requires_booze" = FALSE,
		"requires_chem" = FALSE,
		"requires_enzyme" = FALSE,
		"requires_external" = FALSE
	)

	if(length(R.required_catalysts))
		for(var/catalyst_type in R.required_catalysts)
			if(ispath(catalyst_type, /datum/reagent/consumable/enzyme))
				result["requires_enzyme"] = TRUE
				break

	var/list/all_base_reagents = get_global_base_ingredients(R.required_reagents, 1)

	for(var/reagent_type in all_base_reagents)
		var/dispenser_flags = reagent_to_dispenser_type[reagent_type]

		if(!dispenser_flags)
			result["requires_chem"] = TRUE
		else
			if(dispenser_flags & DISPENSER_TYPE_SODA)
				result["requires_soda"] = TRUE
			if(dispenser_flags & DISPENSER_TYPE_BOOZE)
				result["requires_booze"] = TRUE

	return result

/// Builds the instance cache for this dispenser's recipe data.
/obj/machinery/chem_dispenser/proc/build_dispenser_recipes_cache()
	var/current_hash = "[length(dispensable_reagents)]:[jointext(dispensable_reagents, "|")]"
	if(cached_dispenser_game_recipes && current_hash == cached_dispensable_reagents_hash)
		return

	if(!shared_dispenser_recipe_caches)
		shared_dispenser_recipe_caches = list()
	if(shared_dispenser_recipe_caches[current_hash])
		cached_dispenser_game_recipes = shared_dispenser_recipe_caches[current_hash]
		cached_dispensable_reagents_hash = current_hash
		return

	cached_dispenser_game_recipes = list()
	cached_dispensable_reagents_hash = current_hash

	// Assign upgrade tiers first so RefreshParts() reagents keep proper tier
	var/list/reagent_tiers = list()
	if(upgrade_reagents)
		for(var/r in upgrade_reagents)
			if(!(r in reagent_tiers))
				reagent_tiers[r] = 2
	if(upgrade_reagents2)
		for(var/r in upgrade_reagents2)
			if(!(r in reagent_tiers))
				reagent_tiers[r] = 3
	if(upgrade_reagents3)
		for(var/r in upgrade_reagents3)
			if(!(r in reagent_tiers))
				reagent_tiers[r] = 4
	if(upgrade_reagents4)
		for(var/r in upgrade_reagents4)
			if(!(r in reagent_tiers))
				reagent_tiers[r] = 5
	if(emagged_reagents)
		for(var/r in emagged_reagents)
			if(!(r in reagent_tiers))
				reagent_tiers[r] = 6
	for(var/r in dispensable_reagents)
		if(!(r in reagent_tiers))
			reagent_tiers[r] = 1

	for(var/recipe_name in cached_game_recipes_data)
		var/list/cached_recipe = cached_game_recipes_data[recipe_name]
		var/datum/chemical_reaction/R = GLOB.normalized_chemical_reactions_list[recipe_name]

		var/list/base_data = get_recipe_base_ingredients_data(R)
		var/list/base_ingredients = base_data["ingredients"]
		var/list/intermediate_yields = base_data["intermediate_yields"]

		var/list/cross_dispenser = null
		if(dispenser_type & DISPENSER_TYPE_DRINKS)
			cross_dispenser = analyze_recipe_dispenser_requirements(R)

		var/can_make = TRUE
		for(var/reagent_name in base_ingredients)
			if(!base_ingredients[reagent_name]["can_dispense"])
				can_make = FALSE
				break

		var/list/enriched_sub_recipes = list()
		var/list/original_sub_recipes = cached_recipe["sub_recipes"]
		if(length(original_sub_recipes))
			for(var/reagent_name in original_sub_recipes)
				var/list/sub_data = original_sub_recipes[reagent_name]
				var/sub_recipe_name = sub_data["recipe_name"]
				var/datum/chemical_reaction/sub_R = GLOB.normalized_chemical_reactions_list[sub_recipe_name]
				if(!sub_R)
					enriched_sub_recipes[reagent_name] = sub_data
					continue

				var/list/sub_base = get_base_ingredients(sub_R.required_reagents, 1)
				var/list/sub_base_with_info = list()
				for(var/sub_reagent_type in sub_base)
					var/datum/reagent/sub_reagent = GLOB.chemical_reagents_list[sub_reagent_type]
					var/sub_reagent_name = sub_reagent ? sub_reagent.name : "[sub_reagent_type]"
					var/sub_can_dispense = (sub_reagent_type in dispensable_reagents)
					var/sub_source_flags = reagent_to_dispenser_type ? reagent_to_dispenser_type[sub_reagent_type] : 0
					sub_base_with_info[sub_reagent_name] = list(
						"amount" = sub_base[sub_reagent_type],
						"can_dispense" = sub_can_dispense,
						"source_dispenser" = sub_source_flags || 0
					)

				var/result_type = null
				for(var/rtype in sub_R.results)
					var/datum/reagent/check = GLOB.chemical_reagents_list[rtype]
					if(check && check.name == reagent_name)
						result_type = rtype
						break
				var/sub_result_amount = result_type ? (sub_R.results[result_type] || 1) : 1

				enriched_sub_recipes[reagent_name] = list(
					"recipe_name" = sub_data["recipe_name"],
					"required" = sub_data["required"],
					"temp" = sub_data["temp"],
					"is_cold" = sub_data["is_cold"],
					"base_ingredients" = sub_base_with_info,
					"result_amount" = sub_result_amount
				)

		var/recipe_tier = calculate_recipe_tier(R, reagent_tiers)

		var/list/enriched_alt_recipes = list()
		var/list/cached_alt_recipes = cached_recipe["alt_recipes"]
		if(length(cached_alt_recipes))
			var/alt_idx = 1
			for(var/list/alt_recipe as anything in cached_alt_recipes)
				var/datum/chemical_reaction/alt_R = alt_recipe_datums["[recipe_name]|[alt_idx]"]
				alt_idx++
				if(!alt_R)
					continue

				var/list/alt_base_data = get_recipe_base_ingredients_data(alt_R)
				var/list/alt_base_ingredients = alt_base_data["ingredients"]
				var/list/alt_intermediate_yields = alt_base_data["intermediate_yields"]

				var/alt_can_make = TRUE
				for(var/alt_reagent_name in alt_base_ingredients)
					if(!alt_base_ingredients[alt_reagent_name]["can_dispense"])
						alt_can_make = FALSE
						break

				var/list/alt_enriched_sub_recipes = list()
				var/list/alt_original_sub_recipes = alt_recipe["sub_recipes"]
				if(length(alt_original_sub_recipes))
					for(var/alt_reagent_name in alt_original_sub_recipes)
						var/list/alt_sub_data = alt_original_sub_recipes[alt_reagent_name]
						var/alt_sub_recipe_name = alt_sub_data["recipe_name"]
						var/datum/chemical_reaction/alt_sub_R = GLOB.normalized_chemical_reactions_list[alt_sub_recipe_name]
						if(!alt_sub_R)
							alt_enriched_sub_recipes[alt_reagent_name] = alt_sub_data
							continue

						var/list/alt_sub_base = get_base_ingredients(alt_sub_R.required_reagents, 1)
						var/list/alt_sub_base_with_info = list()
						for(var/alt_sub_reagent_type in alt_sub_base)
							var/datum/reagent/alt_sub_reagent = GLOB.chemical_reagents_list[alt_sub_reagent_type]
							var/alt_sub_reagent_name = alt_sub_reagent ? alt_sub_reagent.name : "[alt_sub_reagent_type]"
							var/alt_sub_can_dispense = (alt_sub_reagent_type in dispensable_reagents)
							var/alt_sub_source_flags = reagent_to_dispenser_type ? reagent_to_dispenser_type[alt_sub_reagent_type] : 0
							alt_sub_base_with_info[alt_sub_reagent_name] = list(
								"amount" = alt_sub_base[alt_sub_reagent_type],
								"can_dispense" = alt_sub_can_dispense,
								"source_dispenser" = alt_sub_source_flags || 0
							)

						var/alt_result_type = null
						for(var/rtype in alt_sub_R.results)
							var/datum/reagent/check = GLOB.chemical_reagents_list[rtype]
							if(check && check.name == alt_reagent_name)
								alt_result_type = rtype
								break
						var/alt_sub_result_amount = alt_result_type ? (alt_sub_R.results[alt_result_type] || 1) : 1

						alt_enriched_sub_recipes[alt_reagent_name] = list(
							"recipe_name" = alt_sub_data["recipe_name"],
							"required" = alt_sub_data["required"],
							"temp" = alt_sub_data["temp"],
							"is_cold" = alt_sub_data["is_cold"],
							"base_ingredients" = alt_sub_base_with_info,
							"result_amount" = alt_sub_result_amount
						)

				var/alt_recipe_tier = calculate_recipe_tier(alt_R, reagent_tiers)

				enriched_alt_recipes += list(list(
					"required" = alt_recipe["required"],
					"catalysts" = alt_recipe["catalysts"],
					"temp" = alt_recipe["temp"],
					"is_cold" = alt_recipe["is_cold"],
					"can_make" = alt_can_make,
					"tier" = alt_recipe_tier,
					"result_amount" = alt_recipe["result_amount"],
					"sub_recipes" = alt_enriched_sub_recipes,
					"base_ingredients" = alt_base_ingredients,
					"intermediate_yields" = alt_intermediate_yields,
					"clean_batches" = compute_clean_batches(alt_intermediate_yields),
					"is_fermichem" = alt_recipe["is_fermichem"],
					"optimal_temp_min" = alt_recipe["optimal_temp_min"],
					"optimal_temp_max" = alt_recipe["optimal_temp_max"],
					"explode_temp" = alt_recipe["explode_temp"],
					"optimal_ph_min" = alt_recipe["optimal_ph_min"],
					"optimal_ph_max" = alt_recipe["optimal_ph_max"],
					"react_ph_lim" = alt_recipe["react_ph_lim"],
					"purity_min" = alt_recipe["purity_min"],
					"thermic_constant" = alt_recipe["thermic_constant"],
					"h_ion_release" = alt_recipe["h_ion_release"],
					"fermi_explode" = alt_recipe["fermi_explode"]
				))

		cached_dispenser_game_recipes[recipe_name] = list(
			"required" = cached_recipe["required"],
			"catalysts" = cached_recipe["catalysts"],
			"category" = cached_recipe["category"],
			"temp" = cached_recipe["temp"],
			"is_cold" = cached_recipe["is_cold"],
			"can_make" = can_make,
			"tier" = recipe_tier,
			"desc" = cached_recipe["desc"],
			"result_amount" = cached_recipe["result_amount"],
			"sub_recipes" = enriched_sub_recipes,
			"base_ingredients" = base_ingredients,
			"intermediate_yields" = intermediate_yields,
			"clean_batches" = compute_clean_batches(intermediate_yields),
			"is_fermichem" = cached_recipe["is_fermichem"],
			"optimal_temp_min" = cached_recipe["optimal_temp_min"],
			"optimal_temp_max" = cached_recipe["optimal_temp_max"],
			"explode_temp" = cached_recipe["explode_temp"],
			"optimal_ph_min" = cached_recipe["optimal_ph_min"],
			"optimal_ph_max" = cached_recipe["optimal_ph_max"],
			"react_ph_lim" = cached_recipe["react_ph_lim"],
			"purity_min" = cached_recipe["purity_min"],
			"thermic_constant" = cached_recipe["thermic_constant"],
			"h_ion_release" = cached_recipe["h_ion_release"],
			"fermi_explode" = cached_recipe["fermi_explode"],
			"is_extract_recipe" = cached_recipe["is_extract_recipe"],
			"extract_container_name" = cached_recipe["extract_container_name"],
			"alt_recipes" = enriched_alt_recipes,
			"cross_dispenser" = cross_dispenser
		)

	shared_dispenser_recipe_caches[current_hash] = cached_dispenser_game_recipes

/obj/machinery/chem_dispenser/ui_act(action, params)
	if(..())
		return
	// Rate-limit recipe actions to prevent rapid-click spam.
	var/static/list/recipe_dispense_actions = list("dispense_recipe", "dispense_recipe_game", "dispense_recipe_partial", "dispense_sub_recipe", "dispense_final_step")
	if(action in recipe_dispense_actions)
		if(!COOLDOWN_FINISHED(src, dispense_cooldown))
			return
	switch(action)
		if("toggle_view")
			var/mob/living/L = usr
			if(istype(L) && L.client && L.client.prefs)
				L.client.prefs.chem_dispenser_classic_view = !L.client.prefs.chem_dispenser_classic_view
				L.client.prefs.save_preferences()
			. = TRUE
		if("toggle_color_mode")
			var/mob/living/L = usr
			if(istype(L) && L.client && L.client.prefs)
				L.client.prefs.chem_dispenser_use_reagent_color = !L.client.prefs.chem_dispenser_use_reagent_color
				L.client.prefs.save_preferences()
			. = TRUE
		if("toggle_icons")
			var/mob/living/L = usr
			if(istype(L) && L.client && L.client.prefs)
				L.client.prefs.chem_dispenser_show_icons = !L.client.prefs.chem_dispenser_show_icons
				L.client.prefs.save_preferences()
			. = TRUE
		if("toggle_sort")
			var/mob/living/L = usr
			if(istype(L) && L.client && L.client.prefs)
				L.client.prefs.chem_dispenser_alphabetical_sort = !L.client.prefs.chem_dispenser_alphabetical_sort
				L.client.prefs.save_preferences()
			. = TRUE
		if("amount")
			if(!is_operational() || QDELETED(beaker))
				return
			var/target = text2num(params["target"])
			SetAmount(target)
			work_animation()
			. = TRUE
		if("dispense")
			if(!is_operational() || QDELETED(cell))
				return
			var/reagent_name = params["reagent"]
			if(!recording_recipe)
				var/reagent = GLOB.name2reagent[reagent_name]
				if(beaker && dispensable_reagents.Find(reagent))
					var/datum/reagents/R = beaker.reagents
					var/free = R.maximum_volume - R.total_volume
					var/actual = min(amount, (cell.charge * powerefficiency)*10, free)
					if(!cell.use(actual / powerefficiency))
						say("Недостаточно энергии для задачи!")
						return
					R.add_reagent(reagent, actual)
					log_reagent("DISPENSER: ([COORD(src)]) ([REF(src)]) [key_name(usr)] dispensed [actual] of [reagent] to [beaker] ([REF(beaker)]).")
					work_animation()
			else
				recording_recipe[reagent_name] += amount
			. = TRUE
		if("dispense_ph")
			if(!is_operational() || QDELETED(cell) || !beaker || recording_recipe)
				return
			var/reagent_type
			if(params["type"] == "acid")
				var/best_ph = INFINITY
				for(var/re in dispensable_reagents)
					var/datum/reagent/temp = GLOB.chemical_reagents_list[re]
					if(temp && temp.pH < best_ph)
						best_ph = temp.pH
						reagent_type = re
			else
				var/best_ph = -INFINITY
				for(var/re in dispensable_reagents)
					var/datum/reagent/temp = GLOB.chemical_reagents_list[re]
					if(temp && temp.pH > best_ph)
						best_ph = temp.pH
						reagent_type = re
			if(!reagent_type)
				say("Реагент недоступен!")
				return
			var/datum/reagents/R = beaker.reagents
			var/free = R.maximum_volume - R.total_volume
			if(free < 1)
				say("Ёмкость заполнена!")
				return
			if(!cell.use(1 / powerefficiency))
				say("Недостаточно энергии!")
				return
			R.add_reagent(reagent_type, 1)
			work_animation()
			. = TRUE
		if("remove")
			if(!is_operational() || recording_recipe || !beaker)
				return
			var/remove_amount
			if(params["all"])
				remove_amount = beaker.reagents.total_volume
			else
				remove_amount = text2num(params["amount"])
			if(remove_amount > 0)
				beaker.reagents.remove_all(remove_amount)
				work_animation()
			. = TRUE
		if("eject")
			replace_beaker(usr)
			. = TRUE
		if("dispense_recipe")
			if(!is_operational() || QDELETED(cell))
				return
			var/list/chemicals_to_dispense = saved_recipes[params["recipe"]]
			if(!LAZYLEN(chemicals_to_dispense))
				return
			var/list/logstring = list()
			var/earlyabort = FALSE
			var/datum/reagents/BR = !recording_recipe && beaker ? beaker.reagents : null
			for(var/key in chemicals_to_dispense)
				var/reagent = GLOB.name2reagent[translate_legacy_chem_id(key)]
				var/dispense_amount = chemicals_to_dispense[key]
				logstring += "[reagent] = [dispense_amount]"
				if(!dispensable_reagents.Find(reagent))
					break
				if(!recording_recipe)
					if(!BR)
						return
					var/free = BR.maximum_volume - BR.total_volume
					var/actual = min(dispense_amount, (cell.charge * powerefficiency)*10, free)
					if(actual)
						if(!cell.use(actual / powerefficiency))
							say("Недостаточно энергии для задачи!")
							earlyabort = TRUE
							break
						BR.add_reagent(reagent, actual, no_react = TRUE)
						work_animation()
				else
					recording_recipe[key] += dispense_amount

			if(BR)
				BR.handle_reactions()

			logstring = logstring.Join(", ")
			if(!recording_recipe)
				log_reagent("DISPENSER: [key_name(usr)] dispensed recipe [params["recipe"]] with chemicals [logstring] to [beaker] ([REF(beaker)])[earlyabort? " (aborted early)":""]")
			. = TRUE
		if("dispense_recipe_game")
			if(!is_operational() || QDELETED(cell) || !beaker)
				return
			var/recipe_name = params["recipe"]
			var/multiplier = clamp(text2num(params["multiplier"]) || 1, 1, CHEM_RECIPE_MAX_BATCH)
			var/alt_index = text2num(params["alt_index"]) || 0

			var/datum/chemical_reaction/R
			var/list/recipe_data = cached_dispenser_game_recipes[recipe_name]
			if(!recipe_data)
				return
			if(alt_index > 0)
				R = alt_recipe_datums["[recipe_name]|[alt_index]"]
			else
				R = GLOB.normalized_chemical_reactions_list[recipe_name]
			if(!R)
				return

			var/recipe_tier
			if(alt_index > 0)
				var/list/alt_recipes = recipe_data["alt_recipes"]
				if(!length(alt_recipes) || alt_index > length(alt_recipes))
					return
				recipe_tier = alt_recipes[alt_index]["tier"] || 0
			else
				recipe_tier = recipe_data["tier"] || 0

			if(recipe_tier >= CHEM_RECIPE_EMAG_TIER)
				if(!(obj_flags & EMAGGED))
					say("Требуется взлом протоколов безопасности!")
					return

			else if(!(dispenser_type & DISPENSER_TYPE_DRINKS) && recipe_tier > manipulator_tier)
				say("Недостаточный уровень манипулятора для этого рецепта!")
				return

			var/list/base_ingredients = get_base_ingredients(R.required_reagents, multiplier)
			if(!length(base_ingredients))
				say("Невозможно выдать ингредиенты для этого рецепта!")
				return

			var/list/logstring = list()
			var/datum/reagents/BR = beaker.reagents
			for(var/reagent_type in base_ingredients)
				var/needed_amount = base_ingredients[reagent_type]
				var/free = BR.maximum_volume - BR.total_volume
				var/actual = min(needed_amount, (cell.charge * powerefficiency) * 10, free)
				if(actual <= 0)
					continue
				if(!cell.use(actual / powerefficiency))
					say("Недостаточно энергии!")
					break
				BR.add_reagent(reagent_type, actual, no_react = TRUE)
				logstring += "[reagent_type] = [actual]"
			BR.handle_reactions()
			work_animation()
			log_reagent("DISPENSER: [key_name(usr)] dispensed game recipe [recipe_name][alt_index ? " alt#[alt_index]" : ""] x[multiplier] with chemicals [logstring.Join(", ")] to [beaker] ([REF(beaker)])")
			. = TRUE
		if("dispense_recipe_partial")
			if(!is_operational() || QDELETED(cell) || !beaker)
				return
			var/recipe_name = params["recipe"]
			var/multiplier = clamp(text2num(params["multiplier"]) || 1, 1, CHEM_RECIPE_MAX_BATCH)
			var/alt_index = text2num(params["alt_index"]) || 0

			var/datum/chemical_reaction/R
			var/list/recipe_data = cached_dispenser_game_recipes[recipe_name]
			if(!recipe_data)
				return
			if(alt_index > 0)
				R = alt_recipe_datums["[recipe_name]|[alt_index]"]
			else
				R = GLOB.normalized_chemical_reactions_list[recipe_name]
			if(!R)
				return

			var/list/base_ingredients = get_base_ingredients(R.required_reagents, multiplier)
			if(!length(base_ingredients))
				say("Невозможно выдать ингредиенты для этого рецепта!")
				return

			var/list/logstring = list()
			var/dispensed_any = FALSE
			var/datum/reagents/BR = beaker.reagents
			for(var/reagent_type in base_ingredients)
				if(!(reagent_type in dispensable_reagents))
					continue

				var/needed_amount = base_ingredients[reagent_type]
				var/current_amount = BR.get_reagent_amount(reagent_type)
				if(current_amount >= needed_amount)
					continue

				var/to_dispense = needed_amount - current_amount
				var/free = BR.maximum_volume - BR.total_volume
				var/actual = min(to_dispense, (cell.charge * powerefficiency) * 10, free)
				if(actual <= 0)
					continue
				if(!cell.use(actual / powerefficiency))
					say("Недостаточно энергии!")
					break
				BR.add_reagent(reagent_type, actual, no_react = TRUE)
				logstring += "[reagent_type] = [actual]"
				dispensed_any = TRUE
			if(dispensed_any)
				BR.handle_reactions()
				work_animation()
				log_reagent("DISPENSER: [key_name(usr)] partial dispensed game recipe [recipe_name][alt_index ? " alt#[alt_index]" : ""] x[multiplier] with chemicals [logstring.Join(", ")] to [beaker] ([REF(beaker)])")
			else
				say("Нет доступных ингредиентов для выдачи!")
			. = TRUE
		if("dispense_sub_recipe")
			if(!is_operational() || QDELETED(cell) || !beaker)
				return
			var/recipe_name = params["recipe"]
			var/sub_reagent_name = params["sub_reagent"]
			var/multiplier = clamp(text2num(params["multiplier"]) || 1, 1, CHEM_RECIPE_MAX_BATCH)
			var/alt_index = text2num(params["alt_index"]) || 0

			var/datum/chemical_reaction/R
			if(alt_index > 0)
				R = alt_recipe_datums["[recipe_name]|[alt_index]"]
			else
				R = GLOB.normalized_chemical_reactions_list[recipe_name]
			if(!R)
				return
			var/list/recipe_data_sub = cached_dispenser_game_recipes[recipe_name]
			if(!recipe_data_sub)
				return
			var/check_tier
			if(alt_index > 0)
				var/list/alt_recipes = recipe_data_sub["alt_recipes"]
				if(!length(alt_recipes) || alt_index > length(alt_recipes))
					return
				check_tier = alt_recipes[alt_index]["tier"] || 0
			else
				check_tier = recipe_data_sub["tier"] || 0

			if(!(dispenser_type & DISPENSER_TYPE_DRINKS) && check_tier > manipulator_tier)
				say("Недостаточный уровень манипулятора для этого рецепта!")
				return

			var/target_reagent_type = null
			for(var/reagent_type in R.required_reagents)
				var/datum/reagent/check = GLOB.chemical_reagents_list[reagent_type]
				if(check && check.name == sub_reagent_name)
					target_reagent_type = reagent_type
					break

			if(!target_reagent_type)
				return

			build_recipes_by_result_cache()
			var/list/recipes = recipes_by_result[target_reagent_type]
			if(!length(recipes))
				return

			var/datum/chemical_reaction/sub_R = null
			for(var/recipe in recipes)
				var/datum/chemical_reaction/check_R = recipe
				if(!check_R.is_secret)
					sub_R = check_R
					break

			if(!sub_R)
				return

			var/needed_amount = R.required_reagents[target_reagent_type] * multiplier
			var/yield_per_reaction = sub_R.results[target_reagent_type] || 1
			var/reactions_needed = CEILING(needed_amount / yield_per_reaction, 1)

			var/list/base_ingredients = get_base_ingredients(sub_R.required_reagents, reactions_needed)
			if(!length(base_ingredients))
				say("Невозможно выдать ингредиенты!")
				return

			var/list/logstring = list()
			var/datum/reagents/BR = beaker.reagents
			for(var/reagent_type in base_ingredients)
				var/reagent_amount = base_ingredients[reagent_type]
				var/free = BR.maximum_volume - BR.total_volume
				var/actual = min(reagent_amount, (cell.charge * powerefficiency) * 10, free)
				if(actual <= 0)
					continue
				if(!cell.use(actual / powerefficiency))
					say("Недостаточно энергии!")
					break
				BR.add_reagent(reagent_type, actual, no_react = TRUE)
				logstring += "[reagent_type] = [actual]"
			BR.handle_reactions()
			work_animation()
			log_reagent("DISPENSER: [key_name(usr)] dispensed sub-recipe [sub_reagent_name] for [recipe_name][alt_index ? " alt#[alt_index]" : ""] x[multiplier] with chemicals [logstring.Join(", ")] to [beaker] ([REF(beaker)])")
			. = TRUE
		if("dispense_final_step")
			if(!is_operational() || QDELETED(cell) || !beaker)
				return
			var/recipe_name = params["recipe"]
			var/multiplier = clamp(text2num(params["multiplier"]) || 1, 1, CHEM_RECIPE_MAX_BATCH)
			var/alt_index = text2num(params["alt_index"]) || 0

			var/datum/chemical_reaction/R
			if(alt_index > 0)
				R = alt_recipe_datums["[recipe_name]|[alt_index]"]
			else
				R = GLOB.normalized_chemical_reactions_list[recipe_name]
			if(!R)
				return
			var/list/recipe_data_final = cached_dispenser_game_recipes[recipe_name]
			if(!recipe_data_final)
				return
			var/check_tier
			if(alt_index > 0)
				var/list/alt_recipes = recipe_data_final["alt_recipes"]
				if(!length(alt_recipes) || alt_index > length(alt_recipes))
					return
				check_tier = alt_recipes[alt_index]["tier"] || 0
			else
				check_tier = recipe_data_final["tier"] || 0
			if(check_tier > manipulator_tier)
				say("Недостаточный уровень манипулятора для этого рецепта!")
				return

			build_dispenser_recipes_cache()
			var/list/recipe_data = cached_dispenser_game_recipes[recipe_name]
			var/list/this_recipe_sub_recipes
			if(alt_index > 0)
				var/list/alt_recipes_data = recipe_data ? recipe_data["alt_recipes"] : list()
				this_recipe_sub_recipes = (length(alt_recipes_data) >= alt_index) ? alt_recipes_data[alt_index]["sub_recipes"] : list()
			else
				this_recipe_sub_recipes = recipe_data ? recipe_data["sub_recipes"] : list()

			var/list/logstring = list()
			var/datum/reagents/BR = beaker.reagents
			for(var/reagent_type in R.required_reagents)
				var/can_dispense = (reagent_type in dispensable_reagents)
				var/datum/reagent/reagent = GLOB.chemical_reagents_list[reagent_type]
				var/reagent_name = reagent ? reagent.name : null

				if(reagent_name && this_recipe_sub_recipes[reagent_name] && !can_dispense)
					continue
				if(!can_dispense)
					continue

				var/needed_amount = R.required_reagents[reagent_type] * multiplier
				var/free = BR.maximum_volume - BR.total_volume
				var/actual = min(needed_amount, (cell.charge * powerefficiency) * 10, free)
				if(actual <= 0)
					continue
				if(!cell.use(actual / powerefficiency))
					say("Недостаточно энергии!")
					break
				BR.add_reagent(reagent_type, actual, no_react = TRUE)
				logstring += "[reagent_type] = [actual]"
			BR.handle_reactions()
			work_animation()
			log_reagent("DISPENSER: [key_name(usr)] dispensed final step for [recipe_name][alt_index ? " alt#[alt_index]" : ""] x[multiplier] with chemicals [logstring.Join(", ")] to [beaker] ([REF(beaker)])")
			. = TRUE
		if("clear_recipes")
			if(!is_operational())
				return
			var/yesno = tgui_alert(usr, "Очистить все рецепты?", name, list("Да", "Нет"))
			if(yesno != "Да")
				return
			if(!usr.canUseTopic(src, !hasSiliconAccessInArea(usr)))
				return
			saved_recipes = list()

			. = TRUE
		if("delete_recipe")
			if(!is_operational())
				return
			var/recipe_name = params["recipe"]
			if(recipe_name && saved_recipes[recipe_name])
				saved_recipes -= recipe_name
	
				log_reagent("DISPENSER: [key_name(usr)] deleted recipe [recipe_name]")
			. = TRUE
		if("record_recipe")
			if(!is_operational())
				return
			recording_recipe = list()
			. = TRUE
		if("save_recording")
			if(!is_operational())
				return
			var/name = stripped_input(usr,"Имя","Введите название рецепта", "Рецепт", MAX_NAME_LEN)
			if(!usr.canUseTopic(src, !hasSiliconAccessInArea(usr)))
				return
			if(saved_recipes[name] && tgui_alert(usr, "Рецепт \"[name]\" уже существует, хотите перезаписать?", src.name, list("Да", "Нет")) != "Да")
				return
			if(name && recording_recipe)
				var/list/logstring = list()
				for(var/reagent in recording_recipe)
					var/reagent_id = GLOB.name2reagent[translate_legacy_chem_id(reagent)]
					logstring += "[reagent_id] = [recording_recipe[reagent]]"
					if(!dispensable_reagents.Find(reagent_id))
						visible_message("<span class='warning'>[src] жужжит.</span>", "<span class='hear'>Вы слышите слабое жужжание.</span>")
						to_chat(usr, "<span class ='danger'>[src] не может найти <b>[reagent]</b>!</span>")
						playsound(src, 'sound/machines/buzz-two.ogg', 50, TRUE)
						return
				saved_recipes[name] = recording_recipe
	
				logstring = logstring.Join(", ")
				recording_recipe = null
				log_reagent("DISPENSER: [key_name(usr)] recorded recipe [name] with chemicals [logstring]")
				. = TRUE
		if("cancel_recording")
			if(!is_operational())
				return
			recording_recipe = null
			. = TRUE

		// Store and withdraw reagents.
		if("store")
			if(!is_operational() || QDELETED(cell))
				return
			if(!beaker)
				return
			if(recording_recipe)
				say("Хранилище недоступно во время записи рецепта!")
				return
			if(beaker.reagents.fermiIsReacting)
				say("Хранилище недоступно во время реакции веществ!")
				return
			var/reagent = text2path(params["id"])
			var/datum/reagent/R = beaker.reagents.has_reagent(reagent)
			var/freeSpace = reagents.maximum_volume - reagents.total_volume
			if(freeSpace <= 0)
				say("В хранилище нет места!")
				return
			var/potentialAmount = min(amount, R.volume, freeSpace)
			beaker.reagents.trans_id_to(src, R.type, potentialAmount)
			work_animation()
			. = TRUE

		if("unstore")
			if(!is_operational() || QDELETED(cell))
				return
			if(!beaker)
				return
			if(recording_recipe)
				say("Невозможно выдать реагенты!")
				return
			var/reagent = text2path(params["id"])
			var/datum/reagent/R = reagents.has_reagent(reagent)
			reagents.trans_id_to(beaker, R.type, amount)
			work_animation()
			. = TRUE

		if("store_all")
			if(!is_operational() || QDELETED(cell))
				return
			if(!beaker || !canStore)
				return
			if(recording_recipe)
				say("Хранилище недоступно во время записи рецепта!")
				return
			if(beaker.reagents.fermiIsReacting)
				say("Хранилище недоступно во время реакции веществ!")
				return
			if(!beaker.reagents.total_volume)
				return
			beaker.reagents.trans_to(src, beaker.reagents.total_volume, no_react = TRUE)
			work_animation()
			. = TRUE

		if("unstore_all")
			if(!is_operational() || QDELETED(cell))
				return
			if(!beaker)
				return
			if(recording_recipe)
				say("Невозможно выдать реагенты!")
				return
			if(!reagents.total_volume)
				return
			reagents.trans_to(beaker, reagents.total_volume)
			work_animation()
			. = TRUE

		if("clear_storage")
			if(!is_operational())
				return
			if(!reagents.total_volume)
				return
			reagents.remove_all(reagents.total_volume)
			. = TRUE
	// Start cooldown on successful recipe dispense action
	if(. && (action in recipe_dispense_actions))
		COOLDOWN_START(src, dispense_cooldown, 2)

/obj/machinery/chem_dispenser/proc/SetAmount(inputAmount)
	if(inputAmount <= 1) // Always allow 1u dosage.
		amount = max(inputAmount, 1)
		return
	if(inputAmount % 5 == 0) // Always allow 5u values.
		amount = inputAmount
		return
	inputAmount -= inputAmount % dispenseUnit
	if(inputAmount == 0) // Prevent ghost entries in macros.
		amount = dispenseUnit
		return
	amount = inputAmount

/obj/machinery/chem_dispenser/attackby(obj/item/I, mob/user, params)
	if(default_unfasten_wrench(user, I))
		return
	if(default_deconstruction_screwdriver(user, icon_state, icon_state, I))
		update_icon()
		return
	if(default_deconstruction_crowbar(I))
		return
	if(istype(I, /obj/item/reagent_containers) && !(I.item_flags & ABSTRACT) && I.is_open_container() || is_type_in_list(I, CLOSED_CONTAINERS_OPERABLE))
		var/obj/item/reagent_containers/B = I
		. = TRUE // No afterattack.
		if(!user.transferItemToLoc(B, src))
			return
		replace_beaker(user, B)
		to_chat(user, "<span class='notice'>Вы вставили [B] в [src].</span>")
		updateUsrDialog()
	else if(user.a_intent != INTENT_HARM && !istype(I, /obj/item/card/emag))
		to_chat(user, "<span class='warning'>Вы не можете вставить [I] в [src]!</span>")
		return ..()
	else
		return ..()

/obj/machinery/chem_dispenser/get_cell()
	return cell

/obj/machinery/chem_dispenser/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	var/list/datum/reagents/R = list()
	var/total = min(rand(7,15), FLOOR(cell.charge*powerefficiency, 1))
	var/datum/reagents/Q = new(total*10)
	if(beaker && beaker.reagents)
		R += beaker.reagents
	for(var/i in 1 to total)
		Q.add_reagent(pick(dispensable_reagents), 10)
	R += Q
	chem_splash(get_turf(src), 3, R)
	if(beaker && beaker.reagents)
		beaker.reagents.remove_all()
	cell.use(total/powerefficiency)
	cell.emp_act(severity)
	work_animation()
	visible_message("<span class='danger'>[src] сбоит, разбрызгивая химикаты во все стороны!</span>")

/obj/machinery/chem_dispenser/RefreshParts()
	recharge_amount = initial(recharge_amount)
	var/newpowereff = initial(powerefficiency)
	for(var/obj/item/stock_parts/cell/P in component_parts)
		cell = P
		// Add minor irradiation when the cell is radioactive (mainly for glow effects).
		if(P.cell_is_radioactive)
			AddComponent(/datum/component/radioactive, 0, src, 0)
		else
			qdel(GetComponent(/datum/component/radioactive))
	for(var/obj/item/stock_parts/matter_bin/M in component_parts)
		newpowereff += CHEM_DISPENSER_EFFICIENCY_PER_RATING*M.rating
		if(reagents)
			reagents.maximum_volume = CHEM_DISPENSER_BASE_STORAGE*(M.rating)
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		recharge_amount *= C.rating
		capacitor_rating = C.rating
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		manipulator_tier = M.rating
		if(M.rating > 1) // T2
			dispensable_reagents |= upgrade_reagents
		if(M.rating > 2) // T3
			dispensable_reagents |= upgrade_reagents2
		if(M.rating > 3) // T4
			dispensable_reagents |= upgrade_reagents3
		if(M.rating > 4) // T5
			dispensable_reagents |= upgrade_reagents4
		// Emag reagents are only accessible via emag_act(), not through manipulator upgrades
		switch(M.rating)
			if(-INFINITY to 1)
				dispenseUnit = 5
			if(2)
				dispenseUnit = 3
			if(3)
				dispenseUnit = 2
			if(4 to INFINITY)
				dispenseUnit = 1
	powerefficiency = round(newpowereff, 0.01)
	update_static_data_for_all_viewers()

/obj/machinery/chem_dispenser/proc/replace_beaker(mob/living/user, obj/item/reagent_containers/new_beaker)
	if(beaker)
		var/obj/item/reagent_containers/B = beaker
		B.forceMove(drop_location())
		if(user && Adjacent(user) && user.can_hold_items())
			user.put_in_hands(B)
	if(new_beaker)
		beaker = new_beaker
		if(amount > beaker.reagents.maximum_volume)
			amount = beaker.reagents.maximum_volume
	else
		beaker = null
	update_icon()
	return TRUE

/obj/machinery/chem_dispenser/on_deconstruction()
	cell = null
	if(beaker)
		beaker.forceMove(drop_location())
		beaker = null
	return ..()

/obj/machinery/chem_dispenser/AltClick(mob/living/user)
	. = ..()
	if(istype(user) && user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		replace_beaker(user)
		return TRUE

/obj/machinery/chem_dispenser/proc/ConvertpHToCol(pH)
	switch(pH)
		if(-INFINITY to 1)
			return "red"
		if(1 to 2)
			return "orange"
		if(2 to 3)
			return "average"
		if(3 to 4)
			return "yellow"
		if(4 to 5)
			return "olive"
		if(5 to 6)
			return "good"
		if(6 to 8)
			return "green"
		if(8 to 9.5)
			return "teal"
		if(9.5 to 11)
			return "blue"
		if(11 to 12.5)
			return "violet"
		if(12.5 to INFINITY)
			return "purple"

/obj/machinery/chem_dispenser/proc/get_reagent_category(reagent_type)
	if(ispath(reagent_type, /datum/reagent/medicine))
		return "medicine"
	if(ispath(reagent_type, /datum/reagent/toxin))
		return "toxins"
	if(ispath(reagent_type, /datum/reagent/drug))
		return "drugs"
	if(ispath(reagent_type, /datum/reagent/consumable/organicprecursor))
		return "other"
	if(ispath(reagent_type, /datum/reagent/consumable/ethanol))
		return "alcoholic_drinks"
	if(ispath(reagent_type, /datum/reagent/consumable))
		return "soft_drinks"
	if(reagent_type in list(
		/datum/reagent/water,
		/datum/reagent/fuel,
		/datum/reagent/stable_plasma,
		/datum/reagent/oil,
		/datum/reagent/ammonia,
		/datum/reagent/ash,
		/datum/reagent/acetone,
		/datum/reagent/phenol,
		/datum/reagent/diethylamine,
		/datum/reagent/saltpetre
	))
		return "compounds"
	if(ispath(reagent_type, /datum/reagent))
		return "elements"
	return "other"


/obj/machinery/chem_dispenser/drinks/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/simple_rotation, ROTATION_ALTCLICK | ROTATION_CLOCKWISE)

/obj/machinery/chem_dispenser/drinks/setDir()
	var/old = dir
	. = ..()
	if(dir != old)
		update_icon() // Reposition the beaker overlay after rotation.

/obj/machinery/chem_dispenser/drinks/display_beaker()
	var/mutable_appearance/b_o = beaker_overlay || mutable_appearance(icon, "disp_beaker")
	switch(dir)
		if(NORTH)
			b_o.pixel_y = 7
			b_o.pixel_x = rand(-9, 9)
		if(EAST)
			b_o.pixel_x = 4
			b_o.pixel_y = rand(-5, 7)
		if(WEST)
			b_o.pixel_x = -5
			b_o.pixel_y = rand(-5, 7)
		else // SOUTH
			b_o.pixel_y = -7
			b_o.pixel_x = rand(-9, 9)
	return b_o


/obj/machinery/chem_dispenser/drinks
	name = "Soda Dispenser"
	desc = "Содержит огромное количество неалкогольных напитков."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "soda_dispenser"
	has_panel_overlay = FALSE
	amount = 10
	pixel_y = 6
	layer = BELOW_OBJ_LAYER
	circuit = /obj/item/circuitboard/machine/chem_dispenser/drinks
	working_state = null
	nopower_state = null
	pass_flags = PASSTABLE
	canStore = FALSE
	dispenser_type = DISPENSER_TYPE_SODA
	dispensable_reagents = list(
		/datum/reagent/water,
		/datum/reagent/consumable/ice,
		/datum/reagent/consumable/coffee,
		/datum/reagent/consumable/cream,
		/datum/reagent/consumable/tea,
		/datum/reagent/consumable/icetea,
		/datum/reagent/consumable/space_cola,
		/datum/reagent/consumable/spacemountainwind,
		/datum/reagent/consumable/dr_gibb,
		/datum/reagent/consumable/space_up,
		/datum/reagent/consumable/tonic,
		/datum/reagent/consumable/sodawater,
		/datum/reagent/consumable/lemon_lime,
		/datum/reagent/consumable/pwr_game,
		/datum/reagent/consumable/shamblers,
		/datum/reagent/consumable/sugar,
		/datum/reagent/consumable/pineapplejuice,
		/datum/reagent/consumable/orangejuice,
		/datum/reagent/consumable/grenadine,
		/datum/reagent/consumable/limejuice,
		/datum/reagent/consumable/tomatojuice,
		/datum/reagent/consumable/lemonjuice,
		/datum/reagent/consumable/menthol,
		/datum/reagent/consumable/synthdrink // BLUEMOON ADD - напитки для синтов
	)
	upgrade_reagents = list(
		/datum/reagent/consumable/banana,
		/datum/reagent/consumable/berryjuice,
		/datum/reagent/consumable/strawberryjuice
	)
	upgrade_reagents2 = list(
		/datum/reagent/consumable/applejuice,
		/datum/reagent/consumable/carrotjuice,
		/datum/reagent/consumable/pumpkinjuice,
		/datum/reagent/consumable/watermelonjuice,
		/datum/reagent/consumable/melonjuice // BLUEMOON ADD
	)
	upgrade_reagents3 = list(
		/datum/reagent/drug/mushroomhallucinogen,
		/datum/reagent/consumable/nothing,
		/datum/reagent/consumable/peachjuice,
		/datum/reagent/consumable/blumpkinjuice, // BLUEMOON ADD
		/datum/reagent/consumable/coco // BLUEMOON ADD
	)
	emagged_reagents = list(
		/datum/reagent/toxin/mindbreaker,
		/datum/reagent/toxin/staminatoxin,
		/datum/reagent/medicine/cryoxadone,
		/datum/reagent/iron
	)

/obj/machinery/chem_dispenser/drinks/fullupgrade // Fully upgraded stock parts, emagged.
	desc = "Содержит огромное количество неалкогольных напитков. Конкретно у этого сбоят протоколы безопасности."
	obj_flags = CAN_BE_HIT | EMAGGED
	flags_1 = NODECONSTRUCT_1
	circuit = /obj/item/circuitboard/machine/chem_dispenser/drinks/fullupgrade

/obj/machinery/chem_dispenser/drinks/fullupgrade/Initialize(mapload)
	. = ..()
	dispensable_reagents |= emagged_reagents // Add emagged reagents.

/obj/machinery/chem_dispenser/drinks/beer
	name = "Booze Dispenser"
	desc = "Содержит огромное количество хорошего пойла."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "booze_dispenser"
	circuit = /obj/item/circuitboard/machine/chem_dispenser/drinks/beer
	dispenser_type = DISPENSER_TYPE_BOOZE
	dispensable_reagents = list(
		/datum/reagent/consumable/ethanol/beer,
		/datum/reagent/consumable/ethanol/kahlua,
		/datum/reagent/consumable/ethanol/whiskey,
		/datum/reagent/consumable/ethanol/wine,
		/datum/reagent/consumable/ethanol/vodka,
		/datum/reagent/consumable/ethanol/gin,
		/datum/reagent/consumable/ethanol/rum,
		/datum/reagent/consumable/ethanol/tequila,
		/datum/reagent/consumable/ethanol/vermouth,
		/datum/reagent/consumable/ethanol/cognac,
		/datum/reagent/consumable/ethanol/ale,
		/datum/reagent/consumable/ethanol/absinthe,
		/datum/reagent/consumable/ethanol/hcider,
		/datum/reagent/consumable/ethanol/creme_de_menthe,
		/datum/reagent/consumable/ethanol/creme_de_cacao,
		/datum/reagent/consumable/ethanol/creme_de_coconut,
		/datum/reagent/consumable/ethanol/triple_sec,
		/datum/reagent/consumable/ethanol/sake,
		/datum/reagent/consumable/ethanol/applejack
	)
	upgrade_reagents = list(
		/datum/reagent/consumable/ethanol,
		/datum/reagent/consumable/ethanol/fernet,
		/datum/reagent/consumable/synthdrink/synthanol // BLUEMOON ADD - напитки для синтов
	)
	upgrade_reagents2 = null
	upgrade_reagents3 = null
	emagged_reagents = list(
		/datum/reagent/consumable/ethanol/alexander,
		/datum/reagent/consumable/clownstears,
		/datum/reagent/toxin/minttoxin,
		/datum/reagent/consumable/ethanol/atomicbomb,
		/datum/reagent/consumable/ethanol/thirteenloko,
		/datum/reagent/consumable/ethanol/changelingsting
	)

/obj/machinery/chem_dispenser/drinks/beer/fullupgrade // Fully upgraded stock parts, emagged.
	desc = "Содержит огромное количество хорошего пойла. Конкретно у этого сбоят протоколы безопасности."
	obj_flags = CAN_BE_HIT | EMAGGED
	flags_1 = NODECONSTRUCT_1
	circuit = /obj/item/circuitboard/machine/chem_dispenser/drinks/beer/fullupgrade

/obj/machinery/chem_dispenser/drinks/beer/fullupgrade/Initialize(mapload)
	. = ..()
	dispensable_reagents |= emagged_reagents // Add emagged reagents.

/obj/machinery/chem_dispenser/mutagen
	name = "Mutagen Dispenser"
	desc = "Создаёт и выдаёт мутаген."
	dispensable_reagents = list(/datum/reagent/toxin/mutagen)
	upgrade_reagents = null
	emagged_reagents = list(/datum/reagent/toxin/plasma)
	canStore = FALSE


/obj/machinery/chem_dispenser/mutagensaltpeter
	name = "Botanical Chemical Dispenser"
	desc = "Создаёт и выдаёт ботанические химикаты."
	flags_1 = NODECONSTRUCT_1
	canStore = FALSE
	circuit = /obj/item/circuitboard/machine/chem_dispenser/mutagensaltpeter

	dispensable_reagents = list(
		/datum/reagent/toxin/mutagen,
		/datum/reagent/saltpetre,
		/datum/reagent/plantnutriment/eznutriment,
		/datum/reagent/plantnutriment/left4zednutriment,
		/datum/reagent/plantnutriment/robustharvestnutriment,
		/datum/reagent/water,
		/datum/reagent/toxin/plantbgone,
		/datum/reagent/toxin/plantbgone/weedkiller,
		/datum/reagent/toxin/pestkiller,
		/datum/reagent/medicine/cryoxadone,
		/datum/reagent/ammonia,
		/datum/reagent/ash,
		/datum/reagent/diethylamine)
	upgrade_reagents = null
	upgrade_reagents2 = null
	upgrade_reagents3 = null

/obj/machinery/chem_dispenser/fullupgrade // Fully upgraded stock parts, emagged.
	desc = "Создаёт и выдаёт ботанические химикаты. Конкретно у этого сбоят протоколы безопасности."
	obj_flags = CAN_BE_HIT | EMAGGED
	flags_1 = NODECONSTRUCT_1
	circuit = /obj/item/circuitboard/machine/chem_dispenser/fullupgrade

/obj/machinery/chem_dispenser/fullupgrade/Initialize(mapload)
	. = ..()
	dispensable_reagents |= emagged_reagents // Add emagged reagents.

/obj/machinery/chem_dispenser/abductor
	name = "Reagent Synthesizer"
	desc = "Синтезирует разнообразные препараты, используя прото-материю."
	icon = 'icons/obj/abductor.dmi'
	icon_state = "chem_dispenser"
	has_panel_overlay = FALSE
	circuit = /obj/item/circuitboard/machine/chem_dispenser/abductor
	working_state = null
	nopower_state = null
	dispensable_reagents = list(
		/datum/reagent/hydrogen,
		/datum/reagent/lithium,
		/datum/reagent/carbon,
		/datum/reagent/nitrogen,
		/datum/reagent/oxygen,
		/datum/reagent/fluorine,
		/datum/reagent/sodium,
		/datum/reagent/aluminium,
		/datum/reagent/silicon,
		/datum/reagent/phosphorus,
		/datum/reagent/sulfur,
		/datum/reagent/chlorine,
		/datum/reagent/potassium,
		/datum/reagent/iron,
		/datum/reagent/copper,
		/datum/reagent/mercury,
		/datum/reagent/radium,
		/datum/reagent/water,
		/datum/reagent/consumable/ethanol,
		/datum/reagent/consumable/sugar,
		/datum/reagent/toxin/acid,
		/datum/reagent/fuel,
		/datum/reagent/silver,
		/datum/reagent/iodine,
		/datum/reagent/bromine,
		/datum/reagent/stable_plasma,
		/datum/reagent/oil,
		/datum/reagent/ammonia,
		/datum/reagent/ash,
		/datum/reagent/acetone,
		/datum/reagent/phenol,
		/datum/reagent/diethylamine,
		/datum/reagent/medicine/mine_salve,
		/datum/reagent/toxin,
		/datum/reagent/drug/space_drugs,
		/datum/reagent/toxin/plasma,
		/datum/reagent/consumable/frostoil,
		/datum/reagent/uranium,
		/datum/reagent/toxin/histamine,
		/datum/reagent/medicine/morphine
	)

/// A unique, less efficient model found in medbay apothecary.
/obj/machinery/chem_dispenser/apothecary
	name = "Apothecary Chem Dispenser"
	desc = "Удешевлённый химраздатчик для производства малых партий мед-препаратов."
	icon_state = "minidispenser"
	working_state = "minidispenser_working"
	nopower_state = "minidispenser_nopower"
	circuit = /obj/item/circuitboard/machine/chem_dispenser/apothecary
	canStore = FALSE
	powerefficiency = CHEM_DISPENSER_APOTHECARY_EFFICIENCY
	dispensable_reagents = list( // Radium and stable plasma are moved to upgrade tiers 1 and 2.
		/datum/reagent/hydrogen,
		/datum/reagent/lithium,
		/datum/reagent/carbon,
		/datum/reagent/nitrogen,
		/datum/reagent/oxygen,
		/datum/reagent/fluorine,
		/datum/reagent/sodium,
		/datum/reagent/aluminium,
		/datum/reagent/silicon,
		/datum/reagent/phosphorus,
		/datum/reagent/sulfur,
		/datum/reagent/chlorine,
		/datum/reagent/potassium,
		/datum/reagent/iron,
		/datum/reagent/copper,
		/datum/reagent/mercury,
		/datum/reagent/water,
		/datum/reagent/consumable/ethanol,
		/datum/reagent/consumable/sugar,
		/datum/reagent/toxin/acid,
		/datum/reagent/fuel,
		/datum/reagent/silver,
		/datum/reagent/iodine,
		/datum/reagent/bromine
	)
	upgrade_reagents = list(
		/datum/reagent/oil,
		/datum/reagent/ammonia,
		/datum/reagent/radium
	)
	upgrade_reagents2 = list(
		/datum/reagent/acetone,
		/datum/reagent/phenol,
		/datum/reagent/stable_plasma
	)
	upgrade_reagents3 = list(
		/datum/reagent/medicine/mine_salve
	)
	emagged_reagents = list(
		/datum/reagent/drug/space_drugs,
		/datum/reagent/toxin/carpotoxin,
		/datum/reagent/medicine/morphine
	)
