// organ_internal.dm   --   /obj/item/organ

// Do I have a stake in my heart?
/mob/living/AmStaked()
	var/obj/item/bodypart/BP = get_bodypart("chest")
	if (!BP)
		return FALSE
	for(var/obj/item/I in BP.embedded_objects)
		if (istype(I,/obj/item/stake/))
			return TRUE
	return FALSE

/mob/proc/AmStaked()
	return FALSE

/mob/living/proc/StakeCanKillMe()
	return IsSleeping() || stat >= UNCONSCIOUS || blood_volume <= 0 || HAS_TRAIT(src, TRAIT_DEATHCOMA) // NOTE: You can't go to sleep in a coffin with a stake in you.

/obj/item/stake
	name = "wooden stake"
	desc = "Простой деревянный кол с заостренным концом."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "wood" // Inventory Icon
	item_state = "wood" // In-hand Icon
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi' // File for in-hand icon
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	attack_verb = list("staked")
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	hitsound = 'sound/weapons/bladeslice.ogg'
	force = 6
	throwforce = 10
	embedding = list("embed_chance" = 25, "fall_chance" = 0.5) // UPDATE 2/10/18 embedding_behavior.dm is how this is handled
	//embed_chance = 25  // Look up "is_pointed" to see where we set stakes able to do this.
	//embedded_fall_chance = 0.5 // Chance it will fall out.
	obj_integrity = 30
	max_integrity = 30
	//embedded_fall_pain_multiplier
	var/staketime = 120		// Time it takes to embed the stake into someone's chest.

/obj/item/stake/basic
	name = "wooden stake"
	// This exists so Hardened/Silver Stake can't have a welding torch used on them.

/obj/item/stake/basic/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WELDER)
		//if (amWelded)
		//	to_chat(user, "<span class='warning'>This stake has already been treated with fire.</span>")
		//	return
		//amWelded = TRUE
		// Weld it
		if(W.use(0))//remove_fuel(0,user))
			user.visible_message("[user.name] опаляет заостренный конец [src] сварочным инструментом.", \
						 "<span class='notice'>Вы опаляете заостренный конец [src] сварочным инструментом.</span>", \
						 "<span class='italics'>Вы слышите сварку.</span>")
		// 8 Second Timer
		if(!do_mob(user, src, 80))
			return
		// Create the Stake
		qdel(src)
		var/obj/item/stake/hardened/new_item = new(usr.loc)
		user.put_in_hands(new_item)
	else
		return ..()

/obj/item/stake/afterattack(atom/target, mob/user, proximity)
	//to_chat(world, "<span class='notice'>DEBUG: Staking </span>")
	// Invalid Target, or not targetting chest with HARM intent?
	. = ..()
	if(!iscarbon(target) || check_zone(user.zone_selected) != "chest" || user.a_intent != INTENT_HARM)
		return
	var/mob/living/carbon/C = target
	// Needs to be Down/Slipped in some way to Stake.
	if(!C.can_be_staked() || target == user)
		to_chat(user, "<span class='danger'>Вы не можете проткнуть [target], когда она движется! Она должна лежать или быть схвачена за шею!</span>")
		return
			// Oops! Can't.
	if(HAS_TRAIT(C, TRAIT_PIERCEIMMUNE))
		to_chat(user, "<span class='danger'>Грудь [target] сопротивляется колу. Он не входит во внутрь.</span>")
		return
	// Make Attempt...
	to_chat(user, "<span class='notice'>Вы вкладываете весь свой вес в то, чтобы вонзить кол в грудь [target]...</span>")
	playsound(user, 'sound/magic/Demon_consume.ogg', 50, 1)
	if(!do_mob(user, C, staketime, NONE, extra_checks=CALLBACK(C, TYPE_PROC_REF(/mob/living/carbon, can_be_staked)))) // user / target / time / uninterruptable / show progress bar / extra checks
		return
	// Drop & Embed Stake
	user.visible_message("<span class='danger'>[user.name] втыкает [src] в грудь [target]!</span>", \
			 "<span class='danger'>Вы втыкаете [src] в грудь [target]!</span>")
	playsound(get_turf(target), 'sound/effects/splat.ogg', 40, 1)
	user.dropItemToGround(src, TRUE) //user.drop_item() // "drop item" doesn't seem to exist anymore. New proc is user.dropItemToGround() but it doesn't seem like it's needed now?
	var/obj/item/bodypart/B = C.get_bodypart("chest")  // This was all taken from hitby() in human_defense.dm
	B.embedded_objects |= src
	embedded()
	add_mob_blood(target)//Place blood on the stake
	loc = C // Put INSIDE the character
	B.receive_damage(w_class * embedding["pain_mult"])
	if(C.mind)
		var/datum/antagonist/bloodsucker/bloodsucker = C.mind.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
		if(bloodsucker)
			// If DEAD or TORPID...kill vamp!
			if(C.StakeCanKillMe()) // NOTE: This is the ONLY time a staked Torpid vamp dies.
				bloodsucker.FinalDeath()
				return
			else
				to_chat(target, "<span class='userdanger'>Вас проткнули колом! Ваши силы бесполезны, ваша смерть вечна, пока он остается на месте.</span>")
				to_chat(user, "<span class='warning'>Вы не попали [C.ru_ego(TRUE)] сердце! Это было бы легче, если бы [C.ru_who(TRUE)] не сопротивлялся так сильно.</span>")

// Can this target be staked? If someone stands up before this is complete, it fails. Best used on someone stationary.
/mob/living/carbon/proc/can_be_staked()
	return !CHECK_MOBILITY(src, MOBILITY_STAND)
	// ABOVE:  Taken from update_mobility() in living.dm

/obj/item/stake/hardened
	// Created by welding and acid-treating a simple stake.
	name = "hardened stake"
	desc = "Закаленный деревянный кол, заостренный и опаленный на конце."
	icon_state = "hardened" // Inventory Icon
	force = 8
	throwforce = 12
	armour_penetration = 10
	embedding = list("embed_chance" = 50, "fall_chance" = 0) // UPDATE 2/10/18 embedding_behavior.dm is how this is handled
	obj_integrity = 120
	max_integrity = 120

	staketime = 80

/obj/item/stake/hardened/silver
	name = "silver stake"
	desc = "Отполированный и острый на конце. Для тех случаев, когда кто-то из сильных мира сего постоянно пытается подняться на коньках в гору."
	icon_state = "silver" // Inventory Icon
	item_state = "silver" // In-hand Icon
	siemens_coefficient = 1 //flags = CONDUCT // var/siemens_coefficient = 1 // for electrical admittance/conductance (electrocution checks and shit)
	force = 9
	armour_penetration = 25
	embedding = list("embed_chance" = 65) // UPDATE 2/10/18 embedding_behavior.dm is how this is handled
	obj_integrity = 300
	max_integrity = 300

	staketime = 60

// Convert back to Silver
/obj/item/stake/hardened/silver/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_WELDER)
		if(I.use(0))//remove_fuel(0, user))
			var/obj/item/stack/sheet/mineral/silver/newsheet = new (user.loc)
			for(var/obj/item/stack/sheet/mineral/silver/S in user.loc)
				if(S == newsheet)
					continue
				if(S.amount >= S.max_amount)
					continue
				S.attackby(newsheet, user)
			to_chat(user, "<span class='notice'>Вы расплавляете кол и добавляете в стопку. Теперь она содержит [newsheet.amount] лист[newsheet.amount % 10 == 1 && newsheet.amount % 100 != 11 ? "" : (newsheet.amount % 10 >= 2 && newsheet.amount % 10 <= 4 && (newsheet.amount % 100 < 10 || newsheet.amount % 100 >= 20) ? "а" : "ов")].</span>")
			qdel(src)
	else
		return ..()


// Look up recipes.dm OR pneumaticCannon.dm
/datum/crafting_recipe/silver_stake
	name = "Silver Stake"
	result = /obj/item/stake/hardened/silver
	tools = list(/obj/item/weldingtool)
	reqs = list(/obj/item/stack/sheet/mineral/silver = 1,
				/obj/item/stake/hardened = 1)
				///obj/item/stack/packageWrap = 8,
				///obj/item/pipe = 2)
	time = 80
	category = CAT_WEAPONRY
	subcategory = CAT_MELEE
