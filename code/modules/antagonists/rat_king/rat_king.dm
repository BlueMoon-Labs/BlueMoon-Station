// Антагонист Рэт кинг.

/datum/antagonist/rat_king
	name = "Крысиный король"
	roundend_category = "Крысиные короли"
	antagpanel_category = "Rat King"
	job_rank = ROLE_RAT_KING
	show_in_antagpanel = TRUE
	show_name_in_check_antagonists = TRUE
	threat = 2
	blacklisted_quirks = list(/datum/quirk/nonviolent, /datum/quirk/mute, /datum/quirk/rat_whisperer)
	var/infected = 0
	/// Уже обращённые, чтобы не считать одного и того же дважды.
	var/list/infected_minds = list()
	var/domain_time = 0
	var/area/nest_area

/datum/antagonist/rat_king/greet()
	if(!owner)
		return
	to_chat(owner, span_boldannounce("Вы - крысиный король. Под вашими лапами техтоннели, а в зубах - жажда власти."))
	to_chat(owner, span_notice("Собирайте орду, распространяйте крысиную слюну и не дайте себя убить."))
	to_chat(owner, span_notice("Укажите цель, ваши милые подданые атакуют её."))
	owner.announce_objectives()
	if(owner.current)
		SEND_SOUND(owner.current, sound('sound/effects/mousesqueek.ogg'))

/datum/antagonist/rat_king/on_gain()
	forge_objectives()
	. = ..()

/datum/antagonist/rat_king/proc/forge_objectives()
	if(length(objectives) || !owner)
		return
	var/datum/objective/rat_king/claim/claim_objective = new
	claim_objective.king = src
	objectives += claim_objective

	var/datum/objective/rat_king/horde/horde_objective = new
	horde_objective.king = src
	objectives += horde_objective

	var/datum/objective/rat_king/lick_target/lick_objective = new
	lick_objective.owner = owner
	lick_objective.king = src
	lick_objective.find_target()
	if(lick_objective.target)
		objectives += lick_objective
	else
		qdel(lick_objective)

	var/list/extras = list()
	var/datum/objective/rat_king/infect/infect_objective = new
	infect_objective.king = src
	extras += infect_objective
	var/datum/objective/rat_king/coffers/coffers_objective = new
	coffers_objective.king = src
	extras += coffers_objective
	var/datum/objective/rat_king/chew/chew_objective = new
	chew_objective.king = src
	extras += chew_objective

	var/datum/objective/rat_king/nest/nest_objective = new
	nest_objective.king = src
	nest_objective.pick_area()
	if(nest_objective.target_area)
		extras += nest_objective
	else
		qdel(nest_objective)

	var/list/chosen = list()
	for(var/i in 1 to min(2, length(extras)))
		chosen += pick_n_take(extras)
	for(var/datum/objective/objective as anything in extras)
		qdel(objective)
	objectives += chosen
	for(var/datum/objective/objective as anything in chosen)
		if(istype(objective, /datum/objective/rat_king/nest))
			var/datum/objective/rat_king/nest/nest = objective
			nest_area = nest.target_area

	var/datum/objective/rat_king/survive/survive_objective = new
	survive_objective.owner = owner
	objectives += survive_objective

/datum/antagonist/rat_king/roundend_report()
	if(!owner)
		return
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

/datum/objective/rat_king/claim
	var/datum/antagonist/rat_king/king
	explanation_text = "Вы — король крыс. Ваша задача найти подданных и захватить как можно больше территории. Дипломатия или сила — решать вам."

/datum/objective/rat_king/claim/check_completion()
	if(!king || !king.owner || !king.owner.current)
		return FALSE
	var/mob/living/simple_animal/hostile/regalrat/rat_king = king.owner.current
	if(!istype(rat_king) || !rat_king.horde || QDELETED(rat_king.horde))
		return FALSE
	return length(rat_king.horde.minions) > 0

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
	explanation_text = "Превратите [target_amount] членов экипажа в крысиных друзей - слюной или едой."
	. = ..()

/datum/objective/rat_king/infect/check_completion()
	if(!king)
		return FALSE
	return king.infected >= target_amount

/datum/objective/rat_king/coffers
	var/datum/antagonist/rat_king/king

/datum/objective/rat_king/coffers/New()
	target_amount = rand(3, 6)
	explanation_text = "Наполните королевскую казну [target_amount] раз способностью 'Наполнить казну'."
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
	explanation_text = "Пусть ваши крысы перегрызут [target_amount] кабелей и обесточат станцию."
	. = ..()

/datum/objective/rat_king/chew/check_completion()
	if(!king || !king.owner || !king.owner.current)
		return FALSE
	var/mob/living/simple_animal/hostile/regalrat/rat_king = king.owner.current
	return istype(rat_king) && rat_king.cables_chewed >= target_amount

/datum/objective/rat_king/lick_target
	var/datum/antagonist/rat_king/king

/datum/objective/rat_king/lick_target/New()
	explanation_text = "Оближите выбранную цель и сделайте её крысиным другом."
	. = ..()

/datum/objective/rat_king/lick_target/update_explanation_text()
	if(target?.current)
		explanation_text = "Оближите [target.current.real_name] и сделайте [target.current.p_them()] крысиным другом."
	else
		explanation_text = "Оближите выбранную цель и сделайте её крысиным другом."

/datum/objective/rat_king/lick_target/check_completion()
	if(!king || !target)
		return FALSE
	if(!(target in king.infected_minds))
		return FALSE
	var/mob/living/victim = target.current
	if(!istype(victim) || QDELETED(victim))
		return FALSE
	return victim.has_status_effect(/datum/status_effect/rat_friend)

/datum/objective/rat_king/nest
	var/datum/antagonist/rat_king/king
	var/area/target_area

/datum/objective/rat_king/nest/New()
	target_amount = rand(30, 60)
	explanation_text = "Обоснуйтесь как следует, удержите одну из точек на станции."
	. = ..()

/datum/objective/rat_king/nest/proc/pick_area()
	var/static/list/nest_area_types = list(
		/area/service/kitchen,
		/area/service/bar,
		/area/cargo/storage,
		/area/medical/medbay/central,
		/area/engineering/main,
		/area/science/research,
		/area/security/brig,
		/area/command/bridge,
	)
	var/list/valid_areas = list()
	for(var/area_type in nest_area_types)
		var/area/A = locate(area_type)
		if(A)
			valid_areas += A
	if(!length(valid_areas))
		return
	target_area = pick(valid_areas)
	explanation_text = "Захватите [target_area.name]: проведите там [target_amount] секунд с активными 'Владениями' и превратите место в гнездо."

/datum/objective/rat_king/nest/check_completion()
	if(!king || !king.owner || !king.owner.current)
		return FALSE
	return king.domain_time >= target_amount

/datum/objective/rat_king/survive
	explanation_text = "Переживите охоту на крыс: доживите до конца раунда, не потеряв корону."

/datum/objective/rat_king/survive/check_completion()
	return owner && owner.current && owner.current.stat != DEAD

/datum/antagonist/rat_king/lust
	name = "Крысиная королева"
	show_in_antagpanel = FALSE
	soft_antag = TRUE
	show_to_ghosts = TRUE
	threat = 0

/datum/antagonist/rat_king/lust/greet()
	if(!owner)
		return
	to_chat(owner, span_purple("Вы - крысиная королева. Ваша власть - не когти, а очарование и мягкая лапа, ведущая мышей."))
	to_chat(owner, span_notice("Вы не обязаны никого убивать. Собирайте свиту, вейте гнездо и наслаждайтесь."))
	to_chat(owner, span_notice("Взмах вашей лапки заставит мышек полюбить ближнего своего."))
	if(owner.current)
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
	cost = 6
	intensity = 8
	director_ghost_jobban = ROLE_RAT_KING
	director_ghost_preference = ROLE_RAT_KING
	family = "vermin"
	required_round_type = list(ROUNDTYPE_DYNAMIC_LIGHT, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_TEAMBASED)
	description = "Спавн короля крыс."

/datum/round_event/ghost_role/rat_king
	role_name = "Rat king"

/datum/round_event/ghost_role/rat_king/spawn_role()
	var/list/spawn_locs = find_exposed_wires()
	if(!length(spawn_locs))
		for(var/obj/effect/landmark/carpspawn/carp_spawn in GLOB.landmarks_list)
			if(isturf(carp_spawn.loc))
				spawn_locs += carp_spawn.loc
	if(!length(spawn_locs))
		return MAP_ERROR
	var/mob/living/simple_animal/hostile/regalrat/king = new /mob/living/simple_animal/hostile/regalrat/controlled(pick(spawn_locs))
	SSminor_mapping.trigger_migration(rand(8, 14))
	message_admins("[ADMIN_LOOKUPFLW(king)] создан как король крыс. Гост-роль предложена призракам.")
	log_game("[key_name(king)] создан как король крыс; гост-роль предложена призракам.")
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
	if(!quirk_holder || QDELETED(src) || QDELETED(quirk_holder))
		return
	. = ..()
	horde = new(quirk_holder, RAT_HORDE_SOFT)
	order_action = new
	order_action.horde = horde
	order_action.Grant(quirk_holder)
	call_action = new
	call_action.horde = horde
	call_action.Grant(quirk_holder)
	RegisterSignal(quirk_holder, COMSIG_MOB_POINTED, PROC_REF(on_pointed))

/datum/quirk/rat_whisperer/remove()
	. = ..()
	if(quirk_holder && !QDELETED(quirk_holder))
		UnregisterSignal(quirk_holder, COMSIG_MOB_POINTED)
		if(order_action)
			order_action.Remove(quirk_holder)
		if(call_action)
			call_action.Remove(quirk_holder)
	if(order_action)
		qdel(order_action)
		order_action = null
	if(call_action)
		qdel(call_action)
		call_action = null
	if(horde)
		qdel(horde)
		horde = null

/datum/quirk/rat_whisperer/proc/get_horde()
	if(!quirk_holder)
		return null
	if(!horde || QDELETED(horde))
		horde = new(quirk_holder, RAT_HORDE_SOFT)
	return horde

/datum/quirk/rat_whisperer/proc/on_pointed(datum/source, atom/target)
	SIGNAL_HANDLER
	if(!target || QDELETED(target) || target == quirk_holder || !isliving(target))
		return
	var/datum/rat_horde/rat_horde = get_horde()
	if(rat_horde)
		rat_horde.issue_order(RAT_ORDER_PLAY, target, get_turf(target))

/datum/quirk/rat_whisperer/transfer_mob(mob/living/to_mob)
	var/mob/living/old_holder = quirk_holder
	. = ..()
	if(!quirk_holder || QDELETED(src) || QDELETED(quirk_holder))
		return
	if(old_holder && old_holder != quirk_holder && !QDELETED(old_holder))
		UnregisterSignal(old_holder, COMSIG_MOB_POINTED)
	RegisterSignal(quirk_holder, COMSIG_MOB_POINTED, PROC_REF(on_pointed))
	if(order_action)
		order_action.Grant(quirk_holder)
	if(call_action)
		call_action.Grant(quirk_holder)
	if(horde)
		horde.set_leader(quirk_holder)


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
	var/datum/quirk/rat_whisperer/quirk = locate(/datum/quirk/rat_whisperer) in traitor.roundstart_quirks
	if(quirk?.horde && !QDELETED(quirk.horde))
		quirk.horde.alert_betrayal(traitor)
	for(var/mob/living/simple_animal/hostile/regalrat/king in oview(RAT_HORDE_ORDER_RANGE, traitor))
		if(king.horde && !QDELETED(king.horde))
			king.horde.alert_betrayal(traitor)

/atom/movable/screen/alert/status_effect/rat_friend
	name = "Крысиный друг"
	desc = "Крысы и мыши не атакуют вас. Считайте это помилованием."
	icon_state = "in_love"

/// Перехватываем друга, если он пидорас
/proc/rat_friend_harm_intercept(mob/living/user, atom/target)
	if(!user || QDELETED(user))
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
	SEND_SIGNAL(affected_mob, COMSIG_ADD_MOOD_EVENT, "[type]_overdose", /datum/mood_event/overdose, name)
	to_chat(affected_mob, span_userdanger("Вы чувствуете, что приняли слишком много крысиной слюны!"))
	if(!iscarbon(affected_mob))
		return
	var/mob/living/carbon/victim = affected_mob
	if(victim.has_status_effect(/datum/status_effect/rat_friend))
		return
	victim.vomit()
	victim.apply_status_effect(/datum/status_effect/rat_friend)
	var/mob/living/source
	if(data)
		source = data["source"]
	if(source && !QDELETED(source))
		var/datum/antagonist/rat_king/king = source.mind?.has_antag_datum(/datum/antagonist/rat_king)
		if(king)
			var/infected_key = victim.mind || victim
			if(!(infected_key in king.infected_minds))
				king.infected_minds += infected_key
				king.infected++
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
