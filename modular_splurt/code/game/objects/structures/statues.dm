/obj/structure/statue/boney //wow thanks so much, it's almost like no one would ever make bone statues
	name = "statue of an ashwalker"
	icon = 'modular_splurt/icons/obj/structures/statue.dmi'
	icon_state = "ashie"
	max_integrity = 300
	desc = "This is a suprisingly-well done statue made out of bone."
	impressiveness = 10
	custom_materials = list(/datum/material/bone = MINERAL_MATERIAL_AMOUNT*5)
	abstract_type = /obj/structure/statue/bone

/obj/structure/statue/boney/ashwalker
	icon_state = "bone"
	desc = "A statue honoring Owia-Akeshi, a brave ashwalker that perished while defending the nest from a wild ash drake. May his soul rest in peace."
	impressiveness = 25

/obj/structure/statue/gargoyle
	name = "statue"
	desc = "An incredibly intricate statue, which... almost seems alive!"
	icon_state = "human_male"
	density = TRUE
	anchored = TRUE
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1
	max_integrity = 200
	var/mob/living/petrified_mob

/obj/structure/statue/gargoyle/Initialize(mapload, mob/living/L)
	. = ..()
	if(L)
		petrified_mob = L
		if(L.buckled)
			L.buckled.unbuckle_mob(L,force=1)
		L.visible_message("<span class='warning'>[L]'s skin rapidly turns to stone!</span>", "<span class='userdanger'>Your skin abruptly hardens as you turn to stone once more!</span>")
		L.forceMove(src)
		ADD_TRAIT(L, TRAIT_MUTE, STATUE_TRAIT)
		ADD_TRAIT(L, TRAIT_MOBILITY_NOMOVE, STATUE_TRAIT)
		ADD_TRAIT(L, TRAIT_MOBILITY_NOPICKUP, STATUE_TRAIT)
		ADD_TRAIT(L, TRAIT_MOBILITY_NOUSE, STATUE_TRAIT)
		ADD_TRAIT(L, TRAIT_RESTRAINED, STATUE_TRAIT)
		L.faction += "mimic" //Stops mimics from instaqdeling people in statues
		L.status_flags |= GODMODE
		obj_integrity = L.health + 100 //stoning damaged mobs will result in easier to shatter statues
		max_integrity = obj_integrity

/obj/structure/statue/gargoyle/handle_atom_del(atom/A)
	if(A == petrified_mob)
		petrified_mob = null

/obj/structure/statue/gargoyle/Destroy()
	if(petrified_mob)
		var/datum/quirk/gargoyle/gargoyle_quirk = locate() in petrified_mob.roundstart_quirks
		if(gargoyle_quirk)
			gargoyle_quirk.transformed = FALSE
			gargoyle_quirk.current = null
			gargoyle_quirk.paused = FALSE
			gargoyle_quirk.cooldown = 30
		var/datum/action/gargoyle/transform/transform_action = locate() in petrified_mob.actions
		if(transform_action)
			transform_action.current = null
		petrified_mob.status_flags &= ~GODMODE
		petrified_mob.forceMove(loc)
		REMOVE_TRAIT(petrified_mob, TRAIT_MUTE, STATUE_TRAIT)
		REMOVE_TRAIT(petrified_mob, TRAIT_MOBILITY_NOMOVE, STATUE_TRAIT)
		REMOVE_TRAIT(petrified_mob, TRAIT_MOBILITY_NOPICKUP, STATUE_TRAIT)
		REMOVE_TRAIT(petrified_mob, TRAIT_MOBILITY_NOUSE, STATUE_TRAIT)
		REMOVE_TRAIT(petrified_mob, TRAIT_RESTRAINED, STATUE_TRAIT)
		petrified_mob.take_overall_damage((petrified_mob.health - obj_integrity + 100)) //any new damage the statue incurred is transfered to the mob
		petrified_mob.faction -= "mimic"
		petrified_mob = null
	return ..()

/obj/structure/statue/gargoyle/deconstruct(disassembled = TRUE)
	if(!disassembled)
		if(petrified_mob)
			petrified_mob.dust()
	visible_message("<span class='danger'>[src] shatters!.</span>")
	qdel(src)
