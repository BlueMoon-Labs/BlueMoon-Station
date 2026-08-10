/obj/machinery/portable_atmospherics/scrubber
	name = "portable air scrubber"
	icon_state = "pscrubber:0"
	density = TRUE
	ui_x = 320
	ui_y = 350

	var/on = FALSE
	var/volume_rate = 1000
	var/use_overlays = TRUE
	volume = 1000

	var/list/scrubbing = list(GAS_PLASMA, GAS_CO2, GAS_NITROUS, GAS_BZ, GAS_NITRYL, GAS_TRITIUM, GAS_HYPERNOB, GAS_H2O)

/obj/machinery/portable_atmospherics/scrubber/Destroy()
	var/turf/T = get_turf(src)
	if(T)
		T.assume_air(air_contents)
		air_update_turf()
	return ..()

/obj/machinery/portable_atmospherics/scrubber/update_icon_state()
	icon_state = "pscrubber:[on]"

/obj/machinery/portable_atmospherics/scrubber/update_overlays()
	. = ..()
	if(!use_overlays)
		return
	if(holding)
		. += "scrubber-open"
	if(connected_port)
		. += "scrubber-connector"

/obj/machinery/portable_atmospherics/scrubber/process_atmos()
	if(!on)
		return ..()

	// A working scrubber watches turf/tank air that changes without wake
	// events, so it never sleeps while switched on.
	excited = TRUE
	if(holding)
		scrub(holding.air_contents)
	else
		var/turf/T = get_turf(src)
		scrub(T.return_air())
	return ..()

/obj/machinery/portable_atmospherics/scrubber/proc/scrub(var/datum/gas_mixture/mixture)
	if(!mixture)
		return
	var/mixture_volume = mixture.return_volume()
	if(mixture_volume <= 0)
		return
	mixture.scrub_into(air_contents, volume_rate / mixture_volume, scrubbing)
	if(!holding)
		air_update_turf()

/// A dockable scrubber for removing selected gases directly from a pipenet.
/// The removable tank is deliberately required: filtered gas never shares the
/// machine's pipenet-facing mixture, so reconnecting cannot put it back.
/obj/machinery/portable_atmospherics/scrubber/pipe
	name = "portable pipe scrubber"
	desc = "A portable scrubber for filtering a connected pipenet into an inserted gas tank. It stops before the tank reaches leak pressure."
	// Amber housing: this and the ordinary portable scrubber ship in the same
	// cargo crate and would otherwise be the same sprite standing side by side.
	icon_state = "pipescrubber:0"
	volume_rate = 500

/obj/machinery/portable_atmospherics/scrubber/pipe/update_icon_state()
	icon_state = "pipescrubber:[on]"

/obj/machinery/portable_atmospherics/scrubber/pipe/process_atmos()
	if(!connected_port)
		return ..()
	if(!on || !holding || holding.air_contents.return_pressure() >= TANK_LEAK_PRESSURE * 0.9)
		excited = FALSE
		return
	var/network_volume = air_contents.return_volume()
	if(network_volume <= 0)
		excited = FALSE
		return
	var/moles_before = air_contents.total_moles()
	air_contents.scrub_into(holding.air_contents, min(1, volume_rate / network_volume), scrubbing)
	if(air_contents.total_moles() < moles_before)
		holding.excite_tank()
		// The connector's pipeline can be mid-rebuild (unwrenched/exploded pipe).
		var/datum/pipeline/pipe_net = connected_port.parents[1]
		if(pipe_net)
			pipe_net.mark_dirty()
	excited = FALSE

/obj/machinery/portable_atmospherics/scrubber/pipe/examine(mob/user)
	. = ..()
	if(!holding)
		. += "<span class='warning'>Для фильтрации пайплайна нужно вставить пустой газовый баллон.</span>"

/obj/machinery/portable_atmospherics/scrubber/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(is_operational)
		if(prob(severity/3))
			on = !on
		excite()
		update_icon()

/obj/machinery/portable_atmospherics/scrubber/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PortableScrubber", name)
		ui.open()

/obj/machinery/portable_atmospherics/scrubber/ui_data()
	var/list/data = ui_contents_data()
	data["on"] = on
	data["volume_rate"] = round(volume_rate)
	data["max_volume_rate"] = round(volume)

	data["id_tag"] = -1 //must be defined in order to reuse code between portable and vent scrubbers
	data["filter_types"] = list()
	for(var/id in GLOB.gas_data.ids)
		data["filter_types"] += list(list("gas_id" = id, "gas_name" = GLOB.gas_data.names[id], "enabled" = (id in scrubbing)))
	return data

/obj/machinery/portable_atmospherics/scrubber/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("power")
			on = !on
			. = TRUE
		if("eject")
			if(holding)
				holding.forceMove(drop_location())
				holding = null
				. = TRUE
		if("toggle_filter")
			scrubbing ^= params["val"]
			. = TRUE
		if("set_all_filters")
			// Отметить полтора десятка газов по одному - занятие на минуту.
			// Список плоский: GLOB.gas_data.ids ассоциативен, а scrubbing
			// живёт под операцией ^= и обязан остаться обычным списком.
			scrubbing = list()
			if(text2num(params["val"]))
				for(var/gas_id in GLOB.gas_data.ids)
					scrubbing += gas_id
			. = TRUE
		if("volume_rate")
			var/rate = params["rate"]
			if(rate == "max")
				rate = volume
				. = TRUE
			else if(!isnull(text2num(rate)))
				rate = text2num(rate)
				. = TRUE
			if(.)
				volume_rate = clamp(rate, 0, volume)
	// Power/filter changes must pull a sleeping scrubber back in.
	excite()
	update_icon()

/obj/machinery/portable_atmospherics/scrubber/huge
	name = "huge air scrubber"
	icon_state = "scrubber:0"
	anchored = TRUE
	active_power_usage = 500
	idle_power_usage = 10

	volume_rate = 1500
	volume = 50000

	var/movable = FALSE
	use_overlays = FALSE

/obj/machinery/portable_atmospherics/scrubber/huge/movable
	movable = TRUE

/obj/machinery/portable_atmospherics/scrubber/huge/update_icon_state()
	icon_state = "scrubber:[on]"

/obj/machinery/portable_atmospherics/scrubber/huge/process_atmos()
	if(((!anchored && !movable) || !is_operational) && on)
		on = FALSE
		update_icon()
	use_power = on ? ACTIVE_POWER_USE : IDLE_POWER_USE
	. = ..()
	if(!on)
		return
	if(!holding)
		var/turf/T = get_turf(src)
		for(var/turf/AT in T.GetAtmosAdjacentTurfs(alldir = TRUE))
			scrub(AT.return_air())

/obj/machinery/portable_atmospherics/scrubber/huge/attackby(obj/item/W, mob/user)
	if(default_unfasten_wrench(user, W))
		if(!movable)
			on = FALSE
	else
		return ..()
