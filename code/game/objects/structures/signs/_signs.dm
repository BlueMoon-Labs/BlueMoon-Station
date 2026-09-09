/obj/structure/sign
	icon = 'icons/obj/decals.dmi'
	anchored = TRUE
	opacity = 0
	density = FALSE
	plane = ABOVE_WALL_PLANE
	layer = SIGN_LAYER
	max_integrity = 100
	armor = list(MELEE = 50, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 50)
	var/buildable_sign = 1 //unwrenchable and modifiable
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
	///Как тип называется в списке выбора у ручки. Без него тип в список не попадёт даже с is_editable.
	var/sign_change_name
	///Можно ли выбрать этот тип ручкой. Флаг наследуется, поэтому подтип, которому список не нужен, гасит его сам.
	var/is_editable = FALSE

/obj/structure/sign/basic
	name = "blank sign"
	desc = "How can signs be real if our eyes aren't real?"
	icon_state = "backing"
	is_editable = TRUE
	sign_change_name = "Blank Sign"

/obj/item/sign
	name = "sign backing"
	desc = "A plastic sign backing, use a pen to change the decal. It can be placed on a wall."
	icon = 'icons/obj/decals.dmi'
	icon_state = "backing"
	item_state = "backing"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	custom_materials = list(/datum/material/plastic = 2000)
	armor = list(MELEE = 50, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 50)
	resistance_flags = FLAMMABLE
	max_integrity = 100
	///Тип структуры, которая появится на стене. По умолчанию выглядит так же, как сама подложка.
	var/sign_path = /obj/structure/sign/basic

/obj/item/sign/Initialize(mapload) //Signs not attached to walls are always rotated so they look like they're laying horizontal.
	. = ..()
	var/matrix/M = matrix()
	M.Turn(90)
	transform = M

/obj/structure/sign/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	. = ..()
	if(user.is_blind())
		return
	user.examinate(src)

/proc/populate_editable_sign_types()
	var/list/output = list()
	for(var/obj/structure/sign/potential_sign as anything in subtypesof(/obj/structure/sign))
		if(!initial(potential_sign.is_editable))
			continue
		// Ключ списка - имя, поэтому безымянный тип занял бы ключ null, а подтип
		// с унаследованным именем - запись родителя.
		var/change_name = initial(potential_sign.sign_change_name)
		if(!change_name)
			stack_trace("[potential_sign] is editable but has no sign_change_name")
			continue
		output[change_name] = potential_sign
	// sort_list() зовёт sortTim() без associative, а тот на ассоциативном списке роняет
	// значения: список типов превратился бы в список null. Раньше это не всплывало только
	// потому, что запись в нём была одна и до сортировки дело не доходило.
	return sortTim(output, GLOBAL_PROC_REF(cmp_text_asc), associative = TRUE) //Alphabetizes the results.

/obj/item/sign/proc/set_sign_type(obj/structure/sign/fake_type)
	name = initial(fake_type.name)
	if(fake_type != /obj/structure/sign/basic)
		desc = "[initial(fake_type.desc)] It can be placed on a wall."
	else
		desc = initial(desc)
	icon_state = initial(fake_type.icon_state)
	sign_path = fake_type

/obj/item/sign/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!iswallturf(target) || !proximity)
		return
	var/turf/target_turf = target
	var/turf/user_turf = get_turf(user)
	var/obj/structure/sign/placed_decal = new sign_path(user_turf) //We place the sign on the turf the user is standing, and pixel shift it to the target wall, as below.
	//This is to mimic how signs and other wall objects are usually placed by mappers, and so they're only visible from one side of a wall.
	placed_decal.set_custom_materials(custom_materials) //иначе снятый ключом деревянный знак возвращался на стену пластиковым
	var/wall_dir = get_dir(user_turf, target_turf)
	placed_decal.setDir(wall_dir) //направленным знакам (флаги, плакаты) иначе доставалось направление по умолчанию
	if(wall_dir & NORTH)
		placed_decal.pixel_y = 32
	else if(wall_dir & SOUTH)
		placed_decal.pixel_y = -32
	if(wall_dir & EAST)
		placed_decal.pixel_x = 32
	else if(wall_dir & WEST)
		placed_decal.pixel_x = -32
	user.visible_message(span_notice("[user] fastens [src] to [target_turf]."), \
		span_notice("You attach the sign to [target_turf]."))
	playsound(target_turf, 'sound/items/deconstruct.ogg', 50, TRUE)
	qdel(src)

/obj/item/sign/random/Initialize(mapload)
	. = ..()
	set_sign_type(GLOB.editable_sign_types[pick(GLOB.editable_sign_types)])

/obj/structure/sign/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(damage_amount)
				playsound(src.loc, 'sound/weapons/slash.ogg', 80, 1)
			else
				playsound(loc, 'sound/weapons/tap.ogg', 50, 1)
		if(BURN)
			playsound(loc, 'sound/items/welder.ogg', 80, 1)

/obj/structure/sign/attackby(obj/item/I, mob/user, params)
	if(!buildable_sign)
		return ..()

	if(I.tool_behaviour == TOOL_WRENCH)
		user.visible_message(span_notice("[user] starts removing [src]..."), span_notice("You start unfastening [src]."))
		I.play_tool_sound(src)
		if(!I.use_tool(src, user, 4 SECONDS))
			return
		playsound(src, 'sound/items/deconstruct.ogg', 50, 1)
		user.visible_message(span_notice("[user] unfastens [src]."), span_notice("You unfasten [src]."))
		var/obj/item/sign/backing = new(get_turf(user))
		backing.set_sign_type(type)
		backing.set_custom_materials(custom_materials) //чтобы рамки для картин и деревянные знаки не теряли материал
		qdel(src)
		return

	if(istype(I, /obj/item/pen))
		change_sign_type(user)
		return

	return ..()

/// Меняет тип знака на выбранный [user] из GLOB.editable_sign_types.
/obj/structure/sign/proc/change_sign_type(mob/user)
	set waitfor = FALSE

	if(!user?.client)
		return
	var/choice = tgui_input_list(user, "Выберите тип знака.", "Настройка знака", GLOB.editable_sign_types)
	if(isnull(choice) || QDELETED(src) || !Adjacent(user))
		return
	var/obj/structure/sign/sign_type = GLOB.editable_sign_types[choice]
	if(!sign_type || sign_type == type)
		return

	// Пиксельный сдвиг и направление обязаны переехать: иначе знак спрыгнет со стены на середину турфа.
	var/obj/structure/sign/new_sign = new sign_type(get_turf(src))
	new_sign.set_custom_materials(custom_materials)
	new_sign.pixel_x = pixel_x
	new_sign.pixel_y = pixel_y
	new_sign.setDir(dir)
	qdel(src)

/obj/structure/sign/nanotrasen
	name = "\improper Nanotrasen Logo"
	desc = "A sign with the Nanotrasen Logo on it. Glory to Nanotrasen!"
	icon_state = "nanotrasen"

/obj/structure/sign/logo
	name = "nanotrasen logo"
	desc = "The Nanotrasen corporate logo."
	icon_state = "nanotrasen_sign1"

/obj/structure/sign/xenobio_guide
	name = "\improper Slime Genealogy Sign"
	desc = "A sign depicting how the slime colors change with mutations, and the grey slime in the root."
	icon_state = "xenobio-guide"
