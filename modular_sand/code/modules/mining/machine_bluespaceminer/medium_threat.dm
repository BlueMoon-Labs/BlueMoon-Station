GLOBAL_LIST_INIT(bsm_medium_threat_pool, list(
	/datum/bsm_instability_effect/medium/plasma_burp = 5,
	/datum/bsm_instability_effect/medium/nitrogen_burp = 10,
	/datum/bsm_instability_effect/medium/co2_vent = 10,
	/datum/bsm_instability_effect/medium/water_vapor_gust = 10,
	/datum/bsm_instability_effect/medium/cold_snap = 10,
	/datum/bsm_instability_effect/medium/nitrous_whiff = 10,
	/datum/bsm_instability_effect/medium/pressure_ping = 5,
))

/datum/bsm_instability_effect/medium

/datum/bsm_instability_effect/medium/plasma_burp

/datum/bsm_instability_effect/medium/plasma_burp/trigger(obj/machinery/mineral/bluespace_miner/machine)
	var/turf/center = get_turf(machine)
	if(!center)
		return
	playsound(machine, 'sound/effects/bamf.ogg', 60, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	machine.balloon_alert_to_viewers("плазма!")
	machine.visible_message(span_warning("Блюспейс-майнер срыгивает облако плазмы!"))
	var/turf/open/plasma_turf = center
	if(istype(plasma_turf) && plasma_turf.air)
		plasma_turf.air.adjust_moles(GAS_PLASMA, rand(15, 35))
		plasma_turf.air_update_turf()

/datum/bsm_instability_effect/medium/nitrogen_burp

/datum/bsm_instability_effect/medium/nitrogen_burp/trigger(obj/machinery/mineral/bluespace_miner/machine)
	var/turf/center = get_turf(machine)
	if(!center)
		return
	playsound(machine, 'sound/effects/bamf.ogg', 55, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	machine.balloon_alert_to_viewers("холодный азот!")
	machine.visible_message(span_warning("Из блюспейс-майнера вырывается холодный азот!"))
	var/turf/open/n2_turf = center
	if(istype(n2_turf) && n2_turf.air)
		n2_turf.air.adjust_moles(GAS_N2, rand(45, 85))
		n2_turf.air_update_turf()

/datum/bsm_instability_effect/medium/co2_vent

/datum/bsm_instability_effect/medium/co2_vent/trigger(obj/machinery/mineral/bluespace_miner/machine)
	var/turf/center = get_turf(machine)
	if(!center)
		return
	playsound(machine, 'sound/effects/bamf.ogg', 48, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	machine.balloon_alert_to_viewers("выброс CO₂!")
	machine.visible_message(span_warning("Блюспейс-майнер выпускает углекислый газ!"))
	var/turf/open/co2_turf = center
	if(istype(co2_turf) && co2_turf.air)
		co2_turf.air.adjust_moles(GAS_CO2, rand(20, 45))
		co2_turf.air_update_turf()

/datum/bsm_instability_effect/medium/water_vapor_gust

/datum/bsm_instability_effect/medium/water_vapor_gust/trigger(obj/machinery/mineral/bluespace_miner/machine)
	var/turf/center = get_turf(machine)
	if(!center)
		return
	playsound(machine, 'sound/effects/bamf.ogg', 42, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	machine.balloon_alert_to_viewers("пар!")
	machine.visible_message(span_warning("Вокруг [machine] на секунду сгущается пар!"))
	var/turf/open/steam_turf = center
	if(istype(steam_turf) && steam_turf.air)
		steam_turf.air.adjust_moles(GAS_H2O, rand(25, 55))
		steam_turf.air_update_turf()

/datum/bsm_instability_effect/medium/cold_snap

/datum/bsm_instability_effect/medium/cold_snap/trigger(obj/machinery/mineral/bluespace_miner/machine)
	var/turf/center = get_turf(machine)
	if(!center)
		return
	playsound(machine, 'sound/effects/glassbr1.ogg', 72, TRUE, MEDIUM_RANGE_SOUND_EXTRARANGE)
	machine.balloon_alert_to_viewers("криогенный скачок!")
	machine.visible_message(span_warning("Блюспейс обрушивается в криогенный разряд — воздух вокруг [machine] на мгновение проваливается ниже нуля!"))
	var/turf/open/cold_turf = center
	if(istype(cold_turf) && cold_turf.air)
		var/new_temp = max(TCMB + 5, cold_turf.air.return_temperature() - rand(75, 130))
		cold_turf.air.set_temperature(new_temp)
		cold_turf.air_update_turf()

/datum/bsm_instability_effect/medium/nitrous_whiff

/datum/bsm_instability_effect/medium/nitrous_whiff/trigger(obj/machinery/mineral/bluespace_miner/machine)
	var/turf/center = get_turf(machine)
	if(!center)
		return
	playsound(machine, 'sound/effects/bamf.ogg', 40, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	machine.balloon_alert_to_viewers("сладкий газ...")
	machine.visible_message(span_warning("Сладковатый запах — в разломе мелькает закись азота!"))
	var/turf/open/n2o_turf = center
	if(istype(n2o_turf) && n2o_turf.air)
		n2o_turf.air.adjust_moles(GAS_NITROUS, rand(8, 18))
		n2o_turf.air_update_turf()

/datum/bsm_instability_effect/medium/pressure_ping

/datum/bsm_instability_effect/medium/pressure_ping/trigger(obj/machinery/mineral/bluespace_miner/machine)
	var/turf/center = get_turf(machine)
	if(!center)
		return
	machine.balloon_alert_to_viewers("скачок давления!")
	machine.visible_message(span_warning("Скачок давления и ослепительная вспышка от [machine]!"))
	do_sparks(rand(4, 8), FALSE, machine)
	playsound(center, 'sound/weapons/flashbang.ogg', 90, TRUE, 8, 0.9)
	new /obj/effect/dummy/lighting_obj (center, LIGHT_COLOR_WHITE, 9, 4, 2)
	var/obj/item/grenade/flashbang/simulated = new(center)
	simulated.flashbang_mobs(center, 7)
	qdel(simulated)
