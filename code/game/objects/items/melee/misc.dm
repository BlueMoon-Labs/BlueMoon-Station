/obj/item/melee
	item_flags = NEEDS_PERMIT
	wound_bonus = 4

/obj/item/melee/proc/check_martial_counter(mob/living/carbon/human/target, mob/living/carbon/human/user)
	if(target.check_martial_melee_block())
		target.visible_message("<span class='danger'>[target.name] blocks your attack!</span>",
					"<span class='userdanger'>You block the attack!</span>")
		return TRUE

/obj/item/melee
	var/hole = CUM_TARGET_VAGINA

/obj/item/melee/CtrlShiftClick(mob/living/carbon/human/user as mob)
	hole = hole == CUM_TARGET_VAGINA ? CUM_TARGET_ANUS : CUM_TARGET_VAGINA
	to_chat(user, span_notice("Я целюсь в... [hole]."))

/obj/item/melee/attack(mob/living/target, mob/living/user)
	if(user.zone_selected == BODY_ZONE_PRECISE_GROIN && user.a_intent == INTENT_HELP)
		do_eblya(target, user)
	else
		. = ..()

/obj/item/melee/baton/attack(mob/living/target, mob/living/user)
	if(user.zone_selected == BODY_ZONE_PRECISE_GROIN && user.a_intent == INTENT_HELP)
		do_eblya(target, user)
	else
		. = ..()

/obj/item/melee/proc/do_eblya(mob/living/target, mob/living/user)
	var/message = ""
	var/lust_amt = 0
	if(!user.canUseTopic(target, BE_CLOSE))
		return
	user.DelayNextAction(CLICK_CD_MELEE)
	if(ishuman(target) && (target?.client?.prefs?.toggles & VERB_CONSENT))
		if(user.zone_selected == BODY_ZONE_PRECISE_GROIN)
			switch(hole)
				if(CUM_TARGET_VAGINA)
					if(target.has_vagina() == HAS_EXPOSED_GENITAL)
						message = (user == target) ? pick("крепко обхватывает '\the [src]' и начинает пихать это прямо в свою киску.", "запихивает '\the [src]' в свою киску", "постанывает и садится на '\the [src]'.") : pick("трахает <b>[target]</b> прямо в киску с помощью '\the [src]'.", "засовывает '\the [src]' прямо в киску <b>[target]</b>.")
						lust_amt = NORMAL_LUST
				if(CUM_TARGET_ANUS)
					if(target.has_anus() == HAS_EXPOSED_GENITAL)
						message = (user == target) ? pick("крепко обхватывает '\the [src]' и начинает пихать это прямо в свою попку.","запихивает '\the [src]' прямо в свою собственную попку.", "постанывает и садится на '\the [src]'.") : pick("трахает <b>[target]</b> прямо в попку '\the [src]'.", "активно суёт '\the [src]' прямо в попку <b>[target]</b>.")
						lust_amt = NORMAL_LUST
	if(message)
		user.visible_message(span_lewd("<b>[user]</b> [message]"))
		target.handle_post_sex(lust_amt, null, user)

		switch (hole)
			if (CUM_TARGET_VAGINA)
				user.client?.plug13.send_emote(PLUG13_EMOTE_VAGINA, min(lust_amt*3, 100), PLUG13_DURATION_NORMAL)
			if (CUM_TARGET_ANUS)
				user.client?.plug13.send_emote(PLUG13_EMOTE_ANUS, min(lust_amt*3, 100), PLUG13_DURATION_NORMAL)

		playsound(loc, pick('modular_sand/sound/interactions/bang4.ogg',
							'modular_sand/sound/interactions/bang5.ogg',
							'modular_sand/sound/interactions/bang6.ogg'), 70, 1, -1)
		if(!HAS_TRAIT(target, TRAIT_LEWD_JOB))
			new /obj/effect/temp_visual/heart(target.loc)

/obj/item/melee/chainofcommand
	name = "Chain Of Command"
	desc = "A tool used by great men to placate the frothing masses."
	icon_state = "chain"
	item_state = "chain"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	force = 14
	throwforce = 10
	wound_bonus = 8
	bare_wound_bonus = 10
	reach = 2
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb = list("flogged", "whipped", "lashed", "disciplined")
	hitsound = 'sound/weapons/chainhit.ogg'
	custom_materials = list(/datum/material/iron = 1000)

/obj/item/melee/chainofcommand/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is strangling себя with [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return (OXYLOSS)

/obj/item/melee/synthetic_arm_blade
	name = "Synthetic Arm Blade"
	desc = "A grotesque blade that on closer inspection seems made of synthetic flesh, it still feels like it would hurt very badly as a weapon."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "arm_blade"
	item_state = "arm_blade"
	lefthand_file = 'icons/mob/inhands/antag/changeling_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/changeling_righthand.dmi'
	w_class = WEIGHT_CLASS_HUGE
	force = 20
	throwforce = 10
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("attacked", "impaled", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	sharpness = SHARP_EDGED
	total_mass = TOTAL_MASS_HAND_REPLACEMENT

/obj/item/melee/synthetic_arm_blade/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 60, 80) //very imprecise

/obj/item/melee/sabre
	name = "Officer's Sabre"
	desc = "Изящное оружие, мономолекулярная кромка которого способно с легкостью рассекать плоть и кости."
	icon_state = "sabre"
	item_state = "sabre"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	flags_1 = CONDUCT_1
	obj_flags = UNIQUE_RENAME
	force = 18
	throwforce = 15
	w_class = WEIGHT_CLASS_BULKY
	block_chance = 50
	armour_penetration = 75
	sharpness = WOUND_SLASH
	attack_verb = list("slashed", "cut")
	hitsound = 'sound/weapons/rapierhit.ogg'
	custom_materials = list(/datum/material/iron = 1000)
	total_mass = 3.4
	item_flags = NEEDS_PERMIT | ITEM_CAN_PARRY
	block_parry_data = /datum/block_parry_data/captain_saber

/datum/block_parry_data/captain_saber
	can_block_directions = BLOCK_DIR_NORTH | BLOCK_DIR_NORTHEAST | BLOCK_DIR_NORTHWEST | BLOCK_DIR_WEST | BLOCK_DIR_EAST
	block_damage_absorption = 5
	block_damage_multiplier = 0.15
	block_damage_multiplier_override = list(
		TEXT_ATTACK_TYPE_MELEE = 0.25
	)
	block_start_delay = 0		// instantaneous block
	block_stamina_cost_per_second = 2.5
	block_stamina_efficiency = 3
	block_lock_sprinting = TRUE
	// no attacking while blocking
	block_lock_attacking = TRUE
	block_projectile_mitigation = 85
	// more efficient vs projectiles
	block_stamina_efficiency_override = list(
		TEXT_ATTACK_TYPE_PROJECTILE = 6
	)

	parry_time_windup = 0
	parry_time_active = 12
	parry_time_spindown = 0
	parry_time_windup_visual_override = 1
	parry_time_active_visual_override = 3
	parry_time_spindown_visual_override = 4
	parry_flags = PARRY_DEFAULT_HANDLE_FEEDBACK
	parry_time_perfect = 2		// first ds isn't perfect
	parry_time_perfect_leeway = 1
	parry_imperfect_falloff_percent = 10
	parry_efficiency_considered_successful = 25		// VERY generous
	parry_failed_stagger_duration = 3 SECONDS

/obj/item/melee/sabre/directional_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return, override_direction)
	if((attack_type & ATTACK_TYPE_PROJECTILE) && is_bullet_reflectable_projectile(object))
		var/reflect_chance = HAS_TRAIT(owner, TRAIT_FENCER) ? 60 : 20 // Определение шанса на рефлект.
		if(prob(reflect_chance))
			block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_RETURN_TO_SENDER
			return BLOCK_SUCCESS | BLOCK_REDIRECTED | BLOCK_SHOULD_REDIRECT
	return ..()

/obj/item/melee/sabre/on_active_parry(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, list/block_return, parry_efficiency, parry_time)
	. = ..()
	if(parry_efficiency >= 90)		// perfect parry
		block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_DEFLECT
		. |= BLOCK_SHOULD_REDIRECT

/obj/item/melee/sabre/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(is_bullet_reflectable_projectile(object) && (attack_type & ATTACK_TYPE_PROJECTILE))
		var/reflect_chance = HAS_TRAIT(owner, TRAIT_FENCER) ? 60 : 20 // Определение шанса на рефлект.
		if(prob(reflect_chance))
			block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_RETURN_TO_SENDER			//no you
			owner.visible_message("<span class='danger'>[owner] redirected the sent projectile with his [src]!</span>")
			playsound(src, pick('sound/weapons/bulletflyby.ogg', 'sound/weapons/bulletflyby2.ogg', 'sound/weapons/bulletflyby3.ogg'), 75, 1)
			return BLOCK_SHOULD_REDIRECT | BLOCK_SUCCESS | BLOCK_REDIRECTED
	return ..()

/obj/item/melee/sabre/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 30, 95, 5) //fast and effective, but as a sword, it might damage the results.
	AddElement(/datum/element/sword_point)

/obj/item/melee/sabre/on_exit_storage(datum/component/storage/S)
	var/obj/item/storage/belt/sabre/B = S.parent
	if(istype(B))
		playsound(B, 'sound/items/unsheath.ogg', 25, 1)
	..()

/obj/item/melee/sabre/on_enter_storage(datum/component/storage/S)
	var/obj/item/storage/belt/sabre/B = S.parent
	if(istype(B))
		playsound(B, 'sound/items/sheath.ogg', 25, 1)
	..()

/obj/item/melee/sabre/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "sabre") // todo: make this and its rapier equivalent work for the inhands too

/obj/item/melee/sabre/get_worn_belt_overlay(icon_file)
	return mutable_appearance(icon_file, "-sabre")

/obj/item/melee/sabre/suicide_act(mob/living/user)
	user.visible_message("<span class='suicide'>[user] is trying to cut off all [user.ru_ego()] limbs with [src]! it looks like [user.p_theyre()] trying to commit suicide!</span>")
	var/i = 0
	ADD_TRAIT(src, TRAIT_NODROP, SABRE_SUICIDE_TRAIT)
	if(iscarbon(user))
		var/mob/living/carbon/Cuser = user
		var/obj/item/bodypart/holding_bodypart = Cuser.get_holding_bodypart_of_item(src)
		var/list/limbs_to_dismember
		var/list/arms = list()
		var/list/legs = list()
		var/obj/item/bodypart/bodypart

		for(bodypart in Cuser.bodyparts)
			if(bodypart == holding_bodypart)
				continue
			if(bodypart.body_part & ARMS)
				arms += bodypart
			else if (bodypart.body_part & LEGS)
				legs += bodypart

		limbs_to_dismember = arms + legs
		if(holding_bodypart)
			limbs_to_dismember += holding_bodypart

		var/speedbase = abs((4 SECONDS) / limbs_to_dismember.len)
		for(bodypart in limbs_to_dismember)
			i++
			addtimer(CALLBACK(src, PROC_REF(suicide_dismember), user, bodypart), speedbase * i)
	addtimer(CALLBACK(src, PROC_REF(manual_suicide), user), (5 SECONDS) * i)
	return MANUAL_SUICIDE

/obj/item/melee/sabre/proc/suicide_dismember(mob/living/user, obj/item/bodypart/affecting)
	if(!QDELETED(affecting) && affecting.dismemberable && affecting.owner == user && !QDELETED(user))
		playsound(user, hitsound, 25, 1)
		affecting.dismember(BRUTE)
		user.adjustBruteLoss(20)

/obj/item/melee/sabre/proc/manual_suicide(mob/living/user, originally_nodropped)
	if(!QDELETED(user))
		user.adjustBruteLoss(200)
		user.death(FALSE)
	REMOVE_TRAIT(src, TRAIT_NODROP, SABRE_SUICIDE_TRAIT)

/obj/item/melee/rapier
	name = "Plastitanium Rapier"
	desc = "A thin blade made of plastitanium with a diamond tip. It appears to be coated in a persistent layer of an unknown substance."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "rapier"
	item_state = "rapier"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 15
	throwforce = 25
	armour_penetration = 200 //Apparently this gives it the ability to pierce block
	flags_1 = CONDUCT_1
	obj_flags = UNIQUE_RENAME
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_POINTY //It cant be sharpend cook -_-
	attack_verb = list("stabs", "punctures", "pierces", "pokes")
	hitsound = 'sound/weapons/rapierhit.ogg'
	total_mass = 0.4
	item_flags = ITEM_CAN_PARRY | NEEDS_PERMIT
	block_parry_data = /datum/block_parry_data/traitor_rapier

// Fast, efficient parry.
/datum/block_parry_data/traitor_rapier
	parry_time_windup = 0
	parry_time_active = 10
	parry_time_spindown = 0
	parry_time_active_visual_override = 3
	parry_time_spindown_visual_override = 2
	parry_flags = PARRY_DEFAULT_HANDLE_FEEDBACK | PARRY_LOCK_ATTACKING
	parry_time_perfect = 2
	parry_time_perfect_leeway = 2
	parry_time_perfect_leeway_override = list(
		TEXT_ATTACK_TYPE_PROJECTILE = 1
	)
	parry_imperfect_falloff_percent = 30
	parry_efficiency_to_counterattack = 100
	parry_efficiency_considered_successful = 1
	parry_data = list(
		PARRY_KNOCKDOWN_ATTACKER = 10,
		PARRY_DISARM_ATTACKER = TRUE
	)
	parry_efficiency_perfect = 100
	parry_stamina_cost = 5
	parry_failed_stagger_duration = 2 SECONDS
	parry_automatic_enabled = TRUE
	parry_cooldown = 0

/obj/item/melee/rapier/active_parry_reflex_counter(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, list/return_list, parry_efficiency, list/effect_text)
	. = ..()
	if((attack_type & ATTACK_TYPE_PROJECTILE) && (parry_efficiency >= 100))
		. |= BLOCK_SHOULD_REDIRECT
		return_list[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_DEFLECT

/obj/item/melee/rapier/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 20, 65, 0)

/obj/item/melee/rapier/on_exit_storage(datum/component/storage/S)
	var/obj/item/storage/belt/sabre/rapier/B = S.parent
	if(istype(B))
		playsound(B, 'sound/items/unsheath.ogg', 25, 1)
	..()

/obj/item/melee/rapier/on_enter_storage(datum/component/storage/S)
	var/obj/item/storage/belt/sabre/rapier/B = S.parent
	if(istype(B))
		playsound(B, 'sound/items/sheath.ogg', 25, 1)
	..()

/obj/item/melee/rapier/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "rapier") // todo: same as sabre

/obj/item/melee/rapier/get_worn_belt_overlay(icon_file)
	return mutable_appearance(icon_file, "-rapier")

/obj/item/melee/rapier/attack(mob/living/target, mob/living/user)
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

/obj/item/melee/classic_baton
	name = "police baton"
	desc = "A wooden truncheon for beating criminal scum."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "baton"
	item_state = "classic_baton"
	lefthand_file = 'icons/mob/inhands/equipment/security_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/security_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	force = 12 //9 hit crit
	w_class = WEIGHT_CLASS_NORMAL
	var/stun_stam_cost_coeff = 1.25
	var/hardstun_ds = TRUE
	var/softstun_ds = 0
	var/stam_dmg = 30
	var/cooldown_check = 0 // Used internally, you don't want to modify
	var/cooldown = 13 // Default wait time until can stun again.
	/// block mitigation needed to prevent knockdown/disarms
	var/block_percent_to_counter = 50
	var/stun_time_silicon = 60 // How long it stuns silicons for - 6 seconds.
	var/affect_silicon = FALSE // Does it stun silicons.
	var/on_sound // "On" sound, played when switching between able to stun or not.
	var/on_stun_sound = 'sound/effects/woodhit.ogg' // Default path to sound for when we stun.
	var/stun_animation = TRUE // Do we animate the "hit" when stunning.
	var/on = TRUE // Are we on or off
	var/on_icon_state // What is our sprite when turned on
	var/off_icon_state // What is our sprite when turned off
	var/on_item_state // What is our in-hand sprite when turned on
	var/force_on // Damage when on - not stunning
	var/force_off // Damage when off - not stunning
	var/weight_class_on // What is the new size class when turned on
	var/sword_point = TRUE

	var/full_effect_on_superheavy_characters = FALSE // BLUEMOON ADD - если включено, то оглушение и падение от удара этим оружием работает в полную силу.

	wound_bonus = 5

/obj/item/melee/classic_baton/Initialize(mapload)
	. = ..()
	if(sword_point)
		AddElement(/datum/element/sword_point)

// Description for trying to stun when still on cooldown.
/obj/item/melee/classic_baton/proc/get_wait_description()
	return

// Description for when turning their baton "on"
/obj/item/melee/classic_baton/proc/get_on_description()
	. = list()
	.["local_on"] = "<span class ='warning'>You extend the baton.</span>"
	.["local_off"] = "<span class ='notice'>You collapse the baton.</span>"
	return .

// Default message for stunning mob.
/obj/item/melee/classic_baton/proc/get_stun_description(mob/living/target, mob/living/user)
	. = list()
	.["visible"] =  "<span class ='danger'>[user] has knocked down [target] with [src]!</span>"
	.["local"] = "<span class ='danger'>[user] has knocked down [target] with [src]!</span>"
	return .

// Default message for stunning a silicon.
/obj/item/melee/classic_baton/proc/get_silicon_stun_description(mob/living/target, mob/living/user)
	. = list()
	.["visible"] = "<span class='danger'>[user] pulses [target]'s sensors with the baton!</span>"
	.["local"] = "<span class='danger'>You pulse [target]'s sensors with the baton!</span>"
	return .

// Are we applying any special effects when we stun to carbon
/obj/item/melee/classic_baton/proc/additional_effects_carbon(mob/living/target, mob/living/user)
	return

// Are we applying any special effects when we stun to silicon
/obj/item/melee/classic_baton/proc/additional_effects_silicon(mob/living/target, mob/living/user)
	return

/obj/item/melee/classic_baton/attack(mob/living/target, mob/living/user)
	if(!on)
		return ..()

	if(IS_STAMCRIT(user))//CIT CHANGE - makes batons unusuable in stamina softcrit
		to_chat(user, "<span class='warning'>You're too exhausted for that.</span>")//CIT CHANGE - ditto
		return //CIT CHANGE - ditto

	add_fingerprint(user)
	if((HAS_TRAIT(user, TRAIT_CLUMSY)) && prob(50))
		to_chat(user, "<span class ='danger'>You club yourself over the head.</span>")
		user.DefaultCombatKnockdown(60 * force)
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			H.apply_damage(2*force, BRUTE, BODY_ZONE_HEAD)
		else
			user.take_bodypart_damage(2*force)
		return
	if(iscyborg(target))
		if(user.a_intent != INTENT_HARM)	// We don't stun if we're on harm.
			if(affect_silicon)
				var/list/desc = get_silicon_stun_description(target, user)
				target.flash_act(affect_silicon = TRUE)
				target.Stun(stun_time_silicon)
				additional_effects_silicon(target, user)
				user.visible_message(desc["visible"], desc["local"])
				playsound(get_turf(src), on_stun_sound, 100, TRUE, -1)
				if(stun_animation)
					user.do_attack_animation(target)
			else
				..()
		else
			..()
		return
	if(!isliving(target))
		return
	if(user.a_intent == INTENT_HARM)
		if(!..() || !iscyborg(target))
			return
	else
		if(cooldown_check < world.time)
			if(!UseStaminaBufferStandard(user, STAM_COST_BATON_MOB_MULT, warn = TRUE))
				return DISCARD_LAST_ACTION
			var/list/block_return = list()
			if(target.mob_run_block(src, 0, "[user]'s [name]", ATTACK_TYPE_MELEE, 0, user, null, block_return) & BLOCK_SUCCESS)
				playsound(target, 'sound/weapons/genhit.ogg', 50, 1)
				return
			if(ishuman(target))
				var/mob/living/carbon/human/H = target
				if(check_martial_counter(H, user))
					return
			var/list/desc = get_stun_description(target, user)
			if(stun_animation)
				user.do_attack_animation(target)
			playsound(get_turf(src), on_stun_sound, 75, 1, -1)
			var/countered = block_return[BLOCK_RETURN_MITIGATION_PERCENT] > block_percent_to_counter
			// BLUEMOON ADD START - больших и тяжёлых существ проблематично нормально оглушить
			var/final_stun_damage = stam_dmg
			if(target.mob_weight > MOB_WEIGHT_HEAVY)
				if(!full_effect_on_superheavy_characters)
					var/target_size_mod = 1
					if(get_size(target) > 1)
						target_size_mod = 1 / get_size(target) // я за час не придумал, как из 1 получить 1 и из 2 получить 0.5 - сделайте вы
					final_stun_damage *= target_size_mod
					countered = target_size_mod <= 0.6 ? 1 : 0 // если модификатор стана 0.6 или менее, то считается законтренным от падения
			// BLUEMOON ADD END
			target.DefaultCombatKnockdown(softstun_ds, TRUE, FALSE, countered? 0 : hardstun_ds, final_stun_damage, !countered) // BLUEMOON EDIT - заменено stam_dmg на final_stun_damage
			additional_effects_carbon(target, user)
			log_combat(user, target, "stunned", src)
			add_fingerprint(user)
			target.visible_message(desc["visible"], desc["local"])
			if(!iscarbon(user))
				target.LAssailant = null
			else
				target.LAssailant = WEAKREF(user)
			cooldown_check = world.time + cooldown
		else
			var/wait_desc = get_wait_description()
			if(wait_desc)
				to_chat(user, wait_desc)
			return DISCARD_LAST_ACTION

/obj/item/melee/classic_baton/telescopic
	name = "Telescopic Baton"
	desc = "A compact yet robust personal defense weapon. Can be concealed when folded."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "telebaton_0"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	item_state = null
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	item_flags = NONE
	force = 0
	on = FALSE
	on_sound = 'sound/weapons/batonextend.ogg'
	on_icon_state = "telebaton_1"
	off_icon_state = "telebaton_0"
	on_item_state = "telebaton_1"
	force_on = 10
	force_off = 0
	weight_class_on = WEIGHT_CLASS_BULKY
	total_mass = TOTAL_MASS_NORMAL_ITEM
	bare_wound_bonus = 5
	sword_point = FALSE
	var/silent = FALSE

/obj/item/melee/classic_baton/telescopic/suicide_act(mob/user)
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/brain/B = H.getorgan(/obj/item/organ/brain)

	user.visible_message("<span class='suicide'>[user] stuffs [src] up [user.ru_ego()] nose and presses the 'extend' button! It looks like [user.ru_who()] trying to clear [user.ru_ego()] mind.</span>")
	if(!on)
		src.attack_self(user)
	else
		playsound(loc, on_sound, 50, 1)
		add_fingerprint(user)
	sleep(3)
	if (H && !QDELETED(H))
		if (B && !QDELETED(B))
			H.internal_organs -= B
			qdel(B)
		H.spawn_gibs()
		return (BRUTELOSS)

/obj/item/melee/classic_baton/telescopic/attack_self(mob/user)
	on = !on
	var/list/desc = get_on_description()
	if(on)
		to_chat(user, desc["local_on"])
		icon_state = on_icon_state
		item_state = on_item_state
		w_class = weight_class_on
		force = force_on
		attack_verb = list("smacked", "struck", "cracked", "beaten")
		AddElement(/datum/element/sword_point)
		if(!silent)
			user?.visible_message("<span class='warning'>[user] extends [src] with a flick of their wrist!</span>")
	else
		to_chat(user, desc["local_off"])
		icon_state = off_icon_state
		item_state = null //no sprite for concealment even when in hand
		slot_flags = ITEM_SLOT_BELT
		w_class = WEIGHT_CLASS_SMALL
		force = force_off
		attack_verb = list("hit", "poked")
		RemoveElement(/datum/element/sword_point)
		if(!silent)
			user?.visible_message("<span class='warning'>[user] collapses [src] back down!</span>")
	playsound(src.loc, on_sound, 50, 1)
	add_fingerprint(user)

/**
  * # Fancy Cane
  */
/obj/item/melee/classic_baton/ntcane
	name = "Fancy Cane"
	desc = "A cane with special engraving on it. It seems well suited for fending off assailants..."
	icon_state = "cane_nt"
	item_state = "cane_nt"
	item_flags = ITEM_CAN_PARRY | NEEDS_PERMIT

/obj/item/melee/classic_baton/telescopic/centcom
	name = "Tactical Covenant Bat"
	desc = "Выдвижная тактическая бита Центрального Командования Nanotrasen. \
	В официальных документах эта бита проходит под элегантным названием \"Показатель Власти Двадцать Восемь\". \
	Выдаваясь только самым верным и эффективным офицерам NanoTrasen, это оружие является одновременно символом статуса \
	и инструментом высшего правосудия."
	icon_state = "centcom_bat_0"
	off_icon_state = "centcom_bat_0"
	on_icon_state = "centcom_bat_1"
	on_item_state = "centcom_bat_1"

/obj/item/melee/classic_baton/telescopic/centcom/plus
	name = "Tactical Centcom Bat"
	force = 5
	throwforce = 20
	force_on = 50
	force_off = 10
	sharpness = 1
	armour_penetration = 100

/obj/item/melee/classic_baton/telescopic/newspaper
	name = "The Daily Whiplash"
	desc = "A newspaper wrapped around a telescopic baton in such a way that it looks like you're beating people with a rolled up newspaper."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "newspaper"
	lefthand_file = 'icons/mob/inhands/misc/books_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/books_righthand.dmi'
	on_sound = 'sound/weapons/batonextend.ogg'
	on_icon_state = "newspaper2"
	off_icon_state = "newspaper"
	on_item_state = "newspaper"

/obj/item/melee/classic_baton/telescopic/contractor_baton
	name = "contractor baton"
	desc = "A compact, specialised baton assigned to Syndicate contractors. Applies light electrical shocks to targets."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "contractor_baton_0"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	item_state = null
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	item_flags = NONE
	force = 5
	cooldown = 20
	stam_dmg = 75
	affect_silicon = TRUE
	on_sound = 'sound/weapons/contractorbatonextend.ogg'
	on_stun_sound = 'sound/effects/contractorbatonhit.ogg'
	on_icon_state = "contractor_baton_1"
	off_icon_state = "contractor_baton_0"
	on_item_state = "contractor_baton_1"
	force_on = 16
	force_off = 5
	weight_class_on = WEIGHT_CLASS_NORMAL
	silent = TRUE
	full_effect_on_superheavy_characters = TRUE // BLUEMOON ADD - дубинка контрактника работает на сверхтяжей в полную силу

/obj/item/melee/classic_baton/telescopic/contractor_baton/get_wait_description()
	return "<span class='danger'>The baton is still charging!</span>"

/obj/item/melee/classic_baton/telescopic/contractor_baton/additional_effects_carbon(mob/living/target, mob/living/user)
	target.Jitter(25)
	target.stuttering = 25
	target.apply_effect(EFFECT_STUTTER, 20)
	target.apply_status_effect(/datum/status_effect/electrostaff, 30)	//knockdown, disarm, and slowdown, the unholy triumvirate of stam combat

/obj/item/melee/supermatter_sword
	name = "supermatter sword"
	desc = "In a station full of bad ideas, this might just be the worst."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "supermatter_sword"
	item_state = "supermatter_sword"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	slot_flags = null
	w_class = WEIGHT_CLASS_BULKY
	force = 0.001
	armour_penetration = 1000
	var/obj/machinery/power/supermatter_crystal/shard
	var/balanced = 1
	force_string = "INFINITE"

/obj/item/melee/supermatter_sword/Initialize(mapload)
	. = ..()
	shard = new /obj/machinery/power/supermatter_crystal(src)
	qdel(shard.countdown)
	shard.countdown = null
	START_PROCESSING(SSobj, src)
	visible_message("<span class='warning'>[src] appears, balanced ever so perfectly on its hilt. This isn't ominous at all.</span>")

/obj/item/melee/supermatter_sword/process()
	if(balanced || throwing || ismob(src.loc) || isnull(src.loc))
		return
	if(!isturf(src.loc))
		var/atom/target = src.loc
		forceMove(target.loc)
		consume_everything(target)
	else
		var/turf/T = get_turf(src)
		if(!isspaceturf(T))
			shard.consume_turf(T)

/obj/item/melee/supermatter_sword/afterattack(target, mob/user, proximity_flag)
	. = ..()
	if(user && target == user)
		user.dropItemToGround(src)
	if(proximity_flag)
		consume_everything(target)

/obj/item/melee/supermatter_sword/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	..()
	if(ismob(hit_atom))
		var/mob/M = hit_atom
		if(src.loc == M)
			M.dropItemToGround(src)
	consume_everything(hit_atom)

/obj/item/melee/supermatter_sword/pickup(user)
	..()
	balanced = 0

/obj/item/melee/supermatter_sword/ex_act(severity, target, origin)
	visible_message("<span class='danger'>The blast wave smacks into [src] and rapidly flashes to ash.</span>",\
	"<span class='italics'>You hear a loud crack as you are washed with a wave of heat.</span>")
	consume_everything()

/obj/item/melee/supermatter_sword/acid_act()
	visible_message("<span class='danger'>The acid smacks into [src] and rapidly flashes to ash.</span>",\
	"<span class='italics'>You hear a loud crack as you are washed with a wave of heat.</span>")
	consume_everything()

/obj/item/melee/supermatter_sword/bullet_act(obj/item/projectile/P)
	visible_message("<span class='danger'>[P] smacks into [src] and rapidly flashes to ash.</span>",\
	"<span class='italics'>You hear a loud crack as you are washed with a wave of heat.</span>")
	consume_everything(P)
	return BULLET_ACT_HIT

/obj/item/melee/supermatter_sword/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] touches [src]'s blade. It looks like [user.ru_who()] tired of waiting for the radiation to kill [user.ru_na()]!</span>")
	user.dropItemToGround(src, TRUE)
	shard.Bumped(user)

/obj/item/melee/supermatter_sword/proc/consume_everything(target)
	if(isnull(target))
		shard.Consume()
	else if(!isturf(target))
		shard.Bumped(target)
	else
		shard.consume_turf(target)

/obj/item/melee/supermatter_sword/add_blood_DNA(list/blood_dna)
	return FALSE

/obj/item/melee/curator_whip
	name = "curator's whip"
	desc = "Somewhat eccentric and outdated, it still stings like hell to be hit by."
	icon_state = "whip"
	item_state = "chain"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	force = 15
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb = list("flogged", "whipped", "lashed", "disciplined")
	hitsound = 'sound/weapons/whip.ogg'

/obj/item/melee/curator_whip/afterattack(target, mob/user, proximity_flag)
	. = ..()
	if(ishuman(target) && proximity_flag)
		var/mob/living/carbon/human/H = target
		H.drop_all_held_items()
		H.Jitter(50)
		H.stuttering = 50
		H.visible_message("<span class='danger'>[user] disarms [H]!</span>", "<span class='userdanger'>[user] disarmed you!</span>")

/obj/item/melee/roastingstick
	name = "advanced roasting stick"
	desc = "A telescopic roasting stick with a miniature shield generator designed to ensure entry into various high-tech shielded cooking ovens and firepits."
	icon_state = "roastingstick_0"
	item_state = "null"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	item_flags = NONE
	force = 0
	attack_verb = list("hit", "poked")
	var/obj/item/reagent_containers/food/snacks/sausage/held_sausage
	var/static/list/ovens
	var/on = FALSE
	var/datum/beam/beam
	total_mass = 2.5

/obj/item/melee/roastingstick/Initialize(mapload)
	. = ..()
	if (!ovens)
		ovens = typecacheof(list(/obj/singularity, /obj/machinery/power/supermatter_crystal, /obj/structure/bonfire, /obj/structure/destructible/clockwork/massive/ratvar))

/obj/item/melee/roastingstick/attack_self(mob/user)
	on = !on
	if(on)
		extend(user)
	else
		if (held_sausage)
			to_chat(user, "<span class='warning'>You can't retract [src] while [held_sausage] is attached!</span>")
			return
		retract(user)

	playsound(src.loc, 'sound/weapons/batonextend.ogg', 50, 1)
	add_fingerprint(user)

/obj/item/melee/roastingstick/attackby(atom/target, mob/user)
	..()
	if (istype(target, /obj/item/reagent_containers/food/snacks/sausage))
		if (!on)
			to_chat(user, "<span class='warning'>You must extend [src] to attach anything to it!</span>")
			return
		if (held_sausage)
			to_chat(user, "<span class='warning'>[held_sausage] is already attached to [src]!</span>")
			return
		if (user.transferItemToLoc(target, src))
			held_sausage = target
		else
			to_chat(user, "<span class='warning'>[target] doesn't seem to want to get on [src]!</span>")
	update_icon()

/obj/item/melee/roastingstick/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	..()
	if (held_sausage)
		user.put_in_hands(held_sausage)
		held_sausage = null
	update_icon()

/obj/item/melee/roastingstick/update_overlays()
	. = ..()
	if (held_sausage)
		. += mutable_appearance(icon, "roastingstick_sausage")

/obj/item/melee/roastingstick/proc/extend(user)
	to_chat(user, "<span class ='warning'>You extend [src].</span>")
	icon_state = "roastingstick_1"
	item_state = "nullrod"
	w_class = WEIGHT_CLASS_BULKY

/obj/item/melee/roastingstick/proc/retract(user)
	to_chat(user, "<span class ='notice'>You collapse [src].</span>")
	icon_state = "roastingstick_0"
	item_state = null
	w_class = WEIGHT_CLASS_SMALL

/obj/item/melee/roastingstick/handle_atom_del(atom/target)
	if (target == held_sausage)
		held_sausage = null
		update_icon()

/obj/item/melee/roastingstick/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if (!on)
		return
	if (is_type_in_typecache(target, ovens))
		if (held_sausage && held_sausage.roasted)
			to_chat("Your [held_sausage] has already been cooked.")
			return
		if (istype(target, /obj/singularity) && get_dist(user, target) < 10)
			to_chat(user, "You send [held_sausage] towards [target].")
			playsound(src, 'sound/items/rped.ogg', 50, 1)
			beam = user.Beam(target,icon_state="rped_upgrade",time=100)
		else if (user.Adjacent(target))
			to_chat(user, "You extend [src] towards [target].")
			playsound(src.loc, 'sound/weapons/batonextend.ogg', 50, 1)
		else
			return
		if(do_after(user, 100, target = user))
			finish_roasting(user, target)
		else
			QDEL_NULL(beam)
			playsound(src, 'sound/weapons/batonextend.ogg', 50, 1)

/obj/item/melee/roastingstick/proc/finish_roasting(user, atom/target)
	if(!held_sausage || held_sausage.roasted)
		return	// no
	to_chat(user, "You finish roasting [held_sausage]")
	playsound(src,'sound/items/welder2.ogg',50,1)
	held_sausage.add_atom_colour(rgb(103,63,24), FIXED_COLOUR_PRIORITY)
	held_sausage.name = "[target.name]-roasted [held_sausage.name]"
	held_sausage.desc = "[held_sausage.desc] It has been cooked to perfection on \a [target]."
	held_sausage.roasted = TRUE
	update_icon()

/obj/item/melee/cleric_mace
	name = "cleric mace"
	desc = "The grandson of the club, yet the grandfather of the baseball bat. Most notably used by holy orders in days past."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "mace_greyscale"
	item_state = "mace_greyscale"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	material_flags = MATERIAL_ADD_PREFIX | MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS //Material type changes the prefix as well as the color.
	custom_materials = list(/datum/material/iron = 12000)  //Defaults to an Iron Mace.
	slot_flags = ITEM_SLOT_BELT
	force = 14
	w_class = WEIGHT_CLASS_BULKY
	throwforce = 8
	block_chance = 10
	armour_penetration = 50
	attack_verb = list("smacked", "struck", "cracked", "beaten")
	var/overlay_state = "mace_handle"
	var/mutable_appearance/overlay

/obj/item/melee/cleric_mace/Initialize(mapload)
	. = ..()
	overlay = mutable_appearance(icon, overlay_state)
	overlay.appearance_flags = RESET_COLOR
	add_overlay(overlay)
