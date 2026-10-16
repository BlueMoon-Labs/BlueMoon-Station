#define RADIATION_LEAK_PULSE_INTERVAL (20 SECONDS)
#define RADIATION_LEAK_DOSE 150
#define RADIATION_LEAK_DOSE_RANGE 2
/// Выше этой накопленной дозы утечка человека не облучает: до токсина и мутаций она не доводит.
#define RADIATION_LEAK_DOSE_CAP (RAD_MOB_SAFE * 0.6)
#define RADIATION_LEAK_DURATION_MINUTES 10
#define RADIATION_LEAK_DURATION (RADIATION_LEAK_DURATION_MINUTES MINUTES)
#define RADIATION_LEAK_STEP_TIME (4 SECONDS)
#define RADIATION_LEAK_STEP_COUNT 2
#define RADIATION_LEAK_CABLE_COST 2
#define RADIATION_LEAK_HISS_CHANCE 35
#define RADIATION_LEAK_CABLE "cable"
#define RADIATION_LEAK_FILTER "radiation_leak_glow"

/datum/round_event_control/station_incident/radiation_leak
	weight = 15
	name = "Radiation Leak"
	typepath = /datum/round_event/station_incident/radiation_leak
	category = EVENT_CATEGORY_ENGINEERING
	severity = DIRECTOR_SEVERITY_MINOR
	min_staffing = list(DIRECTOR_DEPT_ENGINEERING = 1)
	family = "radiation_leak"
	intensity_linger = 10 MINUTES
	public_locations_only = FALSE
	target_type = /obj/machinery
	allowed_area_types = list(/area/engineering, /area/science, /area/medical)
	announcement_title = "Служба радиационного контроля NanoTrasen"

/datum/round_event_control/station_incident/radiation_leak/New()
	description = "Одна рабочая машина в инженерном, научном или медицинском отсеке начинает слабо фонить: стоящие в [RADIATION_LEAK_DOSE_RANGE] клетках получают небольшую дозу, но до вредной она не дорастает. Инженер устраняет утечку [RADIATION_LEAK_STEP_COUNT] шагами с инструментами, которые видны при осмотре; без ремонта она затихает через [RADIATION_LEAK_DURATION_MINUTES] минут, а сдвинутая с места машина перестаёт фонить сразу."
	incident_message = "Датчики фиксируют слабое ионизирующее излучение от рабочего оборудования. Кратковременное нахождение рядом безопасно, но очередь к этой машине лучше не занимать. Инженерной службе - осмотреть источник и устранить утечку; без ремонта экранирование восстановится само примерно через [RADIATION_LEAK_DURATION_MINUTES] минут."
	return ..()

/datum/round_event_control/station_incident/radiation_leak/valid_area(area/location)
	var/static/list/excluded_areas = typecacheof(list(
		/area/engineering/atmospherics_engine,
		/area/engineering/engine_smes,
		/area/engineering/gravity_generator,
		/area/engineering/storage/tcomms,
		/area/engineering/supermatter,
		/area/engineering/teg,
	))
	return !excluded_areas[location.type] && ..()

/datum/round_event_control/station_incident/radiation_leak/valid_target(obj/machinery/target)
	var/static/list/leaky_machines = typecacheof(list(
		/obj/machinery/autolathe,
		/obj/machinery/cell_charger,
		/obj/machinery/chem_dispenser,
		/obj/machinery/chem_heater,
		/obj/machinery/chem_master,
		/obj/machinery/computer/pandemic,
		/obj/machinery/limbgrower,
		/obj/machinery/mecha_part_fabricator,
		/obj/machinery/monkey_recycler,
		/obj/machinery/processor/slime,
		/obj/machinery/recharger,
		/obj/machinery/rnd/destructive_analyzer,
		/obj/machinery/rnd/experimentor,
		/obj/machinery/rnd/production,
	))
	if(!leaky_machines[target.type] || !target.anchored || !..())
		return FALSE
	return !target.GetComponent(/datum/component/radiation_leak)

/datum/round_event/station_incident/radiation_leak
	var/leak_source_name

/datum/round_event/station_incident/radiation_leak/apply_effect(obj/machinery/target)
	if(target.GetComponent(/datum/component/radiation_leak))
		return FALSE
	target.AddComponent(/datum/component/radiation_leak)
	leak_source_name = target.name
	return TRUE

/datum/round_event/station_incident/radiation_leak/announce(fake)
	if(!affected_count)
		return
	var/datum/round_event_control/station_incident/incident = control
	priority_announce("[incident.incident_message] Источник: [leak_source_name], отсек: [incident_area_name].", incident.announcement_title)

/// Утечка живёт на самой машине: импульсы, мерцание, подсказка при осмотре и ремонт инструментами.
/datum/component/radiation_leak
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Шаги ремонта по порядку: поведение инструмента или RADIATION_LEAK_CABLE.
	var/list/repair_steps
	var/steps_done = 0
	var/busy = FALSE
	var/obj/effect/minor_incident_overlay/radiation_leak/glow

/datum/component/radiation_leak/Initialize()
	if(!ismachinery(parent))
		return COMPONENT_INCOMPATIBLE
	var/list/pool = list(TOOL_WRENCH, TOOL_WELDER, TOOL_SCREWDRIVER, TOOL_MULTITOOL, RADIATION_LEAK_CABLE)
	repair_steps = list()
	for(var/step_number in 1 to RADIATION_LEAK_STEP_COUNT)
		repair_steps += pick_n_take(pool)
	addtimer(CALLBACK(src, PROC_REF(pulse)), RADIATION_LEAK_PULSE_INTERVAL)
	addtimer(CALLBACK(src, PROC_REF(expire)), RADIATION_LEAK_DURATION)

/datum/component/radiation_leak/RegisterWithParent()
	var/obj/machinery/machine = parent
	RegisterSignal(machine, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(machine, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(on_item_interaction))
	RegisterSignal(machine, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	for(var/tool_type in list(TOOL_WRENCH, TOOL_WELDER, TOOL_SCREWDRIVER, TOOL_MULTITOOL))
		RegisterSignal(machine, COMSIG_ATOM_TOOL_ACT(tool_type), PROC_REF(on_tool_act))
	machine.add_filter(RADIATION_LEAK_FILTER, 2, list("type" = "outline", "color" = "#58ff3a90", "size" = 1))
	var/filter = machine.get_filter(RADIATION_LEAK_FILTER)
	animate(filter, color = "#58ff3ad0", size = 1.5, time = 3, loop = -1)
	animate(color = "#58ff3a30", size = 1, time = 2)
	animate(color = "#58ff3ab0", time = 1)
	animate(color = "#58ff3a50", time = 5)
	animate(color = "#58ff3ac0", size = 1.5, time = 1)
	animate(color = "#58ff3a70", size = 1, time = 6)
	glow = new(null, machine)

/datum/component/radiation_leak/UnregisterFromParent()
	var/obj/machinery/machine = parent
	UnregisterSignal(machine, list(COMSIG_PARENT_EXAMINE, COMSIG_ATOM_ITEM_INTERACTION, COMSIG_MOVABLE_MOVED))
	for(var/tool_type in list(TOOL_WRENCH, TOOL_WELDER, TOOL_SCREWDRIVER, TOOL_MULTITOOL))
		UnregisterSignal(machine, COMSIG_ATOM_TOOL_ACT(tool_type))
	machine.remove_filter(RADIATION_LEAK_FILTER)
	QDEL_NULL(glow)

/datum/component/radiation_leak/proc/pulse()
	var/obj/machinery/machine = parent
	if(!machine.anchored)
		detach()
		return
	for(var/mob/living/victim in range(RADIATION_LEAK_DOSE_RANGE, machine))
		if(victim.radiation < RADIATION_LEAK_DOSE_CAP)
			victim.rad_act(RADIATION_LEAK_DOSE)
	playsound(machine, pick('sound/items/geiger/low1.ogg', 'sound/items/geiger/low2.ogg', 'sound/items/geiger/low3.ogg', 'sound/items/geiger/low4.ogg'), 30, FALSE, SHORT_RANGE_SOUND_EXTRARANGE)
	if(prob(RADIATION_LEAK_HISS_CHANCE))
		playsound(machine, pick('modular_bluemoon/sound/minor_incidents/radiation_leak_hiss_1.ogg', 'modular_bluemoon/sound/minor_incidents/radiation_leak_hiss_2.ogg', 'modular_bluemoon/sound/minor_incidents/radiation_leak_hiss_3.ogg'), 35, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	addtimer(CALLBACK(src, PROC_REF(pulse)), RADIATION_LEAK_PULSE_INTERVAL)

/datum/component/radiation_leak/proc/on_moved(datum/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	detach()

/// Утечка привязана к месту установки: сдвинутая или откреплённая машина перестаёт фонить.
/datum/component/radiation_leak/proc/detach()
	var/obj/machinery/machine = parent
	machine.visible_message(span_notice("Мерцание вокруг [machine] гаснет: машину сдвинули с места, и утечка прекратилась."))
	log_game("DIRECTOR: Radiation Leak, утечка у [machine] прекратилась: машину сдвинули или открепили ([AREACOORD(machine)]).")
	qdel(src)

/datum/component/radiation_leak/proc/current_step()
	if(steps_done >= length(repair_steps))
		return null
	return repair_steps[steps_done + 1]

/datum/component/radiation_leak/proc/step_instruction(step)
	switch(step)
		if(TOOL_WRENCH)
			return "подтянуть фланцы экранирующего кожуха гаечным ключом"
		if(TOOL_WELDER)
			return "заварить трещину в кожухе сваркой"
		if(TOOL_SCREWDRIVER)
			return "закрутить ослабленные винты защитной панели отвёрткой"
		if(TOOL_MULTITOOL)
			return "перекалибровать датчик утечки мультитулом"
		if(RADIATION_LEAK_CABLE)
			return "заменить обгоревшую проводку экрана кабелем ([RADIATION_LEAK_CABLE_COST] отрезка)"

/datum/component/radiation_leak/proc/step_progress(step)
	switch(step)
		if(TOOL_WRENCH)
			return "подтягивать фланцы кожуха"
		if(TOOL_WELDER)
			return "заваривать трещину в кожухе"
		if(TOOL_SCREWDRIVER)
			return "закручивать винты защитной панели"
		if(TOOL_MULTITOOL)
			return "перекалибровывать датчик утечки"
		if(RADIATION_LEAK_CABLE)
			return "менять обгоревшую проводку экрана"

/datum/component/radiation_leak/proc/step_matches(step, obj/item/tool)
	if(!step || !tool)
		return FALSE
	if(step == RADIATION_LEAK_CABLE)
		return istype(tool, /obj/item/stack/cable_coil)
	return tool.tool_behaviour == step

/datum/component/radiation_leak/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Из-под кожуха пробивается неровное зелёное мерцание: машина фонит.")
	examine_list += span_notice("Порядок ремонта:")
	for(var/step_index in 1 to length(repair_steps))
		var/instruction = "[step_index]. [step_instruction(repair_steps[step_index])]"
		if(step_index <= steps_done)
			examine_list += span_notice("[instruction] - готово.")
		else if(step_index == steps_done + 1)
			examine_list += span_notice("<b>[instruction].</b>")
		else
			examine_list += span_notice("[instruction].")

/datum/component/radiation_leak/proc/on_tool_act(datum/source, mob/living/user, obj/item/tool)
	SIGNAL_HANDLER
	return try_repair(user, tool)

/datum/component/radiation_leak/proc/on_item_interaction(datum/source, mob/living/user, obj/item/tool, params)
	SIGNAL_HANDLER
	if(!istype(tool, /obj/item/stack/cable_coil))
		return NONE
	return try_repair(user, tool)

/datum/component/radiation_leak/proc/try_repair(mob/living/user, obj/item/tool)
	if(!step_matches(current_step(), tool))
		return NONE
	if(busy)
		to_chat(user, span_warning("Над утечкой уже кто-то работает."))
		return TOOL_ACT_MELEE_CHAIN_BLOCKING
	INVOKE_ASYNC(src, PROC_REF(work_step), user, tool)
	return TOOL_ACT_MELEE_CHAIN_BLOCKING

/datum/component/radiation_leak/proc/work_step(mob/living/user, obj/item/tool)
	var/step = current_step()
	var/amount = 0
	if(step == RADIATION_LEAK_CABLE)
		amount = RADIATION_LEAK_CABLE_COST
	else if(step == TOOL_WELDER)
		amount = 1
	if(!tool.tool_start_check(user, amount))
		return
	if(amount && isstack(tool))
		var/obj/item/stack/coil = tool
		if(coil.get_amount() < amount)
			to_chat(user, span_warning("Нужно хотя бы [amount] отрезка кабеля."))
			return
	busy = TRUE
	user.visible_message(span_notice("[user] начинает [step_progress(step)] [parent]."), span_notice("Вы начинаете [step_progress(step)] [parent]."))
	var/success = tool.use_tool(parent, user, RADIATION_LEAK_STEP_TIME, amount, 50)
	busy = FALSE
	if(success && !QDELETED(src))
		complete_step(user, step)

/// Засчитывает текущий шаг ремонта; последний шаг гасит утечку.
/datum/component/radiation_leak/proc/complete_step(mob/living/user, step)
	if(step != current_step())
		return FALSE
	steps_done++
	if(steps_done < length(repair_steps))
		to_chat(user, span_notice("Готово. Дальше нужно [step_instruction(current_step())]."))
		return TRUE
	var/obj/machinery/machine = parent
	machine.visible_message(span_notice("Зелёное мерцание вокруг [machine] гаснет, щелчки дозиметра стихают."))
	playsound(machine, 'sound/machines/ping.ogg', 40, FALSE, SHORT_RANGE_SOUND_EXTRARANGE)
	log_game("DIRECTOR: Radiation Leak, утечка у [machine] в [AREACOORD(machine)] устранена ([key_name(user)]).")
	qdel(src)
	return TRUE

/datum/component/radiation_leak/proc/expire()
	var/obj/machinery/machine = parent
	machine.visible_message(span_notice("Мерцание вокруг [machine] слабеет и гаснет: экранирование восстановилось само."))
	log_game("DIRECTOR: Radiation Leak, утечка у [machine] в [AREACOORD(machine)] истекла без ремонта.")
	qdel(src)

/obj/effect/minor_incident_overlay/radiation_leak
	particle_type = /particles/radiation_leak

/particles/radiation_leak
	width = 64
	height = 64
	count = 24
	spawning = 0.5
	lifespan = 20
	fade = 10
	fadein = 4
	color = generator("color", "#b8ff8a", "#3cd43a")
	scale = generator("num", 1, 2)
	position = generator("box", list(-11, -12, 0), list(11, 6, 0))
	velocity = generator("vector", list(-0.15, 0.25, 0), list(0.15, 0.6, 0))
	drift = generator("vector", list(-0.05, 0, 0), list(0.05, 0.03, 0))

#undef RADIATION_LEAK_PULSE_INTERVAL
#undef RADIATION_LEAK_DOSE
#undef RADIATION_LEAK_DOSE_RANGE
#undef RADIATION_LEAK_DOSE_CAP
#undef RADIATION_LEAK_DURATION_MINUTES
#undef RADIATION_LEAK_DURATION
#undef RADIATION_LEAK_STEP_TIME
#undef RADIATION_LEAK_STEP_COUNT
#undef RADIATION_LEAK_CABLE_COST
#undef RADIATION_LEAK_HISS_CHANCE
#undef RADIATION_LEAK_CABLE
#undef RADIATION_LEAK_FILTER
