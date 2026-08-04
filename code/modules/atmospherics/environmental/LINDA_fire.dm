#define IGNITE_TURF_CHANCE 30
#define IGNITE_TURF_LOW_POWER 8
#define IGNITE_TURF_HIGH_POWER 22

/// Lavaland/mining Z: auxmos get_fuel_amount() still counts N2 — block air-only fuel so N2+O2 cannot sustain hotspots (matches genericfire N2 skip in reactions.dm).
/proc/turf_has_fire_fuel(datum/gas_mixture/air, temp, z_level)
	if(!air)
		return FALSE
	if(air.get_moles(GAS_PLASMA) > 0.5 || air.get_moles(GAS_TRITIUM) > 0.5)
		return TRUE
	if(air.get_fuel_amount(temp) < 0.5)
		return FALSE
	if(!is_mining_level(z_level))
		return TRUE
	for(var/gas_id in GLOB.gas_data.fire_temperatures)
		if(gas_id == GAS_N2)
			continue
		if(!GLOB.gas_data.fire_temperatures[gas_id])
			continue
		if(air.get_moles(gas_id) > 0.5)
			return TRUE
	return FALSE

/atom/proc/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	return null

// /turf/open/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
// 	if(prob(IGNITE_TURF_CHANCE))
// 		IgniteTurf(rand(IGNITE_TURF_LOW_POWER,IGNITE_TURF_HIGH_POWER))
// 	return ..()

/turf/proc/hotspot_expose(exposed_temperature, exposed_volume, soh = 0)
	return

///Create the visual hotspot only when this turf does not already own one.
///Fire attacks often call this immediately before hotspot_expose(); blindly
///constructing another hotspot orphaned the previous one in SSair.hotspots.
/turf/proc/ensure_hotspot()
	return new /obj/effect/hotspot(src)

/turf/open/ensure_hotspot()
	if(active_hotspot && !QDELETED(active_hotspot))
		return active_hotspot
	return new /obj/effect/hotspot(src)

/turf/open/hotspot_expose(exposed_temperature, exposed_volume, soh)
	//If the air doesn't exist we just return false
	var/list/air_gases = air?.get_gases()
	if(!air_gases)
		return

	// A tile that already burns and was not asked to sustain its hotspot (soh)
	// has no reachable side effect below, so the two full gas-list walks that
	// follow (get_oxidation_power, then get_fuel_amount inside
	// turf_has_fire_fuel) are pure waste. This is the dominant call: every fire
	// reaction ends with fire_expose on its own tile, so each burning tile paid
	// them once per reaction per fire.
	// Удалённый хотспот в поле - это не "тут уже горит", а протухшая ссылка:
	// ниже показано, откуда она берётся. Без QDELETED такой турф отказывался
	// загораться до конца раунда, потому что обе проверки ниже видели в поле
	// "живой" огонь.
	var/obj/effect/hotspot/current_hotspot = QDELETED(active_hotspot) ? null : active_hotspot

	if(current_hotspot && !soh)
		return

	if (air.get_oxidation_power(exposed_temperature) < 0.5 || air.get_moles(GAS_HYPERNOB) > 5)
		return
	var/has_fuel = turf_has_fire_fuel(air, exposed_temperature, z)
	if(current_hotspot)
		if(has_fuel)
			if(current_hotspot.temperature < exposed_temperature)
				current_hotspot.temperature = exposed_temperature
			if(current_hotspot.volume < exposed_volume)
				current_hotspot.volume = exposed_volume
		return

	if((exposed_temperature > PLASMA_MINIMUM_BURN_TEMPERATURE) && has_fuel)
		// Поле выставляет сам perform_exposure() внутри Initialize. Присваивание
		// результата поверх было не просто лишним: конструктор через
		// perform_exposure() зовёт fire_act() по содержимому турфа, детонация
		// оттуда сносит турф, /turf/open/Destroy делает QDEL_NULL(active_hotspot),
		// и эта строка возвращала уже удалённый хотспот обратно в поле турфа.
		// Ссылка держала его до харддела - два таких за раунд 9860 по 540мс.
		var/obj/effect/hotspot/new_hotspot = new /obj/effect/hotspot(src, exposed_volume*25, exposed_temperature)
		if(QDELETED(new_hotspot))
			return
		active_hotspot = new_hotspot

//This is the icon for fire on turfs, also helps for nurturing small fires until they are full tile
/obj/effect/hotspot
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	icon = 'icons/effects/fire.dmi'
	icon_state = "1"
	layer = GASFIRE_LAYER
	blend_mode = BLEND_ADD
	// light_system = MOVABLE_LIGHT
	light_range = LIGHT_RANGE_FIRE
	light_power = 1
	light_color = LIGHT_COLOR_FIRE

	var/volume = 125
	var/temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST
	var/bypassing = FALSE
	var/visual_update_tick = 0

/obj/effect/hotspot/Initialize(mapload, starting_volume, starting_temperature)
	. = ..()
	SSair.hotspots += src
	if(!isnull(starting_volume))
		volume = starting_volume
	if(!isnull(starting_temperature))
		temperature = starting_temperature
	perform_exposure()
	setDir(pick(GLOB.cardinals))
	air_update_turf()

	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/hotspot/proc/perform_exposure()
	// One mixture per hotspot per fire used to be allocated for the non-bypassing
	// branch below and qdel-ed three lines later: a station fire ran ~300
	// hotspots twice a second, so that alone pushed ~600 datums a second through
	// SSgarbage for no reason. The removed portion never outlives the call, so a
	// single reusable scratch covers every hotspot on the station.
	//
	// react() can reach fire_act/temperature_expose code that ignites another
	// tile and re-enters this proc, which would clobber the scratch mid-use; the
	// claim below falls back to the old allocating path for that case instead of
	// corrupting it. The claim is stamped with the fire it was taken in rather
	// than being a plain boolean: a runtime inside react() aborts this proc
	// without ever releasing it, and a boolean would then disable the reuse
	// silently for the rest of the round. A stamp goes stale on the next fire.
	var/static/datum/gas_mixture/exposure_scratch
	var/static/exposure_scratch_claimed_at = 0

	var/turf/open/location = loc
	if(!istype(location) || !(location.air))
		return

	location.active_hotspot = src

	bypassing = volume > CELL_VOLUME*0.95 || location.air.return_temperature() >= FUSION_TEMPERATURE_THRESHOLD

	if(bypassing)
		if(temperature > location.air.return_temperature())
			location.air.set_temperature(temperature) //now actually starts fires like intended
		volume = location.air.reaction_results["fire"]*FIRE_GROWTH_RATE
		temperature = location.air.return_temperature()
	else
		// Everything after assume_air() runs outside the claim, so the contents
		// loop at the bottom of this proc never blocks reuse.
		var/this_fire = (SSair ? SSair.times_fired : 0) + 1 // never 0, which means "free"
		var/reused = exposure_scratch_claimed_at != this_fire
		var/datum/gas_mixture/affected
		var/removed_ratio = volume / location.air.return_volume()
		if(reused)
			if(!exposure_scratch)
				exposure_scratch = new
			affected = exposure_scratch
			exposure_scratch_claimed_at = this_fire
			affected.clear()
			// remove_ratio() stamps the source temperature onto the removed
			// portion; matching it here keeps transfer_ratio_to from running its
			// capacity-weighted blend and reproduces that exactly.
			affected.set_temperature(location.air.return_temperature())
			// A freshly allocated mixture carries no archive; the scratch has to
			// be reset to that, or the previous hotspot's snapshot would answer
			// any archived_heat_capacity() reached from the reaction below.
			affected.gas_archive = null
			affected.temperature_archived = affected.temperature
			location.air.transfer_ratio_to(affected, removed_ratio)
		else
			affected = location.air.remove_ratio(removed_ratio)
		if(affected) //in case volume is 0
			if(temperature > affected.return_temperature())
				affected.set_temperature(temperature) //don't set the temperature lower than what it was
			affected.react(src)
			temperature = affected.return_temperature()
			volume = affected.reaction_results["fire"]*FIRE_GROWTH_RATE
			location.assume_air(affected)
		if(reused)
			exposure_scratch_claimed_at = 0
		else if(affected)
			qdel(affected)

	for(var/A in location)
		var/atom/AT = A
		if(!QDELETED(AT) && AT != src) // It's possible that the item is deleted in temperature_expose
			AT.fire_act(temperature, volume)
	return

/obj/effect/hotspot/proc/gauss_lerp(x, x1, x2)
	var/b = (x1 + x2) * 0.5
	var/c = (x2 - x1) / 6
	return NUM_E ** -((x - b) ** 2 / (2 * c) ** 2)

/obj/effect/hotspot/proc/update_color()
	cut_overlays()

	var/heat_r = heat2colour_r(temperature)
	var/heat_g = heat2colour_g(temperature)
	var/heat_b = heat2colour_b(temperature)
	var/heat_a = 255
	var/greyscale_fire = 1 //This determines how greyscaled the fire is.

	if(temperature < 5000) //This is where fire is very orange, we turn it into the normal fire texture here.
		var/normal_amt = gauss_lerp(temperature, 1000, 3000)
		heat_r = lerp(heat_r,255,normal_amt)
		heat_g = lerp(heat_g,255,normal_amt)
		heat_b = lerp(heat_b,255,normal_amt)
		heat_a -= gauss_lerp(temperature, -5000, 5000) * 128
		greyscale_fire -= normal_amt
	if(temperature > 40000) //Past this temperature the fire will gradually turn a bright purple
		var/purple_amt = temperature < lerp(40000,200000,0.5) ? gauss_lerp(temperature, 40000, 200000) : 1
		heat_r = lerp(heat_r,255,purple_amt)
	if(temperature > 200000 && temperature < 500000) //Somewhere at this temperature nitryl happens.
		var/sparkle_amt = gauss_lerp(temperature, 200000, 500000)
		var/mutable_appearance/sparkle_overlay = mutable_appearance('icons/effects/effects.dmi', "shieldsparkles")
		sparkle_overlay.blend_mode = BLEND_ADD
		sparkle_overlay.alpha = sparkle_amt * 255
		add_overlay(sparkle_overlay)
	if(temperature > 400000 && temperature < 1500000) //Lightning because very anime.
		var/mutable_appearance/lightning_overlay = mutable_appearance(icon, "overcharged")
		lightning_overlay.blend_mode = BLEND_ADD
		add_overlay(lightning_overlay)
	if(temperature > 4500000) //This is where noblium happens. Some fusion-y effects.
		var/fusion_amt = temperature < lerp(4500000,12000000,0.5) ? gauss_lerp(temperature, 4500000, 12000000) : 1
		var/mutable_appearance/fusion_overlay = mutable_appearance('icons/effects/atmospherics.dmi', "fusion_gas")
		fusion_overlay.blend_mode = BLEND_ADD
		fusion_overlay.alpha = fusion_amt * 255
		var/mutable_appearance/rainbow_overlay = mutable_appearance('icons/mob/screen_gen.dmi', "druggy")
		rainbow_overlay.blend_mode = BLEND_ADD
		rainbow_overlay.alpha = fusion_amt * 255
		rainbow_overlay.appearance_flags = RESET_COLOR
		heat_r = lerp(heat_r,150,fusion_amt)
		heat_g = lerp(heat_g,150,fusion_amt)
		heat_b = lerp(heat_b,150,fusion_amt)
		add_overlay(fusion_overlay)
		add_overlay(rainbow_overlay)

	set_light_color(rgb(lerp(250, heat_r, greyscale_fire), lerp(160, heat_g, greyscale_fire), lerp(25, heat_b, greyscale_fire)))

	heat_r /= 255
	heat_g /= 255
	heat_b /= 255

	color = list(lerp(0.3, 1, 1-greyscale_fire) * heat_r,0.3 * heat_g * greyscale_fire,0.3 * heat_b * greyscale_fire, 0.59 * heat_r * greyscale_fire,lerp(0.59, 1, 1-greyscale_fire) * heat_g,0.59 * heat_b * greyscale_fire, 0.11 * heat_r * greyscale_fire,0.11 * heat_g * greyscale_fire,lerp(0.11, 1, 1-greyscale_fire) * heat_b, 0,0,0)
	alpha = heat_a

#define INSUFFICIENT(path) (location.air.get_moles(path) < 0.5)
/obj/effect/hotspot/process()
	var/turf/open/location = loc
	if(!istype(location))
		qdel(src)
		return

	location.eg_reset_cooldowns()

	if((temperature < FIRE_MINIMUM_TEMPERATURE_TO_EXIST) || (volume <= 1))
		qdel(src)
		return
	if(!location.air || location.air.get_moles(GAS_HYPERNOB) > 5 || location.air.get_oxidation_power() < 0.5 || !turf_has_fire_fuel(location.air, temperature, location.z))
		qdel(src)
		return

	perform_exposure()

	// Writing an appearance var re-derives and re-hashes the whole appearance
	// even when the value is unchanged, and a settled fire holds the same frame
	// for its entire life. A string compare is far cheaper than that.
	var/new_icon_state
	if(bypassing)
		new_icon_state = "3"
	else if(volume > CELL_VOLUME*0.4)
		new_icon_state = "2"
	else
		new_icon_state = "1"
	if(icon_state != new_icon_state)
		icon_state = new_icon_state

	if(bypassing)
		location.burn_tile()

		//Possible spread due to radiated heat
		if(location.air.return_temperature() > FIRE_MINIMUM_TEMPERATURE_TO_SPREAD)
			var/radiated_temperature = location.air.return_temperature()*FIRE_SPREAD_RADIOSITY_SCALE
			for(var/t in location.atmos_adjacent_turfs)
				var/turf/open/T = t
				if(!T.active_hotspot)
					T.hotspot_expose(radiated_temperature, CELL_VOLUME/4)

	if((visual_update_tick++ % 7) == 0)
		update_color()

	if(temperature > location.max_fire_temperature_sustained)
		location.max_fire_temperature_sustained = temperature

	if(location.heat_capacity && temperature > location.heat_capacity)
		location.to_be_destroyed = TRUE
	return TRUE

/obj/effect/hotspot/Destroy()
	set_light(0)
	SSair.hotspots -= src
	var/turf/open/T = loc
	if(istype(T) && T.active_hotspot == src)
		T.active_hotspot = null
	DestroyTurf()
	return ..()

/obj/effect/hotspot/proc/DestroyTurf()
	if(isturf(loc))
		var/turf/T = loc
		if(T.to_be_destroyed && !T.changing_turf)
			var/chance_of_deletion
			if (T.heat_capacity) //beware of division by zero
				chance_of_deletion = T.max_fire_temperature_sustained / T.heat_capacity * 8 //there is no problem with prob(23456), min() was redundant --rastaf0
			else
				chance_of_deletion = 100
			if(prob(chance_of_deletion))
				T.Melt()
			else
				T.to_be_destroyed = FALSE
				T.max_fire_temperature_sustained = 0

/obj/effect/hotspot/proc/on_entered(datum/source, atom/movable/AM, oldLoc)
	SIGNAL_HANDLER
	if(isliving(AM))
		var/mob/living/L = AM
		L.fire_act(temperature, volume)

/obj/effect/hotspot/singularity_pull()
	return

/obj/effect/dummy/lighting_obj/moblight/fire
	name = "fire"
	light_color = LIGHT_COLOR_FIRE
	light_range = LIGHT_RANGE_FIRE

#undef INSUFFICIENT
#undef IGNITE_TURF_CHANCE
#undef IGNITE_TURF_LOW_POWER
#undef IGNITE_TURF_HIGH_POWER
