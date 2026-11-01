// Антагонист Рэт кинг.

/datum/antagonist/rat_king
	name = "Крысиный король"
	roundend_category = "Крысиные короли"
	antagpanel_category = "Rat King"
	job_rank = ROLE_RAT_KING
	show_in_antagpanel = TRUE
	show_name_in_check_antagonists = TRUE
	threat = 3
	blacklisted_quirks = list(/datum/quirk/nonviolent, /datum/quirk/mute, /datum/quirk/rat_whisperer)
	var/infected = 0
	/// Уже обращённые, чтобы не считать одного и того же дважды.
	var/list/infected_minds = list()

/datum/antagonist/rat_king/greet()
	to_chat(owner, span_boldannounce("Вы - крысиный король. Под вашими лапами техтоннели, а в зубах - жажда власти."))
	to_chat(owner, span_notice("Собирайте орду, распространяйте крысиную слюну и не дайте себя убить."))
	owner.announce_objectives()
	SEND_SOUND(owner.current, sound('sound/effects/mousesqueek.ogg'))

/datum/antagonist/rat_king/on_gain()
	forge_objectives()
	. = ..()

/datum/antagonist/rat_king/proc/forge_objectives()
	if(length(objectives))
		return
	var/datum/objective/rat_king/horde/horde_objective = new
	horde_objective.king = src
	objectives += horde_objective
	var/datum/objective/rat_king/infect/infect_objective = new
	infect_objective.king = src
	objectives += infect_objective
	var/datum/objective/rat_king/coffers/coffers_objective = new
	coffers_objective.king = src
	objectives += coffers_objective
	var/datum/objective/rat_king/chew/chew_objective = new
	chew_objective.king = src
	objectives += chew_objective
	var/datum/objective/rat_king/survive/survive_objective = new
	survive_objective.owner = owner
	objectives += survive_objective

/datum/antagonist/rat_king/roundend_report()
	var/list/parts = list()
	parts += printplayer(owner)
	if(length(objectives))
		parts += printobjectives(objectives)
		var/all_complete = TRUE
		for(var/datum/objective/objective as anything in objectives)
			if(!objective.check_completion())
				all_complete = FALSE
				break
		parts += all_complete ? span_greentext("Крысиный король добился своего.") : span_redtext("Крысиный король пал или не достиг целей.")
	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/datum/objective/rat_king/horde
	var/datum/antagonist/rat_king/king

/datum/objective/rat_king/horde/New()
	target_amount = rand(6, 10)
	explanation_text = "Соберите орду из [target_amount] крыс."
	. = ..()

/datum/objective/rat_king/horde/check_completion()
	if(!king || !king.owner || !king.owner.current)
		return FALSE
	var/mob/living/simple_animal/hostile/regalrat/rat_king = king.owner.current
	if(!istype(rat_king) || !rat_king.horde || QDELETED(rat_king.horde))
		return FALSE
	return length(rat_king.horde.minions) >= target_amount

/datum/objective/rat_king/infect
	var/datum/antagonist/rat_king/king

/datum/objective/rat_king/infect/New()
	target_amount = rand(3, 5)
	explanation_text = "Сделайте [target_amount] членов экипажа своими друзьями."
	. = ..()

/datum/objective/rat_king/infect/check_completion()
	if(!king)
		return FALSE
	return king.infected >= target_amount

/datum/objective/rat_king/coffers
	var/datum/antagonist/rat_king/king

/datum/objective/rat_king/coffers/New()
	target_amount = rand(3, 6)
	explanation_text = "Наполните королевскую казну [target_amount] раз."
	. = ..()

/datum/objective/rat_king/coffers/check_completion()
	if(!king || !king.owner || !king.owner.current)
		return FALSE
	var/mob/living/simple_animal/hostile/regalrat/rat_king = king.owner.current
	return istype(rat_king) && rat_king.coffers >= target_amount

/datum/objective/rat_king/chew
	var/datum/antagonist/rat_king/king

/datum/objective/rat_king/chew/New()
	target_amount = rand(4, 8)
	explanation_text = "Пусть ваши крысы перегрызут [target_amount] кабелей."
	. = ..()

/datum/objective/rat_king/chew/check_completion()
	if(!king || !king.owner || !king.owner.current)
		return FALSE
	var/mob/living/simple_animal/hostile/regalrat/rat_king = king.owner.current
	return istype(rat_king) && rat_king.cables_chewed >= target_amount

/datum/objective/rat_king/survive
	explanation_text = "Доживите до конца раунда."

/datum/objective/rat_king/survive/check_completion()
	return owner && owner.current && owner.current.stat != DEAD

/datum/antagonist/rat_king/lust
	name = "Крысиная королева"
	show_in_antagpanel = FALSE
	soft_antag = TRUE
	show_to_ghosts = TRUE
	threat = 0

/datum/antagonist/rat_king/lust/greet()
	to_chat(owner, span_purple("Вы - крысиная королева. Ваша власть - не когти, а очарование и мягкая лапа, ведущая мышей."))
	to_chat(owner, span_notice("Вы не обязаны никого убивать. Собирайте свиту, вейте гнездо и наслаждайтесь."))
	SEND_SOUND(owner.current, sound('sound/effects/mousesqueek.ogg'))

/datum/antagonist/rat_king/lust/forge_objectives()
	return

/datum/antagonist/rat_king/lust/roundend_report()
	if(!owner)
		return
	return "<div class='panel redborder'>[printplayer(owner)]<br>[span_purple("Крысиная королева плела своё гнездо и наслаждалась жизнью.")]</div>"

/datum/round_event_control/rat_king
	name = "Spawn Rat King"
	typepath = /datum/round_event/ghost_role/rat_king
	weight = 8
	max_occurrences = 1
	min_players = 20
	earliest_start = 15 MINUTES
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_GHOST
	cost = 8
	intensity = 12
	director_ghost_jobban = ROLE_RAT_KING
	director_ghost_preference = ROLE_RAT_KING
	family = "vermin"
	required_round_type = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_TEAMBASED)
	description = "Спавн короля крыс."

/datum/round_event/ghost_role/rat_king
	role_name = "Rat king"

/datum/round_event/ghost_role/rat_king/spawn_role()
	var/list/candidates = get_candidates(ROLE_RAT_KING, null, ROLE_RAT_KING)
	if(!length(candidates))
		return NOT_ENOUGH_PLAYERS
	var/mob/dead/observer/selected = pick_n_take(candidates)
	var/list/spawn_locs = find_exposed_wires()
	if(!length(spawn_locs))
		for(var/obj/effect/landmark/carpspawn/carp_spawn in GLOB.landmarks_list)
			if(isturf(carp_spawn.loc))
				spawn_locs += carp_spawn.loc
	if(!length(spawn_locs))
		return MAP_ERROR
	var/mob/living/simple_animal/hostile/regalrat/king = new(pick(spawn_locs))
	selected.transfer_ckey(king, FALSE)
	SSminor_mapping.trigger_migration(rand(8, 14))
	message_admins("[ADMIN_LOOKUPFLW(king)] превращен в короля крыс ивентом.")
	log_game("[key_name(king)] превращен в короля крыс ивентом.")
	spawned_mobs += king
	return SUCCESSFUL_SPAWN

// Квирк, который нужно перенести в особености.
/datum/quirk/rat_whisperer
	name = "Мышиный поводырь"
	desc = "Вы умеете тихо созывать мышей и отдавать им простые приказы следовать, собраться, разбежаться или играться с экипажем." // https://www.youtube.com/watch?v=-az3JEFZGuk
	value = 0
	mob_trait = TRAIT_RAT_WHISPERER
	gain_text = span_notice("Мыши смотрят на вас с доверием.") // https://i.pinimg.com/736x/dd/5b/8e/dd5b8e711899ca9acd7032baad1ce280.jpg
	lose_text = span_notice("Мыши больше не обращают на вас внимания.") // https://i.pinimg.com/736x/d0/84/83/d08483ada8ea7e468e1c3324bae12529.jpg
	medical_record_text = "Сообщалось, что пациент разговаривает с грызунами."
	var/datum/rat_horde/horde
	var/datum/action/cooldown/rat_order/order_action
	var/datum/action/cooldown/rat_order/call_mice/call_action

/datum/quirk/rat_whisperer/add()
	if(!quirk_holder || QDELETED(src))
		return
	. = ..()
	horde = new(quirk_holder, RAT_HORDE_SOFT)
	order_action = new
	order_action.horde = horde
	order_action.Grant(quirk_holder)
	call_action = new
	call_action.horde = horde
	call_action.Grant(quirk_holder)

/datum/quirk/rat_whisperer/remove()
	. = ..()
	if(order_action)
		order_action.Remove(quirk_holder)
		qdel(order_action)
		order_action = null
	if(call_action)
		call_action.Remove(quirk_holder)
		qdel(call_action)
		call_action = null
	if(horde)
		qdel(horde)
		horde = null

/datum/quirk/rat_whisperer/proc/get_horde()
	if(!horde || QDELETED(horde))
		horde = new(quirk_holder, RAT_HORDE_SOFT)
	return horde


// Статус друга. Появляется если скушать облизанную королем еду. Ну или если король облизал вас.

/datum/status_effect/rat_friend
	id = "rat_friend"
	duration = -1
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/rat_friend
	examine_text = "Пахнет крысами — грызуны считают вас своим."
	var/had_faction = FALSE
	var/betray_until = 0

/datum/status_effect/rat_friend/on_apply()
	. = ..()
	if(!owner)
		return FALSE
	had_faction = ("rat" in owner.faction)
	owner.faction += "rat"
	to_chat(owner, span_userdanger("С последним глотком вы чувствуете странное родство с крысами. Теперь они считают вас своим."))
	owner.visible_message(
		span_warning("[owner] вздрагивает, и в воздухе пахнет крысами."),
		span_notice("Крысы больше не будут вас атаковать. Не причиняйте им вред — родство разорвётся."),
	)
	return TRUE

/datum/status_effect/rat_friend/on_remove()
	. = ..()
	if(!owner)
		return
	if(!had_faction)
		owner.faction -= "rat"
	to_chat(owner, span_warning("Мышки больше не считают вас за друга..."))

/// Проверка на пидораса
/datum/status_effect/rat_friend/proc/handle_harm_attempt(mob/living/attacker, atom/target)
	if(!owner || attacker != owner || !isliving(target))
		return FALSE
	var/mob/living/living_target = target
	if(!("rat" in living_target.faction))
		return FALSE
	if(world.time < betray_until)
		betray(target)
		return FALSE
	betray_until = world.time + 15 SECONDS
	to_chat(owner, span_warning("Вы чувствуете, что предаёте крысиное родство. Ещё раз и оно разорвётся."))
	return TRUE

/datum/status_effect/rat_friend/proc/betray(atom/target)
	var/mob/living/traitor = owner
	owner.remove_status_effect(/datum/status_effect/rat_friend)
	if(!traitor)
		return
	traitor.visible_message(
		span_danger("[traitor] резко отдёргивается - крысиное родство разорвано!"),
		span_userdanger("Вы предали крыс."),
	)
	for(var/mob/living/simple_animal/hostile/regalrat/king in oview(RAT_HORDE_ORDER_RANGE, traitor))
		if(king.horde && !QDELETED(king.horde))
			king.horde.alert_betrayal(traitor)

/atom/movable/screen/alert/status_effect/rat_friend
	name = "Крысиный друг"
	desc = "Крысы и мыши не атакуют вас. Считайте это помилованием."
	icon_state = "in_love"

/// Перехватываем друга, если он пидорас
/proc/rat_friend_harm_intercept(mob/living/user, atom/target)
	if(!user)
		return FALSE
	var/datum/status_effect/rat_friend/friend = user.has_status_effect(/datum/status_effect/rat_friend)
	if(!friend)
		return FALSE
	return friend.handle_harm_attempt(user, target)

// Слюна крысюка. Будет действовать как 'друг', если передоз.

/datum/reagent/rat_spit
	name = "Крысиная слюна"
	description = "Что-то изо рта крысы. Господи, где она только не была!"
	color = "#C8C8C8"
	metabolization_rate = 0.03 * REAGENTS_METABOLISM
	taste_description = "yummers"
	overdose_threshold = 20

/datum/reagent/rat_spit/on_mob_metabolize(mob/living/affected_mob)
	. = ..()
	if(HAS_TRAIT(affected_mob, TRAIT_AGEUSIA))
		return
	to_chat(affected_mob, span_notice("У этой еды странный привкус!"))

/datum/reagent/rat_spit/overdose_start(mob/living/affected_mob)
	. = ..()
	if(!iscarbon(affected_mob))
		return
	var/mob/living/carbon/victim = affected_mob
	if(victim.has_status_effect(/datum/status_effect/rat_friend))
		return
	victim.vomit()
	victim.apply_status_effect(/datum/status_effect/rat_friend)
	for(var/datum/antagonist/rat_king/king in GLOB.antagonists)
		var/mob/king_mob = king.owner?.current
		if(king_mob && !QDELETED(king_mob) && get_dist(king_mob, victim) <= RAT_HORDE_ORDER_RANGE)
			var/infected_key = victim.mind || victim
			if(!(infected_key in king.infected_minds))
				king.infected_minds += infected_key
				king.infected++
			break
	metabolization_rate = 10 * REAGENTS_METABOLISM

/datum/reagent/rat_spit/on_mob_life(mob/living/carbon/affected_mob)
	. = ..()
	if(prob(15))
		to_chat(affected_mob, span_notice("Вам становится дурно. Вы дуреете."))
		affected_mob.adjust_disgust(3)
	else if(prob(10))
		to_chat(affected_mob, span_warning("Эта еда плохо лежит в желудке!"))
		affected_mob.adjust_disgust(5)
	else if(prob(5))
		affected_mob.vomit()
