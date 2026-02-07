//Made by quotefox
//Really needs some work, mainly because condoms should be a container for semen, but I dont know how that works yet. Feel free to improve upon.

/obj/item/genital_equipment/condom //TODO: fucking fix whatever the shit this it
	name 				= "condom"
	desc 				= "Dont be silly, cover your willy!"
	icon 				= 'modular_splurt/icons/obj/condom.dmi'
	throwforce			= 0
	icon_state 			= "b_condom_wrapped"
	var/unwrapped		= FALSE
	w_class 			= WEIGHT_CLASS_TINY
	custom_price		= PRICE_CHEAP_AS_FREE // 10 credits
	genital_slot 		= ORGAN_SLOT_PENIS
	var/const/max_volume = 300

/obj/item/genital_equipment/condom/Initialize()
	create_reagents(max_volume, DRAWABLE|TRANSPARENT|NO_REACT)
	return ..()

/obj/item/genital_equipment/condom/item_inserting(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE

	if(!(G.owner.client?.prefs?.erppref == "Yes"))
		to_chat(user, span_warning("They don't want you to do that!"))
		return FALSE

	if(!unwrapped)
		to_chat(user, span_notice("You must remove the condom from the package first!"))
		return FALSE

	if(!G.owner.has_penis() == HAS_EXPOSED_GENITAL)
		to_chat(user, span_notice("You can't find anywhere to put the condom!"))
		return FALSE

	if(locate(src.type) in G.contents)
		to_chat(user, span_notice("\The <b>[G.owner]</b> is already wearing a condom!"))
		return FALSE

	G.owner.visible_message(span_warning("\The <b>[user]</b> is trying to put a condom on \the <b>[G.owner]</b>!"),\
						span_warning("\The <b>[user]</b> is trying to put a condom on you!"))

	if(!do_mob(user, G.owner, 4 SECONDS))
		return FALSE

/obj/item/genital_equipment/condom/item_inserted(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE
	playsound(G.owner, 'modular_sand/sound/lewd/latex.ogg', 50, 1, -1)
	to_chat(G.owner, span_userlove("Your penis feels more safe!"))

/obj/item/genital_equipment/condom/update_icon_state()
	if(!unwrapped)
		icon_state = "b_condom_wrapped"
	else
		switch(reagents.total_volume)
			if(1 to 49)
				icon_state = "b_condom_inflated"
			if(50 to 100)
				icon_state = "b_condom_inflated_med"
			if(101 to 249)
				icon_state = "b_condom_inflated_large"
			if(250 to max_volume)
				icon_state = "b_condom_inflated_huge"
			else
				icon_state = "b_condom"
	return ..()

/obj/item/genital_equipment/condom/update_overlays()
	. = ..()
	if(!reagents.total_volume || !unwrapped)
		return

	. += mutable_appearance(icon, "[icon_state]-overlay", color = mix_color_from_reagents(reagents.reagent_list))

/obj/item/genital_equipment/condom/on_reagent_change()
	update_icon()

/obj/item/genital_equipment/condom/attack_self(mob/user) //Unwrap The Condom in hands
	. = ..()
	if(!isliving(user) || unwrapped)
		return

	unwrapped = TRUE
	update_icon()
	to_chat(user, "<span class='notice'>You unwrap the condom.</span>")
	playsound(user, 'sound/items/poster_ripped.ogg', 50, 1, -1)

/obj/item/genital_equipment/condom/throw_impact(atom/hit_atom)
	. = ..()
	if(!. && reagents.total_volume) //if we're not being caught
		splat(hit_atom)

// Копипаста из /obj/item/reagent_containers/proc/SplashReagents
/obj/item/genital_equipment/condom/proc/splat(atom/movable/target)
	if(isliving(loc) || !reagents || !reagents.total_volume)
		return

	var/mob/thrown_by = thrownby?.resolve()

	if(ismob(target) && target.reagents)
		reagents.total_volume *= rand(5,10) * 0.1 //Not all of it makes contact with the target
		var/mob/M = target
		var/R = reagents.log_list()
		target.visible_message("<span class='danger'>[M] has been splashed with something!</span>", \
						"<span class='userdanger'>[M] has been splashed with something!</span>")
		var/turf/TT = get_turf(target)
		var/throwerstring
		if(thrown_by)
			log_combat(thrown_by, M, "splashed", R)
			var/turf/AT = get_turf(thrown_by)
			throwerstring = " THROWN BY [key_name(thrown_by)] at [AT] (AREACOORD(AT)]"
		log_reagent("SPLASH: [src] mob SplashReagents() onto [key_name(target)] at [TT] ([AREACOORD(TT)])[throwerstring] - [R]")
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			var/obj/item/bodypart/affecting = H.get_bodypart(check_zone(thrown_by.zone_selected))
			reagents.reaction(M, TOUCH, affected_bodypart = affecting)
		else
			reagents.reaction(M, TOUCH)
	else
		if(isturf(target) && reagents.reagent_list.len && thrown_by)
			log_combat(thrown_by, target, "splashed (thrown) [english_list(reagents.reagent_list)]", "in [AREACOORD(target)]")
			log_game("[key_name(thrown_by)] splashed (thrown) [english_list(reagents.reagent_list)] on [target] in [AREACOORD(target)].")
			message_admins("[ADMIN_LOOKUPFLW(thrown_by)] splashed (thrown) [english_list(reagents.reagent_list)] on [target] in [ADMIN_VERBOSEJMP(target)].")
		var/turf/T = get_turf(target)
		var/throwerstring
		if(thrown_by)
			var/turf/AT = get_turf(thrown_by)
			throwerstring = " THROWN BY [key_name(thrown_by)] at [AT] ([AREACOORD(AT)])"
		log_reagent("SPLASH - [src] object SplashReagents() onto [target] at [T] ([AREACOORD(T)])[throwerstring] - [reagents.log_list()]")
		visible_message("<span class='notice'>[src] spills its contents all over [target].</span>")
		reagents.reaction(target, TOUCH)

	reagents.clear_reagents()
	playsound(get_turf(target), 'sound/misc/splort.ogg', 50, TRUE)
	qdel(src)

/obj/item/genital_equipment/condom/open
	icon_state = "b_condom"
	unwrapped = TRUE

/obj/item/genital_equipment/condom/open/used
	icon_state = "b_condom_inflated"

/obj/item/genital_equipment/condom/open/used/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/consumable/semen, rand(5, max_volume))

/obj/item/clothing/head/condom //p
	name = "condom"
	icon = 'modular_splurt/icons/obj/condom.dmi'
	desc = "Looks like someone had abit of some fun!"
	mob_overlay_icon = 'modular_splurt/icons/obj/clothing/head.dmi'
	icon_state = "b_condom_out"
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 5, "rad" = 0, "fire" = 0, "acid" = 0)
