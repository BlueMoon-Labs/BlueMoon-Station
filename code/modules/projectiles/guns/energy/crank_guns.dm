/obj/item/gun/energy/laser/musket
	name = "laser musket"
	desc = "Самодельное лазерное оружие с рукояткой сбоку, которой можно зарядить его."
	icon_state = "musket"
	item_state = "musket"
	ammo_type = list(/obj/item/ammo_casing/energy/laser/musket)
	cell_type = /obj/item/stock_parts/cell/high
	slot_flags = ITEM_SLOT_BACK
	obj_flags = UNIQUE_RENAME
	weapon_weight = WEAPON_HEAVY
	shaded_charge = TRUE
	custom_materials = list(/datum/material/wood = SHEET_MATERIAL_AMOUNT * 8, /datum/material/iron = SHEET_MATERIAL_AMOUNT * 1.35, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 1.3, /datum/material/plastic = SMALL_MATERIAL_AMOUNT)
	light_color = COLOR_PURPLE

/obj/item/gun/energy/laser/musket/Initialize(mapload)
	. = ..()
	AddComponent( \
		/datum/component/crank_recharge, \
		charging_cell = get_cell(), \
		charge_amount = STANDARD_CELL_CHARGE * 0.5, \
		cooldown_time = 2 SECONDS, \
		charge_sound = 'sound/items/weapons/laser_crank.ogg', \
		charge_sound_cooldown_time = 1.8 SECONDS, \
		charge_move = IGNORE_USER_LOC_CHANGE, \
	)

/obj/item/gun/energy/laser/musket/prime
	name = "heroic laser musket"
	desc = "Хорошо сконструированное, заряжаемое вручную лазерное оружие. Его конденсаторы гудят от потенциала."
	icon_state = "musket_prime"
	item_state = "musket_prime"
	ammo_type = list(/obj/item/ammo_casing/energy/laser/musket/prime)
	shaded_charge = TRUE
	custom_materials = list(
		/datum/material/wood = SHEET_MATERIAL_AMOUNT * 8,
		/datum/material/silver = SHEET_MATERIAL_AMOUNT * 5,
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 1.55,
		/datum/material/glass = SHEET_MATERIAL_AMOUNT * 1.45,
		/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3,
	)

// Термальные пистолеты

/obj/item/gun/energy/laser/thermal /* общий родитель этих пушек, он просто стреляет тяжёлыми пулями, может кому-то понравится? */
	name = "thermal pistol"
	desc = "Модифицированный ручной пушкой с метаморфным запасом выведенных из эксплуатации военизированных нанитов. Плюётся сгустками злых роботов во врагов."
	icon_state = "infernopistol"
	item_state = null
	ammo_type = list(/obj/item/ammo_casing/energy/nanite)
	cell_type = /obj/item/stock_parts/cell/thermal
	shaded_charge = TRUE
	ammo_x_offset = 1
	obj_flags = UNIQUE_RENAME
	w_class = WEIGHT_CLASS_NORMAL
	dual_wield_spread = 5 //как задумано кодерами

/obj/item/gun/energy/laser/thermal/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/empprotection, EMP_PROTECT_SELF|EMP_PROTECT_CONTENTS)
	AddComponent( \
		/datum/component/crank_recharge, \
		charging_cell = get_cell(), \
		spin_to_win = TRUE, \
		charge_amount = 1250, \
		cooldown_time = 0.8 SECONDS, \
		charge_sound = 'sound/items/weapons/kinetic_reload.ogg', \
		charge_sound_cooldown_time = 0.8 SECONDS, \
	)

/obj/item/gun/energy/laser/thermal/inferno //магма-пушка
	name = "inferno nanite pistol"
	desc = "Модифицированный ручной пушкой с метаморфным запасом выведенных из эксплуатации военизированных нанитов. Плюётся сгустками расплавленных злых роботов во врагов. \
		Хотя сам по себе он и не манипулирует температурой, он вызывает бурное извержение у любого, кто сильно замёрз. Способен генерировать \
		боеприпасы при ручном вращении нанитного контейнера оружия."
	icon_state = "infernopistol"
	light_color = COLOR_RED
	ammo_type = list(/obj/item/ammo_casing/energy/nanite/inferno)

/obj/item/gun/energy/laser/thermal/cryo //ледяная пушка
	name = "cryo nanite pistol"
	desc = "Модифицированный ручной пушкой с метаморфным запасом выведенных из эксплуатации военизированных нанитов. Плюётся осколками замёрзших злых роботов во врагов. \
		Хотя сам по себе он и не манипулирует температурой, он вызывает внутренний взрыв у любого, кто сильно перегрелся. Способен генерировать \
		боеприпасы при ручном вращении нанитного контейнера оружия."
	icon_state = "cryopistol"
	item_state = null
	light_color = COLOR_BLUE
	ammo_type = list(/obj/item/ammo_casing/energy/nanite/cryo)

/obj/item/gun/energy/laser/thermal/inferno/emag_act(mob/user, obj/item/card/emag/emag_card)
	. = ..()
	if(obj_flags & EMAGGED)
		return FALSE
	balloon_alert(user, "Взлом прошёл успешно!")
	visible_message(span_warning("От [src] летят искры!"))
	playsound(src, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	do_sparks(2, TRUE, src)
	obj_flags |= EMAGGED
	ammo_type = list(/obj/item/ammo_casing/energy/nanite/inferno/emagged)
	update_ammo_types()
	recharge_newshot(TRUE)
	return TRUE

/obj/item/gun/energy/laser/thermal/cryo/emag_act(mob/user, obj/item/card/emag/emag_card)
	. = ..()
	if(obj_flags & EMAGGED)
		return FALSE
	balloon_alert(user, "Взлом прошёл успешно!")
	visible_message(span_warning("От [src] летят искры!"))
	playsound(src, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	do_sparks(2, TRUE, src)
	obj_flags |= EMAGGED
	ammo_type = list(/obj/item/ammo_casing/energy/nanite/cryo/emagged)
	update_ammo_types()
	recharge_newshot(TRUE)
	return TRUE
