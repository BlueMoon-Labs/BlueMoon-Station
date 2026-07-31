#define LAVA_MOAT 1
#define LAVA_AROUND 2
#define FIRE_SPEW 3
#define FIRE_MOAT 4

/**
  * # Drakeling
  *
  * A small drake/dragon.
  * Has four attacks.
  * - Lava moat - Creates a moat of lava around themselves.
  * - Lava rivers - Creates lava rivers in all cardinal directions.
  * - Firespew - Spews fire in the direction they're facing.
  * - Fire moat - Spews fire in all directions.
  */

/mob/living/simple_animal/hostile/asteroid/elite/drakeling
	name = "Drakeling"
	desc = "A small but still fearsome dragon."
	icon = 'modular_sand/icons/mob/lavaland/lavaland_elites.dmi'
	icon_state = "ash_whelp"
	icon_living = "ash_whelp"
	icon_aggro = "ash_whelp"
	icon_dead = "ash_whelp_dead"
	icon_gib = "syndicate_gib"
	maxHealth = 800
	health = 800
	melee_damage_lower = 30
	melee_damage_upper = 30
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/magic/demon_attack1.ogg'
	speed = 1
	move_to_delay = 3
	mouse_opacity = MOUSE_OPACITY_ICON
	deathsound = 'sound/magic/WandODeath.ogg'
	deathmessage = "'s wings flail weakly until he settles down, dead"
	loot_drop = /obj/item/borg/upgrade/modkit/fire
	speak_emote = list("huffs")

	attack_action_types = list(/datum/action/innate/elite_attack/lavamoat,
								/datum/action/innate/elite_attack/lavaaround,
								/datum/action/innate/elite_attack/firespew,
								/datum/action/innate/elite_attack/firemoat)

/mob/living/simple_animal/hostile/asteroid/elite/drakeling/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/glory_kill, \
		messages_unarmed = list("отрывает рога маленького дрейка, после чего вонзает их в его рот!", "хватает дрейклинга за голову и отрывает её от тела голыми руками!"), \
		messages_crusher = list("разрубает голову дрейклинга своим крашером пополам, оставляя обе половины висеть на чудом целой шее!"), \
		messages_pka = list("несколько раз ударяет по челюсти дрейклинга прикладом своего протокинетического ускорителя, пока та не отломится, а затем для пущего эффекта стреляет ему в голову!", "хватает дрейклинга за шею, после чего отстреливает его голову при помощи своего протокинетического ускорителя!"), \
		messages_pka_bayonet = list("пинает дрейклинга на землю спиной, после чего вспарывает его брюхо ножом, пока беззащитный зверь кричит в агонии!"), \
		health_given = 50, \
		threshold = (maxHealth/10 * 0.625))

/datum/action/innate/elite_attack/lavamoat
	name = "Lava Moat"
	icon_icon = 'modular_sand/icons/mob/actions/actions_elites.dmi'
	button_icon_state = "lava_moat"
	chosen_message = "<span class='boldwarning'>You will attempt to create a lava moat around you.</span>"
	chosen_attack_num = LAVA_MOAT

/datum/action/innate/elite_attack/lavaaround
	name = "Lava Rivers"
	icon_icon = 'modular_sand/icons/mob/actions/actions_elites.dmi'
	button_icon_state = "lava_around"
	chosen_message = "<span class='boldwarning'>You will now create lava rivers at your cardinal directions.</span>"
	chosen_attack_num = LAVA_AROUND

/datum/action/innate/elite_attack/firespew
	name = "Fire Spew"
	icon_icon = 'modular_sand/icons/mob/actions/actions_elites.dmi'
	button_icon_state = "fire_spew"
	chosen_message = "<span class='boldwarning'>You will now spew fire at your target.</span>"
	chosen_attack_num = FIRE_SPEW

/datum/action/innate/elite_attack/firemoat
	name = "Fire Moat"
	icon_icon = 'modular_sand/icons/mob/actions/actions_elites.dmi'
	button_icon_state = "fire_moat"
	chosen_message = "<span class='boldwarning'>You will now spew fire at all cardinal directions.</span>"
	chosen_attack_num = FIRE_MOAT

/mob/living/simple_animal/hostile/asteroid/elite/drakeling/OpenFire()
	if(client)
		switch(chosen_attack)
			if(LAVA_MOAT)
				lava_moat(target)
			if(LAVA_AROUND)
				lava_around(target)
			if(FIRE_SPEW)
				fire_spew()
			if(FIRE_MOAT)
				fire_moat()
		return
	var/aiattack = rand(1,4)
	switch(aiattack)
		if(LAVA_MOAT)
			lava_moat(target)
		if(LAVA_AROUND)
			lava_around(target)
		if(FIRE_SPEW)
			fire_spew()
		if(FIRE_MOAT)
			fire_moat()

//Drakeling actions
/mob/living/simple_animal/hostile/asteroid/elite/drakeling/proc/lava_moat()
	if(QDELETED(src) || !isturf(loc))
		return FALSE
	ranged_cooldown = world.time + 25
	visible_message("<span class='boldwarning'>[src] spews lava around themselves! Get back!</span>")
	for(var/turf/T in oview(1, src))
		new /obj/effect/temp_visual/lava_warning/drakeling(T, 40)
	return TRUE

/mob/living/simple_animal/hostile/asteroid/elite/drakeling/proc/lava_around()
	if(QDELETED(src) || !isturf(loc))
		return FALSE
	ranged_cooldown = world.time + 50
	for(var/d in GLOB.cardinals)
		INVOKE_ASYNC(src, PROC_REF(lava_wall), d, 5)
	return TRUE

/mob/living/simple_animal/hostile/asteroid/elite/drakeling/proc/fire_spew()
	if(QDELETED(src) || !isturf(loc))
		return FALSE
	ranged_cooldown = world.time + 25
	visible_message("<span class='boldwarning'>[src] spews fire!</span>")
	playsound(src,'sound/magic/Fireball.ogg', 200, 1)
	sleep(5)
	if(QDELETED(src) || !isturf(loc))
		return FALSE
	return fire_wall(src.dir, 10)

/mob/living/simple_animal/hostile/asteroid/elite/drakeling/proc/fire_moat()
	if(QDELETED(src) || !isturf(loc))
		return FALSE
	ranged_cooldown = world.time + 100
	playsound(src,'sound/magic/Fireball.ogg', 200, 1)
	visible_message("<span class='boldwarning'>[src] violently puffs smoke!They're going to make a fire moat!</span>")
	sleep(5)
	if(QDELETED(src) || !isturf(loc))
		return FALSE
	for(var/d in GLOB.alldirs)
		INVOKE_ASYNC(src, PROC_REF(fire_wall), d, 10)
	return TRUE

// Drakeling helpers

/mob/living/simple_animal/hostile/asteroid/elite/drakeling/proc/fire_wall(dir, range)
	if(QDELETED(src) || !isturf(loc))
		return FALSE
	var/list/hitlist = list(src)
	var/turf/T = get_turf(src)
	for(var/i in 1 to range)
		if(QDELETED(src) || !T)
			return FALSE
		T.ensure_hotspot()
		T.hotspot_expose(700,50,1)
		for(var/mob/living/L in T.contents)
			if(L in hitlist || (L == src))
				break
			else
				hitlist += L
				L.adjustFireLoss(20)
				to_chat(L, "<span class='userdanger'>You're hit by [src]'s fire breath!</span>")
		T = get_step(T, dir)
		sleep(1)
	return TRUE

/mob/living/simple_animal/hostile/asteroid/elite/drakeling/proc/lava_wall(dir, range)
	if(QDELETED(src) || !isturf(loc))
		return FALSE
	var/turf/T = get_turf(src)
	for(var/i in 1 to range)
		if(QDELETED(src) || !T)
			return FALSE
		new /obj/effect/temp_visual/lava_warning/drakeling(T, 40)
		T = get_step(T, dir)
		sleep(2)
	return TRUE

/obj/effect/temp_visual/lava_warning/drakeling
	duration = 7
