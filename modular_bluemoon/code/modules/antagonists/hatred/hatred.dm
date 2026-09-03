/**
 * Данный антаг был вдоховлен игрою "Hatred" (2015).
 */

//////////////////////////////////////////////
//                                          //
//            	 ANTAG BASE		            //
//                                          //
//////////////////////////////////////////////


/**
 * 		TODO NOW
 *
 * 		TODO LATER
 * ?новое оружие - super shotgun двустволка  /obj/item/gun/ballistic/revolver/doublebarrel/super
 * ?hazard immune high gear
 * жига?
 * кс-23? - надо дрочить, шанс гибнуть голову (проебать исцеление), всего 4 патрона (исправимо), реально хорош против брони - мемно и перспективно
 * ?/obj/item/gun/ballistic/shotgun/automatic/dual_tube
 *
 */

#define HATRED_ANTAG "hatred"


/datum/antagonist/hatred
	name = "Mass Shooter"
	antagpanel_category = "Mass Shooter"
	roundend_category = "Mass shooter"
	job_rank = ROLE_MASS_SHOOTER
	// antag_moodlet = /datum/mood_event/focused
	show_to_ghosts = TRUE
	show_in_antagpanel = FALSE // только для призраков
	// antag_hud_type = ANTAG_HUD_WIZ
	// antag_hud_name = "wizard"
	ui_name = "AntagInfoHatred"
	threat = 10
	can_coexist_with_others = FALSE
	// reminded_times_left = 1
	var/list/allowed_z_levels = list()
	/**
	 * Level of available gear is determined by a number of alive security officers and other conditions.
	 * 0 = low guns NOT IMPLEMENTED YET!
	 * 1 = default classic and serious guns
	 * 2 = high gear
	 */
	var/gear_level = 1
	var/list/classic_guns = list("AK47", "Combat Shotgun", "Pistols")
	// there won't be special level 2 guns, because I don't want antag to have cheat guns. Level 2 gear is always better stats/traits for level 1 gear.
	var/list/high_gear = list(/*"Belt of Hatred", */"More armor", "Faster executions")
	var/chosen_gun = null
	var/chosen_high_gear = null
	COOLDOWN_DECLARE(killing_speech_cd)
	var/list/killing_speech = list(	'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_1.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_2.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_3.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_4.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_5.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_6.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_7.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_8.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_9.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_10.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_11.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_12.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_13.ogg',
									'modular_bluemoon/code/modules/antagonists/hatred/killing_speech/hatred_speech_14.ogg'
									)

/datum/antagonist/hatred/proc/forge_objectives()
	var/datum/objective/O = new /datum/objective/genocide()
	O.owner = owner
	objectives += O
	O = new /datum/objective/martyr()
	O.owner = owner
	objectives += O

/datum/objective/genocide
	name = "Genocide of civilians"
	explanation_text = "Убей столько народу, сколько успеешь за свою короткую оставшуюся жизнь. Не щади никого. Кровь слабых питает тебя."
	martyr_compatible = TRUE
	completed = TRUE // i have no idea how to count all your personal kills.
	var/glory_kills = 0

/datum/antagonist/hatred/roundend_report()
	. = ..()
	var/datum/objective/genocide/objective = locate() in objectives
	if(istype(objective))
		. += "<br><b>[objective.glory_kills]</b> ничтожных существ(а) было брутально и безжалостно добито массшутером."

/datum/antagonist/hatred/greet()
	var/greet_text
	greet_text += "Ты - [span_red(span_bold("Безымянный Массшутер"))]. Твое имя совершенно неважно. Твое прошлое даже если и было, оно было незавидным.<br>"
	greet_text += "Ты испытываешь непреодолимую ненависть, отвращение и презрение ко всем окружающим.<br>"
	greet_text += "У тебя лишь две цели: <u>убивать</u> и <u>умереть славной смертью</u>.<br>"
	greet_text += "<br>[span_red(span_bold("Не торопись и познакомься со своими инструментами геноцида. В бою у тебя не будет такой \
					возможности. Соберись с мыслями и отправляйся на станцию когда будешь готов."))]<br><br>"
	greet_text += "Твое проклятое снаряжение неразлучно с тобою и подстегивает тебя продолжать соврешать геноцид беззащитных гражданских.<br>"
	greet_text += "Твоё [span_red("Оружие Ненависти")] и неутолимая жажда убивать вознаграждают тебя, ибо завершающий выстрел в упор в голову (рот) исцеляет твои раны и дает прилив сил, нож добивает быстрее и надежнее.<br>"
	greet_text += span_red("Обычная медицина не лечит раны и ожоги!<br>")
	if(chosen_gun == "Pistols")
		greet_text += "[span_red("Стрелять с двух рук - HARM INTENT")].<br>"
	if(chosen_gun == "Combat Shotgun")
		greet_text += "Акимбо: Ты можешь стрелять из оружия одной рукой, даже если вторая занята, но забудь про автоматическую стрельбу. С твоим дробовиком это только бонус.<br>"
		greet_text += "На твоем поясе висит [span_red("запасная двустволка")] для быстрой стрельбы другим типом боеприпасов. Заряжена выбивающими двери и окна патронами..<br>"
	greet_text += "[span_red(span_bold("Время убивать. Время умирать."))] И пусть ни одна мразь не доживёт до завтра. Ибо никто сегодня не защищен от твоей Ненависти.<br>"
	to_chat(owner.current, greet_text)
	antag_memory = greet_text
	owner.announce_objectives()

/datum/antagonist/hatred/ui_static_data(mob/user)
	. = ..()
	if(!islist(.))
		return
	.["antag_name"] = name
	.["objectives"] = get_objectives()
	.["shotgun"] = (chosen_gun == "Combat Shotgun")
	.["pistols"] = (chosen_gun == "Pistols")

/datum/antagonist/hatred/on_gain()
	var/mob/living/carbon/human/H = owner.current
	if(!istype(H))
		return
	make_authentic_body()
	evaluate_security()
	forge_objectives()
	RegisterSignal(H, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(prevent_spawnloc_movement))
	RegisterSignal(H, COMSIG_MOB_EQUIPPED_ITEM, PROC_REF(check_equipped_item)) // any knife we pick might be our deadliest weapon. also sets nodrop trait onto some weapons
	RegisterSignal(H, COMSIG_LIVING_BIOLOGICAL_LIFE, PROC_REF(recover_from_softcrit))
	H.equipOutfit(/datum/outfit/hatred)
	if(QDELETED(H)) // админы сказали "нет"
		return
	. = ..()
	H.add_movespeed_modifier(/datum/movespeed_modifier/hatred)
	// Unpredictable mood changes makes it diffcult to balance antag's speed.
	H.add_movespeed_mod_immunities(HATRED_ANTAG, list(/datum/movespeed_modifier/damage_slowdown, /datum/movespeed_modifier/damage_slowdown_flying))
	H.add_movespeed_mod_immunities(HATRED_ANTAG, MOVESPEED_ID_SANITY)
	for(var/ms in typesof(/datum/movespeed_modifier/sanity))
		H.add_movespeed_mod_immunities(HATRED_ANTAG, ms)
	// just to be sure
	var/datum/component/mood/mood = H.GetComponent(/datum/component/mood)
	mood?.RemoveComponent()
	// сверхскорость и неуловимость страшнее сверхброни и бесконечных патронов
	for(var/ms as anything in typesof(/datum/movespeed_modifier/reagent))
		if(initial(ms:multiplicative_slowdown) < 0)
			H.add_movespeed_mod_immunities(HATRED_ANTAG, ms)
	H.add_movespeed_mod_immunities(HATRED_ANTAG, /datum/movespeed_modifier/grab_slowdown/aggressive)
	H.add_movespeed_mod_immunities(HATRED_ANTAG, MOVESPEED_ID_MOB_GRAB_STATE)
	H.drag_slowdown = FALSE
	// SPECIAL TRAITS
	ADD_TRAIT(H, TRAIT_SLEEPIMMUNE, HATRED_ANTAG) // I challenge you to a glorious fight!
	ADD_TRAIT(H, TRAIT_VIRUSIMMUNE, HATRED_ANTAG)
	ADD_TRAIT(H, TRAIT_NONATURALHEAL, HATRED_ANTAG)
	ADD_TRAIT(H, TRAIT_IGNOREDAMAGESLOWDOWN, HATRED_ANTAG)
	ADD_TRAIT(H, TRAIT_FEARLESS, HATRED_ANTAG)
	ADD_TRAIT(H, TRAIT_STRONG_GRABBER, HATRED_ANTAG) // This way player will have less problems with his targets run/crawl away during glory kills
	ADD_TRAIT(H, TRAIT_QUICKER_CARRY, HATRED_ANTAG)
	ADD_TRAIT(H, TRAIT_NODISMEMBER, HATRED_ANTAG) // if a player loses his arm, he won't be able to shoot nor drop his gun. it would be unplayable.
	ADD_TRAIT(H, TRAIT_FAST_PUMP, HATRED_ANTAG)
	ADD_TRAIT(H, TRAIT_NOCLONE, HATRED_ANTAG)
	ADD_TRAIT(H, TRAIT_TRUE_NIGHT_VISION, HATRED_ANTAG)
	H.mind.unconvertable = TRUE
	H.status_flags &= ~CANKNOCKDOWN // пкм батоном = автовин сб
	//EMP_PROTECT_CONTENTS
	// ADD_TRAIT(H, TRAIT_DRINKS_BLOOD, HATRED_ANTAG) // why not
	// ADD_TRAIT(H, TRAIT_NOSOFTCRIT, HATRED_ANTAG)
	// ADD_TRAIT(H, TRAIT_STUNIMMUNE, HATRED_ANTAG) // Doesn't work against stunbatons anyway :(
	//  GENERAL QUIRKS
	// H.add_quirk(/datum/quirk/night_vision, FALSE)
	H.add_quirk(/datum/quirk/tough, FALSE)
	H.add_quirk(/datum/quirk/freerunning, FALSE)
	H.add_quirk(/datum/quirk/monochromatic, FALSE)
	H.add_quirk(/datum/quirk/high_pain_threshold, FALSE)
	// H.add_quirk(/datum/quirk/jumper, announce = FALSE) // ADD_TRAIT(H, TRAIT_JUMPER, HATRED_ANTAG)
	// ADD_TRAIT(H, TRAIT_EVIL, HATRED_ANTAG) // H.add_quirk(/datum/quirk/evil, announce = FALSE) // no unwanted post_add() text
	allowed_z_levels += SSmapping.levels_by_trait(ZTRAIT_CENTCOM)
	allowed_z_levels += SSmapping.levels_by_trait(ZTRAIT_RESERVED)
	allowed_z_levels += SSmapping.levels_by_trait(ZTRAIT_STATION)
	RegisterSignal(H, COMSIG_MOB_DEATH, PROC_REF(on_hatred_death))
	RegisterSignal(H, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(check_hatred_off_station)) // almost like anchor implant, but doesn't hurt
	var/datum/action/hatred_deploy/D = new
	D.Grant(H)

/datum/action/hatred_deploy
	name = "Отправиться на станцию"
	desc = "Пришло время геноцида..."
	icon_icon = 'modular_bluemoon/icons/mob/actions/deploy.dmi'
	button_icon_state = "deploy"
	check_flags = NONE
	required_mobility_flags = NONE

/datum/action/hatred_deploy/Trigger()
	. = ..()
	if(!. || QDELETED(src) || QDELETED(owner) || !ishuman(owner) || owner != usr)
		return FALSE
	var/mob/living/carbon/human/H = owner
	var/datum/antagonist/hatred/Ha = H.mind?.has_antag_datum(/datum/antagonist/hatred)
	if(!Ha)
		return FALSE
	// WE ARE READY.
	H.fully_heal(TRUE) // in case of some accidents in spawn room during preparation
	Ha.UnregisterSignal(H, COMSIG_MOVABLE_PRE_MOVE)
	Ha.appear_on_station()
	var/picked_sound = pick('modular_bluemoon/code/modules/antagonists/hatred/hatred_begin_1.ogg', \
							'modular_bluemoon/code/modules/antagonists/hatred/hatred_begin_2.ogg', \
							'modular_bluemoon/code/modules/antagonists/hatred/hatred_begin_3.ogg')
	// Нужна микрозадержка после телепорта, т.к. есть траблы со звуком.
	// soundin, vol = 100, vary = FALSE, extrarange, falloff_exponent, frequency, channel, pressure_affected = FALSE, ignore_walls = FALSE
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), H, picked_sound, 100, FALSE, , , , , FALSE, FALSE), 5, TIMER_STOPPABLE|TIMER_DELETE_ME)
	/*
	playsound(H, pick('modular_bluemoon/code/modules/antagonists/hatred/hatred_begin_1.ogg', \
					'modular_bluemoon/code/modules/antagonists/hatred/hatred_begin_2.ogg', \
					'modular_bluemoon/code/modules/antagonists/hatred/hatred_begin_3.ogg'), vol = 100, vary = FALSE, ignore_walls = FALSE)
	*/
	addtimer(CALLBACK(Ha, TYPE_PROC_REF(/datum/antagonist/hatred, alarm_station)), 8 SECONDS, TIMER_STOPPABLE|TIMER_DELETE_ME) // Give a player a moment to understand what's going on.
	INVOKE_ASYNC(src, PROC_REF(Remove), H)

/datum/action/hatred_deploy/Remove(mob/remove_from)
	. = ..()
	if(!QDELETED(src))
		qdel(src)

/datum/antagonist/hatred/on_removal()
	var/mob/living/L = owner.current
	if(istype(L))
		UnregisterSignal(L, COMSIG_MOVABLE_Z_CHANGED)
		UnregisterSignal(L, COMSIG_MOB_EQUIPPED_ITEM)
		UnregisterSignal(L, COMSIG_MOB_DEATH)
		UnregisterSignal(L, COMSIG_MOVABLE_PRE_MOVE)
		UnregisterSignal(L, COMSIG_LIVING_BIOLOGICAL_LIFE)
		// UnregisterSignal(L, COMSIG_MOB_TRYING_TO_FIRE_GUN) can_trigger_gun
	. = ..()
	if(istype(L) && !QDELETED(L))
		to_chat(L, span_userdanger("Ненависть покидает твой разум, окончательно поглощая тебя всего..."))
		L.dust(FALSE, FALSE, TRUE) // from ghosts we come, to ghosts we leave.
		// deathgasp doesn't appear during dust() so implant doesn't go boom.

/// Железно запрещаем перемещение по стартовой локации ерроров
/datum/antagonist/hatred/proc/prevent_spawnloc_movement()
	SIGNAL_HANDLER
	return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

/datum/antagonist/hatred/proc/on_hatred_death()
	SIGNAL_HANDLER
	var/obj/item/clothing/suit/jacket/leather/overcoat/hatred/h = new(get_turf(owner.current))
	h.desc = "The blood stained shabby leather overcoat with decent armor paddings and special lightweight kevlar."
	addtimer(CALLBACK(h, TYPE_PROC_REF(/obj/item/clothing, repair)), 3 SECONDS, TIMER_STOPPABLE|TIMER_DELETE_ME)
	switch(chosen_gun)
		if("Pistols")
			new /obj/item/storage/bag/ammo/hatred_c4(get_turf(owner.current))
		else
			// предотвращаем уничтожение уникального оружия на спине
			var/mob/living/L = owner.current
			if(istype(L))
				var/obj/item/I = L.get_item_by_slot(ITEM_SLOT_SUITSTORE)
				if(istype(I))
					I.forceMove(L.drop_location())

/// Не ползаем по 10 минут беспомощно в крите. Либо встаем и дерёмся, либо умираем в последней битве.
/datum/antagonist/hatred/proc/recover_from_softcrit(mob/source, delta_time, times_fired)
	SIGNAL_HANDLER
	if(owner.current.stat == SOFT_CRIT)
		owner.current.heal_overall_damage(2*delta_time, 2*delta_time, 0, FALSE, FALSE, FALSE, TRUE)
		owner.current.adjustToxLoss(-2*delta_time, FALSE, TRUE)
		owner.current.adjustOxyLoss(-2*delta_time, FALSE, TRUE)
		owner.current.adjustCloneLoss(-2*delta_time, FALSE, TRUE)
		owner.current.updatehealth()

/datum/movespeed_modifier/hatred
	multiplicative_slowdown = 0.5 // плохе настроение первой степени

/datum/movespeed_modifier/hatred_glory_kill
	multiplicative_slowdown = -1

/datum/antagonist/hatred/proc/evaluate_security()
	var/gear_points = length(SSjob.get_living_sec())
	// for(var/mob/living/carbon/human/player in GLOB.carbon_list)
	// 	if(player.client && player.stat != DEAD && player.mind && (player.mind.assigned_role in list("Blueshield")))
	// 		gear_points++
	if(GLOB.security_level == SEC_LEVEL_GREEN) // (GC) - у станции нет проблем и все внимание СБ будет приковано к антагу
		gear_points++
	if(length(active_ais(check_mind = TRUE))) // вертолеты
		gear_points++
	if(gear_points < 7)
		gear_level = 1 // 5-6
	else
		gear_level = 2 // 7+

/datum/antagonist/hatred/proc/make_authentic_body()
	var/mob/living/carbon/human/H = owner.current
	H.real_name = "The Man without a name"
	H.name = H.real_name
	H.dna.real_name = H.real_name
	H.mind?.name = H.real_name
	H.set_species(/datum/species/human)
	H.set_gender(MALE, TRUE, forced = TRUE)
	H.dna.remove_all_mutations()
	H.skin_tone = "albino"
	//H.hair_style = Curtains diagonal_bangs sunny vivi #000000 "Bonnie"
	H.hair_style = "Curtains"
	H.hair_color = sanitize_hexcolor("#000000")
	H.facial_hair_style = "Beard (3 o\'Clock)" //"Shaved"
	H.facial_hair_color = sanitize_hexcolor("#000000")
	H.set_bark("growl2")
	H.vocal_speed = 8
	H.vocal_pitch = 0.6
	H.vocal_pitch_range = 0.3
	H.dna.update_ui_block(DNA_GENDER_BLOCK)
	H.dna.update_ui_block(DNA_SKIN_TONE_BLOCK)
	H.dna.update_ui_block(DNA_HAIR_STYLE_BLOCK)
	H.dna.update_ui_block(DNA_HAIR_COLOR_BLOCK)
	H.dna.update_ui_block(DNA_FACIAL_HAIR_STYLE_BLOCK)
	H.dna.update_ui_block(DNA_FACIAL_HAIR_COLOR_BLOCK)
	H.dna.features["legs"] = "Plantigrade"
	H.dna.species.mutant_bodyparts["legs"] = "Plantigrade"
	H.Digitigrade_Leg_Swap(TRUE)
	H.update_body()
	H.update_hair()

/datum/antagonist/hatred/proc/appear_on_station()
	var/list/possible_spawns = list()
	var/list/best_possible_spawns = list() // no players around
	// Method 1: find the most optimal maint turf
	for(var/i = 1; i <= 100; i++)
		var/turf/T = get_safe_random_station_turf(typesof(/area/maintenance) & GLOB.the_station_areas)
		if(istype(T))
			if(length(possible_spawns) < 6)
				possible_spawns += T
			var/players_nearby = FALSE
			for(var/mob/living/L in range(10, T))
				if(L.client && L.stat != DEAD)
					players_nearby = TRUE
					break
			if(!players_nearby)
				best_possible_spawns += T
				if(length(best_possible_spawns) >= 6) // enough
					break
	// Method 2 (if 1 failed): find the most optimal xeno maint spawn. Atmos problems are possible.
	for(var/turf/X in GLOB.xeno_spawn) //Some xeno spawns are in some spots that will instantly kill human, like atmos
		if(length(possible_spawns) >= 6)
			break
		if(istype(X.loc, /area/maintenance))
			possible_spawns += X
	// Method 3 (if 1 and 2 failed): find ANY safe station turf
	if(isemptylist(possible_spawns))
		possible_spawns += find_safe_turf(extended_safety_checks = TRUE, dense_atoms = FALSE) // in case of some huge map problems
	possible_spawns += get_safe_random_station_turf(typesof(/area/command/gateway)) // 1/7 is ~15%
	listclearnulls(possible_spawns)
	var/turf/chosen_turf = !isemptylist(best_possible_spawns) ? pick(best_possible_spawns) : pick(possible_spawns)
	owner.current.forceMove(chosen_turf)
	do_sparks(4, TRUE, owner.current)

/datum/antagonist/hatred/proc/check_hatred_off_station()
	SIGNAL_HANDLER
	var/turf/my_location = get_turf(owner.current)
	if(!(my_location.z in allowed_z_levels))
		owner.current.say("Так просто они от меня не избавятся!", spans = list(SPAN_YELL), forced = TRUE)
		appear_on_station()

/// major antag is currently commencing genocide, so we must let everyone know.
/datum/antagonist/hatred/proc/alarm_station()
	if(istype(src) && owner?.current && owner?.current.stat != DEAD)
		var/chosen_sound = pick('modular_bluemoon/code/modules/antagonists/hatred/hatred_spawned_1.ogg','modular_bluemoon/code/modules/antagonists/hatred/hatred_spawned_2.ogg')
		priority_announce("На ваш объект ворвался особо опасный вооруженный преступник с целью массового убийства гражданских лиц. \
							Нейтрализуйте угрозу любыми доступными средствами. \
							ЦК санкционирует всему персоналу станции против данной цели: использование летального вооружения, открытие огня без предупреждения и казнь на месте. \
							\n\nОсобые приметы: мужчина спортивного телосложения в длинном черном кожаном пальто с длинными черными волосами и [chosen_gun].", \
							"ALERT: MASS SHOOTER!", chosen_sound, has_important_message = TRUE)

/// we check if we picked up a knife in our hand. if so, we listen to it when it strikes its target.
/datum/antagonist/hatred/proc/check_equipped_item(mob/source, obj/item/I, slot)
	SIGNAL_HANDLER
	if(ishuman(source) && slot == ITEM_SLOT_HANDS)
		if(istype(I, /obj/item/kitchen/knife))
			RegisterSignal(I, COMSIG_ITEM_DROPPED, PROC_REF(remove_knife_check_glory))
			RegisterSignal(I, COMSIG_ITEM_ATTACK, PROC_REF(knife_check_glory))

/// once we don't hold a knife, we don't listen to it when it strikes.
/datum/antagonist/hatred/proc/remove_knife_check_glory(obj/item/kitchen/knife/K, mob/user)
	SIGNAL_HANDLER
	UnregisterSignal(K, COMSIG_ITEM_ATTACK)
	UnregisterSignal(K, COMSIG_ITEM_DROPPED)

/// if we strike a target and it meets certain criteria - we handle it in a special way.
/datum/antagonist/hatred/proc/knife_check_glory(obj/item/kitchen/knife/knife, mob/living/target_mob, mob/user, damage_multiplier)
	SIGNAL_HANDLER
	if(ishuman(target_mob) && ishuman(user) && target_mob != user)
		if(damage_multiplier == 100) // no need to check. the lethal strike is about to be blown.
			return
		var/mob/living/carbon/human/target = target_mob
		var/mob/living/carbon/human/killer = user
		// the target is dead and we want its heart for the Belt of Hatred.
		if(target.stat == DEAD && killer.zone_selected == BODY_ZONE_CHEST && target.get_bodypart(BODY_ZONE_CHEST))
			var/obj/item/organ/heart/h = locate() in target.internal_organs
			if(istype(h) && !(h.organ_flags & ORGAN_NO_DISMEMBERMENT))
				h.Remove()
				user.visible_message(span_bolddanger("[user] безжалостно вырывает сердце из [target]!"))
				if(!killer.put_in_inactive_hand(h))
					h.forceMove(target.drop_location())
		// the target is almost dead and we want to glory kill it with a knife.
		else if(!(target.stat in list(CONSCIOUS)) && killer.zone_selected == BODY_ZONE_PRECISE_MOUTH && !HAS_TRAIT(target, TRAIT_DULLAHAN) && target.get_bodypart(BODY_ZONE_HEAD))
			target.visible_message(span_bolddanger("[killer] подносит [knife] к горлу [target], готовый перерезать его..."), \
									span_userdanger("[killer] подносит [knife] к твоему горлу, готовый перерезать его..."))
			// it's a signal handler so we don't sleep
			INVOKE_ASYNC(src, PROC_REF(knife_glory_kill), knife, target, killer)
			return COMPONENT_CANCEL_ATTACK_CHAIN

/// target is in crit and about to be executed.
/datum/antagonist/hatred/proc/knife_glory_kill(obj/item/kitchen/knife/knife, mob/living/carbon/human/target, mob/living/carbon/human/killer)
	var/is_glory = TRUE
	// already dead bodies or npcs don't count
	// if((!target.client && ((world.time - target.lastclienttime) > 10 SECONDS)) || (target.stat == DEAD && ((world.time - target.timeofdeath) > 3 SECONDS)))
	if(!target.client || target.stat == DEAD)
		is_glory = FALSE
	else if(COOLDOWN_FINISHED(src, killing_speech_cd))
		playsound(owner.current, pick(killing_speech), vol = 100, vary = FALSE, ignore_walls = FALSE)
		COOLDOWN_START(src, killing_speech_cd, 10 SECONDS)
	var/time_to_kill = chosen_high_gear == "Faster executions" ? 4 SECONDS : 6 SECONDS
	if(do_after(killer, time_to_kill, target))
		target.visible_message(span_bolddanger("[killer] перерезает горло [target]!"), span_userdanger("[killer] перерезает твое горло!"))
		knife.melee_attack_chain(killer, target, damage_multiplier = 100)
		while(!QDELETED(target) && target.stat != DEAD && killer.CanReach(target, knife))
			if(!do_after(killer, 0.5 SECONDS, target))
				break
			if(knife.melee_attack_chain(killer, target, damage_multiplier = 100) & STOP_ATTACK_PROC_CHAIN)
				break
		if(is_glory)
			addtimer(CALLBACK(knife, TYPE_PROC_REF(/obj/item/kitchen/knife, check_glory_kill), killer, target), 1 SECONDS, TIMER_STOPPABLE|TIMER_DELETE_ME)
	else
		killer.visible_message(span_notice("[killer] остановил свой нож."))

/obj/item/gun/handle_suicide(mob/living/carbon/human/user, mob/living/carbon/human/target, params, bypass_timer, time_to_kill = 12 SECONDS)
	var/datum/antagonist/hatred/Ha = user.mind?.has_antag_datum(/datum/antagonist/hatred)
	if(!Ha || !ishuman(target))
		return ..()
	if(!target.get_bodypart(BODY_ZONE_HEAD))
		return
	var/is_glory = TRUE
	// already dead bodies or npcs don't count
	// if((!target.client && ((world.time - target.lastclienttime) > 10 SECONDS)) || (target.stat == DEAD && ((world.time - target.timeofdeath) > 3 SECONDS)))
	if(!target.client || target?.stat == DEAD)
		is_glory = FALSE
	else if(COOLDOWN_FINISHED(Ha, killing_speech_cd))
		playsound(user, pick(Ha.killing_speech), vol = 100, vary = FALSE, ignore_walls = FALSE)
		COOLDOWN_START(Ha, killing_speech_cd, 10 SECONDS)
	var/new_ttk = Ha.chosen_high_gear == "Faster executions" ? 7 SECONDS : 9 SECONDS
	. = ..(user, target, params, bypass_timer, time_to_kill = new_ttk)
	if(!. || user == target || !is_glory)
		return
	addtimer(CALLBACK(src, PROC_REF(check_glory_kill), user, target), 1 SECONDS, TIMER_STOPPABLE|TIMER_DELETE_ME) // wait for boolet to do its job

/obj/item/proc/check_glory_kill(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if((QDELETED(target) || target?.stat == DEAD) && !QDELETED(user) && user?.stat != DEAD)
		user.fully_heal(TRUE) // the only way of healing
		// user.do_adrenaline(150, TRUE, 0, 0, TRUE, list(/datum/reagent/medicine/inaprovaline = 10, /datum/reagent/medicine/synaptizine = 15, /datum/reagent/medicine/regen_jelly = 20, /datum/reagent/medicine/stimulants = 20), "<span class='boldnotice'>You feel a sudden surge of energy!</span>")
		user.visible_message("Кровь жертвы окрапляет [user], даруя ему нечеловеческое облегчение и силу продолжать бойню.")
		user.add_movespeed_modifier(/datum/movespeed_modifier/hatred_glory_kill)
		addtimer(CALLBACK(user, TYPE_PROC_REF(/mob/living/carbon/human, remove_movespeed_modifier), /datum/movespeed_modifier/hatred_glory_kill), 15 SECONDS, TIMER_STOPPABLE|TIMER_DELETE_ME|TIMER_UNIQUE|TIMER_OVERRIDE)
		var/datum/antagonist/hatred/Ha = user.mind?.has_antag_datum(/datum/antagonist/hatred)
		var/datum/objective/genocide/objective = locate() in Ha?.objectives
		objective?.glory_kills++
		var/obj/item/storage/belt/military/assault/hatred/B = user.get_item_by_slot(ITEM_SLOT_BELT)
		if(istype(B))
			to_chat(user, span_notice("[B.name] жадно урчит в предвкушении скорого жертвоприношения."))
			B.glory_points++

//////////////////////////////////////////////
//                                          //
//                	 GEAR		            //
//                                          //
//////////////////////////////////////////////

/// AK-47 GEAR ///

/obj/item/gun/ballistic/automatic/ak47/hatred
	name = "\improper AK-47 rifle of Hatred"
	desc = "The scratches on this rifle say: \"The Genocide Machine\"."
	resistance_flags = FIRE_PROOF | ACID_PROOF
	max_integrity = 400 // will be damaged during antag's death implant detonation
	weapon_weight = WEAPON_HEAVY
	can_suppress = FALSE
	// AP = 0
	// DMG 100% = 28

/obj/item/gun/ballistic/automatic/ak47/hatred/on_attack_hand(mob/user, act_intent, unarmed_attack_flags)
	if(loc == user && user.is_holding(src) && magazine)
		attack_self(user)
		return
	. = ..()

/obj/item/gun/ballistic/automatic/ak47/hatred/Initialize(mapload)
	LAZYADD(actions_types, /datum/action/item_action/no_drop_toggle)
	. = ..()

/obj/item/gun/ballistic/automatic/ak47/hatred/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/no_drop_toggle))
		return
	. = ..()

/obj/item/gun/ballistic/automatic/ak47/hatred/dropped(mob/user, silent) // lost arm, etc...
	. = ..()
	REMOVE_TRAIT(src, TRAIT_NODROP, null)

// clickclickclickclickclick... panic!
/obj/item/gun/ballistic/automatic/ak47/hatred/on_autofire_start(mob/living/shooter)
	. = ..()
	if(. == FALSE && !can_shoot())
		shoot_with_empty_chamber(shooter)

/// SHOTGUN GEAR ///

/obj/item/gun/ballistic/shotgun/automatic/combat/hatred
	name = "\improper Combat Shotgun of Hatred"
	desc = "The scratches on this shotgun say: \"The Bringer of Doom\"."
	icon_state = "cshotgun_slick"
	// icon_state = "wood_riotshotgun"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/com/hatred
	resistance_flags = FIRE_PROOF | ACID_PROOF
	max_integrity = 400 // will be damaged during antag's death implant detonation
	fire_delay = 4
	weapon_weight = WEAPON_HEAVY
	unique_reskin = null
	var/quick_empty_flag = FALSE // is user quick emptying it right now

/obj/item/ammo_box/magazine/internal/shot/com/hatred
	max_ammo = 7 // 7+1 = 2 clips

/obj/item/gun/ballistic/shotgun/automatic/combat/hatred/Initialize(mapload)
	LAZYADD(actions_types, /datum/action/item_action/no_drop_toggle)
	. = ..()
	toggle_stock()
	w_class = WEIGHT_CLASS_BULKY
	pump()

/obj/item/gun/ballistic/shotgun/automatic/combat/hatred/update_icon_state()
	icon_state = "cshotgun_slick"

/obj/item/gun/ballistic/shotgun/automatic/combat/hatred/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/no_drop_toggle))
		return
	. = ..()

/obj/item/gun/ballistic/shotgun/automatic/combat/hatred/examine(mob/user)
	. = ..()
	. += span_red("[span_bold("Ctrl-Shift-Click")] - быстрая разрядка.")

/obj/item/gun/ballistic/shotgun/automatic/combat/hatred/dropped(mob/user, silent) // lost arm, etc...
	. = ..()
	REMOVE_TRAIT(src, TRAIT_NODROP, null)

/obj/item/gun/ballistic/shotgun/automatic/combat/hatred/attack_self(mob/living/user)
	if(!quick_empty_flag)
		. = ..()

/obj/item/gun/ballistic/shotgun/automatic/combat/hatred/CtrlShiftClick(mob/living/carbon/human/user)
	if(!quick_empty_flag)
		quick_empty_flag = TRUE
		pump(user)
		while(chambered)
			stoplag(3) // a bit slower than TRAIT_FAST_PUMP
			pump(user)
		quick_empty_flag = FALSE

/obj/item/gun/ballistic/shotgun/automatic/combat/hatred/toggle_stock(mob/living/user)
	if(stock)
		return
	. = ..()

// Импровизируем, чтобы избавиться от наслеования с револьверов /revolver/doublebarrel.
// Не наследуемся с /ballistic/shotgun/automatic так кам основе лежит помповая дрочильня, даже если она автоматическая.
// Частичный копипаст из обоих объектов.
/obj/item/gun/ballistic/automatic/shotgun/doublebarrel_hatred
	name = "\proper The \"Plan B\""
	desc = "The scratches on this sawn-off double-barreled shotgun say: \"Plan B\"."
	icon = 'modular_splurt/icons/obj/guns/projectile.dmi'
	icon_state = "shotgun"
	item_state = "shotgun"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	w_class = WEIGHT_CLASS_NORMAL
	weapon_weight = WEAPON_LIGHT
	slot_flags = ITEM_SLOT_BELT
	mag_type = /obj/item/ammo_box/magazine/internal/shot/dual/hatred
	fire_sound = "sound/weapons/gunshotshotgunshot.ogg"
	recoil = 2
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC)
	can_suppress = FALSE
	sawn_off = TRUE
	unique_reskin = null
	burst_size = 2
	burst_spread = 16
	burst_shot_delay = 1
	casing_ejector = FALSE

/obj/item/gun/ballistic/automatic/shotgun/doublebarrel_hatred/update_icon_state()
	// sawnshotgun-l_broke
	icon_state = "[sawn_off ? "sawn" : "d"][initial(icon_state)][current_skin]"
	item_state = "[sawn_off ? "sawn" : ""][initial(item_state)]"

/obj/item/gun/ballistic/automatic/shotgun/doublebarrel_hatred/chamber_round()
	if(chambered?.BB || !magazine || !magazine.ammo_count())
		return
	chambered = magazine.get_round(TRUE)

/obj/item/gun/ballistic/automatic/shotgun/doublebarrel_hatred/get_ammo(countchambered)
	return ..(FALSE)

/obj/item/gun/ballistic/automatic/shotgun/doublebarrel_hatred/attack_self(mob/living/user)
	playsound(src, "gun_dry_fire", 30, 1)
	if(!magazine.ammo_count())
		to_chat(user, span_warning("[src] is empty!"))
		return
	chambered = null
	magazine.empty_magazine()
	// playsound(user, 'sound/weapons/shotguninsert.ogg', 60, TRUE)

/obj/item/gun/ballistic/automatic/shotgun/doublebarrel_hatred/attackby(obj/item/A, mob/user, params)
	. = ..()
	if(.)
		return
	var/num_loaded = magazine.attackby(A, user, params, TRUE)
	if(num_loaded)
		chamber_round()
		to_chat(user, "You load a shell into \the [src]!")
		playsound(user, 'sound/weapons/shotguninsert.ogg', 60, TRUE)
		A.update_icon()
		update_icon(UPDATE_DESC)

/obj/item/ammo_box/magazine/internal/shot/dual/hatred
	max_ammo = 2
	ammo_type = /obj/item/ammo_casing/shotgun/frangible

/// PISTOLS GEAR ///

/obj/item/gun/ballistic/automatic/pistol/m1911/hatred // enforcer?
	name = "\proper M1911 of Hatred"
	desc = "The scratches on this pistol say: \"The Executioner\"."
	resistance_flags = FIRE_PROOF | ACID_PROOF
	// AP = 0
	// DMG 100% = 25
	dual_wield_spread = 5
	var/datum/weakref/original_owner = null

/obj/item/gun/ballistic/automatic/pistol/m1911/hatred/Destroy()
	original_owner = null
	. = ..()

/obj/item/gun/ballistic/automatic/pistol/m1911/hatred/equipped(mob/user, slot, initial)
	. = ..()
	if(isnull(original_owner) && ishuman(loc) && slot == ITEM_SLOT_HANDS)
		original_owner = WEAKREF(loc)

/obj/item/gun/ballistic/automatic/pistol/m1911/hatred/dropped(mob/user, silent)
	. = ..()
	if(!QDELETED(src))
		addtimer(CALLBACK(src, PROC_REF(check_destroy_pistol), user), 3 SECONDS, TIMER_STOPPABLE|TIMER_DELETE_ME)

/obj/item/gun/ballistic/automatic/pistol/m1911/hatred/proc/check_destroy_pistol(mob/user)
	if(!QDELETED(src) && original_owner?.resolve() != loc)
		visible_message("[src] рассыпается в прах на ваших глазах...")
		var/obj/effect/decal/cleanable/ash/ash = new /obj/effect/decal/cleanable/ash(get_turf(loc))
		ash.pixel_z = -5
		ash.pixel_w = rand(-1, 1)
		qdel(src)

/obj/item/gun/ballistic/automatic/pistol/m1911/hatred/shoot_with_empty_chamber(mob/living/user)
	. = ..()
	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		H.dropItemToGround(src, force = TRUE, silent = FALSE)
		H.visible_message("[H] с безразличием бросает на землю пустой пистолет.")
	var/obj/item/gun/ballistic/automatic/pistol/m1911/hatred/second = user.get_inactive_held_item()
	if(istype(second, type))
		if(!second.can_shoot() || !second.chambered || !second.chambered.BB)
			addtimer(CALLBACK(second, TYPE_PROC_REF(/obj/item/gun, shoot_with_empty_chamber), user), 2)

/obj/item/storage/belt/holster/hatred
	name = "\proper Holster of Hatred"
	desc = "Кобура Ненависти воплощает смертоностные, но недолговечные пистолеты."
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/item/storage/belt/holster/hatred/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = INFINITY // only for weight calculations. it still has type and slots limits
	STR.display_numerical_stacking = FALSE
	STR.max_items = 2
	STR.quickdraw = TRUE
	STR.can_hold = typecacheof(list(/obj/item/gun/ballistic/automatic/pistol/m1911/hatred))
	new /obj/item/gun/ballistic/automatic/pistol/m1911/hatred(src)
	new /obj/item/gun/ballistic/automatic/pistol/m1911/hatred(src)

/obj/item/storage/belt/holster/hatred/examine(mob/user)
	. = ..()
	. += span_notice("[span_bold("Alt-Click")] - взять пистолет в пустую руку.")

/obj/item/storage/belt/holster/hatred/equipped(mob/user, slot)
	. = ..()
	if(slot in list(ITEM_SLOT_BELT, ITEM_SLOT_SUITSTORE))
		ADD_TRAIT(src, TRAIT_NODROP, HATRED_ANTAG)

/obj/item/storage/belt/holster/hatred/dropped(mob/user, silent)
	. = ..()
	if(!QDELETED(src))
		visible_message("[src] рассыпается в прах на ваших глазах...")
		qdel(src)

/obj/item/storage/belt/holster/hatred/Exited(atom/movable/gone, direction)
	. = ..()
	if(!QDELETED(src))
		new /obj/item/gun/ballistic/automatic/pistol/m1911/hatred(src)
		// atom_storage.refresh_views()
		// update_appearance()

/obj/item/storage/bag/ammo/hatred_c4
	name = "\improper Breaching pouch of Hatred"
	desc = "Проклятый Подсумок Ненависти раз в 20 секунд воплощает заряд C4 с коротким таймером."
	resistance_flags = FIRE_PROOF | ACID_PROOF
	max_integrity = 400

/obj/item/storage/bag/ammo/hatred_c4/Initialize(mapload)
	. = ..()
	create_c4()

/obj/item/storage/bag/ammo/hatred_c4/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.can_hold = typecacheof(list(/obj/item/grenade/plastic/c4))
	STR.max_combined_w_class = INFINITY // only for weight calculations. it still has type and slots limits
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.max_items = 1
	STR.quickdraw = TRUE

/obj/item/storage/bag/ammo/hatred_c4/examine(mob/user)
	. = ..()
	. += span_notice("[span_bold("Alt-Click")] - вытащить предмет.")

/obj/item/storage/bag/ammo/hatred_c4/Exited(atom/movable/gone, atom/newLoc)
	. = ..()
	if(istype(gone, /obj/item/grenade/plastic/c4))
		addtimer(CALLBACK(src, PROC_REF(create_c4)), 20 SECONDS, TIMER_STOPPABLE|TIMER_DELETE_ME|TIMER_UNIQUE)

/obj/item/storage/bag/ammo/hatred_c4/proc/create_c4()
	if(QDELETED(src) || contents.len > 0)
		return
	var/obj/item/grenade/plastic/c4/C = new(src)
	C.det_time = 2
	C.w_class = WEIGHT_CLASS_BULKY // не стакаем бесплатные заряды у себя в рюкзаке

/// THE POUCH OF HATRED ///

/obj/item/storage/bag/ammo/hatred
	name = "\improper Ammo pouch of Hatred"
	desc = "Проклятый Подсумок Ненависти пополняет пустые магазины для твоих Машин Геноцида, подстегивая тебя продолжать бесчеловечную бойню."
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/item/storage/bag/ammo/hatred/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = INFINITY // only for weight calculations. it still has type and slots limits
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.display_numerical_stacking = FALSE
	STR.quickdraw = TRUE

/obj/item/storage/bag/ammo/hatred/examine(mob/user)
	. = ..()
	. += span_red("Положи пустой магазин/картридж/клипсу в этот проклятый подсумок и он наполнится патронами.")
	. += span_notice("[span_bold("Alt-Click")] - вытащить предмет.")

/obj/item/storage/bag/ammo/hatred/Entered(atom/movable/AM, atom/oldLoc)
	. = ..()
	var/M = AM.type
	qdel(AM)
	new M(src)

// TRAIT_NODROP doesn't work on items in pockets T_T
/obj/item/storage/bag/ammo/hatred/MouseDrop(atom/over, src_location, over_location, src_control, over_control, params)

/obj/item/storage/bag/ammo/hatred/equipped(mob/user, slot, initial)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, HATRED_ANTAG)

/obj/item/storage/bag/ammo/hatred/dropped(mob/user, silent)
	. = ..()
	if(!QDELETED(src))
		visible_message("[src] рассыпается в прах на ваших глазах...")
		qdel(src)

/// THE BELT OF HATRED ///

/obj/item/storage/belt/military/assault/hatred
	name = "\improper Belt of Hatred"
	desc = "Проклятый Пояс Ненависти жадно поглощает сердца твоих жертв и вознаграждает тебя смертоностной аммуницией."
	resistance_flags = FIRE_PROOF | ACID_PROOF
	var/glory_points = 0

/obj/item/storage/belt/military/assault/hatred/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 10
	STR.max_combined_w_class = INFINITY
	STR.can_hold_extra += typecacheof(list(/obj/item/gun/ballistic/automatic/shotgun/doublebarrel_hatred))

/obj/item/storage/belt/military/assault/hatred/examine(mob/user)
	. = ..()
	. += span_red("Положи сердце в этот проклятый пояс и оно обратится во взрывчатку.")
	. += span_notice("[src] готов принять [span_red("[glory_points]")] сердец. Брутально добей больше ничтожеств, чтобы насытить пояс.")

/obj/item/storage/belt/military/assault/hatred/Entered(atom/movable/AM, atom/oldLoc)
	. = ..()
	if(istype(AM, /obj/item/organ/heart) && glory_points)
		glory_points--
		qdel(AM)
		switch(rand(1,3))
			if(1)
				new /obj/item/grenade/syndieminibomb/concussion(src)
			if(2)
				new /obj/item/grenade/frag(src)
			if(3)
				var/obj/item/reagent_containers/food/drinks/bottle/molotov/mol = new /obj/item/reagent_containers/food/drinks/bottle/molotov(src)
				mol.reagents.add_reagent(/datum/reagent/consumable/ethanol/vodka, 100)

/obj/item/storage/belt/military/assault/hatred/equipped(mob/user, slot, initial)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, HATRED_ANTAG)

/obj/item/storage/belt/military/assault/hatred/dropped(mob/user, silent)
	. = ..()
	if(!QDELETED(src))
		visible_message("[src] рассыпается в прах на ваших глазах...")
		qdel(src)

/// THE OVERCOAT OF HATRED ///

/obj/item/clothing/suit/jacket/leather/overcoat/hatred
	name = "leather overcoat of Hatred"
	desc = "The shabby leather overcoat with decent armor paddings. Once it has been splashed with blood you can't take it off anymore."
	resistance_flags = FIRE_PROOF
	// clueless armor stats.
	armor = list(MELEE 	= 40, \
				BULLET 	= 40, \
				LASER 	= 40, \
				ENERGY 	= 40, \
				BOMB 	= 40, \
				BIO 	= 40, \
				RAD 	= 20, \
				FIRE 	= 70, \
				ACID 	= 40, \
				WOUND 	= 40)

/obj/item/clothing/suit/jacket/leather/overcoat/hatred/Initialize(mapload)
	. = ..()
	allowed += list(/obj/item/storage/belt/holster, /obj/item/gun)

/obj/item/clothing/head/invisihat/hatred
	name = "Veil of Hatred"
	desc = "Once you felt <b><i>that</i></b> urge to commit relentless genocide of civilians, you clearly understood you were cursed... blessed... and... protected by invisible Veil of Hatred."
	resistance_flags = FIRE_PROOF | ACID_PROOF
	// clueless armor stats.
	armor = list(MELEE 	= 40, \
				BULLET 	= 40, \
				LASER 	= 40, \
				ENERGY 	= 40, \
				BOMB 	= 40, \
				BIO 	= 40, \
				RAD 	= 20, \
				FIRE 	= 70, \
				ACID 	= 40, \
				WOUND 	= 40)

/obj/item/clothing/head/invisihat/hatred/equipped(mob/user, slot)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, HATRED_ANTAG)

/obj/item/clothing/head/invisihat/hatred/dropped(mob/user)
	. = ..()
	if(!QDELETED(src))
		visible_message("[src] рассыпается в прах на ваших глазах...")
		qdel(src)

/// OUTFIT ///
/// defult gear. will be changed during pre_equip().
/datum/outfit/hatred
	name = "Hatred"
	head = /obj/item/clothing/head/invisihat/hatred
	glasses = /obj/item/clothing/glasses/hud/health/sunglasses/aviators // to help player identify when a target is in crit so player can safely execute him
	uniform = /obj/item/clothing/under/rank/civilian/util/greyshirt
	suit = /obj/item/clothing/suit/jacket/leather/overcoat/hatred
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	id = /obj/item/card/id/stowaway_stolen
	belt = /obj/item/storage/belt/military/assault/hatred
	back = /obj/item/storage/backpack/satchel // /obj/item/storage/backpack/rucksack
	backpack_contents = list(/obj/item/storage/box/survival/engineer = 1,
		/obj/item/kitchen/knife/combat = 1,
		// /obj/item/flashlight/seclite = 1,
		/obj/item/crowbar = 1
		)
	implants = list(/obj/item/implant/explosive) // post_equip() doesn't work for implants since implanting occurs afrer post_equip()

/datum/outfit/hatred/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	var/datum/antagonist/hatred/Ha = H.mind?.has_antag_datum(/datum/antagonist/hatred)
	if(!Ha)
		return
	// Ha.gear_level = tgui_input_list(H, "ЭТО ОКОШКО ДЛЯ ОБМАНА ПОДСЧЕТА ОФИЦЕРОВ В РАУНДЕ И НУЖНО ТОЛЬКО ДЛЯ ДЕБАГА, В ИГРЕ ЕГО НЕ БУДЕТ", "gear level?", list(1, 2), 1)
	var/available_sets = Ha.classic_guns
	SEND_SOUND(H, 'sound/misc/notice2.ogg')
	Ha.chosen_gun = tgui_input_list(H, "Выбери стартовое оружие", , available_sets, available_sets[1], 10 SECONDS)
	if(!Ha.chosen_gun)
		Ha.chosen_gun = available_sets[1]
	switch(Ha.chosen_gun)
		if("AK47")
			suit_store = /obj/item/gun/ballistic/automatic/ak47/hatred
			l_pocket = /obj/item/storage/bag/ammo/hatred
		if("Combat Shotgun")
			suit_store = /obj/item/gun/ballistic/shotgun/automatic/combat/hatred
			l_pocket = /obj/item/storage/bag/ammo/hatred
			ADD_TRAIT(H, TRAIT_AKIMBO, HATRED_ANTAG)
		if("Pistols")
			suit_store = /obj/item/storage/belt/holster/hatred
			l_pocket = /obj/item/storage/bag/ammo/hatred_c4
			ADD_TRAIT(H, TRAIT_DOUBLE_TAP, HATRED_ANTAG)
	if(Ha.gear_level >= 2)
		Ha.chosen_high_gear = tgui_input_list(H, "Выбери дополнительную экипировку", , Ha.high_gear, Ha.high_gear[1], 10 SECONDS)
		if(!Ha.chosen_high_gear)
			Ha.chosen_high_gear = Ha.high_gear[1]

/datum/outfit/hatred/post_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	if(!istype(H) || QDELETED(H))
		return
	// var/obj/item/implant/explosive/E = new
	// E.implant(H)
	// var/obj/item/organ/cyberimp/brain/anti_drop/ad = new
	// ad.Insert(H)
	var/obj/item/clothing/under/U = H.get_item_by_slot(ITEM_SLOT_ICLOTHING)
	if(U)
		U.has_sensor = NO_SENSORS
		U.resistance_flags = FIRE_PROOF | ACID_PROOF
		U.unique_reskin = null
		U.max_restricted_accessories = 1
		ADD_TRAIT(U, TRAIT_NODROP, HATRED_ANTAG)

	var/obj/item/I = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(I)
		ADD_TRAIT(I, TRAIT_NODROP, HATRED_ANTAG)

	I = H.get_item_by_slot(ITEM_SLOT_FEET)
	I?.resistance_flags = FIRE_PROOF

	I = H.get_item_by_slot(ITEM_SLOT_EYES)
	I?.resistance_flags = FIRE_PROOF

	I = H.get_item_by_slot(ITEM_SLOT_GLOVES)
	I?.resistance_flags = FIRE_PROOF

	I = H.get_item_by_slot(ITEM_SLOT_BACK)
	I?.resistance_flags = FIRE_PROOF

	var/obj/item/storage/belt/B = H.get_item_by_slot(ITEM_SLOT_BELT)
	if(B)
		new /obj/item/grenade/syndieminibomb/concussion(B)
		new /obj/item/grenade/frag(B)
		var/obj/item/reagent_containers/food/drinks/bottle/molotov/mol = new /obj/item/reagent_containers/food/drinks/bottle/molotov(B)
		mol.reagents.add_reagent(/datum/reagent/consumable/ethanol/vodka, 100)
		new /obj/item/lighter(B)

	var/datum/antagonist/hatred/Ha = H.mind?.has_antag_datum(/datum/antagonist/hatred)
	if(!Ha)
		return
	switch(Ha.chosen_gun)
		if("AK47")
			var/obj/item/storage/bag/ammo/hatred/P = H.get_item_by_slot(ITEM_SLOT_LPOCKET)
			if(P)
				var/datum/component/storage/STR = P.GetComponent(/datum/component/storage)
				STR.can_hold = typecacheof(list(/obj/item/ammo_box/magazine/ak47))
				STR.max_items = 3
				new /obj/item/ammo_box/magazine/ak47(P)
				new /obj/item/ammo_box/magazine/ak47(P)
		if("Combat Shotgun")
			var/obj/item/storage/bag/ammo/hatred/P = H.get_item_by_slot(ITEM_SLOT_LPOCKET)
			if(P)
				var/datum/component/storage/STR = P.GetComponent(/datum/component/storage)
				STR.can_hold = typecacheof(list(/obj/item/ammo_box/shotgun/loaded))
				STR.max_items = 5
				new /obj/item/ammo_box/shotgun/loaded/buckshot(P)
				new /obj/item/ammo_box/shotgun/loaded(P)
				new /obj/item/ammo_box/shotgun/loaded/incendiary(P)
				// new /obj/item/ammo_casing/shotgun/dragonsbreath(P)
				new /obj/item/ammo_box/shotgun/loaded/frangible(P)
				new /obj/item/ammo_box/shotgun/loaded/flechette(P)
			if(B)
				new /obj/item/gun/ballistic/automatic/shotgun/doublebarrel_hatred(B)
		if("Pistols")
			I = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
			I?.resistance_flags = FIRE_PROOF | ACID_PROOF // to prevent the holster of Hatred to be dropped and lost forever.

	switch(Ha.chosen_high_gear)
		if("More armor")
			var/obj/item/clothing/C = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
			C?.armor = C?.armor.modifyAllRatings(10)
			C = H.get_item_by_slot(ITEM_SLOT_HEAD)
			C?.armor = C?.armor.modifyAllRatings(10)

/// DYNAMIC THINGS ///

/datum/dynamic_ruleset/midround/from_ghosts/hatred
	name = "Mass Shooter"
	antag_datum = /datum/antagonist/hatred
	antag_flag = ROLE_MASS_SHOOTER
	antag_flag_override = ROLE_MASS_SHOOTER
	// enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain")
	required_enemies = list(0,0,0,0,0,0,0,0,0,0)
	required_round_type = list(ROUNDTYPE_DYNAMIC_HARD)
	required_candidates = 1
	repeatable = FALSE // one man is enough to shake this station.
	earliest_start = 30 MINUTES
	weight = 9 // этот антаг имеет высокие требования к количеству живых офицеров и в нагруженные динамики это требование зачастую будет невыполено.
	admin_only = TRUE // пока что пусть то админы срут когда захотят
	// все что ниже ровно как у мага, т.к. для меня это какие то бессмысленные магические числа
	cost = 15
	intensity = 45
	antag_heavy = TRUE
	// requirements = list(101,101,100,60,40,20,20,20,10,10) // I'm not sure how this works and I don't trust it.
	// var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/hatred/ready(forced = FALSE)
	. = ..()
	// временно проверка не нужна так как на данный момент антаг должен запускаться только с подачи админов
	// if(. && !forced)
	// 	if(length(SSjob.get_living_sec()) < 5) // я желаю достойного сопротивления.
	// 		return FALSE

/datum/dynamic_ruleset/midround/from_ghosts/hatred/generate_ruleset_body(mob/applicant)
	// var/turf/entry_spawn_loc
	// if(length(GLOB.newplayer_start))
	// 	entry_spawn_loc = pick(GLOB.newplayer_start)
	// else
	// 	entry_spawn_loc = get_safe_random_station_turf(typesof(/area/centcom/evac))
	var/mob/living/carbon/human/body = new(get_turf(GET_ERROR_ROOM))
	body.dna.remove_all_mutations()
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE
	player_mind.transfer_to(body)
	message_admins("[ADMIN_LOOKUPFLW(body)] has been made into a Mass Shooter by the midround ruleset.")
	log_game("DYNAMIC: [key_name(body)] was spawned as a Mass Shooter by the midround ruleset.")
	return body

/datum/admins/proc/makeMassShooter(mob/dead/observer/applicant)
	var/mutable_appearance/alert_overlay = mutable_appearance('modular_bluemoon/code/modules/antagonists/hatred/hatred_icon.dmi', "human")
	if(!istype(applicant))
		var/list/mob/candidates = pollGhostCandidates("Do you wish to be considered for the position of a Mass Shooter?", "pacifist", null, ROLE_MASS_SHOOTER, 30 SECONDS,/* poll_header = "Mass Shooter",*/ poll_alert_pic = alert_overlay)
		applicant = pick_n_take(candidates)
	if(!istype(applicant) || !applicant.client)
		return FALSE
	// var/turf/entry_spawn_loc
	// if(length(GLOB.newplayer_start))
	// 	entry_spawn_loc = pick(GLOB.newplayer_start)
	// else
	// 	entry_spawn_loc = get_safe_random_station_turf(typesof(/area/centcom/evac))
	var/mob/living/carbon/human/body = new(get_turf(GET_ERROR_ROOM))
	body.dna.remove_all_mutations()
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE
	player_mind.transfer_to(body)
	notify_ghosts("Массшутер готовится к геноциду...", 'sound/weapons/autoguninsert.ogg', source = body, alert_overlay = alert_overlay, action = NOTIFY_ORBIT, header = "Mass Shooter")
	body.mind.make_MassShooter()
	return TRUE

/datum/mind/proc/make_MassShooter()
	if(!has_antag_datum(/datum/antagonist/hatred))
		special_role = "Mass Shooter"
		assigned_role = "Mass Shooter"
		add_antag_datum(/datum/antagonist/hatred)


#undef HATRED_ANTAG
