#define MAGNETIC_TOMAHAWK_CHARGE_LENIENCY 0.3
#define MAGNETIC_TOMAHAWK_DEPLETION_RATE 0.006

// ============================================
// Базовое оружие из ваучеров
// ============================================


/obj/item/gun/energy/e_gun/mini/expeditor
	name = "expeditor's miniature energy gun"
	desc = "Modernized pistol-sized energy gun with a built-in flashlight and expanded cell. It has two settings: stun and kill."
	w_class = WEIGHT_CLASS_SMALL
	cell_type = /obj/item/stock_parts/cell{charge = 1200; maxcharge = 1200}
	pin = /obj/item/firing_pin/explorer

/obj/item/gun/ballistic/automatic/laser/vanguard
	name = "Vanguard miniature energy gun"
	desc = "Modernized version of standart miniature energy gun with a built-in flashlight and changebale cell, usable by Vanguard squadrons. Seemes like switch is stuck in kill mode"
	icon = 'modular_bluemoon/icons/obj/guns/energy.dmi'
	icon_state = "flashgun"
	item_state = "gun"
	mag_type = /obj/item/ammo_box/magazine/recharge/vanguard
	automatic_burst_overlay = FALSE
	w_class = WEIGHT_CLASS_SMALL
	weapon_weight = WEAPON_LIGHT
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC)
	actions_types = list()
	fire_sound = 'sound/weapons/lasgun.ogg'
	casing_ejector = FALSE
	pin = /obj/item/firing_pin/explorer
	gunlight_state = "mini-light"
	can_flashlight = 0 // Can't attach or detach the flashlight, and override it's icon update

/obj/item/gun/ballistic/automatic/laser/vanguard/Initialize(mapload)
	gun_light = new /obj/item/flashlight/seclite(src)
	return ..()


/obj/item/gun/ballistic/automatic/laser/vanguard/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"]"

/obj/item/ammo_box/magazine/recharge/vanguard
	name = "Detachable laser battery"
	desc = "A rechargeable, detachable battery that serves as a magazine for laser rifles."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "energypack"
	ammo_type = /obj/item/ammo_casing/caseless/laser
	caliber = LASER
	max_ammo = 15

/obj/item/ammo_box/magazine/recharge/vanguard/update_icon_state()
	icon_state = "[initial(icon_state)]-[round(ammo_count(),3)]"

/obj/item/gun/ballistic/automatic/pistol/sigsauer
	name = "P320"
	desc = " пистолет SIG Sauer P320, он же рабочая лошадка эксадронов Авангарда. Оснащён встроенным фонариком "
	icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi'
	icon_state = "sauer"
	w_class = WEIGHT_CLASS_SMALL
	mag_type = /obj/item/ammo_box/magazine/sig
	can_suppress = FALSE
	burst_size = 1
	spread = 7
	fire_delay = 0
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC)
	automatic_burst_overlay = FALSE
	gunlight_state = "mini-light"
	can_flashlight = 0
	can_suppress = FALSE
	pin = /obj/item/firing_pin/explorer

/obj/item/gun/ballistic/automatic/pistol/sigsauer/Initialize(mapload)
	gun_light = new /obj/item/flashlight/seclite(src)
	return ..()

/obj/item/gun/ballistic/automatic/pistol/sigsauer/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"][magazine && istype(magazine, /obj/item/ammo_box/magazine/sig/sig_ext) ? "-ext" : ""]"

/obj/item/ammo_box/magazine/sig
	name = "Sig Sauer p320 mag"
	desc = "A Sig Sauer p320 standart mag."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "sauer"
	ammo_type = /obj/item/ammo_casing/c9mm
	caliber = "9mm"
	max_ammo = 17

/obj/item/ammo_box/magazine/sig/sig_ext
	name = "Sig Sauer p320 extended mag"
	desc = "A Sig Sauer p320 extended mag."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "sauer_ext"
	max_ammo = 24

/obj/item/ammo_box/magazine/sig/update_icon()
	. = ..()
	if(ammo_count())
		icon_state = "[initial(icon_state)]-ammo"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/ammo_box/magazine/sig/sig_ext/update_icon()
	. = ..()
	if(ammo_count())
		icon_state = "[initial(icon_state)]-ammo"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/shield/riot/pointman
	name = "pointman shield"
	desc = "A shield fit for those that want to sprint headfirst into the unknown! Cumbersome as hell."
	icon_state = "riot"
	icon = 'modular_bluemoon/icons/mob/vanguard/riot.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/vanguard/riot_left.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/vanguard/riot_right.dmi'
	force = 14
	throwforce = 5
	throw_speed = 1
	throw_range = 1
	block_chance = 60
	w_class = WEIGHT_CLASS_BULKY
	attack_verb_continuous = list("shoves", "bashes")
	attack_verb_simple = list("shove", "bash")
	repair_material = /obj/item/stack/sheet/plasteel

/obj/item/shield/riot/pointman/shatter(mob/living/carbon/human/owner)
	playsound(owner, 'sound/effects/glassbr3.ogg', 100)
	new /obj/item/pointman_broken((get_turf(src)))

/obj/item/pointman_broken
	name = "broken pointman shield"
	desc = "Might be able to be repaired with plasteel and a welder."
	icon_state = "riot_broken"
	icon = 'modular_bluemoon/icons/mob/vanguard/riot.dmi'
	w_class = WEIGHT_CLASS_BULKY

//broken shield fixing
/datum/crafting_recipe/pointman
	name = "Broken Riot Repair"
	result = /obj/item/shield/riot/pointman
	reqs = list(/obj/item/pointman_broken = 1,
				/obj/item/stack/sheet/plasteel = 3,
				/obj/item/stack/sheet/rglass = 3)
	time = 40
	category = CAT_WEAPONRY
	subcategory = CAT_MELEE
	tools = list(TOOL_WELDER)

/obj/item/melee/tomahawk
	name = "Vanguard magnetic tomahawk"
	desc = "A somewhat dulled axe blade upon a short fibremetal handle. \
		A powerful electromagnet in the grip ensures this weapon always finds its way back to the thrower's hand when activated."
	icon = 'modular_bluemoon/icons/mob/vanguard/tomahawk.dmi'
	icon_state = "tomahawk"
	item_state = "tomahawk"
	lefthand_file = 'modular_bluemoon/icons/mob/vanguard/tomahawk_l.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/vanguard/tomahawk_r.dmi'
	force = 15
	throwforce = 25
	throw_speed = 6
	throw_range = 8
	w_class = WEIGHT_CLASS_NORMAL
	sharpness = SHARP_EDGED
	attack_verb_continuous = list("chops", "tears", "lacerates", "cuts")
	attack_verb_simple = list("chop", "tear", "lacerate", "cut")

	var/hit_sound = 'sound/weapons/egloves.ogg'
	var/turn_on_sound = "sparks"

	// Battery & Magnetic system
	var/obj/item/stock_parts/cell/cell
	var/hitcost = 0
	var/preload_cell_type = /obj/item/stock_parts/cell/high/plus
	var/turned_on = FALSE
	var/throw_cost = 500
	var/return_cost = 0

/obj/item/melee/tomahawk/Initialize(mapload)
	. = ..()
	if(preload_cell_type)
		if(!ispath(preload_cell_type, /obj/item/stock_parts/cell))
			log_mapping("[src] at [AREACOORD(src)] had an invalid preload_cell_type: [preload_cell_type].")
		else
			cell = new preload_cell_type(src)
	update_icon()

/obj/item/melee/tomahawk/get_cell()
	. = cell
	if(iscyborg(loc))
		var/mob/living/silicon/robot/R = loc
		. = R.get_cell()

/obj/item/melee/tomahawk/proc/deductcharge(chrgdeductamt, chargecheck = TRUE, explode = TRUE)
	var/obj/item/stock_parts/cell/copper_top = get_cell()
	if(!copper_top)
		switch_status(FALSE, TRUE)
		return FALSE

	copper_top.use(min(chrgdeductamt, copper_top.charge), explode)
	if(QDELETED(src))
		return FALSE
	if(turned_on && (!copper_top || !copper_top.charge || copper_top.charge < (hitcost * MAGNETIC_TOMAHAWK_CHARGE_LENIENCY)))
		switch_status(FALSE)

/obj/item/melee/tomahawk/proc/switch_status(new_status = FALSE, silent = FALSE)
	if(turned_on != new_status)
		turned_on = new_status
		if(!silent)
			playsound(loc, 'sound/effects/sparks3.ogg', 75, 1, -1)
		if(turned_on)
			START_PROCESSING(SSobj, src)
		else
			STOP_PROCESSING(SSobj, src)
	update_icon()

/obj/item/melee/tomahawk/process()
	deductcharge(round(hitcost * MAGNETIC_TOMAHAWK_DEPLETION_RATE), FALSE, FALSE)

/obj/item/melee/tomahawk/update_icon_state()
	if(turned_on)
		icon_state = "[initial(icon_state)]_active"
	else if(!cell)
		icon_state = "[initial(icon_state)]_nocell"
	else
		icon_state = "[initial(icon_state)]"
	return ..()

/obj/item/melee/tomahawk/examine(mob/user)
	. = ..()
	var/obj/item/stock_parts/cell/copper_top = get_cell()
	if(copper_top)
		. += "<span class='notice'>\The [src] is [round(copper_top.percent())]% charged.</span>"
		. += "<span class='notice'>\The [src] has enough power for [round(copper_top.charge / throw_cost)] magnetic throws.</span>"
	else
		. += "<span class='warning'>\The [src] does not have a power source installed.</span>"
	. += "<span class='notice'>Right click (attack_self) to toggle the magnetic return system.</span>"

/obj/item/melee/tomahawk/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/stock_parts/cell))
		var/obj/item/stock_parts/cell/C = W
		if(cell)
			to_chat(user, "<span class='notice'>[src] already has a cell.</span>")
		else
			if(C.maxcharge < (hitcost * MAGNETIC_TOMAHAWK_CHARGE_LENIENCY))
				to_chat(user, "<span class='notice'>[src] requires a higher capacity cell.</span>")
				return
			if(!user.transferItemToLoc(W, src))
				return
			cell = W
			to_chat(user, "<span class='notice'>You install a cell in [src].</span>")
			update_icon()
	else if(W.tool_behaviour == TOOL_SCREWDRIVER)
		if(cell)
			cell.update_icon()
			cell.forceMove(get_turf(src))
			cell = null
			to_chat(user, "<span class='notice'>You remove the cell from [src].</span>")
			switch_status(FALSE, TRUE)
	else
		return ..()

/obj/item/melee/tomahawk/attack_self(mob/user)
	var/obj/item/stock_parts/cell/copper_top = get_cell()
	if(!copper_top || copper_top.charge < (hitcost * MAGNETIC_TOMAHAWK_CHARGE_LENIENCY))
		switch_status(FALSE, TRUE)
		if(!copper_top)
			to_chat(user, "<span class='warning'>[src] does not have a power source!</span>")
		else
			to_chat(user, "<span class='warning'>[src] is out of charge.</span>")
	else
		switch_status(!turned_on)
		to_chat(user, "<span class='notice'>[src] is now [turned_on ? "on" : "off"].</span>")
	add_fingerprint(user)

// --- Вспомогательная процедура отталкивания цели (только для живых) ---
/obj/item/melee/tomahawk/proc/push_away(atom/movable/target, atom/source)
	if(!istype(target) || QDELETED(target) || target == source)
		return
	var/direction = get_dir(source, target) // направление от источника (топора) к цели
	if(!direction)
		return
	// Сдвигаем цель в направлении ОТ источника – отталкиваем только мобов
	for(var/i in 1 to 2)
		var/turf/new_turf = get_step(target, direction)
		if(!new_turf || new_turf.density)
			break
		if(isliving(target))
			var/mob/living/L = target
			if(!L.Move(new_turf))
				break
		// структуры и машинерии не отталкиваем

// --- Throwing & Return Mechanics ---

/obj/item/melee/tomahawk/throw_at(atom/target, range, speed, mob/thrower, spin = TRUE, diagonals_first = FALSE, datum/callback/callback, force, quickstart = TRUE)
	if(turned_on && thrower)
		var/obj/item/stock_parts/cell/copper_top = get_cell()
		if(!copper_top || copper_top.charge < throw_cost)
			to_chat(thrower, "<span class='warning'>[src] doesn't have enough charge to activate the magnetic return!</span>")
			return ..()

		deductcharge(throw_cost, FALSE)

		if(ishuman(thrower))
			var/mob/living/carbon/human/H = thrower
			H.throw_mode_on()

	return ..()

/obj/item/melee/tomahawk/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..() // стандартная логика урона и ловли

	var/mob/thrown_by = thrownby?.resolve()
	if(!thrown_by || QDELETED(thrown_by))
		return

	// Отталкиваем цель, если она живая и не владелец
	if(hit_atom != thrown_by && isliving(hit_atom))
		push_away(hit_atom, src)

	// Проверяем, не перехватил ли топор другой моб (кроме владельца)
	var/mob/holder = loc
	if(isliving(holder) && holder != thrown_by)
		// Наносим урон перехватчику
		holder.hitby(src, throwingdatum)
		// Вырываем топор из рук
		holder.dropItemToGround(src, TRUE)
		// Запускаем возврат, если есть заряд
		if(turned_on)
			var/obj/item/stock_parts/cell/copper_top = get_cell()
			if(copper_top && copper_top.charge >= return_cost)
				throw_back()
			else
				to_chat(thrown_by, "<span class='warning'>[src] doesn't have enough charge to return!</span>")
		return

	// Если топор не перехвачен, но попал не в владельца и включён магнит – запускаем возврат
	if(turned_on && hit_atom != thrown_by && loc != thrown_by)
		var/obj/item/stock_parts/cell/copper_top = get_cell()
		if(copper_top && copper_top.charge >= return_cost)
			throw_back()
		else
			to_chat(thrown_by, "<span class='warning'>[src] doesn't have enough charge to return!</span>")

/obj/item/melee/tomahawk/proc/throw_back()
	set waitfor = FALSE
	sleep(0.5 SECONDS)
	var/mob/thrown_by = thrownby?.resolve()
	if(!QDELETED(src) && thrown_by && !QDELETED(thrown_by))
		deductcharge(return_cost, FALSE)
		throw_at(thrown_by, throw_range + 2, throw_speed, null, TRUE)

//ножи марксмана - перейдут к штурмовику

/obj/item/kitchen/knife/combat/marksman
	name = "throwing knife"
	desc = "Very well weighted for throwing, feels awkward to use for anything else."
	icon_state = "throwing"
	force = 10
	throwforce = 35
	embedding = list("pain_mult" = 4, "embed_chance" = 75, "fall_chance" = 10, "ignore_throwspeed_threshold" = TRUE)


#undef MAGNETIC_TOMAHAWK_CHARGE_LENIENCY
#undef MAGNETIC_TOMAHAWK_DEPLETION_RATE
