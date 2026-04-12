#define IC_SMOKE_REAGENTS_MINIMUM_UNITS 10

/obj/item/integrated_circuit/reagent
	category_text = "Реагенты"
	resistance_flags = UNACIDABLE | FIRE_PROOF
	cooldown_per_use = 10
	var/volume = 0

/obj/item/integrated_circuit/reagent/Initialize(mapload)
	. = ..()
	if(volume)
		create_reagents(volume)
		push_vol()

/obj/item/integrated_circuit/reagent/proc/push_vol()
	set_pin_data(IC_OUTPUT, 1, reagents.total_volume)
	push_data()

// Hydroponics trays have no reagents holder and handle reagents in their own snowflakey way.
// This is a dirty hack to make injecting reagents into them work.
// TODO: refactor that.
//Time for someone to refactor this. Trays can now hold reagents.
//obj/item/integrated_circuit/reagent/proc/inject_tray(obj/machinery/hydroponics/tray, atom/movable/source, amount)
	//var/atom/movable/acting_object = get_object()
	//var/list/trays = list(tray)
	//var/visi_msg = "[acting_object] transfers fluid into [tray]"

	//acting_object.visible_message("<span class='notice'>[visi_msg].</span>")
	//playsound(loc, 'sound/effects/slosh.ogg', 25, 1)

	//var/split = round(amount/trays.len)

	//for(var/obj/machinery/hydroponics/H in trays)
		//var/datum/reagents/temp_reagents = new /datum/reagents()
		//temp_reagents.my_atom = H

		//source.reagents.trans_to(temp_reagents, split)
		//H.on_hydroponics_apply(temp_reagents)

		//temp_reagents.clear_reagents()
		//qdel(temp_reagents)

/obj/item/integrated_circuit/reagent/injector
	name = "integrated hypo-injector"
	desc = "Эта устрашающе выглядящая штуковина способна закачивать жидкости в любой объект, на который она направлена, или высасывать жидкости из него."
	icon_state = "injector"
	extended_desc = "Этот автоинжектор может перекачивать до 30 единиц реагентов в другой контейнер или другому объекту, находящемуся за пределами машины. Цель \
    должна находиться рядом с машиной, а если это человек, он не должен быть одет в толстую одежду. Указание отрицательного количества приводит к тому, что инжектор вместо этого всасывает реагенты."

	volume = 30

	complexity = 20
	cooldown_per_use = 6 SECONDS
	inputs = list(
		"цель" = IC_PINTYPE_REF,
		"объем инъекции" = IC_PINTYPE_NUMBER
		)
	inputs_default = list(
		"2" = 5
		)
	outputs = list(
		"объема использовано" = IC_PINTYPE_NUMBER,
		"самоссылка" = IC_PINTYPE_SELFREF
		)
	activators = list(
		"ввести" = IC_PINTYPE_PULSE_IN,
		"при вводе" = IC_PINTYPE_PULSE_OUT,
		"при неудаче" = IC_PINTYPE_PULSE_OUT,
		"push ref" = IC_PINTYPE_PULSE_IN

		)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 15
	var/direction_mode = SYRINGE_INJECT
	var/transfer_amount = 10
	var/busy = FALSE

/obj/item/integrated_circuit/reagent/injector/Initialize(mapload)
	. = ..()
	reagents.reagents_holder_flags |= OPENCONTAINER

/obj/item/integrated_circuit/reagent/injector/on_reagent_change(changetype)
	push_vol()

/obj/item/integrated_circuit/reagent/injector/on_data_written()
	var/new_amount = get_pin_data(IC_INPUT, 2)
	if(new_amount < 0)
		new_amount = -new_amount
		direction_mode = SYRINGE_DRAW
	else
		direction_mode = SYRINGE_INJECT
	if(isnum(new_amount))
		new_amount = clamp(new_amount, 0, volume)
		transfer_amount = new_amount


/obj/item/integrated_circuit/reagent/injector/do_work(ord)
	switch(ord)
		if(1)
			inject()
		if(4)
			set_pin_data(IC_OUTPUT, 2, WEAKREF(src))
			push_data()

/obj/item/integrated_circuit/reagent/injector/proc/inject()
	set waitfor = FALSE // Don't sleep in a proc that is called by a processor without this set, otherwise it'll delay the entire thing
	var/atom/movable/AM = get_pin_data_as_type(IC_INPUT, 1, /atom/movable)
	var/atom/movable/acting_object = get_object()

	if(busy || !check_target(AM))
		activate_pin(3)
		return

	if(!AM.reagents)
		//if(istype(AM, /obj/machinery/hydroponics) && direction_mode == SYRINGE_INJECT && reagents.total_volume && transfer_amount)//injection into tray.
			//inject_tray(AM, src, transfer_amount)
			//activate_pin(2)
			//return
		activate_pin(3)
		return

	if(direction_mode == SYRINGE_INJECT)
		if(!reagents.total_volume || !AM.is_injectable() || AM.reagents.holder_full())
			activate_pin(3)
			return

		if(isliving(AM))
			var/mob/living/L = AM
			if(!L.can_inject(null, 0))
				activate_pin(3)
				return

			//Always log attemped injections for admins
			var/contained = reagents.log_list()
			log_combat(src, L, "attempted to inject", addition="which had [contained]")
			L.visible_message("<span class='danger'>[acting_object] пробует уколоть [L]!</span>", \
								"<span class='userdanger'>[acting_object] пробует уколоть вас!</span>")
			busy = TRUE
			if(do_atom(src, L, extra_checks=CALLBACK(L, TYPE_PROC_REF(/mob/living, can_inject),null,0)))
				var/fraction = min(transfer_amount/reagents.total_volume, 1)
				reagents.reaction(L, INJECT, fraction)
				reagents.trans_to(L, transfer_amount)
				log_combat(src, L, "injected", addition="which had [contained]")
				L.visible_message("<span class='danger'>[acting_object] вводит что-то [L] с помощью иглы!</span>", \
									"<span class='userdanger'>[acting_object] вводит вам что-то с помощью иглы!</span>")
			else
				busy = FALSE
				activate_pin(3)
				return
			busy = FALSE

		else
			reagents.trans_to(AM, transfer_amount)

	if(direction_mode == SYRINGE_DRAW)
		if(reagents.total_volume >= reagents.maximum_volume)
			acting_object.visible_message("[acting_object] всосать что-то из [AM], но инжектор полон.")
			activate_pin(3)
			return

		var/tramount = abs(transfer_amount)

		if(isliving(AM))
			var/mob/living/L = AM
			L.visible_message("<span class='danger'>[acting_object] пробует взять образец крови из [L]!</span>", \
								"<span class='userdanger'>[acting_object] пробует взять образец крови из вас!</span>")
			busy = TRUE
			if(do_atom(src, L, extra_checks=CALLBACK(L, TYPE_PROC_REF(/mob/living, can_inject),null,0)))
				if(L.transfer_blood_to(src, tramount))
					L.visible_message("<span class='danger'>[acting_object] берёт образец крови из [L]!</span>", \
					"<span class='userdanger'>[acting_object] берёт образец крови из вас!</span>")
				else
					L.visible_message("<span class='warning'>[acting_object] не может взять образец крови из [L].</span>", \
								"<span class='userdanger'>[acting_object] не может взять образец крови из вас!</span>")
					busy = FALSE
					activate_pin(3)
					return
			busy = FALSE

		else
			if(!AM.reagents.total_volume)
				acting_object.visible_message("<span class='notice'>[acting_object] пытается всосать что-то из [AM], но в нём пусто!</span>")
				activate_pin(3)
				return

			if(!AM.is_drawable())
				activate_pin(3)
				return
			tramount = min(tramount, AM.reagents.total_volume)
			AM.reagents.trans_to(src, tramount)
	activate_pin(2)



/obj/item/integrated_circuit/reagent/pump
	name = "reagent pump"
	desc = "Безопасно транспортирует жидкости внутри машины или даже рядом с ней."
	icon_state = "reagent_pump"
	extended_desc = "Это насос, который перекачивает жидкости из исходного резервуара в целевой резервуар. Третий пин определяет, \
    какой объем жидкости перекачивается за один импульс - от 0 до 50. Насос может перекачивать реагенты в любой открытый контейнер внутри аппарата или \
    за пределы аппарата, если он находится рядом с ним."

	complexity = 8
	inputs = list("источник" = IC_PINTYPE_REF, "цель" = IC_PINTYPE_REF, "объем инъекции" = IC_PINTYPE_NUMBER)
	inputs_default = list("3" = 5)
	outputs = list()
	activators = list("переместить реагенты" = IC_PINTYPE_PULSE_IN, "при перемещении" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/transfer_amount = 10
	var/direction_mode = SYRINGE_INJECT
	power_draw_per_use = 10

/obj/item/integrated_circuit/reagent/pump/on_data_written()
	var/new_amount = get_pin_data(IC_INPUT, 3)
	if(new_amount < 0)
		new_amount = -new_amount
		direction_mode = SYRINGE_DRAW
	else
		direction_mode = SYRINGE_INJECT
	if(isnum(new_amount))
		new_amount = clamp(new_amount, 0, 50)
		transfer_amount = new_amount

/obj/item/integrated_circuit/reagent/pump/do_work()
	var/atom/movable/source = get_pin_data_as_type(IC_INPUT, 1, /atom/movable)
	var/atom/movable/target = get_pin_data_as_type(IC_INPUT, 2, /atom/movable)

	// Check for invalid input.
	if(!check_target(source) || !check_target(target))
		return

	// If the pump is pumping backwards, swap target and source.
	if(!direction_mode)
		var/temp_source = source
		source = target
		target = temp_source

	if(!source.reagents)
		return

	//if(!target.reagents)
		// Hydroponics trays have no reagents holder and handle reagents in their own snowflakey way.
		// This is a dirty hack to make injecting reagents into them work.
		//Someone should redo this. Trays should hold reagents now.
		//if(istype(target, /obj/machinery/hydroponics) && source.reagents.total_volume)
			//inject_tray(target, source, transfer_amount)
			//activate_pin(2)
		//return

	if(!source.is_drainable() || !target.is_refillable())
		return

	source.reagents.trans_to(target, transfer_amount)
	activate_pin(2)

/obj/item/integrated_circuit/reagent/storage
	cooldown_per_use = 1
	name = "reagent storage"
	desc = "Жидкость хранится внутри устройства вдали от электрических компонентов. Объём хранения составляет до 60 единиц."
	icon_state = "reagent_storage"
	extended_desc = "По сути, это внутренний стакан."

	volume = 60

	complexity = 4
	inputs = list()
	outputs = list(
		"использовано объема" = IC_PINTYPE_NUMBER,
		"самоссылка" = IC_PINTYPE_SELFREF
		)
	activators = list("push ref" = IC_PINTYPE_PULSE_IN)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/reagent/storage/Initialize(mapload)
	. = ..()
	reagents.reagents_holder_flags |= OPENCONTAINER

/obj/item/integrated_circuit/reagent/storage/do_work(ord)
	set_pin_data(IC_OUTPUT, 2, WEAKREF(src))
	push_data()

/obj/item/integrated_circuit/reagent/storage/on_reagent_change(changetype)
	push_vol()

/obj/item/integrated_circuit/reagent/storage/big
	name = "big reagent storage"
	icon_state = "reagent_storage_big"
	desc = "Жидкость хранится внутри устройства вдали от электрических компонентов. Вместимость до 180 единиц."

	volume = 180

	complexity = 16
	spawn_flags = IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/reagent/storage/cryo
	name = "cryo reagent storage"
	desc = "Жидкость хранится внутри устройства вдали от электрических компонентов. Емкость резервуара составляет до 60 u. Это также предотвращает возникновение реакций."
	icon_state = "reagent_storage_cryo"
	extended_desc = "По сути, это внутренний криогенный стакан."

	complexity = 8
	spawn_flags = IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/reagent/storage/cryo/Initialize(mapload)
	. = ..()
	reagents.reagents_holder_flags |= NO_REACT

/obj/item/integrated_circuit/reagent/storage/grinder
	name = "reagent grinder"
	desc = "Это блендер для реагентов. Она принимает сырье и перерабатывает его в реагенты. Её вместимость составляет до 100 единиц."
	icon_state = "blender"
	extended_desc = ""
	inputs = list(
		"цель" = IC_PINTYPE_REF,
		)
	outputs = list(
		"использованный объем" = IC_PINTYPE_NUMBER,
		"самоссылка" = IC_PINTYPE_SELFREF
		)
	activators = list(
		"измельчить" = IC_PINTYPE_PULSE_IN,
		"при измельчении" = IC_PINTYPE_PULSE_OUT,
		"при неудаче" = IC_PINTYPE_PULSE_OUT,
		"push ref" = IC_PINTYPE_PULSE_IN
		)
	volume = 100
	power_draw_per_use = 150
	complexity = 16
	spawn_flags = IC_SPAWN_RESEARCH


/obj/item/integrated_circuit/reagent/storage/grinder/do_work(ord)
	switch(ord)
		if(1)
			grind()
		if(4)
			set_pin_data(IC_OUTPUT, 2, WEAKREF(src))
			push_data()

/obj/item/integrated_circuit/reagent/storage/grinder/proc/grind()
	if(reagents.total_volume >= reagents.maximum_volume)
		activate_pin(3)
		return FALSE
	var/obj/item/I = get_pin_data_as_type(IC_INPUT, 1, /obj/item)
	if(istype(I)&&(I.grind_results)&&check_target(I)&&(I.on_grind(src) != -1))
		reagents.add_reagent_list(I.grind_results)
		if(I.reagents)
			I.reagents.trans_to(src, I.reagents.total_volume)
		qdel(I)
		activate_pin(2)
		return TRUE
	activate_pin(3)
	return FALSE

/obj/item/integrated_circuit/reagent/storage/juicer
	name = "reagent juicer"
	desc = "Это соковыжималка для реагентов. Она принимает референс на какой-либо объект и преобразует его в реагенты. Её вместимость составляет до 100 единиц."
	icon_state = "blender"
	extended_desc = ""
	inputs = list(
		"цель" = IC_PINTYPE_REF,
		)
	outputs = list(
		"использованный объем" = IC_PINTYPE_NUMBER,
		"самоссылка" = IC_PINTYPE_SELFREF
		)
	activators = list(
		"выжать" = IC_PINTYPE_PULSE_IN,
		"при выжимке" = IC_PINTYPE_PULSE_OUT,
		"при неудаче" = IC_PINTYPE_PULSE_OUT,
		"push ref" = IC_PINTYPE_PULSE_IN
		)
	volume = 100
	power_draw_per_use = 150
	complexity = 16
	spawn_flags = IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/reagent/storage/juicer/do_work(ord)
	switch(ord)
		if(1)
			juice()
		if(4)
			set_pin_data(IC_OUTPUT, 2, WEAKREF(src))
			push_data()

/obj/item/integrated_circuit/reagent/storage/juicer/proc/juice()
	if(reagents.total_volume >= reagents.maximum_volume)
		activate_pin(3)
		return FALSE
	var/obj/item/I = get_pin_data_as_type(IC_INPUT, 1, /obj/item)
	if(istype(I)&&check_target(I)&&(I.juice_results)&&(I.on_juice() != -1))
		reagents.add_reagent_list(I.juice_results)
		qdel(I)
		activate_pin(2)
		return TRUE
	activate_pin(3)
	return FALSE



/obj/item/integrated_circuit/reagent/storage/scan
	name = "reagent scanner"
	desc = "Внутри устройства хранится жидкость, отдельно от электрических компонентов. Емкость составляет до 60 единиц. При подаче импульса этот пробирка передаст список содержащихся в ней реагентов."
	icon_state = "reagent_scan"
	extended_desc = "В основном используется для фильтрации реагентов."

	complexity = 8
	outputs = list(
		"использованный объем" = IC_PINTYPE_NUMBER,
		"самоссылка" = IC_PINTYPE_SELFREF,
		"список реагентов" = IC_PINTYPE_LIST
		)
	activators = list(
		"сканировать" = IC_PINTYPE_PULSE_IN,
		"push ref" = IC_PINTYPE_PULSE_IN
		)
	spawn_flags = IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/reagent/storage/scan/do_work(ord)
	switch(ord)
		if(1)
			var/cont[0]
			for(var/datum/reagent/RE in reagents.reagent_list)
				cont += RE.type
			set_pin_data(IC_OUTPUT, 3, cont)
			push_data()
		if(2)
			set_pin_data(IC_OUTPUT, 2, WEAKREF(src))
			push_data()

/obj/item/integrated_circuit/reagent/filter
	name = "reagent filter"
	desc = "Фильтрует жидкости по списку желаемых или нежелательных реагентов."
	icon_state = "reagent_filter"
	extended_desc = "Это фильтр, который перемещает жидкости из источника в конечный пункт. \
    Если значение в четвёртом пине положительное, перемещаются все реагенты, кроме тех, что входят в список нежелательных. \
    Если значение в четвёртом пине отрицательное, перемещаются только реагенты из списка желаемых. \
    Третий пин определяет количество реагентов, перемещаемых за один импульс, в диапазоне от 0 до 50. Количество указывается для каждого отдельного реагента."

	complexity = 8
	inputs = list(
		"источник" = IC_PINTYPE_REF,
		"цель" = IC_PINTYPE_REF,
		"объем инъекции" = IC_PINTYPE_NUMBER,
		"список реагентов" = IC_PINTYPE_LIST
		)
	inputs_default = list(
		"3" = 5
		)
	outputs = list()
	activators = list(
		"переместить реагенты" = IC_PINTYPE_PULSE_IN,
		"при перемещении" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/transfer_amount = 10
	var/direction_mode = SYRINGE_INJECT
	power_draw_per_use = 10

/obj/item/integrated_circuit/reagent/filter/on_data_written()
	var/new_amount = get_pin_data(IC_INPUT, 3)
	if(new_amount < 0)
		new_amount = -new_amount
		direction_mode = SYRINGE_DRAW
	else
		direction_mode = SYRINGE_INJECT
	if(isnum(new_amount))
		new_amount = clamp(new_amount, 0, 50)
		transfer_amount = new_amount

/obj/item/integrated_circuit/reagent/filter/do_work()
	var/atom/movable/source = get_pin_data_as_type(IC_INPUT, 1, /atom/movable)
	var/atom/movable/target = get_pin_data_as_type(IC_INPUT, 2, /atom/movable)
	var/list/demand = get_pin_data(IC_INPUT, 4)

	// Check for invalid input.
	if(!check_target(source) || !check_target(target))
		return

	if(!source.reagents || !target.reagents)
		return

	// FALSE in those procs makes mobs invalid targets.
	if(!source.is_drawable(FALSE) || !target.is_injectable(FALSE))
		return

	if(target.reagents.maximum_volume - target.reagents.total_volume <= 0)
		return

	for(var/datum/reagent/G in source.reagents.reagent_list)
		if(!direction_mode)
			if(G.type in demand)
				source.reagents.trans_id_to(target, G.type, transfer_amount)
		else
			if(!(G.type in demand))
				source.reagents.trans_id_to(target, G.type, transfer_amount)
	activate_pin(2)
	push_data()

/obj/item/integrated_circuit/reagent/storage/heater
	name = "chemical heater"
	desc = "Внутри устройства предусмотрено отделение для хранения жидкости, расположенное вдали от электрических компонентов. Его объём составляет до 60 единиц. При включении устройство нагревает или охлаждает реагенты \
    до заданной температуры."
	icon_state = "heater"
	complexity = 8
	inputs = list(
		"целевая температура" = IC_PINTYPE_NUMBER,
		"включен?" = IC_PINTYPE_BOOLEAN
		)
	inputs_default = list("1" = 300)
	outputs = list("использованный объем" = IC_PINTYPE_NUMBER,"самоссылка" = IC_PINTYPE_SELFREF,"температура" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_RESEARCH
	var/heater_coefficient = 0.1
	var/max_temp = 1000
	var/min_temp = 2.7

/obj/item/integrated_circuit/reagent/storage/heater/on_data_written()
	if(get_pin_data(IC_INPUT, 2))
		power_draw_idle = 30
	else
		power_draw_idle = 0

/obj/item/integrated_circuit/reagent/storage/heater/Initialize(mapload)
	.=..()
	START_PROCESSING(SScircuit, src)

/obj/item/integrated_circuit/reagent/storage/heater/Destroy()
	STOP_PROCESSING(SScircuit, src)
	return ..()

/obj/item/integrated_circuit/reagent/storage/heater/process()
	if(power_draw_idle)
		var/target_temperature = clamp(get_pin_data(IC_INPUT, 1), min_temp, max_temp)
		if(reagents.chem_temp > target_temperature)
			reagents.chem_temp += min(-1, (target_temperature - reagents.chem_temp) * heater_coefficient)
		if(reagents.chem_temp < target_temperature)
			reagents.chem_temp += max(1, (target_temperature - reagents.chem_temp) * heater_coefficient)

		reagents.chem_temp = round(reagents.chem_temp)
		reagents.handle_reactions()
		set_pin_data(IC_OUTPUT, 3, reagents.chem_temp)
		push_data()


//Hippie Ported Code--------------------------------------------------------------------------------------------------------


/obj/item/integrated_circuit/reagent/smoke
	name = "smoke generator"
	desc = "В отличие от большинства электронных устройств, появление дыма в данном случае является полностью преднамеренным."
	icon_state = "smoke"
	extended_desc = "Этот дымогенератор создает облака дыма по команде. Внутри него также можно хранить жидкости, которые при активации \
    попадают в облака дыма. При образовании дыма реагенты расходуются. Для генерации дыма требуется не менее 10 единиц реагентов."
	ext_cooldown = 1

	volume = 100

	complexity = 20
	cooldown_per_use = 1 SECONDS
	inputs = list()
	outputs = list(
		"использованный объем" = IC_PINTYPE_NUMBER,
		"самоссылка" = IC_PINTYPE_SELFREF
		)
	activators = list(
		"создать дым" = IC_PINTYPE_PULSE_IN,
		"при создании дыма" = IC_PINTYPE_PULSE_OUT,
		"push ref" = IC_PINTYPE_PULSE_IN
		)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 20
	var/smoke_radius = 5
	var/notified = FALSE

/obj/item/integrated_circuit/reagent/smoke/Initialize(mapload)
	. = ..()
	reagents.reagents_holder_flags |= OPENCONTAINER

/obj/item/integrated_circuit/reagent/smoke/on_reagent_change(changetype)
	//reset warning only if we have reagents now
	if(changetype == ADD_REAGENT)
		notified = FALSE
	push_vol()

/obj/item/integrated_circuit/reagent/smoke/do_work(ord)
	switch(ord)
		if(1)
			if(!reagents || (reagents.total_volume < IC_SMOKE_REAGENTS_MINIMUM_UNITS))
				return
			var/location = get_turf(src)
			var/datum/effect_system/smoke_spread/chem/S = new
			S.attach(location)
			playsound(location, 'sound/effects/smoke.ogg', 50, 1, -3)
			if(S)
				S.set_up(reagents, smoke_radius, location, notified)
				if(!notified)
					notified = TRUE
				S.start()
			reagents.clear_reagents()
			activate_pin(2)
		if(3)
			set_pin_data(IC_OUTPUT, 2, WEAKREF(src))
			push_data()

// - Integrated extinguisher - //
/obj/item/integrated_circuit/reagent/extinguisher
	name = "integrated extinguisher"
	desc = "Эта схема распыляет любое содержимое, как огнетушитель."
	icon_state = "injector"
	extended_desc = "Эта схема может вместить до 30 единиц любого химического вещества. При каждом запуске она распыляет эти реагенты, как огнетушитель. Для работы требуется не менее 10 единиц реагентов."

	volume = 30

	complexity = 20
	cooldown_per_use = 6 SECONDS
	inputs = list(
		"относительный X цели" = IC_PINTYPE_NUMBER,
		"относительный Y цели" = IC_PINTYPE_NUMBER
		)
	outputs = list(
		"объем" = IC_PINTYPE_NUMBER,
		"самоссылка" = IC_PINTYPE_SELFREF
		)
	activators = list(
		"распылить" = IC_PINTYPE_PULSE_IN,
		"при распылении" = IC_PINTYPE_PULSE_OUT,
		"при неудаче" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 15
	var/busy = FALSE

/obj/item/integrated_circuit/reagent/extinguisher/Initialize(mapload)
	.=..()
	reagents.reagents_holder_flags |= OPENCONTAINER
	set_pin_data(IC_OUTPUT,2, src)

/obj/item/integrated_circuit/reagent/extinguisher/on_reagent_change(changetype)
	push_vol()

/obj/item/integrated_circuit/reagent/extinguisher/do_work()
	//Check if enough volume
	set_pin_data(IC_OUTPUT, 1, reagents.total_volume)
	if(!reagents || reagents.total_volume < IC_SMOKE_REAGENTS_MINIMUM_UNITS || busy)
		push_data()
		activate_pin(3)
		return

	playsound(loc, 'sound/effects/extinguish.ogg', 75, 1, -3)
	//Get the tile on which the water particle spawns
	var/turf/Spawnpoint = get_turf(src)
	if(!Spawnpoint)
		push_data()
		activate_pin(3)
		return

	//Get direction and target turf for each water particle
	var/turf/T = locate(Spawnpoint.x + get_pin_data(IC_INPUT, 1),Spawnpoint.y + get_pin_data(IC_INPUT, 2),Spawnpoint.z)
	if(!T)
		push_data()
		activate_pin(3)
		return
	var/direction = get_dir(Spawnpoint, T)
	var/turf/T1 = get_step(T,turn(direction, 90))
	var/turf/T2 = get_step(T,turn(direction, -90))
	var/list/the_targets = list(T,T1,T2)
	busy = TRUE

	// Create list with particles and their targets
	var/list/water_particles=list()
	for(var/a=0, a<5, a++)
		var/obj/effect/particle_effect/water/W = new /obj/effect/particle_effect/water(get_turf(src))
		water_particles[W] = pick(the_targets)
		var/datum/reagents/R = new/datum/reagents(5)
		W.reagents = R
		R.my_atom = W
		reagents.trans_to(W,1)

	//Make em move dat ass, hun
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/item/integrated_circuit/reagent/extinguisher, move_particles), water_particles), 2)

//This whole proc is a loop
/obj/item/integrated_circuit/reagent/extinguisher/proc/move_particles(var/list/particles, var/repetitions=0)
	//Check if there's anything in here first
	if(!particles || particles.len == 0)
		return
	// Second loop: Get all the water particles and make them move to their target
	for(var/obj/effect/particle_effect/water/W in particles)
		var/turf/my_target = particles[W]
		if(!W)
			continue
		step_towards(W,my_target)
		if(!W.reagents)
			continue
		W.reagents.reaction(get_turf(W))
		for(var/A in get_turf(W))
			W.reagents.reaction(A)
		if(W.loc == my_target)
			break
	if(repetitions < 4)
		repetitions++	//Can't have math operations in addtimer(CALLBACK())
		addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/item/integrated_circuit/reagent/extinguisher, move_particles), particles, repetitions), 2)
	else
		push_data()
		activate_pin(2)
		busy = FALSE

// - Beaker Connector - //
/obj/item/integrated_circuit/input/beaker_connector
	category_text = "Реагенты"
	cooldown_per_use = 1
	name = "beaker slot"
	desc = "Позволяет добавлять мензурку в корпус и удалять её даже после того, как корпус закрыт."
	icon_state = "reagent_storage"
	extended_desc = "Это поможет вам легче извлекать реагенты."
	complexity = 4

	inputs = list()
	outputs = list(
		"использованный объем" = IC_PINTYPE_NUMBER,
		"текущее хранилище" = IC_PINTYPE_REF
		)
	activators = list(
		"при вставке" = IC_PINTYPE_PULSE_OUT,
		"при извлечении" = IC_PINTYPE_PULSE_OUT,
		"push ref" = IC_PINTYPE_PULSE_IN
		)

	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	can_be_asked_input = TRUE
	demands_object_input = TRUE
	can_input_object_when_closed = TRUE

	var/obj/item/reagent_containers/glass/beaker/current_beaker

/obj/item/integrated_circuit/input/beaker_connector/do_work(ord)
	switch(ord)
		if(3)
			set_pin_data(IC_OUTPUT, 2, WEAKREF(current_beaker))
			push_data()

/obj/item/integrated_circuit/input/beaker_connector/attackby(var/obj/item/reagent_containers/I, var/mob/living/user)
	//Check if it truly is a reagent container
	if(!istype(I,/obj/item/reagent_containers/glass/beaker))
		to_chat(user,"<span class='warning'>[I.name] не подходит сюда.</span>")
		return

	//Check if there is no other beaker already inside
	if(current_beaker)
		to_chat(user,"<span class='notice'>Внутри уже находится контейнер для реагентов.</span>")
		return

	//The current beaker is the one we just attached, its location is inside the circuit
	current_beaker = I
	user.transferItemToLoc(I,src)

	to_chat(user,"<span class='warning'>Вы вставляете [I.name] в соединитель мензурок.</span>")

	//Set the pin to a weak reference of the current beaker
	push_vol()
	set_pin_data(IC_OUTPUT, 2, WEAKREF(current_beaker))
	push_data()
	activate_pin(1)
	activate_pin(3)


/obj/item/integrated_circuit/input/beaker_connector/ask_for_input(mob/user)
	attack_self(user)

/obj/item/integrated_circuit/input/beaker_connector/attack_self(mob/user)
	//Check if no beaker attached
	if(!current_beaker)
		to_chat(user, "<span class='notice'>В данный момент мензурка не установлена.</span>")
		return

	//Remove beaker and put in user's hands/location
	to_chat(user, "<span class='notice'>Вы извлекаете [current_beaker] из разъема для мензурки.</span>")
	user.put_in_hands(current_beaker)
	current_beaker = null
	//Remove beaker reference
	push_vol()
	set_pin_data(IC_OUTPUT, 2, null)
	push_data()
	activate_pin(2)
	activate_pin(3)


/obj/item/integrated_circuit/input/beaker_connector/proc/push_vol()
	var/beakerVolume = 0
	if(current_beaker)
		beakerVolume = current_beaker.reagents.total_volume

	set_pin_data(IC_OUTPUT, 1, beakerVolume)
	push_data()


/obj/item/reagent_containers/glass/beaker/on_reagent_change()
	..()
	if(istype(loc,/obj/item/integrated_circuit/input/beaker_connector))
		var/obj/item/integrated_circuit/input/beaker_connector/current_circuit = loc
		current_circuit.push_vol()
