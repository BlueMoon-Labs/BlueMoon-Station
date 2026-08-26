// /obj/item/mod/module/armor
// 	name = "Base MOD armor"
// 	icon_state = "base_armor"
// 	desc = "Незавершенная плитка дополнительной брони, защищающая владельца от указанного на этикетке типа повреждений. Стоит понимать, что \
// 	каждая такая плитка имеет вес и, следовательно, повышает энергопотребление из-за нагрузки на сервоприводы."
// 	module_type = MODULE_ARMOR
// 	var/datum/armor/additional_armor
// 	var/armor_type //MELEE, BULLET, LASER
// 	var/need_sheets = 10
// 	var/slowdown_bonus = 0.25
// 	idle_power_cost = DEFAULT_CHARGE_DRAIN
// 	var/list/material_to_armor_list = list(
// 		new /obj/item/stack/sheet/durathread 			= new /datum/armor(melee = 15, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0),
// 		new /obj/item/stack/sheet/plasteel 				= new /datum/armor(melee = 0, bullet = 15, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0),
// 		new /obj/item/stack/sheet/mineral/titanium 		= new /datum/armor(melee = 0, bullet = 0, laser = 15, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0),
// 		new /obj/item/stack/sheet/mineral/diamond		= new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 15, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0),
// 		new /obj/item/stack/sheet/mineral/gold			= new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 15, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0),
// 		new /obj/item/stack/sheet/mineral/silver		= new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 15, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0),
// 		new /obj/item/stack/sheet/mineral/plastitanium 	= new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 15, fire = 0, acid = 0, magic = 0, wound = 0),
// 		new /obj/item/stack/sheet/plastitaniumglass		= new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 15, acid = 0, magic = 0, wound = 0),
// 		new /obj/item/stack/sheet/rglass				= new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 15, magic = 0, wound = 0),
// 		new /obj/item/stack/sheet/mineral/adamantine	= new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 15, wound = 0),
// 		new /obj/item/stack/sheet/mineral/abductor		= new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 15),
// 	)
// 	complexity = 2

// /obj/item/mod/module/armor/examine_more(mob/user)
// 	. = ..()
// 	if(armor_type)
// 		return
// 	. += span_boldnotice("Сейчас доступны варианты:")
// 	for(var/obj/item/stack/sheet/material in material_to_armor_list)
// 		. += (span_alert("Материал --[(material.name)]-- позволяет сделать защиту от:") + span_revenminor("[material_to_armor_list[material]]"))

// /obj/item/mod/module/armor/proc/get_active_armor_types(datum/armor/additional_armor)
// 	var/list/active = list()

// 	for (var/armor_type in ARMOR_LIST_ALL())
// 		var/value = additional_armor.vars[armor_type]

// 		if (isnum(value) && value > 0)
// 			active += armor_type

// 	return active

// /obj/item/mod/module/armor/proc/add_armor_bonus()
// 	for(var/index in mod.mod_parts)
// 		if(index == MOD_PART_CELL)
// 			continue
// 		var/obj/item/clothing/mod_part/part = mod.mod_parts[index]
// 		part.armor.modifyRating(additional_armor)
// 	mod.slowdown_active += slowdown_bonus	//в модулях опасно обращаться напрямую к wearer, потому что его может не быть
// 	mod.slowdown_inactive += slowdown_bonus //лучше просто моду самому поменять слоудаун.

// /obj/item/mod/module/armor/proc/remove_armor_bonus()
// 	for(var/index in mod.mod_parts)
// 		if(index == MOD_PART_CELL)
// 			continue
// 		var/obj/item/clothing/mod_part/part = mod.mod_parts[index]
// 		part.armor.detachArmor(additional_armor)
// 	mod.slowdown_active -= slowdown_bonus
// 	mod.slowdown_inactive -= slowdown_bonus

// /obj/item/mod/module/armor/proc/get_armor_by_material(obj/item/stack/sheet/material)
// 	if (!(material.type in material_to_armor_list))
// 		return null
// 	return material_to_armor_list[material.type]

// /obj/item/mod/module/armor/on_install()
// 	. = ..()
// 	if(!armor_type)
// 		return
// 	mod.current_armor_module_installed += 1
// 	add_armor_bonus()

// /obj/item/mod/module/armor/on_uninstall()
// 	. = ..()
// 	if(!armor_type)
// 		return
// 	mod.current_armor_module_installed -= 1
// 	remove_armor_bonus()

// /obj/item/mod/module/armor/attackby(obj/item/I, mob/living/user, params)
// //Чекает в списке какую броню ставить, если это материал и меняет icon_state с названием
// 	. = ..()
// 	if(armor_type)
// 		return
// 	var/mob/living/carbon/C = user
// 	if(!istype(I, /obj/item/stack/sheet))
// 		return
// 	var/obj/item/stack/sheet/material = I
// 	additional_armor = get_armor_by_material(material)
// 	armor_type = get_active_armor_types(additional_armor)
// 	if(material.amount < need_sheets || !armor_type)
// 		var/ballon_message = armor_type ? "Нужно 10 листов" : "Не подходящий материал!"
// 		C.balloon_alert(C, ballon_message)
// 		armor_type = null
// 		return
// 	if(do_after(user, 2 SECONDS, src))
// 		name = "[armor_type] MOD armor"
// 		icon_state = "armor-[armor_type]"
// 		desc = "Завершенный модуль брони для МОДа, который защищает от повреждений типа [armor_type]"
// 		material.use(need_sheets)
// 	else
// 		armor_type = null

// /obj/item/mod/module/armor/prebuild
// 	name = "Base prebuild"

// /obj/item/mod/module/armor/prebuild/Initialize(mapload)
// 	. = ..()
// 	name = "[armor_type] MOD armor"
// 	icon_state = "armor-[armor_type]"

// /obj/item/mod/module/armor/prebuild/melee
// 	armor_type = MELEE
// 	additional_armor = new /datum/armor(melee = 15, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0)

// /obj/item/mod/module/armor/prebuild/bullet
// 	armor_type = BULLET
// 	additional_armor = new /datum/armor(melee = 0, bullet = 15, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0)

// /obj/item/mod/module/armor/prebuild/laser
// 	armor_type = LASER
// 	additional_armor = new /datum/armor(melee = 0, bullet = 0, laser = 15, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0)

// /obj/item/mod/module/armor/prebuild/energy
// 	armor_type = ENERGY
// 	additional_armor = new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 15, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0)

// /obj/item/mod/module/armor/prebuild/bomb
// 	armor_type = BOMB
// 	additional_armor = new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 15, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0)

// /obj/item/mod/module/armor/prebuild/bio
// 	armor_type = BIO
// 	additional_armor = new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 15, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0)

// /obj/item/mod/module/armor/prebuild/rad
// 	armor_type = RAD
// 	additional_armor = new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 15, fire = 0, acid = 0, magic = 0, wound = 0)

// /obj/item/mod/module/armor/prebuild/fire
// 	armor_type = FIRE
// 	additional_armor = new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 15, acid = 0, magic = 0, wound = 0)

// /obj/item/mod/module/armor/prebuild/acid
// 	armor_type = ACID
// 	additional_armor = new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 15, magic = 0, wound = 0)

// /obj/item/mod/module/armor/prebuild/magic
// 	armor_type = MAGIC
// 	additional_armor = new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 15, wound = 0)

// /obj/item/mod/module/armor/prebuild/wound
// 	armor_type = WOUND
// 	additional_armor = new /datum/armor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 15)
