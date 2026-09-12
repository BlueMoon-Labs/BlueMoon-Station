#define MAX_RADIUS_REQUIRED 175			// tritbomb
#define MIN_RADIUS_REQUIRED 20			// maxcap
#define RADIUS_OVERHEAT_MODIFIER 30
#define OVERHEAT_DURATION 360 SECONDS 	// 6 минут
#define REQUIRED_IMPLOSION_POWER 400000	// В ваттах
/**
  * # Explosive compressor machines
  *
  * The explosive compressor machine used in anomaly core production.
  *
  * Uses the standard toxins/tank explosion scaling to compress raw anomaly cores into completed ones. The required explosion radius increases with consecutive uses of the machine.
  */
/obj/machinery/research/explosive_compressor
	name = "implosion compressor"
	desc = "Продвинутое устройство, способное обрабатывать сырые ядра аномалий при помощи эффекта имплозии за счёт бризантного эффекта клапанных бомб."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "explosive_compressor"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/explosive_compressor

	/// The raw core inserted in the machine.
	var/obj/item/raw_anomaly_core/inserted_core
	/// The TTV inserted in the machine.
	var/obj/item/transfer_valve/inserted_bomb
	/// The last time we did say_requirements(), because someone will inevitably click spam this.
	var/last_requirements_say = 0
	/// Счётчик перегрева после каждого использования машины
	var/overheat_count = 0
	/// Переменная хранения ссылки на таймер перегрева
	var/overheat_timer

/obj/machinery/research/explosive_compressor/examine(mob/user)
	. = ..()
	if(overheat_count)
		var/overheat_adjective = ""
		switch(overheat_count)
			if(1)
				overheat_adjective = "слегка"
			if(2)
				overheat_adjective = span_yellowteamradio("ощутимо")
			else
				overheat_adjective = span_danger("очень")
		. += span_notice("Машина выглядит [overheat_adjective] горячей.")
	. += span_notice("Ctrl-click для извлечения ядра и Alt-click для извлечения клапанного устройства.")
	. += span_notice("Нажмите пустой рукой по компрессору с вставленным ядром, чтобы узнать информацию о минимальном радиусе для имплозии. \
	Вставьте готовую клапанную бомбу и затем нажмите на компрессор для начала процесса имплозии.")

/obj/machinery/research/explosive_compressor/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(!inserted_core)
		to_chat(user, span_warning("Отсутствует ядро!"))
		return
	if(inserted_bomb)
		to_chat(user, span_notice("Вы нажимаете на кнопку запуска имплозии ядра."))
		do_implosion()
		return TRUE
	if(last_requirements_say + 3 SECONDS > world.time)
		return
	last_requirements_say = world.time
	say_requirements(inserted_core)
	return TRUE

/obj/machinery/research/explosive_compressor/CtrlClick(mob/living/user)
	. = ..()
	if(!istype(user) || !user.Adjacent(src) || !(user.mobility_flags & MOBILITY_USE))
		return
	if(!inserted_core)
		to_chat(user, span_warning("Отсутствует ядро!"))
		return
	eject_core(user)

/obj/machinery/research/explosive_compressor/AltClick(mob/living/user)
	. = ..()
	if(!istype(user) || !user.Adjacent(src) || !(user.mobility_flags & MOBILITY_USE))
		return
	if(!inserted_bomb)
		to_chat(user, span_warning("Отсутствует клапанное устройство!"))
		return
	eject_valve(user)

/**
  * Says (no, literally) the data of required explosive power for a certain anomaly type.
  */
/obj/machinery/research/explosive_compressor/proc/say_requirements(obj/item/raw_anomaly_core/C)
	var/required = get_required_radius(C.anomaly_type)
	if(isnull(required))
		say("К сожалению, из-за истощения запасов конденсированной аномальной материи [C] и любые ядра этого типа больше не обладают достаточным уровнем качества, чтобы быть сжатыми в работоспособное ядро.")
	else
		say("Для успешной имплозии [C] в заряженное ядро аномалии требуется теоретический радиус не менее [required] и совокупно доступная энергия питания не менее [REQUIRED_IMPLOSION_POWER / 1000] кВт.")

/**
  * Прок расчёта необходимой силы бомбы (last value, so light impact theoretical radius), нужной для создания ядра.
  *
  * Использует перегрев машины как утяжелитель требования к бомбе
  *
  * Arguments:
  * * anomaly_type - дефайн типа аномалии
  */
/obj/machinery/research/explosive_compressor/proc/get_required_radius(anomaly_type)
	if(!SSresearch.is_core_available(anomaly_type))
		return		//return null

	// Используем простую арифметику "Минимум плюс модификатор за каждый поинт счётчика"
	var/radius_increase_per_overheat = overheat_count * RADIUS_OVERHEAT_MODIFIER
	var/radius = clamp(round(MIN_RADIUS_REQUIRED + radius_increase_per_overheat, 1), MIN_RADIUS_REQUIRED, MAX_RADIUS_REQUIRED)
	return radius

/obj/machinery/research/explosive_compressor/on_deconstruction()
	eject_valve()
	eject_core()
	return ..()

/obj/machinery/research/explosive_compressor/Destroy()
	if(overheat_timer)
		deltimer(overheat_timer)
		overheat_timer = null
	return ..()

/obj/machinery/research/explosive_compressor/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/raw_anomaly_core))
		if(inserted_core)
			to_chat(user, span_warning("В [src] уже вставлено ядро."))
			return FALSE
		if(!user.transferItemToLoc(I, src))
			to_chat(user, span_warning("[I] прилипло к вашей руке!"))
			return FALSE

		inserted_core = I
		to_chat(user, span_notice("Вы вставляете [I] в [src]."))
		return TRUE

	if(istype(I, /obj/item/transfer_valve))
		if(inserted_bomb)
			to_chat(user, span_warning("Внутри уже есть передаточный клапан!"))
			return FALSE

		// If they don't have a bomb core inserted, don't let them insert this. If they do, insert and do implosion.
		if(!inserted_core)
			to_chat(user, span_warning("Какой смысл производить имплозию без ядра?"))
			return FALSE

		var/obj/item/transfer_valve/valve = I
		if(!valve.ready())
			to_chat(user, span_warning("Сборка [valve] не завершена."))
			return FALSE
		if(!user.transferItemToLoc(I, src))
			to_chat(user, span_warning("[I] прилипло к вашей руке."))
			return FALSE

		inserted_bomb = I
		to_chat(user, span_notice("Вы вставляете [I] в клапанную камеру."))
	. = ..()

/obj/machinery/research/explosive_compressor/screwdriver_act(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, "explosive_compressor", "explosive_compressor", tool)

/obj/machinery/research/explosive_compressor/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/research/explosive_compressor/wrench_act(mob/living/user, obj/item/tool)
	return default_unfasten_wrench(user, tool)

/**
  * The ""explosion"" proc.
  */
/obj/machinery/research/explosive_compressor/proc/do_implosion()
	var/required_radius = get_required_radius(inserted_core.anomaly_type)
	if(isnull(required_radius))
		say("ВНИМАНИЕ: этот тип ядра невозможно скомпрессовать!")
		eject_valve()
		eject_core()
		return FALSE

	// Проверка доступности энергии от прямого подключения к кабелю + АПЦ зоны
	var/turf/compressor_turf = get_turf(src)
	var/area/compressor_area = get_area(compressor_turf)

	var/obj/structure/cable/power_cable = get_direct_power_cable(compressor_turf)
	var/compressor_apc = get_available_apc(compressor_area)
	if(!resolve_energy_need(power_cable, compressor_apc))
		say("ВНИМАНИЕ: недостаточно энергии для реакции! Компоненты извлечены.")
		eject_valve()
		eject_core()
		return FALSE

	// Списание энергии на имплозию
	if(!implosion_energy_draw(power_cable, compressor_apc))
		say("ВНИМАНИЕ: энергоснабжение машины просело во время подготовки реакции! Компоненты извлечены.")
		eject_valve()
		eject_core()
		return FALSE

	// By now, we should be sure that we have a core, a TTV, and that the TTV has both tanks in place.
	var/datum/gas_mixture/mix1 = inserted_bomb.tank_one.air_contents
	var/datum/gas_mixture/mix2 = inserted_bomb.tank_two.air_contents
	// Snowflaked tank explosion
	var/datum/gas_mixture/mix = new(70) // Standard tank volume, 70L
	mix.merge(mix1)
	mix.merge(mix2)
	mix.react()
	if(mix.return_pressure() < TANK_FRAGMENT_PRESSURE)
		// They failed so miserably we're going to give them their bomb back.
		say("Передаточный клапан создал ничтожную взрывную мощность. Компоненты извлечены.")
		eject_valve()
		eject_core()
		return FALSE
	mix.react()		// build more pressure

	var/pressure = mix.return_pressure()
	var/range = (pressure - TANK_FRAGMENT_PRESSURE) / TANK_FRAGMENT_SCALE
	if(range < required_radius)
		say("В результате детонации не хватило имплозивной мощности для сжатия [inserted_core]. Ядро извлечено.")
		eject_valve()
		eject_core()
		return FALSE

	inserted_core.create_core(drop_location(), TRUE, TRUE)
	inserted_core = null
	++overheat_count
	overheat_timer = addtimer(CALLBACK(src, PROC_REF(overheat_check)), OVERHEAT_DURATION, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_STOPPABLE)
	say("Успешно. Теоретический радиус получившейся детонации: [range]. Требуемый радиус: [required_radius]. Создание ядра завершено.")
	QDEL_NULL(inserted_bomb)	// bomb goes poof

////////////////////////// ТАЙМЕР //////////////////////////
/**
  * Прок проверки таймера перегрева и вызова цикла таймеров для ступенчатого остужения нагрева машины
  */
/obj/machinery/research/explosive_compressor/proc/overheat_check()
	--overheat_count
	if(overheat_count <= 0)
		overheat_timer = null
		overheat_count = 0 // Guard на случай, если значение вдруг станет отрицательным от внешних источников
		return
	// Если счётчик ещё не 0, отправляем перегрев на новый цикл остывания. Ступенчато.
	overheat_timer = addtimer(CALLBACK(src, PROC_REF(overheat_check)), OVERHEAT_DURATION, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_STOPPABLE)

/obj/machinery/research/explosive_compressor/proc/eject_core(mob/living/user)
	if(!inserted_core)
		return
	if(user)
		to_chat(user, span_notice("Вы извлекли [inserted_core] из [src]."))
		user.put_in_hands(inserted_core)
	else
		inserted_core.forceMove(drop_location())
	inserted_core = null

/obj/machinery/research/explosive_compressor/proc/eject_valve()
	if(!inserted_bomb)
		return
	inserted_bomb.forceMove(drop_location())
	inserted_bomb = null

//////////////////////////  		//////////////////////////
////////////////////////// ЭНЕРГИЯ //////////////////////////
/**
  * Проверка суммарно доступной энергии от прямого подключения кабеля и батареи АПЦ зоны.
  */
/obj/machinery/research/explosive_compressor/proc/resolve_energy_need(obj/structure/cable/power_cable, obj/machinery/power/apc/apc)
	var/available_energy = get_direct_power_available(power_cable)
	available_energy += get_apc_available_power(apc)
	return available_energy >= REQUIRED_IMPLOSION_POWER

/obj/machinery/research/explosive_compressor/proc/get_available_apc(area/compressor_area)
	if(!compressor_area)
		return
	var/obj/machinery/power/apc/compressor_apc = compressor_area.get_apc()
	if(compressor_apc?.cell && compressor_apc.operating)
		return compressor_apc

/**
  * Прок поиска кабеля для прямого подключения к энергосети под машиной
  */
/obj/machinery/research/explosive_compressor/proc/get_direct_power_cable(turf/compressor_turf)
	if(!compressor_turf)
		return null
	var/obj/structure/cable/compressor_cable = compressor_turf.get_cable_node()
	if(compressor_cable && compressor_cable.powernet)
		return compressor_cable
	return null

/obj/machinery/research/explosive_compressor/proc/get_direct_power_available(obj/structure/cable/power_cable)
	if(!power_cable)
		return 0
	return power_cable.delayed_surplus()

//////////////////////////
/**
  * Списание энергии из энергосети и АПЦ
  */
/obj/machinery/research/explosive_compressor/proc/implosion_energy_draw(obj/structure/cable/power_cable, obj/machinery/power/apc/apc)
	var/needed_energy = REQUIRED_IMPLOSION_POWER
	var/drawn_energy
	var/drawn_energy_total = 0

	// Берём из энергосети
	drawn_energy = min(needed_energy, get_direct_power_available(power_cable))
	if(drawn_energy > 0)
		power_cable.add_delayedload(drawn_energy)
		needed_energy -= drawn_energy
		drawn_energy_total += drawn_energy

	// Берём из батареи АПЦ, если все ещё нужна энергия
	if(needed_energy > 0)
		drawn_energy = draw_compressor_apc_cell(apc, needed_energy)
		needed_energy -= drawn_energy
		drawn_energy_total += drawn_energy
	if(needed_energy > 0)
		log_runtime("Ошибка: [src] получил [drawn_energy_total]W для имплозии при запросе в [REQUIRED_IMPLOSION_POWER]W, хотя прошёл до этого проверки на энергию.")
		return FALSE
	return TRUE

/obj/machinery/research/explosive_compressor/proc/get_apc_available_power(obj/machinery/power/apc/apc)
	if(!apc?.cell || !apc.operating)
		return 0
	return apc.cell.charge WATTS

/**
  * Взято от code\modules\station_goals\bsa.dm
  */
/obj/machinery/research/explosive_compressor/proc/draw_compressor_apc_cell(obj/machinery/power/apc/apc, amount_watts)
	if(!apc?.cell || amount_watts <= 0)
		return 0
	if(!apc.operating)
		return 0
	var/cell_take = min(apc.cell.charge, amount_watts JOULES)
	if(cell_take <= 0)
		return 0
	if(!apc.cell.use(cell_take))
		return 0
	if(apc.charging == 2)
		apc.charging = 1
	return cell_take WATTS

//////////////////////////  		//////////////////////////

#undef MAX_RADIUS_REQUIRED
#undef MIN_RADIUS_REQUIRED
#undef RADIUS_OVERHEAT_MODIFIER
#undef OVERHEAT_DURATION
#undef REQUIRED_IMPLOSION_POWER
