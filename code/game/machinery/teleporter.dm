/obj/machinery/teleport
	name = "teleport"
	icon = 'icons/obj/machines/teleporter.dmi'
	density = TRUE

/obj/machinery/teleport/hub
	name = "teleporter hub"
	desc = "Хаб телепортационной машины."
	icon_state = "tele0"
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 2000
	circuit = /obj/item/circuitboard/machine/teleporter_hub
	var/accuracy = 0
	var/obj/machinery/teleport/station/power_station
	var/calibrated //Calibration prevents mutation

/obj/machinery/teleport/hub/Initialize(mapload)
	. = ..()
	link_power_station()

/obj/machinery/teleport/hub/Destroy()
	if (power_station)
		power_station.teleporter_hub = null
		power_station = null
	return ..()

/obj/machinery/teleport/hub/RefreshParts()
	var/A = 0
	for(var/obj/item/stock_parts/matter_bin/M in component_parts)
		A += M.rating
	accuracy = A

/obj/machinery/teleport/hub/examine_display_content()
	. += "– Вероятность телепортационного сбоя уменьшена на <b>[(accuracy*25)-25]%</b>."

/obj/machinery/teleport/hub/proc/link_power_station()
	if(power_station)
		return
	for(var/direction in GLOB.cardinals)
		power_station = locate(/obj/machinery/teleport/station, get_step(src, direction))
		if(power_station)
			break
	return power_station

/obj/machinery/teleport/hub/Bumped(atom/movable/AM)
	if(is_centcom_level(z))
		to_chat(AM, "You can't use this here.")
		return
	if(is_ready())
		teleport(AM)

/obj/machinery/teleport/hub/attackby(obj/item/W, mob/user, params)
	if(default_deconstruction_screwdriver(user, "tele-o", "tele0", W))
		if(power_station && power_station.engaged)
			power_station.engaged = 0 //hub with panel open is off, so the station must be informed.
			update_icon()
		return
	if(default_deconstruction_crowbar(W))
		return
	return ..()

/obj/machinery/teleport/hub/proc/teleport(atom/movable/M as mob|obj, turf/T)
	var/obj/machinery/computer/teleporter/com = power_station.teleporter_console
	if (QDELETED(com))
		return
	if (QDELETED(com.target))
		com.target = null
		visible_message("<span class='alert'>Невозможно аутентифицировать заданные координаты. Пожалуйста, переутвердите координатную матрицу.</span>")
		return
	if (ismovable(M))
		if(do_teleport(M, com.target, channel = TELEPORT_CHANNEL_BLUESPACE))
			use_power(5000)

			if(!calibrated && iscarbon(M) && prob(30 - ((accuracy) * 10))) //oh dear a problem
				var/mob/living/carbon/C = M
				if(C.dna?.species && C.dna.species.id != "fly" && !HAS_TRAIT(C, TRAIT_RADIMMUNE))
					to_chat(C, span_italics("Вы слышите жужжание в ваших ушах."))
					C.set_species(/datum/species/fly)
					log_game("[C] ([key_name(C)]) was turned into a fly person")
					C.apply_effect((rand(120 - accuracy * 40, 180 - accuracy * 60)), EFFECT_IRRADIATE, 0)

			calibrated = FALSE
	return

/obj/machinery/teleport/hub/update_icon_state()
	if(panel_open)
		icon_state = "tele-o"
	else if(is_ready())
		icon_state = "tele1"
	else
		icon_state = "tele0"

/obj/machinery/teleport/hub/power_change()
	..()
	update_icon()

/obj/machinery/teleport/hub/proc/is_ready()
	. = !panel_open && !(machine_stat & (BROKEN|NOPOWER)) && power_station && power_station.engaged && !(power_station.machine_stat & (BROKEN|NOPOWER))

/obj/machinery/teleport/hub/syndicate/Initialize(mapload)
	. = ..()
	component_parts += new /obj/item/stock_parts/matter_bin/super(null)
	RefreshParts()


/obj/machinery/teleport/station
	name = "teleporter station"
	desc = "Станция питания блюспейс-телепортера. Используется для переключения питания и активации пробного телепорта для предотвращения неполадок."
	icon_state = "controller"
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 2000
	circuit = /obj/item/circuitboard/machine/teleporter_station
	var/engaged = FALSE
	var/obj/machinery/computer/teleporter/teleporter_console
	var/obj/machinery/teleport/hub/teleporter_hub
	var/list/linked_stations = list()
	var/efficiency = 0

/obj/machinery/teleport/station/Initialize(mapload)
	. = ..()
	link_console_and_hub()

/obj/machinery/teleport/station/RefreshParts()
	var/E
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		E += C.rating
	efficiency = E - 1

/obj/machinery/teleport/station/examine(mob/user)
	. = ..()
	if(!panel_open)
		. += span_notice("Панель <i>привинчена</i>, мешая связыванию устройств и укладке кабеля панели.")
	else
		. += span_notice("<i>Связывающее</i> устройство теперь можно <i>отсканировать</i> мультитулом.\
		<i>Проводка</i> может быть <i>подсоединена<i> к ближайшей консоли и хабу при помощи пары кусачек.")

/obj/machinery/teleport/station/examine_display_content()
	. += "– Станцию можно подключить к <b>[efficiency]</b> ед. других станций"

/obj/machinery/teleport/station/proc/link_console_and_hub()
	for(var/direction in GLOB.cardinals)
		teleporter_hub = locate(/obj/machinery/teleport/hub, get_step(src, direction))
		if(teleporter_hub)
			teleporter_hub.link_power_station()
			break
	for(var/direction in GLOB.cardinals)
		teleporter_console = locate(/obj/machinery/computer/teleporter, get_step(src, direction))
		if(teleporter_console)
			teleporter_console.link_power_station()
			break
	return teleporter_hub && teleporter_console


/obj/machinery/teleport/station/Destroy()
	if(teleporter_hub)
		teleporter_hub.power_station = null
		teleporter_hub.update_icon()
		teleporter_hub = null
	if (teleporter_console)
		teleporter_console.power_station = null
		teleporter_console = null
	return ..()

/obj/machinery/teleport/station/attackby(obj/item/W, mob/user, params)
	if(default_deconstruction_screwdriver(user, "controller-o", "controller", W))
		update_icon()
		return TRUE

	else if(default_deconstruction_crowbar(W))
		return TRUE

	else
		return ..()

/obj/machinery/teleport/station/multitool_act(mob/living/user, obj/item/tool)
	..()
	if(panel_open)
		tool.buffer = src
		to_chat(user, "<span class='caution'>Вы загрузили данные из буфера [tool.name]'.</span>")
	else
		if(tool.buffer && istype(tool.buffer, /obj/machinery/teleport/station) && tool.buffer != src)
			if(linked_stations.len < efficiency)
				linked_stations.Add(tool.buffer)
				tool.buffer = null
				to_chat(user, "<span class='caution'>Вы загрузили данные из буфера [tool.name].</span>")
			else
				to_chat(user, span_alert("Эта станция переполнена информацией, попробуйте улучшить её."))
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/teleport/station/wirecutter_act(mob/living/user, obj/item/tool)
	..()
	if(panel_open)
		link_console_and_hub()
		to_chat(user, "<span class='caution'>Вы переподключили станцию к ближайшей машинерии.</span>")
		return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/teleport/station/interact(mob/user)
	toggle(user)

/obj/machinery/teleport/station/proc/toggle(mob/user)
	if(machine_stat & (BROKEN|NOPOWER) || !teleporter_hub || !teleporter_console )
		return
	if (teleporter_console.target)
		if(teleporter_hub.panel_open || teleporter_hub.machine_stat & (BROKEN|NOPOWER))
			to_chat(user, span_alert("Телепортерный хаб не отвечает!"))
		else
			engaged = !engaged
			use_power(5000)
			to_chat(user, span_notice("Телепортер [engaged ? "вк" : "вык"]лючается!</span>"))
	else
		to_chat(user, span_alert("Цель не обнаружена."))
		engaged = FALSE
	teleporter_hub.update_icon()
	add_fingerprint(user)

/obj/machinery/teleport/station/power_change()
	..()
	update_icon()
	if(teleporter_hub)
		teleporter_hub.update_icon()

/obj/machinery/teleport/station/update_icon_state()
	if(panel_open)
		icon_state = "controller-o"
	else if(machine_stat & (BROKEN|NOPOWER))
		icon_state = "controller-p"
	else if(teleporter_console && teleporter_console.calibrating)
		icon_state = "controller-c"
	else
		icon_state = "controller"
