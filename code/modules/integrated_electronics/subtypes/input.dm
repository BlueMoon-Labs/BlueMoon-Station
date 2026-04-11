/obj/item/integrated_circuit/input
	var/can_be_asked_input = 0
	category_text = "Ввод"
	power_draw_per_use = 5

/obj/item/integrated_circuit/input/proc/ask_for_input(mob/user)
	return

/obj/item/integrated_circuit/input/button
	name = "button"
	desc = "Эта крошечная кнопка наверняка для чего-то нужна, правда?"
	icon_state = "button"
	complexity = 1
	can_be_asked_input = 1
	inputs = list()
	outputs = list()
	activators = list("при нажатии" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/input/button/ask_for_input(mob/user) //Bit misleading name for this specific use.
	to_chat(user, "<span class='notice'>Вы нажали кнопку, названную '[displayed_name]'.</span>")
	activate_pin(1)

/obj/item/integrated_circuit/input/toggle_button
	name = "toggle button"
	desc = "Она включается, выключается, включается, выключается..."
	icon_state = "toggle_button"
	complexity = 1
	can_be_asked_input = 1
	inputs = list()
	outputs = list("включено?" = IC_PINTYPE_BOOLEAN)
	activators = list("при переключении" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/input/toggle_button/ask_for_input(mob/user) // Ditto.
	set_pin_data(IC_OUTPUT, 1, !get_pin_data(IC_OUTPUT, 1))
	push_data()
	activate_pin(1)
	to_chat(user, "<span class='notice'>Вы переключаете кнопку, названную '[displayed_name]' в [get_pin_data(IC_OUTPUT, 1) ? "включенный" : "выключенный"] режим.</span>")

/obj/item/integrated_circuit/input/numberpad
	name = "number pad"
	desc = "Эта небольшая цифровая клавиатура позволяет вводить цифры в систему."
	icon_state = "numberpad"
	complexity = 2
	can_be_asked_input = 1
	inputs = list()
	outputs = list("введённое число" = IC_PINTYPE_NUMBER)
	activators = list("при вводе" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 4

/obj/item/integrated_circuit/input/numberpad/ask_for_input(mob/user)
	var/new_input = input(user, "Введите число, пожалуйста",displayed_name) as null|num
	if(isnum(new_input) && user.IsAdvancedToolUser())
		set_pin_data(IC_OUTPUT, 1, new_input)
		push_data()
		activate_pin(1)

/obj/item/integrated_circuit/input/textpad
	name = "text pad"
	desc = "Этот небольшой текстовый блок позволяет пользователю вводить строку в систему."
	icon_state = "textpad"
	complexity = 2
	can_be_asked_input = 1
	inputs = list()
	outputs = list("введённая строка" = IC_PINTYPE_STRING)
	activators = list("при вводе" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 4

/obj/item/integrated_circuit/input/textpad/ask_for_input(mob/user)
	var/new_input = stripped_multiline_input(user, "Введите несколько слов, пожалуйста",displayed_name)
	if(istext(new_input) && user.IsAdvancedToolUser())
		set_pin_data(IC_OUTPUT, 1, new_input)
		push_data()
		activate_pin(1)

/obj/item/integrated_circuit/input/colorpad
	name = "color pad"
	desc = "Этот небольшой цветовой блок позволяет вводить шестнадцатеричные коды цветов в систему."
	icon_state = "colorpad"
	complexity = 2
	can_be_asked_input = 1
	inputs = list()
	outputs = list("введённый цвеет" = IC_PINTYPE_STRING)
	activators = list("при вводе" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 4

/obj/item/integrated_circuit/input/colorpad/ask_for_input(mob/user)
	var/new_color = input(user, "Введите цвет, пожалуйста", "Color", "#ffffff") as color|null
	if(new_color && user.IsAdvancedToolUser())
		set_pin_data(IC_OUTPUT, 1, new_color)
		push_data()
		activate_pin(1)

/obj/item/integrated_circuit/input/med_scanner
	name = "integrated medical analyser"
	desc = "Очень миниатюрная версия обычного медицинского анализатора. С его помощью аппарат может определить, насколько человек здоров."
	icon_state = "medscan"
	complexity = 4
	inputs = list("цель" = IC_PINTYPE_REF)
	outputs = list(
		"процент общего здоровья" = IC_PINTYPE_NUMBER,
		"общее потерянное здоровье" = IC_PINTYPE_NUMBER
		)
	activators = list("сканировать" = IC_PINTYPE_PULSE_IN, "при сканировании" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 40

/obj/item/integrated_circuit/input/med_scanner/do_work()
	var/mob/living/H = get_pin_data_as_type(IC_INPUT, 1, /mob/living)
	if(!istype(H)) //Invalid input
		return
	if(H.Adjacent(get_turf(src))) // Like normal analysers, it can't be used at range.
		var/total_health = round(H.health/H.getMaxHealth(), 0.01)*100
		var/missing_health = H.getMaxHealth() - H.health

		set_pin_data(IC_OUTPUT, 1, total_health)
		set_pin_data(IC_OUTPUT, 2, missing_health)

	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/input/adv_med_scanner
	name = "integrated adv. medical analyser"
	desc = "Очень миниатюрная версия медицинского анализатора медбота. Благодаря ей аппарат может определить, насколько человек здоров. \
    Этот тип анализатора гораздо точнее, что позволяет аппарату получить гораздо больше информации о целевом объекте, чем обычный анализатор."
	icon_state = "medscan_adv"
	complexity = 12
	inputs = list("target" = IC_PINTYPE_REF)
	outputs = list(
		"процент общего здоровья"		= IC_PINTYPE_NUMBER,
		"общее потерянное здоровье"	= IC_PINTYPE_NUMBER,
		"ушибы" = IC_PINTYPE_NUMBER,
		"ожоги" = IC_PINTYPE_NUMBER,
		"токсины" = IC_PINTYPE_NUMBER,
		"удушение" = IC_PINTYPE_NUMBER,
		"клеточный урон" = IC_PINTYPE_NUMBER
	)
	activators = list("сканировать" = IC_PINTYPE_PULSE_IN, "при сканировании" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 80

/obj/item/integrated_circuit/input/adv_med_scanner/do_work()
	var/mob/living/H = get_pin_data_as_type(IC_INPUT, 1, /mob/living)
	if(!istype(H)) //Invalid input
		return
	if(H in view(get_turf(src))) // Like medbot's analyzer it can be used in range..
		var/total_health = round(H.health/H.getMaxHealth(), 0.01)*100
		var/missing_health = H.getMaxHealth() - H.health

		set_pin_data(IC_OUTPUT, 1, total_health)
		set_pin_data(IC_OUTPUT, 2, missing_health)
		set_pin_data(IC_OUTPUT, 3, H.getBruteLoss())
		set_pin_data(IC_OUTPUT, 4, H.getFireLoss())
		set_pin_data(IC_OUTPUT, 5, H.getToxLoss())
		set_pin_data(IC_OUTPUT, 6, H.getOxyLoss())
		set_pin_data(IC_OUTPUT, 7, H.getCloneLoss())

	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/input/slime_scanner
	name = "slime_scanner"
	desc = "Очень компактная версия анализатора ксенобио. Это позволяет устройству определять все необходимые свойства слизи. Выводимый список мутаций не является ассоциативным."
	icon_state = "medscan_adv"
	complexity = 12
	inputs = list("target" = IC_PINTYPE_REF)
	outputs = list(
		"цвет" = IC_PINTYPE_STRING,
		"взрослый?" = IC_PINTYPE_BOOLEAN,
		"насыщение"	= IC_PINTYPE_NUMBER,
		"заряд" = IC_PINTYPE_NUMBER,
		"здоровье" = IC_PINTYPE_NUMBER,
		"возможные мутации" = IC_PINTYPE_LIST,
		"генетическая нестабильность" = IC_PINTYPE_NUMBER,
		"количество ядер" = IC_PINTYPE_NUMBER,
		"Процесс роста" = IC_PINTYPE_NUMBER,
	)
	activators = list("сканировать" = IC_PINTYPE_PULSE_IN, "при сканировании" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 80

/obj/item/integrated_circuit/input/slime_scanner/do_work()
	var/mob/living/simple_animal/slime/T = get_pin_data_as_type(IC_INPUT, 1, /mob/living/simple_animal/slime)
	if(!isslime(T)) //Invalid input
		return
	if(T in view(get_turf(src))) // Like medbot's analyzer it can be used in range..

		set_pin_data(IC_OUTPUT, 1, T.colour)
		set_pin_data(IC_OUTPUT, 2, T.is_adult)
		set_pin_data(IC_OUTPUT, 3, T.nutrition/T.get_max_nutrition())
		set_pin_data(IC_OUTPUT, 4, T.powerlevel)
		set_pin_data(IC_OUTPUT, 5, round(T.health/T.maxHealth,0.01)*100)
		set_pin_data(IC_OUTPUT, 6, uniqueList(T.slime_mutation))
		set_pin_data(IC_OUTPUT, 7, T.mutation_chance)
		set_pin_data(IC_OUTPUT, 8, T.cores)
		set_pin_data(IC_OUTPUT, 9, T.amount_grown/SLIME_EVOLUTION_THRESHOLD)


	push_data()
	activate_pin(2)



/obj/item/integrated_circuit/input/plant_scanner
	name = "integrated plant analyzer"
	desc = "Очень компактная версия анализатора растений. Это позволяет устройству определять все важные параметры растений, выращенных в лотках. \
            Оно может сканировать только растения, но не семена или плоды."
	icon_state = "medscan_adv"
	complexity = 12
	inputs = list("цель" = IC_PINTYPE_REF)
	outputs = list(
		"тип растения" = IC_PINTYPE_STRING,
		"возраст" = IC_PINTYPE_NUMBER,
		"потенция" = IC_PINTYPE_NUMBER,
		"урожайность"			= IC_PINTYPE_NUMBER,
		"Скорость созревания"			= IC_PINTYPE_NUMBER,
		"Скорость производства"			= IC_PINTYPE_NUMBER,
		"Стойкость"			= IC_PINTYPE_NUMBER,
		"Продолжительность жизни"			= IC_PINTYPE_NUMBER,
		"Скорость роста сорняков"		= IC_PINTYPE_NUMBER,
		"Уязвимость к сорнякам"	= IC_PINTYPE_NUMBER,
		"Уровень сорняков"			= IC_PINTYPE_NUMBER,
		"Уровень пестицидов" = IC_PINTYPE_NUMBER,
		"Уровень токсичности"			= IC_PINTYPE_NUMBER,
		"Уровень воды"			= IC_PINTYPE_NUMBER,
		"Уровень питания"			= IC_PINTYPE_NUMBER,
		"урожай"			= IC_PINTYPE_NUMBER,
		"мертвый"			= IC_PINTYPE_NUMBER,
		"здоровье растения"			= IC_PINTYPE_NUMBER,
		"самоподдерживающийся"		= IC_PINTYPE_NUMBER,
		"с использованием орошения" 		= IC_PINTYPE_NUMBER,
		"соединенные лотки"		= IC_PINTYPE_LIST
	)
	activators = list("сканировать" = IC_PINTYPE_PULSE_IN, "при сканировании" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 10

/obj/item/integrated_circuit/input/plant_scanner/do_work()
	var/obj/machinery/hydroponics/H = get_pin_data_as_type(IC_INPUT, 1, /obj/machinery/hydroponics)
	if(!istype(H)) //Invalid input
		return
	for(var/i=1, i<=outputs.len, i++)
		set_pin_data(IC_OUTPUT, i, null)
	if(H in view(get_turf(src))) // Like medbot's analyzer it can be used in range..
		if(H.myseed)
			set_pin_data(IC_OUTPUT, 1, H.myseed.plantname)
			set_pin_data(IC_OUTPUT, 2, H.age)
			set_pin_data(IC_OUTPUT, 3, H.myseed.potency)
			set_pin_data(IC_OUTPUT, 4, H.myseed.yield)
			set_pin_data(IC_OUTPUT, 5, H.myseed.maturation)
			set_pin_data(IC_OUTPUT, 6, H.myseed.production)
			set_pin_data(IC_OUTPUT, 7, H.myseed.endurance)
			set_pin_data(IC_OUTPUT, 8, H.myseed.lifespan)
			set_pin_data(IC_OUTPUT, 9, H.myseed.weed_rate)
			set_pin_data(IC_OUTPUT, 10, H.myseed.weed_chance)
		set_pin_data(IC_OUTPUT, 11, H.weedlevel)
		set_pin_data(IC_OUTPUT, 12, H.pestlevel)
		set_pin_data(IC_OUTPUT, 13, H.toxic)
		set_pin_data(IC_OUTPUT, 14, H.waterlevel)
		set_pin_data(IC_OUTPUT, 15, H.reagents.total_volume)
		set_pin_data(IC_OUTPUT, 16, H.harvest)
		set_pin_data(IC_OUTPUT, 17, H.dead)
		set_pin_data(IC_OUTPUT, 18, H.plant_health)
		set_pin_data(IC_OUTPUT, 19, H.self_sustaining)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/input/gene_scanner
	name = "gene scanner"
	desc = "Эта схема будет сканировать исследуемое растение на наличие признаков и генов-реагентов. Результат не является ассоциативным."
	extended_desc = "Это позволяет аппарату сканировать растения в лотках на наличие генов-реагентов и признаков. \
            Он может сканировать только растения, но не семена или плоды."
	inputs = list(
		"цель" = IC_PINTYPE_REF
	)
	outputs = list(
		"признаки" = IC_PINTYPE_LIST,
		"реагенты" = IC_PINTYPE_LIST
	)
	activators = list("сканировать" = IC_PINTYPE_PULSE_IN, "при сканировании" = IC_PINTYPE_PULSE_OUT)
	icon_state = "medscan_adv"
	spawn_flags = IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/input/gene_scanner/do_work()
	var/list/gtraits = list()
	var/list/greagents = list()
	var/obj/machinery/hydroponics/H = get_pin_data_as_type(IC_INPUT, 1, /obj/machinery/hydroponics)
	if(!istype(H)) //Invalid input
		return
	for(var/i=1, i<=outputs.len, i++)
		set_pin_data(IC_OUTPUT, i, null)
	if(H in view(get_turf(src))) // Like medbot's analyzer it can be used in range..
		if(H.myseed)
			for(var/datum/plant_gene/reagent/G in H.myseed.genes)
				greagents.Add(G.get_name())

			for(var/datum/plant_gene/trait/G in H.myseed.genes)
				gtraits.Add(G.get_name())

	set_pin_data(IC_OUTPUT, 1, gtraits)
	set_pin_data(IC_OUTPUT, 2, greagents)
	push_data()
	activate_pin(2)


/obj/item/integrated_circuit/input/examiner
	name = "examiner"
	desc = "Это небольшая система машинного зрения. Она может выдать название, описание, расстояние, \
    относительные координаты, общее количество реагентов, максимальное количество реагентов, плотность и непрозрачность объекта, на который указывает."
	icon_state = "video_camera"
	complexity = 6
	inputs = list(
		"цель" = IC_PINTYPE_REF
		)
	outputs = list(
		"имя"				 	= IC_PINTYPE_STRING,
		"описание"			= IC_PINTYPE_STRING,
		"X"						= IC_PINTYPE_NUMBER,
		"Y"						= IC_PINTYPE_NUMBER,
		"дистанция"				= IC_PINTYPE_NUMBER,
		"максимальное количество реагентов"			= IC_PINTYPE_NUMBER,
		"количество реагентов"	= IC_PINTYPE_NUMBER,
		"плотность"				= IC_PINTYPE_BOOLEAN,
		"непрозрачность"				= IC_PINTYPE_BOOLEAN,
		"занятая территория"			= IC_PINTYPE_REF
		)
	activators = list(
		"сканировать" = IC_PINTYPE_PULSE_IN,
		"при сканировании" = IC_PINTYPE_PULSE_OUT,
		"если сканирование не удалось" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 80

/obj/item/integrated_circuit/input/examiner/do_work()
	var/atom/H = get_pin_data_as_type(IC_INPUT, 1, /atom)
	var/turf/T = get_turf(src)

	if(!istype(H) || !(H in view(T)))
		activate_pin(3)
	else
		set_pin_data(IC_OUTPUT, 1, H.name)
		set_pin_data(IC_OUTPUT, 2, H.desc)

		if(istype(H, /mob/living))
			var/mob/living/carbon/human/D = generate_or_wait_for_human_dummy(DUMMY_HUMAN_SLOT_EXAMINER)
			var/msg = H.examine(D)
			if(msg)
				set_pin_data(IC_OUTPUT, 2, msg)
			unset_busy_human_dummy(DUMMY_HUMAN_SLOT_EXAMINER)

		set_pin_data(IC_OUTPUT, 3, H.x-T.x)
		set_pin_data(IC_OUTPUT, 4, H.y-T.y)
		set_pin_data(IC_OUTPUT, 5, sqrt((H.x-T.x)*(H.x-T.x)+ (H.y-T.y)*(H.y-T.y)))
		var/mr = 0
		var/tr = 0
		if(H.reagents)
			mr = H.reagents.maximum_volume
			tr = H.reagents.total_volume
		set_pin_data(IC_OUTPUT, 6, mr)
		set_pin_data(IC_OUTPUT, 7, tr)
		set_pin_data(IC_OUTPUT, 8, H.density)
		set_pin_data(IC_OUTPUT, 9, H.opacity)
		set_pin_data(IC_OUTPUT, 10, get_turf(H))
		push_data()
		activate_pin(2)

/obj/item/integrated_circuit/input/turfpoint
	name = "Tile pointer"
	desc = "Эта схема вернет ссылку на плитку с указанными абсолютными координатами."
	extended_desc = "Если робот не видит цель, он не сможет рассчитать правильное направление.\
	Эта схема работает только внутри корпуса."
	icon_state = "numberpad"
	complexity = 5
	inputs = list("X" = IC_PINTYPE_NUMBER,"Y" = IC_PINTYPE_NUMBER)
	outputs = list("плитка" = IC_PINTYPE_REF)
	activators = list("вычислить направление" = IC_PINTYPE_PULSE_IN, "при вычислении" = IC_PINTYPE_PULSE_OUT,"если вычисление не удалось" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 40

/obj/item/integrated_circuit/input/turfpoint/do_work()
	if(!assembly)
		activate_pin(3)
		return
	var/turf/T = get_turf(assembly)
	var/target_x = clamp(get_pin_data(IC_INPUT, 1), 0, world.maxx)
	var/target_y = clamp(get_pin_data(IC_INPUT, 2), 0, world.maxy)
	var/turf/A = locate(target_x, target_y, T.z)
	set_pin_data(IC_OUTPUT, 1, null)
	if(!A || !(A in view(T)))
		activate_pin(3)
		return
	else
		set_pin_data(IC_OUTPUT, 1, WEAKREF(A))
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/input/turfscan
	name = "tile analyzer"
	desc = "Эта схема способна анализировать содержимое отсканированного изображения и распознавать буквы на нем."
	icon_state = "video_camera"
	complexity = 5
	inputs = list(
		"цель" = IC_PINTYPE_REF
		)
	outputs = list(
		"найденные ссылки" 		= IC_PINTYPE_LIST,
		"написанные символы" 	= IC_PINTYPE_STRING,
		"зона"				= IC_PINTYPE_STRING
		)
	activators = list(
		"сканировать" = IC_PINTYPE_PULSE_IN,
		"при сканировании" = IC_PINTYPE_PULSE_OUT,
		"если сканирование не удалось" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 40
	cooldown_per_use = 10

/obj/item/integrated_circuit/input/turfscan/do_work()
	var/turf/scanned_turf = get_pin_data_as_type(IC_INPUT, 1, /turf)
	var/turf/circuit_turf = get_turf(src)
	var/area_name = get_area_name(scanned_turf)
	if(!istype(scanned_turf)) //Invalid input
		activate_pin(3)
		return

	if(scanned_turf in view(circuit_turf)) // This is a camera. It can't examine things that it can't see.
		var/list/turf_contents = new()
		for(var/obj/U in scanned_turf)
			turf_contents += WEAKREF(U)
		for(var/mob/U in scanned_turf)
			turf_contents += WEAKREF(U)
		set_pin_data(IC_OUTPUT, 1, turf_contents)
		set_pin_data(IC_OUTPUT, 3, area_name)
		var/list/St = new()
		for(var/obj/effect/decal/cleanable/crayon/I in scanned_turf)
			St.Add(I.icon_state)
		if(St.len)
			set_pin_data(IC_OUTPUT, 2, jointext(St, ",", 1, 0))
		push_data()
		activate_pin(2)
	else
		activate_pin(3)

/obj/item/integrated_circuit/input/local_locator
	name = "local locator"
	desc = "Это необходимо для некоторых устройств, которым требуется ссылка на объект, с которым они должны взаимодействовать. Данный тип определяет только то, \
    что содержит устройство, в котором оно находится."
	inputs = list()
	outputs = list("найденная ссылка"		= IC_PINTYPE_REF,
					"это поверхность?"			= IC_PINTYPE_BOOLEAN,
					"это существо?"		= IC_PINTYPE_BOOLEAN)
	activators = list("найти" = IC_PINTYPE_PULSE_IN,
		"при сканировании" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 20

/obj/item/integrated_circuit/input/local_locator/do_work()
	var/datum/integrated_io/O = outputs[1]
	O.data = null
	if(assembly)
		O.data = WEAKREF(assembly.loc)
	set_pin_data(IC_OUTPUT, 2, isturf(assembly.loc))
	set_pin_data(IC_OUTPUT, 3, ismob(assembly.loc))
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/input/adjacent_locator
	name = "adjacent locator"
	desc = "Это необходимо для некоторых устройств, которым требуется ориентир, по отношению к которому они могут действовать. Данный тип определяет только объекты, \
    находящиеся на расстоянии до одного метра от устройства."
	extended_desc = "Первый пин требует ссылки на тип объекта, который должен найти локатор. Это означает, что он будет \
    выдавать указатели на похожие объекты, находящиеся поблизости. Если поблизости найдется более одного подходящего объекта, он выберет один из них \
    случайным образом."
	inputs = list("ссылка желаемого типа" = IC_PINTYPE_REF)
	outputs = list("найденная ссылка" = IC_PINTYPE_REF)
	activators = list("найти" = IC_PINTYPE_PULSE_IN,"найдено" = IC_PINTYPE_PULSE_OUT,
		"не найдено" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 30

/obj/item/integrated_circuit/input/adjacent_locator/do_work()
	var/datum/integrated_io/I = inputs[1]
	var/datum/integrated_io/O = outputs[1]
	O.data = null

	if(!isweakref(I.data))
		return
	var/atom/A = I.data.resolve()
	if(!A)
		return
	var/desired_type = A.type

	var/list/nearby_things = range(1, get_turf(src))
	var/list/valid_things = list()
	for(var/atom/thing in nearby_things)
		if(thing.type != desired_type)
			continue
		valid_things.Add(thing)
	if(valid_things.len)
		O.data = WEAKREF(pick(valid_things))
		activate_pin(2)
	else
		activate_pin(3)
	O.push_data()

/obj/item/integrated_circuit/input/advanced_locator_list
	complexity = 6
	name = "list advanced locator"
	desc = "Это необходимо для некоторых устройств, которым требуется список имен объектов, с которыми нужно взаимодействовать. Данный тип позволяет обнаружить объекты, \
    находящиеся в заданном радиусе до 8 метров. Вывод является неассоциативным. При вводе будут учитываться только ассоциативные ключи."
	extended_desc = "Первый пин требует указания списка типов объектов, которые должен найти локатор. Он найдет ближайшие объекты по имени и описанию, \
    а затем предоставит список всех найденных объектов, которые соответствуют заданным критериям. \
    Второй пин это радиус."
	inputs = list("список ссылок желаемого типа" = IC_PINTYPE_LIST, "радиус" = IC_PINTYPE_NUMBER)
	outputs = list("найденная ссылка" = IC_PINTYPE_LIST)
	activators = list("найти" = IC_PINTYPE_PULSE_IN,"найдено" = IC_PINTYPE_PULSE_OUT,"не найдено" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 30
	var/radius = 1
	cooldown_per_use = 10

/obj/item/integrated_circuit/input/advanced_locator_list/on_data_written()
	var/rad = get_pin_data(IC_INPUT, 2)

	if(isnum(rad))
		rad = clamp(rad, 0, 8)
		radius = rad

/obj/item/integrated_circuit/input/advanced_locator_list/do_work()
	var/datum/integrated_io/I = inputs[1]
	var/datum/integrated_io/O = outputs[1]
	O.data = null
	var/list/input_list = list()
	input_list = I.data
	if(length(input_list))	//if there is no input don't do anything.
		var/turf/T = get_turf(src)
		var/list/nearby_things = view(radius,T)
		var/list/valid_things = list()
		for(var/item in input_list)
			if(!isnull(item) && !isnum(item))
				if(istext(item))
					for(var/i in nearby_things)
						var/atom/thing = i
						if(ismob(thing) && !isliving(thing))
							continue
						if(findtext(addtext(thing.name," ",thing.desc), item, 1, 0) )
							valid_things.Add(WEAKREF(thing))
				else
					var/atom/A = item
					var/desired_type = A.type
					for(var/i in nearby_things)
						var/atom/thing = i
						if(thing.type != desired_type)
							continue
						if(ismob(thing) && !isliving(thing))
							continue
						valid_things.Add(WEAKREF(thing))
		if(valid_things.len)
			O.data = valid_things
			O.push_data()
			activate_pin(2)
		else
			O.push_data()
			activate_pin(3)
	else
		O.push_data()
		activate_pin(3)

/obj/item/integrated_circuit/input/advanced_locator
	complexity = 6
	name = "advanced locator"
	desc = "Это необходимо для некоторых устройств, которым требуется ссылка на объект, по отношению к которому они могут действовать. Данный тип определяет местонахождение объекта, \
    находящегося в заданном радиусе до 8 метров"
	extended_desc = "Первый пин требует ссылку на тип объекта, который локатор должен обнаружить. Это означает, что он будет \
	выдавать ссылки на ближайшие объекты того же типа. Если в этот пин передана строка, локатор будет искать \
	предмет, в названии или описании которого содержится указанный текст. Если поблизости найдено несколько \
	подходящих объектов, один из них будет выбран случайным образом. Второй пин это радиус."
	inputs = list("желаемый тип" = IC_PINTYPE_ANY, "радиус" = IC_PINTYPE_NUMBER)
	outputs = list("найденная ссылка" = IC_PINTYPE_REF)
	activators = list("найти" = IC_PINTYPE_PULSE_IN,"найдено" = IC_PINTYPE_PULSE_OUT,"не найдено" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 30
	var/radius = 1

/obj/item/integrated_circuit/input/advanced_locator/on_data_written()
	var/rad = get_pin_data(IC_INPUT, 2)
	if(isnum(rad))
		rad = clamp(rad, 0, 8)
		radius = rad

/obj/item/integrated_circuit/input/advanced_locator/do_work()
	var/datum/integrated_io/I = inputs[1]
	var/datum/integrated_io/O = outputs[1]
	O.data = null
	var/turf/T = get_turf(src)
	var/list/nearby_things =  view(radius,T)
	var/list/valid_things = list()
	if(isweakref(I.data))
		var/atom/A = I.data.resolve()
		if(!A)
			O.push_data()
			activate_pin(3)
			return
		var/desired_type = A.type
		if(desired_type)
			for(var/i in nearby_things)
				var/atom/thing = i
				if(ismob(thing) && !isliving(thing))
					continue
				if(thing.type == desired_type)
					valid_things.Add(thing)
	else if(istext(I.data))
		var/DT = I.data
		for(var/i in nearby_things)
			var/atom/thing = i
			if(ismob(thing) && !isliving(thing))
				continue
			if(findtext(addtext(thing.name," ",thing.desc), DT, 1, 0) )
				valid_things.Add(thing)
	if(valid_things.len)
		O.data = WEAKREF(pick(valid_things))
		O.push_data()
		activate_pin(2)
	else
		O.push_data()
		activate_pin(3)

/obj/item/integrated_circuit/input/signaler
	name = "integrated signaler"
	desc = "С его помощью можно принимать сигналы от сигнализатора, что позволяет осуществлять дистанционное управление. Он также может отправлять сигналы."
	extended_desc = "При получении сигнала от другого сигнализатора на выводе активатора 'получение сигнала' появится импульс. \
    Два входных пина служат для настройки параметров встроенного сигнализатора. Обратите внимание, что в значении частоты не должно быть десятичной дроби, \
    то есть частота по умолчанию указывается как 1457, а не 145,7. Для отправки сигнала подайте импульс на пин активатора 'отправка сигнала'."
	icon_state = "signal"
	complexity = 4
	inputs = list("частота" = IC_PINTYPE_NUMBER,"код" = IC_PINTYPE_NUMBER)
	outputs = list()
	activators = list(
		"отправить сигнал" = IC_PINTYPE_PULSE_IN,
		"при отправке сигнала" = IC_PINTYPE_PULSE_OUT,
		"при приёме сигнала" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_LONG_RANGE
	power_draw_idle = 5
	power_draw_per_use = 40
	cooldown_per_use = 5
	var/frequency = FREQ_SIGNALER
	var/code = DEFAULT_SIGNALER_CODE
	var/datum/radio_frequency/radio_connection
	var/hearing_range = 1

/obj/item/integrated_circuit/input/signaler/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(init_frequency)), 4 SECONDS)

/obj/item/integrated_circuit/input/signaler/Destroy()
	SSradio.remove_object(src,frequency)
	frequency = 0
	return ..()

/obj/item/integrated_circuit/input/signaler/proc/init_frequency()
	set_frequency(frequency)
	// Set the pins so when someone sees them, they won't show as null
	set_pin_data(IC_INPUT, 1, frequency)
	set_pin_data(IC_INPUT, 2, code)

/obj/item/integrated_circuit/input/signaler/on_data_written()
	var/new_freq = get_pin_data(IC_INPUT, 1)
	var/new_code = get_pin_data(IC_INPUT, 2)
	if(isnum(new_freq) && new_freq > 0)
		set_frequency(new_freq)
	if(isnum(new_code))
		code = new_code


/obj/item/integrated_circuit/input/signaler/do_work() // Sends a signal.
	if(!radio_connection)
		return

	var/datum/signal/signal = new(list("code" = code))
	radio_connection.post_signal(src, signal)
	activate_pin(2)

/obj/item/integrated_circuit/input/signaler/proc/set_frequency(new_frequency)
	if(!frequency)
		return
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = SSradio.add_object(src, frequency, RADIO_SIGNALER)

/obj/item/integrated_circuit/input/signaler/receive_signal(datum/signal/signal)
	var/new_code = get_pin_data(IC_INPUT, 2)
	var/code = 0

	if(isnum(new_code))
		code = new_code
	if(!signal)
		return FALSE
	if(signal.data["code"] != code)
		return FALSE
	if(signal.source == src) // Don't trigger ourselves.
		return FALSE

	activate_pin(3)
	audible_message("[icon2html(src, hearers(src))] *beep* *beep* *beep*", null, hearing_range)
	for(var/CHM in get_hearers_in_view(hearing_range, src))
		if(ismob(CHM))
			var/mob/LM = CHM
			LM.playsound_local(get_turf(src), 'sound/machines/triple_beep.ogg', ASSEMBLY_BEEP_VOLUME, TRUE)

/obj/item/integrated_circuit/input/ntnet_packet
	name = "NTNet networking circuit"
	desc = "Включает отправку и получение сообщений через NTNet с помощью протокола пакетной передачи данных."
	extended_desc = "Данные можно отправлять или принимать с помощью второго пина с каждой стороны, \
    а третий пин зарезервирован для дополнительных данных. При получении сообщения второй пин активации \
    подаст импульс на подключенное к нему устройство. Импульс на первом пине активации приведет к отправке сообщения. Сообщения \
    можно отправлять нескольким адресатам. Адреса необходимо разделять точкой с запятой, например: Адрес1;Адрес2;и т. д."
	icon_state = "signal"
	complexity = 2
	cooldown_per_use = 1
	inputs = list(
		"целевые адреса NTNet"= IC_PINTYPE_STRING,
		"данные для отправки"			= IC_PINTYPE_STRING,
		"второстепенный текст"		= IC_PINTYPE_STRING,
		"passkey"				= IC_PINTYPE_STRING
		)
	outputs = list(
		"полученный адрес"			= IC_PINTYPE_STRING,
		"полученные данные"				= IC_PINTYPE_STRING,
		"полученный второстепенный текст"	= IC_PINTYPE_STRING,
		"полученная passkey"			= IC_PINTYPE_STRING,
		"is_broadcast"				= IC_PINTYPE_BOOLEAN
		)
	activators = list(
		"отправить данные" = IC_PINTYPE_PULSE_IN,
		"при получении данных" = IC_PINTYPE_PULSE_OUT,
		"при отправке данных" = IC_PINTYPE_PULSE_OUT,
	)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_LONG_RANGE
	power_draw_per_use = 50
	var/address

/obj/item/integrated_circuit/input/ntnet_packet/Initialize(mapload)
	. = ..()
	var/datum/component/ntnet_interface/net = LoadComponent(/datum/component/ntnet_interface)
	address = net.hardware_id
	net.differentiate_broadcast = FALSE
	desc += "<br>Аппаратный адрес NTNet этой схемы: [address]"

/obj/item/integrated_circuit/input/ntnet_packet/do_work()
	var/target_address = get_pin_data(IC_INPUT, 1)
	var/message = get_pin_data(IC_INPUT, 2)
	var/text = get_pin_data(IC_INPUT, 3)
	var/passkey = get_pin_data(IC_INPUT, 4)

	var/datum/netdata/data = new
	data.recipient_ids = splittext(target_address, ";")
	data.standard_format_data(message, text, passkey)
	if(ntnet_send(data))
		activate_pin(3)

/obj/item/integrated_circuit/input/ntnet_receive(datum/netdata/data)
	set_pin_data(IC_OUTPUT, 1, data.sender_id)
	set_pin_data(IC_OUTPUT, 2, data.data["data"])
	set_pin_data(IC_OUTPUT, 3, data.data["data_secondary"])
	set_pin_data(IC_OUTPUT, 4, data.data["encrypted_passkey"])
	set_pin_data(IC_OUTPUT, 5, data.broadcast)

	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/input/ntnet_advanced
	name = "Low level NTNet transreceiver"
	desc = "Обеспечивает отправку и получение сообщений по NTNet с помощью протокола пакетной передачи данных. Обеспечивает расширенное управление содержанием сообщений и сигнализацией. Требует использования ассоциативных списков. Выводит ассоциативный список. Имеет более низкую скорость передачи данных по сравнению с обычными схемами NTNet из-за повышенной сложности обработки данных."
	extended_desc = "Данные можно отправлять или принимать с помощью второго пина с каждой стороны. \
  При получении сообщения второй пин подает импульс на подключенное к нему устройство. \
  Импульс на первом пине инициирует отправку сообщения. Сообщения можно отправлять нескольким адресатам. \
  Адреса необходимо разделять точкой с запятой, например: Адрес1;Адрес2;и т. д."
	icon_state = "signal"
	complexity = 4
	cooldown_per_use = 10
	inputs = list(
		"целевые адреса NTNet"= IC_PINTYPE_STRING,
		"данные"					= IC_PINTYPE_LIST,
		"passkey"				= IC_PINTYPE_STRING,
		)
	outputs = list("полученные данные" = IC_PINTYPE_LIST, "is_broadcast" = IC_PINTYPE_BOOLEAN, "полученная passkey" = IC_PINTYPE_STRING)
	activators = list(
		"отправить данные" = IC_PINTYPE_PULSE_IN,
		"при получении данных" = IC_PINTYPE_PULSE_OUT,
		"при отправке данных" = IC_PINTYPE_PULSE_OUT,
	)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_LONG_RANGE
	power_draw_per_use = 50
	var/address

/obj/item/integrated_circuit/input/ntnet_advanced/Initialize(mapload)
	. = ..()
	var/datum/component/ntnet_interface/net = LoadComponent(/datum/component/ntnet_interface)
	address = net.hardware_id
	net.differentiate_broadcast = FALSE
	desc += "<br>Аппаратный адрес NTNet этой схемы: [address]"

/obj/item/integrated_circuit/input/ntnet_advanced/do_work()
	var/target_address = get_pin_data(IC_INPUT, 1)
	var/list/message = get_pin_data(IC_INPUT, 2)
	var/passkey = get_pin_data(IC_INPUT, 3)
	if(!islist(message))
		message = list()
	var/datum/netdata/data = new
	data.recipient_ids = splittext(target_address, ";")
	data.data = message
	data.passkey = passkey
	if(ntnet_send(data))
		activate_pin(3)

/obj/item/integrated_circuit/input/ntnet_advanced/ntnet_receive(datum/netdata/data)
	set_pin_data(IC_OUTPUT, 1, data.data)
	set_pin_data(IC_OUTPUT, 2, data.broadcast)
	set_pin_data(IC_OUTPUT, 3, data.passkey)
	push_data()
	activate_pin(2)

//This circuit gives information on where the machine is.
/obj/item/integrated_circuit/input/gps
	name = "global positioning system"
	desc = "Это позволяет легко определить местонахождение машины, на которой установлено данное устройство."
	extended_desc = "Координаты, выдаваемые GPS, являются абсолютными, а не относительными. В полном наборе координат они разделены запятыми и представлены в виде строки."
	icon_state = "gps"
	complexity = 4
	inputs = list()
	outputs = list("X"= IC_PINTYPE_NUMBER, "Y" = IC_PINTYPE_NUMBER, "Z" = IC_PINTYPE_NUMBER, "полные координаты" = IC_PINTYPE_STRING)
	activators = list("получить координаты" = IC_PINTYPE_PULSE_IN, "при получении координат" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 30

/obj/item/integrated_circuit/input/gps/do_work()
	var/turf/T = get_turf(src)

	set_pin_data(IC_OUTPUT, 1, null)
	set_pin_data(IC_OUTPUT, 2, null)
	set_pin_data(IC_OUTPUT, 3, null)
	set_pin_data(IC_OUTPUT, 4, null)
	if(!T)
		return

	set_pin_data(IC_OUTPUT, 1, T.x)
	set_pin_data(IC_OUTPUT, 2, T.y)
	set_pin_data(IC_OUTPUT, 3, T.z)
	set_pin_data(IC_OUTPUT, 4, "[T.x],[T.y],[T.z]")
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/input/microphone
	name = "microphone"
	desc = "Полезно для слежки за людьми или для устройств с голосовым управлением."
	extended_desc = "Это устройство автоматически переводит большинство услышанных языков на галактический общий язык. \
    Первый пин всегда подает сигнал, когда схема улавливает речь человека, а второй \
    срабатывает только в том случае, если улавливается речь на языке, отличном от галактического общего языка."
	icon_state = "recorder"
	complexity = 4 //cuts complexity in half, you'll need to use a ref to string for the name
	inputs = list()
	flags_1 = CONDUCT_1 | HEAR_1
	outputs = list(
	"говорящий" = IC_PINTYPE_REF,
	"сообщение" = IC_PINTYPE_STRING
	)
	activators = list("при получении сообщения" = IC_PINTYPE_PULSE_OUT, "при переводе" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 5

/obj/item/integrated_circuit/input/microphone/Hear(message, atom/movable/speaker, message_langs, raw_message, radio_freq, spans, message_mode, atom/movable/source)
	. = ..()
	var/translated = FALSE
	if(speaker && message)
		if(raw_message)
			if(message_langs != get_selected_language())
				translated = TRUE
		set_pin_data(IC_OUTPUT, 1, speaker)
		set_pin_data(IC_OUTPUT, 2, raw_message)

	push_data()
	activate_pin(1)
	if(translated)
		activate_pin(2)

/obj/item/integrated_circuit/input/sensor
	name = "sensor"
	desc = "Сканирует и выдает информацию о любых объектах или людях, находящихся рядом с вами. Достаточно просто поднести устройство к их лицу."
	extended_desc = "Если для параметра 'игнорировать хранилища?' установлено значение true, датчик не будет сканировать различные емкости для хранения, такие как рюкзаки."
	icon_state = "recorder"
	complexity = 12
	inputs = list("игнорировать хранилища?" = IC_PINTYPE_BOOLEAN)
	outputs = list("просканированный объект" = IC_PINTYPE_REF)
	activators = list("при сканировании" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 120

/obj/item/integrated_circuit/input/sensor/sense(atom/A, mob/user, prox)
	if(!prox || !A || (ismob(A) && !isliving(A)))
		return FALSE
	if(!check_then_do_work())
		return FALSE
	var/ignore_bags = get_pin_data(IC_INPUT, 1)
	if(ignore_bags)
		var/datum/component/storage/STR = A.GetComponent(/datum/component/storage)
		if(STR)
			return FALSE
	set_pin_data(IC_OUTPUT, 1, WEAKREF(A))
	push_data()
	to_chat(user, "<span class='notice'>Вы сканируете [A] с помощью [assembly].</span>")
	activate_pin(1)
	return TRUE

/obj/item/integrated_circuit/input/sensor/ranged
	name = "ranged sensor"
	desc = "Сканирует и определяет координаты всех объектов или людей, находящихся в зоне действия. Достаточно просто направить устройство на цель."
	extended_desc = "Если для параметра 'игнорировать хранилища?' установлено значение true, датчик не будет сканировать различные емкости для хранения, такие как рюкзаки."
	icon_state = "recorder"
	complexity = 36
	inputs = list("игнорировать хранилища?" = IC_PINTYPE_BOOLEAN)
	outputs = list("просканированный объект" = IC_PINTYPE_REF)
	activators = list("при сканировании" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 120

/obj/item/integrated_circuit/input/sensor/ranged/sense(atom/A, mob/user)
	if(!user || !A || (ismob(A) && !isliving(A)))
		return FALSE
	if(user.client)
		if(!(A in view(user.client)))
			return FALSE
	else
		if(!(A in view(user)))
			return FALSE
	if(!check_then_do_work())
		return FALSE
	var/ignore_bags = get_pin_data(IC_INPUT, 1)
	if(ignore_bags)
		if(istype(A, /obj/item/storage))
			return FALSE
	set_pin_data(IC_OUTPUT, 1, WEAKREF(A))
	push_data()
	to_chat(user, "<span class='notice'>Вы сканируете [A] с помощью [assembly].</span>")
	activate_pin(1)
	return TRUE

/obj/item/integrated_circuit/input/obj_scanner
	name = "scanner"
	desc = "Проводит сканирование и получает ссылки на все объекты, используемые в корпусе."
	extended_desc = "Если пин 'положить' установлен в значение true, корпус перенесет отсканированный объект из ваших рук в указанное место. \
    Полезно для взаимодействия с захватом. Сканер работает только при использовании команды «help»."
	icon_state = "recorder"
	complexity = 4
	inputs = list("положить" = IC_PINTYPE_BOOLEAN)
	outputs = list("просканированный объект" = IC_PINTYPE_REF)
	activators = list("при сканировании" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 20

/obj/item/integrated_circuit/input/obj_scanner/attackby_react(var/atom/A,var/mob/user,intent)
	if(intent!=INTENT_HELP)
		return FALSE
	if(!check_then_do_work())
		return FALSE
	var/pu = get_pin_data(IC_INPUT, 1)
	if(pu)
		user.transferItemToLoc(A,drop_location())
	set_pin_data(IC_OUTPUT, 1, WEAKREF(A))
	push_data()
	to_chat(user, "<span class='notice'>Вы позволяете [assembly] просканировать [A].</span>")
	activate_pin(1)
	return TRUE

/obj/item/integrated_circuit/input/internalbm
	name = "internal battery monitor"
	desc = "Это устройство отслеживает уровень заряда встроенного аккумулятора."
	icon_state = "internalbm"
	extended_desc = "Эта схема по запросу предоставит вам данные о заряде, максимальном заряде и текущем проценте заряда встроенного аккумулятора."
	w_class = WEIGHT_CLASS_TINY
	complexity = 1
	inputs = list()
	outputs = list(
		"заряд батареи" = IC_PINTYPE_NUMBER,
		"максимальный заряд" = IC_PINTYPE_NUMBER,
		"процент" = IC_PINTYPE_NUMBER,
		"ссылка на корпус" = IC_PINTYPE_REF,
		"ссылка на батарею" = IC_PINTYPE_REF
		)
	activators = list("прочесть" = IC_PINTYPE_PULSE_IN, "при прочтении" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 1

/obj/item/integrated_circuit/input/internalbm/do_work()
	set_pin_data(IC_OUTPUT, 1, null)
	set_pin_data(IC_OUTPUT, 2, null)
	set_pin_data(IC_OUTPUT, 3, null)
	set_pin_data(IC_OUTPUT, 4, null)
	set_pin_data(IC_OUTPUT, 5, null)
	if(assembly)
		set_pin_data(IC_OUTPUT, 4, WEAKREF(assembly))
		if(assembly.battery)
			set_pin_data(IC_OUTPUT, 1, assembly.battery.charge)
			set_pin_data(IC_OUTPUT, 2, assembly.battery.maxcharge)
			set_pin_data(IC_OUTPUT, 3, 100*assembly.battery.charge/assembly.battery.maxcharge)
			set_pin_data(IC_OUTPUT, 5, WEAKREF(assembly.battery))
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/input/externalbm
	name = "external battery monitor"
	desc = "Эта схема позволяет считывать состояние аккумулятора любого устройства, находящегося в поле зрения."
	icon_state = "externalbm"
	extended_desc = "Эта схема отобразит заряд, максимальный заряд и текущий процент заряда любого устройства или аккумулятора, находящегося в поле зрения."
	w_class = WEIGHT_CLASS_TINY
	complexity = 2
	inputs = list("target" = IC_PINTYPE_REF)
	outputs = list(
		"заряд батареи" = IC_PINTYPE_NUMBER,
		"максимальный заряд" = IC_PINTYPE_NUMBER,
		"процент" = IC_PINTYPE_NUMBER
		)
	activators = list("прочесть" = IC_PINTYPE_PULSE_IN, "при прочтении" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 1

/obj/item/integrated_circuit/input/externalbm/do_work()

	var/atom/movable/AM = get_pin_data_as_type(IC_INPUT, 1, /atom/movable)
	set_pin_data(IC_OUTPUT, 1, null)
	set_pin_data(IC_OUTPUT, 2, null)
	set_pin_data(IC_OUTPUT, 3, null)
	if(AM)
		var/obj/item/stock_parts/cell/C = AM.get_cell()
		if(C)
			var/turf/A = get_turf(src)
			if(get_turf(AM) in view(A))
				set_pin_data(IC_OUTPUT, 1, C.charge)
				set_pin_data(IC_OUTPUT, 2, C.maxcharge)
				set_pin_data(IC_OUTPUT, 3, C.percent())
	push_data()
	activate_pin(2)
	return

/obj/item/integrated_circuit/input/ntnetsc
	name = "NTNet scanner"
	desc = "Эта схема может вернуть идентификаторы NTNet компонентов, содержащихся в указанном объекте, если таковые имеются."
	icon_state = "signalsc"
	w_class = WEIGHT_CLASS_TINY
	complexity = 2
	inputs = list("цель" = IC_PINTYPE_REF)
	outputs = list(
		"id" = IC_PINTYPE_STRING
		)
	activators = list("прочесть" = IC_PINTYPE_PULSE_IN, "найдено" = IC_PINTYPE_PULSE_OUT,"не найдено" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 1

/obj/item/integrated_circuit/input/ntnetsc/do_work()
	var/atom/AM = get_pin_data_as_type(IC_INPUT, 1, /atom)
	var/datum/component/ntnet_interface/net

	if(AM)
		var/list/processing_list = list(AM)
		while(processing_list.len && !net)
			var/atom/A = processing_list[1]
			processing_list.Cut(1, 2)
			//Byond does not allow things to be in multiple contents, or double parent-child hierarchies, so only += is needed
			//This is also why we don't need to check against assembled as we go along
			processing_list += A.contents
			net = A.GetComponent(/datum/component/ntnet_interface)

	if(net)
		set_pin_data(IC_OUTPUT, 1, net.hardware_id)
		push_data()
		activate_pin(2)
	else
		set_pin_data(IC_OUTPUT, 1, null)
		push_data()
		activate_pin(3)

/obj/item/integrated_circuit/input/matscan
	name = "material scanner"
	desc = "Этот специальный модуль предназначен для сбора информации о контейнерах для материалов, используемых на различных станках, \
            таких как ORM, протолаты и т. д."
	icon_state = "video_camera"
	complexity = 6
	inputs = list(
		"цель" = IC_PINTYPE_REF
		)
	outputs = list(
		"Металл"				 	= IC_PINTYPE_NUMBER,
		"Стекло"					= IC_PINTYPE_NUMBER,
		"Серебро"				= IC_PINTYPE_NUMBER,
		"Золото"					= IC_PINTYPE_NUMBER,
		"Алмазы"				= IC_PINTYPE_NUMBER,
		"Твёрдая плазма"			= IC_PINTYPE_NUMBER,
		"Уран"				= IC_PINTYPE_NUMBER,
		"Бананиум"				= IC_PINTYPE_NUMBER,
		"Титан"		= IC_PINTYPE_NUMBER,
		"Блюспейс кристаллы"		= IC_PINTYPE_NUMBER,
		"Биомасса"				= IC_PINTYPE_NUMBER,
		"Пластик"				= IC_PINTYPE_NUMBER
		)
	activators = list(
		"сканировать" = IC_PINTYPE_PULSE_IN,
		"при сканировании" = IC_PINTYPE_PULSE_OUT,
		"сканирование не удалось" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 40
	var/list/mtypes = list(/datum/material/iron, /datum/material/glass, /datum/material/silver, /datum/material/gold, /datum/material/diamond, /datum/material/plasma, /datum/material/uranium, /datum/material/bananium, /datum/material/titanium, /datum/material/bluespace, /datum/material/biomass, /datum/material/plastic)


/obj/item/integrated_circuit/input/matscan/do_work()
	var/atom/movable/H = get_pin_data_as_type(IC_INPUT, 1, /atom/movable)
	var/turf/T = get_turf(src)
	var/datum/component/material_container/mt = H.GetComponent(/datum/component/material_container)
	if(!mt) //Invalid input
		return
	if(H in view(T)) // This is a camera. It can't examine thngs,that it can't see.
		for(var/I in mtypes)
			if(I in mt.materials)
				set_pin_data(IC_OUTPUT, I, mt.materials[I])
			else
				set_pin_data(IC_OUTPUT, I, null)
		push_data()
		activate_pin(2)
	else
		activate_pin(3)

/obj/item/integrated_circuit/input/atmospheric_analyzer
	name = "atmospheric analyzer"
	desc = "Миниатюрный анализатор, способный сканировать любые объекты, содержащие газы. Оставьте поле 'цель' пустым, чтобы сканировать воздух вокруг корпуса."
	extended_desc = "n-й элемент списка газов представляет собой количество молей \
                    n-го газа в списке. \
                    Давление указано в кПа, температура - в кельвинах. \
                    В связи с ограничениями программирования при сканировании объекта, \
                    не содержащего газа, вместо него будет возвращаться окружающий воздух."
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	inputs = list(
			"цель" = IC_PINTYPE_REF
			)
	outputs = list(
			"список газов" = IC_PINTYPE_LIST,
			"количество газов" = IC_PINTYPE_LIST,
			"общее количество молей" = IC_PINTYPE_NUMBER,
			"давление" = IC_PINTYPE_NUMBER,
			"температура" = IC_PINTYPE_NUMBER,
			"объем" = IC_PINTYPE_NUMBER
			)
	activators = list(
			"сканировать" = IC_PINTYPE_PULSE_IN,
			"при успехе" = IC_PINTYPE_PULSE_OUT,
			"при неудаче" = IC_PINTYPE_PULSE_OUT
			)
	power_draw_per_use = 5

/obj/item/integrated_circuit/input/atmospheric_analyzer/do_work()
	for(var/i=1 to 6)
		set_pin_data(IC_OUTPUT, i, null)
	var/atom/target = get_pin_data_as_type(IC_INPUT, 1, /atom)
	if(!target)
		target = get_turf(src)
	if( get_dist(get_turf(target),get_turf(src)) > 1 )
		activate_pin(3)
		return

	var/datum/gas_mixture/air_contents = target.return_air()
	if(!air_contents)
		activate_pin(3)
		return

	var/list/gas_names = list()
	var/list/gas_amounts = list()
	for(var/id in air_contents.get_gases())
		var/name = GLOB.gas_data.names[id]
		var/amt = round(air_contents.get_moles(id), 0.001)
		gas_names.Add(name)
		gas_amounts.Add(amt)

	set_pin_data(IC_OUTPUT, 1, gas_names)
	set_pin_data(IC_OUTPUT, 2, gas_amounts)
	set_pin_data(IC_OUTPUT, 3, round(air_contents.total_moles(), 0.001))
	set_pin_data(IC_OUTPUT, 4, round(air_contents.return_pressure(), 0.001))
	set_pin_data(IC_OUTPUT, 5, round(air_contents.return_temperature(), 0.001))
	set_pin_data(IC_OUTPUT, 6, round(air_contents.return_volume(), 0.001))
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/input/data_card_reader
	name = "data card reader"
	desc = "Схема, способная считывать и записывать данные на карты памяти."
	extended_desc = "Если для логического параметра 'режим записи' задать значение true, то при использовании любой карты данных в корпусе \
	существующие строки функций и данных будут заменены указанными строками; если же для него задать значение false, то при использовании карты данных в корпусе \
	строки функций и данных, хранящиеся на карте, будут выведены на выводные пины."
	icon_state = "card_reader"
	complexity = 4
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	inputs = list(
		"функция" = IC_PINTYPE_STRING,
		"данные для хранения" = IC_PINTYPE_STRING,
		"режим записи" = IC_PINTYPE_BOOLEAN
	)
	outputs = list(
		"функция" = IC_PINTYPE_STRING,
		"сохраненные данные" = IC_PINTYPE_STRING
	)
	activators = list(
		"при записи" = IC_PINTYPE_PULSE_OUT,
		"при чтении" = IC_PINTYPE_PULSE_OUT
	)

/obj/item/integrated_circuit/input/data_card_reader/attackby_react(obj/item/I, mob/living/user, intent)
	var/obj/item/card/data/card = I.GetCard()
	var/write_mode = get_pin_data(IC_INPUT, 3)
	if(card)
		if(write_mode == TRUE)
			card.function = get_pin_data(IC_INPUT, 1)
			card.data = get_pin_data(IC_INPUT, 2)
			push_data()
			activate_pin(1)
		else
			set_pin_data(IC_OUTPUT, 1, card.function)
			set_pin_data(IC_OUTPUT, 2, card.data)
			push_data()
			activate_pin(2)
	else
		return FALSE
	return TRUE


//Hippie Ported Code--------------------------------------------------------------------------------------------------------


	//Adding some color to cards aswell, because why not
/obj/item/card/data/attackby(obj/item/I, mob/living/user)
	if(istype(I, /obj/item/integrated_electronics/detailer))
		var/obj/item/integrated_electronics/detailer/D = I
		detail_color = D.detail_color
		update_icon()
	return ..()



// -Inputlist- //
/obj/item/integrated_circuit/input/selection
	name = "selection circuit"
	desc = "Эта схема позволяет выбирать между различными строками из предложенного списка."
	extended_desc = "Эта схема позволяет выбирать до 4 различных значений из набора, состоящего из 8 строк, которые вы можете задать. Нулевые значения игнорируются, а выбранное значение выводится в поле 'selected'."
	icon_state = "addition"
	can_be_asked_input = 1
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	inputs = list(
		"A" = IC_PINTYPE_STRING,
		"B" = IC_PINTYPE_STRING,
		"C" = IC_PINTYPE_STRING,
		"D" = IC_PINTYPE_STRING,
		"E" = IC_PINTYPE_STRING,
		"F" = IC_PINTYPE_STRING,
		"G" = IC_PINTYPE_STRING,
		"H" = IC_PINTYPE_STRING
	)
	outputs = list(
		"выбранное" = IC_PINTYPE_STRING
	)
	activators = list(
		"при выборе" = IC_PINTYPE_PULSE_OUT
	)

/obj/item/integrated_circuit/input/selection/ask_for_input(mob/user)
	var/list/selection = list()
	for(var/k in 1 to inputs.len)
		var/I = get_pin_data(IC_INPUT, k)
		if(istext(I))
			selection.Add(I)
	var/selected = input(user,"Choose input.","Selection") in selection
	if(!selected)
		return
	set_pin_data(IC_OUTPUT, 1, selected)
	push_data()
	activate_pin(1)


// -storage examiner- // **works**
/obj/item/integrated_circuit/input/storage_examiner
	name = "storage examiner circuit"
	desc = "Эта схема позволяет сканировать содержимое контейнера (рюкзаков, ящиков для инструментов и т. п.)."
	extended_desc = "Элементы отображаются в качестве ссылок, что позволяет взаимодействовать с ними. Кроме того, указывается количество элементов."
	icon_state = "grabber"
	can_be_asked_input = 1
	complexity = 6
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	inputs = list(
		"хранилище" = IC_PINTYPE_REF
	)
	outputs = list(
		"количество предметов" = IC_PINTYPE_NUMBER,
		"список предметов" = IC_PINTYPE_LIST
	)
	activators = list(
		"осмотр" = IC_PINTYPE_PULSE_IN,
		"при осмотре" = IC_PINTYPE_PULSE_OUT
	)
	power_draw_per_use = 85

/obj/item/integrated_circuit/input/storage_examiner/do_work()
	var/obj/item/storage = get_pin_data_as_type(IC_INPUT, 1, /obj/item)
	if(!istype(storage,/obj/item/storage))
		return

	set_pin_data(IC_OUTPUT, 1, storage.contents.len)

	var/list/regurgitated_contents = list()
	for(var/obj/o in storage.contents)
		regurgitated_contents.Add(WEAKREF(o))


	set_pin_data(IC_OUTPUT, 2, regurgitated_contents)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/input/anomaly_scanner
	name = "anomaly scanner"
	desc = "Это небольшой анализатор аномалий, который достаточно точно определяет частоту, но может ошибаться при определении кода. Результат будет равен случайному числу, находящемуся в пределах 10 цифр от искомого числа."
	complexity = 12
	inputs = list("цель" = IC_PINTYPE_REF)
	outputs = list(
		"частота"				= IC_PINTYPE_NUMBER,
		"код"				= IC_PINTYPE_NUMBER,
	)
	activators = list("сканировать" = IC_PINTYPE_PULSE_IN, "при сканировании" = IC_PINTYPE_PULSE_OUT, "при неудаче сканирования" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 80

/obj/item/integrated_circuit/input/anomaly_scanner/do_work()
	var/obj/effect/anomaly/T = get_pin_data_as_type(IC_INPUT, 1, /obj/effect/anomaly)
	if(!istype(T)) //Invalid input
		activate_pin(3)
		return
	if(T in view(get_turf(src))) // Like medbot's analyzer it can be used in range..

		set_pin_data(IC_OUTPUT, 2, T.aSignal.code+rand(-10,10))
		set_pin_data(IC_OUTPUT, 1, (T.aSignal.frequency))
	push_data()
	activate_pin(2)
