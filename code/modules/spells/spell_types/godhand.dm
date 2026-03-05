/obj/item/melee/touch_attack
	name = "\improper outstretched hand"
	desc = "High Five?"
	var/catchphrase = "High Five!"
	var/on_use_sound = null
	var/obj/effect/proc_holder/spell/targeted/touch/attached_spell
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "syndballoon"
	item_state = null
	item_flags = NEEDS_PERMIT | ABSTRACT | DROPDEL
	w_class = WEIGHT_CLASS_HUGE
	force = 0
	throwforce = 0
	throw_range = 0
	throw_speed = 0
	var/charges = 1

/obj/item/melee/touch_attack/attack(mob/target, mob/living/carbon/user)
	if(!iscarbon(user)) //Look ma, no hands
		return
	if(user.lying || user.handcuffed)
		to_chat(user, "<span class='warning'>You can't reach out!</span>")
		return
	..()

/obj/item/melee/touch_attack/afterattack(atom/target, mob/user, proximity)
	. = ..()
	user.say(catchphrase, forced = "spell")
	playsound(get_turf(user), on_use_sound,50,1)
	charges--
	charges_check()

/obj/item/melee/touch_attack/proc/charges_check()
	if(charges > 0)
		return
	attached_spell?.on_hand_destroy(src)
	qdel(src)

/obj/item/melee/touch_attack/proc/hand_spell_check(mob/living/target, mob/living/carbon/user, proximity, speak_check = TRUE, cuffed_check = TRUE, allow_self_touch = FALSE, silence = FALSE)
	. = FALSE
	if(!proximity || (!allow_self_touch && target == user) || !istype(target) || !istype(user))
		return
	if(cuffed_check && (user.lying || user.handcuffed))
		if(!silence)
			to_chat(user, span_warning("You can't reach out!"))
		return
	if(speak_check && !user.can_speak_vocal())
		if(!silence)
			to_chat(user, span_warning("You can't get the words out!"))
		return

	return TRUE

/obj/item/melee/touch_attack/Destroy()
	attached_spell?.cancel_cast()
	return ..()

/obj/item/melee/touch_attack/disintegrate
	name = "\improper disintegrating touch"
	desc = "This hand of mine glows with an awesome power!"
	catchphrase = "EI NATH!!"
	on_use_sound = 'sound/magic/disintegrate.ogg'
	icon_state = "disintegrate"
	item_state = "disintegrate"

/obj/item/melee/touch_attack/disintegrate/afterattack(atom/target, mob/living/carbon/user, proximity)
	if(!hand_spell_check(target, user, proximity))
		return
	var/mob/M = target
	do_sparks(4, FALSE, M.loc)
	for(var/mob/living/L in view(src, 7))
		if(L != user)
			L.flash_act(affect_silicon = FALSE)
	var/atom/A = M.anti_magic_check()
	if(A)
		if(isitem(A))
			target.visible_message("<span class='warning'>[target]'s [A] glows brightly as it wards off the spell!</span>")
		user.visible_message("<span class='warning'>The feedback blows [user]'s arm off!</span>","<span class='userdanger'>The spell bounces from [M]'s skin back into your arm!</span>")
		user.flash_act()
		var/obj/item/bodypart/part = user.get_holding_bodypart_of_item(src)
		if(part)
			part.dismember()
		return ..()
	M.gib()
	return ..()

/obj/item/melee/touch_attack/alive_bones
	name = "\improper alive bones touch"
	desc = "This hand of mine glows with an awesome power!"
	catchphrase = "EI NECR!!"
	on_use_sound = 'sound/magic/Mutate.ogg'
	icon_state = "necrohand"
	item_state = "necrohand"

/obj/item/melee/touch_attack/alive_bones/afterattack(atom/target, mob/living/carbon/user, proximity)
	if(!ishuman(target) || !hand_spell_check(target, user, proximity))
		return
	var/mob/living/carbon/human/H = target
	var/static/list/bodyparts_check = list(BODY_ZONE_L_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_ARM, BODY_ZONE_R_LEG)
	var/bodyparts_count = 0
	for(var/zone in bodyparts_check)
		if(!H.get_bodypart(zone))
			continue
		bodyparts_count++
	if(bodyparts_count <= 1)
		to_chat(user, span_warning("У [H] недостаточно конечностей, чтобы создать скелета!"))
		return

	do_sparks(4, FALSE, H.loc)
	for(var/mob/living/L in view(src, 7))
		if(L != user)
			L.flash_act(affect_silicon = FALSE)
	if(H.anti_magic_check())
		to_chat(user, span_warning("The spell can't seem to affect [H]!"))
		to_chat(H, span_warning("You feel like your skelet PAINFULL wants to break free, but it calms down."))
		H.pain_emote()
		return ..()
	to_chat(H, span_userdanger("МОЙ СКЕЛЕТ, ААААААААА!!!"))

	var/is_robot = HAS_TRAIT(H, TRAIT_ROBOTIC_ORGANISM)
	var/turf/T = get_turf(H)
	// Отрываем конечности
	H.spread_bodyparts(keep_head = TRUE)
	new /obj/effect/gibspawner/human/bodypartless(T, H)

	// Переломы
	H.adjustBruteLoss(40)
	var/obj/item/bodypart/BP = H.get_bodypart(BODY_ZONE_HEAD)
	if(BP)
		var/datum/wound/blunt/critical/trauma = new
		trauma.apply_wound(BP)

	BP = H.get_bodypart(BODY_ZONE_CHEST)
	if(BP)
		var/datum/wound/blunt/critical/trauma = new
		trauma.apply_wound(BP)

	// Больно, ТОЛЬКО если НЕ робот (обезбол намеренно не учитываем)
	if(!is_robot)
		H.pain_emote(PAIN_FULL, realagony = TRUE)

	// Создаем скелета
	var/mob/living/simple_animal/hostile/skeleton/alive_bones/skelet = new(T)
	skelet.name += " of [H.real_name]"
	skelet.set_mage_servant(user)
	if(is_robot)
		skelet.add_atom_colour("#404040", FIXED_COLOUR_PRIORITY)
		skelet.name = "metal " + skelet.name

	return ..()

/obj/item/melee/touch_attack/fleshtostone
	name = "\improper petrifying touch"
	desc = "That's the bottom line, because flesh to stone said so!"
	catchphrase = "STAUN EI!!"
	on_use_sound = 'sound/magic/fleshtostone.ogg'
	icon_state = "fleshtostone"
	item_state = "fleshtostone"

/obj/item/melee/touch_attack/fleshtostone/afterattack(atom/target, mob/living/carbon/user, proximity)
	if(!hand_spell_check(target, user, proximity))
		return
	var/mob/living/M = target
	if(M.anti_magic_check())
		to_chat(user, "<span class='warning'>The spell can't seem to affect [M]!</span>")
		to_chat(M, "<span class='warning'>You feel your flesh turn to stone for a moment, then revert back!</span>")
		return ..()
	M.Stun(40)
	M.petrify()
	return ..()

/obj/item/melee/touch_attack/nuclearfist
	name = "\improper PURE MANLINESS"
	desc = "SHOW THEM RAW POWER"
	catchphrase = "I CAST FIST!"
	on_use_sound = 'sound/weapons/nuclear_fist.ogg'
	icon_state = "disintegrate"
	item_state = "disintegrate"

/obj/item/melee/touch_attack/nuclearfist/afterattack(atom/movable/target, mob/living/carbon/user, proximity)
	if(!hand_spell_check(target, user, proximity))
		return
	var/mob/M = target
	var/atom/A = M.anti_magic_check()
	if(A)
		if(isitem(A))
			target.visible_message("<span class='warning'>[target]'s [A] glows brightly as it wards off the spell!</span>")
		user.visible_message("<span class='warning'>The feedback blows [user]'s arm off!</span>","<span class='userdanger'>The spell bounces from [M]'s skin back into your arm!</span>")
		user.flash_act()
		var/obj/item/bodypart/part = user.get_holding_bodypart_of_item(src)
		if(part)
			part.dismember()
		return ..()
	var/angle = dir2angle(get_dir(src, get_step_away(target, src)))
	var/obj/item/projectile/magic/nuclear/P = new(get_turf(src))
	P.victim = target
	target.forceMove(P)
	P.setAngle(angle)
	P.original = user
	P.firer = user
	P.fire()
	return ..()

/obj/item/melee/touch_attack/megahonk
	name = "\improper honkmother's blessing"
	desc = "You've got a feeling they won't be laughing after this one. Honk honk."
	catchphrase = "HONKDOOOOUKEN!"
	on_use_sound = 'sound/items/airhorn.ogg'
	icon = 'icons/mecha/mecha_equipment.dmi'
	icon_state = "mecha_honker"

/obj/item/melee/touch_attack/megahonk/afterattack(atom/target, mob/living/carbon/user, proximity)
	if(!proximity || !iscarbon(target) || !iscarbon(user) || user.handcuffed)
		return
	user.say(catchphrase, forced = "spell")
	playsound(get_turf(target), on_use_sound,100,1)
	for(var/mob/living/carbon/M in (hearers(1, target) - user)) //3x3 around the target, not affecting the user
		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			if(istype(H.ears, /obj/item/clothing/ears/earmuffs))
				continue
		var/mul = (M==target ? 1 : 0.5)
		to_chat(M, "<font color='red' size='7'>HONK</font>")
		M.SetSleeping(0)
		M.stuttering += 20*mul
		M.adjustEarDamage(0, 30*mul)
		M.DefaultCombatKnockdown(60*mul)
		if(prob(40))
			M.DefaultCombatKnockdown(200*mul)
		else
			M.Jitter(500*mul)

	charges--
	charges_check()

/obj/item/melee/touch_attack/megahonk/attack_self(mob/user)
	. = ..()
	to_chat(user, "<span class='notice'>\The [src] disappears, to honk another day.</span>")
	qdel(src)

/obj/item/melee/touch_attack/bspie
	name = "\improper bluespace pie"
	desc = "A thing you can barely comprehend as you hold it in your hand. You're fairly sure you could fit an entire body inside."
	on_use_sound = 'sound/magic/demon_consume.ogg'
	icon = 'icons/obj/food/piecake.dmi'
	icon_state = "frostypie"
	color = "#000077"

/obj/item/melee/touch_attack/bspie/attack_self(mob/user)
	. = ..()
	to_chat(user, "<span class='notice'>You smear \the [src] on your chest! </span>")
	qdel(src)

/obj/item/melee/touch_attack/bspie/afterattack(atom/target, mob/living/carbon/user, proximity)
	if(!proximity || !iscarbon(target) || !iscarbon(user) || user.handcuffed)
		return
	if(target == user)
		to_chat(user, "<span class='notice'>You smear \the [src] on your chest!</span>")
		qdel(src)
		return
	var/mob/living/carbon/M = target

	user.visible_message("<span class='warning'>[user] is trying to stuff [M]\s body into \the [src]!</span>")
	if(do_mob(user, M, 250))
		var/name = M.real_name
		var/obj/item/reagent_containers/food/snacks/pie/cream/body/pie = new(get_turf(M))
		pie.name = "\improper [name] [pie.name]"

		playsound(get_turf(target), on_use_sound, 50, 1)

		/*
		var/obj/item/bodypart/head = M.get_bodypart("head")
		if(head)
			head.drop_limb()
		head.throw_at(get_turf(head), 1, 1)
		qdel(M)
		*/
		M.forceMove(pie)


		charges--

	charges_check()
