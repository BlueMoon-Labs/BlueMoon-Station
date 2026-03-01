/obj/item/storage/belt/shamshir
	name = "authentic shamshir leather sheath"
	desc = "A good-looking sheath that is advertised as being made of real Venusian black leather. It feels rather plastic-like to the touch, and it looks like it's made to fit a British cavalry sabre."
	icon_state = "sheathsec"
	item_state = "sheathsec"
	w_class = WEIGHT_CLASS_BULKY
	content_overlays = TRUE
	onmob_overlays = TRUE
	var/list/fitting_swords = list(/obj/item/melee/sabre, /obj/item/melee/baton/stunsword, /obj/item/melee/shamshir)
	var/starting_sword = /obj/item/melee/shamshir

/obj/item/storage/belt/shamshir/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 1
	STR.rustle_sound = FALSE
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.can_hold = typecacheof(fitting_swords)
	STR.quickdraw = TRUE

/obj/item/storage/belt/shamshir/examine(mob/user)
	. = ..()
	if(length(contents))
		. += "<span class='notice'>Alt-click it to quickly draw the blade.</span>"

/obj/item/storage/belt/shamshir/PopulateContents()
	if(starting_sword)
		new starting_sword(src)

/obj/item/melee/shamshir
	name = "authentic shamshir sabre"
	desc = "An expertly crafted historical human sword once used by the Persians which has recently gained traction due to Venusian historal recreation sports. One small flaw, the Taj-based company who produces these has mistaken them for British cavalry sabres akin to those used by high ranking Nanotrasen officials. Atleast it cuts the same way!."
	icon = 'icons/obj/weapons/sword.dmi'
	icon_state = "shamshir"
	item_state = "shamshir"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	flags_1 = CONDUCT_1
	obj_flags = UNIQUE_RENAME
	force = 15
	wound_bonus = 5
	bare_wound_bonus = 10
	throwforce = 15
	w_class = WEIGHT_CLASS_BULKY
	block_chance = 30
	armour_penetration = 50
	sharpness = WOUND_SLASH
	attack_verb = list("slashed", "cut")
	hitsound = 'sound/weapons/rapierhit.ogg'
	custom_materials = list(/datum/material/iron = 1000)
	total_mass = 3.4
	item_flags = NEEDS_PERMIT | ITEM_CAN_PARRY
	block_parry_data = /datum/block_parry_data/traitor_rapier

// слизываю проки кэпской сабли
/obj/item/melee/shamshir/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 30, 95, 5) //fast and effective, but as a sword, it might damage the results.
	AddElement(/datum/element/sword_point)

/obj/item/melee/shamshir/on_exit_storage(datum/component/storage/S)
	var/obj/item/storage/belt/shamshir/B = S.parent
	if(istype(B))
		playsound(B, 'sound/items/unsheath.ogg', 25, 1)
	..()

/obj/item/melee/shamshir/on_enter_storage(datum/component/storage/S)
	var/obj/item/storage/belt/shamshir/B = S.parent
	if(istype(B))
		playsound(B, 'sound/items/sheath.ogg', 25, 1)
	..()

/obj/item/melee/shamshir/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "shamshir") // todo: make this and its rapier equivalent work for the inhands too

/obj/item/melee/shamshir/get_worn_belt_overlay(icon_file)
	return mutable_appearance(icon_file, "-shamshir")

/obj/item/melee/shamshir/suicide_act(mob/living/user)
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

/obj/item/melee/shamshir/proc/suicide_dismember(mob/living/user, obj/item/bodypart/affecting)
	if(!QDELETED(affecting) && affecting.dismemberable && affecting.owner == user && !QDELETED(user))
		playsound(user, hitsound, 25, 1)
		affecting.dismember(BRUTE)
		user.adjustBruteLoss(20)

/obj/item/melee/shamshir/proc/manual_suicide(mob/living/user, originally_nodropped)
	if(!QDELETED(user))
		user.adjustBruteLoss(200)
		user.death(FALSE)
	REMOVE_TRAIT(src, TRAIT_NODROP, SABRE_SUICIDE_TRAIT)
