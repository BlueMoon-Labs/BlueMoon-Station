
/mob/living/simple_animal/hostile/boss/benrey
	var/list/alert_sounds
	var/alert_cooldown = 3 SECONDS
	var/alert_cooldown_time


/mob/living/simple_animal/hostile/boss/benrey/Aggro()
	if(alert_sounds)
		if(!(world.time <= alert_cooldown_time))
			playsound(src, pick(alert_sounds), 70)
			alert_cooldown_time = world.time + alert_cooldown


//F E E L M Y P A S S P O R T
/mob/living/simple_animal/hostile/boss/benrey
	name = "Benrey"
	desc = "WHAT THE ACTUAL HELL"
	icon = 'modular_bluemoon/icons/mob/mesa_mobs.dmi'
	icon_state = "security_guard_melee"
	icon_living = "security_guard_melee"
	icon_dead = "security_guard_dead"
	icon_gib = "syndicate_gib"
	mob_biotypes = MOB_HUMANOID
	boss_abilities = list(/datum/action/boss/benrey_summon_sketelons)
	faction = list("hostile","xen")
	del_on_death = TRUE
	ranged = 1
	rapid = 3
	environment_smash = ENVIRONMENT_SMASH_NONE
	minimum_distance = 2
	retreat_distance = 2
	obj_damage = 60
	melee_damage_lower = 30
	melee_damage_upper = 40
	health = 6000
	maxHealth = 6000
	loot = list(/obj/effect/temp_visual/benrey_death,/obj/item/stack/spacecash/c100000,/obj/item/uber_teleporter,/obj/item/reagent_containers/hypospray/medipen/tuberculosiscure )
	projectiletype = /obj/item/projectile/bullet/shotgun_meteorslug/benrey
	projectilesound = 'sound/weapons/flashbang.ogg'
	attack_sound = 'sound/magic/blink.ogg'
	var/list/copies = list()
	footstep_type = FOOTSTEP_MOB_SHOE
	alert_sounds = list('modular_bluemoon/sound/creatures/mesa/benrey/benreylaugh.ogg','modular_bluemoon/sound/creatures/mesa/benrey/youdie.ogg')


/datum/action/boss/benrey_summon_sketelons
	name = "Summon skeletons"
	icon_icon = 'icons/mob/actions/actions_minor_antag.dmi'
	button_icon_state = "ninja_cloak"
	usage_probability = 10
	boss_cost = 20
	boss_type = /mob/living/simple_animal/hostile/boss/benrey
	needs_target = FALSE
	req_statuses = list(AI_ON)
	say_when_triggered = "F E E L M Y P A S S P O R T"
	var/list/summoned_minions = list()
	var/maximum_skeleton = 6
	var/skeleton_to_summon = 3

/datum/action/boss/benrey_summon_sketelons/Trigger()
	. =..()
	if(!.)
		return
	var/to_summon = skeleton_to_summon
	var/current_len = length(summoned_minions)
	if(current_len > maximum_skeleton - skeleton_to_summon)
		for(var/a in (maximum_skeleton - skeleton_to_summon) to current_len)
			var/mob/living/simple_animal/hostile/skeleton/benrey/S = popleft(summoned_minions)
			if(!S.client)
				qdel(S)
			else
				S.forceMove(boss.drop_location())
				S.revive(TRUE)
				summoned_minions += S
				to_summon--

	var/static/list/minions = list(
	/mob/living/simple_animal/hostile/skeleton/benrey,
	/mob/living/simple_animal/hostile/skeleton/benrey/meteor,
	/mob/living/simple_animal/hostile/skeleton/benrey/leaper)

	var/list/directions = GLOB.cardinals.Copy()
	for(var/i in 1 to to_summon)
		var/minions_chosen = pick(minions)
		var/mob/living/simple_animal/hostile/skeleton/benrey/S = new minions_chosen (get_step(boss,pick_n_take(directions)), 1)
		S.faction = boss.faction
		RegisterSignal(S, COMSIG_PARENT_QDELETING, PROC_REF(remove_from_list))
		summoned_minions += S

/datum/action/boss/benrey_summon_sketelons/proc/remove_from_list(datum/source, forced)
	summoned_minions -= source

//fancy effects
/obj/effect/temp_visual/benrey_scatter
	name = "scattering paper"
	desc = "Black mesa sweet voice starts to explode."
	layer = ABOVE_OPEN_TURF_LAYER
	icon = 'icons/effects/effects.dmi'
	icon_state = "explosion"
	anchored = TRUE
	duration = 5
	randomdir = FALSE

/obj/effect/temp_visual/benrey_death
	name = "craft portal"
	desc = "A big anomalious explosion kills this monster. Forewer"
	layer = ABOVE_OPEN_TURF_LAYER
	icon = 'icons/effects/effects.dmi'
	icon_state = "explosionOLD"
	anchored = TRUE
	duration = 18
	randomdir = FALSE

/obj/effect/temp_visual/benrey_death/Initialize(mapload)
	. = ..()
	visible_message("<span class='boldannounce'>Benrey finally explodes and starts to decays in air!</span>")
	playsound(get_turf(src),'sound/magic/mandswap.ogg', 50, 1, 1)
	playsound(get_turf(src),'sound/weapons/flashbang.ogg', 50, 1, 1)

/obj/effect/temp_visual/benrey_death/Destroy()
	for(var/mob/M in range(7,src))
		shake_camera(M, 7, 1)
	var/turf/T = get_turf(src)
	playsound(T,'sound/magic/summon_magic.ogg', 50, 1, 1)
	new /obj/effect/temp_visual/benrey_scatter(T)
	new /obj/item/clothing/suit/wizrobe/paper(T)
	new /obj/item/clothing/head/collectable/paper(T)
	return ..()



/mob/living/simple_animal/hostile/skeleton/benrey
	name = "black mesa skeleton"
	desc = "BLACK MESA SWEET VOICE IS STUNNED ME!"
	turns_per_move = 5
	maxHealth = 50
	blood_volume = 0
	health = 50
	maxHealth = 50
	minimum_distance = 2
	retreat_distance = 2
	speed = 1
	color = "#2531db"
	ranged = 1
	harm_intent_damage = 3
	loot = list(/obj/item/organ/regenerative_core/legion)
	melee_damage_lower = 8
	melee_damage_upper = 15
	attack_verb_continuous = "SWEET VOICES"
	attack_verb_simple = "SWEET VOICE"
	deathmessage = "Slowly decays into ashes"
	projectilesound = 'modular_bluemoon/sound/weapons/mesa/sweetvoice.ogg'
	projectiletype = /obj/item/projectile/bullet/shotgun_meteorslug/skeleton

/mob/living/simple_animal/hostile/skeleton/benrey/meteor
	color = "#1e6940"
	health = 20
	maxHealth = 20
	harm_intent_damage = 10
	melee_damage_lower = 12
	melee_damage_upper = 17
	projectiletype = /obj/item/projectile/bullet/shotgun_meteorslug/benrey

/mob/living/simple_animal/hostile/skeleton/benrey/leaper
	color = "#be1c1c"
	projectiletype = /obj/item/projectile/leaper



/obj/item/projectile/bullet/shotgun_meteorslug/benrey
	name = "deadly mesa sweet voice"
	icon = 'icons/effects/effects.dmi'
	icon_state = "chronofield"
	knockdown = 40

/obj/item/projectile/bullet/shotgun_meteorslug/skeleton
	knockdown = 0
	icon = 'icons/effects/effects.dmi'
	icon_state = "impact_laser_blue"

// Sweetvoice hand item for emote - works like kiss emote
/obj/item/hand_item/sweetvoice_blower
	name = "sweet voice"
	desc = "SWEET VOICE is ready to be deployed."
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "red_laser"
	var/list/intent_colors = list(
		"help" = "#00ff00",   // Зеленый для помощи
		"disarm" = "#ffff00", // Желтый для разоружения
		"grab" = "#00ffff",   // Голубой для захвата
		"harm" = "#ff0000"    // Красный для вреда
	)
	var/list/intent_pitches = list(
		"help" = 1.2,    // Высокий тон для помощи
		"disarm" = 1.0,  // Нормальный тон для разоружения
		"grab" = 0.9,    // Низкий тон для захвата
		"harm" = 0.8     // Самый низкий тон для вреда
	)

/obj/item/hand_item/sweetvoice_blower/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/two_handed, require_twohands=TRUE)

/obj/item/hand_item/sweetvoice_blower/can_give()
	return FALSE

/obj/item/hand_item/sweetvoice_blower/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()

	if(!isliving(user))
		return

	var/mob/living/L = user
	var/user_intent = L.a_intent
	var/projectile_color = intent_colors[user_intent] || "#ffffff"
	var/sound_pitch = intent_pitches[user_intent] || 1.0

	// Проигрываем звук с нужным тоном
	playsound(user.loc, 'modular_bluemoon/sound/weapons/mesa/sweetvoice.ogg', 50, sound_pitch, 3)

	var/obj/item/projectile/sweetvoice/blown_voice = new(get_turf(user))
	blown_voice.color = projectile_color
	user.visible_message("<b>[user]</b> издаёт сладкий голос в сторону [target]!", span_notice("Вы издаёте сладкий голос в сторону [target]!"))

	//Shooting Code:
	blown_voice.original = target
	blown_voice.fired_from = user
	blown_voice.pixels_per_second = TILES_TO_PIXELS(7) // Speed of sweet voice
	blown_voice.firer = user // don't hit ourself that would be really annoying
	blown_voice.impacted = list(user = TRUE) // just to make sure we don't hit the wearer
	blown_voice.preparePixelProjectile(target, user)
	blown_voice.fire()
	qdel(src)

// Sweetvoice projectile for emote - harmless fun projectile
/obj/item/projectile/sweetvoice
	name = "sweet voice"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "red_laser" // Using laser pointer dot icon
	damage = 0
	nodamage = TRUE
	knockdown = 0
	stamina = 0
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE
	projectile_phasing = PASSTABLE | PASSGLASS | PASSGRILLE
	range = 7
	color = "#ffffff" // Dynamic color set by emote

/obj/item/projectile/sweetvoice/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!target)
		return

	// Only affect living mobs
	if(isliving(target))
		var/mob/living/L = target
		if(L == firer)
			return // Don't affect the firer

		// Add soft light effect
		L.set_light(2, 1, color)
		addtimer(CALLBACK(L, TYPE_PROC_REF(/atom, set_light), 0), 1 SECONDS)
