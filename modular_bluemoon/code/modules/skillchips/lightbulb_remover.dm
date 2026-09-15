// TRAIT_LIGHTBULB_REMOVER (skillchip "N16H7M4R3") lets you take out glowing light fixtures bare-handed, burning yourself in the process.
/obj/machinery/light/on_attack_hand(mob/living/carbon/human/user)
	. = ..()
	user.DelayNextAction(CLICK_CD_MELEE)
	add_fingerprint(user)

	if(status == LIGHT_EMPTY)
		to_chat(user, "There is no [fitting] in this light.")
		return

	if(on)
		var/prot = 0
		var/mob/living/carbon/human/H = user

		if(istype(H))
			var/datum/species/ethereal/eth_species = H.dna?.species
			if(istype(eth_species))
				to_chat(H, "<span class='notice'>You start channeling some power through the [fitting] into your body.</span>")
				if(do_after(user, 50, target = src))
					var/obj/item/organ/stomach/ethereal/stomach = H.getorganslot(ORGAN_SLOT_STOMACH)
					if(istype(stomach))
						to_chat(H, "<span class='notice'>You receive some charge from the [fitting].</span>")
						stomach.adjust_charge(2)
					else
						to_chat(H, "<span class='warning'>You can't receive charge from the [fitting]!</span>")
				return

			if(H.gloves)
				var/obj/item/clothing/gloves/G = H.gloves
				if(G.max_heat_protection_temperature)
					prot = (G.max_heat_protection_temperature > 360)
		else
			prot = 1

		if(prot > 0 || HAS_TRAIT(user, TRAIT_RESISTHEAT) || HAS_TRAIT(user, TRAIT_RESISTHEATHANDS))
			to_chat(user, "<span class='notice'>You remove the light [fitting].</span>")
		else if(istype(user) && user.dna.check_mutation(TK))
			to_chat(user, "<span class='notice'>You telekinetically remove the light [fitting].</span>")
		else
			if(HAS_TRAIT(user, TRAIT_LIGHTBULB_REMOVER))
				to_chat(user, "<span class='notice'>You feel your hand burning, but the light begins to budge...</span>")
				if(do_after(user, 5 SECONDS, target = src))
					var/obj/item/bodypart/affecting = H.get_bodypart("[(user.active_hand_index % 2 == 0) ? "r" : "l" ]_arm")
					if(affecting && affecting.receive_damage(0, 10)) // 10 burn damage for powering through
						H.update_damage_overlays()
					to_chat(user, "<span class='notice'>You manage to remove the light [fitting], shattering it in the process.</span>")
					break_light_tube()
				return

			to_chat(user, "<span class='warning'>You try to remove the light [fitting], but you burn your hand on it!</span>")

			var/obj/item/bodypart/affecting = H.get_bodypart("[(user.active_hand_index % 2 == 0) ? "r" : "l" ]_arm")
			if(affecting && affecting.receive_damage(0, 5))		// 5 burn damage
				H.update_damage_overlays()
			return				// if burned, don't remove the light
	else
		to_chat(user, "<span class='notice'>You remove the light [fitting].</span>")
	// create a light tube/bulb item and put it in the user's hand
	drop_light_tube(user)