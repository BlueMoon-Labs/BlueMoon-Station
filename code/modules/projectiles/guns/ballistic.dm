/obj/item/gun/ballistic
	desc = "Now comes in flavors like GUN. Uses 10mm ammo, for some reason."
	name = "projectile gun"
	icon_state = "pistol"
	w_class = WEIGHT_CLASS_NORMAL
	recoil = 0.25
	reskin_binding = COMSIG_CLICK_ALT
	var/spawnwithmagazine = TRUE
	var/mag_type = /obj/item/ammo_box/magazine/m10mm //Removes the need for max_ammo and caliber info
	var/obj/item/ammo_box/magazine/magazine
	var/casing_ejector = TRUE //whether the gun ejects the chambered casing
	var/magazine_wording = "magazine"
	var/sawn_icon_state = "gun"
	var/sawn_item_state = "gun" //смена модельки оружия от третьего лица при обрезании ствола. ПОНЯТИЯ ИНВЕРТИРОВАНЫ, РАНЬШЕ БЫЛ ТОЛЬКО SAWN_ITEM_STATE, ЧТО МЕНЯЛ ИКОНКУ -RaizlenW
	/// Можно ли сменить магазин, пока внутри есть другой
	var/tactical_reload = FALSE
	var/load_sound = SFX_GUN_INSERT_FULL_MAGAZINE
	var/load_empty_sound = SFX_GUN_INSERT_EMPTY_MAGAZINE
	var/unlock_sound = SFX_GUN_SLIDE_LOCK
	var/eject_sound = 'sound/weapons/gun_magazine_remove_full.ogg'
	var/eject_empty_sound = SFX_GUN_REMOVE_EMPTY_MAGAZINE
	var/lock_back_sound ='sound/weapons/gun_chamber_round.ogg'
	var/base_w_class = null //Защита от того, что если другая система заменит вес предмета, то игра будет знать оригинальный. Это универсальный скрипт -RaizlenW

/obj/item/gun/ballistic/Initialize(mapload)
	. = ..()
	if(!default_fire_sound)
		default_fire_sound = fire_sound
	if(isnull(base_w_class))
		base_w_class = w_class
	if(!spawnwithmagazine)
		update_icon()
		return
	if(!magazine)
		magazine = new mag_type(src)
	chamber_round()
	update_icon()

/obj/item/gun/ballistic/update_icon_state()
	if(current_skin)
		icon_state = "[unique_reskin[current_skin]["icon_state"]][suppressed ? "-suppressed" : ""][sawn_off ? "-sawn" : ""]"
	else
		icon_state = "[initial(icon_state)][suppressed ? "-suppressed" : ""][sawn_off ? "-sawn" : ""]"

/obj/item/gun/ballistic/process_chamber(mob/living/user, empty_chamber = 1)
	var/obj/item/ammo_casing/AC = chambered //Find chambered round
	if(istype(AC)) //there's a chambered round
		if(casing_ejector)
			AC.forceMove(drop_location()) //Eject casing onto ground.
			AC.bounce_away(TRUE)
			chambered = null
		else if(empty_chamber)
			chambered = null
	chamber_round()


/obj/item/gun/ballistic/proc/chamber_round()
	if (chambered || !magazine)
		return
	else if (magazine.ammo_count())
		chambered = magazine.get_round()
		chambered.forceMove(src)

/obj/item/gun/ballistic/can_shoot()
	if(!magazine || !magazine.ammo_count(0))
		return FALSE
	return TRUE

/obj/item/gun/ballistic/attackby(obj/item/A, mob/user, params)
	..()

	if(istype(A, /obj/item/ammo_box/magazine))
		return insert_mag(A, user)
	if(istype(A, /obj/item/suppressor))
		var/obj/item/suppressor/S = A
		if(!can_attach_suppressor(S, user))
			if(sawn_off)
				to_chat(user, span_warning("Вы не можете установить глушитель на [src], потому что резьба для [S] отсутсвует!"))
				return
			else if(suppressed)
				to_chat(user, span_warning("[src] уже имеет установленный глушитель!"))
			else if(bayonet && !can_mount_both)
				to_chat(user, span_warning("Вы не можете установить штык-нож одновременно с глушителем на [src]!"))
			else
				to_chat(user, span_warning("Вы не можете разобраться как установить [S] на [src]!"))
			return
		if(!user.is_holding(src))
			to_chat(user, span_notice("Нужно держать [src] в руках, чтобы установить [S]!"))
			return
		if(user.transferItemToLoc(A, src))
			to_chat(user, span_notice("Вы накручиваете глушитель [S] на [src]."))
			install_suppressor(S)
			return TRUE
	return FALSE

/obj/item/gun/ballistic/proc/insert_mag(obj/item/ammo_box/magazine/AM, mob/user)
	if(!istype(AM, mag_type))
		return
	if(!magazine || tactical_reload)
		var/obj/item/ammo_box/magazine/oldmag = magazine
		if(user.transferItemToLoc(AM, src))
			magazine = AM
			if(oldmag)
				to_chat(user, span_notice("Вы совершаете тактическую перезарядку с [src], заменяя [magazine_wording]."))
				user.put_in_hands(oldmag)
				oldmag.update_icon()
			else
				to_chat(user, span_notice("Вы загружаете свежий [magazine_wording] в [src]."))
			if(magazine.ammo_count())
				playsound(src, load_sound, 70, 1)
				if(!chambered)
					chamber_round()
					if(lock_back_sound)
						addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), src, lock_back_sound, 100, 1), 3)
			else
				playsound(src, load_empty_sound, 70, 1)
			magazine.update_icon()
			update_icon()
			if(user.is_holding(src))
				user.update_inv_hands()
			return TRUE
		else
			to_chat(user, span_warning("Вы не можете разобраться как убрать [src] из рук!"))
			return
	else
		to_chat(user, span_notice("[magazine_wording] уже находится в [src]."))

/obj/item/gun/ballistic/proc/on_suppressor_installed(obj/item/suppressor/S)
    w_class = base_w_class + S.w_class

/obj/item/gun/ballistic/proc/on_suppressor_removed(obj/item/suppressor/S)
    w_class = base_w_class

/obj/item/gun/ballistic/proc/install_suppressor(obj/item/suppressor/S)
	// this proc assumes that the suppressor is already inside src
    suppressed = S
    fire_sound = suppressed_fire_sound
    on_suppressor_installed(S)
    update_icon()

/obj/item/gun/ballistic/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
    if(loc == user)
        if(suppressed && can_unsuppress)
            var/obj/item/suppressor/S = suppressed
            if(!user.is_holding(src))
                return ..()
            to_chat(user, "<span class='notice'>Вы откручиваете [suppressed] от [src].</span>")
            user.put_in_hands(suppressed)
            fire_sound = default_fire_sound //Кэширование оригинального звука выстрела для исключения багов в будущем -RaizlenW
            on_suppressor_removed(S)
            suppressed = null
            update_icon()
            return

    return ..()

/obj/item/gun/ballistic/attack_self(mob/living/user)
	var/obj/item/ammo_casing/AC = chambered //Find chambered round
	if(magazine)
		magazine.forceMove(drop_location())
		user.put_in_hands(magazine)
		magazine.update_icon()
		if(magazine.ammo_count())
			playsound(src, eject_sound, 70, 1)
		else
			playsound(src, eject_empty_sound, 70, 1)
		magazine = null
		to_chat(user, "<span class='notice'>Вы вытаскиваете магазин из [src].</span>")
	else if(chambered)
		AC.forceMove(drop_location())
		AC.bounce_away()
		chambered = null
		to_chat(user, "<span class='notice'>Вы вытаскиваете патрон из [src].</span>")
		playsound(src, unlock_sound, 70, 1)
	else
		to_chat(user, "<span class='notice'>В [src] отсутствует магазин.</span>")
	update_icon()
	return


/obj/item/gun/ballistic/examine(mob/user)
	. = ..()
	if(suppressed)
		. += "[suppressed] [can_suppress ? "" : "намертво"] примкнут."
		if(can_suppress)
			. += "<span class='info'>Похоже, что [suppressed] можно <b>открутить голыми руками</b> от [src].</span>"
	if (can_suppress && sawn_off && !makeshift_threading)
		. += "<span class='info'>Похоже, что [src] <b>не имеет резьбы</b> для глушителя. Но её можно <b>сделать</b>.</span>"
	else if(can_suppress)
		. += "Видно крепление для <b>глушителя</b>."
	if(sawn_icon_state)
		. += "<span class='info'>[sawn_icon_state] [sawn_off ? "" : "Если найти пилу, то [src] можно будет <b>укоротить ствол</b>."]</span>"
		if(sawn_off)
			. += "<span class='info'>Похоже, что [src] <b>уже укорочен</b>.</span>"

/obj/item/gun/ballistic/proc/get_ammo(countchambered = 1)
	var/boolets = 0 //mature var names for mature people
	if (chambered && countchambered)
		boolets++
	if (magazine)
		boolets += magazine.ammo_count()
	return boolets

#define BRAINS_BLOWN_THROW_RANGE 3
#define BRAINS_BLOWN_THROW_SPEED 1
/obj/item/gun/ballistic/suicide_act(mob/living/user)
	var/obj/item/organ/brain/B = user.getorganslot(ORGAN_SLOT_BRAIN)
	if (B && chambered && chambered.BB && can_trigger_gun(user) && !chambered.BB.nodamage)
		user.visible_message("<span class='suicide'>[user] приставляет ствол [src] к [user.ru_ego()] рту.  Похоже, [user.p_theyre()] пытается покончить с собой!</span>")
		sleep(25)
		if(user.is_holding(src))
			var/turf/T = get_turf(user)
			process_fire(user, user, FALSE, null, BODY_ZONE_HEAD)
			user.visible_message("<span class='suicide'>[user] вышибает [user.ru_ego()] мозги[user.p_s()] с помощью [src]!</span>")
			playsound(src, 'sound/weapons/dink.ogg', 30, 1)
			var/turf/target = get_ranged_target_turf(user, turn(user.dir, 180), BRAINS_BLOWN_THROW_RANGE)
			B.Remove()
			B.forceMove(T)
			if(iscarbon(user))
				var/mob/living/carbon/C = user
				B.add_blood_DNA(C.dna, C.diseases)
			var/datum/callback/gibspawner = CALLBACK(user, TYPE_PROC_REF(/mob/living, spawn_gibs), FALSE, B)
			B.throw_at(target, BRAINS_BLOWN_THROW_RANGE, BRAINS_BLOWN_THROW_SPEED, callback=gibspawner)
			return(BRUTELOSS)
		else
			user.visible_message("<span class='suicide'>[user] паникует и начинает задыхаться!</span>")
			return(OXYLOSS)
	else
		user.visible_message("<span class='suicide'>[user] делает вид, что вышибит [user.ru_ego()] мозги[user.p_s()] с помощью [src]! Похоже, что [user.p_theyre()] пытается покончить с собой!</b></span>")
		playsound(src, "gun_dry_fire", 30, 1)
		return (OXYLOSS)
#undef BRAINS_BLOWN_THROW_SPEED
#undef BRAINS_BLOWN_THROW_RANGE

/obj/item/gun/ballistic/proc/sawoff(mob/user)
	if(sawn_off)
		to_chat(user, "<span class='warning'>ствол [src] уже укорочен!</span>")
		return
	if(!user.is_holding(src))
		to_chat(user, span_notice("Нужно держать [src] в руках, чтобы обрезать ствол!"))
		return
	if(suppressed)
		to_chat(user, "<span class='warning'>Сначала снимите глушитель с [src]!</span>")
		return
	if(bayonet)
		to_chat(user, "<span class='warning'>Сначала снимите штык-нож с [src]!</span>")
		return
	user.DelayNextAction(CLICK_CD_MELEE)
	user.visible_message("[user] начинает укорачивать ствол [src].", "<span class='notice'>Вы начинаете укорачивать ствол [src]...</span>")

	//if there's any live ammo inside the gun, makes it go off
	if(blow_up(user))
		user.visible_message("<span class='danger'> [src] непроизвольно стрелет!</span>", "<span class='danger'>спусковой крючок [src] в процессе нажимается, стреляя вам прямо в плечо!</span>")
		return

	if(do_after(user, 30, target = src))
		if(sawn_off)
			return
		user.visible_message("[user] укорачивает [src]!", "<span class='notice'>Вы укорачиваете [src].</span>")
		name = "обрез [src.name]"
		desc = sawn_desc
		w_class = WEIGHT_CLASS_NORMAL
		icon_state = sawn_icon_state
		item_state = sawn_item_state
		slot_flags &= ~ITEM_SLOT_BACK	//you can't sling it on your back
		slot_flags |= ITEM_SLOT_BELT		//but you can wear it on your belt (poorly concealed under a trenchcoat, ideally)
		sawn_off = TRUE
		on_sawoff(user) //Позволяем обрезу оружия X делать собственные изменения при обрезании ствола, например статистики. - RaizlenW
		update_icon()
		return TRUE

/// is something supposed to happen here?
/obj/item/gun/ballistic/proc/on_sawoff(mob/user)
	return

// Sawing guns related proc
/obj/item/gun/ballistic/proc/blow_up(mob/user)
	. = 0
	for(var/obj/item/ammo_casing/AC in magazine.stored_ammo)
		if(AC.BB)
			process_fire(user, user, FALSE)
			. = 1


/obj/item/suppressor
	name = "suppressor"
	desc = "Глушитель для стрелкового оружия, производства синдиката. Идеальное решение для шпионажа."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "suppressor"
	w_class = WEIGHT_CLASS_TINY


/obj/item/suppressor/specialoffer
	name = "cheap suppressor"
	desc = "Подделка кустарного производства, выглящая хлипкой, дешевой и ломкой. Но на некоторые виды оружия всё же подходит."
