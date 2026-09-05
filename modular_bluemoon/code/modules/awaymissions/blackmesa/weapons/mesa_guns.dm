// ============================================================================
// TIER 1 - Basic Weapons (Lowest Power)
// ============================================================================
// ПРИМЕЧАНИЕ: Данный файл содержит mesa guns с поддержкой динамической системы звуков.
// Система описана в: modular_bluemoon/code/modules/awaymissions/blackmesa/weapons/dynamic_gun_sounds.dm
//
// Для внедрения системы в другое оружие укажите dynamic_sound_dry и
// dynamic_sound_tail. Остальные параметры громкости можно переопределить
// при необходимости; датум создаётся автоматически в общем Initialize().

/obj/item/gun/ballistic/automatic/pistol/hl9mm
	name = "9mm pistol"
	desc = " пистолет Beretta 92FS или же 9mm pistol является довольно распространённым пистолетом у охранников комплекса чёрной мезы... Выглядит невероятно старомодно "
	icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi'
	icon_state = "hl9mmpistol"
	w_class = WEIGHT_CLASS_SMALL
	mag_type = /obj/item/ammo_box/magazine/pistolm9mm/mesa
	can_suppress = FALSE
	burst_size = 1
	spread = 7
	fire_delay = 0
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC)
	automatic_burst_overlay = FALSE
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/9mm.ogg'
	mesa_muzzle_flash = TRUE
	gunlight_state = "mini-light"
	can_flashlight = 0

/obj/item/gun/ballistic/automatic/pistol/hl9mm/Initialize(mapload)
	gun_light = new /obj/item/flashlight/seclite(src)
	return ..()


/obj/item/gun/ballistic/automatic/pistol/hl9mm/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"]"

/obj/item/gun/ballistic/automatic/pistol/hl9mm/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	..()
	playsound(user, fire_sound, 80, 0, 0)

/obj/item/gun/ballistic/automatic/pistol/hl9mm/insert_mag(obj/item/ammo_box/magazine/AM, mob/user)
	if(!istype(AM, /obj/item/ammo_box/magazine/pistolm9mm) && !istype(AM, /obj/item/ammo_box/magazine/pistolm9mm/mesa))
		return
	return ..()

// Custom magazine for hl9mm with special projectile
/obj/item/ammo_box/magazine/pistolm9mm/mesa
	name = "9mm magazine (special)"
	icon_state = "9x19p"
	ammo_type = /obj/item/ammo_casing/c9mm/mesa
	max_ammo = 16
	multiple_sprites = 2

/obj/item/ammo_box/magazine/pistolm9mm/mesa/update_icon()
	..()
	icon_state = "9x19p-[ammo_count() ? "16" : "0"]"

// Custom casing for hl9mm
/obj/item/ammo_casing/c9mm/mesa
	name = "9mm bullet casing (Black Mesa)"
	desc = "A 9mm bullet casing."
	caliber = "9mm"
	projectile_type = /obj/item/projectile/bullet/c9mm/mesa

// Custom projectile for hl9mm with bonus damage to simple animals
/obj/item/projectile/bullet/c9mm/mesa
	name = "9mm bullet"
	damage = 22
	armour_penetration = 20
	embedding = list(embed_chance=15, fall_chance=3, jostle_chance=4, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.4, pain_mult=5, jostle_pain_mult=6, rip_time=10)

/obj/item/projectile/bullet/c9mm/mesa/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!target)
		return
	if(istype(target, /mob/living/simple_animal))
		var/mob/living/simple_animal/SA = target
		if(!SA)
			return
		SA.apply_damage(10, BRUTE)

// ============================================================================
// TIER 4 - Elite Weapons (Highest Power)
// ============================================================================

/obj/item/gun/ballistic/automatic/sniper_rifle/m4oa1
	name = "m40a1 sniper rifle"
	desc = "Довольно старая, но верная и мощная снайперская винтовка прямиком из далёкого прошлого"
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "m4oa1"
	item_state = "m4oa1"
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/sniper_fire.ogg'
	mesa_muzzle_flash = TRUE
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

// TIER 2
/obj/item/gun/ballistic/automatic/mp5
	name = "MP5 machinegun"
	desc = "Heckler Koch Mp5 является хоть и устаревшим, но невероятно сильным оружием в виду своей скорострельности. Какой идиот вообще подумал, что будет отличной идеей отобрать его у морпеха HECU?"
	icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "mp5"
	item_state = "mp5"
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/mp5/mpshot.ogg'
	mesa_muzzle_flash = TRUE
	mag_type = /obj/item/ammo_box/magazine/mp5
	load_sound = 'modular_bluemoon/sound/weapons/mesa/mp5/magin.ogg'
	load_empty_sound = 'modular_bluemoon/sound/weapons/mesa/mp5/magout.ogg'
	eject_sound = 'modular_bluemoon/sound/weapons/mesa/mp5/magout.ogg'
	eject_empty_sound = 'modular_bluemoon/sound/weapons/mesa/mp5/magout.ogg'
	can_suppress = FALSE
	weapon_weight = WEAPON_LIGHT
	w_class = WEIGHT_CLASS_BULKY
	spread = 9
	burst_size = 3
	burst_shot_delay = 2
	fire_delay = 0.5 ///Это пиздец!
	can_bayonet = FALSE
	automatic_burst_overlay = FALSE
	dynamic_sound_dry = 'modular_bluemoon/sound/weapons/mesa/mp5/dry1.ogg'
	dynamic_sound_tail = 'modular_bluemoon/sound/weapons/mesa/mp5/mpshot.ogg'
	dynamic_sound_volume = 50
	dynamic_sound_suppressed_volume = 10
	var/progressive_spread_enabled = TRUE
	var/progressive_spread_step = 1.5
	var/progressive_spread_max = 36
	var/progressive_spread_reset_delay = 3
	var/progressive_spread_current = 0
	var/progressive_spread_last_shot = 0

/obj/item/gun/ballistic/automatic/mp5/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
	if(!progressive_spread_enabled || on_cooldown() || !can_shoot())
		return ..()
	if(world.time > progressive_spread_last_shot + progressive_spread_reset_delay)
		progressive_spread_current = 0
	progressive_spread_current = min(progressive_spread_current + progressive_spread_step, progressive_spread_max)
	progressive_spread_last_shot = world.time
	var/base_spread = spread
	spread += progressive_spread_current
	. = ..()
	spread = base_spread

/obj/item/gun/ballistic/automatic/mp5/update_icon_state()
	if(magazine)
		icon_state = "mp5"
	else
		icon_state = "mp5nomag"

/obj/item/ammo_box/magazine/mp5
	name = "MP5 magazine (5.7mm)"
	desc = "Magazines taking 5.7mm ammunition; it fits in the MP5."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "mp5"
	ammo_type = /obj/item/ammo_casing/mm57
	caliber = "5.7mm"
	max_ammo = 30

/obj/item/ammo_box/magazine/mp5/update_icon()
	. = ..()
	if(ammo_count())
		icon_state = "[initial(icon_state)]-ammo"
	else
		icon_state = "[initial(icon_state)]"

// TIER 1
/obj/item/gun/ballistic/shotgun/m870
	name = "m870 shotgun"
	desc = "Remington 870 - это классический помповый дробовик, который был представлен компанией Remington Arms в 1950 году и до сих пор остается одним из самых популярных и продаваемых ружей в США."
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/m870shot.ogg'
	icon_state = "m870"
	item_state = "m870"
	w_class = WEIGHT_CLASS_BULKY
	recoil = 4
	attack_speed = 10
	force = 10
	fire_delay = 4
	mag_type = /obj/item/ammo_box/magazine/internal/shot/m870
	weapon_weight = WEAPON_HEAVY
	var/load_delay = 6
	var/recentload = 0
	var/pump_delay = 8
	var/load_sound_start = 'modular_bluemoon/sound/weapons/mesa/mossberg/ammostart.ogg'
	var/list/load_sounds_mid = list(
		'modular_bluemoon/sound/weapons/mesa/mossberg/ammomid.ogg',
		'modular_bluemoon/sound/weapons/mesa/mossberg/ammomid1.ogg',
		'modular_bluemoon/sound/weapons/mesa/mossberg/ammomid2.ogg'
	)
	var/load_sound_end = 'modular_bluemoon/sound/weapons/mesa/mossberg/ammostop.ogg'
	mesa_shotgun_bonus = TRUE
	mesa_melee_knockback = TRUE
	mesa_damage_bonus = 1.2

/obj/item/gun/ballistic/shotgun/m870/attack(mob/living/M, mob/user)
	. = ..()
	if(mesa_melee_knockback && istype(M, /mob/living))
		var/mob/living/victim = M
		var/knockback_dir = get_dir(src, victim)
		if(!knockback_dir)
			knockback_dir = user ? user.dir : dir
		var/throw_target = get_edge_target_turf(victim, knockback_dir)
		victim.safe_throw_at(throw_target, rand(1, 2), 1, user)

/obj/item/gun/ballistic/shotgun/m870/attack_self(mob/living/user)
	if(recentpump > world.time)
		return
	if(IS_STAMCRIT(user))
		to_chat(user, "<span class='warning'>You're too exhausted for that.</span>")
		return
	pump(user, TRUE)
	var/actual_delay = HAS_TRAIT(user, TRAIT_FAST_PUMP) ? round(pump_delay * 0.5) : pump_delay
	if(!HAS_TRAIT(user, TRAIT_FAST_PUMP))
		if(!user.UseStaminaBuffer(2, warn = TRUE))
			return
	recentpump = world.time + actual_delay
	user.DelayNextAction(actual_delay)

/obj/item/gun/ballistic/shotgun/m870/attackby(obj/item/A, mob/user, params)
	if(istype(A, /obj/item/ammo_box) || istype(A, /obj/item/ammo_casing))
		if(recentload > world.time)
			return
		if(!magazine)
			return
		if(magazine.ammo_count() >= magazine.max_ammo)
			to_chat(user, "<span class='warning'>[src] is full!</span>")
			return
		var/ammo_before = magazine.ammo_count()
		var/num_loaded = magazine.attackby(A, user, params, 1)
		if(num_loaded)
			recentload = world.time + load_delay
			if(user)
				user.DelayNextAction(load_delay)
			to_chat(user, "<span class='notice'>You load [num_loaded] shell\s into \the [src]!</span>")
			var/sound_to_play
			var/ammo_after = magazine.ammo_count()
			if(ammo_before == 0 && load_sound_start)
				sound_to_play = load_sound_start
			else if(ammo_after >= magazine.max_ammo && load_sound_end)
				sound_to_play = load_sound_end
			else if(load_sounds_mid && length(load_sounds_mid))
				sound_to_play = pick(load_sounds_mid)
			else
				sound_to_play = 'sound/weapons/shotguninsert.ogg'

			playsound(user, sound_to_play, 60, 1)
			A.update_icon()
			update_icon()
		return
	return ..()

/obj/item/ammo_box/magazine/internal/shot/m870
	name = "shotgun internal magazine"
	ammo_type = /obj/item/ammo_casing/shotgun/buckshot
	caliber = "shotgun"
	max_ammo = 4

// TIER 2
/obj/item/gun/ballistic/shotgun/spas
	name = "SPAS 12 shotgun"
	desc = "Этот невероятно старый и брутальный дробовик заставляет вас надеть балаклаву с горнолыжными очками."
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "spas"
	item_state = "spas"
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/spas.ogg'
	mesa_muzzle_flash = TRUE
	w_class = WEIGHT_CLASS_BULKY
	recoil = 3
	force = 10
	fire_delay = 4
	mag_type = /obj/item/ammo_box/magazine/internal/shot/spas
	pumpsound = 'modular_bluemoon/sound/weapons/mesa/shotgun_rack.ogg'
	weapon_weight = WEAPON_HEAVY
	var/stamina_drain_per_shot = 5
	var/load_delay = 5
	var/recentload = 0
	var/pump_delay = 5
	var/load_sound_start = 'modular_bluemoon/sound/weapons/mesa/mossberg/ammostart.ogg'
	var/list/load_sounds_mid = list(
		'modular_bluemoon/sound/weapons/mesa/mossberg/ammomid.ogg',
		'modular_bluemoon/sound/weapons/mesa/mossberg/ammomid1.ogg',
		'modular_bluemoon/sound/weapons/mesa/mossberg/ammomid2.ogg'
	)
	var/load_sound_end = 'modular_bluemoon/sound/weapons/mesa/mossberg/ammostop.ogg'
	mesa_shotgun_bonus = TRUE
	mesa_melee_knockback = TRUE
	mesa_damage_bonus = 1.2

/obj/item/gun/ballistic/shotgun/spas/attack(mob/living/M, mob/user)
	. = ..()
	if(mesa_melee_knockback && istype(M, /mob/living))
		var/mob/living/victim = M
		var/knockback_dir = get_dir(src, victim)
		if(!knockback_dir)
			knockback_dir = user ? user.dir : dir
		var/throw_target = get_edge_target_turf(victim, knockback_dir)
		victim.safe_throw_at(throw_target, rand(1, 2), 1, user)

/obj/item/gun/ballistic/shotgun/spas/attack_self(mob/living/user)
	if(recentpump > world.time)
		return
	if(IS_STAMCRIT(user))
		to_chat(user, "<span class='warning'>You're too exhausted for that.</span>")
		return
	pump(user, TRUE)
	var/actual_delay = HAS_TRAIT(user, TRAIT_FAST_PUMP) ? round(pump_delay * 0.5) : pump_delay
	if(!HAS_TRAIT(user, TRAIT_FAST_PUMP))
		if(!user.UseStaminaBuffer(2, warn = TRUE))
			return
	recentpump = world.time + actual_delay
	user.DelayNextAction(actual_delay)

/obj/item/gun/ballistic/shotgun/spas/attackby(obj/item/A, mob/user, params)
	if(istype(A, /obj/item/ammo_box) || istype(A, /obj/item/ammo_casing))
		if(recentload > world.time)
			return
		if(!magazine)
			return
		if(magazine.ammo_count() >= magazine.max_ammo)
			to_chat(user, "<span class='warning'>[src] is full!</span>")
			return
		var/ammo_before = magazine.ammo_count()
		var/num_loaded = magazine.attackby(A, user, params, 1)
		if(num_loaded)
			recentload = world.time + load_delay
			if(user)
				user.DelayNextAction(load_delay)
			to_chat(user, "<span class='notice'>You load [num_loaded] shell\s into \the [src]!</span>")
			var/sound_to_play
			var/ammo_after = magazine.ammo_count()
			if(ammo_before == 0 && load_sound_start)
				sound_to_play = load_sound_start
			else if(ammo_after >= magazine.max_ammo && load_sound_end)
				sound_to_play = load_sound_end
			else if(load_sounds_mid && length(load_sounds_mid))
				sound_to_play = pick(load_sounds_mid)
			else
				sound_to_play = 'sound/weapons/shotguninsert.ogg'

			playsound(user, sound_to_play, 60, 1)
			A.update_icon()
			update_icon()
		return
	return ..()

/obj/item/ammo_box/magazine/internal/shot/spas
	name = "shotgun internal magazine"
	ammo_type = /obj/item/ammo_casing/shotgun/buckshot
	caliber = "shotgun"
	max_ammo = 8


/obj/item/gun/ballistic/shotgun/m500
	name = "mossberg 500 shotgun"
	desc = "«Моссберг-500» — семейство многозарядных ружей США, что сейчас выпускается в различных модификациях, предназначенных как для охоты, так и для полиции, охранников и самообороны."
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/mossberg/m500.ogg'
	pumpsound = 'modular_bluemoon/sound/weapons/mesa/mossberg/rack.ogg'
	icon_state = "m500"
	item_state = "m500"
	w_class = WEIGHT_CLASS_BULKY
	recoil = 3
	attack_speed = 8
	force = 8
	fire_delay = 3
	mag_type = /obj/item/ammo_box/magazine/internal/shot/m500
	weapon_weight = WEAPON_HEAVY
	var/load_delay = 4
	var/recentload = 0
	var/pump_delay = 4
	var/load_sound_start = 'modular_bluemoon/sound/weapons/mesa/mossberg/ammostart.ogg'
	var/list/load_sounds_mid = list(
		'modular_bluemoon/sound/weapons/mesa/mossberg/ammomid.ogg',
		'modular_bluemoon/sound/weapons/mesa/mossberg/ammomid1.ogg',
		'modular_bluemoon/sound/weapons/mesa/mossberg/ammomid2.ogg'
	)
	var/load_sound_end = 'modular_bluemoon/sound/weapons/mesa/mossberg/ammostop.ogg'
	mesa_shotgun_bonus = TRUE
	mesa_melee_knockback = TRUE
	mesa_damage_bonus = 1.2

/obj/item/gun/ballistic/shotgun/m500/attack(mob/living/M, mob/user)
	. = ..()
	if(mesa_melee_knockback && istype(M, /mob/living))
		var/mob/living/victim = M
		var/knockback_dir = get_dir(src, victim)
		if(!knockback_dir)
			knockback_dir = user ? user.dir : dir
		var/throw_target = get_edge_target_turf(victim, knockback_dir)
		victim.safe_throw_at(throw_target, rand(1, 2), 1, user)

/obj/item/gun/ballistic/shotgun/m500/attack_self(mob/living/user)
	if(recentpump > world.time)
		return
	if(IS_STAMCRIT(user))
		to_chat(user, "<span class='warning'>You're too exhausted for that.</span>")
		return
	pump(user, TRUE)
	var/actual_delay = HAS_TRAIT(user, TRAIT_FAST_PUMP) ? round(pump_delay * 0.5) : pump_delay
	if(!HAS_TRAIT(user, TRAIT_FAST_PUMP))
		if(!user.UseStaminaBuffer(2, warn = TRUE))
			return
	recentpump = world.time + actual_delay
	user.DelayNextAction(actual_delay)

/obj/item/gun/ballistic/shotgun/m500/attackby(obj/item/A, mob/user, params)
	if(istype(A, /obj/item/ammo_box) || istype(A, /obj/item/ammo_casing))
		if(recentload > world.time)
			return
		if(!magazine)
			return
		if(magazine.ammo_count() >= magazine.max_ammo)
			to_chat(user, "<span class='warning'>[src] is full!</span>")
			return
		var/ammo_before = magazine.ammo_count()
		var/num_loaded = magazine.attackby(A, user, params, 1)
		if(num_loaded)
			recentload = world.time + load_delay
			if(user)
				user.DelayNextAction(load_delay)
			to_chat(user, "<span class='notice'>You load [num_loaded] shell\s into \the [src]!</span>")
			var/sound_to_play
			var/ammo_after = magazine.ammo_count()
			if(ammo_before == 0 && load_sound_start)
				sound_to_play = load_sound_start
			else if(ammo_after >= magazine.max_ammo && load_sound_end)
				sound_to_play = load_sound_end
			else if(load_sounds_mid && length(load_sounds_mid))
				sound_to_play = pick(load_sounds_mid)
			else
				sound_to_play = 'sound/weapons/shotguninsert.ogg'

			playsound(user, sound_to_play, 60, 1)
			A.update_icon()
			update_icon()
		return
	return ..()

/obj/item/ammo_box/magazine/internal/shot/m500
	name = "shotgun internal magazine"
	ammo_type = /obj/item/ammo_casing/shotgun/buckshot
	caliber = "shotgun"
	max_ammo = 9


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
	mesa_muzzle_flash = TRUE
	pin = /obj/item/firing_pin

// TIER 3
/obj/item/gun/ballistic/automatic/m16a4/mesa
	name = "\improper old M16 rifle"
	desc = "Невероятно старая версия М16 с сломанным подствольным гранатомётом и... Большей отдачей что-ли? Держа её в руках, вы чувствуете странные ощущения... Да и отряды HECU с таким замечены не были"
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	icon_state = "m16hl"
	burst_size = 1
	fire_delay = 1 //ATATATATATATATATA!!!
	spread = 11
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/m16.ogg'
	mesa_muzzle_flash = TRUE
	mag_type = /obj/item/ammo_box/magazine/m16/mesa
	obj_flags = UNIQUE_RENAME
	unique_reskin = list(
		"Default" = list("icon_state" = "m16hl"),
		"Alternative" = list("icon_state" = "m16hl_alt")
	)

/obj/item/gun/ballistic/automatic/m16a4/mesa/Initialize(mapload)
	gun_light = new /obj/item/flashlight/seclite(src)
	return ..()


/obj/item/gun/ballistic/automatic/m16a4/mesa/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	if(!user)
		return
	. = ..(user, pointblank, pbtarget, message, stam_cost)

//  пульки

/obj/item/ammo_box/magazine/m16/mesa
	icon = 'modular_bluemoon/phenyamomota/icon/obj/guns/ammo.dmi'
	icon_state = "m16e"
	ammo_type = /obj/item/ammo_casing/a556hl
	caliber = "a556"
	max_ammo = 50

/obj/item/ammo_box/magazine/m16/mesa/update_icon()
	. = ..()
	if(ammo_count())
		icon_state = "[initial(icon_state)]"
	else
		icon_state = "[initial(icon_state)]-0"

/obj/item/ammo_casing/a556hl
	name = "5.56mm bullet casing"
	desc = "A 5.56mm bullet casing."
	caliber = "a556"
	projectile_type = /obj/item/projectile/bullet/a556hl


/obj/item/projectile/bullet/a556hl
	damage = 15
	armour_penetration = 10
	wound_bonus = 0.5

/obj/item/projectile/bullet/a556hl/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!target)
		return
	if(istype(target, /mob/living/simple_animal))
		var/mob/living/simple_animal/SA = target
		if(!SA)
			return
		SA.apply_damage(15, BRUTE)

//пули. Хз зачем решил их обозначить так.

/obj/item/gun/ballistic/automatic/m16a4/mesa/update_icon_state()
	if(current_skin)
		icon_state = "[unique_reskin[current_skin]["icon_state"]][magazine ? "" : "-e"]"
	else
		icon_state = "[initial(icon_state)][magazine ? "" : "-e"]"

// TIER 1

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
	mesa_muzzle_flash = TRUE
	weapon_weight = WEAPON_LIGHT
	mag_type = /obj/item/ammo_box/magazine/mp7

/obj/item/gun/ballistic/automatic/mp7/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : ""]"
	if(magazine)
		icon_state = "mp7"
	else
		icon_state = "mp7nomag"

/obj/item/gun/ballistic/automatic/mp7/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	..()
	playsound(user, fire_sound, 80, 0, 0)


// тоже пули

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

// 5mm/4.6mm мини-патроны — BR0/BR1
/obj/item/projectile/bullet/mm46
	name = "4.6mm bullet"
	damage = 10
	armour_penetration = BULLET_BR0   // BLUEMOON EDIT: было 3 → BR0 (слишком мелкий)
	wound_bonus = -3
	bare_wound_bonus = 1

/obj/item/projectile/bullet/mm46/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!target)
		return
	if(istype(target, /mob/living/simple_animal))
		var/mob/living/simple_animal/SA = target
		if(!SA)
			return
		SA.apply_damage(10, BRUTE)
// конец пулек

// TIER 3
/obj/item/gun/ballistic/automatic/scar
	name = "\improper HC scar"
	desc = "Модифицированная версия FN Scar, предназначенная для ведения стрельбы на средние и дальние дистанции. В отличие от M4oa1, имеет автоматический режим стрельбы и менее убойный калибр + крутой песчаный камуфляж (Но вы же помните то, что орудуете только в научном комплексе?)"
	icon = 'modular_bluemoon/icons/obj/guns/Machineguns.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "scarh"
	item_state = "scar"
	fire_delay = 2
	spread = 10
	burst_size = 3
	fire_sound = 'modular_bluemoon/sound/weapons/mesa/scar.ogg'
	mesa_muzzle_flash = TRUE
	weapon_weight = WEAPON_HEAVY
	w_class = WEIGHT_CLASS_BULKY
	mag_type = /obj/item/ammo_box/magazine/scar

/obj/item/gun/ballistic/automatic/scar/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : ""]"
	if(magazine)
		icon_state = "scarh"
	else
		icon_state = "scarh-e"

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

// 7.62mm мини (не путать с x39) — BR1
/obj/item/projectile/bullet/mm762
	name = "7.62mm bullet"
	damage = 25
	armour_penetration = BULLET_BR1   // BLUEMOON EDIT: было 4 → BR1
	wound_bonus = -6
	bare_wound_bonus = 5

// TIER 2
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
	mesa_muzzle_flash = TRUE
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
	damage = 20
	armour_penetration = BULLET_BR1   // BLUEMOON EDIT: было 4 → BR1 (5.7мм аналог FN57)
	wound_bonus = -4
	bare_wound_bonus = 2

//tier 2
/obj/item/gun/ballistic/revolver/hltaurus
	name = "\improper taurus revolver"
	desc = "Тaurus Model 85 является компактным револьвером, который был разработан бразильской компанией Taurus International. Он предназначен для скрытого ношения и самообороны, и является популярным выбором среди гражданских лиц и правоохранительных органов. Данный экземпляр может похвастаться модифицированным барабаном на 4 выстрела калибром .357"
	icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi'
	icon_state = "taurus"
	mesa_muzzle_flash = TRUE
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/rev357/taurus
	fire_delay = 3

/obj/item/ammo_box/magazine/internal/cylinder/rev357/taurus
	max_ammo = 4

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

//leader

/obj/item/choice_beacon/mesaleader
	name = "leader type choice beacon"
	desc = "Secret USA army technology. Select your primary weapon."

/obj/item/choice_beacon/mesaleader/generate_display_names()
	var/static/list/leader_item_list
	if(!leader_item_list)
		leader_item_list = list()
		var/list/templist = typesof(/obj/item/storage/box/basedleader)
		for(var/V in templist)
			var/atom/A = V
			leader_item_list[initial(A.name)] = A
	return leader_item_list

/obj/item/storage/box/basedleader
	name = "RSH-12 revolver kit"

/obj/item/storage/box/basedleader/PopulateContents()
	new /obj/item/gun/ballistic/revolver/hlrsh12(src)
	new /obj/item/ammo_box/hlrsh12(src)
	new /obj/item/ammo_box/hlrsh12(src)

/obj/item/storage/box/basedleader/deagle
	name = "Desert Eagle handgun kit"

/obj/item/storage/box/basedleader/deagle/PopulateContents()
	new /obj/item/gun/ballistic/automatic/pistol/deagle/hl(src)
	new /obj/item/ammo_box/magazine/m50(src)
	new /obj/item/ammo_box/magazine/m50(src)
	new /obj/item/ammo_box/magazine/m50(src)

/obj/item/storage/box/basedleader/hl357
	name = ".357 pyton revolver kit"

/obj/item/storage/box/basedleader/hl357/PopulateContents()
	new /obj/item/gun/ballistic/revolver/mateba/hl357(src)
	new /obj/item/ammo_box/a357(src)
	new /obj/item/ammo_box/a357(src)

/obj/item/shield/police
	name = "special police shield"
	desc = "A gigantic shield made of robust materials"
	icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/weapons_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/weapons_righthand.dmi'
	icon_state = "policeshield"
	item_state = "policeshield"
	w_class = WEIGHT_CLASS_HUGE
	armor = list(MELEE = 60, BULLET = 70, LASER = 50, ENERGY = 0, BOMB = 40, BIO = 0, RAD = 0, FIRE = 80, ACID = 70)
	slot_flags = ITEM_SLOT_BACK
	block_chance = 80
	shieldbash_knockback = 5
	force = 15
	throw_range = 1
	throw_speed = 2
	attack_verb = list("bashed","pounded","slammed")
	item_flags = SLOWS_WHILE_IN_HAND
	w_class = WEIGHT_CLASS_GIGANTIC
	var/durability = 30

/obj/item/shield/police/on_shield_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance)
	durability--
	if(durability <= 0)
		if(owner)
			owner.visible_message("<span class='warning'>[src] breaks apart!</span>")
			playsound(owner, 'sound/effects/bang.ogg', 50, 1)
		qdel(src)
		return TRUE

	var/static/list/shield_sounds = list(
		'modular_bluemoon/sound/weapons/shield/ric1.ogg',
		'modular_bluemoon/sound/weapons/shield/ric2.ogg',
		'modular_bluemoon/sound/weapons/shield/ric3.ogg',
		'modular_bluemoon/sound/weapons/shield/ric5.ogg'
	)
	playsound(owner, pick(shield_sounds), 50, 1)
	return ..()

// TIER 4
/obj/item/gun/ballistic/revolver/hlrsh12
	name = "RSH-12 revolver"
	desc = "Противник даже слова сказать не успеет. Это прототип РШ12 который можно зарядить картечью. С этого дерьма даже стрелять опасно!"
	icon_state = "rs12"
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	fire_sound = 'modular_bluemoon/sound/weapons/rsh.ogg'
	mesa_muzzle_flash = TRUE
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/hlrsh12
	recoil = 6
	fire_delay = 4

/obj/item/gun/ballistic/revolver/hlrsh12/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	var/result = ..(user, pointblank, pbtarget, message, 35)
	if(isliving(user))
		user.apply_damage(4, BURN, BODY_ZONE_PRECISE_L_HAND)
		user.apply_damage(4, BURN, BODY_ZONE_PRECISE_R_HAND)
		user.adjustStaminaLoss(20)
		if(prob(30))
			user.adjustEarDamage(0, 20)
	return result

/obj/item/ammo_box/magazine/internal/cylinder/hlrsh12
	name = "RS-12 revolver cylinder"
	ammo_type = /obj/item/ammo_casing/hlrsh12
	caliber = list("rs12", "shotgun")
	max_ammo = 6
	multiload = 0

/obj/item/ammo_casing/hlrsh12
	name = "RS-12 bullet casing"
	desc = "An RS-12 bullet casing."
	caliber = "rs12"
	projectile_type = /obj/item/projectile/bullet/hlrsh12

/obj/item/projectile/bullet/hlrsh12
	name = "RS-12 bullet"
	damage = 70
	armour_penetration = 6
	wound_bonus = -8
	bare_wound_bonus = 8
	stamina = 55

/obj/item/ammo_box/hlrsh12
	name = "speedloader (RS-12)"
	desc = "A speedloader for RS-12 revolvers. Reloads quickly with pre-loaded ammunition."
	icon_state = "357"
	ammo_type = /obj/item/ammo_casing/hlrsh12
	caliber = "rs12"
	max_ammo = 6
	speedloader = TRUE
	multiple_sprites = 1

// TIER 3
/obj/item/gun/ballistic/automatic/pistol/deagle/hl
	name = "Desert Eagle handgun"
	desc = "Карманная артиллерия прямо у вас в руках. пустынный орёл способен пробивать бронежилеты большинства стандартных образцов, что делает его идеальным выбором для лидеров отрядов HECU"
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	icon_state = "hldeagle"
	mesa_muzzle_flash = TRUE
	w_class = WEIGHT_CLASS_NORMAL
	can_suppress = FALSE
	burst_size = 1
	spread = 5
	fire_delay = 6
	can_flashlight = 0
	unique_reskin = FALSE

/obj/item/gun/ballistic/automatic/pistol/deagle/hl/update_overlays()
	. = ..()
	if(magazine)
		. += "hldeagle"

/obj/item/gun/ballistic/automatic/pistol/deagle/hl/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "_mag"]"

// TIER 3
/obj/item/gun/ballistic/revolver/mateba/hl357
	name = "\improper .357 revolver"
	desc = "Достаточно неплохого калибра револьвер, специально выбранный для быстрого устранения... Крупной дичи"
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	icon_state = "hl357"
	mesa_muzzle_flash = TRUE
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/rev357
/obj/item/ammo_box/magazine/internal/cylinder/rev357
	name = "revolver cylinder (.357)"
	desc = "A revolver cylinder chambered for .357 Magnum rounds."
	caliber = list("357")
	ammo_type = /obj/item/ammo_casing/a357
	max_ammo = 6

// TIER 4
/obj/item/gun/ballistic/automatic/m249
	name = "M249 SAW"
	desc = "FN M249 Squad Automatic Weapon - лёгкий пулемёт, предназначенный для обеспечения огневой поддержки отделения. Обычно используется с 100-патронной лентой. Имеет сошки для улучшения точности при стрельбе лёжа."
	icon = 'modular_bluemoon/icons/obj/guns/Machineguns.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/left48x32.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/right48x32.dmi'
	icon_state = "m249"
	item_state = "m249"
	fire_sound = 'modular_bluemoon/sound/weapons/m249.ogg'
	mesa_muzzle_flash = TRUE
	mag_type = /obj/item/ammo_box/magazine/m249
	w_class = WEIGHT_CLASS_BULKY
	weapon_weight = WEAPON_HEAVY
	recoil = 1
	spread = 6
	burst_size = 3
	burst_shot_delay = 3
	fire_delay = 1.5
	can_suppress = FALSE
	can_bayonet = FALSE
	slot_flags = ITEM_SLOT_BACK
	automatic_burst_overlay = FALSE
	actions_types = list(/datum/action/item_action/deploy_bipod)
	var/cover_open = FALSE
	slowdown = 1.0
	item_flags = SLOWS_WHILE_IN_HAND

	var/bipod_deployed = FALSE
	var/heat_accumulated = 0
	var/max_heat = 20
	var/overheated = FALSE
	var/overheat_cooldown_end = 0
	var/last_fire_time = 0
	var/initial_spread = 6
	var/bipod_spread = 1
	var/no_bipod_spread = 15
	var/stamina_drain_per_shot = 5
	var/heat_cooldown_rate = 1.5
	var/heat_gain_per_shot = 1
	var/last_bipod_turf = null


/obj/item/gun/ballistic/automatic/m249/examine(mob/user)
	. = ..()
	if(cover_open && magazine)
		. += "<span class='notice'>It seems like you could use an <b>empty hand</b> to remove the magazine.</span>"
	if(bipod_deployed)
		. += "<span class='notice'>Сошки разложены. Разброс минимален, стамина не тратится.</span>"
	else
		. += "<span class='notice'>Сошки сложены. Высокий разброс, тратится стамина при стрельбе.</span>"
	if(overheated)
		. += "<span class='warning'>Пулемёт перегрет! Ожидайте остывания.</span>"
	else if(heat_accumulated > 0)
		. += "<span class='warning'>Нагрев: [round(heat_accumulated, 0.1)]/[max_heat]</span>"

/obj/item/gun/ballistic/automatic/m249/attack_self(mob/user)
	cover_open = !cover_open
	to_chat(user, "<span class='notice'>You [cover_open ? "open" : "close"] [src]'s cover.</span>")
	if(cover_open)
		playsound(user, 'sound/weapons/sawopen.ogg', 60, 1)
	else
		playsound(user, 'sound/weapons/sawclose.ogg', 60, 1)
	update_icon()

/obj/item/gun/ballistic/automatic/m249/ui_action_click(mob/user, actiontype)
	if(istype(actiontype, /datum/action/item_action/deploy_bipod))
		toggle_bipod(user)
	else
		..()

/obj/item/gun/ballistic/automatic/m249/can_shoot()
	if(overheated)
		var/mob/living/user = loc
		if(user && ismob(user))
			to_chat(user, "<span class='warning'>[src] перегрет! Подождите пока остынет.</span>")
		return FALSE
	return get_ammo()

/obj/item/gun/ballistic/automatic/m249/proc/toggle_bipod(mob/living/user)
	if(!user)
		return
	if(bipod_deployed)
		collapse_bipod(user)
	else
		deploy_bipod(user)

/obj/item/gun/ballistic/automatic/m249/proc/deploy_bipod(mob/living/user)
	if(!user)
		return
	if(user.mobility_flags & MOBILITY_STAND)
		to_chat(user, "<span class='warning'>Вы должны лежать, чтобы разложить сошки!</span>")
		return
	bipod_deployed = TRUE
	spread = bipod_spread
	last_bipod_turf = get_turf(user)
	to_chat(user, "<span class='notice'>Вы разложили сошки [src]. Разброс уменьшен.</span>")
	playsound(user, 'sound/weapons/sawopen.ogg', 50, 1)
	update_icon()

/obj/item/gun/ballistic/automatic/m249/proc/collapse_bipod(mob/living/user)
	if(!user)
		return
	bipod_deployed = FALSE
	spread = no_bipod_spread
	last_bipod_turf = null
	if(user)
		to_chat(user, "<span class='notice'>Вы сложили сошки [src].</span>")
	playsound(user, 'sound/weapons/sawclose.ogg', 50, 1)
	update_icon()

/obj/item/gun/ballistic/automatic/m249/proc/check_bipod_stability()
	if(!bipod_deployed)
		return
	var/mob/living/user = loc
	if(!user || !ismob(user))
		collapse_bipod()
		return
	if(user.mobility_flags & MOBILITY_STAND)
		collapse_bipod(user)
		if(user)
			to_chat(user, "<span class='warning'>Вы встали и сошки сложились!</span>")
		return
	var/current_turf = get_turf(user)
	if(current_turf != last_bipod_turf)
		collapse_bipod(user)
		if(user)
			to_chat(user, "<span class='warning'>Вы переместились и сошки сложились!</span>")
		return

/obj/item/gun/ballistic/automatic/m249/update_icon_state()
	var/ammo_state = ""
	if(!magazine)
		ammo_state = "_nomag_empty"
	else if(get_ammo(0) <= 0)
		ammo_state = "_empty"
	icon_state = "m249[cover_open ? "_panel" : ""][ammo_state]"

/obj/item/gun/ballistic/automatic/m249/afterattack(atom/target as mob|obj|turf, mob/living/user as mob|obj, flag, params)
	if(cover_open)
		to_chat(user, "<span class='warning'>[src]'s cover is open! Close it before firing!</span>")
		return
	if(overheated)
		to_chat(user, "<span class='warning'>[src] перегрет! Подождите пока остынет.</span>")
		return
	check_bipod_stability()
	. = ..()
	update_icon()

/obj/item/gun/ballistic/automatic/m249/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(loc != user)
		..()
		return
	if(!cover_open || (cover_open && !magazine))
		..()
	else if(cover_open && magazine)
		magazine.update_icon()
		magazine.forceMove(drop_location())
		user.put_in_hands(magazine)
		magazine = null
		update_icon()
		to_chat(user, "<span class='notice'>You remove the magazine from [src].</span>")
		playsound(user, 'sound/weapons/magout.ogg', 60, 1)

/obj/item/gun/ballistic/automatic/m249/attackby(obj/item/A, mob/user, params)
	if(!cover_open && istype(A, mag_type))
		to_chat(user, "<span class='warning'>[src]'s cover is closed! You can't insert a new mag.</span>")
		return
	..()
	update_icon()

/obj/item/gun/ballistic/automatic/m249/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	if(!user)
		return
	if(overheated)
		to_chat(user, "<span class='warning'>[src] перегрет! Подождите пока остынет.</span>")
		return
	process_heat_cooldown()
	if(heat_accumulated >= max_heat)
		overheated = TRUE
		overheat_cooldown_end = world.time + 50
		user.balloon_alert(user, "Пулемёт сильно нагрелся и заклинил!")
		playsound(src, 'sound/effects/smoke.ogg', 50, 1)
		return
	heat_accumulated += heat_gain_per_shot
	last_fire_time = world.time
	if(heat_accumulated >= 10 && heat_accumulated < 11)
		user.balloon_alert(user, "Дуло пулемёта начинает дымиться!")
	if(heat_accumulated >= (max_heat * 0.8) && heat_accumulated < (max_heat * 0.8) + 1)
		user.balloon_alert(user, "Пулемёт сильно нагревается!")
	if(!bipod_deployed)
		user.adjustStaminaLoss(stamina_drain_per_shot)
	. = ..(user, pointblank, pbtarget, message, stam_cost)

/obj/item/gun/ballistic/automatic/m249/proc/process_heat_cooldown()
	if(overheated && world.time >= overheat_cooldown_end)
		overheated = FALSE
		heat_accumulated = 0
		if(loc && ismob(loc))
			var/mob/living/user = loc
			user.balloon_alert(user, "Пулемёт остыл!")
		return
	if(heat_accumulated <= 0)
		return
	var/time_since_last_fire = world.time - last_fire_time
	if(time_since_last_fire >= 20)
		var/cooling_amount = heat_cooldown_rate * (time_since_last_fire / 10)
		heat_accumulated = max(0, heat_accumulated - cooling_amount)
		if(heat_accumulated <= 0 && !overheated)
			heat_accumulated = 0

/obj/item/gun/ballistic/automatic/m249/Initialize(mapload)
	. = ..()
	spread = no_bipod_spread
	START_PROCESSING(SSobj, src)

/obj/item/gun/ballistic/automatic/m249/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/gun/ballistic/automatic/m249/process()
	process_heat_cooldown()
	check_bipod_stability()

/obj/item/gun/ballistic/automatic/m249/pickup(mob/user)
	. = ..()
	if(bipod_deployed)
		collapse_bipod(user)
	if(istype(user, /mob/living))
		RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_mob_move))
		RegisterSignal(user, COMSIG_LIVING_RESTING, PROC_REF(on_mob_rest))

/obj/item/gun/ballistic/automatic/m249/dropped(mob/user)
	. = ..()
	if(bipod_deployed)
		collapse_bipod(user)
	if(istype(user, /mob/living))
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
		UnregisterSignal(user, COMSIG_LIVING_RESTING)

/obj/item/gun/ballistic/automatic/m249/proc/on_mob_move(atom/old_loc, dir)
	SIGNAL_HANDLER
	if(!bipod_deployed)
		return
	var/mob/living/user = loc
	if(!user)
		return
	collapse_bipod(user)
	to_chat(user, "<span class='warning'>Вы переместились и сошки сложились!</span>")

/obj/item/gun/ballistic/automatic/m249/proc/on_mob_rest(mob/living/source, new_resting)
	SIGNAL_HANDLER
	if(!bipod_deployed)
		return
	var/mob/living/user = loc
	if(!user || !ismob(user))
		return
	if(!new_resting)
		collapse_bipod(user)
		to_chat(user, "<span class='warning'>Вы встали и сошки сложились!</span>")

/obj/item/ammo_box/magazine/m249
	name = "M249 ammo belt (5.56mm)"
	desc = "100-патронная лента для M249 SAW. Содержит стандартные 5.56x45mm НАТО патроны."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "m249"
	ammo_type = /obj/item/ammo_casing/a556
	max_ammo = 100
	caliber = "a556"

/obj/item/ammo_box/magazine/m249/update_icon()
	. = ..()
	if(ammo_count())
		icon_state = "[initial(icon_state)]-ammo"
	else
		icon_state = "[initial(icon_state)]"

/datum/action/item_action/deploy_bipod
	name = "Разложить/Сложить сошки"
	desc = "Разложить сошки для улучшения точности (только лёжа)"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "activate"
	background_icon_state = "storage_gather_switch"
	required_mobility_flags = NONE
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS

/obj/item/clothing/neck/tie/hecudogtag
	name = "HECU Dogtag"
	desc = "Военные жетоны солдата HECU. На них выбиты имя, фамилия и группа крови."
	icon = 'modular_bluemoon/icons/obj/clothing/skihellclothes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "dogtag"
	item_state = "dogtag"

/obj/item/clothing/head/machinegunner
	name = "machinegunner bandana"
	desc = "A fine bandana with nanotech lining, perfect for a heavy weapons specialist."
	icon_state = "machinegunner"
	item_state = "machinegunner"
	icon = 'modular_bluemoon/icons/obj/clothing/skihellclothes.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	alternate_worn_layer = null
