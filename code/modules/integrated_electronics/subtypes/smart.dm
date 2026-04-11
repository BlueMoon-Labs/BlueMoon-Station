/obj/item/integrated_circuit/smart
	category_text = "Умное"

/obj/item/integrated_circuit/smart/basic_pathfinder
	name = "basic pathfinder"
	desc = "Эта сложная схема способна определить, в каком направлении находится данная цель."
	extended_desc = "Эта схема использует миниатюрную встроенную камеру для определения местоположения цели. Если машина \
	не видит цель, она не сможет рассчитать правильное направление."
	icon_state = "numberpad"
	complexity = 5
	inputs = list("цель" = IC_PINTYPE_REF,"игнорировать преграды?" = IC_PINTYPE_BOOLEAN)
	outputs = list("направление" = IC_PINTYPE_DIR)
	activators = list("рассчитать направление" = IC_PINTYPE_PULSE_IN, "при расчёте" = IC_PINTYPE_PULSE_OUT,"если рассчитать не удалось" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 40

/obj/item/integrated_circuit/smart/basic_pathfinder/do_work()
	var/datum/integrated_io/I = inputs[1]
	set_pin_data(IC_OUTPUT, 1, null)
	if(!isweakref(I.data))
		activate_pin(3)
		return
	var/atom/A = I.data.resolve()
	if(!A)
		activate_pin(3)
		return
	if(!(A in view(get_turf(src))))
		push_data()
		activate_pin(3)
		return // Can't see the target.

	if(get_pin_data(IC_INPUT, 2))
		set_pin_data(IC_OUTPUT, 1, get_dir(get_turf(src), get_turf(A)))
	else
		set_pin_data(IC_OUTPUT, 1, get_dir(get_turf(src), get_step_towards2(get_turf(src),A)))
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/smart/coord_basic_pathfinder
	name = "coordinate pathfinder"
	desc = "Эта сложная схема способна определять, в каком направлении находится данная цель"
	extended_desc = "Эта схема использует абсолютные координаты для определения местоположения цели. Если машина \
	не видит цель, она не сможет рассчитать правильное направление. \
	Эта схема будет работать только внутри сборки."
	icon_state = "numberpad"
	complexity = 5
	inputs = list("X" = IC_PINTYPE_NUMBER,"Y" = IC_PINTYPE_NUMBER,"игнорировать преграды?" = IC_PINTYPE_BOOLEAN)
	outputs = list(	"направление" 					= IC_PINTYPE_DIR,
					"дистанция"				= IC_PINTYPE_NUMBER
	)
	activators = list("рассчитать направление" = IC_PINTYPE_PULSE_IN, "при расчёте" = IC_PINTYPE_PULSE_OUT,"если рассчитать не удалось" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 40

/obj/item/integrated_circuit/smart/coord_basic_pathfinder/do_work()
	if(!assembly)
		activate_pin(3)
		return
	var/turf/T = get_turf(assembly)
	var/target_x = clamp(get_pin_data(IC_INPUT, 1), 0, world.maxx)
	var/target_y = clamp(get_pin_data(IC_INPUT, 2), 0, world.maxy)
	var/turf/A = locate(target_x, target_y, T.z)
	set_pin_data(IC_OUTPUT, 1, null)
	if(!A||A==T)
		activate_pin(3)
		return
	if(get_pin_data(IC_INPUT, 2))
		set_pin_data(IC_OUTPUT, 1, get_dir(get_turf(src), get_turf(A)))
	else
		set_pin_data(IC_OUTPUT, 1, get_dir(get_turf(src), get_step_towards2(get_turf(src),A)))
	set_pin_data(IC_OUTPUT, 2, sqrt((A.x-T.x)*(A.x-T.x)+ (A.y-T.y)*(A.y-T.y)))
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/smart/advanced_pathfinder
	name = "advanced pathfinder"
	desc = "Эта схема использует сложный процессор для поиска пути на большие расстояния."
	extended_desc = "Эта схема использует абсолютные координаты для поиска цели. Будет сгенерирован маршрут к цели с учетом препятствий \
	и обхода всех входных данных. Ключ доступа, полученный с помощью считывателя карт, используется для расчета правильного пути через воздушные шлюзы."
	icon_state = "numberpad"
	complexity = 40
	cooldown_per_use = 50
	inputs = list("X цели" = IC_PINTYPE_NUMBER,"Y цели" = IC_PINTYPE_NUMBER,"преграда" = IC_PINTYPE_REF,"доступ" = IC_PINTYPE_STRING)
	outputs = list("X" = IC_PINTYPE_LIST,"Y" = IC_PINTYPE_LIST)
	activators = list("рассчитать путь" = IC_PINTYPE_PULSE_IN, "при расчёте" = IC_PINTYPE_PULSE_OUT,"если рассчитать не удалось" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 80
	var/obj/item/card/id/idc

/obj/item/integrated_circuit/smart/advanced_pathfinder/Initialize(mapload)
	.=..()
	idc = new(src)

/obj/item/integrated_circuit/smart/advanced_pathfinder/Destroy()
	. = ..()
	idc = null

/obj/item/integrated_circuit/smart/advanced_pathfinder/do_work()
	if(!assembly)
		activate_pin(3)
		return
	idc.access = assembly.access_card.access
	var/turf/a_loc = get_turf(assembly)
	if(!a_loc)
		activate_pin(3)
		return
	var/turf/destination = locate(get_pin_data(IC_INPUT, 1), get_pin_data(IC_INPUT, 2), a_loc.z)
	if(!destination)
		activate_pin(3)
		return
	var/list/P = get_path_to(assembly, destination, 200, id=idc, exclude=get_turf(get_pin_data_as_type(IC_INPUT,3, /atom)), simulated_only = 0)

	if(!P)
		activate_pin(3)
		return
	else
		var/list/Xn =  new/list(P.len)
		var/list/Yn =  new/list(P.len)
		var/turf/T
		for(var/i =1 to P.len)
			T=P[i]
			Xn[i] = T.x
			Yn[i] = T.y
		set_pin_data(IC_OUTPUT, 1, Xn)
		set_pin_data(IC_OUTPUT, 2, Yn)
		push_data()
		activate_pin(2)


//Hippie Ported Code--------------------------------------------------------------------------------------------------------



// - MMI Tank - //
/obj/item/integrated_circuit/input/mmi_tank
	name = "man-machine interface tank"
	desc = "Эта схема представляет собой всего лишь банку, наполненную искусственной жидкостью, имитирующую спинномозговую жидкость."
	extended_desc = "Этот контейнер может содержать 1 человеко-машинный интерфейс и позволяет ему управлять некоторыми основными функциями сборки."
	complexity = 60
	inputs = list("laws" = IC_PINTYPE_LIST)
	outputs = list(
		"man-machine interface" = IC_PINTYPE_REF,
		"направление" = IC_PINTYPE_DIR,
		"цель нажатия" = IC_PINTYPE_REF
		)
	activators = list(
		"движение" = IC_PINTYPE_PULSE_OUT,
		"лево" = IC_PINTYPE_PULSE_OUT,
		"право" = IC_PINTYPE_PULSE_OUT,
		"верх" = IC_PINTYPE_PULSE_OUT,
		"низ" = IC_PINTYPE_PULSE_OUT,
		"левый клик" = IC_PINTYPE_PULSE_OUT,
		"шифт клик" = IC_PINTYPE_PULSE_OUT,
		"альт клик" = IC_PINTYPE_PULSE_OUT,
		"контрл клик" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 150
	can_be_asked_input = TRUE
	demands_object_input = TRUE

	var/obj/item/mmi/installed_brain

/obj/item/integrated_circuit/input/mmi_tank/attackby(obj/item/mmi/O, mob/user)
	if(!istype(O, /obj/item/mmi))
		to_chat(user, span_warning("Вы не можете засунуть это внутрь."))
		return
	if(installed_brain)
		to_chat(user, span_warning("Внутри уже есть мозг."))
		return
	user.transferItemToLoc(O, src)
	installed_brain = O
	can_be_asked_input = FALSE
	to_chat(user, span_notice("Вы аккуратно помещаете человеко-машинный интерфейс внутрь резервуара."))
	to_chat(O, span_notice("Вас медленно помещают в резервуар для взаимодействия человека и машины."))
	O.brainmob.remote_control = src
	set_pin_data(IC_OUTPUT, 1, O)
	push_data()

/obj/item/integrated_circuit/input/mmi_tank/attack_self(mob/user)
	if(installed_brain)
		RemoveBrain()
		to_chat(user, span_notice("Вы медленно поднимаете [installed_brain] из резервуара для MMI."))
		playsound(src, 'sound/items/Crowbar.ogg', 50, 1)
	else
		to_chat(user, span_notice("Вы не видите мозга, плавающего в резервуаре."))

/obj/item/integrated_circuit/input/mmi_tank/Destroy()
	RemoveBrain()
	return ..()

/obj/item/integrated_circuit/input/mmi_tank/relaymove(n, dir)
	set_pin_data(IC_OUTPUT, 2, dir)
	do_work(1)
	switch(dir)
		if(WEST)
			activate_pin(2)
		if(EAST)
			activate_pin(3)
		if(NORTH)
			activate_pin(4)
		if(SOUTH)
			activate_pin(5)

/obj/item/integrated_circuit/input/mmi_tank/do_work(n)
	push_data()
	activate_pin(n)

/obj/item/integrated_circuit/input/mmi_tank/proc/RemoveBrain()
	if(installed_brain)
		can_be_asked_input = TRUE
		installed_brain.forceMove(drop_location())
		set_pin_data(IC_OUTPUT, 1, WEAKREF(null))
		push_data()
		if(installed_brain.brainmob)
			installed_brain.brainmob.remote_control = null
		installed_brain = null

//Brain changes
/mob/living/brain/var/check_bot_self = FALSE

/mob/living/brain/ClickOn(atom/A, params)
	..()
	if(!istype(remote_control,/obj/item/integrated_circuit/input/mmi_tank))
		return
	var/obj/item/integrated_circuit/input/mmi_tank/brainholder=remote_control
	brainholder.set_pin_data(IC_OUTPUT, 3, A)
	var/list/modifiers = params2list(params)

	if(modifiers["shift"])
		brainholder.do_work(7)
		return
	if(modifiers["alt"])
		brainholder.do_work(8)
		return
	if(modifiers["ctrl"])
		brainholder.do_work(9)
		return

	if(istype(A,/obj/item/electronic_assembly))
		var/obj/item/electronic_assembly/CheckedAssembly = A

		if(brainholder in CheckedAssembly.assembly_components)
			var/obj/item/electronic_assembly/holdingassembly=A
			check_bot_self=TRUE

			if(holdingassembly.opened)
				holdingassembly.ui_interact(src)
			holdingassembly.attack_self(src)
			check_bot_self=FALSE
			return

	brainholder.do_work(6)

/mob/living/brain/canUseTopic(atom/movable/M, be_close=FALSE, no_dextery=FALSE, no_tk=FALSE, check_resting=FALSE, silent = FALSE)
	return	check_bot_self

/obj/item/integrated_circuit/smart/advanced_pathfinder/proc/hippie_xor_decrypt()
	var/Ps = get_pin_data(IC_INPUT, 4)
	if(!Ps)
		return
	var/list/Pl = json_decode(XorEncrypt(hextostr(Ps, TRUE), SScircuit.cipherkey))
	if(Pl&&islist(Pl))
		idc.access = Pl

// - pAI connector circuit - //
/obj/item/integrated_circuit/input/pAI_connector
	name = "pAI connector circuit"
	desc = "Эта схема позволяет вам подключить персональный искусственный интеллект и дать ему некоторую форму контроля над ботом."
	extended_desc = "You can wire various functions to it."
	complexity = 60
	inputs = list("laws" = IC_PINTYPE_LIST)
	outputs = list(
		"персональный искусственный интеллект" = IC_PINTYPE_REF,
		"направление" = IC_PINTYPE_DIR,
		"цель клика" = IC_PINTYPE_REF
		)
	activators = list(
		"движение" = IC_PINTYPE_PULSE_OUT,
		"лево" = IC_PINTYPE_PULSE_OUT,
		"право" = IC_PINTYPE_PULSE_OUT,
		"верх" = IC_PINTYPE_PULSE_OUT,
		"низ" = IC_PINTYPE_PULSE_OUT,
		"левый клик" = IC_PINTYPE_PULSE_OUT,
		"шифт клик" = IC_PINTYPE_PULSE_OUT,
		"альт клик" = IC_PINTYPE_PULSE_OUT,
		"контрл клик" = IC_PINTYPE_PULSE_OUT,
		"шифтконтрл клик" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 150
	can_be_asked_input = TRUE
	demands_object_input = TRUE

	var/obj/item/paicard/installed_pai

/obj/item/integrated_circuit/input/pAI_connector/attackby(obj/item/paicard/O, mob/user)
	if(!istype(O, /obj/item/paicard))
		to_chat(user, span_warning("Вы не можете засунуть это внутрь."))
		return
	if(installed_pai)
		to_chat(user, span_warning("пИИ уже установлен."))
		return
	user.transferItemToLoc(O, src)
	installed_pai = O
	can_be_asked_input = FALSE
	to_chat(user, span_notice("Вы медленно подключаете пины платы к [installed_pai]."))
	to_chat(O, span_notice("Вас медленно подключают к коннектору пИИ"))
	O.pai.remote_control = src
	set_pin_data(IC_OUTPUT, 1, O)
	push_data()

/obj/item/integrated_circuit/input/pAI_connector/attack_self(mob/user)
	if(installed_pai)
		RemovepAI()
		to_chat(user, span_notice("Вы медленно отключаете пины платы от [installed_pai]."))
		playsound(src, 'sound/items/Crowbar.ogg', 50, 1)
	else
		to_chat(user, span_notice("Порт подключения пуст."))

/obj/item/integrated_circuit/input/pAI_connector/Destroy()
	RemovepAI()
	return ..()

/obj/item/integrated_circuit/input/pAI_connector/relaymove(n, dir)
	set_pin_data(IC_OUTPUT, 2, dir)
	do_work(1)
	switch(dir)
		if(WEST)
			activate_pin(2)
		if(EAST)
			activate_pin(3)
		if(NORTH)
			activate_pin(4)
		if(SOUTH)
			activate_pin(5)

/obj/item/integrated_circuit/input/pAI_connector/do_work(n)
	push_data()
	activate_pin(n)

/obj/item/integrated_circuit/input/pAI_connector/proc/RemovepAI()
	if(installed_pai)
		can_be_asked_input = TRUE
		installed_pai.forceMove(drop_location())
		set_pin_data(IC_OUTPUT, 1, WEAKREF(null))
		push_data()
		if(installed_pai.pai)
			installed_pai.pai.remote_control = null
		installed_pai = null

//pAI changes
/mob/living/silicon/pai/var/check_bot_self = FALSE

/mob/living/silicon/pai/ClickOn(atom/A, params)
	..()
	if(!istype(remote_control,/obj/item/integrated_circuit/input/pAI_connector))
		return
	var/obj/item/integrated_circuit/input/pAI_connector/paiholder=remote_control
	paiholder.set_pin_data(IC_OUTPUT, 3, A)
	var/list/modifiers = params2list(params)

	if(modifiers["shift"] && modifiers["ctrl"])
		paiholder.do_work(10)
		return
	if(modifiers["shift"])
		paiholder.do_work(7)
		return
	if(modifiers["alt"])
		paiholder.do_work(8)
		return
	if(modifiers["ctrl"])
		paiholder.do_work(9)
		return

	if(istype(A,/obj/item/electronic_assembly))
		var/obj/item/electronic_assembly/CheckedAssembly = A

		if(paiholder in CheckedAssembly.assembly_components)
			var/obj/item/electronic_assembly/holdingassembly=A
			check_bot_self=TRUE

			if(holdingassembly.opened)
				holdingassembly.ui_interact(src)
			holdingassembly.attack_self(src)
			check_bot_self=FALSE
			return

	paiholder.do_work(6)

/mob/living/silicon/pai/canUseTopic(atom/movable/M, be_close=FALSE, no_dextery=FALSE, no_tk=FALSE, check_resting=FALSE, silent = FALSE)
	return	check_bot_self
