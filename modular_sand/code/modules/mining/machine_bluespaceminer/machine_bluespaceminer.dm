GLOBAL_VAR_INIT(bsminers_lock, FALSE)

#define BLUESPACE_MINER_BONUS_MULT		CONFIG_GET(number/bluespaceminer_mult_output)
#define BLUESPACE_MINER_CRYSTAL_TIER	CONFIG_GET(number/bluespaceminer_crystal_tier)
#define TIME_TO_CORE_DESTROY_MINUTES	CONFIG_GET(number/bluespaceminer_core_work_time_minutes)
#define TIME_TO_CORE_DESTROY 			(TIME_TO_CORE_DESTROY_MINUTES MINUTES)
#define CORE_CHANSE_NO_DAMAGE			CONFIG_GET(number/bluespaceminer_core_work_chanse_no_damage)
#define INSTABILITY_COOLDOWN_TIME		CONFIG_GET(number/bluespaceminer_instability_cooldown)

#define CORE_INTEGRITY_PERCENT bs_core ? PERCENT(bs_core.obj_integrity / bs_core.max_integrity) : 0
#define CORE_DAMAGE_PER_SECOND (round(((/obj/item/assembly/signaler/anomaly/bluespace::max_integrity SECONDS) / TIME_TO_CORE_DESTROY) * 10000)/10000)
#define CORE_DAMAGE_DT(DT) (round(CORE_DAMAGE_PER_SECOND*DT*10000)/10000)

#define BLUESPACE_INSTABILITY_EVENT_RADIUS 7

#define INSTABILITY_ON_ZLEVEL_TO_EVENT 100

#define BLUESPACE_MINER_SOUND_CHANCE 1
/// Шанс в секунду"«дёрнуть" температуру воздуха вокруг блюспейс-майнера
#define BSM_AMBIENT_TEMP_CHAOS_PROB 2

#define BSM_CORE_TEMP_OPTIMAL_LOW (T0C - 10)
#define BSM_CORE_TEMP_OPTIMAL_HIGH (T0C + 10)
/// Номинальное давление вокруг майнера (кПа); вне ±BSM_CORE_PRESSURE_TOLERANCE_KPA — двойной износ ядра
#define BSM_CORE_PRESSURE_NOMINAL_KPA 101.28
#define BSM_CORE_PRESSURE_TOLERANCE_KPA 50
/// Интервал повтора радио-предупреждений о ядре (секунды), как `WARNING_DELAY` у суперматерии.
#define BSM_CORE_WARNING_REPEAT_AFTER 60

#define CORE_INSERT_REG_SIGNAL RegisterSignal(bs_core, COMSIG_PARENT_QDELETING, PROC_REF(on_core_remove))

#define INSTABILITY_SETTINGS_PERCENT "percent"
#define INSTABILITY_SETTINGS_VALUE "instability"
#define INSTABILITY_SETTINGS_CORE_ICON_STATE "add_core_state"
#define INSTABILITY_SETTINGS_EXAMINE_COLOR "examine_color"
#define INSTABILITY_LIST_ADD(percent, instability, core_state, examine_color) list(\
		INSTABILITY_SETTINGS_PERCENT = percent,\
		INSTABILITY_SETTINGS_VALUE = instability,\
		INSTABILITY_SETTINGS_CORE_ICON_STATE = core_state,\
		INSTABILITY_SETTINGS_EXAMINE_COLOR = examine_color,\
	)

#define MINER_UPDATE_ICON update_icon(UPDATE_ICON_STATE | UPDATE_OVERLAYS)

/obj/machinery/mineral/bluespace_miner
	name = "bluespace mining machine"
	desc = "Машина, что используя Bluespace медленно добывает ресурсы из других миров и помещает их в привязанное хранилище материалов."
	icon = 'modular_sand/icons/obj/machines/mining_machines.dmi'
	icon_state = "bsminer"
	density = TRUE
	can_be_unanchored = TRUE
	circuit = /obj/item/circuitboard/machine/bluespace_miner
	layer = BELOW_OBJ_LAYER
	init_process = TRUE
	idle_power_usage = 100
	active_power_usage = 5000

	var/obj/item/assembly/signaler/anomaly/bluespace/bs_core

	var/registered_z = 0
	COOLDOWN_DECLARE(z_reg_cooldown)
	var/const/z_reg_cooldown_time = 20 SECONDS

	COOLDOWN_DECLARE(z_check_cooldown)
	var/const/z_check_cooldown_time = 2 MINUTES
	var/last_z_check = FALSE

	var/list/ore_rates = list(
		/datum/material/iron = 0.05,
		/datum/material/glass = 0.05,
		/datum/material/silver = 0.025,
		/datum/material/titanium = 0.025,
		/datum/material/uranium = 0.025,
		/datum/material/plastic = 0.025,
		/datum/material/gold = 0.01,
		/datum/material/diamond = 0.01,
		/datum/material/plasma = 0.01
		)
	var/datum/component/remote_materials/materials

	var/multiplier = 0
	var/no_core_damage = FALSE

	var/static/core_damage_per_tick
	COOLDOWN_DECLARE_STATIC(core_damage_updt_cooldown)
	var/const/core_damage_updt_cooldown_time = 1 MINUTES

	COOLDOWN_DECLARE(instability_cooldown)
	var/bsm_rainbow_until = 0
	/// `REALTIMEOFDAY` последнего оповещения по порогу 50% / 10%; сброс в 0 при целостности выше порога (как `lastwarning` у СМ).
	var/last_core_radio_warning_50 = 0
	var/last_core_radio_warning_10 = 0
	var/static/list/instability_settings = list(
		INSTABILITY_LIST_ADD(100, 10, "inst1", "#c5641e"),
		INSTABILITY_LIST_ADD(50, 20, "inst2", "#c51e1e"),
		INSTABILITY_LIST_ADD(10, 50, "inst3", "#c51e1e"),
	)

#undef INSTABILITY_LIST_ADD

/obj/machinery/mineral/bluespace_miner/Initialize(mapload)
	. = ..()
	if(bs_core)
		CORE_INSERT_REG_SIGNAL

	materials = AddComponent(/datum/component/remote_materials, "bsm", mapload)

	multiplier *= BLUESPACE_MINER_BONUS_MULT

/obj/machinery/mineral/bluespace_miner/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))

		var/list/display_list = list("Статус дисплей показывает:")
		display_list += "Эффективность: <b>[PERCENT(multiplier)]%</b>. \
		Добыча блюспейс-кристаллов: <b>[multiplier >= BLUESPACE_MINER_CRYSTAL_TIER ? span_green("Активна") : span_danger("Неактивна")]</b>"
		if(no_core_damage)
			display_list += "Установлен [span_bold(span_green("стабилизатор"))], ядро [span_bold(span_green("не будет"))] повреждаться при работе."
		else
			display_list += "Ожидаемое время работы целого ядра <b>~[TIME_TO_CORE_DESTROY_MINUTES]</b> минут."
			display_list += "Рекомендуемая температура вокруг майнера: от <b>−10°C</b> до <b>+10°C</b>. Ниже или выше — ядро изнашивается <b>в два раза быстрее</b>."
			display_list += "Рекомендуемое давление: около <b>[BSM_CORE_PRESSURE_NOMINAL_KPA] кПа</b> (±<b>[BSM_CORE_PRESSURE_TOLERANCE_KPA] кПа</b>). Сильнее отклонение — ядро изнашивается <b>в два раза быстрее</b> (умножается с температурой)."
		if(bs_core)
			var/list/inst_pattern = LAZYACCESS(instability_settings, get_instability_level())
			var/percent_core_integrity_text = span_bold("[CORE_INTEGRITY_PERCENT]%")
			if(inst_pattern)
				percent_core_integrity_text = "<span style='color:[inst_pattern[INSTABILITY_SETTINGS_EXAMINE_COLOR]]'>[percent_core_integrity_text]</span>"
			else
				percent_core_integrity_text = span_green(percent_core_integrity_text)

			display_list += "Состояние Bluespace ядра: [percent_core_integrity_text]"
			var/core_level = get_instability_level()
			switch(core_level)
				if(0)
					display_list += span_notice("Случайные блюспейс-эффекты от майнера маловероятны — ядро ещё в норме.")
				if(1)
					display_list += span_notice("Ожидаются в основном безвредные проявления (игрушки, свет, звук).")
				if(2)
					display_list += span_warning("Возможны малые угрозы: газы, давление и т.п.")
				if(3)
					display_list += span_boldwarning("Критическое состояние ядра: возможны аномалии, порталы, спавнеры и метеоритные удары!")

		. += span_notice(jointext(display_list, "\n- "))
	else
		. += span_notice("На машине есть небольшой дисплей, но вам нужно подойти ближе, чтобы разглядеть его.")
	if(!bs_core)
		. += span_warning("Bluespace ядро не установлено, без него машина не будет работать.")
	if(on_hold())
		. += span_warning("Все майнеры на станции отключены; пожалуйста, свяжитесь с командованием.")
	if(!anchored)
		. += span_warning("Машина не будет работать, пока не будет надежно прикреплена к полу.")
	if(!materials?.silo)
		. += span_warning("Хранилище материалов не подключено. Свяжите хранилище с машиной, используя мультитул.")
	else if(materials?.on_hold())
		. += span_warning("Доступ к материалам приостановлен, пожалуйста свяжитесь с квартирмейстером.")

/obj/machinery/mineral/bluespace_miner/RefreshParts()
	multiplier = 0
	var/stock_amt = 0
	for(var/obj/item/stock_parts/L in component_parts)
		if(!istype(L))
			continue
		multiplier += L.rating
		stock_amt++
	multiplier /= stock_amt
	if(multiplier >= BLUESPACE_MINER_CRYSTAL_TIER)
		ore_rates[/datum/material/bluespace] = 0.005
		ore_rates[/datum/material/bananium] = 0.005
	else
		ore_rates -= /datum/material/bluespace
		ore_rates -= /datum/material/bananium

	multiplier *= BLUESPACE_MINER_BONUS_MULT

/obj/machinery/mineral/bluespace_miner/deconstruct(disassembled)
	if(disassembled && bs_core)
		bs_core.forceMove(drop_location())
		on_core_remove()

	return ..()

/obj/machinery/mineral/bluespace_miner/Destroy()
	materials = null
	if(registered_z)
		SSmachines.bluespaceminer_by_zlevel[registered_z] -= src
	QDEL_NULL(bs_core)
	return ..()

/obj/machinery/mineral/bluespace_miner/is_operational()
	. = ..()
	if(!.)
		return
	if(!anchored || !bs_core || !materials?.silo || !materials?.mat_container || materials?.on_hold())
		return FALSE
	if(on_hold())
		return FALSE

/obj/machinery/mineral/bluespace_miner/update_icon_state()
	icon_state = initial(icon_state) + (is_operational() ? "-work" : "")
	return ..()

/obj/machinery/mineral/bluespace_miner/update_overlays()
	. = ..()
	var/static/list/instability_overlay_colors = list(
		"#49C25B",
		"#81B73E",
		"#E4C23B",
		"#F4A029",
		"#CD1616"
	)

	var/suffix = is_operational() ? "-work" : ""

	var/inst = clamp(get_instability_level() * (INSTABILITY_ON_ZLEVEL_TO_EVENT / 3), 0, INSTABILITY_ON_ZLEVEL_TO_EVENT)

	if(inst)
		var/idx = min(5, floor(inst / (INSTABILITY_ON_ZLEVEL_TO_EVENT / 4)) + 1)
		for(var/i=1, i<=idx, i++)
			var/mutable_appearance/MA = mutable_appearance(icon, "overlay-instability[suffix]", color = instability_overlay_colors[idx])
			MA.pixel_y += 2*(i-1)
			. += MA

	if(!(panel_open || bs_core))
		return

	if(bs_core)
		var/add_core_state = ""
		var/list/inst_pattern = LAZYACCESS(instability_settings, get_instability_level())
		if(inst_pattern)
			add_core_state = inst_pattern[INSTABILITY_SETTINGS_CORE_ICON_STATE]
			add_core_state = add_core_state ? "-[add_core_state]" : ""
		. += mutable_appearance(icon, "overlay-core[add_core_state][suffix]")

	if(panel_open)
		. += mutable_appearance(icon, "overlay-maintenance[suffix]")

	// Rainbow prism must sit above overlay-core or the core sprite hides it entirely.
	if(world.time < bsm_rainbow_until)
		var/static/list/rainbow_prism_colors = list("#e40303", "#ff8c00", "#ffed00", "#008026", "#24408e", "#732982")
		for(var/prism_color in rainbow_prism_colors)
			var/mutable_appearance/prism = mutable_appearance(icon, "overlay-instability[suffix]")
			prism.color = prism_color
			prism.alpha = 130
			prism.blend_mode = BLEND_ADD
			. += prism

/obj/machinery/mineral/bluespace_miner/attackby(obj/item/I, mob/living/user, params)
	if(bs_core || !istype(I, ANOMALY_CORE_BLUESPACE))
		return ..()
	add_fingerprint(user)
	to_chat(user, span_notice("Вы начали установку Bluespace ядра в машину."))
	playsound(src, 'sound/items/deconstruct.ogg', 60, TRUE)
	if(!do_after(user, 1.5 SECONDS, src))
		return
	if(user.temporarilyRemoveItemFromInventory(I))
		I.forceMove(src)
		bs_core = I
		last_core_radio_warning_50 = 0
		last_core_radio_warning_10 = 0
		CORE_INSERT_REG_SIGNAL

/obj/machinery/mineral/bluespace_miner/process(delta_time)
	MINER_UPDATE_ICON
	core_damage_updt(delta_time)
	var/operational = is_operational()
	zlevel_reg(!operational)
	if(!operational)
		return

	if(!no_core_damage && !DT_PROB(CORE_CHANSE_NO_DAMAGE, delta_time))
		var/env_damage_mult = get_bs_core_temp_damage_multiplier() * get_bs_core_pressure_damage_multiplier()
		bs_core.take_damage(core_damage_per_tick * env_damage_mult, sound_effect = FALSE)
	check_core_integrity_radio_warnings()

	if(instability_check(delta_time) && QDELETED(src))
		return PROCESS_KILL
	bsm_ambient_temperature_chaos(delta_time)
	if(DT_PROB(BLUESPACE_MINER_SOUND_CHANCE, delta_time))
		playsound(src, pick(GLOB.otherworld_sounds), 100, TRUE)
		balloon_alert_to_viewers(pick(
			"из машины исходят странные звуки...",
			"блюспейс шепчет...",
			"что-то дребезжит внутри...",
			"слышен чужой гул...",
			"искажение в голове от шума...",
		))

	var/datum/material/ore = pick(ore_rates)
	var/datum/component/material_container/mat_container = materials.mat_container
	mat_container.bsm_insert(((ore_rates[ore] * 1000) * multiplier), ore)

/obj/machinery/mineral/bluespace_miner/proc/core_damage_updt(delta_time)
	if(COOLDOWN_FINISHED(src, core_damage_updt_cooldown) || !core_damage_per_tick)
		COOLDOWN_START(src, core_damage_updt_cooldown, core_damage_updt_cooldown_time)
		core_damage_per_tick = CORE_DAMAGE_DT(delta_time)

/obj/machinery/mineral/bluespace_miner/proc/get_bs_core_temp_damage_multiplier()
	. = 1
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/datum/gas_mixture/env = T.return_air()
	if(!env)
		return
	var/env_temp = env.return_temperature()
	if(env_temp < BSM_CORE_TEMP_OPTIMAL_LOW || env_temp > BSM_CORE_TEMP_OPTIMAL_HIGH)
		return 2

/obj/machinery/mineral/bluespace_miner/proc/get_bs_core_pressure_damage_multiplier()
	. = 1
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/datum/gas_mixture/env = T.return_air()
	if(!env)
		return
	var/pressure_kpa = env.return_pressure()
	if(pressure_kpa < BSM_CORE_PRESSURE_NOMINAL_KPA - BSM_CORE_PRESSURE_TOLERANCE_KPA || pressure_kpa > BSM_CORE_PRESSURE_NOMINAL_KPA + BSM_CORE_PRESSURE_TOLERANCE_KPA)
		return 2

/// Случайно нагревает или охлаждает газ на 1–3 открытых тайлах рядом.
/obj/machinery/mineral/bluespace_miner/proc/bsm_ambient_temperature_chaos(delta_time)
	if(!DT_PROB(BSM_AMBIENT_TEMP_CHAOS_PROB, delta_time))
		return
	var/turf/center = get_turf(src)
	if(!center)
		return
	var/list/open_turfs = list()
	for(var/turf/open/O in range(2, center))
		if(O.air)
			open_turfs += O
	if(!length(open_turfs))
		return
	var/touches = min(rand(1, 3), length(open_turfs))
	for(var/i in 1 to touches)
		var/turf/open/target = pick(open_turfs)
		var/datum/gas_mixture/air = target.air
		var/cur = air.return_temperature()
		if(prob(50))
			air.set_temperature(min(cur + rand(25, 180), 450 + T0C))
		else
			air.set_temperature(max(TCMB + 15, cur - rand(25, 140)))
		target.air_update_turf()

/obj/machinery/mineral/bluespace_miner/proc/zlevel_reg(unreg = FALSE)
	if(unreg && registered_z && COOLDOWN_FINISHED(src, z_reg_cooldown))
		COOLDOWN_START(src, z_reg_cooldown, z_reg_cooldown_time)
		SSmachines.bluespaceminer_by_zlevel[registered_z] -= src
		registered_z = 0
	else if(!unreg && !registered_z)
		SSmachines.bluespaceminer_by_zlevel[src.z] += src
		registered_z = src.z

/obj/machinery/mineral/bluespace_miner/proc/get_instability_level()
	. = 0
	if(!LAZYLEN(instability_settings))
		return

	var/core_integrity = CORE_INTEGRITY_PERCENT
	for(var/i=instability_settings.len, i>=1, i--)
		var/list/inst_settings = instability_settings[i]
		if(core_integrity <= inst_settings[INSTABILITY_SETTINGS_PERCENT])
			return i

/obj/machinery/mineral/bluespace_miner/proc/z_check(force = FALSE)
	if(!force && !COOLDOWN_FINISHED(src, z_check_cooldown))
		return last_z_check
	else
		COOLDOWN_START(src, z_check_cooldown, z_check_cooldown_time)
		last_z_check = is_station_level(z)// || is_mining_level(z)

	return last_z_check

/// Запись в `game.log` (`log_game`) и `message_admins` при срабатывании нестабильности блюспейс-майнера.
/proc/bsm_log_instability(obj/machinery/mineral/bluespace_miner/machine, tier_description, event_description)
	if(QDELETED(machine))
		return
	log_game("Bluespace miner instability ([tier_description]): [event_description] at [get_area_name(machine)] [COORD(machine)].")
	message_admins(span_adminnotice("Bluespace miner instability ([tier_description]): [event_description] at [ADMIN_VERBOSEJMP(machine)]"))

/obj/machinery/mineral/bluespace_miner/proc/instability_check(delta_time = 1)
	if(!COOLDOWN_FINISHED(src, instability_cooldown))
		return
	if(!get_instability_level())
		return
	COOLDOWN_START(src, instability_cooldown, INSTABILITY_COOLDOWN_TIME)
	instability_event_start()
	return TRUE

/obj/machinery/mineral/bluespace_miner/proc/instability_event_start()

	var/core_level = get_instability_level()
	var/picked
	switch(core_level)
		if(1)
			picked = pickweight(GLOB.bsm_low_threat_pool)
			if(!picked)
				return
			var/datum/bsm_instability_effect/fx = new picked()
			fx.trigger(src)
			bsm_log_instability(src, "low", "[fx.type]")
		if(2)
			picked = pickweight(GLOB.bsm_medium_threat_pool)
			if(!picked)
				return
			var/datum/bsm_instability_effect/fx = new picked()
			fx.trigger(src)
			bsm_log_instability(src, "medium", "[fx.type]")
		if(3)
			picked = pickweight(bsm_get_high_threat_pool())
			if(!picked)
				return
			bsm_fire_high_threat_pick(src, picked)

/obj/machinery/mineral/bluespace_miner/proc/on_core_remove()
	SIGNAL_HANDLER

	UnregisterSignal(bs_core, COMSIG_PARENT_QDELETING)
	bs_core = null
	last_core_radio_warning_50 = 0
	last_core_radio_warning_10 = 0

/// Радио-предупреждения о ядре: Science при ≤50%, Common+громко при ≤10%; повтор каждые `BSM_CORE_WARNING_REPEAT_AFTER` с (как суперматерия).
/obj/machinery/mineral/bluespace_miner/proc/check_core_integrity_radio_warnings()
	if(no_core_damage || !bs_core || QDELETED(bs_core))
		return
	if(!z_check(FALSE))
		return
	var/pct = CORE_INTEGRITY_PERCENT
	if(pct > 50)
		last_core_radio_warning_50 = 0
	if(pct > 10)
		last_core_radio_warning_10 = 0
	var/area_name = get_area_name(src)
	if(pct <= 10)
		if(!last_core_radio_warning_10 || (REALTIMEOFDAY - last_core_radio_warning_10) / 10 >= BSM_CORE_WARNING_REPEAT_AFTER)
			var/first_in_band = !last_core_radio_warning_10
			last_core_radio_warning_10 = REALTIMEOFDAY
			var/msg = "КРИТИЧНО: блюспейс-майнер ([area_name], [COORD(src)]): целостность блюспейс-ядра [pct]%. Немедленно отключите майнер!"
			playsound(src, 'sound/machines/engine_alert1.ogg', 100, FALSE, 30, 30, falloff_distance = 10)
			bsm_radio_common_loud(msg)
			if(first_in_band)
				log_game("BSM core ≤10%: [src] at [area_name] [COORD(src)].")
	else if(pct <= 50)
		if(!last_core_radio_warning_50 || (REALTIMEOFDAY - last_core_radio_warning_50) / 10 >= BSM_CORE_WARNING_REPEAT_AFTER)
			var/first_in_band = !last_core_radio_warning_50
			last_core_radio_warning_50 = REALTIMEOFDAY
			var/msg = "ВНИМАНИЕ: блюспейс-майнер ([area_name], [COORD(src)]): целостность блюспейс-ядра [pct]%. Требуется проверка или остановка."
			bsm_radio_science(msg)
			if(first_in_band)
				log_game("BSM core ≤50%: [src] at [area_name] [COORD(src)].")

/obj/machinery/mineral/bluespace_miner/proc/bsm_radio_science(message)
	if(!message)
		return
	var/obj/item/radio/R = new(null)
	R.set_frequency(FREQ_SCIENCE)
	R.talk_into(src, message, FREQ_SCIENCE)
	qdel(R)

/// Общий канал (Common), крупный текст — как экстренное оповещение суперматерии (`SPAN_YELL`).
/obj/machinery/mineral/bluespace_miner/proc/bsm_radio_common_loud(message)
	if(!message)
		return
	var/obj/item/radio/R = new(null)
	R.set_frequency(FREQ_COMMON)
	R.talk_into(src, message, FREQ_COMMON, list(SPAN_YELL))
	qdel(R)

/obj/machinery/mineral/bluespace_miner/proc/on_hold()
	return GLOB.bsminers_lock && z_check(TRUE)

/obj/machinery/mineral/bluespace_miner/multitool_act(mob/living/user, obj/item/M)
	. = ..()
	if(!istype(M?.buffer, /obj/machinery/ore_silo))
		to_chat(user, span_warning("Требуется мультитул с привязаным хранилищем ресурсов."))
		balloon_alert(user, "Данные отсутствуют!")
		return TRUE

/obj/machinery/mineral/bluespace_miner/crowbar_act(mob/living/user, obj/item/I)
	. = ..()
	if(user.a_intent == INTENT_HARM)
		return
	. = TRUE

	if(!panel_open)
		balloon_alert(user, "Открути панель")
		return

	if(bs_core)
		if(I.use_tool(src, user, 2 SECONDS, volume = 50))
			user.put_in_hands(bs_core)
			on_core_remove()
			to_chat(user, span_notice("Вы извлекли Bluespace ядро из машины."))
		return

	if(no_core_damage)
		if(tgui_alert(user,\
			"В машину установлен стабилизатор, он не дает ядру повреждаться при работе. При разборке, он будет утерян. Продолжить?",\
			"ВНИМАНИЕ",\
			list("Нет", "Да"),\
			5 SECONDS\
		) != "Да" && Adjacent(user))
			return

	default_deconstruction_crowbar(I, FALSE)

/obj/machinery/mineral/bluespace_miner/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(user.a_intent == INTENT_HARM)
		return
	. = TRUE

	if(!anchored && panel_open)
		balloon_alert(user, span_balloon_warning("Прикрути!"))
		return
	if(default_deconstruction_screwdriver(user, I = I))
		MINER_UPDATE_ICON
		return

/obj/machinery/mineral/bluespace_miner/can_be_unfasten_wrench(mob/user, silent = FALSE)
	. = ..()
	if(. == FAILED_UNFASTEN)
		return
	if(!panel_open)
		if(!silent)
			balloon_alert(user, "Открути панель")
		return FAILED_UNFASTEN

/obj/machinery/mineral/bluespace_miner/wrench_act(mob/living/user, obj/item/I)
	. = ..()
	if(user.a_intent == INTENT_HARM)
		return
	. = TRUE

	default_unfasten_wrench(user, I)

////////////////////////////////////////////////////////////

/obj/machinery/mineral/bluespace_miner/with_core

/obj/machinery/mineral/bluespace_miner/with_core/Initialize(mapload)
	bs_core = new(src)
	. = ..()

/obj/machinery/mineral/bluespace_miner/with_core/infinity
	no_core_damage = TRUE

/proc/get_safe_random_turf_near(atom/center, radius = BLUESPACE_INSTABILITY_EVENT_RADIUS)
	var/turf/center_turf = get_turf(center)
	if(!center_turf)
		return null
	var/list/candidates = list()
	for(var/turf/T in range(radius, center_turf))
		if(!is_blocked_turf(T, TRUE))
			candidates += T
	if(length(candidates))
		return pick(candidates)
	return center_turf

//////////////////// material_container ////////////////////
/datum/component/material_container/proc/bsm_insert(amt, datum/material/mat)
	if(!istype(mat))
		mat = SSmaterials.GetMaterialRef(mat)
	if(amt > 0 && has_space(amt))
		var/total_amount_saved = total_amount
		if(mat)
			materials[mat] += amt
			total_amount += amt
		else
			for(var/i in materials)
				materials[i] += amt
				total_amount += amt
		return (total_amount - total_amount_saved)
	return FALSE

#undef BLUESPACE_MINER_BONUS_MULT
#undef BLUESPACE_MINER_CRYSTAL_TIER
#undef TIME_TO_CORE_DESTROY_MINUTES
#undef TIME_TO_CORE_DESTROY
#undef CORE_CHANSE_NO_DAMAGE
#undef INSTABILITY_COOLDOWN_TIME

#undef CORE_INTEGRITY_PERCENT
#undef CORE_DAMAGE_PER_SECOND
#undef CORE_DAMAGE_DT

#undef BLUESPACE_INSTABILITY_EVENT_RADIUS
#undef INSTABILITY_ON_ZLEVEL_TO_EVENT
#undef BLUESPACE_MINER_SOUND_CHANCE
#undef BSM_AMBIENT_TEMP_CHAOS_PROB
#undef BSM_CORE_TEMP_OPTIMAL_LOW
#undef BSM_CORE_TEMP_OPTIMAL_HIGH
#undef BSM_CORE_PRESSURE_NOMINAL_KPA
#undef BSM_CORE_PRESSURE_TOLERANCE_KPA

#undef CORE_INSERT_REG_SIGNAL

#undef INSTABILITY_SETTINGS_PERCENT
#undef INSTABILITY_SETTINGS_VALUE
#undef INSTABILITY_SETTINGS_CORE_ICON_STATE
#undef INSTABILITY_SETTINGS_EXAMINE_COLOR

#undef MINER_UPDATE_ICON
