/* Kitchen tools
 * Contains:
 *		Fork
 *		Kitchen knives
 *		Ritual Knife
 *		Bloodletter
 *		Butcher's cleaver
 *		Combat Knife
 *		Rolling Pins
 */

/obj/item/kitchen
	icon = 'icons/obj/kitchen.dmi'
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_righthand.dmi'

/obj/item/kitchen/fork
	name = "fork"
	desc = "Pointy."
	icon_state = "fork"
	force = 4
	w_class = WEIGHT_CLASS_TINY
	throwforce = 0
	throw_speed = 3
	throw_range = 5
	custom_materials = list(/datum/material/iron=80)
	flags_1 = CONDUCT_1
	attack_verb = list("attacked", "stabbed", "poked")
	hitsound = 'sound/weapons/bladeslice.ogg'
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 30)
	sharpness = SHARP_POINTY
	var/datum/reagent/forkload //used to eat omelette

/obj/item/kitchen/fork/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] stabs \the [src] into [user.ru_ego()] chest! It looks like [user.ru_who()] trying to take a bite out of себя!</span>")
	playsound(src, 'sound/items/eatfood.ogg', 50, 1)
	return BRUTELOSS

/obj/item/kitchen/fork/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(!istype(M))
		return ..()

	if(forkload)
		if(M == user)
			M.visible_message("<span class='notice'>[user] eats a delicious forkful of omelette!</span>")
			M.reagents.add_reagent(forkload.type, 1)
		else
			M.visible_message("<span class='notice'>[user] feeds [M] a delicious forkful of omelette!</span>")
			M.reagents.add_reagent(forkload.type, 1)
		icon_state = "fork"
		forkload = null

	else if(user.zone_selected == BODY_ZONE_PRECISE_EYES)
		return eyestab(M,user)
	else
		return ..()

/obj/item/kitchen/fork/throwing
	name = "throwing fork"
	desc = "A fork, sharpened to perfection, making it a great weapon for throwing."
	throwforce = 15
	throw_speed = 4
	throw_range = 6
	embedding = list("pain_mult" = 2, "embed_chance" = 100, "fall_chance" = 0, "embed_chance_turf_mod" = 15)
	sharpness = SHARP_EDGED

/obj/item/kitchen/spoon
	name = "spoon"
	desc = "Just be careful your food doesn't melt the spoon first."
	icon_state = "spoon"
	w_class = WEIGHT_CLASS_TINY
	flags_1 = CONDUCT_1
	force = 2
	throw_speed = 3
	throw_range = 5
	attack_verb_simple = list("whack", "spoon", "tap")
	attack_verb_continuous = list("whacks", "spoons", "taps")
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 0)
	custom_materials = list(/datum/material/iron=120)
	tool_behaviour = TOOL_MINING
	toolspeed = 25 // Literally 25 times worse than the base pickaxe

/obj/item/kitchen/knife
	name = "kitchen knife"
	icon_state = "knife"
	desc = "A general purpose Chef's Knife made by SpaceCook Incorporated. Guaranteed to stay sharp for years to come."
	flags_1 = CONDUCT_1
	force = 10
	w_class = WEIGHT_CLASS_SMALL
	throwforce = 10
	hitsound = 'sound/weapons/bladeslice.ogg'
	throw_speed = 3
	throw_range = 6
	custom_materials = list(/datum/material/iron=12000)
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	sharpness = SHARP_POINTY
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 50)
	var/bayonet = FALSE	//Can this be attached to a gun?
	wound_bonus = 6
	bare_wound_bonus = 10
	custom_price = PRICE_NORMAL

/obj/item/kitchen/knife/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 80 - force, 100, force - 10) //bonus chance increases depending on force

/obj/item/kitchen/knife/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(user.zone_selected == BODY_ZONE_PRECISE_EYES)
		return eyestab(M,user)
	else
		return ..()

/obj/item/kitchen/knife/suicide_act(mob/user)
	user.visible_message(pick("<span class='suicide'>[user] is slitting [user.ru_ego()] wrists with the [src.name]! It looks like [user.p_theyre()] trying to commit suicide.</span>", \
						"<span class='suicide'>[user] is slitting [user.ru_ego()] throat with the [src.name]! It looks like [user.p_theyre()] trying to commit suicide.</span>", \
						"<span class='suicide'>[user] is slitting [user.ru_ego()] stomach open with the [src.name]! It looks like [user.ru_who()] trying to commit seppuku.</span>"))
	return (BRUTELOSS)

/obj/item/kitchen/efink
	name = "E-Fink"
	icon_state = "efink"
	desc = "The E-Fink is a product by Mending Solutions Inc. Unfortunately it can only mend sliced meat, fruits and dough back to their original state. Unbutchering is not possible."
	flags_1 = CONDUCT_1
	force = 10
	w_class = WEIGHT_CLASS_SMALL
	throwforce = 10
	hitsound = 'sound/weapons/bladesliceb.ogg'
	throw_speed = 3
	throw_range = 6
	custom_materials = list(/datum/material/iron=12000)
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	sharpness = SHARP_POINTY
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 50)
	var/bayonet = FALSE	//Can this be attached to a gun?
	wound_bonus = 6
	bare_wound_bonus = 10
	custom_price = PRICE_NORMAL

/obj/item/kitchen/efink/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 80 - force, 100, force - 10) //bonus chance increases depending on force

/obj/item/kitchen/efink/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(user.zone_selected == BODY_ZONE_PRECISE_EYES)
		return eyestab(M,user)
	else
		return ..()

/obj/item/kitchen/efink/suicide_act(mob/user)
	user.visible_message(pick("<span class='suicide'>[user] is slitting [user.ru_ego()] wrists with the [src.name]! It looks like [user.p_theyre()] trying to commit suicide.</span>", \
						"<span class='suicide'>[user] is slitting [user.ru_ego()] throat with the [src.name]! It looks like [user.p_theyre()] trying to commit suicide.</span>", \
						"<span class='suicide'>[user] is slitting [user.ru_ego()] stomach open with the [src.name]! It looks like [user.ru_who()] trying to commit seppuku.</span>"))
	return (BRUTELOSS)

/obj/item/kitchen/knife/ritual
	name = "ritual knife"
	desc = "The unearthly energies that once powered this blade are now dormant."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "render"
	item_state = "knife"
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/kitchen/knife/bloodletter
	name = "bloodletter"
	desc = "An occult looking dagger that is cold to the touch. Somehow, the flawless orb on the pommel is made entirely of liquid blood."
	icon = 'icons/obj/ice_moon/artifacts.dmi'
	icon_state = "bloodletter"
	w_class = WEIGHT_CLASS_NORMAL
	/// Bleed stacks applied when an organic mob target is hit
	var/bleed_stacks_per_hit = 3

/obj/item/kitchen/knife/bloodletter/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!isliving(target) || !proximity_flag)
		return
	var/mob/living/M = target
	if(!(M.mob_biotypes & MOB_ORGANIC))
		return
	var/datum/status_effect/stacking/saw_bleed/bloodletting/B = M.has_status_effect(/datum/status_effect/stacking/saw_bleed/bloodletting)
	if(!B)
		M.apply_status_effect(/datum/status_effect/stacking/saw_bleed/bloodletting, bleed_stacks_per_hit)
	else
		B.add_stacks(bleed_stacks_per_hit)

/obj/item/kitchen/knife/butcher
	name = "butcher's cleaver"
	icon_state = "butch"
	desc = "A huge thing used for chopping and chopping up meat. This includes clowns and clown by-products."
	flags_1 = CONDUCT_1
	force = 15
	throwforce = 10
	custom_materials = list(/datum/material/iron=18000)
	attack_verb = list("cleaved", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	w_class = WEIGHT_CLASS_NORMAL
	wound_bonus = 6
	bare_wound_bonus = 13
	custom_price = PRICE_EXPENSIVE

/obj/item/kitchen/knife/combat
	name = "combat knife"
	icon_state = "buckknife"
	item_state = "knife"
	desc = "A military combat utility survival knife."
	embedding = list("pain_mult" = 4, "embed_chance" = 65, "fall_chance" = 10, "ignore_throwspeed_threshold" = TRUE)
	force = 16
	throwforce = 16
	wound_bonus = 8
	bare_wound_bonus = 11
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "cut")
	bayonet = TRUE

/obj/item/kitchen/knife/combat/survival
	name = "survival knife"
	icon_state = "survivalknife"
	item_state = "knife"
	desc = "A hunting grade survival knife."
	embedding = list("pain_mult" = 4, "embed_chance" = 35, "fall_chance" = 10)
	force = 15
	throwforce = 15
	wound_bonus = 6
	bare_wound_bonus = 11
	bayonet = TRUE

/obj/item/kitchen/knife/combat/survival/knuckledagger
	name = "survival dagger"
	icon_state = "glaive-dagger"
	desc = "An enhanced hunting grade survival dagger, with a bright light and a handguard that makes it better for efficient butchery."
	actions_types = list(/datum/action/item_action/toggle_light)
	var/light_on = FALSE
	var/brightness_on = 7

/obj/item/kitchen/knife/combat/survival/knuckledagger/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 30, 130, 20) // it's good for butchering stuff

/obj/item/kitchen/knife/combat/survival/knuckledagger/ui_action_click(mob/user, actiontype)
	light_on = !light_on
	playsound(user, 'sound/weapons/empty.ogg', 100, TRUE)
	update_brightness(user)
	update_icon()

/obj/item/kitchen/knife/combat/survival/knuckledagger/proc/update_brightness(mob/user = null)
	if(light_on)
		set_light(brightness_on)
	else
		set_light(0)

/obj/item/kitchen/knife/combat/survival/knuckledagger/update_overlays()
	. = ..()
	if(light_on)
		. += "[icon_state]_lit"

/obj/item/kitchen/knife/combat/bone
	name = "bone dagger"
	item_state = "bone_knife0"
	icon_state = "bone_knife0"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	desc = "A sharpened bone. The bare minimum in survival."
	embedding = list("pain_mult" = 4, "embed_chance" = 35, "fall_chance" = 10)
	force = 15
	throwforce = 15
	custom_materials = null

/obj/item/kitchen/knife/combat/bone/ritual
	name = "dueling dagger"
	item_state = "bone_ritual1"
	icon_state = "bone_ritual1"
	desc = "A dueling dagger of the Ashwalker tribe. For when words lose all meaning."

/obj/item/kitchen/knife/combat/bone/plastic
	name = "plastic knife"
	desc = "A plastic knife. Rather harmless to anything."
	force = 1
	throwforce = 1
	bayonet = FALSE

/obj/item/kitchen/knife/combat/cyborg
	name = "cyborg knife"
	icon = 'icons/obj/items_cyborg.dmi'
	icon_state = "knife"
	desc = "A cyborg-mounted plasteel knife. Extremely sharp and durable."

/obj/item/kitchen/knife/shiv
	name = "glass shiv"
	icon = 'icons/obj/shards.dmi'
	icon_state = "shiv"
	item_state = "shiv"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	desc = "A makeshift glass shiv."
	force = 8
	throwforce = 12//fuck git
	attack_verb = list("shanked", "shivved")
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)
	custom_materials = list(/datum/material/glass=400)

/obj/item/kitchen/knife/shiv/carrot
	name = "carrot shiv"
	icon_state = "carrotshiv"
	item_state = "carrotshiv"
	icon = 'icons/obj/kitchen.dmi'
	desc = "Unlike other carrots, you should probably keep this far away from your eyes."
	custom_materials = null

/obj/item/kitchen/knife/shiv/plasma
	name = "plasma shiv"
	icon_state = "plasmashiv"
	item_state = "plasmashiv"
	desc = "A makeshift plasma glass shiv."
	force = 9
	throwforce = 13
	armor = list(MELEE = 25, BULLET = 25, LASER = 25, ENERGY = 25, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50)
	custom_materials = list(/datum/material/glass=SHEET_MATERIAL_AMOUNT *4, /datum/material/plasma=SHEET_MATERIAL_AMOUNT * 2)

/obj/item/kitchen/knife/shiv/titanium
	name = "titanium shiv"
	icon_state = "titaniumshiv"
	item_state = "titaniumshiv"
	desc = "A makeshift titanium-infused glass shiv."
	throwforce = 14
	throw_range = 7
	wound_bonus = 7
	armor = list(MELEE = 25, BULLET = 25, LASER = 25, ENERGY = 25, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50)
	custom_materials = list(/datum/material/glass=SHEET_MATERIAL_AMOUNT * 4, /datum/material/titanium=SHEET_MATERIAL_AMOUNT * 2)

/obj/item/kitchen/knife/shiv/plastitanium
	name = "plastitanium shiv"
	icon_state = "plastitaniumshiv"
	item_state = "plastitaniumshiv"
	desc = "A makeshift titanium-infused plasma glass shiv."
	force = 10
	throwforce = 15
	throw_speed = 4
	throw_range = 8
	wound_bonus = 6
	bare_wound_bonus = 16
	armor = list(MELEE = 50, BULLET = 50, LASER = 50, ENERGY = 50, BOMB = 50, BIO = 0, RAD = 0, FIRE = 75, ACID = 75)
	custom_materials = list(/datum/material/glass= SHEET_MATERIAL_AMOUNT * 4, /datum/material/alloy/plastitanium= SHEET_MATERIAL_AMOUNT * 2)

/obj/item/kitchen/knife/shiv/carrot/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] forcefully drives \the [src] into [user.ru_ego()] eye! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return BRUTELOSS

/obj/item/kitchen/rollingpin
	name = "rolling pin"
	desc = "Used to knock out the Bartender."
	icon_state = "rolling_pin"
	force = 8
	throwforce = 5
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_NORMAL
	custom_materials = list(/datum/material/wood = MINERAL_MATERIAL_AMOUNT * 1.5)
	attack_verb = list("bashed", "battered", "bludgeoned", "thrashed", "whacked")
	custom_price = PRICE_ALMOST_CHEAP

/obj/item/kitchen/rollingpin/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins flattening [user.ru_ego()] head with \the [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return BRUTELOSS

/obj/item/kitchen/unrollingpin
	name = "unrolling pin"
	desc = "For when you accidentally flattened something."
	icon_state = "unrolling_pin"
	force = 8
	throwforce = 5
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_NORMAL
	custom_materials = list(/datum/material/wood = MINERAL_MATERIAL_AMOUNT * 1.5)
	attack_verb = list("bashed", "battered", "bludgeoned", "thrashed", "whacked")
	custom_price = PRICE_ALMOST_CHEAP

/obj/item/kitchen/unrollingpin/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins unflattening [user.ru_ego()] head with \the [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return BRUTELOSS

/* Trays  moved to /obj/item/storage/bag */

/obj/item/kitchen/knife/scimitar
	name = "scimitar knife"
	desc = "A knife used to cleanly butcher. Its razor-sharp edge has been honed for butchering, but has been poorly maintained over the years."
	attack_verb = list("cleaved", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")

/obj/item/kitchen/knife/scimitar/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 90 - force, 100, force - 60) //bonus chance increases depending on force
