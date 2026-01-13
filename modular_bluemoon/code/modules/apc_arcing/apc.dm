/// Lower excess value for APC arcing, 5% chance to arc
#define APC_ARC_LOWERLIMIT 5 MEGA * WATT
/// Moderate excess value for APC arcing, 10% chance to arc
#define APC_ARC_MEDIUMLIMIT 10 MEGA * WATT
/// Upper excess value for for APC arcing, 15% chance to arc
#define APC_ARC_UPPERLIMIT 15 MEGA * WATT

/obj/machinery/power/apc
	/// Has the APC been protected against arcing?
	var/arc_shielded = FALSE
	/// Should we be forcing arcing, assuming there isn't arc shielding?
	var/force_arcing = FALSE

/obj/machinery/power/apc/examine()
	. = ..()
	. += "Дуговое экранирование [arc_shielded ? "" : "не"] установлено."
	if(panel_open)
		if(arc_shielded)
			. += "Дуговое экранирование можно снять <b>гаечным ключом</b>."
		else
			. += "Можно экранировать <b>листом бронзы</b>."

/obj/machinery/power/apc/process(seconds_per_tick)
	. = ..()
	if(!cell || shorted)
		return
	var/excess = surplus()
	if(((excess < APC_ARC_LOWERLIMIT) && !force_arcing) || arc_shielded)
		return
	var/shock_chance = 5
	if(excess >= APC_ARC_UPPERLIMIT)
		shock_chance = 15
	else if(excess >= APC_ARC_MEDIUMLIMIT)
		shock_chance = 10
	if(prob(shock_chance)) // sometimes arc, otherwise give the players a hint something is amiss
		// pick a random person in range to shock
		#define SHOCK_SOMEONE 1
		// create some sparks
		#define MAKE_SPARKS 2
		// cut the power for 2-4 seconds
		#define CAUSE_BROWNOUT 3

		var/effect = pick(list(
			SHOCK_SOMEONE,
			MAKE_SPARKS,
			CAUSE_BROWNOUT,
		))
		switch(effect)
			if(SHOCK_SOMEONE)
				var/list/shock_mobs = list()
				for(var/mob/living/creature in viewers(get_turf(src), 5))
					shock_mobs += creature
				if(length(shock_mobs))
					var/mob/living/living_target = shock_mobs
					var/shock_damage = excess/99.5
					do_sparks(n = 3, c = FALSE, source = living_target)
					living_target.electrocute_act(shock_damage, "electrical arc")
					playsound(get_turf(living_target), 'sound/magic/LightningShock.ogg', 75, TRUE)
					Beam(living_target, icon_state = "lightning[rand(1, 12)]", icon = 'icons/effects/beam.dmi', time = 5)
					energy_fail(2)
			if(MAKE_SPARKS)
				do_sparks(n = 3, c = FALSE, source = src)
			if(CAUSE_BROWNOUT)
				energy_fail(rand(2, 4)) // energy_fail does not use the SECONDS macro, so it's deliberately not used here in the arg. don't add it.
		#undef SHOCK_SOMEONE
		#undef MAKE_SPARKS
		#undef CAUSE_BROWNOUT


/obj/machinery/power/apc/attackby(obj/item/W, mob/living/user, params)
	. = ..()
	if(.)
		return .

	if(istype(W, /obj/item/stack/sheet/bronze) && panel_open)
		. = bronze_act(user, W)

/// Handles interaction of adding arc shielding to apc with bronze
/obj/machinery/power/apc/proc/bronze_act(mob/living/user, obj/item/stack/sheet/bronze/bronze)
	if(arc_shielded)
		balloon_alert(user, "уже экранировано!")
		return FALSE
	bronze.use(1)
	balloon_alert(user, "установлено дуговое экранирование.")
	arc_shielded = TRUE
	playsound(src, 'sound/items/rped.ogg', 20)
	return TRUE

/obj/machinery/power/apc/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(panel_open && arc_shielded)
		balloon_alert(user, "дуговое экранирование снято.")
		arc_shielded = FALSE
		tool.play_tool_sound(src, 50)

/// Set all APCs to start (or stop) arcing
/proc/force_apc_arcing(force_mode = FALSE)
	for(var/obj/machinery/power/apc/controller as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/apc))
		controller.force_arcing = force_mode

#undef APC_ARC_LOWERLIMIT
#undef APC_ARC_MEDIUMLIMIT
#undef APC_ARC_UPPERLIMIT
