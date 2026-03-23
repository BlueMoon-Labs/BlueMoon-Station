///Плазме меч
/obj/item/melee/transforming/plasmasword
	name = "Plasma Sword"
	desc = "Клинок из чистой плазмы разогретой от двух до девяти тысяч градусов по желанию владельца. Силовой модуль выполненный в виде рукояти разогревает газ и поддерживает его форму сильнейшим магнитным полем. Кажется таких клинков не выпускали со времён открытия световых мечей."
	icon_state = "psword_2k"
	icon_state_on = "psword_2k_on"
	icon = 'modular_bluemoon/Ren/Icons/Obj/misc.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	armour_penetration = 35
	force_on = 35
	damtype = "brute"
	throwforce_on = 20
	force = 3
	throwforce = 5
	hitsound = "swing_hit" //it starts deactivated plasma_hit
	hitsound_on = 'modular_bluemoon/Ren/Sound/4.111.ogg'
	transform_on_sound = 'modular_bluemoon/Ren/Sound/2.1.ogg'
	transform_off_sound = 'modular_bluemoon/Ren/Sound/2.1.ogg'
	attack_verb_off = list("tapped", "poked")
	throw_speed = 3
	throw_range = 5
	sharpness = SHARP_EDGED
	embedding = list("embed_chance" = 75, "impact_pain_mult" = 10)
	armour_penetration = 35
	block_chance = 50
	item_flags = NEEDS_PERMIT | ITEM_CAN_PARRY
	block_parry_data = /datum/block_parry_data/energy_sword
	light_color = "#FF3900"
	var/safe = 0

	unique_reskin = list(
		"Red safe" = list(icon_state_on = "psword_2k_alt_on", icon_state = "psword_2k_alt", safe = 1),
		"Blue" = list(icon_state = "psword_2k", icon_state_on = "psword_12k_on", light_color = "#20214f, "),
		"Blue safe" = list(icon_state = "psword_2k_alt", icon_state_on = "psword_12k_alt_on", light_color = "#20214f", safe = 1),
		"Lavender" = list(icon_state = "psword_2k", icon_state_on = "psword_15k_on", light_color = "a2a2d0"),
		"Lavender safe" = list(icon_state = "psword_2k_alt", icon_state_on = "psword_15k_alt_on", light_color = "a2a2d0", safe = 1)
	)

/obj/item/melee/transforming/plasmasword/transform_weapon(mob/living/user, supress_message_text)
	. = ..()
	if(.)
		if(active)
			START_PROCESSING(SSobj, src)
			set_light(3)
			do_sparks(3, TRUE, src)
		else
			STOP_PROCESSING(SSobj, src)
			set_light(0)

/obj/item/melee/transforming/plasmasword/transform_weapon(mob/living/user, supress_message_text)
	. = ..()
	if(active)
		AddElement(/datum/element/sword_point)
	else
		RemoveElement(/datum/element/sword_point)

/obj/item/melee/transforming/plasmasword/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(!active)
		return NONE
	if(is_energy_reflectable_projectile(object) && (attack_type & ATTACK_TYPE_PROJECTILE) && prob(50))
		owner.visible_message("<span class='danger'>[owner] just melted bullet in air!</span>")
		playsound(src, pick('modular_bluemoon/Ren/Sound/plasma_hit.ogg'), 75, 1)
		var/turf/owner_turf = get_turf(owner)
		new /obj/effect/decal/cleanable/plasma(drop_location(owner_turf))
		new /obj/effect/temp_visual/scythe_block(owner_turf)
		block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_RETURN_TO_SENDER
		return BLOCK_SUCCESS | BLOCK_REDIRECTED | BLOCK_SHOULD_REDIRECT
	return ..()

/obj/item/melee/transforming/energy/sword/on_active_parry(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, list/block_return, parry_efficiency, parry_time)
	. = ..()
	if(parry_efficiency >= 100)		// perfect parry
		block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_RETURN_TO_SENDER
		. |= BLOCK_SHOULD_REDIRECT


//Плазма коса
/obj/item/plasmascythe
	name = "plasma axe"
	desc = "Handle with care."
	icon_state = "plasma_axealt"	// Прошло голосование за смену спрайта с аниме косы на топор
	var/icon_state_on = "plasma_axealt_on"
	icon = 'modular_bluemoon/Ren/Icons/Obj/misc.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/64_64_l.dmi'
	righthand_file =  'modular_bluemoon/Ren/Icons/Mob/64_64_r.dmi'
	inhand_x_dimension = -2
	inhand_y_dimension = -2
	force = 3
	damtype = "brute"
	throwforce = 5
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_SMALL
	item_flags = SLOWS_WHILE_IN_HAND
	var/w_class_on = WEIGHT_CLASS_BULKY
	heat = 300
	hitsound = "swing_hit"
	var/hitsound_on = 'modular_bluemoon/Ren/Sound/4.111.ogg'
	armour_penetration = 70
	light_color = "#FF3900"
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	max_integrity = 200
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 70)
	resistance_flags = FIRE_PROOF
	wound_bonus = 7
	bare_wound_bonus = 13
	block_parry_data = /datum/block_parry_data/dual_esword
	block_chance = 75
	/// Can this reflect all energy projectiles?
	var/can_reflect = TRUE
	var/brightness_on = 6 //TWICE AS BRIGHT AS A REGULAR ESWORD
	var/spinnable = TRUE
	total_mass = 0.4 //Survival flashlights typically weigh around 5 ounces.
	var/total_mass_on = 3.4
	var/wielded = FALSE // track wielded status on item
	var/slowdown_wielded = 0
	unique_reskin = list(
		"scythe" = list(name = "plasma scythe", icon_state_on = "plasma_scythe_on", icon_state = "plasma_scythe", light_color = "#FF3900" ), // Прошло голосование за смену спрайта с аниме косы на топор
		"old axe" = list(icon_state_on = "plasma_axe_on", light_color = "#FF3900", icon_state = "plasma_axe" ),
		"12000 kelvin scythe" = list(icon_state_on = "plasma_scythe_blue_on", icon_state = "plasma_scythe", light_color = "#20214f" ),
		"30000 kelvin scythe" = list(icon_state_on = "plasma_scythe_green_on", icon_state = "plasma_scythe", light_color = "#1c542d" )
	)

/obj/effect/temp_visual/scythe_block
	name = "scythe block"
	desc = "A shimmering plasma blade."
	icon = 'modular_bluemoon/Ren/Icons/Obj/misc.dmi'
	layer = FLY_LAYER
	light_range = 2
	duration = 5
	light_color = "#ff9900"
	color = "#ff9900"
	var/number

/obj/effect/temp_visual/scythe_block/blue
	color = "#20214f"
	light_color = "#20214f"

/obj/effect/temp_visual/scythe_block/green
	color = "#1c542d"
	light_color = "#1c542d"

/obj/effect/temp_visual/scythe_block/Initialize(mapload)
	. = ..()
	if(!number)
		number = rand(3)
	icon_state = "deflect[number]"


/obj/item/plasmascythe/directional_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return, override_direction)
	if((attack_type & ATTACK_TYPE_PROJECTILE) && is_energy_reflectable_projectile(object))
		block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_RETURN_TO_SENDER
		return BLOCK_SHOULD_REDIRECT | BLOCK_SUCCESS | BLOCK_REDIRECTED
	return ..()

/obj/item/plasmascythe/on_active_parry(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, list/block_return, parry_efficiency, parry_time)
	. = ..()
	if(parry_efficiency >= 90)
		block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_RETURN_TO_SENDER
		. |= BLOCK_SHOULD_REDIRECT

/obj/item/plasmascythe/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(!wielded)
		return NONE
	if((attack_type & ATTACK_TYPE_PROJECTILE) && is_energy_reflectable_projectile(object))
		block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_RETURN_TO_SENDER
		owner.visible_message("<span class='danger'>[owner] just reflected the beam in air!</span>")
		playsound(src, pick('modular_bluemoon/Ren/Sound/plasma_hit.ogg'), 75, 1)
		var/turf/owner_turf = get_turf(owner)
		if(icon_state == "plasma_scythe_on" || icon_state == "plasma_axe_on" )
			new /obj/effect/temp_visual/scythe_block(owner_turf)
		if(icon_state == "plasma_scythe_blue_on")
			new /obj/effect/temp_visual/scythe_block/blue(owner_turf)
		if(icon_state == "plasma_scythe_green_on")
			new /obj/effect/temp_visual/scythe_block/green(owner_turf)
		new /obj/effect/decal/cleanable/plasma((owner_turf))
		return BLOCK_SHOULD_REDIRECT | BLOCK_SUCCESS | BLOCK_REDIRECTED
	if((attack_type & ATTACK_TYPE_PROJECTILE) && !is_energy_reflectable_projectile(object))
		return BLOCK_NONE
	return ..()

/obj/item/plasmascythe/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/plasmascythe/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded=3, force_wielded=45, \
					wieldsound='modular_bluemoon/Ren/Sound/2.1.ogg', unwieldsound='modular_bluemoon/Ren/Sound/2.1.ogg')

/// Triggered on wield of two handed item
/// Specific hulk checks due to reflection chance for balance issues and switches hitsounds.
/obj/item/plasmascythe/proc/on_wield(obj/item/source, mob/living/carbon/user)
	if(user.has_dna() && user.dna.check_mutation(HULK))
		to_chat(user, "<span class='warning'>You lack the grace to wield this!</span>")
		return COMPONENT_TWOHANDED_BLOCK_WIELD
	wielded = TRUE
	sharpness = SHARP_EDGED
	w_class = w_class_on
	total_mass = total_mass_on
	icon_state = icon_state_on
	hitsound = hitsound_on
	slowdown += slowdown_wielded
	heat = 3800
	START_PROCESSING(SSobj, src)
	set_light(brightness_on)
	AddElement(/datum/element/sword_point)
	do_sparks(5, TRUE, src)
	item_flags |= (ITEM_CAN_BLOCK|ITEM_CAN_PARRY)

/// Triggered on unwield of two handed item
/// switch hitsounds
/obj/item/plasmascythe/proc/on_unwield(obj/item/source, mob/living/carbon/user)
	sharpness = initial(sharpness)
	w_class = initial(w_class)
	total_mass = initial(total_mass)
	icon_state = initial(icon_state)
	wielded = FALSE
	hitsound = "swing_hit"
	slowdown -= slowdown_wielded
	heat = initial(heat)
	STOP_PROCESSING(SSobj, src)
	set_light(0)
	RemoveElement(/datum/element/sword_point)
	item_flags &= ~(ITEM_CAN_BLOCK|ITEM_CAN_PARRY)
	if(icon_state_on == "plasma_axe_on")
		icon_state = "plasma_axe"
	else if(icon_state_on == "plasma_scythe_on" || icon_state_on == "plasma_scythe_blue_on" || icon_state_on == "plasma_scythe_green_on")
		icon_state = "plasma_scythe"

/obj/item/plasmascythe/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/item/plasmascythe/suicide_act(mob/living/carbon/user)
	if(wielded)
		user.visible_message("<span class='suicide'>[user] begins spinning way too fast! It looks like [user.p_theyre()] trying to commit suicide!</span>")
		var/obj/item/bodypart/head/myhead = user.get_bodypart(BODY_ZONE_HEAD)//stole from chainsaw code
		var/obj/item/organ/brain/B = user.getorganslot(ORGAN_SLOT_BRAIN)
		B.organ_flags &= ~ORGAN_VITAL	//this cant possibly be a good idea
		var/randdir
		for(var/i in 1 to 24)//like a headless chicken!
			if(user.is_holding(src))
				randdir = pick(GLOB.alldirs)
				user.Move(get_step(user, randdir),randdir)
				user.emote("spin")
				if (i == 3 && myhead)
					myhead.drop_limb()
				sleep(3)
			else
				user.visible_message("<span class='suicide'>[user] panics and starts choking to death!</span>")
				return OXYLOSS
	else
		user.visible_message("<span class='suicide'>[user] begins beating themself to death with \the [src]'s handle! It probably would've been cooler if [user.ru_who()] turned it on first!</span>")
	return BRUTELOSS

/obj/item/plasmascythe/attack(mob/target, mob/living/carbon/human/user)
	if(user.has_dna() && user.dna.check_mutation(HULK))
		to_chat(user, "<span class='warning'>You grip the blade too hard and accidentally drop it!</span>")
		user.dropItemToGround(src)
		return
	..()
	if(HAS_TRAIT(user, TRAIT_CLUMSY) && (wielded) && prob(40))
		impale(user)
		return
	if(spinnable && (wielded) && prob(50))
		INVOKE_ASYNC(src, PROC_REF(jedi_spin), user)

/obj/item/plasmascythe/proc/jedi_spin(mob/living/user)
	for(var/i in list(NORTH,SOUTH,EAST,WEST,EAST,SOUTH,NORTH,SOUTH,EAST,WEST,EAST,SOUTH))
		user.setDir(i)
		if(i == WEST)
			user.emote("flip")
		sleep(1)

/obj/item/plasmascythe/proc/impale(mob/living/user)
	to_chat(user, "<span class='warning'>You twirl around a bit before losing your balance and impaling yourself on [src].</span>")
	if (force)
		user.take_bodypart_damage(20,25)
	else
		user.adjustStaminaLoss(25)

/obj/item/plasmascythe/attack_hulk(mob/living/carbon/human/user, does_attack_animation = 0)  //In case thats just so happens that it is still activated on the groud, prevents hulk from picking it up
	if(wielded)
		to_chat(user, "<span class='warning'>You can't pick up such dangerous item with your meaty hands without losing fingers, better not to!</span>")
		return TRUE

/obj/item/plasmascythe/ignition_effect(atom/A, mob/user)
	// same as /obj/item/melee/transforming/energy, mostly
	if(!wielded)
		return ""
	var/in_mouth = ""
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(C.wear_mask)
			in_mouth = ", barely missing [user.ru_ego()] nose"
	. = "<span class='warning'>[user] swings [user.ru_ego()] [name][in_mouth]. [user.ru_who(TRUE)] light[user.p_s()] [user.ru_ego()] [A.name] in the process.</span>"
	playsound(loc, hitsound, get_clamped_volume(), 1, -1)
	add_fingerprint(user)
	// Light your candles while spinning around the room
	if(spinnable)
		INVOKE_ASYNC(src, PROC_REF(jedi_spin), user)

/obj/item/plasmascythe/toy
	name = "Toy Plasma Scythe"
	desc = "A cheap, plastic replica of a plasma scythe. Realistic lights and sounds! Ages 8 and up."
	force = 0
	throwforce = 0
	heat = 0
	armour_penetration = 0
	block_parry_data = null
	attack_verb = list("attacked", "struck", "hit")
	total_mass_on = TOTAL_MASS_TOY_SWORD
	sharpness = SHARP_NONE
	wound_bonus = 0
	bare_wound_bonus = 0

/obj/item/plasmascythe/toy/ComponentInitialize()
	AddComponent(/datum/component/two_handed, force_unwielded=0, force_wielded=0, \
					wieldsound='modular_bluemoon/Ren/Sound/2.1.ogg', unwieldsound='modular_bluemoon/Ren/Sound/2.1.ogg')

/obj/item/plasmascythe/toy/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	return BLOCK_NONE
