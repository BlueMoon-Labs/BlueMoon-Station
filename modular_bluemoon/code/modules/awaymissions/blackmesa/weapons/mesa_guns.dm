/obj/item/gun/ballistic/automatic/pistol/hl9mm
	name = "9mm pistol"
	desc = " пистолет Beretta 92FS или же 9mm pistol является довольно распространённым пистолетом у охранников комплекса чёрной мезы... Выглядит невероятно старомодно "
	icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi'
	icon_state = "hl9mmpistol"
	w_class = WEIGHT_CLASS_SMALL
	mag_type = /obj/item/ammo_box/magazine/pistolm9mm
	can_suppress = FALSE
	burst_size = 1
	spread = 7
	fire_delay = 0
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC)
	automatic_burst_overlay = FALSE
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/9mm.ogg'
	gunlight_state = "mini-light"
	can_flashlight = 0

/obj/item/gun/ballistic/automatic/pistol/hl9mm/Initialize(mapload)
	gun_light = new /obj/item/flashlight/seclite(src)
	return ..()


/obj/item/gun/ballistic/automatic/pistol/hl9mm/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"]"

/obj/item/gun/ballistic/automatic/sniper_rifle/m4oa1
	name = "m40a1 sniper rifle"
	desc = "Довольно старая, но верная и мощная снайперская винтовка прямиком из далёкого прошлого"
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "m4oa1"
	item_state = "m4oa1"
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/sniper_fire.ogg'
	recoil = 1
	weapon_weight = WEAPON_HEAVY
	mag_type = /obj/item/ammo_box/magazine/sniper_rounds/m4oa1
	fire_delay = 25
	burst_size = 1
	can_unsuppress = TRUE
	can_suppress = TRUE
	w_class = WEIGHT_CLASS_NORMAL
	inaccuracy_modifier = 0.5
	zoomable = TRUE
	zoom_amt = 7
	zoom_out_amt = 5
	slot_flags = ITEM_SLOT_BACK
	automatic_burst_overlay = FALSE
	actions_types = list()

/obj/item/gun/ballistic/automatic/sniper_rifle/m4oa1/update_icon_state()
	if(magazine)
		icon_state = "m4oa1"
	else
		icon_state = "m4oa1_mag"

/obj/item/ammo_box/magazine/sniper_rounds/m4oa1
	name = "m4oa1 magazine"
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "m4oa1"
	ammo_type = /obj/item/ammo_casing/p50
	max_ammo = 8
	caliber = ".50"

/obj/item/ammo_box/magazine/sniper_rounds/m4oa1/update_icon()
	. = ..()
	if(ammo_count())
		icon_state = "[initial(icon_state)]-ammo"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/gun/ballistic/automatic/mp5
	name = "MP5 machinegun"
	desc = "Heckler Koch Mp5 является хоть и устаревшим, но невероятно сильным оружием в виду своей скорострельности. Какой идиот вообще подумал, что будет отличной идеей отобрать его у морпеха HECU?"
	icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "mp5"
	item_state = "mp5"
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/mp5.ogg'
	mag_type = /obj/item/ammo_box/magazine/mp5
	can_suppress = FALSE
	weapon_weight = WEAPON_HEAVY
	w_class = WEIGHT_CLASS_BULKY
	spread = 9
	burst_size = 3
	burst_shot_delay = 2
	fire_delay = 2.5 ///Это пиздец!
	can_bayonet = FALSE
	automatic_burst_overlay = FALSE

/obj/item/gun/ballistic/automatic/mp5/update_icon_state()
	if(magazine)
		icon_state = "mp5"
	else
		icon_state = "mp5nomag"

/obj/item/ammo_box/magazine/mp5
	name = "MP5 magazine (10mm Auto)"
	desc = "Magazines taking 10mm ammunition; it fits in the MP5."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "mp5"
	ammo_type = /obj/item/ammo_casing/c10mm
	max_ammo = 30

/obj/item/ammo_box/magazine/mp5/update_icon()
	. = ..()
	if(ammo_count())
		icon_state = "[initial(icon_state)]-ammo"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/gun/ballistic/shotgun/m870
	name = "m870 shotgun"
	desc = "Remington 870 - это классический помповый дробовик, который был представлен компанией Remington Arms в 1950 году и до сих пор остается одним из самых популярных и продаваемых ружей в США."
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "m870"
	item_state = "m870"
	w_class = WEIGHT_CLASS_BULKY
	recoil = 4
	attack_speed = 10
	force = 40
	fire_delay = 4
	mag_type = /obj/item/ammo_box/magazine/internal/shot/m870
	weapon_weight = WEAPON_HEAVY

/obj/item/ammo_box/magazine/internal/shot/m870
	name = "shotgun internal magazine"
	ammo_type = /obj/item/ammo_casing/shotgun/buckshot
	caliber = "shotgun"
	max_ammo = 4

/obj/item/gun/ballistic/shotgun/spas
	name = "SPAS 12 shotgun"
	desc = "Этот невероятно старый и брутальный дробовик заставляет вас надеть балаклаву с горнолыжными очками."
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "spas"
	item_state = "spas"
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/shotgun.ogg'
	w_class = WEIGHT_CLASS_BULKY
	recoil = 3
	force = 10
	fire_delay = 4
	mag_type = /obj/item/ammo_box/magazine/internal/shot/spas
	pumpsound = 'modular_bluemoon/sound/weapons/mesa/shotgun_rack.ogg'
	weapon_weight = WEAPON_HEAVY

/obj/item/gun/ballistic/shotgun/spas/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	..()
	src.pump(user)

/obj/item/ammo_box/magazine/internal/shot/spas
	name = "shotgun internal magazine"
	ammo_type = /obj/item/ammo_casing/shotgun/buckshot
	caliber = "shotgun"
	max_ammo = 8

/obj/item/gun/ballistic/automatic/mp5/underbarrel
	desc = "Версия MP5 с подствольным гранатомётом и невероятным желанием выстрелить из него"
	var/obj/item/gun/ballistic/revolver/grenadelauncher/halflife/underbarrel
	icon_state = "mp5grenade"
	item_state = "mp5"

/obj/item/gun/ballistic/automatic/mp5/underbarrel/Initialize(mapload)
	. = ..()
	underbarrel = new /obj/item/gun/ballistic/revolver/grenadelauncher/halflife(src)
	update_icon()

/obj/item/gun/ballistic/automatic/mp5/underbarrel/afterattack(atom/target, mob/living/user, flag, params)
	if(select == 2)
		underbarrel.afterattack(target, user, flag, params)
	else
		. = ..()
		return
/obj/item/gun/ballistic/automatic/mp5/underbarrel/attackby(obj/item/A, mob/user, params)
	if(istype(A, /obj/item/ammo_casing))
		if(istype(A, underbarrel.magazine.ammo_type))
			underbarrel.attack_self()
			underbarrel.attackby(A, user, params)
	else
		..()

/obj/item/gun/ballistic/automatic/mp5/underbarrel/update_icon_state()
	if(magazine)
		icon_state = "mp5grenade"
	else
		icon_state = "mp5grenadenomag"


/obj/item/gun/ballistic/automatic/mp5/underbarrel/fire_select()
	var/mob/living/carbon/human/user = usr
	switch(select)
		if(0)
			select = 1
			burst_size = initial(burst_size)
			to_chat(user, "<span class='notice'>You switch to [burst_size]-rnd burst.</span>")
		if(1)
			select = 2
			to_chat(user, "<span class='notice'>You switch to grenades.</span>")
		if(2)
			select = 0
			burst_size = 1
			to_chat(user, "<span class='notice'>You switch to semi-auto.</span>")
	playsound(user, 'sound/weapons/empty.ogg', 100, 1)
	update_icon()
	return


/obj/item/gun/ballistic/revolver/grenadelauncher/halflife
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/underbarrel.ogg'
	pin = /obj/item/firing_pin

/obj/item/gun/ballistic/automatic/m16a4/mesa
	name = "\improper old M16 rifle"
	desc = "Невероятно старая версия М16 с сломанным подствольным гранатомётом и... Большей отдачей что-ли? Держа её в руках, вы чувствуете странные ощущения... Да и отряды HECU с таким замечены не были"
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	icon_state = "m16hl"
	burst_size = 1
	fire_delay = 3
	spread = 11
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/m16.ogg'

/obj/item/gun/ballistic/automatic/m16a4/mesa/update_icon_state()
	if(magazine)
		icon_state = "m16hl"
	else
		icon_state = "m16hl-e"

/obj/item/gun/ballistic/automatic/mp7
	name = "\improper mp7"
	desc = "Heckler & Koch MP7 A1 PDW — пистолет-пулемёт, разработанный в начале 2000-х годов немецкой фирмой Heckler & Koch. Отлично подойдёт, если вместо лечения союзников медик вашего отряда HECU хочет устроить бойню"
	icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "mp7"
	item_state = "mp7"
	fire_delay = 1 //ATATATATATATATATA!!!
	spread = 8
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/mp7.ogg'
	weapon_weight = WEAPON_LIGHT
	mag_type = /obj/item/ammo_box/magazine/mp7

/obj/item/gun/ballistic/automatic/mp7/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : ""]"
	if(magazine)
		icon_state = "mp7"
	else
		icon_state = "mp7nomag"

/obj/item/ammo_box/magazine/mp7
	name = "MP7 magazine"
	desc = "A standart magazine for mp7"
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "mp7"
	ammo_type = /obj/item/ammo_casing/mm46
	caliber = "4.6mm"
	max_ammo = 30

/obj/item/ammo_box/magazine/mp7/update_icon()
	. = ..()
	if(ammo_count())
		icon_state = "[initial(icon_state)]-ammo"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/ammo_casing/mm46
	name = "4.6mm bullet casing"
	desc = "A 4.6mm bullet casing."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "5.8x40mm"
	caliber = "4.6mm"
	projectile_type = /obj/item/projectile/bullet/mm46

/obj/item/projectile/bullet/mm46
	name = "4.6mm bullet"
	damage = 10
	armour_penetration = 3
	wound_bonus = -3
	bare_wound_bonus = 1

/obj/item/gun/ballistic/automatic/scar
	name = "\improper HC scar"
	desc = "Модифицированная версия FN Scar, предназначенная для ведения стрельбы на средние и дальние дистанции. В отличие от M4oa1, имеет автоматический режим стрельбы и менее убойный калибр + крутой песчаный камуфляж (Но вы же помните то, что орудуете только в научном комплексе?)"
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "scar"
	item_state = "scar"
	fire_delay = 5
	spread = 10
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/scar.ogg'
	weapon_weight = WEAPON_HEAVY
	w_class = WEIGHT_CLASS_BULKY
	mag_type = /obj/item/ammo_box/magazine/scar

/obj/item/gun/ballistic/automatic/scar/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : ""]"
	if(magazine)
		icon_state = "scar"
	else
		icon_state = "scar_mag"

/obj/item/ammo_box/magazine/scar
	name = " HC SCAR magazine"
	desc = "A standart magazine for HC SCAR"
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "scar"
	ammo_type = /obj/item/ammo_casing/mm762
	caliber = "7.62mm"
	max_ammo = 15

/obj/item/ammo_box/magazine/scar/update_icon()
	. = ..()
	if(ammo_count())
		icon_state = "[initial(icon_state)]-ammo"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/ammo_casing/mm762
	name = "7.62mm bullet casing"
	desc = "A 7.62mm bullet casing."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "5.8x40mm"
	caliber = "7.62mm"
	projectile_type = /obj/item/projectile/bullet/mm762

/obj/item/projectile/bullet/mm762
	name = "7.62mm bullet"
	damage = 25
	armour_penetration = 4
	wound_bonus = -6
	bare_wound_bonus = 5

/obj/item/gun/ballistic/automatic/p90
	name = "\improper P90"
	desc = "FN P90 является оружием индивидуальной самообороны бельгийской компании Fabrique Nationale Herstal."
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "p90"
	item_state = "p90"
	fire_delay = 1.5 //FUUUUUUUUCK!!!!!
	spread = 17
	fire_sound = 'sound/weapons/gunshot_smg_alt.ogg'
	weapon_weight = WEAPON_HEAVY
	w_class = WEIGHT_CLASS_BULKY
	mag_type = /obj/item/ammo_box/magazine/p90

/obj/item/gun/ballistic/automatic/p90/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : ""]"
	if(magazine)
		icon_state = "p90"
	else
		icon_state = "p90_mag"

/obj/item/ammo_box/magazine/p90
	name = "p90 magazine"
	desc = "A standart magazine for p90"
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "p90"
	ammo_type = /obj/item/ammo_casing/mm57
	caliber = "5.7mm"
	max_ammo = 50

/obj/item/ammo_box/magazine/p90/update_icon()
	. = ..()
	if(ammo_count())
		icon_state = "[initial(icon_state)]-ammo"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/ammo_casing/mm57
	name = "5.7mm bullet casing"
	desc = "A 5.7mm bullet casing."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "5.8x40mm"
	caliber = "5.7mm"
	projectile_type = /obj/item/projectile/bullet/mm57

/obj/item/projectile/bullet/mm57
	name = "5.7mm bullet"
	damage = 10
	armour_penetration = 4
	wound_bonus = -4
	bare_wound_bonus = 2


/obj/item/uber_teleporter
	name = "\improper Nihilanth's Divinity"
	desc = "It glows harshly, the power of a portal wielding monster lays within."
	icon = 'modular_bluemoon/icons/obj/structures/mesa_plants.dmi'
	icon_state = "crystal_pylon"

/obj/item/uber_teleporter/attack_self(mob/living/user, modifiers)
	. = ..()
	playsound(get_turf(user), 'sound/magic/LightningShock.ogg', 50, TRUE)
	var/area/area_to_teleport_to = tgui_input_list(usr, "Area to teleport to", "Teleport", GLOB.teleportlocs)
	if(!area_to_teleport_to)
		return

	var/area/teleport_area = GLOB.teleportlocs[area_to_teleport_to]

	var/list/possible_turfs = list()
	for(var/turf/iterating_turf in get_area_turfs(teleport_area.type))
		if(!iterating_turf.density)
			var/clear = TRUE
			for(var/obj/iterating_object in iterating_turf)
				if(iterating_object.density)
					clear = FALSE
					break
			if(clear)
				possible_turfs += iterating_turf

	if(!LAZYLEN(possible_turfs))
		to_chat(user, span_warning("The spell matrix was unable to locate a suitable teleport destination for an unknown reason. Sorry."))
		return

	if(user.buckled)
		user.buckled.unbuckle_mob(user, force=1)

	var/list/temp_turfs = possible_turfs
	var/attempt = null
	var/success = FALSE
	while(length(temp_turfs))
		attempt = pick(temp_turfs)
		do_teleport(user, attempt, channel = TELEPORT_CHANNEL_FREE)
		if(get_turf(user) == attempt)
			success = TRUE
			break
		else
			temp_turfs.Remove(attempt)

	if(!success)
		do_teleport(user, possible_turfs, channel = TELEPORT_CHANNEL_FREE)
		playsound(get_turf(user), 'sound/magic/LightningShock.ogg', 50, TRUE)



//SPECGUNS
//В РАЗРАБОТКЕ

//obj/item/gun/energy/beam_rifle/mesa
//	name = "CARGO HELPER 1998"
//	desc = "Критично ПРОВАЛЬНЫЙ прототип который должен был помогать работникам чёрной мезы перетаскивать предметы при помощи антигравитационного луча. К превиликому сожалению или счастью, этот монстр вместо того, что-бы поднимать предметы буквально ПРОШИВАЕТ их смертоносной энергией зена. На корпусе видно куча торчащих проводков и надписей с предупреждениями"
//	icon = 'icons/obj/guns/energy.dmi'
//	icon_state = "esniper"
//	item_state = "esniper"
//	fire_sound = 'sound/weapons/beam_sniper.ogg'
//	slot_flags = FALSE
//	force = 20
//	recoil = 6
//	ammo_x_offset = 0
//	ammo_y_offset = 0
//	ammo_type = list(/obj/item/projectile/beam/emitter/hitscan)
//	cell_type = /obj/item/stock_parts/cell/beam_rifle
//	canMouseDown = TRUE
//	can_turret = FALSE
//	can_circuit = FALSE
//	//Cit changes: beam rifle stats.
//	slowdown = 1
//	item_flags = NO_MAT_REDEMPTION | SLOWS_WHILE_IN_HAND
//	pin = /obj/item/firing_pin
//	aiming_time = 6
//	aiming_time_fire_threshold = 4
//	aiming_time_left = 5
//	aiming_time_increase_user_movement = 10
//	structure_piercing = 1
//	wall_pierce_amount = 1
//	projectile_damage = 40
//	projectile_stun = 1
//	delay = 25

//	var/static/image/charged_overlay = image(icon = 'icons/obj/guns/energy.dmi', icon_state = "esniper_charged")
//	var/static/image/drained_overlay = image(icon = 'icons/obj/guns/energy.dmi', icon_state = "esniper_empty")



//ПРИЗЫВ ПУШЕК??!??!?!?7
//Grunt
/obj/item/choice_beacon/mesagrunt
	name = "Grunt type choice beacon"
	desc = "Secret USA army technology. Get your guns here and now"

/obj/item/choice_beacon/mesagrunt/generate_display_names()
	var/static/list/grunt_item_list
	if(!grunt_item_list)
		grunt_item_list = list()
		var/list/templist = typesof(/obj/item/storage/box/basedgrunt)
		for(var/V in templist)
			var/atom/A = V
			grunt_item_list[initial(A.name)] = A
	return grunt_item_list

/obj/item/storage/box/basedgrunt
	name = "MP5 machinegun kit"


/obj/item/storage/box/basedgrunt/PopulateContents()
	new /obj/item/ammo_box/magazine/mp5(src)
	new /obj/item/gun/ballistic/automatic/mp5(src)
	new /obj/item/ammo_box/magazine/mp5(src)


/obj/item/storage/box/basedgrunt/marksman
	name = "HC SCAR marksman kit"

/obj/item/storage/box/basedgrunt/marksman/PopulateContents()
	new /obj/item/gun/ballistic/automatic/scar(src)
	new /obj/item/ammo_box/magazine/scar(src)
	new /obj/item/ammo_box/magazine/scar(src)
	new /obj/item/ammo_box/magazine/scar(src)
	new /obj/item/binoculars(src)

/obj/item/storage/box/basedgrunt/rapidgrunt
	name = "p90 machinegun kit"

/obj/item/storage/box/basedgrunt/rapidgrunt/PopulateContents()
	new /obj/item/gun/ballistic/automatic/p90(src)
	new /obj/item/ammo_box/magazine/p90(src)
	new /obj/item/ammo_box/magazine/p90(src)
	new /obj/item/ammo_box/magazine/p90(src)

//breacher

/obj/item/choice_beacon/mesabreacher
	name = "breacher type choice beacon"
	desc = "Secret USA army technology. Get your guns here and now"

/obj/item/choice_beacon/mesabreacher/generate_display_names()
	var/static/list/breacher_item_list
	if(!breacher_item_list)
		breacher_item_list = list()
		var/list/templist = typesof(/obj/item/storage/box/basedbreacher)
		for(var/V in templist)
			var/atom/A = V
			breacher_item_list[initial(A.name)] = A
	return breacher_item_list

/obj/item/storage/box/basedbreacher
	name = "SPAS 12 crowd control kit"

/obj/item/storage/box/basedbreacher/PopulateContents()
	new /obj/item/gun/ballistic/shotgun/spas(src)
	new /obj/item/ammo_box/shotgun/loaded/buckshot(src)


/obj/item/storage/box/basedbreacher/m870
	name = "m870 breacher kit"

/obj/item/storage/box/basedbreacher/m870/PopulateContents()
	new /obj/item/gun/ballistic/shotgun/m870(src)
	new /obj/item/ammo_box/shotgun/loaded/buckshot(src)
	new /obj/item/ammo_box/shotgun/loaded/buckshot(src)
	new /obj/item/grenade/plastic/c4(src)

//medic

/obj/item/choice_beacon/mesamedic
	name = "medic type choice beacon"
	desc = "Secret USA army technology. Get your MEDS here and now"

/obj/item/choice_beacon/mesamedic/generate_display_names()
	var/static/list/medic_item_list
	if(!medic_item_list)
		medic_item_list = list()
		var/list/templist = typesof(/obj/item/storage/box/basedmedic)
		for(var/V in templist)
			var/atom/A = V
			medic_item_list[initial(A.name)] = A
	return medic_item_list

/obj/item/storage/box/basedmedic
	name = "9mm and based meds kit"

/obj/item/storage/box/basedmedic/PopulateContents()
	new /obj/item/gun/ballistic/automatic/pistol/hl9mm(src)
	new /obj/item/ammo_box/magazine/pistolm9mm(src)
	new /obj/item/ammo_box/magazine/pistolm9mm(src)
	new /obj/item/storage/firstaid/emergency(src)

/obj/item/storage/box/basedmedic/mp7
	name = "mp7 and toxin treatment kit"

/obj/item/storage/box/basedmedic/mp7/PopulateContents()
	new /obj/item/gun/ballistic/automatic/mp7(src)
	new /obj/item/ammo_box/magazine/mp7(src)
	new /obj/item/ammo_box/magazine/mp7(src)
	new /obj/item/storage/firstaid/toxin(src)

/obj/item/storage/box/basedmedic/medbeam
	name = "medbeam and tactical meds (No weapons) kit"

/obj/item/storage/box/basedmedic/medbeam/PopulateContents()
	new /obj/item/gun/medbeam(src)
	new /obj/item/storage/firstaid/tactical(src)
