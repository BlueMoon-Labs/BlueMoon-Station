//// ERP Vendiga (👁,‿,👁)

/mob/living/simple_animal/wendigo
	name = "wendigo"
	desc = "A mythological man-eating legendary creature, you probably aren't going to survive this."
	show_erp_profile = TRUE
	health = 2500
	maxHealth = 2500
	icon_state = "wendigo_noblood"
	icon_living = "wendigo_noblood"
	icon_dead = "wendigo_dead"
	icon = 'icons/mob/icemoon/64x64megafauna.dmi'
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"
	attack_sound = 'sound/magic/demon_attack1.ogg'
	weather_immunities = list(TRAIT_SNOWSTORM_IMMUNE) // to ADD: Trait lewd summon
	speak_emote = list("roars")
	melee_damage_lower = 10
	melee_damage_upper = 20
	obj_damage = 20
	pixel_x = -16
	loot = list(/obj/item/wendigo_blood)
	blood_volume = BLOOD_VOLUME_NORMAL
	deathmessage = "falls, shaking the ground around it"
	deathsound = 'sound/effects/gravhit.ogg'
	melee_damage_type = STAMINA
	/// Saves the turf the megafauna was created at (spawns exit portal here)
	var/turf/starting
	/// Range for wendigo stomping when it moves
	var/stomp_range = 1
	/// Stores directions the mob is moving, then calls that a move has fully ended when these directions are removed in moved
	var/stored_move_dirs = 0
	/// If the wendigo is allowed to move
	var/can_move = TRUE

/mob/living/simple_animal/wendigo/Initialize(mapload) // абилки-активки
	. = ..()
	AddSpell(new /obj/effect/proc_holder/spell/targeted/night_vision/qareen(null))
	AddSpell(new /obj/effect/proc_holder/spell/targeted/telepathy/qareen(null))
	START_PROCESSING(SSobj, src)

/mob/living/simple_animal/wendigo/verb/switch_gender()
	set name = "Switch Gender"
	set desc = "Allows you to set your gender."
	set category = "Wendigo"

	if(stat != CONSCIOUS)
		to_chat(usr, span_warning("You cannot toggle your gender while unconcious!"))
		return

	var/choice = tgui_alert(usr, "Select Gender.", "Gender", list("Both", "Male", "Female", "None"))

	switch(choice)
		if("Both")
			has_penis = TRUE
			has_balls = TRUE
			has_vagina = TRUE
			gender = PLURAL
		if("Male")
			has_penis = TRUE
			has_balls = TRUE
			has_vagina = FALSE
			gender = MALE
		if("Female")
			has_penis = FALSE
			has_balls = FALSE
			has_vagina = TRUE
			gender = FEMALE
		if("None")
			has_penis = FALSE
			has_balls = FALSE
			has_vagina = FALSE
			gender = NEUTER

/// открывашка


/mob/living/simple_animal/wendigo/UnarmedAttack(atom/A, proximity, intent = a_intent, flags = NONE)
	if(istype(A, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/B = A
		try_open_airlock(B)
	else
		..()


/mob/living/simple_animal/wendigo/proc/try_open_airlock(obj/machinery/door/airlock/D)
	if(D.operating)
		return
	if(D.welded)
		to_chat(src, "<span class='warning'>The door is welded.</span>")
	else if(D.locked)
		to_chat(src, "<span class='warning'>The door is bolted.</span>")
	else if(D.allowed(src))
		if(D.density)
			D.open(TRUE)
		else
			D.close(TRUE)
		return TRUE
	else
		visible_message("<span class='danger'>[src] forces the door!</span>")
		playsound(src.loc, "sparks", 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
		if(D.density)
			D.open(TRUE)
		else
			D.close(TRUE)
		return TRUE

/mob/living/simple_animal/wendigo/ObjBump(obj/O)
	if(istype(O, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/L = O
		if(L.density) // must check density here, to avoid rapid bumping of an airlock that is in the process of opening, instantly forcing it closed
			return try_open_airlock(L)
	if(istype(O, /obj/machinery/door/firedoor))
		var/obj/machinery/door/firedoor/F = O
		if(F.density && !F.welded)
			F.open()
			return 1
	. = ..()

//// невидимость в тени (-(-_-(-_(-_(-_-)_-)-_-)_-)_-)-)

/mob/living/simple_animal/wendigo/process(delta_time)
	var/turf/T = src.loc
	if(istype(T))
		var/light_amount = T.get_lumcount()

		if(light_amount < 0.3)
			//src.alpha = max(0, src.alpha - 55)
			animate(src, alpha = 0, time = 10)
		else
			//src.alpha = min(255, src.alpha + 55)
			animate(src, alpha = 255, time = 30)
