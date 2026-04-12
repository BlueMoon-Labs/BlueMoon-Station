/obj/item/integrated_circuit/manipulation
	category_text = "Манипуляция"

/obj/item/integrated_circuit/manipulation/locomotion
	name = "locomotion circuit"
	desc = "Это позволяет машине двигаться в заданном направлении."
	icon_state = "locomotion"
	extended_desc = "Схема принимает число направления в качестве направления движения.<br>\
    Импульс на пине активатора 'шаг в сторону направления' заставит машину сделать один шаг в этом направлении, при условии, что она не \
    удерживается или не закреплена каким-либо образом. Следует отметить, что способность к перемещению зависит от типа корпуса, в котором находится данная схема; перемещаться могут только корпуса-дроны."
	w_class = WEIGHT_CLASS_SMALL
	complexity = 10
	cooldown_per_use = 1
	ext_cooldown = 4
	inputs = list("направление" = IC_PINTYPE_DIR)
	outputs = list("препятствие" = IC_PINTYPE_REF)
	activators = list("шаг в сторону направления" = IC_PINTYPE_PULSE_IN,"при шаге"=IC_PINTYPE_PULSE_OUT,"при преграде"=IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_MOVEMENT
	power_draw_per_use = 100

/obj/item/integrated_circuit/manipulation/locomotion/do_work()
	..()
	var/turf/T = get_turf(src)
	if(T && assembly)
		if(assembly.anchored || !assembly.can_move())
			return
		if(assembly.loc == T) // Check if we're held by someone.  If the loc is the floor, we're not held.
			var/datum/integrated_io/wanted_dir = inputs[1]
			if(isnum(wanted_dir.data))
				if(step(assembly, wanted_dir.data))
					activate_pin(2)
					return
				else
					set_pin_data(IC_OUTPUT, 1, WEAKREF(assembly.collw))
					push_data()
					activate_pin(3)
					return FALSE
	return FALSE

/obj/item/integrated_circuit/manipulation/plant_module
	name = "plant manipulation module"
	desc = "Используется для удаления сорняков, а также для уборки урожая и высадки рассады."
	icon_state = "plant_m"
	extended_desc = "Схема принимает ссылку на гидропонный лоток или объект на соседней клетке. \
    Ввод режима (0 - сбор урожая, 1 - вырывание сорняков, 2 - вырывание растения, 3 - посадка семян) определяет действие. \
    При сборе урожая выводится список собранных растений."
	w_class = WEIGHT_CLASS_TINY
	complexity = 10
	inputs = list("лоток" = IC_PINTYPE_REF,"режим" = IC_PINTYPE_NUMBER,"объект" = IC_PINTYPE_REF)
	outputs = list("результат" = IC_PINTYPE_LIST)
	activators = list("входящий импульс" = IC_PINTYPE_PULSE_IN,"исходящий импульс" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 50

/obj/item/integrated_circuit/manipulation/plant_module/do_work()
	..()
	var/obj/acting_object = get_object()
	var/obj/OM = get_pin_data_as_type(IC_INPUT, 1, /obj)
	var/obj/O = get_pin_data_as_type(IC_INPUT, 3, /obj/item)

	if(!check_target(OM))
		push_data()
		activate_pin(2)
		return

	if(istype(OM,/obj/structure/spacevine) && check_target(OM) && get_pin_data(IC_INPUT, 2) == 2)
		qdel(OM)
		push_data()
		activate_pin(2)
		return

	var/obj/machinery/hydroponics/TR = OM
	if(istype(TR))
		switch(get_pin_data(IC_INPUT, 2))
			if(0)
				var/list/harvest_output = harvest(TR)
				for(var/i in 1 to length(harvest_output))
					harvest_output[i] = WEAKREF(harvest_output[i])

				if(length(harvest_output))
					set_pin_data(IC_OUTPUT, 1, harvest_output)
					push_data()
			if(1)
				TR.weedlevel = 0
				TR.update_icon()
			if(2)
				if(TR.myseed) //Could be that they're just using it as a de-weeder
					TR.age = 0
					TR.plant_health = 0
					if(TR.harvest)
						TR.harvest = FALSE //To make sure they can't just put in another seed and insta-harvest it
					qdel(TR.myseed)
					TR.myseed = null
				TR.weedlevel = 0 //Has a side effect of cleaning up those nasty weeds
				TR.dead = 0
				TR.update_icon()
			if(3)
				if(!check_target(O))
					activate_pin(2)
					return FALSE

				else if(istype(O, /obj/item/seeds) && !istype(O, /obj/item/seeds/sample))
					if(!TR.myseed)
						if(istype(O, /obj/item/seeds/kudzu))
							investigate_log("had Kudzu planted in it by [acting_object] at [AREACOORD(src)]","kudzu")
						acting_object.visible_message("<span class='notice'>[acting_object] сажает [O].</span>")
						TR.dead = 0
						TR.myseed = O
						TR.age = 1
						TR.plant_health = TR.myseed.endurance
						TR.lastcycle = world.time
						O.forceMove(TR)
						TR.update_icon()
	activate_pin(2)

/obj/item/integrated_circuit/manipulation/plant_module/proc/harvest(obj/machinery/hydroponics/TR)
	if(TR.dead)
		TR.harvest_dead()
		return list()
	else
		return TR.myseed?.harvest_userless()

/obj/item/integrated_circuit/manipulation/seed_extractor
	name = "seed extractor module"
	desc = "Используется для извлечения семян из созревших плодов."
	icon_state = "plant_m"
	extended_desc = "Эта схема принимает ссылку на элемент растения, извлекает из него семена и выводит результаты в список."
	complexity = 8
	inputs = list("цель" = IC_PINTYPE_REF)
	outputs = list("результат" = IC_PINTYPE_LIST)
	activators = list("входящий импульс" = IC_PINTYPE_PULSE_IN,"исходящий импульс" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 50

/obj/item/integrated_circuit/manipulation/seed_extractor/do_work()
	..()
	var/obj/O = get_pin_data_as_type(IC_INPUT, 1, /obj/item)
	if(!check_target(O))
		push_data()
		activate_pin(2)
		return

	var/list/seed_output = seedify(O, -1)
	for(var/i in 1 to length(seed_output))
		seed_output[i] = WEAKREF(seed_output[i])

	if(seed_output.len)
		set_pin_data(IC_OUTPUT, 1, seed_output)
		push_data()
	activate_pin(2)

/obj/item/integrated_circuit/manipulation/grabber
	name = "grabber"
	desc = "Схема с собственным хранилищем предметов. Используется для захвата и хранения предметов."
	icon_state = "grabber"
	extended_desc = "Эта схема принимает ссылку на объект, который необходимо захватить, и может хранить до 10 объектов. Режимы: 1 - захват, 0 - выброс первого объекта, -1 - выброс всех объектов и -2 - выброс целевого объекта. Если вы бросите что-либо из инвентаря захватчика с помощью метателя, захватчик соответствующим образом обновит свои выходы."
	w_class = WEIGHT_CLASS_SMALL
	size = 3
	cooldown_per_use = 5
	complexity = 10
	inputs = list("цель" = IC_PINTYPE_REF,"режим" = IC_PINTYPE_NUMBER)
	outputs = list("первый предмет" = IC_PINTYPE_REF, "последний предмет" = IC_PINTYPE_REF, "количество предметов" = IC_PINTYPE_NUMBER,"содержимое" = IC_PINTYPE_LIST)
	activators = list("входящий импульс" = IC_PINTYPE_PULSE_IN,"исходящий импульс" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_COMBAT
	power_draw_per_use = 50
	var/max_items = 10

/obj/item/integrated_circuit/manipulation/grabber/do_work()
	var/obj/item/AM = get_pin_data_as_type(IC_INPUT, 1, /obj/item)
	if(!QDELETED(AM) && !istype(AM, /obj/item/electronic_assembly) && !istype(AM, /obj/item/transfer_valve) && !istype(assembly.loc, /obj/item/implant/storage) && !AM.GetComponent(/datum/component/two_handed))
		var/mode = get_pin_data(IC_INPUT, 2)
		switch(mode)
			if(1)
				grab(AM)
			if(0)
				if(contents.len)
					drop(contents[1])
			if(-1)
				drop_all()
			if(-2)
				drop(AM)
	update_outputs()
	activate_pin(2)

/obj/item/integrated_circuit/manipulation/grabber/proc/grab(obj/item/AM)
	var/max_w_class = assembly.w_class
	if(check_target(AM))
		if(contents.len < max_items && AM.w_class <= max_w_class)
			var/atom/A = get_object()
			A.investigate_log("picked up ([AM]) with [src].", INVESTIGATE_CIRCUIT)
			AM.forceMove(src)

/obj/item/integrated_circuit/manipulation/grabber/proc/drop(obj/item/AM, turf/T = drop_location())
	if(!check_target(AM, FALSE, TRUE, TRUE, TRUE))
		return
	var/atom/A = get_object()
	A.investigate_log("dropped ([AM]) from [src].", INVESTIGATE_CIRCUIT)
	AM.forceMove(T)

/obj/item/integrated_circuit/manipulation/grabber/proc/drop_all()
	if(contents.len)
		var/turf/T = drop_location()
		var/obj/item/U
		for(U in src)
			drop(U, T)

/obj/item/integrated_circuit/manipulation/grabber/proc/update_outputs()
	if(contents.len)
		set_pin_data(IC_OUTPUT, 1, WEAKREF(contents[1]))
		set_pin_data(IC_OUTPUT, 2, WEAKREF(contents[contents.len]))
	else
		set_pin_data(IC_OUTPUT, 1, null)
		set_pin_data(IC_OUTPUT, 2, null)
	set_pin_data(IC_OUTPUT, 3, contents.len)
	set_pin_data(IC_OUTPUT, 4, contents)
	push_data()

/obj/item/integrated_circuit/manipulation/grabber/attack_self(var/mob/user)
	drop_all()
	update_outputs()
	push_data()

/obj/item/integrated_circuit/manipulation/claw
	name = "pulling claw"
	desc = "Схема, способная тянуть предметы."
	icon_state = "pull_claw"
	extended_desc = "Эта схема принимает ссылку на объект, который необходимо перетащить. Режимы: 0 - отпустить, 1 - перетащить."
	w_class = WEIGHT_CLASS_SMALL
	size = 3
	cooldown_per_use = 5
	complexity = 10
	inputs = list("цель" = IC_PINTYPE_REF,"режим" = IC_PINTYPE_INDEX,"направление" = IC_PINTYPE_DIR)
	outputs = list("тянет?" = IC_PINTYPE_BOOLEAN)
	activators = list("входящий импульс" = IC_PINTYPE_PULSE_IN,"исходящий импульс" = IC_PINTYPE_PULSE_OUT,"при отпускании" = IC_PINTYPE_PULSE_OUT,"тянуть по направлению" = IC_PINTYPE_PULSE_IN)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 50
	ext_cooldown = 1
	var/max_grab = GRAB_PASSIVE

/obj/item/integrated_circuit/manipulation/claw/do_work(ord)
	var/obj/acting_object = get_object()
	var/atom/movable/AM = get_pin_data_as_type(IC_INPUT, 1, /atom/movable)
	var/mode = get_pin_data(IC_INPUT, 2)
	switch(ord)
		if(1)
			mode = clamp(mode, GRAB_PASSIVE, max_grab)
			if(AM)
				if(check_target(AM, exclude_contents = TRUE))
					acting_object.investigate_log("grabbed ([AM]) using [src].", INVESTIGATE_CIRCUIT)
					acting_object.start_pulling(AM,mode)
					if(acting_object.pulling)
						set_pin_data(IC_OUTPUT, 1, TRUE)
					else
						set_pin_data(IC_OUTPUT, 1, FALSE)
			push_data()

		if(4)
			if(acting_object.pulling)
				var/dir = get_pin_data(IC_INPUT, 3)
				var/turf/G =get_step(get_turf(acting_object),dir)
				var/atom/movable/pullee = acting_object.pulling
				var/turf/Pl = get_turf(pullee)
				var/turf/F = get_step_towards(Pl,G)
				if(acting_object.Adjacent(F))
					if(!step_towards(pullee, F))
						F = get_step_towards2(Pl,G)
						if(acting_object.Adjacent(F))
							step_towards(pullee, F)
	activate_pin(2)

/obj/item/integrated_circuit/manipulation/claw/stop_pulling()
	set_pin_data(IC_OUTPUT, 1, FALSE)
	activate_pin(3)
	push_data()
	..()



/obj/item/integrated_circuit/manipulation/thrower
	name = "thrower"
	desc = "Компактная пусковая установка, позволяющая бросать предметы изнутри или с соседних клеток со скоростью, недостаточной для нанесения вреда."
	extended_desc = "Первый и второй входные параметры должны быть числами, соответствующими координатам, по которым необходимо бросить объекты относительно самой машины. \
    Активатор 'огонь' заставит механизм попытаться бросить объекты в указанные координаты, если это возможно. Обратите внимание, что \
    снаряд должен находиться внутри машины или на соседней клетке и быть среднего размера или меньше. Корпус \
    также должен быть оружием, если вы хотите бросить что-либо, когда корпус находится в руке."
	complexity = 25
	w_class = WEIGHT_CLASS_SMALL
	size = 2
	cooldown_per_use = 10
	ext_cooldown = 1
	inputs = list(
		"относительный X цели" = IC_PINTYPE_NUMBER,
		"относительный Y цели" = IC_PINTYPE_NUMBER,
		"снаряд" = IC_PINTYPE_REF
		)
	outputs = list()
	activators = list(
		"огонь" = IC_PINTYPE_PULSE_IN
	)
	spawn_flags = IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_COMBAT
	power_draw_per_use = 50

/obj/item/integrated_circuit/manipulation/thrower/do_work()
	var/max_w_class = assembly.w_class
	var/target_x_rel = round(get_pin_data(IC_INPUT, 1))
	var/target_y_rel = round(get_pin_data(IC_INPUT, 2))
	var/obj/item/A = get_pin_data_as_type(IC_INPUT, 3, /obj/item)

	if(!A || A.anchored || A.throwing || A == assembly || istype(A, /obj/item/transfer_valve) || A.GetComponent(/datum/component/two_handed))
		return

	if (istype(assembly.loc, /obj/item/implant/storage)) //Prevents the more abusive form of chestgun.
		return

	if(max_w_class && (A.w_class > max_w_class))
		return

	if(!assembly.can_fire_equipped && ishuman(assembly.loc))
		return

	// Is the target inside the assembly or close to it?
	if(!check_target(A, exclude_components = TRUE))
		return

	var/turf/T = get_turf(get_object())
	if(!T)
		return

	// If the item is in mob's inventory, try to remove it from there.
	if(ismob(A.loc))
		var/mob/living/M = A.loc
		if(!M.temporarilyRemoveItemFromInventory(A))
			return

	// If the item is in a grabber circuit we'll update the grabber's outputs after we've thrown it.
	var/obj/item/integrated_circuit/manipulation/grabber/G = A.loc

	var/x_abs = clamp(T.x + target_x_rel, 0, world.maxx)
	var/y_abs = clamp(T.y + target_y_rel, 0, world.maxy)
	var/range = round(clamp(sqrt(target_x_rel*target_x_rel+target_y_rel*target_y_rel),0,8),1)
	//remove damage
	A.throwforce = 0
	A.embedding = list("embed_chance" = 0)
	//throw it
	assembly.visible_message("<span class='danger'>[assembly] бросает [A]!</span>")
	log_attack("[assembly] [REF(assembly)] has thrown [A] with non-lethal force.")
	A.forceMove(drop_location())
	A.throw_at(locate(x_abs, y_abs, T.z), range, 3, null, null, null, CALLBACK(src, PROC_REF(post_throw), A))

	// If the item came from a grabber now we can update the outputs since we've thrown it.
	if(istype(G))
		G.update_outputs()

/obj/item/integrated_circuit/manipulation/thrower/proc/post_throw(obj/item/A)
	//return damage
	A.throwforce = initial(A.throwforce)
	A.embedding = initial(A.embedding)

/obj/item/integrated_circuit/manipulation/matman
	name = "material manager"
	desc = "Эта схема предназначена для автоматического складирования и распределения материалов."
	extended_desc = "Первый вход принимает ссылку на машину с контейнером для материала. \
					Второй вход используется для вставки стопок материалов во внутреннее хранилище материалов. \
                    Входы 3–13 используются для перемещения материалов между целевой машиной и хранилищем схемы. \
                    Положительные значения означают, что это количество материалов будет взято из другой машины. \
                    Отрицательные значения означают, что другая машина будет заполнена из внутреннего хранилища. Выходы показывают текущие запасы материалов."
	icon_state = "grabber"
	complexity = 16
	inputs = list(
		"цель" 				= IC_PINTYPE_REF,
		"количество листов для вставки"	 	= IC_PINTYPE_NUMBER,
		"Металл"				 	= IC_PINTYPE_NUMBER,
		"Стекло"					= IC_PINTYPE_NUMBER,
		"Серебро"				= IC_PINTYPE_NUMBER,
		"Золото"					= IC_PINTYPE_NUMBER,
		"Алмазы"				= IC_PINTYPE_NUMBER,
		"Уран"				= IC_PINTYPE_NUMBER,
		"Твёрдая плазма"			= IC_PINTYPE_NUMBER,
		"Блюспейс кристаллы"		= IC_PINTYPE_NUMBER,
		"Бананиум"				= IC_PINTYPE_NUMBER,
		"Титан"				= IC_PINTYPE_NUMBER,
		"Пластик"				= IC_PINTYPE_NUMBER
		)
	outputs = list(
		"Самоссылка" 				= IC_PINTYPE_REF,
		"Общее количество"		 	= IC_PINTYPE_NUMBER,
		"Металл"				 	= IC_PINTYPE_NUMBER,
		"Стекло"					= IC_PINTYPE_NUMBER,
		"Серебро"				= IC_PINTYPE_NUMBER,
		"Золото"					= IC_PINTYPE_NUMBER,
		"Алмазы"				= IC_PINTYPE_NUMBER,
		"Уран"				= IC_PINTYPE_NUMBER,
		"Твёрдая плазма"			= IC_PINTYPE_NUMBER,
		"Блюспейс кристаллы"		= IC_PINTYPE_NUMBER,
		"Бананиум"				= IC_PINTYPE_NUMBER,
		"Титан"				= IC_PINTYPE_NUMBER,
		"Пластик"				= IC_PINTYPE_NUMBER
		)
	activators = list(
		"вставить листы" = IC_PINTYPE_PULSE_IN,
		"переместить материалы" = IC_PINTYPE_PULSE_IN,
		"при успехе" = IC_PINTYPE_PULSE_OUT,
		"при неудаче" = IC_PINTYPE_PULSE_OUT,
		"выдать ссылку" = IC_PINTYPE_PULSE_IN,
		"при выдаче ссылки" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 40
	ext_cooldown = 1
	cooldown_per_use = 10
	var/static/list/mtypes = list(
		/datum/material/iron,
		/datum/material/glass,
		/datum/material/silver,
		/datum/material/gold,
		/datum/material/diamond,
		/datum/material/uranium,
		/datum/material/plasma,
		/datum/material/bluespace,
		/datum/material/bananium,
		/datum/material/titanium,
		/datum/material/plastic
		)

/obj/item/integrated_circuit/manipulation/matman/ComponentInitialize()
	var/datum/component/material_container/materials = AddComponent(/datum/component/material_container, mtypes, 100000, FALSE, /obj/item/stack, CALLBACK(src, PROC_REF(is_insertion_ready)), CALLBACK(src, PROC_REF(AfterMaterialInsert)))
	materials.precise_insertion = TRUE
	.=..()

/obj/item/integrated_circuit/manipulation/matman/proc/AfterMaterialInsert(type_inserted, id_inserted, amount_inserted)
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	set_pin_data(IC_OUTPUT, 2, materials.total_amount)
	for(var/I in 1 to mtypes.len)
		var/datum/material/M = materials.materials[SSmaterials.GetMaterialRef(I)]
		var/amount = materials.materials[M]
		if(M)
			set_pin_data(IC_OUTPUT, I+2, amount)
	push_data()

/obj/item/integrated_circuit/manipulation/matman/proc/is_insertion_ready(mob/user)
	return TRUE

/obj/item/integrated_circuit/manipulation/matman/do_work(ord)
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	var/atom/movable/H = get_pin_data_as_type(IC_INPUT, 1, /atom/movable)
	if(!check_target(H))
		activate_pin(4)
		return
	var/turf/T = get_turf(H)
	switch(ord)
		if(1)
			var/obj/item/stack/sheet/S = H
			if(!S)
				activate_pin(4)
				return
			if(materials.insert_item(S, clamp(get_pin_data(IC_INPUT, 2),0,100), multiplier = 1) )
				AfterMaterialInsert()
				activate_pin(3)
			else
				activate_pin(4)
		if(2)
			var/datum/component/material_container/mt = H.GetComponent(/datum/component/material_container)
			var/suc
			for(var/I in 1 to mtypes.len)
				var/datum/material/M = materials.materials[mtypes[I]]
				if(M)
					var/U = clamp(get_pin_data(IC_INPUT, I+2),-100000,100000)
					if(!U)
						continue
					if(!mt) //Invalid input
						if(U>0)
							if(materials.retrieve_sheets(U, SSmaterials.GetMaterialRef(mtypes[I]), T))
								suc = TRUE
					else
						if(mt.transer_amt_to(materials, U, mtypes[I]))
							suc = TRUE
			if(suc)
				AfterMaterialInsert()
				activate_pin(3)
			else
				activate_pin(4)
		if(5)
			set_pin_data(IC_OUTPUT, 1, WEAKREF(src))
			AfterMaterialInsert()
			activate_pin(6)

/obj/item/integrated_circuit/manipulation/matman/Destroy()
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	materials.retrieve_all()
	.=..()


//Hippie Ported Code--------------------------------------------------------------------------------------------------------

// - inserter circuit - //
/obj/item/integrated_circuit/manipulation/inserter
	name = "inserter"
	desc = "Простая схема, которая позволяет помещать предметы в хранилище, подобное рюкзаку, и извлекать их оттуда."
	icon_state = "grabber"
	extended_desc = "Эта схема принимает ссылку на объект, который будет вставлен или извлечен в зависимости от режима. Если для извлечения указано хранилище, извлеченный элемент будет помещен в новое хранилище. Режимы: 1 - вставка, 0 - извлечение."
	w_class = WEIGHT_CLASS_SMALL
	size = 3
	cooldown_per_use = 5
	complexity = 10
	inputs = list("целевой объект" = IC_PINTYPE_REF, "целевое хранилище" = IC_PINTYPE_REF,"режим" = IC_PINTYPE_NUMBER)
	activators = list("входящий импульс" = IC_PINTYPE_PULSE_IN,"исходящий импульс" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_COMBAT
	power_draw_per_use = 20

/obj/item/integrated_circuit/manipulation/inserter/do_work()
    var/obj/item/target_obj = get_pin_data_as_type(IC_INPUT, 1, /obj/item)
    if(!target_obj || QDELETED(target_obj))
        return

    var/mob/holder = loc
    if(istype(holder))
        if(!holder.Adjacent(target_obj))
            return
    else
        if(get_dist(get_turf(src), get_turf(target_obj)) > 1)
            return

    var/obj/item/storage/container = get_pin_data_as_type(IC_INPUT, 2, /obj/item)
    var/mode = get_pin_data(IC_INPUT, 3)

    switch(mode)
        if(TRUE) // Insert mode 1
            if(!container || !istype(container,/obj/item/storage))
                return

            var/datum/component/storage/STR = container.GetComponent(/datum/component/storage)
            if(!STR)
                return

            STR.attackby(src.loc, target_obj)

        if(FALSE) // Extract mode 0
            if(!container || !istype(container,/obj/item/storage))
                return

            var/datum/component/storage/STR = container.GetComponent(/datum/component/storage)
            if(target_obj in container.contents)
                if(STR)
                    STR.remove_from_storage(target_obj, get_turf(src))

// Renamer circuit. Renames the assembly it is in. Useful in cooperation with telecomms-based circuits.
/obj/item/integrated_circuit/manipulation/renamer
	name = "renamer"
	desc = "Небольшая схема, которая переименовывает корпус, в котором она находится. Полезна в сочетании со схемами, основанными на речевом управлении."
	icon_state = "internalbm"
	extended_desc = "Эта схема принимает строку в качестве входных данных и может генерировать импульс для перезаписи имени текущего корпуса указанной строкой. В случае успешного выполнения она подает импульс на выходной провод по умолчанию."
	inputs = list("имя" = IC_PINTYPE_STRING)
	outputs = list("текущее имя" = IC_PINTYPE_STRING)
	activators = list("переименовать" = IC_PINTYPE_PULSE_IN,"получить имя" = IC_PINTYPE_PULSE_IN,"исходящий импульс" = IC_PINTYPE_PULSE_OUT)
	power_draw_per_use = 1
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/manipulation/renamer/do_work(var/n)
	if(!assembly)
		return
	switch(n)
		if(1)
			var/new_name = get_pin_data(IC_INPUT, 1)
			if(new_name)
				assembly.name = new_name

		else
			set_pin_data(IC_OUTPUT, 1, assembly.name)
			push_data()

	activate_pin(3)



// - redescribing circuit - //
/obj/item/integrated_circuit/manipulation/redescribe
	name = "redescriber"
	desc = "Принимает любую строку в качестве входных данных и устанавливает её в качестве описания корпуса."
	extended_desc = "Строки могут быть любой длины."
	icon_state = "speaker"
	cooldown_per_use = 10
	complexity = 3
	inputs = list("текст" = IC_PINTYPE_STRING)
	outputs = list("описание" = IC_PINTYPE_STRING)
	activators = list("переописать" = IC_PINTYPE_PULSE_IN,"получить описание" = IC_PINTYPE_PULSE_IN,"исходящий импульс" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/manipulation/redescribe/do_work(var/n)
	if(!assembly)
		return

	switch(n)
		if(1)
			assembly.desc = get_pin_data(IC_INPUT, 1)

		else
			set_pin_data(IC_OUTPUT, 1, assembly.desc)
			push_data()

	activate_pin(3)

// - repainting circuit - //
/obj/item/integrated_circuit/manipulation/repaint
	name = "auto-repainter"
	desc = "В этой схеме установлено необычно много распылительных баллончиков."
	extended_desc = "Принимает значение в шестнадцатеричном формате и использует его для перекраски того корпуса, в котором оно находится."
	cooldown_per_use = 10
	complexity = 3
	inputs = list("цвет" = IC_PINTYPE_COLOR)
	outputs = list("текущий цвет" = IC_PINTYPE_COLOR)
	activators = list("перекрасить" = IC_PINTYPE_PULSE_IN,"получить цвет" = IC_PINTYPE_PULSE_IN,"исходящий импульс" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/manipulation/repaint/do_work(var/n)
	if(!assembly)
		return

	switch(n)
		if(1)
			assembly.detail_color = get_pin_data(IC_INPUT, 1)
			assembly.update_icon()

		else
			set_pin_data(IC_OUTPUT, 1, assembly.detail_color)
			push_data()

	activate_pin(3)



