/obj/item/antag_spawner/monkey_agent
	name = "monkey agent beacon"
	desc = "Call up some backup from ARC for monkey mayhem."
	icon = 'icons/obj/device.dmi'
	icon_state = "locator"

/obj/item/antag_spawner/monkey_agent/proc/check_usability(mob/user)
	if(used)
		to_chat(user, span_warning("[src] is out of power!"))
		return FALSE
	if(!user.mind)
		return FALSE
	if(user.mind.has_antag_datum(/datum/antagonist/traitor) || user.mind.has_antag_datum(/datum/antagonist/nukeop, TRUE))
		return TRUE
	to_chat(user, span_danger("AUTHENTICATION FAILURE. ACCESS DENIED."))
	return FALSE

/obj/item/antag_spawner/monkey_agent/attack_self(mob/user)
	if(!check_usability(user))
		return
	to_chat(user, span_notice("You activate [src] and wait for confirmation."))
	var/list/candidates = pollGhostCandidates("Do you want to play as an InteQ monkey agent?", ROLE_SYNDICATE_MONKEY, null, ROLE_SYNDICATE_MONKEY, 10 SECONDS, POLL_IGNORE_SYNDICATE_MONKEY, priority_check = FALSE)
	if(!LAZYLEN(candidates))
		to_chat(user, span_warning("Unable to connect to the Animal Rights Consortium's Banana Ops. Please wait and try again later or use the beacon on your uplink to get your points refunded."))
		return
	if(QDELETED(src) || !check_usability(user))
		return
	used = TRUE
	var/mob/dead/observer/chosen = pick(candidates)
	spawn_monkey_agent(chosen.client, get_turf(src), user)
	do_sparks(4, TRUE, src)
	qdel(src)

/obj/item/antag_spawner/monkey_agent/proc/spawn_monkey_agent(client/our_client, turf/T, mob/user)
	new /obj/effect/particle_effect/smoke(T)
	var/mob/living/carbon/monkey/M = new(T)
	M.key = our_client.key
	var/chosen_name = pick(GLOB.syndicate_monkey_names)
	M.real_name = chosen_name
	M.name = chosen_name
	M.aggressive = FALSE
	M.grant_all_languages(UNDERSTOOD_LANGUAGE, grant_omnitongue = FALSE, source = LANGUAGE_ATOM)

	var/obj/item/clothing/head/fedora/hat = new(M)
	M.equip_to_slot_or_del(hat, ITEM_SLOT_HEAD)

	var/obj/item/clothing/mask/cigarette/syndicate/cig = new(M)
	M.equip_to_slot_or_del(cig, ITEM_SLOT_MASK)

	var/obj/item/reagent_containers/food/drinks/soda_cans/monkey_energy/energy = new(M)
	M.put_in_hands(energy)

	var/obj/item/reagent_containers/food/snacks/grown/banana/banana = new(M)
	M.put_in_hands(banana)

	var/obj/item/storage/fancy/cigarettes/cigpack_syndicate/cigpack = new(M)
	M.equip_to_slot_if_possible(cigpack, ITEM_SLOT_BACK)

	if(user.mind)
		M.mind.enslave_mind_to_creator(user)
		M.mind.special_role = ROLE_SYNDICATE_MONKEY

	var/obj/item/implant/explosive/imp = new()
	imp.implant(M, user)

	to_chat(M, span_alertwarning("[user.real_name] is your superior. Follow any and all orders given by them. You're here to support their mission only."))
