#define REGENERATION_DELAY 60  // After taking damage, how long it takes for automatic regeneration to begin for tentacles.
#define REGEN_AMOUNT 6 //How much is healed pre regen cooldown

/obj/structure/tentacles/node
	name = "tentacles node"
	desc = "Looks like their roots."
	icon = 'modular_bluemoon/icons/mob/tentacles.dmi'
	icon_state = "node"
	max_integrity = 200
	CanAtmosPass = ATMOS_PASS_DENSITY

/mob/living/simple_animal/hostile/tentacles
	name = "Tentacles"
	desc = "I have seen enough space hentai to know..."
	icon = 'modular_bluemoon/icons/mob/tentacles.dmi'
	icon_state = "tentacles"
	icon_living = "tentacles"
	icon_dead = "tentacles_dead"
	icon_gib = "tentacles_dead"
	faction = list("hentai")
	var/base_icon = "tentacles"

	var/change_target_hole_cooldown = 0
	var/REGEN_COOLDOWN = 0 //Used for how long it takes before a healing will take place default in 60 seconds
	var/chosen_hole
	has_penis = TRUE
	has_tentacles = TRUE
	var/tired = 0
	var/regen_cooldown = 0 //Used for how long it takes before a healing will take place default in 60 seconds
	var/regen_amount = 0 //How much is healed pre regen cooldow

	mob_biotypes = MOB_ORGANIC|MOB_BEAST

	//Tentacles don't speak and not move
	density = 0
	speak_chance = 0
	wander = 0
	stop_automated_movement = 1
	speed = 3
	turns_per_move = 3
	move_force = MOVE_FORCE_DEFAULT
	move_resist = MOVE_FORCE_VERY_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
	a_intent = INTENT_HARM // Сука.

	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat)

	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"

	maxHealth = 200
	health = 200

	//Harmless
	harm_intent_damage = 0
	obj_damage = 0
	melee_damage_lower = 0
	melee_damage_upper = 0
	attack_verb_continuous = "slap"
	attack_verb_simple = "slap"
	attack_sound = 'sound/weapons/bite.ogg'
	speak_emote = list("jiggles", "waves", "vibrates")
	//Tentacles aren't affected by cold.
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500
	pressure_resistance = 200
	gold_core_spawnable = HOSTILE_SPAWN

/mob/living/simple_animal/hostile/tentacles/Initialize()
	. = ..()
	status_flags &= !CANPUSH
	//SShorny_mobs_pool.horny_mobs += src

/mob/living/simple_animal/hostile/tentacles/death(gibbed)
	. = ..()
	qdel(src)
	//SShorny_mobs_pool.horny_mobs -= src

/mob/living/simple_animal/hostile/tentacles/Destroy()
	. = ..()
	//SShorny_mobs_pool.horny_mobs -= src

/mob/living/simple_animal/hostile/tentacles/moan() //Tentacles do not moan lmao
	return

/mob/living/simple_animal/hostile/tentacles/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(regen_amount)
		regen_cooldown = world.time + REGENERATION_DELAY

/mob/living/simple_animal/hostile/tentacles/BiologicalLife(delta_time, times_fired)
	if(!(. = ..()))
		return
	if(REGEN_AMOUNT && REGEN_COOLDOWN < world.time)
		heal_overall_damage(REGEN_AMOUNT)
	if(tired >=1)
		tired -= 1

/mob/living/simple_animal/hostile/tentacles/MoveToTarget()
	stop_automated_movement = 1
	if(!target || !CanAttack(target))
		LoseTarget()
		return 0
	if(targets_from && isturf(targets_from.loc) && target.Adjacent(targets_from)) //If they're next to us, attack
		MeleeAction()
	else
		return 1

//BLUEMOON ADD START || The sex mob will no longer even try to attack targets that are not suitable for prefs.
/mob/living/simple_animal/hostile/tentacles/CanAttack(atom/the_target)
	. = ..()
	if(!.)
		return .

	if(!isliving(the_target))
		return .

	var/mob/living/M = the_target

	if(M.client && M.client?.prefs.mobsexpref == "No") //So the new pref checks - Gardelin0
		return FALSE

	if(M.client && M.client?.prefs.erppref == "Yes" && CHECK_BITFIELD(M.client?.prefs.toggles, VERB_CONSENT) && M.client?.prefs.nonconpref != "No")
		return TRUE

	return FALSE
//BLUEMOON ADD END

/mob/living/simple_animal/hostile/tentacles/AttackingTarget()
	var/mob/living/M = target

	var/onLewdCooldown = FALSE

	if(get_refraction_dif() > 0)
		onLewdCooldown = TRUE

	if(onLewdCooldown)
		return // Do nothing

	if(!M.pulledby)
		if(!M.buckled)
			M.forceMove(src.loc)

		start_pulling(M, supress_message = TRUE)
		log_combat(src, M, "grabbed")
		M.visible_message("<span class='warning'>[src] violently grab and entangle [M]!</span>", \
			"<span class='userdanger'>[src] violently grab and entangle you!</span>")
		setGrabState(GRAB_NECK) //Instant neck grab
		if(prob(25))
			M.Stun(30) //People want them to be dangerous, huh?
			M.visible_message("<span class='warning'>[src] secure [M]'s limbs, immobilizing them!</span>", \
				"<span class='userdanger'>[src] secures your limbs, immobilizing you!</span>")


		return

	if(change_target_hole_cooldown < world.time)
		chosen_hole = null
		while (chosen_hole == null)
			pickNewHole(M)
		change_target_hole_cooldown = world.time + 50

	if(get_refraction_dif() > 0)
		..()
		return

	while(M.pulledby && !tired)
		if(activate_after(src, 25))
			do_lewd_action(M)

/mob/living/simple_animal/hostile/tentacles/proc/pickNewHole(mob/living/M)
	var/hole_chosen = pick(1, 2)
	switch(hole_chosen)
		if(1)
			if(M.has_vagina())
				chosen_hole = CUM_TARGET_VAGINA
			if(M.has_penis())
				chosen_hole = CUM_TARGET_PENIS
		if(2)
			chosen_hole = CUM_TARGET_ANUS

/mob/living/simple_animal/hostile/tentacles/proc/do_lewd_action(mob/living/M)
	if(get_refraction_dif() > 0)
		return

	if(!M.pulledby)
		return

	var/result = pick(1, 2)
	switch(chosen_hole)
		if(CUM_TARGET_ANUS)
			if(tearSlot(M, ITEM_SLOT_OCLOTHING))
				return
			if(tearSlot(M, ITEM_SLOT_ICLOTHING))
				return
			if(tearSlot(M, ITEM_SLOT_SHIRT))
				return
			if(tearSlot(M, ITEM_SLOT_UNDERWEAR))
				return

			tentacle_anal(M)

		if(CUM_TARGET_VAGINA)
			if(tearSlot(M, ITEM_SLOT_OCLOTHING))
				return
			if(tearSlot(M, ITEM_SLOT_ICLOTHING))
				return
			if(tearSlot(M, ITEM_SLOT_SHIRT))
				return
			if(tearSlot(M, ITEM_SLOT_UNDERWEAR))
				return

			switch(result)
				if(1)
					tentacle_vaginal(M)
				if(2)
					tentacle_vaginal_double(M)

		if(CUM_TARGET_PENIS)
			if(tearSlot(M, ITEM_SLOT_OCLOTHING))
				return
			if(tearSlot(M, ITEM_SLOT_ICLOTHING))
				return
			if(tearSlot(M, ITEM_SLOT_SHIRT))
				return
			if(tearSlot(M, ITEM_SLOT_UNDERWEAR))
				return

			switch(result)
				if(1)
					tentacle_penis(M)
				if(2)
					tentacle_penis_double(M)

/mob/living/simple_animal/hostile/tentacles/cum(mob/living/M, target_orifice, cum_inside = FALSE, anonymous = FALSE)

	if(get_refraction_dif() > 0)
		return

	var/message
	var/obj/item/organ/genital/target_gen = null
	switch(chosen_hole)
		if(CUM_TARGET_VAGINA)
			message = "вгоняют свои тентакли в дырочки \the [M] и заполняют их спермой!"
			target_gen = M.getorganslot(ORGAN_SLOT_WOMB)
			target_gen.reagents.add_reagent(/datum/reagent/consumable/semen, 100)
			M.impregnate(src, M.getorganslot(ORGAN_SLOT_WOMB), src.type)

		if(CUM_TARGET_PENIS)
			message = "обхватывают член \the [M] и обливают спермой!"
			target_gen = M.getorganslot(ORGAN_SLOT_PENIS)
			target_gen.reagents.add_reagent(/datum/reagent/consumable/semen, 100)

		if(CUM_TARGET_ANUS)
			message = "вгоняют свои тентакли в задницу \the [M] и заполняют её спермой!"
			target_gen = M.getorganslot(ORGAN_SLOT_ANUS)
			target_gen.reagents.add_reagent(/datum/reagent/consumable/semen, 100)

	if(istype(M, /mob/living/carbon))
		M.reagents.add_reagent(/datum/reagent/drug/aphrodisiacplus, 5) //Cum contains hexocrocin
	new /obj/effect/decal/cleanable/semen(loc)

	playsound(loc, 'sound/effects/splat.ogg', 30, 1, -1)
	visible_message("<font color=purple><b>\The [src]</b> [message]</font>")
	shake_camera(M, 6, 1)
	set_is_fucking(null ,null)

	set_lust(0) // Nuts at 400
	tired += rand(5, 15)

/mob/living/simple_animal/hostile/tentacles/proc/tearSlot(mob/living/M, slot)
	var/obj/item/W = M.get_item_by_slot(slot)
	if(W)
		M.dropItemToGround(W)
		playsound(loc, "sound/items/poster_ripped.ogg", 30, 1, -1)
		visible_message("<span class='danger'>\The [src]</b> tears off \the [M]'s clothes!</span>", \
				"<span class='userdanger'>\The [src]</b> tears off \the [M]'s clothes!</span>", null, COMBAT_MESSAGE_RANGE)
		return TRUE
	return FALSE

/obj/item/reagent_containers/food/snacks/cube/tentacles
	name = "tentacles cube"
	desc = "Instant tentacles! Just add water!"
	tastes = list("pleasure" = 1, "hentai" = 1)
	dried_being = /mob/living/simple_animal/hostile/tentacles

/obj/item/storage/box/tentaclescubes
	name = "Instante tentacles box"
	desc = "Drymate brand tentacles cubes. Just add water!"
	icon = 'modular_bluemoon/icons/mob/tentacles.dmi'
	icon_state = "tentaclecubebox"
	illustration = null
	custom_price = 1500 //So people will stop spamming it

//  ⠄⢰⣧⣼⣯⠄⣸⣠⣶⣶⣦⣾⠄⢸⡇⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⣠
//  ⠄⣾⣿⠿⠿⠶⠿⢿⣿⣿⣿⣿⣦⣤⣄⢀⡅⢠⣾⣛⡉⠄⠄⠄⠸⢀⣿⠄
//  ⢀⡋⣡⣴⣶⣶⡀⠄⠄⠙⢿⣿⣿⣿⣿⣿⣴⣿⣿⣿⢃⣤⣄⣀⣥⣿⣿⠄
//  ⢸⣇⠻⣿⣿⣿⣧⣀⢀⣠⡌⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠿⣿⣿⣿⠄
//  ⢸⣿⣷⣤⣤⣤⣬⣙⣛⢿⣿⣿⣿⣿⣿⣿⡿⣿⣿⡍⠄⠄⢀⣤⣄⠉⠋⣰
//  ⣖⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⢇⣿⣿⡷⠶⠶⢿⣿⣿⠇⢀⣤
//  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣽⣿⣿⣿⡇⣿⣿⣿⣿⣿⣿⣷⣶⣥⣴⣿⡗
//  ⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠄
//  ⣦⣌⣛⣻⣿⣿⣧⠙⠛⠛⡭⠅⠒⠦⠭⣭⡻⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠄
//  ⣿⣿⣿⣿⣿⣿⣿⡆⠄⠄⠄⠄⠄⠄⠄⠄⠹⠈⢋⣽⣿⣿⣿⣿⣵⣾⠃⠄
//  ⣿⣿⣿⣿⣿⣿⣿⣿⠄⣴⣿⣶⣄⠄⣴⣶⠄⢀⣾⣿⣿⣿⣿⣿⣿⠃⠄⠄
// ⠈⠻⣿⣿⣿⣿⣿⣿⡄⢻⣿⣿⣿⠄⣿⣿⡀⣾⣿⣿⣿⣿⣛⠛⠁⠄⠄⠄
//  ⠄⠄⠈⠛⢿⣿⣿⣿⠁⠞⢿⣿⣿⡄⢿⣿⡇⣸⣿⣿⠿⠛⠁⠄⠄⠄⠄⠄
//  ⠄⠄⠄⠄⠄⠉⠻⣿⣿⣾⣦⡙⠻⣷⣾⣿⠃⠿⠋⠁⠄⠄⠄⠄⠄⢀⣠⣴
//  ⣿⣶⣶⣮⣥⣒⠲⢮⣝⡿⣿⣿⡆⣿⡿⠃⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⣠

/obj/item/storage/box/tentaclescubes/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 7
	STR.can_hold = typecacheof(list(/obj/item/reagent_containers/food/snacks/cube/tentacles))

/obj/item/storage/box/tentaclescubes/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/reagent_containers/food/snacks/cube/tentacles(src)
