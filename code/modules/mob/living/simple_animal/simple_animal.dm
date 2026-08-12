/mob/living/simple_animal
	name = "animal"
	icon = 'icons/mob/animal.dmi'
	health = 20
	maxHealth = 20
	gender = PLURAL //placeholder
	///How much blud it has for bloodsucking
	blood_volume = 550
	rad_flags = RAD_NO_CONTAMINATE
	hud_type = /datum/hud/living/simple_animal

	status_flags = CANPUSH

	var/icon_living = ""
	///icon when the animal is dead. Don't use animated icons for this.
	var/icon_dead = ""
	///We only try to show a gibbing animation if this exists.
	var/icon_gib = null

	var/list/speak = list()
	///Emotes while speaking IE: Ian [emote], [text] -- Ian barks, "WOOF!". Spoken text is generated from the speak variable.
	var/list/speak_emote = list()
	var/speak_chance = 0
	///Hearable emotes
	var/list/emote_hear = list()
	///Unlike speak_emote, the list of things in this variable only show by themselves with no spoken text. IE: Ian barks, Ian yaps.
	var/list/emote_see = list()

	var/turns_per_move = 1
	var/turns_since_move = 0
	///Use this to temporarely stop random movement or to if you write special movement code for animals.
	var/stop_automated_movement = 0
	///Does the mob wander around when idle?
	var/wander = 1
	///When set to 1 this stops the animal from moving when someone is pulling it.
	var/stop_automated_movement_when_pulled = 1

	///When someone interacts with the simple animal.
	///Help-intent verb in present continuous tense.
	var/response_help_continuous = "pokes"
	///Help-intent verb in present simple tense.
	var/response_help_simple = "poke"
	///Disarm-intent verb in present continuous tense.
	var/response_disarm_continuous = "shoves"
	///Disarm-intent verb in present simple tense.
	var/response_disarm_simple = "shove"
	///Harm-intent verb in present continuous tense.
	var/response_harm_continuous = "hits"
	///Harm-intent verb in present simple tense.
	var/response_harm_simple = "hit"
	var/harm_intent_damage = 3
	///Minimum force required to deal any damage.
	var/force_threshold = 0

	///Temperature effect.
	var/minbodytemp = 250
	var/maxbodytemp = 350

	/// List of weather immunity traits that are then added on Initialize(), see traits.dm.
	var/list/weather_immunities

	///Healable by medical stacks? Defaults to yes.
	var/healable = 1

	///Atmos effect - Yes, you can make creatures that require plasma or co2 to survive. N2O is a trace gas and handled separately, hence why it isn't here. It'd be hard to add it. Hard and me don't mix (Yes, yes make all the dick jokes you want with that.) - Errorage
	var/list/atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0) //Leaving something at 0 means it's off - has no maximum
	///This damage is taken when atmos doesn't fit all the requirements above.
	var/unsuitable_atmos_damage = 2
	///Cached because JPS asks this for many prospective turfs. Refresh explicitly
	///if code changes atmos_requirements at runtime.
	var/tmp/atmos_pathing_sensitive = FALSE
	///Whether any gas bound is active, independently of damage/pathing policy.
	var/tmp/has_atmos_requirements = FALSE
	///Сабтип с собственным handle_environment() обязан выставить TRUE, иначе
	///гейт environment_processing_immune может отключить его обработку среды.
	var/uses_custom_environment_handling = FALSE
	///Direct hot-path copies of atmos_requirements. The source list remains the
	///public configuration API; refresh_atmos_pathing_sensitivity() updates these.
	var/tmp/atmos_min_oxy = 0
	var/tmp/atmos_max_oxy = 0
	var/tmp/atmos_min_tox = 0
	var/tmp/atmos_max_tox = 0
	var/tmp/atmos_min_n2 = 0
	var/tmp/atmos_max_n2 = 0
	var/tmp/atmos_min_co2 = 0
	var/tmp/atmos_max_co2 = 0

	///LETTING SIMPLE ANIMALS ATTACK? WHAT COULD GO WRONG. Defaults to zero so Ian can still be cuddly.
	var/melee_damage_lower = 0
	var/melee_damage_upper = 0
	///How much damage this simple animal does to objects, if any.
	var/obj_damage = 0
	///How much armour they ignore, as a flat reduction from the targets armour value.
	var/armour_penetration = 0
	///Damage type of a simple mob's melee attack, should it do damage.
	var/melee_damage_type = BRUTE
	/// 1 for full damage , 0 for none , -1 for 1:1 heal from that source.
	var/list/damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
	///Attacking verb in present continuous tense.
	var/attack_verb_continuous = "attacks"
	///Attacking verb in present simple tense.
	var/attack_verb_simple = "attack"
	var/attack_sound = null
	///Attacking, but without damage, verb in present continuous tense.
	var/friendly_verb_continuous = "nuzzles"
	///Attacking, but without damage, verb in present simple tense.
	var/friendly_verb_simple = "nuzzle"
	///Set to 1 to allow breaking of crates,lockers,racks,tables; 2 for walls; 3 for Rwalls.
	var/environment_smash = ENVIRONMENT_SMASH_NONE

	///LETS SEE IF I CAN SET SPEEDS FOR SIMPLE MOBS WITHOUT DESTROYING EVERYTHING. Higher speed is slower, negative speed is faster.
	var/speed = 1

	///Hot simple_animal baby making vars.
	var/list/childtype = null
	COOLDOWN_DECLARE(childmaker)
	///Sorry, no spider+corgi buttbabies.
	var/animal_species

	///Innate access uses an internal ID card.
	var/obj/item/card/id/access_card = null
	///In the event that you want to have a buffing effect on the mob, but don't want it to stack with other effects, any outside force that applies a buff to a simple mob should at least set this to TRUE, so we have something to check against.
	var/buffed = FALSE
	///If the mob can be spawned with a gold slime core. HOSTILE_SPAWN are spawned with plasma, FRIENDLY_SPAWN are spawned with blood.
	var/gold_core_spawnable = NO_SPAWN

	var/datum/component/spawner/nest

	///Sentience type, for slime potions.
	var/sentience_type = SENTIENCE_ORGANIC

	///list of things spawned at mob's loc when it dies.
	var/list/loot = list()
	///causes mob to be deleted on death, useful for mobs that spawn lootable corpses.
	var/del_on_death = FALSE
	var/deathmessage = ""
	///The sound played on death.
	var/death_sound = null
	var/list/damaged_sound = null
	var/list/talk_sound = null //The sound played when talk

	var/allow_movement_on_non_turfs = FALSE

	///Played when someone punches the creature.
	var/attacked_sound = "punch"

	///If the creature has, and can use, hands.
	var/dextrous = FALSE
	var/dextrous_hud_type = /datum/hud/dextrous

	///The Status of our AI, can be set to AI_ON (On, usual processing), AI_IDLE (Will not process, but will return to AI_ON if an enemy comes near), AI_OFF (Off, Not processing ever), AI_Z_OFF (Temporarily off due to nonpresence of players).
	var/AIStatus = AI_ON
	///once we have become sentient, we can never go back.
	var/can_have_ai = TRUE

	///convenience var for forcibly waking up an idling AI on next check.
	var/shouldwakeup = FALSE

	///Domestication.
	var/tame = 0

	///I don't want to confuse this with client registered_z.
	var/my_z

	///What kind of footstep this mob should have. Null if it shouldn't have any.
	var/footstep_type

	//How much wounding power it has
	var/wound_bonus = 0
	//How much bare wounding power it has
	var/bare_wound_bonus = 2
	//If the attacks from this are sharp
	var/sharpness = SHARP_NONE
	//Generic flags
	var/simple_mob_flags = NONE

	var/mob/living/carbon/human/master_commander = null //holding var for determining who own/controls a sentient simple animal (for sentience potions).

	/// If TRUE, observers may click this mob to take control when it has no client and is alive.
	var/playable_by_ghost = FALSE
	/// Optional [tgui_alert] title when offering ghost control; defaults to capitalized [name].
	var/ghost_possess_title = null
	/// Optional question text; defaults to a generic possess prompt with [name].
	var/ghost_possess_question = null

/mob/living/simple_animal/Initialize(mapload)
	. = ..()
	refresh_atmos_pathing_sensitivity()
	GLOB.simple_animals[AIStatus] += src
	if(gender == PLURAL)
		gender = pick(MALE,FEMALE)
	if(!real_name)
		real_name = name
	if(!loc)
		stack_trace("Simple animal being instantiated in nullspace")
	update_simplemob_varspeed()
	if(dextrous)
		AddComponent(/datum/component/personal_crafting)
	if(footstep_type)
		AddComponent(/datum/component/footstep, footstep_type)
	for(var/trait in weather_immunities)
		ADD_TRAIT(src, trait, ROUNDSTART_TRAIT)

/mob/living/simple_animal/Destroy()
	// Выписываемся из ВСЕХ бакетов, а не только из GLOB.simple_animals[AIStatus]:
	// прямое присвоение AIStatus на живом мобе оставляет запись в старом бакете,
	// и `-= src` по текущему статусу её не находит - труп висит в списке навечно
	for(var/bucket_index in 1 to length(GLOB.simple_animals))
		var/list/bucket = GLOB.simple_animals[bucket_index]
		if(bucket_index == AIStatus)
			bucket -= src
		else if(src in bucket)
			bucket -= src
			log_world("## GC: [type] найден в бакете simple_animals\[[bucket_index]] при AIStatus=[AIStatus] - страндед-запись вычищена в Destroy()")
	if (LAZYLEN(SSnpcpool.currentrun))
		SSnpcpool.currentrun -= src

	if(nest)
		nest.spawned_mobs -= src
		nest = null

	if (AIStatus == AI_Z_OFF && islist(SSidlenpcpool.idle_mobs_by_zlevel))
		// Регистрация в idle_mobs_by_zlevel шла по турфу НА МОМЕНТ toggle_ai(AI_Z_OFF);
		// если моба с тех пор переместили между z (или он уже в nullspace), чистка по
		// текущему турфу промахнётся - поэтому выписываемся из всех z-списков
		for (var/i in 1 to SSidlenpcpool.idle_mobs_by_zlevel.len)
			var/list/idle_z_list = SSidlenpcpool.idle_mobs_by_zlevel[i]
			if(islist(idle_z_list))
				idle_z_list -= src

	return ..()

/mob/living/simple_animal/updatehealth()
	..()
	health = clamp(health, 0, maxHealth)

/mob/living/simple_animal/update_stat()
	if(status_flags & GODMODE)
		return
	if(stat != DEAD)
		if(health <= 0)
			death()
		else
			set_stat(CONSCIOUS)
	med_hud_set_status()
	..()

/mob/living/simple_animal/proc/handle_automated_action()
	set waitfor = FALSE
	return

/mob/living/simple_animal/proc/handle_automated_movement()
	set waitfor = FALSE
	if(!stop_automated_movement && wander)
		if((isturf(src.loc) || allow_movement_on_non_turfs) && CHECK_MULTIPLE_BITFIELDS(mobility_flags, MOBILITY_STAND|MOBILITY_MOVE) && !buckled)		//This is so it only moves if it's not inside a closet, gentics machine, etc.
			turns_since_move++
			if(turns_since_move >= turns_per_move)
				if(!(stop_automated_movement_when_pulled && pulledby)) //Some animals don't move when pulled
					var/anydir = pick(GLOB.cardinals)
					if(Process_Spacemove(anydir))
						Move(get_step(src, anydir), anydir)
						turns_since_move = 0
			return TRUE

/mob/living/simple_animal/proc/handle_automated_speech(var/override)
	set waitfor = FALSE
	if(speak_chance)
		if(prob(speak_chance) || override)
			//реплика в пустоту - чистый расход: say()/emote() без единого слушателя рядом
			if(!override && !has_nearby_player(9))
				return
			if(speak && speak.len)
				if((emote_hear && emote_hear.len) || (emote_see && emote_see.len))
					var/length = speak.len
					if(emote_hear && emote_hear.len)
						length += emote_hear.len
					if(emote_see && emote_see.len)
						length += emote_see.len
					var/randomValue = rand(1,length)
					if(randomValue <= speak.len)
						say(pick(speak), forced = "polly")
					else
						randomValue -= speak.len
						if(emote_see && randomValue <= emote_see.len)
							emote("me [pick(emote_see)]", 1)
						else
							emote("me [pick(emote_hear)]", 2)
				else
					say(pick(speak), forced = "polly")
			else
				if(!(emote_hear && emote_hear.len) && (emote_see && emote_see.len))
					emote("me", EMOTE_VISIBLE, pick(emote_see))
				if((emote_hear && emote_hear.len) && !(emote_see && emote_see.len))
					emote("me", EMOTE_AUDIBLE, pick(emote_hear))
				if((emote_hear && emote_hear.len) && (emote_see && emote_see.len))
					var/length = emote_hear.len + emote_see.len
					var/pick = rand(1,length)
					if(pick <= emote_see.len)
						emote("me", EMOTE_VISIBLE, pick(emote_see))
					else
						emote("me", EMOTE_AUDIBLE, pick(emote_hear))


/mob/living/simple_animal/proc/environment_is_safe(datum/gas_mixture/environment, check_temp = FALSE)
	//Keep the legacy no-argument call checking the mob's current open turf.
	//Callers which provide a mixture (notably pathfinding) get that exact
	//prospective atmosphere checked instead.
	if(!environment && isopenturf(loc))
		var/turf/open/current_turf = loc
		environment = current_turf.air
	. = (environment || isopenturf(loc)) ? atmosphere_is_safe(environment, check_temp) : TRUE
	if(pulledby && pulledby.grab_state >= GRAB_KILL && atmos_requirements["min_oxy"])
		return FALSE //getting choked

///Pure atmosphere check used both by Life() and by pathfinding. Previously the
///environment argument was ignored and src.loc.air was read instead, making it
///impossible to evaluate a prospective route without moving the mob there.
/mob/living/simple_animal/proc/atmosphere_is_safe(datum/gas_mixture/environment, check_temp = FALSE)
	if(!has_atmos_requirements && !check_temp)
		return TRUE
	if(!environment)
		if(atmos_min_oxy || atmos_min_tox || atmos_min_n2 || atmos_min_co2)
			return FALSE
		if(check_temp)
			var/null_environment_temp = get_temperature(environment)
			return null_environment_temp >= minbodytemp && null_environment_temp <= maxbodytemp
		return TRUE

	if(atmos_min_oxy || atmos_max_oxy)
		var/oxy = environment.get_moles(GAS_O2)
		if((atmos_min_oxy && oxy < atmos_min_oxy) || (atmos_max_oxy && oxy > atmos_max_oxy))
			return FALSE
	if(atmos_min_tox || atmos_max_tox)
		var/tox = environment.get_moles(GAS_PLASMA)
		if((atmos_min_tox && tox < atmos_min_tox) || (atmos_max_tox && tox > atmos_max_tox))
			return FALSE
	if(atmos_min_n2 || atmos_max_n2)
		var/n2 = environment.get_moles(GAS_N2)
		if((atmos_min_n2 && n2 < atmos_min_n2) || (atmos_max_n2 && n2 > atmos_max_n2))
			return FALSE
	if(atmos_min_co2 || atmos_max_co2)
		var/co2 = environment.get_moles(GAS_CO2)
		if((atmos_min_co2 && co2 < atmos_min_co2) || (atmos_max_co2 && co2 > atmos_max_co2))
			return FALSE
	if(check_temp)
		var/areatemp = get_temperature(environment)
		if(areatemp < minbodytemp || areatemp > maxbodytemp)
			return FALSE
	return TRUE

///Whether entering an open turf would immediately expose this mob to an
///atmosphere that damages it. Closed turfs are handled as obstacles elsewhere.
/mob/living/simple_animal/proc/requires_safe_atmosphere()
	return atmos_pathing_sensitive

/mob/living/simple_animal/proc/refresh_atmos_pathing_sensitivity()
	atmos_min_oxy = atmos_requirements["min_oxy"]
	atmos_max_oxy = atmos_requirements["max_oxy"]
	atmos_min_tox = atmos_requirements["min_tox"]
	atmos_max_tox = atmos_requirements["max_tox"]
	atmos_min_n2 = atmos_requirements["min_n2"]
	atmos_max_n2 = atmos_requirements["max_n2"]
	atmos_min_co2 = atmos_requirements["min_co2"]
	atmos_max_co2 = atmos_requirements["max_co2"]
	has_atmos_requirements = !!(atmos_min_oxy || atmos_max_oxy || atmos_min_tox || atmos_max_tox || atmos_min_n2 || atmos_max_n2 || atmos_min_co2 || atmos_max_co2)
	atmos_pathing_sensitive = unsuitable_atmos_damage && has_atmos_requirements
	//Среда не может ни навредить, ни остудить/согреть осмысленно - Life может
	//вообще не читать атмосферу такого моба (лавовая/космическая фауна).
	environment_processing_immune = !uses_custom_environment_handling && !has_atmos_requirements && minbodytemp <= 0 && maxbodytemp >= INFINITY

/mob/living/simple_animal/proc/can_safely_enter_turf(turf/candidate, environment_policy_prechecked = FALSE)
	if(!isopenturf(candidate) || (!environment_policy_prechecked && !requires_safe_atmosphere()))
		return TRUE
	return atmosphere_is_safe(candidate.return_air())

///Opening or destroying a pressure barrier affects more than its own turf.
///Refuse it when a connected open turf would damage the mob.
/mob/living/simple_animal/proc/can_safely_open_pressure_barrier(obj/barrier)
	if(!barrier)
		return FALSE
	if(!requires_safe_atmosphere())
		return TRUE
	var/turf/barrier_turf = get_turf(barrier)
	if(!can_safely_enter_turf(barrier_turf))
		return FALSE
	var/obj/structure/window/window = barrier
	if((istype(window) && !window.fulltile) || istype(barrier, /obj/machinery/door/window) || istype(barrier, /obj/machinery/door/firedoor/border_only))
		return can_safely_enter_turf(get_step(barrier, barrier.dir))
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(barrier, direction)
		if(neighbor && !can_safely_enter_turf(neighbor))
			return FALSE
	return TRUE


/mob/living/simple_animal/handle_environment(datum/gas_mixture/environment)
	var/atom/A = src.loc
	if(isturf(A))
		var/areatemp = get_temperature(environment)
		if( abs(areatemp - bodytemperature) > 5)
			var/diff = areatemp - bodytemperature
			diff = diff / 5
			adjust_bodytemperature(diff)

	if(!environment_is_safe(environment))
		adjustHealth(unsuitable_atmos_damage)
		// BLUEMOON ADD START - оповещения для игрока, чтобы ХП не пропадало "само по себе"
		if(client)
			if(!(world.time % 3))
				to_chat(client, span_userdanger("Здесь что-то не так с воздухом!"))
		// BLUEMOON ADD END

	handle_temperature_damage()

/mob/living/simple_animal/proc/handle_temperature_damage()
	if((bodytemperature < minbodytemp) || (bodytemperature > maxbodytemp))
		adjustHealth(unsuitable_atmos_damage)
		// BLUEMOON ADD START - оповещения для игрока, чтобы ХП не пропадало "само по себе"
		if(client)
			if(!(world.time % 3))
				if(bodytemperature < minbodytemp)
					to_chat(client, span_userdanger("Здесь слишком холодно!"))
				if(bodytemperature > maxbodytemp)
					to_chat(client, span_userdanger("Здесь слишком горячо!"))
		// BLUEMOON ADD END

/mob/living/simple_animal/gib(no_brain, no_organs, no_bodyparts, datum/explosion/was_explosion)
	if(butcher_results || guaranteed_butcher_results)
		var/list/butcher = list()
		if(butcher_results)
			butcher += butcher_results
		if(guaranteed_butcher_results)
			butcher += guaranteed_butcher_results
		var/atom/Tsec = drop_location()
		for(var/path in butcher)
			for(var/i in 1 to butcher[path])
				new path(Tsec)
	..()

/mob/living/simple_animal/gib_animation()
	if(icon_gib)
		new /obj/effect/temp_visual/gib_animation/animal(loc, icon_gib)

/mob/living/simple_animal/say_mod(input, message_mode)
	if(speak_emote && speak_emote.len)
		verb_say = pick(speak_emote)
	. = ..()

/mob/living/simple_animal/emote(act, m_type=1, message = null, intentional = FALSE, message_override = null)
	if(stat)
		return
	if(act == "scream")
		message = "makes a loud and pained whimper." //ugly hack to stop animals screaming when crushed :P
		act = "me"
	..(act, m_type, message, intentional, message_override)

/mob/living/simple_animal/proc/set_varspeed(var_value)
	speed = var_value
	update_simplemob_varspeed()

/mob/living/simple_animal/proc/update_simplemob_varspeed()
	if(speed == 0)
		remove_movespeed_modifier(/datum/movespeed_modifier/simplemob_varspeed)
	add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/simplemob_varspeed, multiplicative_slowdown = speed)

/mob/living/simple_animal/get_status_tab_items()
	. = ..()
	. += ""
	. += "Health: [round((health / maxHealth) * 100)]%"

/mob/living/simple_animal/proc/drop_loot()
	if(!length(loot))
		return
	for(var/loot_type in loot)
		if(!ispath(loot_type))
			continue
		new loot_type(loc)

/mob/living/simple_animal/death(gibbed)
	movement_type &= ~FLYING
	if(nest)
		nest.spawned_mobs -= src
		nest = null
	drop_loot()
	if(dextrous)
		drop_all_held_items()
	if(!gibbed)
		if(death_sound)
			playsound(get_turf(src),death_sound, 200, 1)
		if(deathmessage || !del_on_death)
			emote("deathgasp")
	if(del_on_death)
		..()
		//Prevent infinite loops if the mob Destroy() is overridden in such
		//a manner as to cause a call to death() again
		del_on_death = FALSE
		qdel(src)
	else
		health = 0
		icon_state = icon_dead
		density = FALSE
		lying = 1
		..()

/mob/living/simple_animal/proc/CanAttack(atom/the_target)
	if(see_invisible < the_target.invisibility)
		return FALSE
	if(ismob(the_target))
		var/mob/M = the_target
		if(M.status_flags & GODMODE)
			return FALSE
	if (isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat != CONSCIOUS)
			return FALSE
	if (ismecha(the_target))
		var/obj/vehicle/sealed/mecha/M = the_target
		if(LAZYLEN(M.occupants))
			return FALSE
	return TRUE

/mob/living/simple_animal/handle_fire()
	return

/mob/living/simple_animal/IgniteMob()
	return FALSE

/mob/living/simple_animal/ExtinguishMob()
	return

/mob/living/simple_animal/revive(full_heal = 0, admin_revive = 0, excess_healing = 0)
	if(..()) //successfully ressuscitated from death
		icon = initial(icon)
		icon_state = icon_living
		density = initial(density)
		lying = 0
		. = 1
		setMovetype(initial(movement_type))

/mob/living/simple_animal/proc/make_babies() // <3 <3 <3
	if(!COOLDOWN_FINISHED(src, childmaker))
		return
	if(gender != FEMALE || stat || !childtype || !animal_species || !SSticker.IsRoundInProgress())
		return
	COOLDOWN_START(src, childmaker, 40 SECONDS)
	var/mob/living/simple_animal/partner
	var/children = 0
	for(var/mob/M in view(7, src))
		if(M.stat != CONSCIOUS) //Check if it's conscious FIRST.
			continue
		else if(M.type in childtype) //Check for children SECOND.
			children++
		else if(istype(M, animal_species))
			if(M.ckey)
				continue
			else if(!istype(M, childtype) && M.gender == MALE) //Better safe than sorry ;_;
				partner = M

		else if(isliving(M) && !faction_check_mob(M)) //shyness check. we're not shy in front of things that share a faction with us.
			return //we never mate when not alone, so just abort early

	if(partner && children < 3)
		var/childspawn = pickweight(childtype)
		var/turf/target = get_turf(loc)
		if(target)
			return new childspawn(target)

/mob/living/simple_animal/canUseTopic(atom/movable/M, be_close=FALSE, no_dextery=FALSE, no_tk=FALSE, check_resting=FALSE, silent = FALSE)
	if(incapacitated())
		if(!silent)
			to_chat(src, "<span class='warning'>You can't do that right now!</span>")
		return FALSE
	if(be_close && !in_range(M, src))
		if(!silent)
			to_chat(src, "<span class='warning'>You are too far away!</span>")
		return FALSE
	if(!(no_dextery || dextrous))
		if(!silent)
			to_chat(src, "<span class='warning'>You don't have the dexterity to do this!</span>")
		return FALSE
	return TRUE

/mob/living/simple_animal/stripPanelUnequip(obj/item/what, mob/who, where)
	if(!canUseTopic(who, BE_CLOSE))
		return
	else
		..()

/mob/living/simple_animal/stripPanelEquip(obj/item/what, mob/who, where)
	if(!canUseTopic(who, BE_CLOSE))
		return
	else
		..()

/mob/living/simple_animal/update_mobility(value_otherwise = MOBILITY_FLAGS_DEFAULT)
	if(IsUnconscious() || IsStun() || IsParalyzed() || stat || resting)
		drop_all_held_items()
		mobility_flags = NONE
	else if(buckled)
		mobility_flags = ~MOBILITY_MOVE
	else
		mobility_flags = MOBILITY_FLAGS_DEFAULT
	if(!CHECK_MOBILITY(src, MOBILITY_MOVE)) // !(mobility_flags & MOBILITY_MOVE)
		walk(src, 0) //stop mid walk
	update_transform()
	update_action_buttons_icon()
	return mobility_flags

/mob/living/simple_animal/update_transform(do_animate)
	var/matrix/ntransform = matrix(transform) //aka transform.Copy()
	var/changed = 0

	if(resize != RESIZE_DEFAULT_SIZE)
		changed++
		ntransform.Scale(resize)
		ntransform.Translate(0, 16*(resize-1)) //Makes sure you stand on the tile no matter the size - sand
		resize = RESIZE_DEFAULT_SIZE

	if(changed)
		animate(src, transform = ntransform, time = 2, easing = EASE_IN|EASE_OUT)

/mob/living/simple_animal/proc/sentience_act() //Called when a simple animal gains sentience via gold slime potion
	toggle_ai(AI_OFF) // To prevent any weirdness.
	can_have_ai = FALSE

/mob/living/simple_animal/update_sight(forced = TRUE)
	if(!client)
		return
	if(stat == DEAD)
		sight = (SEE_TURFS|SEE_MOBS|SEE_OBJS)
		see_in_dark = 8
		see_invisible = SEE_INVISIBLE_OBSERVER
		return

	if(forced)
		see_invisible = initial(see_invisible)
		see_in_dark = initial(see_in_dark)
		sight = initial(sight)

	if(client.eye != src)
		var/atom/A = client.eye
		if(A.update_remote_sight(src)) //returns 1 if we override all other sight updates.
			return
	sync_lighting_plane_alpha()

/mob/living/simple_animal/get_idcard(hand_first = TRUE)
	return ..() || access_card

/mob/living/simple_animal/can_hold_items()
	return dextrous

/mob/living/simple_animal/IsAdvancedToolUser()
	return dextrous

/mob/living/simple_animal/activate_hand(selhand)
	if(!dextrous)
		return ..()
	if(!selhand)
		selhand = (active_hand_index % held_items.len)+1
	if(istext(selhand))
		selhand = lowertext(selhand)
		if(selhand == "right" || selhand == "r")
			selhand = 2
		if(selhand == "left" || selhand == "l")
			selhand = 1
	if(selhand != active_hand_index)
		swap_hand(selhand)
	else
		mode()

/mob/living/simple_animal/swap_hand(hand_index)
	. = ..()
	if(!.)
		return
	if(!dextrous)
		return
	if(!hand_index)
		hand_index = (active_hand_index % held_items.len)+1
	var/oindex = active_hand_index
	active_hand_index = hand_index
	if(hud_used)
		var/atom/movable/screen/inventory/hand/H
		H = hud_used.hand_slots["[hand_index]"]
		if(H)
			H.update_icon()
		H = hud_used.hand_slots["[oindex]"]
		if(H)
			H.update_icon()

/mob/living/simple_animal/put_in_hands(obj/item/I, del_on_fail = FALSE, merge_stacks = TRUE)
	. = ..(I, del_on_fail, merge_stacks)
	update_inv_hands()

/mob/living/simple_animal/update_inv_hands()
	if(client && hud_used && hud_used.hud_version != HUD_STYLE_NOHUD)
		var/obj/item/l_hand = get_item_for_held_index(1)
		var/obj/item/r_hand = get_item_for_held_index(2)
		if(r_hand)
			r_hand.layer = ABOVE_HUD_LAYER
			r_hand.plane = ABOVE_HUD_PLANE
			r_hand.screen_loc = ui_hand_position(get_held_index_of_item(r_hand))
			client.screen |= r_hand
		if(l_hand)
			l_hand.layer = ABOVE_HUD_LAYER
			l_hand.plane = ABOVE_HUD_PLANE
			l_hand.screen_loc = ui_hand_position(get_held_index_of_item(l_hand))
			client.screen |= l_hand

// Симпл мобы интеракты
/mob/living/simple_animal/proc/toggle_throw_mode()
	if(stat)
		return
	if(throw_mode)
		throw_mode_off()
	else
		throw_mode_on()

/mob/living/simple_animal/proc/throw_mode_off()
	throw_mode = FALSE
	if(client && hud_used && hud_used.throw_icon)
		hud_used.throw_icon.icon_state = "act_throw_off"

/mob/living/simple_animal/proc/throw_mode_on()
	throw_mode = TRUE
	if(client && hud_used && hud_used.throw_icon)
		hud_used.throw_icon.icon_state = "act_throw_on"

/mob/living/simple_animal/throw_item(atom/target)
	. = ..()
	throw_mode_off()
	update_mouse_pointer()
	if(!target || !isturf(loc))
		return FALSE
	if(istype(target, /atom/movable/screen))
		return FALSE
	var/obj/item/held_item = get_active_held_item()
	if(!held_item)
		return FALSE
	visible_message(span_danger("[src] throws [held_item]."))
	log_message("has thrown [held_item]", LOG_ATTACK)
	do_attack_animation(target, no_effect = 1)
	playsound(loc, 'sound/weapons/punchmiss.ogg', 50, 1, -1)
	newtonian_move(get_dir(target, src))
	held_item.safe_throw_at(target, held_item.throw_range, held_item.throw_speed, src)
	DelayNextAction(CLICK_CD_THROW)

//ANIMAL RIDING

/mob/living/simple_animal/user_buckle_mob(mob/living/M, mob/user, check_loc)
	var/datum/component/riding/riding_datum = GetComponent(/datum/component/riding)
	if(riding_datum)
		if(user.incapacitated())
			return
		for(var/atom/movable/A in get_turf(src))
			if(A != src && A != M && A.density)
				return
		M.forceMove(get_turf(src))
		return ..()

/mob/living/simple_animal/relaymove(mob/user, direction)
	var/datum/component/riding/riding_datum = GetComponent(/datum/component/riding)
	if(tame && riding_datum)
		riding_datum.handle_ride(user, direction)

/mob/living/simple_animal/buckle_mob(mob/living/buckled_mob, force = 0, check_loc = 1)
	. = ..()
	LoadComponent(/datum/component/riding)

/mob/living/simple_animal/proc/toggle_ai(togglestatus)
	// Отложенный toggle_ai по уже удалённому мобу (timestop, циклы мегафауны,
	// подвисшие в currentrun ссылки) заново кладёт его в бакет simple_animals,
	// откуда Destroy() его уже вынул - моб виснет там навечно (прод: слайм в warnfail)
	if(QDELING(src))
		return
	if(!can_have_ai && (togglestatus != AI_OFF))
		return
	//Контроллерный моб не возвращается в легаси-пулы, но старые вызовы
	//toggle_ai всё ещё обязаны реально останавливать/возобновлять его AI.
	if(ai_controller)
		switch(togglestatus)
			if(AI_OFF)
				ADD_TRAIT(src, TRAIT_AI_PAUSED, AI_PAUSED_LEGACY_TOGGLE)
				ai_controller.update_able_to_run()
			if(AI_Z_OFF)
				ai_controller.set_ai_status(AI_STATUS_OFF)
			if(AI_IDLE)
				REMOVE_TRAIT(src, TRAIT_AI_PAUSED, AI_PAUSED_LEGACY_TOGGLE)
				ai_controller.update_able_to_run()
				if(ai_controller.able_to_run)
					ai_controller.set_ai_status(AI_STATUS_IDLE)
			if(AI_ON)
				REMOVE_TRAIT(src, TRAIT_AI_PAUSED, AI_PAUSED_LEGACY_TOGGLE)
				ai_controller.update_able_to_run()
				if(ai_controller.able_to_run)
					ai_controller.set_ai_status(AI_STATUS_ON)
		return
	if (AIStatus != togglestatus)
		if (togglestatus > 0 && togglestatus < 5)
			if (togglestatus == AI_Z_OFF || AIStatus == AI_Z_OFF)
				var/turf/T = get_turf(src)
				if (AIStatus == AI_Z_OFF)
					SSidlenpcpool.idle_mobs_by_zlevel[T.z] -= src
				else
					SSidlenpcpool.idle_mobs_by_zlevel[T.z] += src
			GLOB.simple_animals[AIStatus] -= src
			GLOB.simple_animals[togglestatus] += src
			AIStatus = togglestatus
		else
			stack_trace("Something attempted to set simple animals AI to an invalid state: [togglestatus]")

///Вынуть моба из легаси-AI-бакетов насовсем: контроллерный моб планируется
///SSai_controllers и не должен числиться в GLOB.simple_animals вообще.
///Обратный путь - обычный toggle_ai(AI_ON) после смерти контроллера.
/mob/living/simple_animal/proc/unenroll_legacy_ai()
	if(QDELING(src))
		return
	if(AIStatus == AI_Z_OFF && islist(SSidlenpcpool.idle_mobs_by_zlevel))
		//регистрация шла по турфу на момент toggle_ai(AI_Z_OFF) - чистим все z-списки
		for(var/z_index in 1 to SSidlenpcpool.idle_mobs_by_zlevel.len)
			var/list/idle_z_list = SSidlenpcpool.idle_mobs_by_zlevel[z_index]
			if(islist(idle_z_list))
				idle_z_list -= src
	//свип по всем бакетам, как в Destroy: страндед-запись в чужом бакете не должна пережить миграцию
	for(var/bucket_index in 1 to length(GLOB.simple_animals))
		var/list/bucket = GLOB.simple_animals[bucket_index]
		bucket -= src
	if(LAZYLEN(SSnpcpool.currentrun))
		SSnpcpool.currentrun -= src
	AIStatus = AI_OFF

///Есть ли у моба живой AI хоть в каком-то состоянии: контроллер (даже спящий -
///его будят урон/обиды/грид) или легаси-статус, отличный от жёсткого AI_OFF.
///Единый гард вместо компаундов вида `(AIStatus != AI_OFF || ai_controller)`.
/mob/living/simple_animal/proc/has_active_ai()
	if(ai_controller)
		return !QDELETED(ai_controller)
	return AIStatus != AI_OFF

///Легаси-эквивалент статуса для старого сабтипового кода на ai_controller.
/mob/living/simple_animal/proc/get_effective_ai_status()
	if(!ai_controller)
		return AIStatus
	switch(ai_controller.ai_status)
		if(AI_STATUS_ON)
			return AI_ON
		if(AI_STATUS_IDLE)
			return AI_IDLE
	return AI_OFF

/// Returns TRUE if any player is within given distance on the same z-level.
/// Override: simple_animals use tighter NEARBY_PLAYER_DISTANCE (15) by default
/mob/living/simple_animal/has_nearby_player(distance = NEARBY_PLAYER_DISTANCE)
	return ..(distance)

/mob/living/simple_animal/proc/consider_wakeup()
	if (pulledby || shouldwakeup)
		toggle_ai(AI_ON)

/mob/living/simple_animal/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(!ckey && !stat && !ai_controller)//Not unconscious; контроллер будит себя сам
		if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
			toggle_ai(AI_ON)


/mob/living/simple_animal/onTransitZ(old_z, new_z)
	..()
	if (AIStatus == AI_Z_OFF)
		SSidlenpcpool.idle_mobs_by_zlevel[old_z] -= src
		toggle_ai(initial(AIStatus))

/mob/living/simple_animal/say(message, verb, sanitize, ignore_speech_problems, ignore_atmospherics, datum/language/language = null, ignore_spam = FALSE, forced = null, var/list/spans = list())
	. = ..()
	if(. && length(src.talk_sound))
		playsound(src, pick(src.talk_sound), 75, TRUE)

/mob/living/simple_animal/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	if(. && length(src.damaged_sound))
		playsound(src, pick(src.damaged_sound), 40, 1)

/mob/living/simple_animal/attack_hand(mob/living/carbon/human/M)
	. = ..()
	if(. && length(src.damaged_sound))
		playsound(src, pick(src.damaged_sound), 40, 1)

/mob/living/simple_animal/attack_animal(mob/living/simple_animal/M)
	. = ..()
	if(. && length(src.damaged_sound))
		playsound(src, pick(src.damaged_sound), 40, 1)

/mob/living/simple_animal/attack_alien(mob/living/carbon/alien/humanoid/M)
	. = ..()
	if(. && length(src.damaged_sound))
		playsound(src, pick(src.damaged_sound), 40, 1)

/mob/living/simple_animal/attack_larva(mob/living/carbon/alien/larva/L)
	. = ..()
	if(. && length(src.damaged_sound))
		playsound(src, pick(src.damaged_sound), 40, 1)

/mob/living/simple_animal/attack_slime(mob/living/simple_animal/slime/M)
	. = ..()
	if(. && length(src.damaged_sound))
		playsound(src, pick(src.damaged_sound), 40, 1)

/mob/living/simple_animal/attack_robot(mob/living/user)
	. = ..()
	if(. && length(src.damaged_sound))
		playsound(src, pick(src.damaged_sound), 40, 1)

/mob/living/simple_animal/attack_ghost(mob/user)
	. = ..()
	if(.)
		return
	if(!playable_by_ghost)
		return
	ghost_possess_animal(user)

/// Lets a ghost take this mob if it is still free (same idea as gondola / venus trap).
/mob/living/simple_animal/proc/ghost_possess_animal(mob/user)
	if(key || stat || QDELETED(src) || !playable_by_ghost)
		return
	if(isobserver(user))
		var/mob/dead/observer/O = user
		if(!O.can_reenter_round())
			to_chat(user, span_warning("Вы не можете войти в эту роль."))
			return
	var/title = ghost_possess_title || capitalize(name)
	var/question = ghost_possess_question || "Вселиться в [name]?"
	var/ghost_ask = tgui_alert(user, question, title, list("Да", "Нет"))
	if(ghost_ask != "Да" || QDELETED(src))
		return
	if(key || stat)
		to_chat(user, span_warning("Кто-то уже занял это существо!"))
		return
	user.transfer_ckey(src, FALSE)
	grant_all_languages(UNDERSTOOD_LANGUAGE, grant_omnitongue = FALSE, source = LANGUAGE_ATOM)
	sentience_act()
	to_chat(src, span_notice("Вы вселились в [name]. Вы понимаете речь и можете общаться."))
	log_game("[key_name(src)] took control of [name] ([type]).")

/mob/living/simple_animal/examine(mob/user)
	var/list/dat = ..()
	if(stat == DEAD)
		dat += "<span class='deadsay'>[p_they_ru(TRUE)] не подаёт признаков жизни.</span>"
	else if(getBruteLoss() && !isbot(src))
		if(health < (maxHealth * 0.15))
			dat += span_warning("[p_they_ru(TRUE)] серьёзно изувечен[ru_a()].")
		else if(health < (maxHealth * 0.5))
			dat += span_warning("[p_they_ru(TRUE)] изувечен[ru_a()].")
		else if(health < (maxHealth * 0.85))
			dat += span_warning("[p_they_ru(TRUE)] ранен[ru_a()].")
		else
			dat += span_warning("[p_they_ru(TRUE)] в царапинах.")
	return dat
