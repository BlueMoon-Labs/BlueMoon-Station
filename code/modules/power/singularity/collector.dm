// stored_power += (pulse_strength-RAD_COLLECTOR_EFFICIENCY)*RAD_COLLECTOR_COEFFICIENT
#define RAD_COLLECTOR_EFFICIENCY 80 	// radiation needs to be over this amount to get power
#define RAD_COLLECTOR_COEFFICIENT 125
#define RAD_COLLECTOR_STORED_OUT 0.05	// (this*100)% of stored power outputted per tick. Doesn't actualy change output total, lower numbers just means collectors output for longer in absence of a source
#define RAD_COLLECTOR_MINING_CONVERSION_RATE 0.00001 //This is gonna need a lot of tweaking to get right. This is the number used to calculate the conversion of watts to research points per process()
#define RAD_COLLECTOR_OUTPUT min(stored_power, (stored_power*RAD_COLLECTOR_STORED_OUT)+1000) //Produces at least 1000 watts if it has more than that stored

/obj/machinery/power/rad_collector
	name = "Radiation Collector Array"
	desc = "Преобразователь энергии, работающий на принципе хокинговского излучения и энергосвойств плазмы. Оснащён научным оборудованием для соответствующих исследований."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "ca"
	anchored = FALSE
	density = TRUE
	req_access = list(ACCESS_ENGINE_EQUIP)
//	use_power = NO_POWER_USE
	max_integrity = 350
	integrity_failure = 0.2
	circuit = /obj/item/circuitboard/machine/rad_collector
	var/obj/item/tank/internals/plasma/loaded_tank = null
	var/stored_power = 0
	var/last_push
	var/active = 0
	var/locked = FALSE
	var/drainratio = 1
	var/powerproduction_drain = 0.001

	var/bitcoinproduction_drain = 0.15
	var/bitcoinmining = FALSE
	rad_insulation = RAD_EXTREME_INSULATION
	rad_flags = RAD_PROTECT_CONTENTS
	var/obj/item/radio/Radio

/obj/machinery/power/rad_collector/anchored
	anchored = TRUE

/obj/machinery/power/rad_collector/Initialize(mapload)
	. = ..()
	Radio = new /obj/item/radio(src)
	Radio.listening = 0
	Radio.set_frequency(FREQ_ENGINEERING)
	if(anchored)
		connect_to_network()

/obj/machinery/power/rad_collector/Destroy()
	QDEL_NULL(Radio)
	return ..()

/obj/machinery/power/rad_collector/process()
	if(!loaded_tank)
		return
	if(!bitcoinmining)
		if(loaded_tank.air_contents.get_moles(GAS_PLASMA) < 0.0001)
			investigate_log("<font color='red'>out of fuel</font>.", INVESTIGATE_SINGULO)
			playsound(src, 'sound/machines/ding.ogg', 50, 1)
			Radio.talk_into(src, "Недостаточно плазмы в [get_area(src)] [src], наружу извлекается \the [loaded_tank].", FREQ_ENGINEERING)
			eject()
		else
			var/gasdrained = min(powerproduction_drain*drainratio,loaded_tank.air_contents.get_moles(GAS_PLASMA))
			loaded_tank.air_contents.adjust_moles(GAS_PLASMA, -gasdrained)
			loaded_tank.air_contents.adjust_moles(GAS_TRITIUM, gasdrained)

			var/power_produced = RAD_COLLECTOR_OUTPUT
			add_avail(power_produced)
			stored_power-=power_produced
	else if(is_station_level(z) && SSresearch.science_tech)
		if(!loaded_tank.air_contents.get_moles(GAS_TRITIUM) || !loaded_tank.air_contents.get_moles(GAS_O2))
			playsound(src, 'sound/machines/ding.ogg', 50, 1)
			Radio.talk_into(src, "Недостаточно тритий-кислородной смеси в [get_area(src)] [src] для производства научных очков, наружу извлекается \the [loaded_tank].", FREQ_ENGINEERING)
			eject()
		else
			var/gasdrained = bitcoinproduction_drain*drainratio
			loaded_tank.air_contents.adjust_moles(GAS_TRITIUM, -gasdrained)
			loaded_tank.air_contents.adjust_moles(GAS_O2, -gasdrained)
			loaded_tank.air_contents.adjust_moles(GAS_CO2, gasdrained*2)
			var/bitcoins_mined = stored_power*RAD_COLLECTOR_MINING_CONVERSION_RATE
			var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_ENG)
			if(D)
				D.adjust_money(bitcoins_mined)
			SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, bitcoins_mined)
			last_push = stored_power
			stored_power = 0

/obj/machinery/power/rad_collector/interact(mob/user)
	if(anchored)
		if(!src.locked)
			toggle_power()
			user.visible_message("[user.name] [active? "вк":"вык"]лючает [src.name].", \
			span_notice("Вы [active? "вк":"вык"]лючили [src.name]."))
			var/fuel = loaded_tank?.air_contents.get_moles(GAS_PLASMA)
			investigate_log("turned [active?"<font color='green'>on</font>":"<font color='red'>off</font>"] by [key_name(user)]. [loaded_tank?"Fuel: [round(fuel/0.29)]%":"<font color='red'>It is empty</font>"].", INVESTIGATE_SINGULO)
			return
		else
			to_chat(user, span_warning("Механизмы коллектора заблокированы!"))
			return

/obj/machinery/power/rad_collector/can_be_unfasten_wrench(mob/user, silent)
	if(loaded_tank)
		if(!silent)
			to_chat(user, span_warning("Для начала извлеките газовый бак!"))
		return FAILED_UNFASTEN
	return ..()

/obj/machinery/power/rad_collector/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	. = ..()
	if(. == SUCCESSFUL_UNFASTEN)
		if(anchored)
			connect_to_network()
		else
			disconnect_from_network()

/obj/machinery/power/rad_collector/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/tank/internals/plasma))
		if(!anchored)
			to_chat(user, span_warning("Для начала [src] нужно надёжно прикрепить к поверхности!"))
			return TRUE
		if(loaded_tank)
			to_chat(user, span_warning("Внутри уже вставлен газовый бак!"))
			return TRUE
		if(panel_open)
			to_chat(user, span_warning("Для начала закройте панель техобслуживания!"))
			return TRUE
		if(!user.transferItemToLoc(W, src))
			return
		loaded_tank = W
		update_icon()
	else if(W.GetID())
		if(allowed(user))
			if(active)
				locked = !locked
				to_chat(user, span_notice("Вы [locked ? "за" : "раз"]блокировали коллектор."))
			else
				to_chat(user, span_warning("Механизмы устройства могут быть заблокированы только во время работы [src]!"))
		else
			to_chat(user, span_danger("Доступ запрещён."))
			return TRUE
	else
		return ..()

/obj/machinery/power/rad_collector/wrench_act(mob/living/user, obj/item/I)
	default_unfasten_wrench(user, I)
	return TRUE

/obj/machinery/power/rad_collector/screwdriver_act(mob/living/user, obj/item/I)
	if(..())
		return TRUE
	if(loaded_tank)
		to_chat(user, span_warning("Для начала извлеките газовый бак!"))
	else
		default_deconstruction_screwdriver(user, icon_state, icon_state, I)
	return TRUE

/obj/machinery/power/rad_collector/crowbar_act(mob/living/user, obj/item/I)
	if(loaded_tank)
		if(locked)
			to_chat(user, span_warning("Механизмы коллектора заблокированы!"))
			return TRUE
		eject()
		return TRUE
	if(default_deconstruction_crowbar(I))
		return TRUE
	to_chat(user, span_warning("Отсутствует бак с газом!"))
	return TRUE

/obj/machinery/power/rad_collector/multitool_act(mob/living/user, obj/item/I)
	if(!is_station_level(z) && !SSresearch.science_tech)
		to_chat(user, span_warning("[src] не имеет связи с исследовательской системой!"))
		return TRUE
	if(locked)
		to_chat(user, span_warning("Механизмы коллектора заблокированы!"))
		return TRUE
	if(active)
		to_chat(user, span_warning("[src] в процессе работы, идёт выработка [bitcoinmining ? "очков исследования" : "энергии"]."))
		return TRUE
	bitcoinmining = !bitcoinmining
	to_chat(user, span_warning("Вы [bitcoinmining ? "вк":"вык"]лючили исследовательский функционал коллектора."))
	return TRUE

/obj/machinery/power/rad_collector/analyzer_act(mob/living/user, obj/item/I)
	if(loaded_tank)
		loaded_tank.analyzer_act(user, I)
	return TRUE

/obj/machinery/power/rad_collector/return_analyzable_air()
	if(loaded_tank)
		return loaded_tank.return_analyzable_air()
	else
		return null

/obj/machinery/power/rad_collector/examine(mob/user)
	. = ..()
	if(!active)
		if(!bitcoinmining)
			. += span_notice("<b>Таблоид коллектора сообщает:</b>\n\
			\"Включён режим производства энергии. Пожалуйста, вставьте бак с <b>плазмой</b>. Используйте мультитул для смены режима работы.\"")
		else
			. += span_notice("– <b>Таблоид коллектора сообщает:</b>\n\
			\"Включён режим производства научных очков. Пожалуйста, вставьте бак с <b>тритием</b> и <b>кислородом</b>. Используйте мультитул для смены режима работы.\"")

/obj/machinery/power/rad_collector/examine_display_content()
	if(active)
		if(!bitcoinmining)
			. += "\
			– Хранится <b>[DisplayEnergy(stored_power)]</b>, обрабатывается <b>[DisplayPower((RAD_COLLECTOR_OUTPUT)*((1 SECONDS)/SSmachines.wait))]</b> энергии от излучения.\n\
			– <b>Плазма</b> внутри бака радиотрансмутируется в <b>тритий</b>."
		else
			. += "\
			– Производится <b>[(last_push*RAD_COLLECTOR_MINING_CONVERSION_RATE)*((60 SECONDS)/SSmachines.wait)]</b> научных очков в минуту.\n\
			– <b>Тритий</b> и <b>кислород</b> внутри бака сжигаются в <b>углекислый газ</b>."

/obj/machinery/power/rad_collector/obj_break(damage_flag)
	if(!(machine_stat & BROKEN) && !(flags_1 & NODECONSTRUCT_1))
		eject()
		set_machine_stat(machine_stat | BROKEN)

/obj/machinery/power/rad_collector/proc/eject()
	locked = FALSE
	var/obj/item/tank/internals/plasma/Z = src.loaded_tank
	if (!Z)
		return
	Z.forceMove(drop_location())
	Z.layer = initial(Z.layer)
	RESET_PLANE_EXPLICIT(Z, Z)
	src.loaded_tank = null
	if(active)
		toggle_power()
	else
		update_icon()

/obj/machinery/power/rad_collector/rad_act(pulse_strength)
	. = ..()
	if(loaded_tank && active && pulse_strength > RAD_COLLECTOR_EFFICIENCY)
		stored_power += (pulse_strength-RAD_COLLECTOR_EFFICIENCY)*RAD_COLLECTOR_COEFFICIENT

/obj/machinery/power/rad_collector/update_overlays()
	. = ..()
	if(loaded_tank)
		. += "ptank"
	if(machine_stat & (NOPOWER|BROKEN))
		return
	if(active)
		. += "on"


/obj/machinery/power/rad_collector/proc/toggle_power()
	active = !active
	if(active)
		icon_state = "ca_on"
		flick("ca_active", src)
	else
		icon_state = "ca"
		flick("ca_deactive", src)
	update_icon()
	return

#undef RAD_COLLECTOR_EFFICIENCY
#undef RAD_COLLECTOR_COEFFICIENT
#undef RAD_COLLECTOR_STORED_OUT
#undef RAD_COLLECTOR_MINING_CONVERSION_RATE
#undef RAD_COLLECTOR_OUTPUT
