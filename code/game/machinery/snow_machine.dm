// "Просто добавь воды и у тебя тоже будет своя зимняя сказка!"

/obj/machinery/snow_machine
	name = "Snow Machine"
	desc = "Просто добавь воды - и у тебя тоже будет собственная зимняя сказка! Колядники не входят в комплект."
	icon_state = "snow_machine_off"
	density = TRUE
	layer = OBJ_LAYER
	use_power = IDLE_POWER_USE
	idle_power_usage = 50
	active_power_usage = 500
	circuit = /obj/item/circuitboard/machine/snow_machine
	var/active = FALSE
	var/power_used_this_cycle = 0
	var/cooling_speed = 1
	var/power_efficiency = 1
	var/lower_temperature_limit = T0C - 10 //Set lower for a bigger freeze
	var/infinite_snow = FALSE //Set this to have it not use water

/obj/item/circuitboard/machine/snow_machine
	name = "Snow Machine (Machine Board)"
	icon_state = "generic"
	build_path = /obj/machinery/snow_machine
	req_components = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/micro_laser = 1)

/obj/machinery/snow_machine/Initialize(mapload)
	. = ..()
	create_reagents(300, OPENCONTAINER | NO_REACT) //Makes 100 snow tiles! But any reagent will do.
	reagents.add_reagent(/datum/reagent/water, 300)
	RefreshParts()

/obj/machinery/snow_machine/examine(mob/user)
	. = ..()
	. += span_notice("Индикатор внутреннего резервуара показывает [infinite_snow ? "100" : round(reagents.total_volume / reagents.maximum_volume * 100)]% заполненности.")

/obj/machinery/snow_machine/RefreshParts()
	power_efficiency = 0
	cooling_speed = 0
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		cooling_speed += B.rating
	for(var/obj/item/stock_parts/micro_laser/L in component_parts)
		power_efficiency += L.rating

/obj/machinery/snow_machine/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(panel_open)
		return ..()
	if(!anchored)
		to_chat(user, span_warning("Прикрутите машинку к полу!"))
		return TRUE
	if(!active && (machine_stat & NOPOWER))
		to_chat(user, span_warning("[src] не подключён к питанию."))
		return TRUE
	if(turn_on_or_off(!active))
		to_chat(user, span_notice("Вы [active ? "включаете" : "выключаете"] [src]."))
	return TRUE

/obj/machinery/snow_machine/crowbar_act(mob/user, obj/item/I)
	if(default_deconstruction_crowbar(user, I))
		return TRUE

/obj/machinery/snow_machine/screwdriver_act(mob/user, obj/item/I)
	if(default_deconstruction_screwdriver(user, "snow_machine_openpanel", "snow_machine_off", I))
		turn_on_or_off(FALSE)
		return TRUE

/obj/machinery/snow_machine/wrench_act(mob/user, obj/item/I)
	. = TRUE
	if(!default_unfasten_wrench(user, I, 0))
		return
	if(!anchored)
		turn_on_or_off(FALSE)

/obj/machinery/snow_machine/process()
	if(power_used_this_cycle)
		power_used_this_cycle /= max(power_efficiency, 1)
		use_power(power_used_this_cycle)
		power_used_this_cycle = 0
	if(!active || !anchored)
		return
	if(machine_stat & NOPOWER)
		return
	if(!reagents.has_reagent(reagents.get_master_reagent_id(), 3))
		return //This means you don't need to top it up constantly to keep the nice snowclouds going
	var/turf/T = get_turf(src)
	if(isspaceturf(T) || T.density) //If the snowmachine is on a dense tile or in space, then it shouldn't be able to produce any snow and so will turn off
		turn_on_or_off(FALSE, TRUE)
		return
	if(istype(T, /turf/open))
		cool_turf(T, cooling_speed)
	for(var/turf/open/TF in range(1, src))
		if(prob(50))
			continue
		make_snowcloud(TF)

/// Прямое охлаждение воздуха на турфе (замена Paradise-овской milla_safe обёртки).
/obj/machinery/snow_machine/proc/cool_turf(turf/open/T, modifier)
	var/datum/gas_mixture/env = T.return_air()
	if(!env || T.density)
		return
	var/initial_temperature = env.return_temperature()
	if(initial_temperature <= lower_temperature_limit) //Can we actually cool this?
		return
	var/old_thermal_energy = env.return_temperature() * env.heat_capacity()
	var/amount_cooled = initial_temperature - modifier * 8000 / env.heat_capacity()
	env.set_temperature(max(amount_cooled, lower_temperature_limit))
	T.air_update_turf(FALSE)
	power_used_this_cycle += (old_thermal_energy - env.return_temperature() * env.heat_capacity()) / 100

/obj/machinery/snow_machine/power_change()
	. = ..()
	if((machine_stat & NOPOWER) && active)
		turn_on_or_off(FALSE, TRUE)
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/snow_machine/update_icon_state()
	if(panel_open)
		icon_state = "snow_machine_openpanel"
	else
		icon_state = "snow_machine_[active ? "on" : "off"]"

/obj/machinery/snow_machine/on_deconstruction()
	turn_on_or_off(FALSE)
	return ..()

/obj/machinery/snow_machine/proc/make_snowcloud(turf/T)
	if(isspaceturf(T))
		return
	if(T.density)
		return
	var/datum/gas_mixture/G = T.return_air()
	if(!G || G.return_temperature() > T0C + 1)
		return
	if(locate(/obj/effect/snowcloud, T)) //Ice to see you
		return
	if(infinite_snow || reagents.remove_reagent(reagents.get_master_reagent_id(), 3))
		new /obj/effect/snowcloud(T, src)
		power_used_this_cycle += 1000
		return TRUE

/obj/machinery/snow_machine/proc/turn_on_or_off(activate, give_message = FALSE)
	active = activate ? TRUE : FALSE
	if(!active && give_message)
		visible_message(span_warning("[src] выключается!"))
		playsound(loc, 'sound/machines/buzz-sigh.ogg', 50, FALSE)
	update_icon(UPDATE_ICON_STATE)
	return TRUE

//Снежное облако: остужает свой турф и расползается по холодным соседям.

/obj/effect/snowcloud
	name = "снежное облако"
	desc = "Пусть идёт снег, пусть идёт снег, пусть идёт снег!"
	icon = 'icons/obj/snow_machine_fx.dmi'
	icon_state = "snowcloud"
	layer = FLY_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/obj/machinery/snow_machine/parent_machine

/obj/effect/snowcloud/New(turf, obj/machinery/snow_machine/SM)
	..()
	START_PROCESSING(SSobj, src)
	if(SM && istype(SM))
		parent_machine = SM

/obj/effect/snowcloud/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/snowcloud/process()
	if(QDELETED(parent_machine))
		parent_machine = null
	var/turf/T = get_turf(src)
	if(isspaceturf(T) || T.density) // Don't want snowclouds or snow on walls
		qdel(src)
		return
	var/turf/open/O = T
	var/turf_hotness = istype(O) && O.return_air() ? O.return_air().return_temperature() : T20C
	if(turf_hotness > T0C && prob(10 * (turf_hotness - T0C))) //Cloud disappears if it's too warm
		qdel(src)
		return
	if(!parent_machine || !parent_machine.active || (parent_machine.machine_stat & NOPOWER)) //All reasons a cloud could dissipate
		if(prob(10))
			qdel(src)
		return
	try_to_snow(O, turf_hotness)
	try_to_spread_cloud()
	if(istype(O) && O.return_air())
		parent_machine.cool_turf(O, 0.25 * parent_machine.cooling_speed)

/obj/effect/snowcloud/proc/try_to_snow(turf/open/O, turf_hotness)
	if(!istype(O))
		return
	if(locate(/obj/effect/snow, O))
		return
	if(prob(75 + turf_hotness - T0C)) //Colder turf = more chance of snow
		return
	new /obj/effect/snow(O)

/obj/effect/snowcloud/proc/try_to_spread_cloud()
	if(prob(95 - parent_machine.cooling_speed * 5)) //10 / 15 / 20 / 25% chance to spawn a new cloud
		return
	var/list/random_dirs = shuffle(GLOB.cardinals)
	for(var/potential in random_dirs)
		var/turf/T = get_turf(get_step(src, potential))
		if(isspaceturf(T) || T.density)
			continue
		if(!CanAtmosPass(potential) || !T.CanAtmosPass(turn(potential, 180)))
			continue
		if(parent_machine.make_snowcloud(T))
			return


//Snow stuff below

/obj/effect/snow
	desc = "Отлично подходит для создания снежных ангелов или метания в других людей!"
	icon = 'icons/obj/snow_machine_fx.dmi'
	icon_state = "snow1"
	plane = FLOOR_PLANE
	layer = ABOVE_NORMAL_TURF_LAYER

/obj/effect/snow/New()
	START_PROCESSING(SSobj, src)
	icon_state = "snow[rand(1,6)]"
	..()

/obj/effect/snow/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/snow/process()
	var/turf/T = get_turf(src)
	if(isspaceturf(T) || T.density) // Don't want snowclouds or snow on walls
		qdel(src)
		return
	var/turf/open/O = T
	var/turf_hotness = istype(O) && O.return_air() ? O.return_air().return_temperature() : T20C
	if(turf_hotness <= T0C)
		return
	if(prob(10 + turf_hotness - T0C))
		qdel(src)

/obj/effect/snow/attack_hand(mob/living/carbon/human/user)
	if(!istype(user)) //Nonhumans don't have the balls to fight in the snow
		return
	user.changeNext_move(CLICK_CD_MELEE)
	var/obj/item/snowball/SB = new(get_turf(user))
	user.put_in_hands(SB)
	to_chat(user, span_notice("Вы загребаете немного снега и лепите \a [SB]!"))

/obj/effect/snow/attackby(obj/item/used, mob/living/user, params)
	if(used.tool_behaviour == TOOL_SHOVEL)
		user.visible_message(span_notice("[user] расчищает [src]..."), span_notice("Вы начинаете расчищать [src]..."), span_warning("Вы слышите влажный звук копания."))
		playsound(loc, used.usesound || 'sound/effects/shovel_dig.ogg', 50, TRUE)
		if(do_after(user, 50 * used.toolspeed, target = src))
			user.visible_message(span_notice("[user] расчищает [src]!"), span_notice("Вы расчистили [src]!"))
			qdel(src)
		return TRUE
	else
		return ..()

/obj/effect/snow/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume, global_overlay = TRUE)
	..()
	qdel(src)

/obj/effect/snow/ex_act(severity)
	if(severity == EXPLODE_LIGHT && prob(50))
		return
	qdel(src)

/obj/item/snowball
	name = "snowball"
	desc = "Приготовьтесь к снежной битве!"
	icon = 'icons/obj/toys.dmi'
	icon_state = "snowball"
	throwforce = 1
	w_class = WEIGHT_CLASS_SMALL
	/// The amount of stamina damage to do on hit.
	var/stamina_damage = 10

/obj/item/snowball/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(!. && isliving(hit_atom))
		var/mob/living/M = hit_atom
		M.apply_damage(stamina_damage, STAMINA)
		playsound(M, 'sound/weapons/tap.ogg', 50, TRUE)
	qdel(src)

/obj/item/snowball/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume, global_overlay = TRUE)
	..()
	qdel(src)

/obj/item/snowball/ex_act(severity)
	qdel(src)
