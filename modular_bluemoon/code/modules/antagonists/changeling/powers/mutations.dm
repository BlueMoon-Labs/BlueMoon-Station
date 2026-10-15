/datum/action/changeling/sting/sleepy
	name = "Sleepy Sting"
	desc = "We silently sting our victim with a cocktail of chemicals that put them to sleep. Costs 15 chemicals."
	helptext = "We silently sting our victim with a cocktail of chemicals that put them to sleep. Costs 15 chemicals."
	button_icon_state = "sting_cryo"
	sting_icon = "sting_cryo"
	chemical_cost = 15
	dna_cost = 2
	loudness = 1
	gamemode_restriction_type = ANTAG_EXTENDED

/datum/action/changeling/sting/sleepy/sting_action(mob/user, mob/target)
	log_combat(user, target, "sting", "sleepy sting")
	if(target.reagents)
		target.reagents.add_reagent(/datum/reagent/toxin/chloralhydrate, 20)
		target.reagents.add_reagent(/datum/reagent/toxin/staminatoxin, 10)
	return TRUE

/datum/action/changeling/gloves/gauntlets/extended
	name = "Soft Bone Gauntlets"
	glove_type = /obj/item/clothing/gloves/krav_maga/combatglovesplus/extended // just punch his head off dude
	gamemode_restriction_type = ANTAG_EXTENDED

/obj/item/clothing/gloves/krav_maga/combatglovesplus/extended
	name = "Soft Bone Gauntlets"
	icon_state = "ling_gauntlets"
	item_state = "ling_gauntlets"
	desc = "Rough bone and chitin, pulsing with an abomination barely called \"life\". Good for punching people, not so much for firearms."
	transfer_prints = TRUE
	item_flags = DROPDEL // whoops
	body_parts_covered = ARMS|HANDS
	cold_protection = ARMS|HANDS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	max_heat_protection_temperature = GLOVES_MAX_TEMP_PROTECT
	armor_type = /datum/armor/martial_arts_extended

/obj/item/clothing/gloves/krav_maga/combatglovesplus/extended/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, CHANGELING_TRAIT)

/obj/item/clothing/gloves/krav_maga/combatglovesplus/extended/equipped(mob/user, slot)
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_GLOVES)
		to_chat(user, "<span class='notice'>With [src] formed around our arms, we are ready to fight.</span>")
