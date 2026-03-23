/obj/machinery/gibber
	name = "gibber"
	desc = "The name isn't descriptive enough?"
	icon = 'icons/obj/machines/kitchen.dmi'
	icon_state = "grinder"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 500
	circuit = /obj/item/circuitboard/machine/gibber
	/// Is it on?
	var/operating = FALSE
	/// Does it need cleaning?
	var/dirty = FALSE
	/// Time from starting until meat appears
	var/gibtime = 4 SECONDS
	/// How much meat we meet when we meat the meat
	var/meat_produced = 2
	/// food_quality of meat produced
	var/meat_quality = 35
	/// If the gibber should give the 'Subject may not have abiotic items on' message
	var/ignore_clothing = FALSE
	/// The DNA info of the last gibbed mob
	var/list/blood_dna_info = list()


/obj/machinery/gibber/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(on_cleaned))

/obj/machinery/gibber/Destroy()
	UnregisterSignal(src, COMSIG_COMPONENT_CLEAN_ACT)
	return ..()

/obj/machinery/gibber/RefreshParts()
	gibtime = initial(gibtime)
	meat_produced = initial(meat_produced)
	meat_quality = initial(meat_quality) // unupgraded this means quality is 50, and max upgraded it is 95
	ignore_clothing = initial(ignore_clothing)
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		meat_produced += B.rating
		meat_quality += B.rating * 15
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		gibtime -= 5 * M.rating
		if(M.rating >= 2)
			ignore_clothing = TRUE

/obj/machinery/gibber/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>The status display reads: Outputting <b>[meat_produced]</b> meat slab(s) after <b>[gibtime*0.1]</b> seconds of processing.</span>"
		for(var/obj/item/stock_parts/manipulator/M in component_parts)
			if(M.rating >= 2)
				. += "<span class='notice'>Gibber has been upgraded to process inorganic materials.</span>"

/obj/machinery/gibber/update_overlays()
	. = ..()
	if(dirty)
		var/mutable_appearance/blood_overlay = mutable_appearance(icon, "grinder_bloody", appearance_flags = RESET_COLOR|KEEP_APART)
		if(blood_dna_info && blood_dna_info["color"])
			blood_overlay.color = blood_dna_info["color"]
		else
			blood_overlay.color = BLOOD_COLOR_HUMAN
		. += blood_overlay
	if(machine_stat & (NOPOWER|BROKEN) || panel_open)
		return
	if(operating)
		. += "grinder_active"
		. += emissive_appearance(icon, "grinder_active", src, alpha = src.alpha)
		. += "grinder_jaws_active"
		return
	if(!occupant)
		. += "grinder_empty"
		. += emissive_appearance(icon, "grinder_empty", src, alpha = src.alpha)
		return
	. += "grinder_loaded"
	. += emissive_appearance(icon, "grinder_loaded", src, alpha = src.alpha)

/obj/machinery/gibber/attack_paw(mob/user)
	return attack_hand(user)

/obj/machinery/gibber/container_resist(mob/living/user)
	go_out()

/obj/machinery/gibber/relaymove(mob/living/user)
	go_out()

/obj/machinery/gibber/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(machine_stat & (NOPOWER|BROKEN))
		return
	if(operating)
		to_chat(user, "<span class='danger'>It's locked and running.</span>")
		return

	if(!anchored)
		to_chat(user, "<span class='notice'>[src] cannot be used unless bolted to the ground.</span>")
		return

	if(user.pulling && user.a_intent == INTENT_GRAB && isliving(user.pulling))
		var/mob/living/L = user.pulling
		if(!iscarbon(L))
			to_chat(user, "<span class='danger'>This item is not suitable for the gibber!</span>")
			return
		var/mob/living/carbon/C = L
		if(C.buckled ||C.has_buckled_mobs())
			to_chat(user, "<span class='warning'>[C] is attached to something!</span>")
			return

		if(!ignore_clothing)
			for(var/obj/item/I in C.held_items + C.get_equipped_items())
				if(!HAS_TRAIT(I, TRAIT_NODROP))
					to_chat(user, "<span class='danger'>Subject may not have abiotic items on.</span>")
					return

		user.visible_message("<span class='danger'>[user] starts to put [C] into the gibber!</span>")

		add_fingerprint(user)

		if(do_after(user, gibtime, target = src))
			if(C && user.pulling == C && !C.buckled && !C.has_buckled_mobs() && !occupant)
				user.visible_message("<span class='danger'>[user] stuffs [C] into the gibber!</span>")
				C.forceMove(src)
				occupant = C
				update_icon()
	else
		startgibbing(user)

/obj/machinery/gibber/attackby(obj/item/P, mob/user, params)
	if(default_deconstruction_screwdriver(user, "grinder_open", "grinder", P))
		return

	else if(default_pry_open(P))
		return

	else if(default_unfasten_wrench(user, P))
		return

	else if(default_deconstruction_crowbar(P))
		return
	else
		return ..()



/obj/machinery/gibber/verb/eject()
	set category = "Object"
	set name = "empty gibber"
	set src in oview(1)

	if(usr.incapacitated())
		return
	src.go_out()
	add_fingerprint(usr)
	return

/obj/machinery/gibber/proc/go_out()
	dropContents()
	update_icon()

/obj/machinery/gibber/proc/startgibbing(mob/user)
	if(src.operating)
		return
	if(!src.occupant)
		visible_message("<span class='italics'>You hear a loud metallic grinding sound.</span>")
		return
	use_power(1000)
	visible_message("<span class='italics'>You hear a loud squelchy grinding sound.</span>")
	playsound(src.loc, 'sound/machines/juicer.ogg', 50, 1)
	operating = TRUE
	update_icon()

	Shake(2, 2, gibtime)
	var/mob/living/mob_occupant = occupant
	var/sourcename = mob_occupant.real_name
	var/sourcejob
	if(ishuman(occupant))
		var/mob/living/carbon/human/gibee = occupant
		sourcejob = gibee.job
	var/sourcenutriment = mob_occupant.nutrition / 15
	var/gibtype = /obj/effect/decal/cleanable/blood/gibs
	var/typeofmeat = /obj/item/reagent_containers/food/snacks/meat/slab/human
	var/typeofskin

	var/obj/item/reagent_containers/food/snacks/meat/slab/allmeat[meat_produced]
	var/obj/item/stack/sheet/animalhide/skin
	var/list/datum/disease/diseases = mob_occupant.get_static_viruses()

	if(ishuman(occupant))
		var/mob/living/carbon/human/gibee = occupant
		if(gibee.dna && gibee.dna.species)
			typeofmeat = gibee.dna.species.meat
			typeofskin = gibee.dna.species.skinned_type
		blood_dna_info = gibee.get_blood_dna_list()

	else if(iscarbon(occupant))
		var/mob/living/carbon/C = occupant
		typeofmeat = C.type_of_meat
		gibtype = C.gib_type
		if(ismonkey(C))
			typeofskin = /obj/item/stack/sheet/animalhide/monkey
		else if(isalien(C))
			typeofskin = /obj/item/stack/sheet/animalhide/xeno
		blood_dna_info = C.get_blood_dna_list()

	for (var/i=1 to meat_produced)
		var/obj/item/reagent_containers/food/snacks/meat/slab/newmeat = new typeofmeat
		newmeat.name = "[sourcename] [newmeat.name]"
		if(istype(newmeat))
			newmeat.adjust_food_quality(meat_quality)
			newmeat.subjectname = sourcename
			newmeat.reagents.add_reagent (/datum/reagent/consumable/nutriment, sourcenutriment / meat_produced) // Thehehe. Fat guys go first
			if(sourcejob)
				newmeat.subjectjob = sourcejob
		allmeat[i] = newmeat

	if(typeofskin)
		skin = new typeofskin

	log_combat(user, occupant, "gibbed")
	mob_occupant.pain_emote(realagony = TRUE)
	mob_occupant.death(1)
	mob_occupant.ghostize()
	qdel(src.occupant)
	addtimer(CALLBACK(src, PROC_REF(make_meat), skin, allmeat, meat_produced, gibtype, diseases), gibtime)

/obj/machinery/gibber/proc/make_meat(obj/item/stack/sheet/animalhide/skin, list/obj/item/reagent_containers/food/snacks/meat/slab/allmeat, meat_produced, gibtype, list/datum/disease/diseases)
	playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)
	if(!dirty && prob(50))
		dirty = TRUE
	var/turf/T = get_turf(src)
	var/list/turf/nearby_turfs = RANGE_TURFS(3,T) - T
	if(skin)
		skin.forceMove(loc)
		skin.throw_at(pick(nearby_turfs),meat_produced,3)
	for (var/i=1 to meat_produced)
		var/obj/item/meatslab = allmeat[i]
		meatslab.forceMove(loc)
		meatslab.throw_at(pick(nearby_turfs),i,3)
		for (var/turfs=1 to meat_produced)
			var/turf/gibturf = pick(nearby_turfs)
			if (!gibturf.density && (src in view(gibturf)))
				new gibtype(gibturf,i,diseases)

	operating = FALSE
	update_icon()

//auto-gibs anything that bumps into it
/obj/machinery/gibber/autogibber
	var/input_dir = NORTH

/obj/machinery/gibber/autogibber/Bumped(atom/movable/AM)
	var/atom/input = get_step(src, input_dir)
	if(ismob(AM))
		var/mob/M = AM

		if(M.loc == input)
			M.forceMove(src)
			M.gib()

/obj/machinery/gibber/proc/on_cleaned(obj/source_component, obj/source)
	SIGNAL_HANDLER

	. = NONE

	dirty = FALSE
	update_appearance(UPDATE_OVERLAYS)
	. |= COMPONENT_CLEANED //|COMPONENT_CLEANED_GAIN_XP
