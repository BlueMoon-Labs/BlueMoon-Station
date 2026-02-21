GLOBAL_VAR_INIT(bsminers_lock, FALSE)	//Miners locked by head ID swipes

// Configuration defines
#define BLUESPACE_MINER_BONUS_MULT		CONFIG_GET(number/bluespaceminer_mult_output)
#define BLUESPACE_MINER_CRYSTAL_TIER	CONFIG_GET(number/bluespaceminer_crystal_tier)
#define TIME_TO_CORE_DESTROY_MINUTES	CONFIG_GET(number/bluespaceminer_core_work_time_minutes)
#define TIME_TO_CORE_DESTROY 			(TIME_TO_CORE_DESTROY_MINUTES MINUTES)
// Вносит частичку хаоса
#define CORE_CHANSE_NO_DAMAGE			CONFIG_GET(number/bluespaceminer_core_work_chanse_no_damage)
#define INSTABILITY_COOLDOWN_TIME		CONFIG_GET(number/bluespaceminer_instability_cooldown)

#define CORE_INTEGRITY_PERCENT bs_core ? PERCENT(bs_core.obj_integrity / bs_core.max_integrity) : 0
// Считаем урон в секунду, что бы разрушить ядро (базовое, если захотят сделать версию круче) в указанное время
#define CORE_DAMAGE_PER_SECOND (round(((/obj/item/assembly/signaler/anomaly/bluespace::max_integrity SECONDS) / TIME_TO_CORE_DESTROY) * 10000)/10000)
#define CORE_DAMAGE_DT(DT) (round(CORE_DAMAGE_PER_SECOND*DT*10000)/10000)

// Сколько дает нестабильности БС майнер при работе
#define BLUESPACE_MINER_INSTABILITY 10

// Сколько нужно нестабильности на уровне, что бы майнеры стали производить аномалии
#define INSTABILITY_ON_ZLEVEL_TO_EVENT 100

// Какой шанс (в секунду) вызвать аномалию, если порог в INSTABILITY_ON_ZLEVEL_TO_EVENT превышен, за 1 процент
#define INSTABILITY_CHANSE_FOR_PERCENT 0.1

// Шанс (в секунду) на playsound при работе
#define BLUESPACE_MINER_SOUND_CHANCE 1

// Сигнал при установке ядра
#define CORE_INSERT_REG_SIGNAL RegisterSignal(bs_core, COMSIG_PARENT_QDELETING, PROC_REF(on_core_remove))

// Веса различных типов ивентов при нестабильности
#define INSTABILITY_EVENT_ANOMALY_WEIGHT 50
#define INSTABILITY_EVENT_PORTAL_WEIGHT 20
#define INSTABILITY_EVENT_TEAR_WEIGHT 1

// Названия для instability_settings
/// Процент распада ядра, для уровня нестабильности
#define INSTABILITY_SETTINGS_PERCENT "percent"
/// Сколько процентов к нестабильности дает уровень
#define INSTABILITY_SETTINGS_VALUE "instability"
/// Суффикс для оверлея ядра. Если нужен стандартный вписать ""
#define INSTABILITY_SETTINGS_CORE_ICON_STATE "add_core_state"
/// Каким цветом будет текст экзамайна, при достижении уровня
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

	var/registered_z = 0 //BLUEMOON ADD подтверждаем где бс майнер
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

	var/multiplier = 0 //Multiplier by tier, has been made fair and everything
	// Будет ли ядро получать урон? Для авеек и прочего
	var/no_core_damage = FALSE

	// Нет необходимости пересчитывать урон ядру постоянно, конфиг не меняется обычно. Так, что делаем КД и выносим в прок
	var/static/core_damage_per_tick
	COOLDOWN_DECLARE_STATIC(core_damage_updt_cooldown)
	var/const/core_damage_updt_cooldown_time = 1 MINUTES

	COOLDOWN_DECLARE_STATIC(instability_cooldown)
	// ВАЖНО, что бы уровни нестабильности шли по убыванию percent: 90, 80, 70 и т.д.
	var/static/list/instability_settings = list(
		INSTABILITY_LIST_ADD(60, 10, "inst1", "#c5641e"),
		INSTABILITY_LIST_ADD(30, 20, "inst2", "#c51e1e"),
		INSTABILITY_LIST_ADD(5, 50, "inst3", "#c51e1e"),
	)

#undef INSTABILITY_LIST_ADD

/obj/machinery/mineral/bluespace_miner/Initialize(mapload)
	. = ..()
	if(bs_core)
		CORE_INSERT_REG_SIGNAL

	materials = AddComponent(/datum/component/remote_materials, "bsm", mapload)

	// Set initial multiplier based on config
	multiplier *= BLUESPACE_MINER_BONUS_MULT

/obj/machinery/mineral/bluespace_miner/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))

		var/list/display_list = list("Статус дисплей показывает:")
		display_list += "Эффективность: <b>[PERCENT(multiplier)]%</b>. \
		Добыча Bluespace кристаллов: <b>[multiplier >= BLUESPACE_MINER_CRYSTAL_TIER ? span_green("Активна") : span_danger("Неактивна")]</b>"
		if(no_core_damage)
			display_list += "Установлен [span_bold(span_green("стабилизатор"))], ядро [span_bold(span_green("не будет"))] повреждаться при работе."
		else
			display_list += "Ожидаемое время работы целого ядра <b>~[TIME_TO_CORE_DESTROY_MINUTES]</b> минут."
		if(bs_core)
			var/list/inst_pattern = LAZYACCESS(instability_settings, get_instability_level())
			var/percent_core_integrity_text = span_bold("[CORE_INTEGRITY_PERCENT]%")
			if(inst_pattern)
				percent_core_integrity_text = "<span style='color:[inst_pattern[INSTABILITY_SETTINGS_EXAMINE_COLOR]]'>[percent_core_integrity_text]</span>"
			else
				percent_core_integrity_text = span_green(percent_core_integrity_text)

			display_list += "Состояние Bluespace ядра: [percent_core_integrity_text]"

		display_list += "Машина создает <b>[get_instability()]%</b> нестабильности в секторе."

		var/instability_onzlevel = get_instability_onzlevel()
		var/instability_onzlevel_text = "[instability_onzlevel]%"
		var/sector_stable = instability_onzlevel < INSTABILITY_ON_ZLEVEL_TO_EVENT
		instability_onzlevel_text = !sector_stable ? span_danger(instability_onzlevel_text) : span_green(instability_onzlevel_text)
		display_list += "Нестабильность пространства в регионе: [span_bold(instability_onzlevel_text)]"
		if(!sector_stable)
			display_list += span_boldwarning("ВНИМАНИЕ! Слишком высокая нестабильность, возможны аномалии!")
		else
			display_list += "В секторе начнуться аномалии при нестабильности <b>[INSTABILITY_ON_ZLEVEL_TO_EVENT]%</b>"

		. += span_notice(jointext(display_list, "\n-"))
	else
		. += span_notice("На машине есть небольшой дисплей, но вам нужно подойти ближе, чтобы разглядеть его.")
	if(!bs_core)
		. += span_warning("Bluespace ядро не установлено, без него машина не будет работать.")
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

	// Apply config multiplier here to not interfere with bluespace material check
	multiplier *= BLUESPACE_MINER_BONUS_MULT

/obj/machinery/mineral/bluespace_miner/deconstruct(disassembled)
	if(disassembled && bs_core)
		bs_core.forceMove(drop_location())
		on_core_remove()

	return ..()

/obj/machinery/mineral/bluespace_miner/Destroy()
	materials = null
	//BLUEMOON ADD считаем бс майнеры на z уровне
	if(registered_z)
		SSmachines.bluespaceminer_by_zlevel[registered_z] -= src
	//BLUEMOON ADD END
	QDEL_NULL(bs_core)
	return ..()

/obj/machinery/mineral/bluespace_miner/is_operational()
	. = ..()
	if(!.)
		return
	if(!anchored || !bs_core || !materials?.silo || !materials?.mat_container || materials?.on_hold())
		return FALSE
	if(GLOB.bsminers_lock && z_check(TRUE))
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

	var/inst = clamp(get_instability_onzlevel(), 0, INSTABILITY_ON_ZLEVEL_TO_EVENT)

	if(inst)
		var/idx = min(5, floor(inst / (INSTABILITY_ON_ZLEVEL_TO_EVENT / 4)) + 1) // От 1 до 5. 5 только, когда inst == INSTABILITY_ON_ZLEVEL_TO_EVENT
		// Не хочу копировать 5 оверлеев на 5 уровней. Если кто будет делать спрайт с большими отличиями, перепишите
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
		CORE_INSERT_REG_SIGNAL

/obj/machinery/mineral/bluespace_miner/process(delta_time)
	MINER_UPDATE_ICON
	core_damage_updt(delta_time)
	var/operational = is_operational()
	zlevel_reg(!operational)
	if(!operational)
		return

	if(!no_core_damage && !DT_PROB(CORE_CHANSE_NO_DAMAGE, delta_time))
		bs_core.take_damage(core_damage_per_tick, sound_effect = FALSE)

	if(instability_check(delta_time) && QDELETED(src))
		return PROCESS_KILL
	if(DT_PROB(BLUESPACE_MINER_SOUND_CHANCE, delta_time))
		playsound(src, pick(GLOB.otherworld_sounds), 100, TRUE)

	if(length(SSmachines.bluespaceminer_by_zlevel[src.z]) >= 5 && prob(0.0005))
		var/datum/round_event_control/anomaly/anomaly_bluespace/bluespace_anomaly = new/datum/round_event_control/anomaly/anomaly_bluespace
		bluespace_anomaly.runEvent()

	//BLUEMOON ADD END магический счётсчки неуспешных процессов
	var/datum/material/ore = pick(ore_rates)
	var/datum/component/material_container/mat_container = materials.mat_container
	mat_container.bsm_insert(((ore_rates[ore] * 1000) * multiplier), ore)

/obj/machinery/mineral/bluespace_miner/proc/core_damage_updt(delta_time)
	if(COOLDOWN_FINISHED(src, core_damage_updt_cooldown) || !core_damage_per_tick)
		COOLDOWN_START(src, core_damage_updt_cooldown, core_damage_updt_cooldown_time)
		core_damage_per_tick = CORE_DAMAGE_DT(delta_time)

/obj/machinery/mineral/bluespace_miner/proc/zlevel_reg(unreg = FALSE)
	// Ставим задержку только на выключение. При перебоях света, майнер 1 раз вычеркнется из списков, но повторное удаление произойдет по КД
	// Даже если фактически машина опять будет не работать
	if(unreg && registered_z && COOLDOWN_FINISHED(src, z_reg_cooldown))
		COOLDOWN_START(src, z_reg_cooldown, z_reg_cooldown_time)
		SSmachines.bluespaceminer_by_zlevel[registered_z] -= src
		registered_z = 0
	else if(!unreg && !registered_z)
		SSmachines.bluespaceminer_by_zlevel[src.z] += src
		registered_z = src.z

/obj/machinery/mineral/bluespace_miner/proc/get_instability_onzlevel()
	. = 0
	var/list/all_miners = SSmachines.bluespaceminer_by_zlevel[src.z]
	for(var/obj/machinery/mineral/bluespace_miner/miner in all_miners)
		. += miner.get_instability()

/obj/machinery/mineral/bluespace_miner/proc/get_instability()
	if(!is_operational())
		return 0
	. = BLUESPACE_MINER_INSTABILITY
	var/list/inst_pattern = LAZYACCESS(instability_settings, get_instability_level())
	if(LAZYLEN(inst_pattern))
		. += inst_pattern[INSTABILITY_SETTINGS_VALUE]

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

/obj/machinery/mineral/bluespace_miner/proc/instability_check(delta_time = 1)
	if(!COOLDOWN_FINISHED(src, instability_cooldown))
		return

	var/event_chanse = get_instability_onzlevel() // Пока, это проценты, что бы не плодить перменные лишние
	if(event_chanse<INSTABILITY_ON_ZLEVEL_TO_EVENT)
		return
	event_chanse = event_chanse*INSTABILITY_CHANSE_FOR_PERCENT // А это уже шанс для probe

	if(!DT_PROB(event_chanse, delta_time))
		return
	COOLDOWN_START(src, instability_cooldown, INSTABILITY_COOLDOWN_TIME)
	instability_event_start()
	return TRUE

/obj/machinery/mineral/bluespace_miner/proc/instability_event_start()

	if(!z_check(TRUE))
		explosion(get_turf(src), 0, 1, 5, flame_range = 5)
		qdel(src)
		return

	var/static/list/possible_events_types
	if(!LAZYLEN(possible_events_types))
		possible_events_types = list()
		for(var/anom_type in subtypesof(/datum/round_event_control/anomaly))
			possible_events_types[anom_type] = INSTABILITY_EVENT_ANOMALY_WEIGHT
		var/static/list/events_tears = list(
			/datum/round_event_control/portal_storm_inteq,
			/datum/round_event_control/portal_storm_narsie,
			/datum/round_event_control/portal_storm_clown,
			/datum/round_event_control/portal_storm_necros,
			/datum/round_event_control/portal_storm_funclaws,
			/datum/round_event_control/portal_storm_clock,
		)
		for(var/path in events_tears)
			possible_events_types[path] = INSTABILITY_EVENT_TEAR_WEIGHT
		for(var/path in subtypesof(/datum/round_event_control/spawners))
			possible_events_types[path] = INSTABILITY_EVENT_PORTAL_WEIGHT

	var/datum/round_event_control/event = pickweight(possible_events_types) // istype
	if(!event)
		return
	event = new event
	event.runEvent(FALSE, increase_occurrences = FALSE)

/obj/machinery/mineral/bluespace_miner/proc/on_core_remove()
	SIGNAL_HANDLER

	UnregisterSignal(bs_core, COMSIG_PARENT_QDELETING)
	bs_core = null

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

#undef BLUESPACE_MINER_INSTABILITY
#undef INSTABILITY_ON_ZLEVEL_TO_EVENT
#undef INSTABILITY_CHANSE_FOR_PERCENT
#undef BLUESPACE_MINER_SOUND_CHANCE

#undef CORE_INSERT_REG_SIGNAL

#undef INSTABILITY_EVENT_ANOMALY_WEIGHT
#undef INSTABILITY_EVENT_PORTAL_WEIGHT
#undef INSTABILITY_EVENT_TEAR_WEIGHT

#undef INSTABILITY_SETTINGS_PERCENT
#undef INSTABILITY_SETTINGS_VALUE
#undef INSTABILITY_SETTINGS_CORE_ICON_STATE
#undef INSTABILITY_SETTINGS_EXAMINE_COLOR
// #undef INSTABILITY_LIST_ADD Удаляется раньше, но я оставил тут, для наглядности

#undef MINER_UPDATE_ICON
