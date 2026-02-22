/// USHM
/obj/item/pickaxe/drill/jackhammer/angle_grinder
	name = "USHM"
	icon = 'modular_bluemoon/Ren/Icons/Obj/USM.dmi'
	icon_state = "RSHM_vrum-vrum"
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/ushm_r.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/ushm_r.dmi'
	item_state = "ushm_r"
	w_class = WEIGHT_CLASS_BULKY
	toolspeed = 0.3
	usesound = 'modular_bluemoon/Ren/Sound/USHM_hit.ogg'
	hitsound = 'modular_bluemoon/Ren/Sound/USHM_hit.ogg'
	desc = "УШМ с алмазным диском и четырёх тактовым двигателем на жидкой плазме. Что ещё может быть нужно, когда требуется взять штурмом чью то крепость? "
	force = 30
	throwforce = 10
	wound_bonus = 35
	armour_penetration = 30
	sharpness = SHARP_EDGED
	attack_verb = list("slashed", "sliced", "shredded")

/obj/item/pickaxe/drill/jackhammer/angle_grinder/afterattack(atom/A, mob/living/user, proximity)
	. = ..()
	if(!proximity || IS_STAMCRIT(user))
		return
	if(istype(A, /obj/structure/window))
		var/obj/structure/window/W = A
		W.take_damage(200, BRUTE, MELEE, 0)
		playsound(user, 'modular_bluemoon/Ren/Sound/USHM_hit.ogg', 50, 1)
	if(istype(A, /obj/structure/grille))
		var/obj/structure/grille/G = A
		G.take_damage(40, BRUTE, MELEE, 0)
		playsound(user, 'modular_bluemoon/Ren/Sound/USHM_hit.ogg', 50, 1)
	if(istype(A, /obj/machinery))
		var/obj/machinery/M = A
		M.take_damage(100, BRUTE, MELEE, 0)
		playsound(user, 'modular_bluemoon/Ren/Sound/USHM_hit.ogg', 50, 1)
	if(istype(A, /obj/structure))
		var/obj/structure/S = A
		S.take_damage(100, BRUTE, MELEE, 0)
		playsound(user, 'modular_bluemoon/Ren/Sound/USHM_hit.ogg', 50, 1)

/obj/item/pickaxe/drill/jackhammer/angle_grinder/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, require_twohands=TRUE)

/// Melter
/obj/item/gun/energy/pulse/pistol/inteq
	name = "Melter"
	desc = "<span class='danger'>Не направлять рабочую часть на органику</span>"
	icon = 'modular_bluemoon/Ren/Icons/Obj/guns.dmi'
	icon_state = "melter"
	charge_delay = 4
	ammo_type = list(/obj/item/ammo_casing/energy/laser/melter, /obj/item/ammo_casing/energy/laser/melter/destroy)
	cell_type = "/obj/item/stock_parts/cell/pulse/melter"

/obj/item/stock_parts/cell/pulse/melter
	name = "melter power cell"
	maxcharge = 10000
	chargerate = 1000

/obj/item/ammo_casing/energy/laser/melter
	projectile_type = /obj/item/projectile/beam/melter
	e_cost = 1400
	select_name = "Kill"
	fire_sound = 'modular_bluemoon/Ren/Sound/Melter.ogg'

/obj/item/ammo_casing/energy/laser/melter/destroy
	projectile_type = /obj/item/projectile/beam/melter/destroy
	e_cost = 5000
	select_name = "MELT"
	fire_sound = 'modular_bluemoon/Ren/Sound/Melter.ogg'

/obj/item/projectile/beam/melter
	icon_state = "heavylaser"
	damage = 60
	light_color = "#ffff00"
	wound_bonus = 10

/obj/item/projectile/beam/melter/destroy
	icon_state = "pulse0"
	light_color = "#e6250c"
	wound_bonus = 40

/obj/item/projectile/beam/melter/on_hit(atom/target, blocked = FALSE)
	. = ..()
	var/turf/open/target_turf = get_turf(target)
	if(istype(target_turf))
		new /obj/effect/decal/cleanable/plasma(drop_location(target_turf))

/obj/item/projectile/beam/melter/destroy/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if (!QDELETED(target) && (isturf(target) || istype(target, /obj/structure/)))
		target.ex_act(EXPLODE_HEAVY)

/obj/item/gun/energy/laser/canceller
	name = "Canceller"
	desc = "Энергетический пистолет довольно старого образца. Создан для использования спецслужбами Солнечной Федерации, но со временем был замещён более удачными образцами. Выглядит сильно модернизированным."
	icon_state = "canceller"
	item_state = "canceller"
	icon = 'modular_bluemoon/Ren/Icons/Obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	ammo_type = list(/obj/item/ammo_casing/energy/disabler)
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT)
	selfcharge = EGUN_SELFCHARGE
	fire_delay = 3
	burst_size = 2
	burst_spread = 20
	burst_shot_delay = 2

/// AA12
/obj/item/ammo_box/magazine/aa12/small
	name = "AA12 magazine (12g buckshot)"
	desc = "Здоровый коробчатый магазин для патрон 12 калибра"
	icon_state = "mag-aa-small"
	icon = 'modular_bluemoon/Ren/Icons/Obj/guns.dmi'
	w_class = WEIGHT_CLASS_SMALL
	max_ammo = 8

/obj/item/ammo_box/magazine/aa12/small/update_icon()
	..()
	icon_state = "mag-aa-small-[ammo_count() ? "1" : "0"]"

/obj/item/ammo_box/magazine/aa12
	name = "AA12 drum magazine (12g buckshot)"
	desc = "Здоровый барабанный магазин для патрон 12 калибра"
	icon_state = "mag-aa"
	icon = 'modular_bluemoon/Ren/Icons/Obj/guns.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	ammo_type = /obj/item/ammo_casing/shotgun/buckshot
	caliber = "shotgun"
	max_ammo = 20

/obj/item/ammo_box/magazine/aa12/update_icon()
	..()
	icon_state = "mag-aa-[ammo_count() ? "1" : "0"]"

/obj/item/gun/ballistic/automatic/shotgun/aa12
	name = "\improper AA12"
	desc = "Древняя, но очень грозная оружейная система. Почему то на ней отсутствует одиночный огонь."
	icon_state = "minotaur"
	item_state = "minotaur"
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file =  'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/guns.dmi'
	w_class = WEIGHT_CLASS_BULKY
	weapon_weight = WEAPON_HEAVY
	recoil = 2
	mag_type = /obj/item/ammo_box/magazine/aa12/small
	fire_sound = 'sound/weapons/gunshotshotgunshot.ogg'
	automatic_burst_overlay = FALSE
	can_suppress = FALSE
	fire_select = 1
	burst_size = 1
	fire_delay = 5 // BLUEMOON EDIT - was NOTHING
	actions_types = list()

/obj/item/gun/ballistic/automatic/shotgun/aa12/update_icon_state()
	..()
	if(magazine)
		if(magazine.ammo_count(0))
			icon_state = "minotaur-mag"
		else
			icon_state = "minotaur-mag-e"
	else
		if(magazine.ammo_count(0))
			icon_state = "minotaur-nomag-e"
		else
			icon_state = "minotaur-nomag"

/obj/item/gun/ballistic/automatic/shotgun/aa12/afterattack()
	. = ..()
	empty_alarm()
	return

//Огнемёт крутой
/obj/item/projectile/bullet/incendiary/m2a100
	name = "Fire"
	damage = 7
	fire_stacks = 10
	damage_type = BURN
	icon_state = ""
	hitsound_wall = ""
	projectile_piercing = PASSMOB
	range = 15

/obj/item/ammo_casing/energy/laser/m2a100
	projectile_type = /obj/item/projectile/bullet/incendiary/m2a100
	pellets = 6
	variance = 35
	e_cost = 50
	select_name = "Fire"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/flamethrower.ogg'

/obj/item/gun/energy/m2a100
	name = "M2A100"
	desc = "Удачная модернизация старых моделей огнемётов из солнечной системы. Совмещает в себе компактность, простоту использования и использование твёрдой плазмы в качестве топлива."
	icon_state = "m240"
	item_state = "m240_0"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/guns.dmi'
	ammo_type = list(/obj/item/ammo_casing/energy/laser/m2a100)
	attack_verb = list("attacked", "bumped", "hited")
	force = 12
	inaccuracy_modifier = 0.25
	can_charge = 0
	var/cover_open = FALSE

/obj/item/gun/energy/m2a100/examine(mob/user)
	. = ..()
	if(cell)
		. += "<span class='notice'>[src] is [round(cell.percent())]% of fuel.</span>"

/obj/item/gun/energy/m2a100/attack_self(mob/user)
	cover_open = !cover_open
	to_chat(user, "<span class='notice'>You [cover_open ? "open" : "close"] [src]'s cover.</span>")
	if(cover_open)
		playsound(user, 'sound/weapons/sawopen.ogg', 60, 1)
	else
		playsound(user, 'sound/weapons/sawclose.ogg', 60, 1)
	update_icon()

/obj/item/gun/energy/m2a100/update_icon_state()
	if(!cell)
		return
	if(cell.percent() > 0)
		icon_state = "m240[cover_open ? "-open" : "-closed"]"
	else
		icon_state = "m240[cover_open ? "-open" : "-closed"]-empty"

/obj/item/gun/energy/m2a100/attackby(obj/item/I, mob/user)  //перезарядка работает как у резака. Можно изменять, сколько требуется плазмы для полного заряда
	if(istype(I, /obj/item/stack/sheet/mineral/plasma) && cover_open == TRUE)
		I.use(1)
		cell.give(500)
		to_chat(user, "<span class='notice'>You insert [I] in [src], recharging it.</span>")
	else if(istype(I, /obj/item/stack/ore/plasma) && cover_open == TRUE)
		I.use(1)
		cell.give(100)
		to_chat(user, "<span class='notice'>You insert [I] in [src], recharging it.</span>")
	else
		..()

/obj/item/gun/energy/m2a100/afterattack(atom/target as mob|obj|turf, mob/living/user as mob|obj, flag, params)
	if(cover_open)
		to_chat(user, "<span class='warning'>[src]'s cover is open! Close it before firing!</span>")
	else
		. = ..()
		update_icon()

//// Омни винтовка
/obj/item/gun/energy/laser/sniper

	name = "Omni rifle"
	desc = "Sniper Energy Rifle against Drones"
	icon = 'modular_bluemoon/Ren/Icons/Obj/40x32.dmi'
	icon_state = "railgun"
	item_state = "railgun"
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file =  'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	ammo_type = list(/obj/item/ammo_casing/energy/laser/omni)
	cell_type = /obj/item/stock_parts/cell/beam_rifle
	slot_flags = ITEM_SLOT_BACK
	fire_delay = 20
	force = 15
	custom_materials = null
	recoil = 1
	ammo_x_offset = 3
	ammo_y_offset = 3


/obj/item/ammo_casing/energy/laser/omni
	projectile_type = /obj/item/projectile/beam/hitscan
	e_cost = 5000
	select_name = "Omni charge"
	fire_sound = 'sound/weapons/beam_sniper.ogg'

/obj/item/projectile/beam/hitscan
	hitscan = TRUE
	muzzle_type = /obj/effect/projectile/muzzle/laser/omni
	tracer_type = /obj/effect/projectile/tracer/laser/omni
	impact_type = /obj/effect/projectile/impact/laser/omni
	name = "omni beam"
	damage = 35
	wound_bonus = 20
	bare_wound_bonus = 10
	armour_penetration = -10
	projectile_piercing = PASSMOB
	impact_effect_type = /obj/effect/temp_visual/bluespace_fissure

/obj/effect/projectile/muzzle/laser/omni
	name = "omni flash"
	icon_state = "muzzle_omni"

/obj/effect/projectile/tracer/laser/omni
	name = "omni beam"
	icon_state = "beam_omni"

/obj/effect/projectile/impact/laser/omni
	name = "omni impact"
	icon_state = "impact_omni"

///Диск с чертежами патрон для автолата
/obj/item/disk/design_disk/adv/ammo/garand
	name = "Ammo desine disk"
	desc = "Вставь в автолат, что-бы печатать крутые патроны"

/obj/item/disk/design_disk/adv/ammo/garand/Initialize(mapload)
	. = ..()
	var/datum/design/ammo_garand/A = new
	var/datum/design/ammo_garand_rubber/H = new
	blueprints[1] = A
	blueprints[2] = H

/datum/design/ammo_garand
	name = "Enbloc clip (.308)."
	desc = "An enbloc clip for a Mars Service Rifle."
	id = "ammo_garand"
	build_type = AUTOLATHE
	materials = list(/datum/material/iron = 28000)
	build_path = /obj/item/ammo_box/magazine/garand
	category = list("Imported")

/datum/design/ammo_garand_rubber
	name = "Enbloc clip (.308) rubber."
	desc = "An enbloc clip for a Mars Service Rifle. Now non lethal"
	id = "ammo_garand_rubber"
	build_type = AUTOLATHE
	materials = list(/datum/material/iron = 28000)
	build_path = /obj/item/ammo_box/magazine/garand/rubber
	category = list("Imported")

/obj/item/disk/design_disk/adv/ammo/ks23
	name = "Ammo Design Disk"
	desc = "Вставь в автолат, чтобы печатать крутые патроны."

/obj/item/disk/design_disk/adv/ammo/ks23/Initialize(mapload)
	. = ..()
	var/datum/design/ammo_ks23/N = new
	var/datum/design/ammo_ks23/slugs/E = new
	var/datum/design/ammo_ks23/buckshot23/G = new
	var/datum/design/ammo_ks23/rubbershot23/R = new
	blueprints[1] = N
	blueprints[2] = E
	blueprints[3] = G
	blueprints[4] = R

/datum/design/ammo_ks23
	name = "ammo box (KS23 slugs)"
	desc = "Ammo for KS23."
	id = "ammo_ks23"
	build_type = AUTOLATHE
	materials = list(/datum/material/iron = 42000)
	build_path = /obj/item/ammo_box/slug23
	category = list("Imported")

/datum/design/ammo_ks23/slugs
	name = "ammo box (KS23 rubber slugs)"
	id = "ammo_ks23_rs"
	build_path = /obj/item/ammo_box/slug_rubber23

/datum/design/ammo_ks23/buckshot23
	name = "ammo box (KS23 buckshots)"
	id = "ammo_ks23_bs"
	build_path = /obj/item/ammo_box/buckshot23

/datum/design/ammo_ks23/rubbershot23
	name = "ammo box (KS23 rubbershots)"
	id = "ammo_ks23_rsh"
	build_path = /obj/item/ammo_box/rubbershot23

///Дорожный знак
/obj/item/spear/stop
	name = "Stop sign"
	desc = "Где вообще посреди космоса ты умудрился найти этот знак?!"
	icon_state = "stop1"
	icon_prefix = "stop"
	icon = 'modular_bluemoon/Ren/Icons/Obj/misc.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	throwforce = 40
	block_chance = 50
	sharpness = SHARP_NONE
	hitsound = 'modular_bluemoon/Ren/Sound/metal.ogg'
	attack_verb = list("attacked", "slam", "jabbed", "torn", "gored")

/obj/item/spear/electrospear/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded=14, force_wielded=22, icon_wielded="[icon_prefix]1")

/datum/crafting_recipe/stopsign
	name = "Stop sign"
	result = /obj/item/spear/stop
	reqs = list(/obj/item/stack/cable_coil = 15,
				/obj/item/stack/sheet/metal = 10,
				/obj/item/stack/sheet/plasteel = 5,
				/obj/item/toy/crayon/spraycan = 1,
				/obj/item/bikehorn = 1)
	tools = list(TOOL_WELDER, TOOL_SCREWDRIVER, TOOL_WIRECUTTER)
	time = 100
	category = CAT_WEAPONRY
	subcategory = CAT_MELEE

///Ретекстуры
/obj/item/melee/baseball_bat/telescopic/inteq
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'

/obj/item/grenade/spawnergrenade/syndiesoap/inteq
	name = "Mister Scrubby"
	spawner_type = /obj/item/soap/inteq

/obj/item/grenade/clusterbuster/soap/inteq
	name = "Slipocalypse"
	payload = /obj/item/grenade/spawnergrenade/syndiesoap/inteq
// Сабля Каракурт
/obj/item/storage/belt/sabre/karakurt
	name = "Karakurt sheath"
	desc = "Ножны со встроенным отсеком для ядом. Постоянно поддерживают элегантное оружие в подобающем виде."
	icon_state = "isheath"
	item_state = "isheath"
	force = 5
	throwforce = 15
	w_class = WEIGHT_CLASS_BULKY
	attack_verb = list("bashed", "slashes", "prods", "pokes")
	fitting_swords = list(/obj/item/melee/rapier/karakurt)
	starting_sword = /obj/item/melee/rapier/karakurt

/obj/item/melee/rapier/karakurt/get_belt_overlay()
	if(istype(loc, /obj/item/storage/belt/sabre/karakurt))
		return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "karakurt")
	return ..()

/obj/item/melee/rapier/karakurt/get_worn_belt_overlay(icon_file)
	return mutable_appearance(icon_file, "-karakurt")

/obj/item/melee/rapier/karakurt
	name = "Karakurt"
	desc = "<span class='nicegreen'>Лучше не трогать это лезвие руками</span>"
	icon_state = "karakurt"
	item_state = "karakurt"
	force = 15
	throwforce = 12
	armour_penetration = 50
	block_parry_data = /datum/block_parry_data/traitor_rapier

/obj/item/melee/rapier/karakurt/attack(mob/living/target, mob/living/user)
	. = ..()
	if(iscarbon(target))
		if(HAS_TRAIT(user, TRAIT_PACIFISM))
			visible_message("<span class='warning'>[user] gently taps [target] with [src].</span>",null,null,COMBAT_MESSAGE_RANGE)
			log_combat(user, target, "slept", src)
			var/mob/living/carbon/H = target
			H.Dizzy(10)
			H.adjustStaminaLoss(30)
			if(CHECK_STAMCRIT(H) != NOT_STAMCRIT)
				H.Sleeping(180)
		else
			if(iscarbon(target))
				visible_message("<span class='warning'>Из свежей раны [target] начинает сочиться яд вместе с свежей кровью. [src] отравил его!</span>",null,null,COMBAT_MESSAGE_RANGE)
				var/mob/living/carbon/H = target
				H.reagents.add_reagent(/datum/reagent/toxin/lexorin, 3)

/obj/item/melee/baseball_bat/ablative/inteq
	name = "Iron will"
	desc = "A metal bat. Very robust"
	force = 26
	throwforce = 30
