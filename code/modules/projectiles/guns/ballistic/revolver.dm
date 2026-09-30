/obj/item/gun/ballistic/revolver
	name = "\improper .357 revolver"
	desc = "A suspicious revolver. Uses .357 ammo." //usually used by syndicates
	icon_state = "revolver"
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder
	fire_sound = "sound/weapons/revolvershot.ogg"
	casing_ejector = FALSE
	recoil = 0.5

/obj/item/gun/ballistic/revolver/Initialize(mapload)
	. = ..()
	if(!istype(magazine, /obj/item/ammo_box/magazine/internal/cylinder))
		verbs += /obj/item/gun/ballistic/revolver/verb/spin

/obj/item/gun/ballistic/revolver/chamber_round(spin = 1)
	if(spin)
		chambered = magazine.get_round(1)
	else
		chambered = magazine.stored_ammo[1]

/obj/item/gun/ballistic/revolver/shoot_with_empty_chamber(mob/living/user as mob|obj)
	..()
	chamber_round(1)

/obj/item/gun/ballistic/revolver/attackby(obj/item/A, mob/user, params) //есть задел для наличия и спилоадеров и коробок с патронами.
	. = ..()
	if(.)
		return
	if(!magazine) // нечего заряжать без барабана/магазина (напр. он извлечён через Alt-click или оружие создано без него)
		return
	var/num_loaded = 0
	if(istype(A, /obj/item/ammo_box)) //проверка что контейнер с боеприпасами и приведение к типу
		var/obj/item/ammo_box/AM = A
		if(!AM.speedloader) // Не спидлоадер
			if(!istype(magazine, /obj/item/ammo_box/magazine/internal/cylinder)) // ВДРУГ используется не цилиндр, двустволку заряжать патронами
				return to_chat(user, span_userdanger("У вас не получается зарядить револьвер при помощи [A]!"))
			var/obj/item/ammo_box/magazine/internal/cylinder/C = magazine
			num_loaded = C.ammo_box_reload(AM, user, params, 1)
		else // Заряжание спидлоадером и патроном
			num_loaded = magazine.attackby(A, user, params, 1) // У магазина есть параметр multiload, если false, то будет заряжать по одному.(иммитация каморы.)
	else
		num_loaded = magazine.attackby(A, user, params, 1) // Да, я не смог победить весвление чтоб объеденить с else выше.
	if(num_loaded)
		to_chat(user, "<span class='notice'>You load [num_loaded] shell\s into \the [src].</span>")
		playsound(user, 'sound/weapons/bulletinsert.ogg', 60, 1)
		A.update_icon()
		update_icon()
		chamber_round(0)

/obj/item/gun/ballistic/revolver/attack_self(mob/living/user)
	var/num_unloaded = 0
	chambered = null
	while (get_ammo() > 0)
		var/obj/item/ammo_casing/CB
		CB = magazine.get_round(0)
		if(CB)
			CB.forceMove(drop_location())
			CB.bounce_away(FALSE, NONE)
			num_unloaded++
	if (num_unloaded)
		to_chat(user, "<span class='notice'>You unload [num_unloaded] shell\s from [src].</span>")
	else
		to_chat(user, "<span class='warning'>[src] is empty!</span>")
	update_icon()

/obj/item/gun/ballistic/revolver/verb/spin()
	set name = "Spin Chamber"
	set category = "Object"
	set desc = "Click to spin your revolver's chamber."

	var/mob/M = usr

	if(M.stat || !in_range(M,src))
		return

	if(do_spin())
		usr.visible_message("[usr] spins [src]'s chamber.", "<span class='notice'>You spin [src]'s chamber.</span>")
	else
		verbs -= /obj/item/gun/ballistic/revolver/verb/spin

/obj/item/gun/ballistic/revolver/proc/do_spin()
	var/obj/item/ammo_box/magazine/internal/cylinder/C = magazine
	. = istype(C)
	if(.)
		C.spin()
		chamber_round(0)

/obj/item/gun/ballistic/revolver/can_shoot()
	return get_ammo(0,0)

/obj/item/gun/ballistic/revolver/get_ammo(countchambered = 0, countempties = 1)
	var/boolets = 0 //mature var names for mature people
	if (chambered && countchambered)
		boolets++
	if (magazine)
		boolets += magazine.ammo_count(countempties)
	return boolets

/obj/item/gun/ballistic/revolver/examine(mob/user)
	. = ..()
	. += "[get_ammo(0,0)] of those are live rounds."

/obj/item/gun/ballistic/revolver/syndicate
	obj_flags = UNIQUE_RENAME
	unique_reskin = list(
		"Default" = list("icon_state" = "revolver"), //Поменял стандартную иконку Револьвера Синдиката.
		"Silver" = list("icon_state" = "russianrevolver"),
		"Robust" = list("icon_state" = "revolvercit"),
		"Bulky" = list("icon_state" = "revolverhakita"),
		"Polished" = list("icon_state" = "revolvertoriate"),
		"Soulless" = list("icon_state" = "revolveroldflip"),
		"Soul" = list("icon_state" = "revolverold")
	)

/obj/item/gun/ballistic/revolver/detective
	name = "\improper .38 Mars Special"
	desc = "A cheap Martian knock-off of a classic law enforcement firearm. Uses .38-special rounds."
	icon_state = "detective"
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/rev38
	obj_flags = UNIQUE_RENAME
	unique_reskin = list(
		"Default" = list("icon_state" = "detective"),
		"Leopard Spots" = list("icon_state" = "detective_leopard"),
		"Black Panther" = list("icon_state" = "detective_panther"),
		"Gold Trim" = list("icon_state" = "detective_gold"),
		"The Peacemaker" = list("icon_state" = "detective_peacemaker")
	)
	var/list/safe_calibers

/obj/item/gun/ballistic/revolver/detective/Initialize(mapload)
	. = ..()
	safe_calibers = magazine.caliber

/obj/item/gun/ballistic/revolver/detective/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
	if(chambered && !(chambered.caliber in safe_calibers))
		var/real_ammo_count = magazine ? magazine.ammo_count(0) : 0
		if(prob(65 - (real_ammo_count * 10)))	//минимум 5, максимум 55
			playsound(user, fire_sound, 50, 1)
			to_chat(user, "<span class='userdanger'>[src] blows up in your face!</span>")
			user.take_bodypart_damage(10,10)
			user.dropItemToGround(src)
			return FALSE
	..()

/obj/item/gun/ballistic/revolver/detective/wrench_act(mob/living/user, obj/item/I)
	if(..())
		return TRUE
	if("38" in magazine.caliber)
		to_chat(user, "<span class='notice'>You begin to reinforce the barrel of [src]...</span>")
		if(magazine.ammo_count())
			afterattack(user, user)	//you know the drill
			user.visible_message("<span class='danger'>[src] goes off!</span>", "<span class='userdanger'>[src] goes off in your face!</span>")
			return TRUE
		if(I.use_tool(src, user, 30))
			if(magazine.ammo_count())
				to_chat(user, "<span class='warning'>You can't modify it!</span>")
				return TRUE
			magazine.caliber = list("357")
			desc = "The barrel and chamber assembly seems to have been modified."
			to_chat(user, "<span class='notice'>You reinforce the barrel of [src]. Now it will fire .357 rounds.</span>")
	else
		to_chat(user, "<span class='notice'>You begin to revert the modifications to [src]...</span>")
		if(magazine.ammo_count())
			afterattack(user, user)	//and again
			user.visible_message("<span class='danger'>[src] goes off!</span>", "<span class='userdanger'>[src] goes off in your face!</span>")
			return TRUE
		if(I.use_tool(src, user, 30))
			if(magazine.ammo_count())
				to_chat(user, "<span class='warning'>You can't modify it!</span>")
				return
			magazine.caliber = list("38")
			desc = initial(desc)
			to_chat(user, "<span class='notice'>You remove the modifications on [src]. Now it will fire .38 rounds.</span>")
	return TRUE


/obj/item/gun/ballistic/revolver/requiem
	name = "\improper Requiem"
	desc = "A massive Nanotrasen heavy assault revolver chambered in 12.7x55mm. Issued in tiny numbers to Central Command and asset-protection details. The cylinder only accepts 12.7x55mm cartridges — not .357."
	icon = 'modular_bluemoon/icons/obj/guns/requiem_revolver.dmi'
	icon_state = "revolver"
	item_state = "revolver"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/requiem_revolver_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/requiem_revolver_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/requiem127
	w_class = WEIGHT_CLASS_NORMAL
	weapon_weight = WEAPON_HEAVY
	fire_sound = 'modular_bluemoon/sound/weapons/re9_requiem_fire.ogg'
	recoil = 6
	dir_recoil_amp = 7
	slowdown = 0.15
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS

/obj/item/gun/ballistic/revolver/requiem/update_icon_state()
	. = ..()
	icon = 'modular_bluemoon/icons/obj/guns/requiem_revolver.dmi'
	if(suppressed || sawn_off)
		return
	if(!get_ammo(0, 0))
		icon_state = "revolver_open"
	else
		icon_state = "revolver"
	item_state = icon_state

/obj/item/gun/ballistic/revolver/requiem/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	. = ..()
	if(user?.client)
		shake_camera(user, 2, 2)

/obj/item/gun/ballistic/revolver/mateba
	name = "\improper Unica 6 auto-revolver"
	desc = "A retro high-powered autorevolver typically used by officers of the New Russia military. Uses .357 ammo."
	icon_state = "mateba" //Поменял стандартную иконку Револьвера Русских.
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS

/obj/item/gun/ballistic/revolver/golden
	name = "\improper Golden revolver"
	desc = "This ain't no game, ain't never been no show, And I'll gladly gun down the oldest lady you know. Uses .357 ammo."
	icon_state = "goldrevolver"
	fire_sound = 'sound/weapons/resonator_blast.ogg'
	recoil = 8
	dir_recoil_amp = 5 // 40 directional recoil is already really funny
	pin = /obj/item/firing_pin

/obj/item/gun/ballistic/revolver/nagant
	name = "\improper Nagant revolver"
	desc = "An old model of revolver that originated in Russia. Able to be suppressed. Uses 7.62x38mmR ammo."
	icon_state = "nagant"
	can_suppress = TRUE
	fire_sound = "sound/weapons/revolvershot2.ogg"

	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/rev762


// A gun to play Russian Roulette!
// You can spin the chamber to randomize the position of the bullet.

/obj/item/gun/ballistic/revolver/russian
	name = "\improper Russian revolver"
	desc = "A Russian-made revolver for drinking games. Uses .357 ammo, and has a mechanism requiring you to spin the chamber before each trigger pull."
	icon_state = "russianrevolver"
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/rus357
	var/spun = FALSE

/obj/item/gun/ballistic/revolver/russian/do_spin()
	. = ..()
	spun = TRUE

/obj/item/gun/ballistic/revolver/russian/Initialize(mapload)
	. = ..()
	do_spin()
	spun = TRUE
	update_icon()

/obj/item/gun/ballistic/revolver/russian/attackby(obj/item/A, mob/user, params)
	..()
	if(get_ammo() > 0)
		spin()
		spun = TRUE
	update_icon()
	A.update_icon()
	return

/obj/item/gun/ballistic/revolver/russian/attack_self(mob/user)
	if(!spun)
		spin()
		spun = TRUE
		return
	..()

/obj/item/gun/ballistic/revolver/russian/afterattack(atom/target, mob/living/user, flag, params)
	. = ..(null, user, flag, params)

	if(flag)
		if(!(target in user.contents) && ismob(target))
			if(user.a_intent == INTENT_HARM) // Flogging action
				return

	if(isliving(user))
		if(!can_trigger_gun(user))
			return
	if(target != user)
		if(ismob(target))
			to_chat(user, "<span class='warning'>A mechanism prevents you from shooting anyone but yourself!</span>")
		return

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(!spun)
			to_chat(user, "<span class='warning'>You need to spin \the [src]'s chamber first!</span>")
			return

		spun = FALSE

		if(chambered)
			var/obj/item/ammo_casing/AC = chambered
			if(AC.fire_casing(user, user))
				playsound(user, fire_sound, 50, 1)
				var/zone = check_zone(user.zone_selected)
				var/obj/item/bodypart/affecting = H.get_bodypart(zone)
				if(zone == BODY_ZONE_HEAD || zone == BODY_ZONE_PRECISE_EYES || zone == BODY_ZONE_PRECISE_MOUTH)
					shoot_self(user, affecting)
				else
					user.visible_message("<span class='danger'>[user.name] cowardly fires [src] at [user.ru_ego()] [affecting.name]!</span>", "<span class='userdanger'>You cowardly fire [src] at your [affecting.name]!</span>", "<span class='italics'>You hear a gunshot!</span>")
				chambered = null
				return

		user.visible_message("<span class='danger'>*click*</span>")
		balloon_alert(user, "Щёлк!")
		playsound(src, "gun_dry_fire", 30, 1)

/obj/item/gun/ballistic/revolver/russian/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
	add_fingerprint(user)
	playsound(src, "gun_dry_fire", 30, TRUE)
	user.visible_message("<span class='danger'>[user.name] tries to fire \the [src] at the same time, but only succeeds at looking like an idiot.</span>", "<span class='danger'>\The [src]'s anti-combat mechanism prevents you from firing it at the same time!</span>")

/obj/item/gun/ballistic/revolver/russian/proc/shoot_self(mob/living/carbon/human/user, affecting = BODY_ZONE_HEAD)
	user.apply_damage(300, BRUTE, affecting)
	user.visible_message("<span class='danger'>[user.name] fires [src] at [user.ru_ego()] head!</span>", "<span class='userdanger'>You fire [src] at your head!</span>", "<span class='italics'>You hear a gunshot!</span>")

/obj/item/gun/ballistic/revolver/russian/soul
	name = "cursed Russian revolver"
	desc = "To play with this revolver requires wagering your very soul."

/obj/item/gun/ballistic/revolver/russian/soul/shoot_self(mob/living/user)
	..()
	var/obj/item/soulstone/anybody/SS = new /obj/item/soulstone/anybody(get_turf(src))
	if(!SS.transfer_soul("FORCE", user)) //Something went wrong
		qdel(SS)
		return
	user.visible_message("<span class='danger'>[user.name]'s soul is captured by \the [src]!</span>", "<span class='userdanger'>You've lost the gamble! Your soul is forfeit!</span>")

/////////////////////////////
// DOUBLE BARRELED SHOTGUN //
/////////////////////////////

/obj/item/gun/ballistic/revolver/doublebarrel
	name = "double-barreled shotgun"
	icon = 'icons/obj/guns/projectile.dmi'
	desc = "A true classic."
	icon_state = "dshotgun"
	item_state = "dshotgun-wielded"
	w_class = WEIGHT_CLASS_BULKY
	weapon_weight = WEAPON_MEDIUM
	recoil = 1
	force = 10
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BACK
	mag_type = /obj/item/ammo_box/magazine/internal/shot/dual
	sawn_desc = "Omar's coming!"
	obj_flags = UNIQUE_RENAME
	unique_reskin = list(
		"Default" = list("icon_state" = "dshotgun"),
		"Dark Red Finish" = list("icon_state" = "dshotgun-d"),
		"Ash" = list("icon_state" = "dshotgun-f"),
		"Faded Grey" = list("icon_state" = "dshotgun-g"),
		"Maple" = list("icon_state" = "dshotgun-l"),
		"Rosewood" = list("icon_state" = "dshotgun-p")
	)

/obj/item/gun/ballistic/revolver/doublebarrel/attackby(obj/item/A, mob/user, params)
	..()
	if(istype(A, /obj/item/ammo_box) || istype(A, /obj/item/ammo_casing))
		chamber_round()
	if(A.tool_behaviour == TOOL_SAW || istype(A, /obj/item/gun/energy/plasmacutter))
		sawoff(user)
	if(istype(A, /obj/item/melee/transforming/energy))
		var/obj/item/melee/transforming/energy/W = A
		if(W.active)
			sawoff(user)

/obj/item/gun/ballistic/revolver/doublebarrel/attack_self(mob/living/user)
	var/num_unloaded = 0
	while (get_ammo() > 0)
		var/obj/item/ammo_casing/CB
		CB = magazine.get_round(0)
		chambered = null
		CB.forceMove(drop_location())
		CB.update_icon()
		num_unloaded++
	if (num_unloaded)
		to_chat(user, "<span class='notice'>You break open \the [src] and unload [num_unloaded] shell\s.</span>")
	else
		to_chat(user, "<span class='warning'>[src] is empty!</span>")

/////////////////////////////
//   IMPROVISED SHOTGUN    //
/////////////////////////////

/obj/item/gun/ballistic/revolver/doublebarrel/improvised
	name = "improvised shotgun"
	desc = "A shoddy break-action breechloaded shotgun. Less ammo-efficient than an actual shotgun, but still packs a punch."
	icon_state = "ishotgun"
	item_state = "shotgun"
	w_class = WEIGHT_CLASS_BULKY
	weapon_weight = WEAPON_MEDIUM // prevents shooting 2 at once, but doesn't require 2 hands
	force = 10
	slot_flags = null
	mag_type = /obj/item/ammo_box/magazine/internal/shot/improvised
	sawn_desc = "I'm just here for the gasoline."
	unique_reskin = list(
		"Default" = list("icon_state" = "ishotgun"),
		"Cobbled" = list("icon_state" = "old_ishotgun")
	)
	var/slung = FALSE

/obj/item/gun/ballistic/revolver/doublebarrel/improvised/attackby(obj/item/A, mob/user, params)
	..()
	if(istype(A, /obj/item/stack/cable_coil) && !sawn_off)
		if(A.use_tool(src, user, 0, 10, skill_gain_mult = EASY_USE_TOOL_MULT))
			slot_flags = ITEM_SLOT_BACK
			to_chat(user, "<span class='notice'>You tie the lengths of cable to the shotgun, making a sling.</span>")
			slung = TRUE
			update_icon()
		else
			to_chat(user, "<span class='warning'>You need at least ten lengths of cable if you want to make a sling!</span>")

/obj/item/gun/ballistic/revolver/doublebarrel/improvised/update_overlays()
	. = ..()
	if(slung)
		. += "[icon_state]sling"

/obj/item/gun/ballistic/revolver/doublebarrel/improvised/sawoff(mob/user)
	. = ..()
	if(. && slung) //sawing off the gun removes the sling
		new /obj/item/stack/cable_coil(get_turf(src), 10)
		slung = 0
		update_icon()

/obj/item/gun/ballistic/revolver/doublebarrel/improvised/sawn
	name = "sawn-off improvised shotgun"
	desc = "The barrel and stock have been sawn and filed down; it can fit in backpacks. You wont want to shoot two of these at once if you value your wrists."
	icon_state = "ishotgun"
	item_state = "gun"
	w_class = WEIGHT_CLASS_NORMAL
	sawn_off = TRUE
	slot_flags = ITEM_SLOT_BELT
	weapon_weight = WEAPON_MEDIUM

/obj/item/gun/ballistic/revolver/reverse //Fires directly at its user... unless the user is a clown, of course.
	clumsy_check = 0

/obj/item/gun/ballistic/revolver/reverse/can_trigger_gun(mob/living/user)
	if((HAS_TRAIT(user, TRAIT_CLUMSY)) || (user.mind && HAS_TRAIT(user.mind, TRAIT_CLOWN_MENTALITY)))
		return ..()
	if(process_fire(user, user, FALSE, null, BODY_ZONE_HEAD))
		user.visible_message("<span class='warning'>[user] somehow manages to shoot себя in the face!</span>", "<span class='userdanger'>You somehow shoot yourself in the face! How the hell?!</span>")
		user.emote("realagony")
		user.drop_all_held_items()
		user.DefaultCombatKnockdown(80)

// -------------- HoS Modular Weapon System -------------
// ---------- Code originally from VoreStation ----------
/obj/item/gun/ballistic/revolver/mws
	name = "MWS-01 'Big Iron'"
	desc = "Modular Weapon System-01, помещается на вашем бедре."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "mws"
	fire_sound = 'sound/weapons/MWSfire.ogg' //i spent 1 hour making a cool sound but byond just compresses it to shit so have this instead >:(
	mag_type = /obj/item/ammo_box/magazine/mws_mag
	spawnwithmagazine = FALSE
	recoil = 0
	can_flashlight = 1
	flight_x_offset = 21
	flight_y_offset = 10

	var/charge_sections = 6

/obj/item/gun/ballistic/revolver/mws/examine(mob/user)
	. = ..()
	. += span_notice("Alt-click для извлечения магазина.")

/obj/item/gun/ballistic/revolver/mws/shoot_with_empty_chamber(mob/living/user as mob|obj)
	process_chamber(user)
	if(!chambered || !chambered.BB)
		to_chat(user, span_danger("*click*"))
		playsound(src, "gun_dry_fire", 30, 1)


/obj/item/gun/ballistic/revolver/mws/process_chamber(mob/living/user)
	if(chambered && !chambered.BB) //if BB is null, i.e the shot has been fired...
		var/obj/item/ammo_casing/mws_batt/shot = chambered
		if(shot.cell.charge >= shot.e_cost)
			shot.chargeshot()
		else
			for(var/B in magazine.stored_ammo)
				var/obj/item/ammo_casing/mws_batt/other_batt = B
				if(istype(other_batt,shot) && other_batt.cell.charge >= other_batt.e_cost)
					switch_to(other_batt, user)
					break
	update_icon()

/obj/item/gun/ballistic/revolver/mws/proc/switch_to(obj/item/ammo_casing/mws_batt/new_batt, mob/living/user)
	if(ishuman(user))
		if(chambered && new_batt.type == chambered.type)
			to_chat(user, span_warning("[src] начинает тратить следующую батарею, [new_batt.type_name]."))
		else
			to_chat(user, span_warning("[src] теперь использует [new_batt.type_name]."))

	chambered = new_batt
	update_icon()

/obj/item/gun/ballistic/revolver/mws/attack_self(mob/living/user)
	if(!chambered)
		return

	var/list/stored_ammo = magazine.stored_ammo

	if(stored_ammo.len == 1)
		return //silly you.

	//Find an ammotype that ISN'T the same, or exhaust the list and don't change.
	var/our_slot = stored_ammo.Find(chambered)

	for(var/index in 1 to stored_ammo.len)
		var/true_index = ((our_slot + index - 1) % stored_ammo.len) + 1 // Stupid ONE BASED lists!
		var/obj/item/ammo_casing/mws_batt/next_batt = stored_ammo[true_index]
		if(chambered != next_batt && !istype(next_batt, chambered.type) && next_batt.cell.charge >= next_batt.e_cost)
			switch_to(next_batt, user)
			break

/obj/item/gun/ballistic/revolver/mws/AltClick(mob/living/user)
	.=..()
	if(magazine)
		user.put_in_hands(magazine)
		magazine.update_icon()
		if(magazine.ammo_count())
			playsound(src, 'sound/weapons/gun_magazine_remove_full.ogg', 70, 1)
		else
			playsound(src, "gun_remove_empty_magazine", 70, 1)
		magazine = null
		to_chat(user, span_notice("Вы извлекли магазин из [src]."))
		if(chambered)
			chambered = null
		update_icon()

/obj/item/gun/ballistic/revolver/mws/update_overlays()
	.=..()
	if(!chambered)
		return

	var/obj/item/ammo_casing/mws_batt/batt = chambered
	var/batt_color = batt.type_color //Used many times

	//Mode bar
	var/image/mode_bar = image(icon, icon_state = "[initial(icon_state)]_type")
	mode_bar.color = batt_color
	. += mode_bar

	//Barrel color
	var/mutable_appearance/barrel_color = mutable_appearance(icon, "[initial(icon_state)]_barrel", color = batt_color)
	barrel_color.alpha = 150
	. += barrel_color

	//Charge bar
	var/ratio = can_shoot() ? CEILING(clamp(batt.cell.charge / batt.cell.maxcharge, 0, 1) * charge_sections, 1) : 0
	for(var/i = 0, i < ratio, i++)
		var/mutable_appearance/charge_bar = mutable_appearance(icon,  "[initial(icon_state)]_charge", color = batt_color)
		charge_bar.pixel_x = i
		. += charge_bar

/////////////////////////////
//    Новые револьверы     //
/////////////////////////////

/obj/item/gun/ballistic/revolver/Condemnation
	name = "\improper Condemnation"
	desc = "A grim harbinger clad in blackened steel and intricate gold engravings. Condemnation does not seek repentance; it seeks an end. It is designed to look into the darkness of the Bayou, weigh the sins of the wicked, and deliver a heavy .45 caliber verdict that sends them straight to the abyss."
	icon = 'modular_bluemoon/icons/obj/guns/revolvers.dmi'
	fire_sound = "modular_bluemoon/fluffs/sound/weapon/Apostle.ogg"
	icon_state = "condemnation"
	item_state = "condemnation"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/requiem_revolver_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/requiem_revolver_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/cowboy
	dual_wield_spread = 1
	w_class = WEIGHT_CLASS_NORMAL
	recoil = 1
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS

/obj/item/gun/ballistic/revolver/Salvation
	name = "\improper Salvation"
	desc = "The pristine mirror to its darker twin, forged from cold silver and adorned with gold filigree. Salvation represents the final mercy of the Order. It fires not out of malice, but to cleanse the flesh and release the corrupted souls from their earthly torment, granting peace through blood and fire."
	icon = 'modular_bluemoon/icons/obj/guns/revolvers.dmi'
	fire_sound = "modular_bluemoon/fluffs/sound/weapon/Apostle.ogg"
	icon_state = "salvation"
	item_state = "salvation"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/requiem_revolver_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/requiem_revolver_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/cowboy
	dual_wield_spread = 1
	w_class = WEIGHT_CLASS_NORMAL
	recoil = 1
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS

/obj/item/gun/ballistic/revolver/proc/try_dual_buscadero_reload(mob/living/user)
	// 1. Проверка пояса buscadero на талии
	var/obj/item/storage/belt/buscadero/belt = user.get_item_by_slot(ITEM_SLOT_BELT)
	if(!istype(belt))
		return FALSE 

	// 2. Проверка наличия второго револьвера в неактивной руке
	var/obj/item/gun/ballistic/revolver/offhand_rev = user.get_inactive_held_item()
	if(!istype(offhand_rev))
		return FALSE

	var/reloaded_any = FALSE

	// 3. Полностью вытряхивает старые гильзы из основного револьвера на пол
	src.chambered = null
	if(src.magazine && src.magazine.stored_ammo && src.magazine.stored_ammo.len)
		for(var/i = src.magazine.stored_ammo.len; i > 0; i--)
			var/obj/item/ammo_casing/CB = src.magazine.stored_ammo[i]
			if(CB)
				src.magazine.stored_ammo -= CB
				CB.forceMove(src.drop_location())
				CB.bounce_away(FALSE, NONE)
				reloaded_any = TRUE 

	// 4. Полностью вытряхивает старые гильзы из второго револьвера на пол
	if(offhand_rev && offhand_rev.magazine && offhand_rev.magazine.stored_ammo && offhand_rev.magazine.stored_ammo.len)
		offhand_rev.chambered = null
		for(var/i = offhand_rev.magazine.stored_ammo.len; i > 0; i--)
			var/obj/item/ammo_casing/CB = offhand_rev.magazine.stored_ammo[i]
			if(CB)
				offhand_rev.magazine.stored_ammo -= CB
				CB.forceMove(offhand_rev.drop_location())
				CB.bounce_away(FALSE, NONE)
				reloaded_any = TRUE

	// Собирает все рассыпные патроны из пояса в отдельный список
	var/list/bullets_in_belt = list()
	for(var/obj/item/ammo_casing/B in belt.contents)
		bullets_in_belt += B

	// 5. ЗАРЯЖАЕТ ПАТРОНЫ ПОШТУЧНО ПРЯМО ИЗ ПОЯСА
	var/actual_reload_success = FALSE

	// Перебирает найденные на поясе патроны
	for(var/obj/item/ammo_casing/bullet in bullets_in_belt)
		
		// Заряжает основной револьвер, пока в барабане есть место
		if(src.magazine && src.magazine.stored_ammo.len < src.magazine.max_ammo)
			// Физически переносим патрон с пояса внутрь магазина револьвера
			bullet.forceMove(src.magazine)
			if(src.magazine.stored_ammo)
				src.magazine.stored_ammo.Add(bullet) // Добавляем патрон в список Сплюрта
			actual_reload_success = TRUE
			continue // Берем следующий патрон из пояса

		// Если основной полный, заряжаем левый револьвер
		if(offhand_rev && offhand_rev.magazine && offhand_rev.magazine.stored_ammo.len < offhand_rev.magazine.max_ammo)
			bullet.forceMove(offhand_rev.magazine)
			if(offhand_rev.magazine.stored_ammo)
				offhand_rev.magazine.stored_ammo.Add(bullet)
			actual_reload_success = TRUE
			continue

	// --- 6. ОБНОВЛЯЕМ КАМОРЫ И ИНТЕРФЕЙС, ЕСЛИ ХОТЬ ЧТО-ТО ЗАРЯДИЛОСЬ ---
	if(actual_reload_success)
		if(src.magazine)
			src.magazine.update_icon()
			src.chamber_round(1) // Досылаем первый патрон (spin = 1 по вашему коду)
		if(offhand_rev && offhand_rev.magazine)
			offhand_rev.magazine.update_icon()
			offhand_rev.chamber_round(1)

	// --- 7. ИТОГИ ---
	if(actual_reload_success || reloaded_any)
		playsound(user, 'sound/weapons/bulletinsert.ogg', 60, 1) 
		user.visible_message(
			"<span class='danger'>[user] ловким движением откидывает барабаны, с треском высыпая гильзы на пол, и вслепую забивает новые патроны из пояса [belt.name] прямо в каморы!</span>",
			"<span class='notice'>Вы ловко очистили каморы револьверов и зарядили их патронами из пояса.</span>"
		)
		src.update_icon()
		offhand_rev.update_icon()
		return TRUE

	return FALSE

/obj/item/gun/ballistic/revolver/Salvation/attack_self(mob/living/user)
	if(try_dual_buscadero_reload(user))
		return 
	return ..() 

/obj/item/gun/ballistic/revolver/Condemnation/attack_self(mob/living/user)
	if(try_dual_buscadero_reload(user))
		return
	return ..()

/obj/item/gun/ballistic/revolver/Apostle //сбухам новый револьвер, урон чуть больше чем енфорсер, меньше, чем у дека, лучше енфорсера разнообразием патрон
	name = "\improper Apostle"
	desc = "A precise tool of holy law crafted for the parish enforcers. Its heavy .41 caliber rounds deliver steady, unforgiving judgement, turning every standard patrol into a righteous crusade through the blighted swamps."
	icon = 'modular_bluemoon/icons/obj/guns/revolvers.dmi'
	fire_sound = "modular_bluemoon/fluffs/sound/weapon/Apostle.ogg"
	icon_state = "apostle"
	item_state = "apostle"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/revolver_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/revolver_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/apostle
	dual_wield_spread = 25
	w_class = WEIGHT_CLASS_NORMAL
	recoil = 1
	slot_flags = ITEM_SLOT_BELT

/obj/item/gun/ballistic/revolver/Dies_Irae //сбухам кит на револьвер для переделки под 308, но КРАЙНЕ МЕДЛЕННАЯ стрельба, плюс с двух рук, считай аналог винтовки с карго, но влезает в сумку ценой скорости стрельбы
	name = "\improper Dies Iraen"
	desc = "The Day of Wrath made manifest in cold, weathered iron. Re-engineered with an elongated frame to chamber devastating rifle cartridges, this hand-cannon shatters bone and banishes monstrosities with the thunderous roar of the final judgement."
	icon = 'modular_bluemoon/icons/obj/guns/revolvers.dmi'
	fire_sound = "modular_bluemoon/fluffs/sound/weapon/Dies_Irae.ogg"
	icon_state = "dies_irae"
	item_state = "apostle"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/revolver_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/revolver_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/dies_irae
	dual_wield_spread = 25
	fire_delay = 20
	w_class = WEIGHT_CLASS_NORMAL
	recoil = 5
	slot_flags = ITEM_SLOT_BELT

/obj/item/gun/ballistic/revolver/Liturgy //Апгрейд на ревик сбух, чтоб было 18 патрон, енфорсеру всунули 28, ревику можно 18
	name = "\improper Liturgy"
	desc = "A mechanical sin born of desperate zealotry. Its massive, cathedral-like cylinder feeds a relentless stream of fire, ensuring the sermon of lead never falters and the final service does not end until the streets are cleansed in blood and ash."
	icon = 'modular_bluemoon/icons/obj/guns/revolvers.dmi'
	icon_state = "liturgy"
	item_state = "apostle"
	fire_sound = "modular_bluemoon/fluffs/sound/weapon/Apostle.ogg"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/revolver_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/revolver_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/liturgy
	dual_wield_spread = 25
	w_class = WEIGHT_CLASS_NORMAL
	recoil = 1
	slot_flags = ITEM_SLOT_BELT 

/obj/item/gun/ballistic/revolver/Passing_Bell //тупа секвоя из нью вегаса антагам, калибр 45 70 давно в игре, но его нахуй никто не использует
	name = "\improper Passing Bell"
	desc = "A five-shot titan forged for the grim task of final rites. Its immense weight stabilizes the violent kick of full-sized rifle ammunition, ensuring that when this bell tolls, its thunderous echo signals the immediate and absolute end of whatever stands in its path."
	icon = 'modular_bluemoon/icons/obj/guns/revolvers.dmi'
	icon_state = "passing_bell"
	item_state = "passing_bell"
	fire_sound = "modular_bluemoon/fluffs/sound/weapon/Dies_Irae.ogg"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/revolver_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/revolver_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/passing_bell
	dual_wield_spread = 25
	w_class = WEIGHT_CLASS_NORMAL
	recoil = 3
	slot_flags = ITEM_SLOT_BELT

/obj/item/gun/ballistic/revolver/Exorcist  //Сделал тот самый револьвер судья, но для баланса ввел новый калибр, лор аккурейт 410
	name = "\improper Exorcist"
	desc = "The ultimate tool of spatial cleansing. Its elongated, heavy cylinder turns the classic revolver silhouette into a monstrous hybrid capable of firing dense clusters of buckshot. No curse can withstand its blast, and no demon can run from the spread of its holy wrath."
	icon = 'modular_bluemoon/icons/obj/guns/revolvers.dmi'
	icon_state = "exorcist"
	item_state = "exorcist"
	fire_sound = "modular_bluemoon/fluffs/sound/weapon/Exorcist.ogg"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/revolver_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/revolver_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder/exorcist 
	dual_wield_spread = 25
	w_class = WEIGHT_CLASS_NORMAL
	recoil = 3
	slot_flags = ITEM_SLOT_BELT
