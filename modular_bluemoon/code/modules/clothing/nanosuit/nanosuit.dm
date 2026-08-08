/datum/action/item_action/dusting_implant
	check_flags =  NONE
	name = "Activate Dusting Implant"
	icon_icon = 'icons/effects/blood.dmi'
	button_icon_state = "remains"

//Crytek Nanosuit made by YoYoBatty
/obj/item/clothing/under/syndicate/combat/nano
	name = "nanosuit lining"
	desc = "Foreign body resistant lining built below the nanosuit. Provides internal protection. Property of CryNet Systems."
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF
	item_flags = DROPDEL

/obj/item/clothing/under/syndicate/combat/nano/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_ICLOTHING)
		ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)

/obj/item/clothing/mask/gas/nano_mask
	name = "nanosuit gas mask"
	desc = "Operator mask. Property of CryNet Systems." //More accurate
	icon_state = "syndicate"
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF
	item_flags = DROPDEL

/obj/item/clothing/mask/gas/nano_mask/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_MASK)
		ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)

/obj/item/clothing/shoes/combat/coldres/nano
	name = "nanosuit boots"
	desc = "Boots part of a nanosuit. Slip resistant. Property of CryNet Systems."
	clothing_flags = NOSLIP
	gas_transfer_coefficient = 0.01
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, FIRE = 0, ACID = 0)
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF
	item_flags = DROPDEL

/obj/item/clothing/shoes/combat/coldres/nano/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_FEET)
		ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)

/obj/item/clothing/gloves/tackler/combat/insulated/nano
	name = "nanosuit gorilla gloves"
	desc = "CryNet-issue guerrilla tackling gloves built into the nanosuit. Fireproof, shock resistant, and tuned for devastating rushes."
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF
	gas_transfer_coefficient = 0.01
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, FIRE = 0, ACID = 0)
	item_flags = DROPDEL
	tackle_stam_cost = 35
	base_knockdown = 1.5 SECONDS
	tackle_range = 5
	tackle_speed = 2
	skill_mod = 3

/obj/item/clothing/gloves/tackler/combat/insulated/nano/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_GLOVES)
		ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)

/obj/item/radio/headset/syndicate/alt/nano
	name = "\proper the nanosuit's bowman headset"
	desc = "Operator communication headset. Property of CryNet Systems. ПКМ to toggle interface."
	icon_state = "syndie_headset"
	item_state = "syndie_headset"
	subspace_transmission = FALSE
	subspace_switchable = TRUE
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF
	item_flags = DROPDEL

/obj/item/radio/headset/syndicate/alt/nano/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_EARS)
		ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)

/obj/item/radio/headset/syndicate/alt/nano/AltClick()
	var/mob/M = usr
	if(usr.canUseTopic(src))
		attack_self(M)
	..()

/obj/item/radio/headset/syndicate/alt/nano/MouseDrop(obj/over_object, src_location, over_location)
	var/mob/M = usr
	if((!istype(over_object, /atom/movable/screen)) && usr.canUseTopic(src))
		return attack_self(M)
	return ..()

/obj/item/radio/headset/syndicate/alt/nano/emp_act()
	return

/obj/item/clothing/glasses/nano_goggles
	name = "nanosuit goggles"
	desc = "Goggles built for a nanosuit. Property of CryNet Systems. Includes a combo HUD, thermal vision and night vision."
	mob_overlay_icon = 'modular_bluemoon/icons/mob/nanosuit/nanosuit_mob.dmi'
	icon = 'modular_bluemoon/icons/mob/nanosuit/nanosuit.dmi'
	icon_state = "nvgmesonnano"
	item_state = "nvgmesonnano"
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF
	glass_colour_type = /datum/client_colour/glass_colour/nightvision
	actions_types = list(/datum/action/item_action/nanosuit/goggletoggle)
	vision_correction = TRUE //We must let our wearer have good eyesight
	vision_flags = SEE_MOBS
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	color_cutoffs = list(25, 8, 5)
	var/on = FALSE
	item_flags = DROPDEL
	var/list/hudlist = list(DATA_HUD_MEDICAL_ADVANCED, DATA_HUD_DIAGNOSTIC_ADVANCED, DATA_HUD_SECURITY_ADVANCED)

/datum/client_colour/glass_colour/nightvision
	colour = "#45723f"

/obj/item/clothing/glasses/nano_goggles/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_EYES)
		ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)
		if(ishuman(user))
			for(var/hud_type in hudlist)
				var/datum/atom_hud/data_hud = GLOB.huds[hud_type]
				data_hud.add_hud_to(user)

/obj/item/clothing/glasses/nano_goggles/dropped(mob/user)
	..()
	if(ishuman(user))
		for(var/hud_type in hudlist)
			var/datum/atom_hud/data_hud = GLOB.huds[hud_type]
			data_hud.remove_hud_from(user)

/obj/item/clothing/glasses/nano_goggles/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/nanosuit/goggletoggle))
		nvgmode(user)
		return TRUE
	return FALSE


/obj/item/clothing/glasses/nano_goggles/proc/nvgmode(mob/user, var/forced = FALSE)
	var/mob/living/carbon/human/H = user
	if(H.glasses != src)
		return
	if(!ishuman(user))
		return
	on = !on
	to_chat(user, "<span class='[forced ? "warning":"notice"]'>Мой ПНВ [on ? "включен":"выключен"][forced ? "!":"."]</span>")
	if(on)
		darkness_view = 8
		lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
		color_cutoffs = list(10, 25, 10)
	else
		darkness_view = 2
		lighting_alpha = null
		color_cutoffs = null
	H.update_sight()
	update_action_buttons()

/obj/item/clothing/glasses/nano_goggles/emp_act(severity)
	..()
	if(prob(33/severity))
		nvgmode(loc,TRUE)

/obj/item/clothing/suit/space/hardsuit/nano
	icon = 'modular_bluemoon/icons/mob/nanosuit/nanosuit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/nanosuit/nanosuit_mob.dmi'
	anthro_mob_worn_overlay = 'icons/mob/clothing/suit_digi.dmi'
	icon_state = "nanosuit"
	item_state = "nanosuit"
	name = "nanosuit"
	desc = "Some sort of alien future suit. It looks very robust. Property of CryNet Systems."
	armor = list(MELEE = 45, BULLET = 45, LASER = 45, ENERGY = 50, BOMB = 80, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 40)
	allowed = list(/obj/item/gun, /obj/item/melee, /obj/item/grenade, /obj/item/nullrod, /obj/item/ammo_box, /obj/item/ammo_casing, /obj/item/tank/internals)
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS					//Uncomment to enable firesuit protection
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/nano
	slowdown = 0.35
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF
	actions_types = list(/datum/action/item_action/toggle_helmet, /datum/action/item_action/nanosuit/armor, /datum/action/item_action/nanosuit/cloak, /datum/action/item_action/nanosuit/speed, /datum/action/item_action/nanosuit/strength)
	var/mob/living/carbon/human/Wearer = null
	var/criticalpower = FALSE
	var/mode = NANO_NONE
	var/datum/martial_art/nanosuit/style = new
	var/shutdown = TRUE
	var/current_charges = 3
	var/max_charges = 3 //How many charges total the shielding has
	var/medical_delay = 200 //How long after we've been shot before we can start recharging. 20 seconds here
	var/medical_timer = null
	var/temp_cooldown = 0
	var/restore_delay = 80
	var/injection_delay = 25
	var/injection_timer = null //Delay between injection of healing nanites
	var/defrosted = FALSE
	var/detecting = FALSE
	var/help_verb = /mob/living/carbon/human/proc/Nanosuit_help
	var/outfit = /datum/outfit/nanosuit
	jetpack = /obj/item/tank/jetpack/suit
	var/recharge_cooldown = 0 //if this number is greater than 0, we can't recharge
	var/cloak_use_rate = 1.2 //cloaked energy consume rate
	var/speed_use_rate = 1.6 //speed energy consume rate
	var/crit_energy = 20 //critical energy level
	var/regen_rate = 3 //rate at which we regen
	var/msg_time_react = 0
	var/trauma_threshold = 30
	block_chance = 0
	//variables for cloak pausing when shooting a suppressed gun
	var/stealth_cloak_out = 1 //transition time out of cloak
	var/stealth_cloak_in = 2 //transition time back into cloak
	var/healthon = FALSE
	var/atmoson = FALSE
	var/radon = FALSE
	var/cellon = FALSE
	/// If this is a path, this gets created as an object in Initialize.
	var/obj/item/stock_parts/cell/cell = /obj/item/stock_parts/cell/nano

/obj/item/clothing/suit/space/hardsuit/nano/Initialize(mapload)
	. = ..()
	if(ispath(cell))
		cell = new cell(src)
	START_PROCESSING(SSfastprocess, src)

/obj/item/clothing/suit/space/hardsuit/nano/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	if(Wearer && help_verb)
		Wearer.verbs -= help_verb
	Wearer = null
	if(style)
		QDEL_NULL(style)
	if(cell)
		QDEL_NULL(cell)
	return ..()

/obj/item/clothing/suit/space/hardsuit/nano/contents_explosion()
	return

/obj/item/clothing/suit/space/hardsuit/nano/examine(mob/user)
	..()
	if(mode != NANO_NONE)
		to_chat(user, "Костюм находится в режиме <b>[mode]</b>.")
	else
		to_chat(user, "Костюм выключен.")

/obj/item/clothing/suit/space/hardsuit/nano/process()
	..()
	if(!Wearer)
		return
	if(shutdown)
		return
	if(!cell)
		return
	if(Wearer.bodytemperature < BODYTEMP_COLD_DAMAGE_LIMIT)
		if(!detecting)
			temp_cooldown = world.time + restore_delay
			detecting = TRUE
		if(world.time > temp_cooldown)
			if(!defrosted)
				helmet.display_visor_message("Активированы протоколы разморозки.")
				Wearer.reagents.add_reagent(/datum/reagent/medicine/leporazine, 3)
				defrosted = TRUE
				temp_cooldown += 100
	else
		if(defrosted || detecting)
			defrosted = FALSE
			detecting = FALSE
	var/energy = cell.charge //store current energy here
	if(mode == NANO_CLOAK) //are we in cloak, not moving?
		energy -= cloak_use_rate //take away the cloak discharge rate at 1/10th since we're not moving
	if((energy < cell.maxcharge) && mode != NANO_CLOAK && !recharge_cooldown) //if our energy is less than 100, we're not in cloak and don't have a recharge delay timer
		var/energy2 = regen_rate //store our regen rate here
		energy2+=energy //add our current energy to it
		energy=min(cell.maxcharge,energy2) //our energy now equals the energy we had + 0.75 for everytime it iterates through, so it increases by 0.75 every tick until it goes to 100
	if(recharge_cooldown > 0) //do we have a recharge delay set?
		recharge_cooldown -= 1 //reduce it
	if(msg_time_react)
		msg_time_react -= 1
	if(cell.charge != energy)
		set_nano_energy(cell.charge - energy) //now set our current energy to the variable we modified
	if(world.time  > medical_timer)
		addmedicalcharge()
		medical_timer = world.time + medical_delay
	if((Wearer.health < 100 && current_charges) && world.time > injection_timer)
		current_charges--
		heal_nano(Wearer)

/obj/item/clothing/suit/space/hardsuit/nano/proc/set_nano_energy(var/amount, var/delay = 0)
	if(delay > recharge_cooldown)
		recharge_cooldown = delay
	if(cell.charge < crit_energy && !criticalpower) //energy is less than critical energy level(20) and not in crit power
		helmet.display_visor_message("Недостаточно энергии!") //now we are
		criticalpower = TRUE
	else if(cell.charge > crit_energy) //did our energy go higher than the crit level
		criticalpower = FALSE //turn it off
	if(!cell.charge) //did we lose energy?
		if(mode == NANO_CLOAK) //are we in cloak?
			recharge_cooldown = 15 //then wait 3 seconds(1 value per 2 ticks = 15*2=30/10 = 3 seconds) to recharge again
		if(mode != NANO_ARMOR && mode != NANO_NONE) //we're not in cloak
			toggle_mode(NANO_ARMOR, TRUE) //go into it, forced
	cell.charge = max(0,(cell.charge - amount))

/obj/item/clothing/suit/space/hardsuit/nano/proc/addmedicalcharge()
	current_charges = min(max_charges, current_charges + 1)

/obj/item/clothing/suit/space/hardsuit/nano/proc/onmove()
	if(mode == NANO_CLOAK)
		set_nano_energy(cloak_use_rate,NANO_CHARGE_DELAY)
	else if(mode == NANO_SPEED)
		set_nano_energy(speed_use_rate,NANO_CHARGE_DELAY)

/obj/item/clothing/suit/space/hardsuit/nano/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(damage <= 0 && (attack_type & ATTACK_TYPE_UNARMED))
		return ..()
	var/obj/item/projectile/P = isprojectile(object) ? object : null
	if(attack_type == ATTACK_TYPE_TACKLE)
		final_block_chance = 75
	if(mode == NANO_ARMOR && cell?.charge)
		if(prob(final_block_chance))
			owner.visible_message(span_danger("Защита [owner] отражает [attack_text]!"))
			if(damage)
				if(!P || P.damage_type != STAMINA)
					set_nano_energy(10 + damage, NANO_CHARGE_DELAY)
				else if(attack_type & ATTACK_TYPE_PROJECTILE)
					set_nano_energy(20, NANO_CHARGE_DELAY)
			if(istype(P, /obj/item/projectile/energy/electrode))
				set_nano_energy(35, NANO_CHARGE_DELAY)
			return BLOCK_SUCCESS | BLOCK_PHYSICAL_EXTERNAL
		medical_timer = world.time + medical_delay
		owner.visible_message(span_warning("Защита [owner] не смогла отразить [attack_text]."))
		if(damage && (attack_type & ATTACK_TYPE_PROJECTILE) && P?.damage_type != STAMINA && prob(50))
			var/datum/effect_system/spark_spread/s = new
			s.set_up(1, 1, src)
			s.start()
		return BLOCK_NONE
	if(Wearer)
		kill_cloak()
		for(var/X in Wearer.bodyparts)
			var/obj/item/bodypart/BP = X
			if(!msg_time_react)
				if(BP.body_zone == BODY_ZONE_L_LEG || BP.body_zone == BODY_ZONE_R_LEG || BP.body_zone == BODY_ZONE_L_ARM || BP.body_zone == BODY_ZONE_R_ARM)
					if(BP.brute_dam > trauma_threshold)
						helmet.display_visor_message("Замечены переломы и обширные травмы в районе [BP.name]!")
						msg_time_react = 200
					else if(BP.burn_dam > trauma_threshold)
						helmet.display_visor_message("Ошибки защиты от огня замечены в области [BP.name]!")
						msg_time_react = 200
				if(BP.body_zone == BODY_ZONE_HEAD)
					if(BP.brute_dam > trauma_threshold)
						helmet.display_visor_message("Замечены критические повреждения черепа!")
						msg_time_react = 300
					else if(BP.burn_dam > trauma_threshold)
						helmet.display_visor_message("Замечены критические ожоги черепа!")
						msg_time_react = 300
				if(BP.body_zone == BODY_ZONE_CHEST)
					if(BP.brute_dam > trauma_threshold)
						helmet.display_visor_message("Замечены травмы тела несовместимые с жизнью!")
						msg_time_react = 300
					else if(BP.burn_dam > trauma_threshold)
						helmet.display_visor_message("Обнаружены критические ожоги тела!")
						msg_time_react = 300
		medical_timer = world.time + medical_delay
	SEND_SIGNAL(src, COMSIG_ITEM_HIT_REACT, list(owner, object, damage, attack_text, attack_type, armour_penetration, attacker, def_zone, final_block_chance, block_return))
	return ..()

/obj/item/clothing/suit/space/hardsuit/nano/proc/heal_nano(mob/living/carbon/human/user)
	helmet.display_visor_message("Включены экстренные медицинские протоколы.")
	user.reagents.add_reagent(/datum/reagent/medicine/syndicate_nanites, 5)
	user.reagents.add_reagent(/datum/reagent/medicine/omnizine, 1)
	injection_timer = world.time + injection_delay
/obj/item/clothing/suit/space/hardsuit/nano/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/nanosuit/armor))
		toggle_mode(NANO_ARMOR)
		return TRUE
	if(istype(action, /datum/action/item_action/nanosuit/cloak))
		toggle_mode(NANO_CLOAK)
		return TRUE
	if(istype(action, /datum/action/item_action/nanosuit/speed))
		toggle_mode(NANO_SPEED)
		return TRUE
	if(istype(action, /datum/action/item_action/nanosuit/strength))
		toggle_mode(NANO_STRENGTH)
		return TRUE
	if(istype(action, /datum/action/item_action/toggle_helmet))
		ToggleHelmet()
		return TRUE
	return FALSE

/obj/item/clothing/suit/space/hardsuit/nano/proc/toggle_mode(var/suitmode, var/forced = FALSE)
	if(!shutdown && (forced || (cell?.charge && mode != suitmode)))
		mode = suitmode
		switch(suitmode)
			if(NANO_ARMOR)
				helmet.display_visor_message("Максимум Брони!")
				block_chance = 55
				slowdown = initial(slowdown)
				armor = armor.setRating(melee = 60, bullet = 60, laser = 55, energy = 60, bomb = 95, rad = 100, fire = 100, acid = 100, wound = 50)
				helmet.armor = helmet.armor.setRating(melee = 60, bullet = 60, laser = 55, energy = 60, bomb = 95, rad = 100, fire = 100, acid = 100, wound = 50)
				Wearer.filters = list()
				animate(Wearer, alpha = 255, time = 5)
				Wearer.remove_movespeed_modifier(/datum/movespeed_modifier/nanospeed)
				REMOVE_TRAIT(Wearer, TRAIT_IGNORESLOWDOWN, NANO_SPEED)
				REMOVE_TRAIT(Wearer, TRAIT_PUSHIMMUNE, NANO_STRENGTH)
				REMOVE_TRAIT(Wearer, TRAIT_HEAVY_MELEE, NANO_STRENGTH)
				REMOVE_TRAIT(Wearer, TRAIT_TACRELOAD, NANO_SPEED)
				REMOVE_TRAIT(Wearer, TRAIT_LIGHT_STEP, NANO_SPEED)
				style.remove(Wearer)
				jetpack.full_speed = FALSE

			if(NANO_CLOAK)
				helmet.display_visor_message("Маскировка включена!")
				block_chance = initial(block_chance)
				slowdown = 0.25 //cloaking makes us move slightly faster
				armor = armor.setRating(melee = 45, bullet = 45, laser = 45, energy = 50, bomb = 80, rad = 100, fire = 100, acid = 100, wound = 40)
				helmet.armor = helmet.armor.setRating(melee = 45, bullet = 45, laser = 45, energy = 50, bomb = 80, rad = 100, fire = 100, acid = 100, wound = 40)
				Wearer.filters = filter(type="blur",size=1)
				animate(Wearer, alpha = 40, time = 2)
				Wearer.remove_movespeed_modifier(/datum/movespeed_modifier/nanospeed)
				REMOVE_TRAIT(Wearer, TRAIT_IGNORESLOWDOWN, NANO_SPEED)
				REMOVE_TRAIT(Wearer, TRAIT_PUSHIMMUNE, NANO_STRENGTH)
				REMOVE_TRAIT(Wearer, TRAIT_HEAVY_MELEE, NANO_STRENGTH)
				REMOVE_TRAIT(Wearer, TRAIT_TACRELOAD, NANO_SPEED)
				ADD_TRAIT(Wearer, TRAIT_LIGHT_STEP, NANO_SPEED)
				style.remove(Wearer)
				jetpack.full_speed = FALSE

			if(NANO_SPEED)
				helmet.display_visor_message("Максимум скорости!")
				block_chance = initial(block_chance)
				slowdown = initial(slowdown)
				armor = armor.setRating(melee = 45, bullet = 45, laser = 45, energy = 50, bomb = 80, rad = 100, fire = 100, acid = 100, wound = 40)
				helmet.armor = helmet.armor.setRating(melee = 45, bullet = 45, laser = 45, energy = 50, bomb = 80, rad = 100, fire = 100, acid = 100, wound = 40)
				Wearer.adjustOxyLoss(-5, 0)
				Wearer.adjustStaminaLoss(-20)
				Wearer.filters = filter(type="outline", size=0.1, color=rgb(255,255,224))
				animate(Wearer, alpha = 255, time = 5)
				REMOVE_TRAIT(Wearer, TRAIT_PUSHIMMUNE, NANO_STRENGTH)
				REMOVE_TRAIT(Wearer, TRAIT_HEAVY_MELEE, NANO_STRENGTH)
				ADD_TRAIT(Wearer, TRAIT_TACRELOAD, NANO_SPEED)
				Wearer.add_movespeed_modifier(/datum/movespeed_modifier/nanospeed, update=TRUE)
				ADD_TRAIT(Wearer, TRAIT_IGNORESLOWDOWN, NANO_SPEED)
				REMOVE_TRAIT(Wearer, TRAIT_LIGHT_STEP, NANO_SPEED)
				style.remove(Wearer)
				jetpack.full_speed = TRUE

			if(NANO_STRENGTH)
				helmet.display_visor_message("Максимум силы!")
				block_chance = 25
				style.teach(Wearer,1)
				slowdown = initial(slowdown)
				armor = armor.setRating(melee = 45, bullet = 45, laser = 45, energy = 50, bomb = 80, rad = 100, fire = 100, acid = 100, wound = 40)
				helmet.armor = helmet.armor.setRating(melee = 45, bullet = 45, laser = 45, energy = 50, bomb = 80, rad = 100, fire = 100, acid = 100, wound = 40)
				Wearer.filters = filter(type="outline", size=0.1, color=rgb(255,0,0))
				animate(Wearer, alpha = 255, time = 5)
				ADD_TRAIT(Wearer, TRAIT_PUSHIMMUNE, NANO_STRENGTH)
				ADD_TRAIT(Wearer, TRAIT_HEAVY_MELEE, NANO_STRENGTH)
				Wearer.remove_movespeed_modifier(/datum/movespeed_modifier/nanospeed)
				REMOVE_TRAIT(Wearer, TRAIT_IGNORESLOWDOWN, NANO_SPEED)
				REMOVE_TRAIT(Wearer, TRAIT_TACRELOAD, NANO_SPEED)
				REMOVE_TRAIT(Wearer, TRAIT_LIGHT_STEP, NANO_SPEED)
				jetpack.full_speed = FALSE

			if(NANO_NONE)
				block_chance = initial(block_chance)
				style.remove(Wearer)
				slowdown = initial(slowdown)
				armor = armor.setRating(melee = 45, bullet = 45, laser = 45, energy = 50, bomb = 80, rad = 100, fire = 100, acid = 100, wound = 40)
				helmet.armor = helmet.armor.setRating(melee = 45, bullet = 45, laser = 45, energy = 50, bomb = 80, rad = 100, fire = 100, acid = 100, wound = 40)
				Wearer.filters = list()
				animate(Wearer, alpha = 255, time = 5)
				REMOVE_TRAIT(Wearer, TRAIT_PUSHIMMUNE, NANO_STRENGTH)
				REMOVE_TRAIT(Wearer, TRAIT_HEAVY_MELEE, NANO_STRENGTH)
				Wearer.remove_movespeed_modifier(/datum/movespeed_modifier/nanospeed)
				REMOVE_TRAIT(Wearer, TRAIT_IGNORESLOWDOWN, NANO_SPEED)
				REMOVE_TRAIT(Wearer, TRAIT_TACRELOAD, NANO_SPEED)
				REMOVE_TRAIT(Wearer, TRAIT_LIGHT_STEP, NANO_SPEED)
				jetpack.full_speed = FALSE

	update_action_buttons()
	Wearer.update_inv_wear_suit()
	Wearer.update_action_buttons_icon()
	update_icon()


/obj/item/clothing/suit/space/hardsuit/nano/emp_act(severity)
	..()
	if(!severity || shutdown)
		return
	set_nano_energy(cell.charge/severity,NANO_EMP_CHARGE_DELAY)
	if((mode == NANO_ARMOR && !cell.charge) || (mode != NANO_ARMOR))
		if(prob(5/severity))
			emp_assault()
		//else if(prob(10/severity))
		//	Wearer.confused += 10
	update_icon()

/obj/item/clothing/suit/space/hardsuit/nano/proc/emp_assault()
	if(!Wearer)
		return //Not sure how this could happen.
	SSblackbox.record_feedback("tally", "nanosuit_emp_shutdown", 1, type)
	//Wearer.confused += 50
	helmet.display_visor_message("ЭМИ атака! Сбой всех систем.")
	sleep(40)
	Wearer.apply_effects(knockdown = 300, stun = 300, jitter = 120)
	toggle_mode(NANO_NONE, TRUE)
	shutdown = TRUE
	addtimer(CALLBACK(src, PROC_REF(emp_assaulttwo)), 25)


/obj/item/clothing/suit/space/hardsuit/nano/proc/emp_assaulttwo()
	sleep(35)
	helmet.display_visor_message("Внимание, ЭМИ атака! Сбой всех систем.")
	sleep(25)
	helmet.display_visor_message("Смена режима: базовое поддержание работы костюма.")
	sleep(25)
	helmet.display_visor_message("Система жизнеобеспечения. Ошибка!")
	addtimer(CALLBACK(src, PROC_REF(emp_assaultthree)), 35)


/obj/item/clothing/suit/space/hardsuit/nano/proc/emp_assaultthree()
	helmet.display_visor_message("Принудительный сброс CMOS начат, ожидайте...")
	sleep(20)
	playsound(src, 'sound/machines/beep.ogg', 50, FALSE)
	helmet.display_visor_message("4672482//-82544111.0//WRXT _YWD")
	sleep(5)
	helmet.display_visor_message("KPO- -86801780.768//1228.")
	sleep(5)
	helmet.display_visor_message("LMU/894411.-//0113122")
	sleep(5)
	helmet.display_visor_message("QRE 8667152...")
	sleep(5)
	helmet.display_visor_message("XAS -123455")
	sleep(5)
	helmet.display_visor_message("WF // .897")
	sleep(20)
	helmet.display_visor_message("DIAG//123")
	sleep(10)
	helmet.display_visor_message("MED//8189")
	sleep(10)
	helmet.display_visor_message("LOADING//...")
	sleep(30)
	helmet.display_visor_message("В процессе лечения сердечной дисритмии, ожидайте...")
	playsound(src, 'sound/machines/defib_charge.ogg', 75, FALSE)
	sleep(25)
	playsound(src, 'sound/machines/defib_zap.ogg', 50, FALSE)
	Wearer.apply_effects(stun = -100, knockdown = -100, stamina = -55)
	Wearer.adjustOxyLoss(-55)
	sleep(3)
	playsound(src, 'sound/machines/defib_success.ogg', 75, FALSE)
	helmet.display_visor_message("Все системы были успешно перезагружены.")
	shutdown = FALSE
	toggle_mode(NANO_ARMOR)
	refresh_nano_action_buttons()

/datum/action/item_action/nanosuit
	check_flags = AB_CHECK_CONSCIOUS
	background_icon_state = "bg_tech_blue"

/datum/action/item_action/nanosuit/goggletoggle
	name = "Night Vision"
	icon_icon = 'modular_bluemoon/icons/mob/nanosuit/actions_nanosuit.dmi'
	button_icon_state = "toggle_goggle"

/datum/action/item_action/nanosuit/armor
	name = "Armor Mode"
	icon_icon = 'modular_bluemoon/icons/mob/nanosuit/actions_nanosuit.dmi'
	button_icon_state = "armor_mode"

/datum/action/item_action/nanosuit/cloak
	name = "Cloak Mode"
	icon_icon = 'modular_bluemoon/icons/mob/nanosuit/actions_nanosuit.dmi'
	button_icon_state = "cloak_mode"

/datum/action/item_action/nanosuit/speed
	name = "Speed Mode"
	icon_icon = 'modular_bluemoon/icons/mob/nanosuit/actions_nanosuit.dmi'
	button_icon_state = "speed_mode"

/datum/action/item_action/nanosuit/strength
	name = "Strength Mode"
	icon_icon = 'modular_bluemoon/icons/mob/nanosuit/actions_nanosuit.dmi'
	button_icon_state = "strength_mode"


/obj/item/clothing/head/helmet/space/hardsuit/nano
	name = "nanosuit helmet"
	desc = "The cherry on top. Property of CryNet Systems."
	mob_overlay_icon = 'modular_bluemoon/icons/mob/nanosuit/nanosuit_mob.dmi'
	icon = 'modular_bluemoon/icons/mob/nanosuit/nanosuit.dmi'
	icon_state = "nanohelmet"
	item_state = "nanohelmet"
	mutantrace_variation = STYLE_NO_ANTHRO_ICON
	//item_color = "nano"
	siemens_coefficient = 0
	gas_transfer_coefficient = 0.01
	armor = list(MELEE = 45, BULLET = 45, LASER = 45, ENERGY = 50, BOMB = 80, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 40)
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF //No longer shall our kind be foiled by lone chemists with spray bottles!
	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	var/zoom_range = 12
	var/zoom = FALSE
	actions_types = list(/datum/action/item_action/nanosuit/zoom)
	rad_insulation = RAD_NO_INSULATION
	var/explosion_detection_dist = 21

/obj/item/clothing/head/helmet/space/hardsuit/nano/proc/sense_explosion(datum/source, turf/epicenter, devastation_range, heavy_impact_range,
		light_impact_range, took, orig_dev_range, orig_heavy_range, orig_light_range)
	var/turf/T = get_turf(src)
	if(T.z != epicenter.z)
		return
	if(get_dist(epicenter, T) > explosion_detection_dist)
		return
	display_visor_message("Замечен взрыв! Эпицентр: [devastation_range], Внешний: [heavy_impact_range], Взрывная волна: [light_impact_range]")

/obj/item/clothing/head/helmet/space/hardsuit/nano/ui_action_click()
	return FALSE

/obj/item/clothing/head/helmet/space/hardsuit/nano/equipped(mob/living/carbon/human/user, slot)
	..()
	if(slot == ITEM_SLOT_HEAD)
		ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)

/obj/item/clothing/head/helmet/space/hardsuit/nano/dropped(mob/living/carbon/human/user)
	..()
	if(zoom)
		toggle_zoom(user, TRUE)

/obj/item/clothing/head/helmet/space/hardsuit/nano/proc/toggle_zoom(mob/living/user, force_off = FALSE)
	if(!user || !user.client)
		return
	if(zoom || force_off)
		user.client.change_view(getScreenSize())
		to_chat(user, span_boldnotice("Отключено: увеличение детализации."))
		zoom = FALSE
		return FALSE
	else
		user.client.change_view(zoom_range)
		to_chat(user, span_boldnotice("Включено: увеличение детализации."))
		zoom = TRUE
		return TRUE

/datum/action/item_action/nanosuit/zoom
	name = "Helmet Zoom"
	background_icon_state = "bg_tech_blue"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"

/datum/action/item_action/nanosuit/zoom/Trigger(trigger_flags)
	var/obj/item/clothing/head/helmet/space/hardsuit/nano/NS = target
	if(istype(NS))
		NS.toggle_zoom(owner)
	return ..()

/obj/item/clothing/head/helmet/space/hardsuit/nano/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/rad_insulation, RAD_NO_INSULATION, TRUE, TRUE)

/obj/item/clothing/suit/space/hardsuit/nano/equipped(mob/user, slot)
	if(ishuman(user))
		Wearer = user
	if(slot == ITEM_SLOT_OCLOTHING)
		var/turf/T = get_turf(user)
		var/area/A = get_area(user)
		ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)
		Wearer.unequip_everything()
		Wearer.equipOutfit(outfit)
		equip_support_gear(Wearer)
		ToggleHelmet(FALSE)
		ADD_TRAIT(Wearer, TRAIT_NODISMEMBER, "Nanosuit")
		ADD_TRAIT(Wearer, TRAIT_NEVER_WOUNDED, "Nanosuit")
		RegisterSignals(Wearer, list(COMSIG_MOB_ITEM_ATTACK,COMSIG_MOB_ITEM_AFTERATTACK,COMSIG_MOB_THROW,COMSIG_MOB_ATTACK_HAND), PROC_REF(kill_cloak),TRUE)
		if(is_station_level(T.z))
			priority_announce("[user] использовал[user.ru_a()] запрещённый нанокостюм в [A.name]!", "Экстренное сообщение!", sound('modular_bluemoon/sound/effects/nanosuitengage.ogg'))
		log_game("[user] has engaged [src]")
		if(help_verb)
			Wearer.verbs += help_verb
		RegisterSignal(Wearer, COMSIG_MOB_KEYDOWN, PROC_REF(nano_keydown))
		INVOKE_ASYNC(src, PROC_REF(bootSequence))
	..()
	if(slot == ITEM_SLOT_OCLOTHING)
		refresh_nano_action_buttons()

/obj/item/clothing/suit/space/hardsuit/nano/proc/refresh_nano_action_buttons()
	if(!Wearer)
		return
	var/list/nano_items = list(src)
	if(istype(helmet) && helmet.loc == Wearer)
		nano_items += helmet
	if(istype(Wearer.glasses, /obj/item/clothing/glasses/nano_goggles))
		nano_items += Wearer.glasses
	for(var/obj/item/I in nano_items)
		for(var/datum/action/A as anything in I.actions)
			A.Grant(Wearer)
		I.update_action_buttons(FALSE, TRUE)
	Wearer.update_action_buttons_icon()

/obj/item/clothing/suit/space/hardsuit/nano/proc/nano_keydown(mob/source, key, client/user, full_key)
	SIGNAL_HANDLER
	if(!Wearer || source != Wearer)
		return
	if(lowertext(key) != "c")
		return
	INVOKE_ASYNC(src, PROC_REF(open_mode_menu), Wearer)

/obj/item/clothing/suit/space/hardsuit/nano/proc/equip_support_gear(mob/living/carbon/human/H)
	equip_kit_item(H, /obj/item/clothing/glasses/nano_goggles, ITEM_SLOT_EYES)
	equip_kit_item(H, /obj/item/clothing/gloves/tackler/combat/insulated/nano, ITEM_SLOT_GLOVES)
	equip_kit_item(H, /obj/item/clothing/shoes/combat/coldres/nano, ITEM_SLOT_FEET)

/obj/item/clothing/suit/space/hardsuit/nano/proc/equip_kit_item(mob/living/carbon/human/H, item_path, slot)
	for(var/obj/item/I in get_turf(H))
		if(istype(I, item_path))
			return H.equip_to_slot_or_del(I, slot)
	return H.equip_to_slot_or_del(new item_path, slot)

/obj/item/clothing/suit/space/hardsuit/nano/dropped(mob/user)
	var/mob/living/carbon/human/H = user || Wearer
	if(ishuman(H))
		UnregisterSignal(H, COMSIG_MOB_KEYDOWN)
	..()
	if(help_verb && Wearer)
		Wearer.verbs -= help_verb

/obj/item/clothing/suit/space/hardsuit/nano/proc/bootSequence()
	helmet.display_visor_message("Crynet - UEFI v1.32 Syndicate Systems")
	sleep(10)
	helmet.display_visor_message("P.O.S.T. Загрузка...")
	sleep(30)
	playsound(src, 'sound/machines/beep.ogg', 50, FALSE)
	helmet.display_visor_message("Проверка памяти: 6144MB OK(Установленный объём: 6144MB)")
	sleep(10)
	helmet.display_visor_message("Набортное оборудование: OK")
	sleep(10)
	helmet.display_visor_message("Телекоммуникационные системы: OK")
	sleep(10)
	helmet.display_visor_message("Проверка сенсоров окружения, ожидайте...")
	sleep(20)
	healthon = TRUE
	helmet.display_visor_message("Датчики форм жизни: OK")
	sleep(5)
	atmoson = TRUE
	helmet.display_visor_message("Атмосферные сенсоры: OK")
	sleep(5)
	cellon = TRUE
	helmet.display_visor_message("Сенсоры энергии: OK")
	sleep(5)
	radon = TRUE
	helmet.display_visor_message("Счётчик гейгера: OK")
	sleep(5)
	helmet.display_visor_message("Загружаем стандартную конфигурацию, ожидайте...")
	sleep(25)
	helmet.display_visor_message("Успех. Приятного использования.")
	shutdown = FALSE
	toggle_mode(NANO_ARMOR)
	refresh_nano_action_buttons()


/datum/outfit/nanosuit
	name = "Nanosuit"
	uniform = /obj/item/clothing/under/syndicate/combat/nano
	mask = /obj/item/clothing/mask/gas/nano_mask
	ears = /obj/item/radio/headset/syndicate/alt/nano
	implants = list(/obj/item/implant/explosive/disintegrate)
	cybernetic_implants = list(/obj/item/organ/cyberimp/chest/nutrimentextreme)

/datum/outfit/nanosuit/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	..()

	if(visualsOnly)
		return

	var/obj/item/tank/internals/emergency_oxygen/recharge/I = new(src)
	H.equip_to_slot_or_del(I, ITEM_SLOT_RPOCKET)

/mob/living/carbon/get_status_tab_items()
	. = ..()
	var/obj/item/organ/alien/plasmavessel/vessel = getorgan(/obj/item/organ/alien/plasmavessel)
	if(vessel)
		. += "Plasma Stored: [vessel.storedPlasma]/[vessel.max_plasma]"
	if(locate(/obj/item/assembly/health) in src)
		. += "Health: [health]"
	var/obj/item/organ/heart/vampire/darkheart = getorgan(/obj/item/organ/heart/vampire)
	if(darkheart)
		. += "Current blood level: [blood_volume]/[BLOOD_VOLUME_MAXIMUM]."
	if(!ishuman(src))
		return
	var/mob/living/carbon/human/H = src
	if(istype(H.wear_suit, /obj/item/clothing/suit/space/hardsuit/nano))
		var/obj/item/clothing/suit/space/hardsuit/nano/NS = H.wear_suit
		var/datum/gas_mixture/environment = H.loc?.return_air()
		var/pressure = environment?.return_pressure() || 0
		. += ""
		. += "Crynet Protocols: [!NS.shutdown ? "Engaged" : "Disengaged"]"
		. += "Energy Charge: [NS.cellon ? "[round(NS.cell.percent())]%" : "offline"]"
		. += "Mode: [NS.mode]"
		. += "Overall Status: [NS.healthon ? "[H.health]% healthy" : "offline"]"
		. += "Nutrition: [NS.healthon ? "[H.nutrition]" : "offline"]"
		. += "Oxygen Loss: [NS.healthon ? "[H.getOxyLoss()]" : "offline"]"
		. += "Toxins: [NS.healthon ? "[H.getToxLoss()]" : "offline"]"
		. += "Burns: [NS.healthon ? "[H.getFireLoss()]" : "offline"]"
		. += "Brute: [NS.healthon ? "[H.getBruteLoss()]" : "offline"]"
		. += "Radiation: [NS.radon ? "[H.radiation] rads" : "offline"]"
		. += "Body Temperature: [NS.healthon ? "[round(H.bodytemperature - T0C, 0.1)] C" : "offline"]"
		. += "Atmospheric Pressure: [NS.atmoson ? "[pressure] kPa" : "offline"]"
		if(NS.atmoson && environment)
			. += "Atmospheric Temperature: [round(environment.return_temperature() - T0C, 0.01)] C"
	else if(istype(H.wear_suit, /obj/item/clothing/suit/space/space_ninja))
		var/obj/item/clothing/suit/space/space_ninja/NS = H.wear_suit
		. += NS.get_status_readout(H)

/mob/living/carbon/human/Move(NewLoc, direct)
	. = ..()
	if(.)
		if(istype(wear_suit, /obj/item/clothing/suit/space/hardsuit/nano))
			var/obj/item/clothing/suit/space/hardsuit/nano/NS = wear_suit
			if(has_gravity() && !stat)
				return NS.onmove()

/datum/martial_art/nanosuit
	name = "Nanosuit strength mode"
	block_chance = 50
	id = MARTIALART_NANOSUIT

/datum/martial_art/nanosuit/proc/check_streak(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(findtext(streak,POWER_PUNCH))
		streak = ""
		PowerPunch(A,D)
		return TRUE
	if(findtext(streak,HEAD_EXPLOSION))
		streak = ""
		HeadStomp(A,D)
		return TRUE
	return FALSE

/datum/martial_art/nanosuit/proc/PowerPunch(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(!D.stat || !D.IsParalyzed())
		D.visible_message(span_warning("[A] сверхсильно бьёт [D]!") , \
						span_userdanger("[A] бьёт меня с невероятной силой!"))
		playsound(get_turf(A), 'sound/weapons/slam.ogg', 50, TRUE, -1)
		D.apply_damage(20, BRUTE)
		var/atom/throw_target = get_edge_target_turf(D, A.dir)
		if(!D.anchored)
			D.throw_at(throw_target, rand(1,2), 7, A)
		log_combat(A, D, "nanosuit slammed")
	return TRUE

/datum/martial_art/nanosuit/proc/HeadStomp(mob/living/carbon/human/A, mob/living/carbon/human/D)
	var/obj/item/bodypart/head/head = D.get_bodypart(BODY_ZONE_HEAD)
	if(head)
		head.drop_limb()
		head.drop_organs()
		D.visible_message(span_warning("[A] лупит [D] в голову, разбрызгивая мозги по полу!") , \
					span_userdanger("ВОТ БЛ-"))
		playsound(get_turf(A), 'sound/weapons/genhit1.ogg', 50, TRUE, -1)
		D.death(FALSE)
		log_combat(A, D, "head stomped")
	if(ishuman(D))
		D.bleed(10)
	D.apply_damage(40, BRUTE)
	A.do_attack_animation(D, ATTACK_EFFECT_KICK)
	return TRUE

/datum/martial_art/nanosuit/grab_act(mob/living/carbon/human/A, mob/living/carbon/D)
	if(A.grab_state >= GRAB_AGGRESSIVE)
		D.grabbedby(A, TRUE)
	else
		A.start_pulling(D, TRUE)
		if(A.pulling)
			D.stop_pulling()
			D.visible_message(span_danger("[A] загребает [D]!") , \
								span_userdanger("[A] неистово хватает меня!"))
			A.grab_state = GRAB_AGGRESSIVE //Instant aggressive grab
			log_combat(A, D, "grabbed", addition="aggressively")
	return TRUE

/datum/martial_art/nanosuit/harm_act(var/mob/living/carbon/human/A, var/mob/living/carbon/D)
	var/picked_hit_type = pick("бьёт", "пинает")
	var/bonus_damage = 15 // must exceed TRAIT_TOUGHT_DAMAGE (10) to harm tough targets
	var/quick = FALSE
	if(D.resting || !(D.mobility_flags & MOBILITY_STAND))//we can hit ourselves
		bonus_damage += 5
		picked_hit_type = "топчется по"
		if(A.zone_selected == BODY_ZONE_HEAD && D.get_bodypart(BODY_ZONE_HEAD) && (!A.resting || (A.mobility_flags & MOBILITY_STAND)))
			D.add_splatter_floor(D.loc)
			D.apply_damage(10, BRAIN)
			bonus_damage += 5
			if(D.health <= 40)
				add_to_streak("S",D)
				if(check_streak(A,D))
					return TRUE
	if(D != A && !D.stat && (!D.IsParalyzed() || !D.IsStun())) //and we can't knock ourselves the fuck out/down!
		if(A.grab_state == GRAB_AGGRESSIVE)
			A.stop_pulling() //So we don't spam the combo
			bonus_damage += 5
			D.Paralyze(15)
			D.visible_message("<span class='warning'>[A] сбивает [D] с ног!", \
							span_userdanger("[A] сбивает меня с ног!"))
			if(prob(75))
				step_away(D,A,15)
		else if(A.grab_state > GRAB_AGGRESSIVE)
			var/atom/throw_target = get_edge_target_turf(D, A.dir)
			if(!D.anchored)
				D.throw_at(throw_target, rand(1,2), 7, A)
			bonus_damage += 10
			D.Paralyze(60)
			D.visible_message("<span class='warning'>[A] бьет [D] очень сильно!", \
							span_userdanger("[A] бьет меня очень сильно"))
		else if(A.resting && (D.mobility_flags & MOBILITY_STAND)) //but we can't legsweep ourselves!
			D.visible_message("<span class='warning'>[A] ломает колено [D]!", \
								span_userdanger("[A] ломает тебе колено!"))
			playsound(get_turf(A), 'sound/effects/hit_kick.ogg', 50, TRUE, -1)
			bonus_damage += 5
			D.Paralyze(60)
			log_combat(A, D, "nanosuit leg swept")
	if(!A.resting || (A.mobility_flags & MOBILITY_STAND))
		if(prob(30))
			quick = TRUE
			A.changeNext_move(CLICK_CD_RAPID)
			.= FALSE
			add_to_streak("Q",D)
			if(check_streak(A,D))
				return TRUE
		else if(prob(35))
			D.visible_message(span_danger("[A] промахивается по [D]!") , \
							span_userdanger("[A] промахивается по мне!"))
			playsound(get_turf(D), 'sound/weapons/punchmiss.ogg', 25, TRUE, -1)
			return TRUE
	D.visible_message(span_danger("[A] [quick?"быстро":""] [picked_hit_type] [D]!") , \
					span_userdanger("[A] [quick?"быстро":""] [picked_hit_type] меня!"))
	if(picked_hit_type == "пинает" || picked_hit_type == "топчется по")
		A.do_attack_animation(D, ATTACK_EFFECT_KICK)
		playsound(get_turf(D), 'sound/weapons/cqchit2.ogg', 50, TRUE, -1)
	else
		A.do_attack_animation(D, ATTACK_EFFECT_PUNCH)
		playsound(get_turf(D), 'sound/weapons/cqchit1.ogg', 50, TRUE, -1)
	log_combat(A, D, "attacked ([name])")
	D.apply_damage(bonus_damage, BRUTE)
	if(!D.stat && D != A)
		D.Unconscious(20)
		step_away(D, A, 15)
	return TRUE

/datum/martial_art/nanosuit/disarm_act(var/mob/living/carbon/human/A, var/mob/living/carbon/D)
	var/obj/item/I = null
	A.do_attack_animation(D, ATTACK_EFFECT_DISARM)
	if(prob(70) && D != A)
		I = D.get_active_held_item()
		if(I)
			if(D.temporarilyRemoveItemFromInventory(I))
				A.put_in_hands(I)
		D.visible_message(span_danger("[A] обезоруживает [D]!") , \
							span_userdanger("[A] обезоруживает [D]!"))
		playsound(D, 'sound/weapons/cqchit1.ogg', 50, TRUE, -1)
		D.Paralyze(40)
	else
		D.visible_message(span_danger("[A] пытается обезоружить [D]!") , \
							span_userdanger("[A] пытается обезоружить [D]!"))
		playsound(D, 'sound/weapons/punchmiss.ogg', 25, TRUE, -1)
	log_combat(A, D, "disarmed with nanosuit", "[I ? " removing [I]" : ""]")
	return TRUE

/obj/proc/heavy_melee_damage()
	return HEAVY_MELEE_FORCE * 3

/mob/living/carbon/human/proc/has_heavy_melee()
	return HAS_TRAIT(src, TRAIT_HEAVY_MELEE)

/mob/living/carbon/human/proc/heavy_melee_harm(mob/living/carbon/target)
	if(!has_heavy_melee() || a_intent != INTENT_HARM)
		return FALSE
	if(!CheckActionCooldown(CLICK_CD_MELEE))
		return FALSE
	if(HAS_TRAIT(src, TRAIT_PACIFISM))
		to_chat(src, span_warning("You don't want to harm other living beings!"))
		return FALSE
	do_attack_animation(target, ATTACK_EFFECT_PUNCH)
	step_away(target, src, 15)
	var/obj/item/bodypart/temp = target.get_bodypart(pick(BODY_ZONE_CHEST, BODY_ZONE_CHEST, BODY_ZONE_CHEST, BODY_ZONE_HEAD))
	if(temp)
		var/update = temp.receive_damage(rand(HEAVY_MELEE_FORCE * 0.5, HEAVY_MELEE_FORCE), 0)
		if(update)
			target.update_damage_overlays()
	target.updatehealth()
	if(!target.stat)
		target.Unconscious(20)
	playsound(get_turf(target), 'sound/weapons/cqchit1.ogg', 50, TRUE)
	target.visible_message(span_danger("[src] бьёт [target] с силой боевого меха!"), \
		span_userdanger("[src] бьёт тебя с силой боевого меха!"), span_hear("You hear a sickening sound of flesh hitting flesh!"), COMBAT_MESSAGE_RANGE, src)
	log_combat(src, target, "heavy meleed")
	DelayNextAction(CLICK_CD_MELEE)
	return TRUE

/atom/proc/attack_heavy_melee(mob/living/carbon/human/user, does_attack_animation = FALSE)
	if(!user.has_heavy_melee())
		return FALSE
	if(!user.CheckActionCooldown(CLICK_CD_MELEE))
		return FALSE
	SEND_SIGNAL(src, COMSIG_MOB_ATTACK_HAND, user)
	if(does_attack_animation)
		log_combat(user, src, "punched", "heavy melee")
		user.do_attack_animation(src, ATTACK_EFFECT_SMASH)
	user.DelayNextAction(CLICK_CD_MELEE)
	return TRUE

/atom/proc/attack_nanosuit(mob/living/carbon/human/user, does_attack_animation = FALSE)
	return attack_heavy_melee(user, does_attack_animation)

/turf/closed/wall/attack_heavy_melee(mob/living/carbon/human/user, does_attack_animation = FALSE)
	if(user.a_intent != INTENT_HARM)
		return FALSE
	if(!..(user, TRUE))
		return FALSE
	user.visible_message(span_danger("[user] бьёт [src]!"), span_danger("You hit [src]!"), null, COMBAT_MESSAGE_RANGE)
	playsound(src, 'sound/weapons/genhit1.ogg', 50, TRUE)
	if(prob(hardness + HEAVY_MELEE_FORCE) && HEAVY_MELEE_FORCE > 20)
		dismantle_wall(1)
		playsound(src, 'sound/weapons/slam.ogg', 100, TRUE)
	else
		add_dent(WALL_DENT_HIT)
	return TRUE

/mob/living/simple_animal/attack_heavy_melee(mob/living/carbon/human/user, does_attack_animation = FALSE)
	if(user.a_intent == INTENT_HARM)
		if(!..(user, TRUE))
			return FALSE
		if(!stat)
			Unconscious(20)
		apply_damage(rand(HEAVY_MELEE_FORCE * 0.5, HEAVY_MELEE_FORCE), BRUTE)
		var/hitverb = "бьёт"
		if(mob_size < MOB_SIZE_LARGE)
			step_away(src, user, 15)
			hitverb = "влетает в"
		playsound(loc, 'sound/weapons/cqchit1.ogg', 25, TRUE, -1)
		visible_message(span_danger("[user] [hitverb] [src]!"), span_userdanger("[user] [hitverb] [src]!"), null, COMBAT_MESSAGE_RANGE)
		return TRUE

/mob/living/simple_animal/attack_nanosuit(mob/living/carbon/human/user, does_attack_animation = FALSE)
	return attack_heavy_melee(user, does_attack_animation)

/obj/item/attack_nanosuit(mob/living/carbon/human/user)
	return FALSE

/obj/effect/attack_nanosuit(mob/living/carbon/human/user, does_attack_animation = FALSE)
	return FALSE

/obj/structure/window/attack_nanosuit(mob/living/carbon/human/user, does_attack_animation = FALSE)
	if(!can_be_reached(user))
		return TRUE
	. = ..()

/obj/structure/grille/attack_nanosuit(mob/living/carbon/human/user, does_attack_animation = FALSE)
	if(user.a_intent == INTENT_HARM)
		if(!shock(user, 70))
			..(user, TRUE)
		return TRUE

/obj/attack_heavy_melee(mob/living/carbon/human/user, does_attack_animation = FALSE)//attacking objects barehand
	if(user.a_intent == INTENT_HARM)
		if(!..(user, TRUE))
			return FALSE
		visible_message(span_danger("[user] ломает [src]!") , null, null, COMBAT_MESSAGE_RANGE)
		if(density)
			playsound(src, 'sound/effects/bang.ogg', 100, TRUE)//less ear rape
		else
			playsound(src, 'sound/effects/bang.ogg', 50, TRUE)//less ear rape
		take_damage(heavy_melee_damage(), BRUTE, "melee", FALSE, get_dir(src, user))
		return TRUE
	return FALSE

/obj/attack_nanosuit(mob/living/carbon/human/user, does_attack_animation = FALSE)
	return attack_heavy_melee(user, does_attack_animation)

/obj/attacked_by(obj/item/I, mob/living/user)
	if(I.force && I.damtype == BRUTE && ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.mind?.has_martialart(MARTIALART_NANOSUIT) || H.has_heavy_melee())
			visible_message(span_danger("[H] бьёт [src] с невероятной силой при помощи [I.name]!") , null, null, COMBAT_MESSAGE_RANGE)
			take_damage(I.force*1.75, I.damtype, "melee", TRUE)//take 75% more damage with strength on
			return
	return ..()

/obj/item/throw_at(atom/target, range, speed, mob/thrower, spin = TRUE, diagonals_first = FALSE, datum/callback/callback, quickstart = TRUE, params)
	if(thrower && ishuman(thrower))
		var/mob/living/carbon/human/H = thrower
		if(istype(H.wear_suit, /obj/item/clothing/suit/space/hardsuit/nano))
			var/obj/item/clothing/suit/space/hardsuit/nano/NS = H.wear_suit
			if(NS.mode == NANO_STRENGTH)
				.=..(target, range*1.5, speed*2, thrower, spin, diagonals_first, callback)
				return
	. = ..()

/datum/martial_art/nanosuit/proc/on_attack_hand(mob/living/carbon/human/owner, atom/target, proximity)
	if(!proximity || iscarbon(target))
		return FALSE
	return target.attack_heavy_melee(owner)

/mob/living/carbon/human/UnarmedAttack(atom/A, proximity)
	var/datum/martial_art/nanosuit/style = mind?.has_martialart(MARTIALART_NANOSUIT)
	if(style)
		if(style.on_attack_hand(src, A, proximity))
			return
		else if(iscarbon(A) && !ishuman(A) && style.harm_act(src, A))
			return
	else if(has_heavy_melee() && proximity && a_intent == INTENT_HARM)
		if(iscarbon(A))
			if(heavy_melee_harm(A))
				return
		else if(A.attack_heavy_melee(src))
			return
	. = ..()

/mob/living/simple_animal/attack_hand(mob/user)
	. = ..()
	if(!ishuman(user))
		return .

	var/mob/living/carbon/human/M = user
	if(istype(M.wear_suit, /obj/item/clothing/suit/space/hardsuit/nano))
		var/obj/item/clothing/suit/space/hardsuit/nano/NS = M.wear_suit
		NS.kill_cloak()

/obj/item/clothing/suit/space/hardsuit/nano/proc/kill_cloak()
	SIGNAL_HANDLER_DOES_SLEEP
	if(mode == NANO_CLOAK)
		var/obj/item/W = Wearer.get_active_held_item()
		if(istype(W, /obj/item/gun))
			var/obj/item/gun/G = W
			if(G.suppressed && G.can_shoot())
				set_nano_energy(15)
				Wearer.filters = null
				animate(Wearer, alpha = 255, time = stealth_cloak_out)
				addtimer(CALLBACK(src, PROC_REF(resume_cloak)),CLICK_CD_RANGE,TIMER_UNIQUE|TIMER_OVERRIDE)
				return
		set_nano_energy(cell.charge,NANO_CHARGE_DELAY)

/obj/item/clothing/suit/space/hardsuit/nano/proc/resume_cloak()
	if(cell.charge && mode == NANO_CLOAK)
		Wearer.filters = filter(type="blur",size=1)
		animate(Wearer, alpha = 40, time = stealth_cloak_in)

/obj/item/storage/box/syndie_kit/nanosuit
	name = "\improper Crynet Systems kit"
	desc = "Maximum Death."

/obj/item/storage/box/syndie_kit/nanosuit/PopulateContents()
	new /obj/item/clothing/suit/space/hardsuit/nano(src)
	new /obj/item/clothing/glasses/nano_goggles(src)
	new /obj/item/clothing/gloves/tackler/combat/insulated/nano(src)
	new /obj/item/clothing/shoes/combat/coldres/nano(src)

/obj/item/implant/explosive/disintegrate
	name = "дезинтеграционный имплант"
	desc = "Прах к праху."
	icon_state = "explosive"
	actions_types = list(/datum/action/item_action/dusting_implant)
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF

/obj/item/implant/explosive/disintegrate/activate(cause)
	if(!cause || !imp_in || cause == "emp" || active)
		return FALSE
	if(cause == "action_button" && !popup)
		popup = TRUE
		var/response = tgui_alert(imp_in, "Активируем [name]? Это действие необратимо!", "[name]", list("Да", "Нет"))
		popup = FALSE
		if(response == "Нет")
			return FALSE
	active = TRUE //to avoid it triggering multiple times due to dying
	to_chat(imp_in, span_notice("Кислотный имплант активируется!"))
	imp_in.visible_message(span_warning("[imp_in] обращается в пепел!"))
	var/turf/T = get_turf(imp_in)
	message_admins("[ADMIN_LOOKUPFLW(imp_in)] has activated their [name] at [ADMIN_VERBOSEJMP(T)], with cause of [cause].")
	playsound(loc, 'sound/effects/fuse.ogg', 30, FALSE)
	imp_in.dust(TRUE, FALSE)
	qdel(src)

/obj/item/tank/internals/emergency_oxygen/recharge
	name = "self-filling miniature oxygen tank"
	desc = "An oxygen tank that uses bluespace technology to replenish it's oxygen supply."
	volume = 3
	icon_state = "emergency_tst"
	item_flags = DROPDEL
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF

/obj/item/tank/internals/emergency_oxygen/recharge/New()
	..()
	air_contents.set_moles(GAS_O2, (10*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))

/obj/item/tank/internals/emergency_oxygen/recharge/process()
	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		var/moles_val = (ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C)
		var/In_Use = H.Move()
		if(In_Use)
			return
		else
			sleep(10)
			if(air_contents.get_moles(GAS_O2) < (10*moles_val))
				air_contents.set_moles(GAS_O2, clamp(air_contents.total_moles()+moles_val,0,(10*moles_val)))
		if(air_contents.return_pressure() != initial(distribute_pressure))
			distribute_pressure = initial(distribute_pressure)

/obj/item/tank/internals/emergency_oxygen/recharge/equipped(mob/living/carbon/human/wearer, slot)
	..()
	if(slot == ITEM_SLOT_RPOCKET)
		ADD_TRAIT(src, TRAIT_NODROP, ABSTRACT_ITEM_TRAIT)
		START_PROCESSING(SSobj, src)

/obj/item/tank/internals/emergency_oxygen/recharge/dropped(mob/living/carbon/human/wearer)
	..()
	STOP_PROCESSING(SSobj, src)

/mob/living/carbon/human/proc/Nanosuit_help()
	set name = "Crytek Product Manual"
	set desc = "You read through the manual..."
	set category = "Nanosuit help"

	to_chat(src, "<b><i>Welcome to CryNet Systems user manual 1.22 rev. 6618. Today we will learn about what your new piece of hardware has to offer.</i></b>")
	to_chat(src, "<b><i>If you are reading this, you've probably alerted the entire sector about the purchase of an illegal syndicate item banned in a radius of 50 megaparsecs!</i></b>")
	to_chat(src, "<b><i>Fortunately the syndicate equipped this bad boy with high tech sensing equipment,the downside is the whole crew knows you're here.</i></b>")
	to_chat(src, "<b>Sensors</b>: Combo HUD (medical, security, robotics), thermal vision, night vision, bomb radar, user life signs monitor and bluespace communication relay.")
	to_chat(src, "<b>Passive equipment</b>: Binoculars, night vision, anti-slips, gorilla tackling gloves, self refilling mini o2 tank, nutriment pump implant, emergency medical systems and body temperature defroster.")
	to_chat(src, "<b>Press C to toggle quick mode selection.</b>")
	to_chat(src, "<b>Active modes</b>: Armor, strength, speed and cloak.")
	to_chat(src, "<span class='notice'>Armor</span>: Resist damage that would normally kill or seriously injure you. Blocks 55% of attacks at a cost of suit energy drain.")
	to_chat(src, "<span class='notice'>Cloak</span>: Become a ninja. Cloaking technology alters the outer layers to refract light through and around the suit, making the user appear almost completely invisible. Simple tasks such as attacking in any way, being hit or throwing objects cancels cloak.")
	to_chat(src, "<span class='notice'>Speed</span>: Run like a madman. Use conservatively as suit energy drains fairly quickly.")
	to_chat(src, "<span class='notice'>Strength</span>: Beat the shit out of objects or people with your fists, breaking walls like a Durand and knocking targets unconscious for two seconds. Gorilla tackling gloves let you rush targets in throw mode. You hit and throw harder with brute objects. You can't be grabbed aggressively or pushed. 25% ranged hits deflection. Toggling throw mode gives you a 75% block chance.")
	to_chat(src, "<b>Energy</b>: The suit uses a built-in self-charging battery (100%). It cannot be removed or recharged externally — no APCs, chargers, or spare cells will help.")
	to_chat(src, "<span class='notice'>Energy</span>: Check your charge in the <b>Status</b> statpanel tab (available after boot finishes). Energy slowly regenerates on its own while you are <b>not</b> in cloak mode and not recovering from heavy use.")
	to_chat(src, "<span class='notice'>Energy</span>: Cloak drains constantly; speed drains while moving; armor drains when blocking hits. After spending energy, regeneration pauses briefly — stand still in armor mode and wait.")
	to_chat(src, "<span class='notice'>Energy</span>: At 0% charge the suit forces armor mode. EMP attacks can drain energy and temporarily shut down all systems until the suit reboots.")
	to_chat(src, "<span class='notice'>Aggressive grab</span>: Your grabs start aggressive.")
	to_chat(src, "<span class='notice'>Robust push</span>: Your disarms have a 70% chance of knocking an opponent down for 4 seconds.")
	to_chat(src, "<span class='notice'>MMA master</span>: Harm intents deals more damage, occasionally trigger series of fast hits and you can leg sweep while lying down.")
	to_chat(src, "<span class='notice'>Highschool bully</span>: Grab someone and harm intent them to deliver a deadly knock down punch.")
	to_chat(src, "<span class='notice'>Knockout master</span>: Tighten your grip and harm intent to deliver a very deadly knock out punch.")
	to_chat(src, "<span class='notice'>Mike Tyson</span>: Getting 2 successful quick punches and a regular punch sends your victim flying back.")
	to_chat(src, "<span class='notice'>Head stomp special</span>: Target victims head while they're knocked down, stomp until their brain explodes.")
	to_chat(src, "<b><i>User warning: The suit is equipped with an implant which vaporizes the suit and user upon request or death.</i></b>")

/obj/item/stock_parts/cell/nano
	name = "nanosuit self charging battery"
	maxcharge = 100
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF

/obj/item/clothing/suit/space/hardsuit/nano/proc/check_menu(mob/living/user)
	if(!user)
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/item/clothing/suit/space/hardsuit/nano/proc/open_mode_menu(mob/living/user)
	var/list/choices = list(
	"armor" = image(icon = 'modular_bluemoon/icons/mob/nanosuit/actions_nanosuit.dmi', icon_state = "armor_menu"),
	"speed" = image(icon = 'modular_bluemoon/icons/mob/nanosuit/actions_nanosuit.dmi', icon_state = "speed_menu"),
	"cloak" = image(icon = 'modular_bluemoon/icons/mob/nanosuit/actions_nanosuit.dmi', icon_state = "cloak_menu"),
	"strength" = image(icon = 'modular_bluemoon/icons/mob/nanosuit/actions_nanosuit.dmi', icon_state = "strength_menu")
	)
	var/choice = show_radial_menu(user,user, choices, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE)
	if(!check_menu(user))
		return
	switch(choice)
		if("armor")
			toggle_mode(NANO_ARMOR)
			return
		if("speed")
			toggle_mode(NANO_SPEED)
			return
		if("cloak")
			toggle_mode(NANO_CLOAK)
			return
		if("strength")
			toggle_mode(NANO_STRENGTH)
			return

//Nanosuit uplink item, available in all traitor rounds
/datum/uplink_item/dangerous/nanosuit
	name = "Нанокостюм CryNet"
	desc = "Станьте постчеловеческим воином с этим тяжелобронированным и мощным костюмом. Нанокостюм нельзя снять, а также он предупреждает экипаж о вашем местоположении, если вы его надели."
	item = /obj/item/storage/box/syndie_kit/nanosuit
	cost = 30
	surplus = 1
	cant_discount = TRUE
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)
	hijack_only = TRUE

/datum/movespeed_modifier/nanospeed
	movetypes = GROUND
	multiplicative_slowdown = -0.65
	id = NANO_SPEED

/obj/item/clothing/suit/space/hardsuit/nano/proc/nano_suit_accepts_s_store(obj/item/I)
	if(istype(I, /obj/item/tank/internals))
		return TRUE
	if(istype(I, /obj/item/gun) || istype(I, /obj/item/melee) || istype(I, /obj/item/grenade) || istype(I, /obj/item/nullrod))
		return TRUE
	if(istype(I, /obj/item/ammo_box) || istype(I, /obj/item/ammo_casing))
		return TRUE
	if(istype(I, /obj/item/spear) || istype(I, /obj/item/claymore) || istype(I, /obj/item/throwing_star))
		return TRUE
	return FALSE

/datum/species/can_equip(obj/item/I, slot, disable_warning, mob/living/carbon/human/H, bypass_equip_delay_self = FALSE, clothing_check = FALSE, list/return_warning)
	if(slot == ITEM_SLOT_SUITSTORE && istype(H?.wear_suit, /obj/item/clothing/suit/space/hardsuit/nano))
		if(HAS_TRAIT(I, TRAIT_NODROP))
			return FALSE
		if(H.s_store)
			return FALSE
		if(!H.wear_suit)
			if(return_warning)
				return_warning[1] = "<span class='warning'>You need a suit before you can attach this [I.name]!</span>"
			return FALSE
		var/obj/item/clothing/suit/space/hardsuit/nano/S = H.wear_suit
		if(I.w_class > WEIGHT_CLASS_BULKY)
			if(return_warning)
				return_warning[1] = "The [I.name] is too big to attach."
			return FALSE
		if(istype(I, /obj/item/modular_computer/pda) || istype(I, /obj/item/pen) || S.nano_suit_accepts_s_store(I))
			return TRUE
		return FALSE
	return ..()
