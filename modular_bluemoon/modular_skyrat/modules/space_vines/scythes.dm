/obj/item/scythe
	icon_state = "scythe0"
	icon = 'modular_bluemoon/modular_skyrat/modules/space_vines/icons/items_and_weapons.dmi'
	mob_overlay_icon = 'modular_bluemoon/modular_skyrat/modules/space_vines/icons/back.dmi'
	lefthand_file = 'modular_bluemoon/modular_skyrat/modules/space_vines/icons/polearms_lefthand.dmi'
	righthand_file = 'modular_bluemoon/modular_skyrat/modules/space_vines/icons/polearms_righthand.dmi'
	name = "scythe_t1"
	desc = "A sharp and curved blade on a long fibremetal handle, this tool makes it easy to reap what you sow."
	force = 13
	throwforce = 5
	throw_speed = 2
	throw_range = 3
	attack_speed = CLICK_CD_MELEE
	w_class = WEIGHT_CLASS_BULKY
	flags_1 = CONDUCT_1
	armour_penetration = 20
	slot_flags = ITEM_SLOT_BACK
	attack_verb = list("chopped", "sliced", "cut", "reaped")
	hitsound = 'sound/weapons/bladeslice.ogg'

	var/hit_range = 0
	var/swiping = FALSE

/obj/item/scythe/stick
	name = "Stick For Angry Plants"
	desc = "A stick with a sharp piece of metal attached to the end of it. It's not much, but it'll do."
	icon_state = "bokken"
	item_state = "bokken"
	icon = 'icons/obj/items_and_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 5

/obj/item/scythe/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 90, 105)

/obj/item/scythe/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is beheading себя with [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		var/obj/item/bodypart/BP = C.get_bodypart(BODY_ZONE_HEAD)
		if(BP)
			BP.drop_limb()
			playsound(src,pick('sound/misc/desceration-01.ogg','sound/misc/desceration-02.ogg','sound/misc/desceration-01.ogg') ,50, 1, -1)
	return (BRUTELOSS)

/obj/item/scythe/pre_attack(atom/A, mob/living/user, params, attackchain_flags, damage_multiplier)
	. = ..()
	if(. & STOP_ATTACK_PROC_CHAIN)
		return
	if(swiping || !istype(A, /obj/structure/spacevine) || get_turf(A) == get_turf(user))
		return
	else
		var/turf/user_turf = get_turf(user)
		var/dir_to_target = get_dir(user_turf, get_turf(A))
		var/stam_gain = 0
		swiping = TRUE
		if(hit_range >= 1)
			for(var/obj/structure/spacevine/choose_vine in view(hit_range, A))
				melee_attack_chain(user, choose_vine)
		var/static/list/scythe_slash_angles = list(0, 45, 90, -45, -90)
		for(var/i in scythe_slash_angles)
			var/turf/T = get_step(user_turf, turn(dir_to_target, i))
			for(var/obj/structure/spacevine/V in T)
				if(user.Adjacent(V))
					melee_attack_chain(user, V, attackchain_flags = ATTACK_IGNORE_CLICKDELAY)
					stam_gain += 5					//should be hitcost
		swiping = FALSE
		stam_gain += 2								//Initial hitcost
		user.adjustStaminaLoss(-stam_gain)
		user.DelayNextAction()

/obj/item/scythe/tier1
	name = "scythe (tier 1)"
	icon_state = "scythe_t1"

/obj/item/scythe/tier2
	name = "scythe (tier 2)"
	icon_state = "scythe_t2"
	force = 15
	hit_range = 1

/obj/item/scythe/tier3
	name = "scythe (tier 3)"
	icon_state = "scythe_t3"
	force = 18
	hit_range = 2

/obj/item/scythe/tier4
	name = "scythe (tier 4)"
	icon_state = "scythe_t4"
	force = 22
	hit_range = 3


/datum/design/scythe
	name = "Scythe (Tier 1)"
	desc = "A sharp and curved blade on a long fibremetal handle, this tool makes it easy to reap what you sow."
	id = "scythet1"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 8000, /datum/material/glass = 4000)
	construction_time = 10
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE
	build_path = /obj/item/scythe/tier1

/datum/design/scythe/tier2
	name = "Scythe (Tier 2)"
	id = "scythet2"
	materials = list(/datum/material/iron = 12000, /datum/material/glass = 6000)
	build_path = /obj/item/scythe/tier2

/datum/techweb_node/scythe_t1
	id = "scythe1"
	display_name = "Scythe (Tier 1)"
	description = "Culling tools"
	prereq_ids = list("botany")
	design_ids = list("scythet1")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3000)

/datum/techweb_node/scythe_t2
	id = "scythe2"
	display_name = "Scythe (Tier 2)"
	description = "Culling tools"
	prereq_ids = list("scythe1")
	design_ids = list("scythet2")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3000)

/datum/supply_pack/service/tier3_scythe
	name = "Tier 3 Scythe"
	desc = "Have pesky vines and need a way to chop it down faster? Order this crate now!"
	cost = 4000
	contains = list(/obj/item/scythe/tier3)
	crate_name = "tier 3 scythe supply crate"

/datum/supply_pack/service/tier4_scythe
	name = "Tier 4 Scythe"
	desc = "Have pesky vines and need a way to chop it down faster? Order this crate now!"
	cost = 8000
	contains = list(/obj/item/scythe/tier4)
	crate_name = "tier 4 scythe supply crate"
