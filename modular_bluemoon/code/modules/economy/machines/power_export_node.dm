#define POWER_EXPORT_SPARK_COOLDOWN (5 SECONDS)
#define WATTS_PER_KILOWATT 1000
#define WATTS_PER_MEGAWATT 1000000
#define POWER_EXPORT_GLOW_LEVELS 3
#define POWER_EXPORT_SPINUP_COOLDOWN (10 SECONDS)
#define POWER_EXPORT_OVERLOAD_SOUND_COOLDOWN (30 SECONDS)
#define POWER_EXPORT_LIGHT_RANGE_PER_LEVEL 0.5
#define POWER_EXPORT_LIGHT_POWER_PER_LEVEL 0.25

/datum/looping_sound/export_node
	start_sound = 'sound/economy/node_spinup.ogg'
	start_length = 2 SECONDS
	start_volume = 35
	mid_sounds = 'sound/economy/node_hum.ogg'
	mid_length = 3 SECONDS
	volume = 25

/datum/controller/subsystem/economy
	/// SSmachines.times_fired цикла, за который считается power_export_paid_w
	var/power_export_cycle
	/// Сколько ватт экспорта уже оплачено за этот цикл со всех узлов
	var/power_export_paid_w = 0

/// Сколько из проданных ватт оплачивается в пределах потолка станции на этот цикл; первый пришедший получает.
/datum/controller/subsystem/economy/proc/claim_power_export(watts)
	if(power_export_cycle != SSmachines.times_fired)
		power_export_cycle = SSmachines.times_fired
		power_export_paid_w = 0
	var/paid = clamp(settings.power_export_station_cap_kw * WATTS_PER_KILOWATT - power_export_paid_w, 0, watts)
	power_export_paid_w += paid
	return paid

/// Цена МДж для бюджета инженерии: база настроек, рынок энергии и цена работы экспорта энергии.
/proc/econ_power_export_price_per_mj()
	var/datum/economy_settings/settings = SSeconomy.settings
	return settings.power_export_credits_per_mj * (settings.work_prices[WORK_ENG_POWER_EXPORT] || 0) * econ_sale_factor(COMMODITY_ENERGY)

/obj/machinery/power/proc/accrue_power_export(credits)
	var/datum/economy_department/engineering/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	engineering?.accrue_power_export(credits * econ_sale_factor(COMMODITY_ENERGY))

/obj/machinery/power/export_node
	name = "power export node"
	desc = "Межсекторный энергоузел: продаёт в сеть сектора излишек мощности станционной сети, оставшийся после всех потребителей. Доход идёт в бюджет инженерии. Подключается к узлу кабеля под собой. Заданная мощность сверх излишка всё равно тянется из сети: станция проседает, APC садят батареи, а узел искрит. Обмотки светятся тем ярче, чем больше заданный отбор; дуги над катушками и «OVR» на табло - перегрузка."
	light_color = LIGHT_COLOR_CYAN
	icon = 'icons/obj/machines/economy/power_export_node.dmi'
	icon_state = "node_off"
	density = TRUE
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/power_export_node
	var/active = FALSE
	var/target_kw = 0
	var/last_export_w = 0
	/// Недобор прошлого цикла, лёгший нагрузкой в этот: без него излишек в окне занижен
	var/shortfall_in_load_w = 0
	var/shortfall_next_w = 0
	/// Длина цикла SSmachines в секундах, из последнего process()
	var/export_seconds = 0
	/// Прошлый цикл заданная мощность не уместилась в излишек
	var/overloaded = FALSE
	/// Уровень свечения, под который сейчас выставлен свет
	var/lit_level = 0
	COOLDOWN_DECLARE(spark_cooldown)
	COOLDOWN_DECLARE(spinup_cooldown)
	COOLDOWN_DECLARE(overload_sound_cooldown)
	var/datum/looping_sound/export_node/soundloop

/obj/machinery/power/export_node/Initialize(mapload)
	. = ..()
	soundloop = new(src)
	connect_to_network()
	update_appearance()

/// Уровень свечения обмоток 1..POWER_EXPORT_GLOW_LEVELS по заданному отбору; 0 - узел не работает.
/obj/machinery/power/export_node/proc/glow_level()
	if(panel_open || !active || (machine_stat & (BROKEN|NOPOWER|MAINT)) || !powernet || !target_kw)
		return 0
	return clamp(CEILING(target_kw * POWER_EXPORT_GLOW_LEVELS / max(SSeconomy.settings.power_export_max_kw, 1), 1), 1, POWER_EXPORT_GLOW_LEVELS)

/obj/machinery/power/export_node/proc/working_state()
	var/level = glow_level()
	if(!level)
		return null
	return overloaded ? "node_overload" : "node_on_[level]"

/obj/machinery/power/export_node/update_icon_state()
	if(panel_open)
		icon_state = "node_panel"
	else if(!active || (machine_stat & BROKEN))
		icon_state = "node_off"
	else
		icon_state = working_state() || "node"
	return ..()

/obj/machinery/power/export_node/update_overlays()
	. = ..()
	if(powernet)
		. += "node_terminal"
	var/working = working_state()
	if(working)
		. += emissive_appearance(icon, "[working]_glow", offset_spokesman = src)

/obj/machinery/power/export_node/on_stat_update(old_value)
	. = ..()
	update_appearance()

/// Свет обмоток только при продаже без перегрузки: в перегрузке светят лишь дуги маской и искры.
/obj/machinery/power/export_node/update_appearance(updates = ALL)
	. = ..()
	var/level = overloaded ? 0 : glow_level()
	if(level == lit_level)
		return
	lit_level = level
	if(!level)
		set_light(0)
		return
	set_light((level + POWER_EXPORT_GLOW_LEVELS) * POWER_EXPORT_LIGHT_RANGE_PER_LEVEL, (level + 1) * POWER_EXPORT_LIGHT_POWER_PER_LEVEL)

/obj/machinery/power/export_node/Destroy()
	if(powernet)
		LAZYREMOVE(powernet.export_nodes, src)
	QDEL_NULL(soundloop)
	return ..()

/obj/machinery/power/export_node/connect_to_network()
	. = ..()
	update_appearance()

/obj/machinery/power/export_node/disconnect_from_network()
	if(powernet)
		LAZYREMOVE(powernet.export_nodes, src)
	. = ..()
	if(.)
		stop_selling()
		update_appearance()

/obj/machinery/power/export_node/examine(mob/user)
	. = ..()
	var/datum/economy_settings/settings = SSeconomy.settings
	if(!on_station_grid())
		. += span_warning("Узел стоит вне станции: сектор покупает энергию только из станционной сети, отсюда узел не продаёт.")
	. += span_notice("Отбор: [target_kw] кВт из [settings.power_export_max_kw] возможных, шаг [settings.power_export_step_kw] кВт. Цена по рынку энергии: [round(econ_power_export_price_per_mj(), 0.01)] кр. за МДж.")
	. += span_notice("Сектор оплачивает не больше [settings.power_export_station_cap_kw] кВт со всех узлов станции вместе, сверх этого энергия уходит бесплатно.")
	. += span_notice("Узел [active ? "включён" : "выключен"][powernet ? "" : ", кабеля под ним нет"][panel_open ? ", панель открыта - продажа остановлена" : ""].")
	if(overloaded)
		. += span_warning((last_export_w ? "Отбор больше излишка сети: продаётся только [DisplayPower(last_export_w)], а недостающее узел всё равно тянет из сети." : "Излишка в сети нет: узел ничего не продаёт, но тянет из сети всю заданную мощность."))
	else if(last_export_w)
		. += span_notice("Сейчас продаётся [DisplayPower(last_export_w)].")

/obj/machinery/power/export_node/proc/set_target_kw(kw)
	if(!isnum(kw))
		return
	var/datum/economy_settings/settings = SSeconomy.settings
	target_kw = clamp(round(kw, settings.power_export_step_kw), 0, settings.power_export_max_kw)
	update_hum()
	update_appearance()

/obj/machinery/power/export_node/proc/toggle(mob/user)
	active = !active
	if(active)
		machine_wake()
		update_hum()
	else
		stop_selling()
	update_appearance()
	log_game("[key_name(user)] [active ? "включил" : "выключил"] узел экспорта энергии ([target_kw] кВт) в [AREACOORD(src)]")

/obj/machinery/power/export_node/proc/can_export()
	return active && powernet && target_kw && !panel_open && !(machine_stat & (BROKEN|NOPOWER|MAINT)) && on_station_grid()

/obj/machinery/power/export_node/proc/on_station_grid()
	var/turf/node_turf = get_turf(src)
	return node_turf && is_station_level(node_turf.z)

/obj/machinery/power/export_node/process(delta_time)
	if(!active)
		stop_selling()
		return machine_sleep()
	if(!can_export())
		stop_selling()
		return
	export_seconds = delta_time
	LAZYOR(powernet.export_nodes, src)
	update_hum()

/// Зовётся из reset() сети после всех потребителей и зарядки СМЕС: продаёт остаток, недобор ложится на сеть следующим циклом.
/obj/machinery/power/export_node/proc/sell_surplus(datum/powernet/net)
	shortfall_in_load_w = shortfall_next_w
	shortfall_next_w = 0
	if(net != powernet || !can_export())
		last_export_w = 0
		set_overloaded(FALSE)
		return
	var/requested = target_kw * WATTS_PER_KILOWATT
	last_export_w = clamp(net.avail - net.load, 0, requested)
	net.load += last_export_w
	var/shortfall = requested - last_export_w
	set_overloaded(shortfall > 0)
	if(shortfall > 0)
		shortfall_next_w = shortfall
		net.delayedload += shortfall
		if(COOLDOWN_FINISHED(src, spark_cooldown))
			COOLDOWN_START(src, spark_cooldown, POWER_EXPORT_SPARK_COOLDOWN)
			do_sparks(3, TRUE, src)
			if(COOLDOWN_FINISHED(src, overload_sound_cooldown))
				COOLDOWN_START(src, overload_sound_cooldown, POWER_EXPORT_OVERLOAD_SOUND_COOLDOWN)
				playsound(src, 'sound/economy/node_overload.ogg', 50, FALSE)
	var/paid_w = SSeconomy.claim_power_export(last_export_w)
	accrue_power_export(paid_w * export_seconds / WATTS_PER_MEGAWATT * SSeconomy.settings.power_export_credits_per_mj)

/obj/machinery/power/export_node/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PowerExportNode", name)
		ui.open()

/obj/machinery/power/export_node/ui_data(mob/user)
	var/datum/economy_settings/settings = SSeconomy.settings
	var/market_factor = econ_sale_factor(COMMODITY_ENERGY)
	var/price = econ_power_export_price_per_mj()
	var/paid_w = min(last_export_w, settings.power_export_station_cap_kw * WATTS_PER_KILOWATT)
	return list(
		"active" = active,
		"connected" = !!powernet,
		"panel_open" = panel_open,
		"on_station" = on_station_grid(),
		"target_kw" = target_kw,
		"max_kw" = settings.power_export_max_kw,
		"step_kw" = settings.power_export_step_kw,
		"station_cap_kw" = settings.power_export_station_cap_kw,
		"export_w" = last_export_w,
		"surplus_w" = powernet ? max(powernet.netexcess + last_export_w + shortfall_in_load_w, 0) : 0,
		"base_price_per_mj" = round(settings.power_export_credits_per_mj * (settings.work_prices[WORK_ENG_POWER_EXPORT] || 0), 0.01),
		"market_percent" = round(market_factor * 100),
		"price_per_mj" = round(price, 0.01),
		"income_per_minute" = round(paid_w / WATTS_PER_MEGAWATT * (1 MINUTES / (1 SECONDS)) * price),
		"payout_minutes" = ECON_POWER_EXPORT_PAYOUT_INTERVAL / (1 MINUTES),
		"payout_bulk" = ECON_POWER_EXPORT_PAYOUT_BULK,
	)

/obj/machinery/power/export_node/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("toggle")
			toggle(usr)
			return TRUE
		if("set_draw")
			var/kw = econ_ui_number(params["kw"])
			if(isnull(kw))
				return FALSE
			set_target_kw(kw)
			return TRUE
	return FALSE

/obj/machinery/power/export_node/proc/stop_selling()
	last_export_w = 0
	shortfall_in_load_w = 0
	shortfall_next_w = 0
	set_overloaded(FALSE)
	update_hum()

/// Гул идёт, пока узел может продавать; раскрутка не повторяется при частых переключениях.
/obj/machinery/power/export_node/proc/update_hum()
	if(!soundloop)
		return
	if(!can_export())
		soundloop.stop()
		return
	if(soundloop.timerid)
		return
	soundloop.skip_starting_sounds = !COOLDOWN_FINISHED(src, spinup_cooldown)
	COOLDOWN_START(src, spinup_cooldown, POWER_EXPORT_SPINUP_COOLDOWN)
	soundloop.start()

/obj/machinery/power/export_node/proc/set_overloaded(state)
	if(overloaded == state)
		return
	overloaded = state
	update_appearance()

/obj/machinery/power/export_node/can_be_unfasten_wrench(mob/user, silent)
	if(active)
		if(!silent)
			to_chat(user, span_warning("Сначала выключите [src]."))
		return FAILED_UNFASTEN
	return ..()

/obj/machinery/power/export_node/wrench_act(mob/living/user, obj/item/tool)
	if(default_unfasten_wrench(user, tool) != SUCCESSFUL_UNFASTEN)
		return TRUE
	if(anchored)
		connect_to_network()
	else
		disconnect_from_network()
	update_appearance()
	return TRUE

/obj/machinery/power/export_node/screwdriver_act(mob/living/user, obj/item/tool)
	. = default_deconstruction_screwdriver(user, "node_panel", "node_off", tool)
	update_hum()
	update_appearance()

/obj/machinery/power/export_node/crowbar_act(mob/living/user, obj/item/tool)
	if(active)
		to_chat(user, span_warning("Сначала выключите [src]."))
		return TRUE
	return default_deconstruction_crowbar(tool)

/obj/item/circuitboard/machine/power_export_node
	name = "Power Export Node (Machine Board)"
	icon_state = "engineering"
	build_path = /obj/machinery/power/export_node
	req_components = list(/obj/item/stock_parts/capacitor = 4, /obj/item/stack/cable_coil = 10)

#undef POWER_EXPORT_OVERLOAD_SOUND_COOLDOWN
#undef POWER_EXPORT_LIGHT_POWER_PER_LEVEL
#undef POWER_EXPORT_LIGHT_RANGE_PER_LEVEL
#undef POWER_EXPORT_SPINUP_COOLDOWN
#undef POWER_EXPORT_GLOW_LEVELS
#undef WATTS_PER_MEGAWATT
#undef WATTS_PER_KILOWATT
#undef POWER_EXPORT_SPARK_COOLDOWN
