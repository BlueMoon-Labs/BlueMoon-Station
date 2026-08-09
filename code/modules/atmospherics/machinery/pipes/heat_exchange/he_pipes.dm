/obj/machinery/atmospherics/pipe/heat_exchanging
	level = 2
	var/minimum_temperature_difference = 0.01
	var/thermal_conductivity = WINDOW_HEAT_TRANSFER_COEFFICIENT
	color = "#404040"
	buckle_lying = 1
	var/icon_temperature = T20C //stop small changes in temperature causing icon refresh
	resistance_flags = LAVA_PROOF | FIRE_PROOF

/obj/machinery/atmospherics/pipe/heat_exchanging/Initialize(mapload)
	. = ..()
	add_atom_colour("#404040", FIXED_COLOUR_PRIORITY)

/obj/machinery/atmospherics/pipe/heat_exchanging/isConnectable(obj/machinery/atmospherics/pipe/heat_exchanging/target, given_layer, HE_type_check = TRUE)
	if(istype(target, /obj/machinery/atmospherics/pipe/heat_exchanging) != HE_type_check)
		return FALSE
	. = ..()

/obj/machinery/atmospherics/pipe/heat_exchanging/hide()
	return

/// Полосу слоя задаёт пиксельный сдвиг, а не отдельный кадр на каждый слой.
///
/// Полоса теплообменной трубы - 15 пикселей, и пять полос с шагом 5 требуют
/// 15 + 4*5 = 35 пикселей на 32-пиксельном тайле. Запечённый в лист сдвиг на
/// крайних слоях вылезал за границу кадра, где его срезало: у прямой трубы
/// отъедало крайнее ребро, у джанкшена - зубец. Сдвиг в рантайме не режет
/// ничего: BYOND просто рисует иконку со смещением, ровно как APC со своим
/// pixel_x -25. На слоях 2-4 результат совпадает с прежними запечёнными
/// кадрами пиксель в пиксель, включая диагонали - у них сдвиг по обеим осям,
/// и PIPING_LAYER_SHIFT на диагональном dir даёт ровно его.
///
/// Манифолдам это не подходит: их корпус сдвигается по обеим осям сразу, а
/// патрубки при этом обязаны дотягиваться до края тайла, то есть меняют длину,
/// а не только положение. Поэтому у них остался PIPING_INNER_LAYERS_ONLY.
/obj/machinery/atmospherics/pipe/heat_exchanging/proc/apply_layer_offset()
	// Сбрасываем обе оси: PIPING_LAYER_SHIFT трогает только ту, что отвечает
	// текущему dir, и после поворота трубы вторая осталась бы от прошлого.
	pixel_x = 0
	pixel_y = 0
	PIPING_LAYER_SHIFT(src, piping_layer)

/// Unlike every other pipe, a heat exchanger does real work each fire, so it
/// cannot PROCESS_KILL itself out of the machinery list. It can still be idle:
/// a pipe sitting at the same temperature as its surroundings conducts nothing.
/// Without this gate SSair paid for every heat exchanging pipe on the map every
/// single fire forever - measured at 69% of the whole machinery phase with 200
/// of them installed, all of it spent discovering that nothing had changed.
///
/// Waking is covered from both sides: the turf registration (register_turf_wake,
/// armed by atmos_consider_idle) catches the room changing, the pipeline's
/// wake_heat_exchangers() catches heat arriving through the loop, and the idle
/// heartbeat backstops anything that slips through both.
/obj/machinery/atmospherics/pipe/heat_exchanging/process_atmos()
	var/environment_temperature = 0
	var/datum/gas_mixture/pipe_air = return_air()
	if(!pipe_air || !parent)
		return

	var/turf/T = loc
	if(istype(T))
		if(islava(T))
			environment_temperature = 5000
		else if(T.blocks_air)
			environment_temperature = T.return_temperature()
		else
			var/turf/open/OT = T
			environment_temperature = OT.GetTemperature()
	else if(T)
		environment_temperature = T.return_temperature()

	var/did_work = FALSE
	if(abs(environment_temperature-pipe_air.return_temperature()) > minimum_temperature_difference)
		parent.temperature_interact(T, volume, thermal_conductivity)
		did_work = TRUE


	//heatup/cooldown any mobs buckled to ourselves based on our temperature
	if(has_buckled_mobs())
		did_work = TRUE
		var/hc = pipe_air.heat_capacity()
		var/mob/living/heat_source = buckled_mobs[1]
		//Best guess-estimate of the total bodytemperature of all the mobs, since they share the same environment it's ~ok~ to guess like this
		var/avg_temp = (pipe_air.return_temperature() * hc + (heat_source.bodytemperature * buckled_mobs.len) * 3500) / (hc + (buckled_mobs ? buckled_mobs.len * 3500 : 0))
		for(var/m in buckled_mobs)
			var/mob/living/L = m
			L.bodytemperature = avg_temp
		pipe_air.set_temperature(avg_temp)

	if(did_work)
		atmos_idle_streak = 0
		return
	atmos_consider_idle()

/obj/machinery/atmospherics/pipe/heat_exchanging/process()
	if(!parent)
		return //machines subsystem fires before atmos is initialized so this prevents race condition runtimes

	var/datum/gas_mixture/pipe_air = return_air()

	//Heat causes pipe to glow
	if(pipe_air.return_temperature() && (icon_temperature > 500 || pipe_air.return_temperature() > 500)) //glow starts at 500K
		if(abs(pipe_air.return_temperature() - icon_temperature) > 10)
			icon_temperature = pipe_air.return_temperature()

			var/h_r = heat2colour_r(icon_temperature)
			var/h_g = heat2colour_g(icon_temperature)
			var/h_b = heat2colour_b(icon_temperature)

			if(icon_temperature < 2000)//scale glow until 2000K
				var/scale = (icon_temperature - 500) / 1500
				h_r = 64 + (h_r - 64) * scale
				h_g = 64 + (h_g - 64) * scale
				h_b = 64 + (h_b - 64) * scale

			animate(src, color = rgb(h_r, h_g, h_b), time = 20, easing = SINE_EASING)

	//burn any mobs buckled based on temperature
	if(has_buckled_mobs())
		var/heat_limit = 1000
		if(pipe_air.return_temperature() > heat_limit + 1)
			for(var/m in buckled_mobs)
				var/mob/living/buckled_mob = m
				buckled_mob.apply_damage(4 * log(pipe_air.return_temperature() - heat_limit), BURN, BODY_ZONE_CHEST)
