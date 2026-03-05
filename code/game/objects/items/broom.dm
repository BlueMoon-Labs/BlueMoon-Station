/datum/block_parry_data/liquidator // fucked up parry data, emphasizing quicker, shorter parries
	parry_stamina_cost = 10 // be wise about when you parry, though, else you won't be able to fight enough to make it count
	parry_time_windup = 0
	parry_time_active = 10 // small parry window
	parry_time_spindown = 0
	// parry_flags = PARRY_DEFAULT_HANDLE_FEEDBACK		// liquidator users can no longer strike while parrying
	parry_time_perfect = 1.5
	parry_time_perfect_leeway = 1
	parry_imperfect_falloff_percent = 7.5
	parry_efficiency_to_counterattack = 120
	parry_efficiency_considered_successful = 65		// VERY generous
	parry_efficiency_perfect = 120
	parry_efficiency_perfect_override = list(
		TEXT_ATTACK_TYPE_PROJECTILE = 30,
	)
	parry_failed_stagger_duration = 3 SECONDS
	parry_data = list(
		PARRY_COUNTERATTACK_MELEE_ATTACK_CHAIN = 2.5, // 10*2.5 = 25, 11*2.5 = 27.5, 12*2.5 = 30, 13*2.5 = 32.5
	)

/datum/block_parry_data/liquidator/quick_parry // emphasizing REALLY SHORT PARRIES
	parry_stamina_cost = 8 // still more costly than most parries, but less than a full liquidator parry
	parry_time_active = 5 // REALLY small parry window
	parry_time_perfect = 2.5 // however...
	parry_time_perfect_leeway = 2 // the entire time, the parry is perfect
	parry_failed_stagger_duration = 1 SECONDS
	// still, don't fucking miss your parries or you're down stamina and staggered to shit

/datum/block_parry_data/liquidator/quick_parry/proj
	parry_efficiency_perfect_override = list()

/// Max number of atoms a broom can sweep at once
#define BROOM_PUSH_LIMIT 20

/obj/item/broom
	name = "Broom"
	desc = "This is my BROOMSTICK! Имеет телескопическую ручку для компактного хранения."
	icon = 'icons/obj/janitor.dmi'
	icon_state = "broom0"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'
	force = 8
	throwforce = 10
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb_continuous = list("сметает", "выметает", "долбит", "шлёпает")
	attack_verb_simple = list("сметает", "выметает", "долбит", "шлёпает")
	resistance_flags = FLAMMABLE

/obj/item/broom/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/broom/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded=8, force_wielded=12, icon_wielded="broom1")

/obj/item/broom/update_icon_state()
	. = ..()
	icon_state = "broom0"

/obj/item/broom/examine(mob/user)
	. = ..()
	. += "[span_yellowteamradio("GRAB INTENT")][span_notice(" - подмести к себе.")]"
	. += span_notice("Можно взяться двумя руками, чтобы подметать предметы на ходу.")

/**
 * Handles registering the do_sweep proc when the broom is wielded
 *
 * Arguments:
 * * source - The source of the on_wield proc call
 * * user - The user which is wielding the broom
 */
/obj/item/broom/proc/on_wield(obj/item/source, mob/user)
	SIGNAL_HANDLER
	user.add_movespeed_modifier(/datum/movespeed_modifier/mop_broom_slowdown)
	to_chat(user, span_notice("Хватаю [src.name] обеими руками и готовлюсь толкать МУСОР."))
	RegisterSignal(user, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(do_sweep))

/**
 * Handles unregistering the do_sweep proc when the broom is unwielded
 *
 * Arguments:
 * * source - The source of the on_unwield proc call
 * * user - The user which is unwielding the broom
 */
/obj/item/broom/proc/on_unwield(obj/item/source, mob/user)
	SIGNAL_HANDLER
	user.remove_movespeed_modifier(/datum/movespeed_modifier/mop_broom_slowdown)
	UnregisterSignal(user, COMSIG_MOVABLE_PRE_MOVE)

/obj/item/broom/afterattack(atom/A, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	sweep(user, A)

/obj/item/broom/proc/do_sweep(mob/user, atom/A)
	sweep(user, user.loc)
	sweep(user, A)

/**
 * Attempts to push up to BROOM_PUSH_LIMIT atoms from a given location the user's faced direction
 *
 * Arguments:
 * * user - The user of the broom
 * * A - The atom which is located at the location to push atoms from
 */
/obj/item/broom/proc/sweep(mob/user, atom/A)
	SIGNAL_HANDLER

	var/turf/current_item_loc = isturf(A) ? A : A.loc
	if (!isturf(current_item_loc))
		return
	var/turf/new_item_loc = user.a_intent == INTENT_GRAB ? get_turf(user) : get_step(current_item_loc, user.dir)
	/*
	for(var/i = 0 to add_dist)
		new_item_loc = get_step(new_item_loc, user.dir)
	*/
	var/obj/machinery/disposal/bin/target_bin = locate(/obj/machinery/disposal/bin) in new_item_loc.contents
	var/i = 1
	for (var/obj/item/garbage in current_item_loc.contents)
		if (!garbage.anchored)
			if (target_bin)
				garbage.forceMove(target_bin)
			else
				garbage.Move(new_item_loc, user.dir)
			i++
		if (i > BROOM_PUSH_LIMIT)
			break
	if (i > 1)
		if (target_bin)
			target_bin.update_icon()
			to_chat(user, span_notice("Заталкиваю весь мусор в мусорку."))
		playsound(loc, 'sound/weapons/thudswoosh.ogg', 30, TRUE, -1)

/**
 * Attempts to insert the push broom into a janicart
 *
 * Arguments:
 * * user - The user of the push broom
 * * J - The janicart to insert into
 */
/obj/item/broom/proc/janicart_insert(mob/user, obj/structure/janitorialcart/J) //bless you whoever fixes this copypasta
	J.put_in_cart(src, user)
	J.mybroom=src
	J.update_icon()

/obj/item/broom/cyborg
	name = "Cyborg Broom"

/obj/item/broom/cyborg/janicart_insert(mob/user, obj/structure/janitorialcart/J)
	to_chat(user, span_notice("Не получается положить [src.name] в [J.name]"))
	return FALSE

/obj/item/broom/liquidator
	name = "Грабли Ликвидатора"
	desc = "Грабли, используемые для борьбы со всяким дерьмом."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "rake"
	lefthand_file = 'icons/mob/inhands/weapons/staves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/staves_righthand.dmi'
	force = 9
	w_class = WEIGHT_CLASS_NORMAL
	throwforce = 28
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	hitsound = 'sound/weapons/bladeslice.ogg'
	sharpness = SHARP_EDGED
	resistance_flags = FLAMMABLE
	var/quick_parry = FALSE // false = default parry, true = really small parry window
	item_flags = ITEM_CAN_PARRY
	bare_wound_bonus = 5
	wound_bonus = 8

/obj/item/broom/liquidator/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded=9, force_wielded=16, icon_wielded="rake")
