/// Hive head suit power + helmet (bee swarm). Adapted from tg/Skyrat-style changeling mutations.

/datum/action/changeling/suit/hive_head
	name = "Hive Head"
	desc = "We coat our head in a waxy secretion that can spawn hostile bees. Reagents poured into the hive are injected by bee stings."
	helptext = "Does not replace real armor. Bees consider everyone hostile except you. Cooldown between releases."
	button_icon_state = "spread_infestation"
	chemical_cost = 15
	dna_cost = 2
	req_human = FALSE
	loudness = 2
	blood_on_castoff = TRUE
	recharge_slowdown = 0.05
	helmet_type = /obj/item/clothing/head/helmet/changeling_hivehead
	helmet_name_simple = "hive head"

/obj/item/clothing/head/helmet/changeling_hivehead
	name = "hive head"
	desc = "Waxy, twitching plates covering your skull. You hear buzzing inside."
	icon = 'icons/obj/clothing/hats.dmi'
	icon_state = "beekeeper_hat"
	item_state = "beekeeper_hat"
	item_flags = DROPDEL
	flags_inv = HIDEEARS|HIDEHAIR|HIDEEYES|HIDEFACIALHAIR|HIDEFACE
	armor = list(MELEE = 10, BULLET = 10, LASER = 10, ENERGY = 10, BOMB = 0, BIO = 50, RAD = 0, FIRE = 30, ACID = 50)
	actions_types = list(/datum/action/item_action/hivehead_release)
	var/next_release = 0

/obj/item/clothing/head/helmet/changeling_hivehead/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, CHANGELING_TRAIT)
	create_reagents(50, REFILLABLE)

/obj/item/clothing/head/helmet/changeling_hivehead/proc/release_bees(mob/living/user)
	if(!ismob(user))
		return
	if(user.get_item_by_slot(ITEM_SLOT_HEAD) != src)
		to_chat(user, "<span class='warning'>We must wear the hive!</span>")
		return
	if(world.time < next_release)
		to_chat(user, "<span class='warning'>The hive is still quiescent...</span>")
		return
	if(is_type_in_list(get_area(user), list(/area/space)))
		to_chat(user, "<span class='warning'>We shouldn't waste brood in vacuum!</span>")
		return
	next_release = world.time + 30 SECONDS
	user.visible_message("<span class='warning'>[user]'s head buzzes as bees pour out!</span>", "<span class='notice'>We unleash the hive!</span>")
	playsound(user, 'sound/creatures/bee.ogg', 70, TRUE)
	var/spawns = 6
	if(user.stat >= SOFT_CRIT)
		spawns = 2
	for(var/i in 1 to spawns)
		var/mob/living/simple_animal/hostile/poison/bees/short/B = new(user.drop_location())
		B.faction = list("[REF(user)]")
		if(length(reagents?.reagent_list))
			var/datum/reagent/R = pick(reagents.reagent_list)
			B.assign_reagent(R)

/datum/action/item_action/hivehead_release
	name = "Release Bees"

/datum/action/item_action/hivehead_release/Trigger(trigger_flags)
	if(!..())
		return FALSE
	var/obj/item/clothing/head/helmet/changeling_hivehead/H = target
	if(istype(H))
		H.release_bees(owner)
	return TRUE
