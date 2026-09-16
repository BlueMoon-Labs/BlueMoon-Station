#define HERETIC_BLOOD_RANGE 5
#define HERETIC_BLOOD_HARVEST_TIME (2 SECONDS)
#define HERETIC_BLOOD_HEALTH_RESERVE 25
#define HERETIC_BLOOD_LINK_LIFETIME (15 SECONDS)
#define HERETIC_BLOOD_COLLECTION_DELAY (1 SECONDS)
#define HERETIC_BLOOD_CONTACT_GRACE (2 SECONDS)
#define HERETIC_BLOOD_REFUND_LIMIT 10
#define HERETIC_BLOOD_REFUND_MULTIPLIER 2
#define HERETIC_BLOOD_REFUND_COOLDOWN (12 SECONDS)
#define HERETIC_BLOOD_SIPHON_FRACTION 0.25
#define HERETIC_BLOOD_SIPHON_LIMIT 10
#define HERETIC_BLOOD_UPGRADED_SIPHON_FRACTION 0.5
#define HERETIC_BLOOD_UPGRADED_SIPHON_LIMIT 20
#define HERETIC_BLOOD_INITIAL_DEBT 10
#define HERETIC_BLOOD_STRIKE_DEBT 6
#define HERETIC_BLOOD_LANCE_DAMAGE 18
#define HERETIC_BLOOD_LANCE_PULL 3
#define HERETIC_BLOOD_RUSH_DURATION (6 SECONDS)
#define HERETIC_BLOOD_PACT_PAYMENT 10
#define HERETIC_BLOOD_PARTIAL_COLLECTION 10
#define HERETIC_BLOOD_RECOVERY_FRACTION 0.25
#define HERETIC_BLOOD_RECOVERY_LIMIT 10
#define HERETIC_BLOOD_CLOT_DURATION (8 SECONDS)
#define HERETIC_BLOOD_CLOT_MULTIPLIER 0.5

/datum/heretic_path/blood
	id = PATH_BLOOD
	deed_type = /datum/heretic_deed/blood
	name = "Кровь"
	desc = "Притягивайте врагов, накапливайте кровный долг ударами и залечивайте свои раны при взыскании. Чаша отдаёт больше крови на лечение."
	strengths = "Быстрое накопление долга, притяжение и лечение ушибов и ожогов за фактический урон врагу. Взыскание восполняет кровь и временно вдвое ослабляет кровотечение."
	weaknesses = "Чтобы взыскать долг, нужно удержать прямую видимость в пяти клетках в течение секунды. Укрытие или оглушение срывает взыскание; антимагия разрывает связь."
	knowledge = list(
		/datum/eldritch_knowledge/base_blood,
		/datum/eldritch_knowledge/blood_grasp,
		/datum/eldritch_knowledge/spell/blood_lance,
		/datum/eldritch_knowledge/blood_mark,
		/datum/eldritch_knowledge/blood_relic,
		/datum/eldritch_knowledge/blood_upgrade,
		/datum/eldritch_knowledge/spell/blood_pact,
		/datum/eldritch_knowledge/blood_vigor,
		/datum/eldritch_knowledge/spell/blood_reckoning,
		/datum/eldritch_knowledge/final_eldritch/blood_final,
	)

/datum/eldritch_knowledge/base_blood
	name = "Первая подпись"
	desc = "Нож и стеклянный осколок создают багровый ланцет. Удар клинком сам связывает врага и добавляет долг раз в 2 секунды. «Связать / взыскать» создаёт связь на расстоянии или взыскивает долг после секунды предупреждения. В намерении «Разоружить» взыскивается до 10 долга с сохранением остатка и прежнего срока связи. Четверть нанесённого взысканием урона лечит ваши ушибы и ожоги, суммарно до 10 за одну связь. Дополнительно 25% фактического урона восполняет кровь до нормы вашего тела, не более 10 единиц за связь, а кровотечение ослабевает вдвое на 8 секунд. Повторное взыскание обновляет длительность; частичные взыскания делят предел восполнения крови. Держитесь в пяти клетках без преград."
	gain_text = "На белом листе появилась капля. Подпись уже была моей."
	route = PATH_BLOOD
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/shard)
	result_atoms = list(/obj/item/melee/sickly_blade/blood)
	combat_resource = 0
	combat_resource_max = 20
	combat_resource_name = "Кровный долг"
	combat_resource_desc = "«Связать / взыскать»: новый враг — связь, свой должник — урон через секунду и лечение ваших ран. Взыскание также восполняет кровь на 25% фактического урона, до 10 единиц за связь и до нормы тела, и вдвое ослабляет кровотечение на 8 секунд. В намерении «Разоружить» взыскивается до 10 долга с сохранением остатка и общих пределов лечения. Клинок добавляет долг раз в 2 секунды и продлевает связь. Чаша расходует долг на усиленное лечение; Договор покупает ускорение вашими ранами."
	combat_resource_action = /obj/effect/proc_holder/spell/pointed/heretic_blood/release
	grasp_visual = /obj/effect/temp_visual/heretic_blood/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/blood_grasp.ogg'
	var/mob/living/blood_body
	var/list/datum/status_effect/heretic_blood_seal/seals = list()
	var/list/datum/status_effect/eldritch/blood/marks = list()
	var/list/obj/effect/temp_visual/heretic_blood/visuals = list()
	var/blood_generation = 0
	var/link_limit = 1
	var/debt_cap = 20
	var/datum/status_effect/heretic_blood_rush/blood_rush
	var/datum/status_effect/heretic_blood_clot/blood_clot

/datum/eldritch_knowledge/base_blood/on_body_gain(mob/living/user)
	if(!user?.mind || blood_body == user)
		return
	if(blood_body)
		on_body_lose(blood_body)
	blood_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	RegisterSignal(user, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(on_health_changed))
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_body_moved))
	grant_combat_power(user)
	update_capacity()

/datum/eldritch_knowledge/base_blood/on_body_lose(mob/living/user)
	if(blood_body)
		UnregisterSignal(blood_body, list(COMSIG_PARENT_QDELETING, COMSIG_CARBON_UPDATEHEALTH, COMSIG_MOVABLE_MOVED))
	blood_body = null
	remove_combat_power()
	clear_blood()

/datum/eldritch_knowledge/base_blood/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(blood_body)

/datum/eldritch_knowledge/base_blood/proc/on_health_changed(datum/source)
	SIGNAL_HANDLER
	validate_links()

/datum/eldritch_knowledge/base_blood/proc/on_body_moved(datum/source)
	SIGNAL_HANDLER
	validate_links()

/datum/eldritch_knowledge/base_blood/on_life(mob/user)
	validate_links()

/datum/eldritch_knowledge/base_blood/on_death(mob/user)
	clear_blood()

/datum/eldritch_knowledge/base_blood/Destroy()
	on_body_lose(blood_body)
	return ..()

/datum/eldritch_knowledge/base_blood/proc/clear_blood()
	blood_generation++
	QDEL_LIST(seals)
	QDEL_LIST(marks)
	QDEL_LIST(visuals)
	QDEL_NULL(blood_rush)
	QDEL_NULL(blood_clot)
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_blood/proc/can_maintain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && !QDELETED(user) && isliving(user) && user == blood_body && user.stat == CONSCIOUS && isturf(user.loc) && heretic?.selected_path == PATH_BLOOD && !heretic.role_removed && heretic.get_knowledge(type) == src

/datum/eldritch_knowledge/base_blood/proc/can_use(mob/living/user)
	return can_maintain(user) && !user.incapacitated()

/datum/eldritch_knowledge/base_blood/proc/can_use_ascension(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/final_eldritch/blood_final/final_knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/blood_final)
	return !QDELETED(src) && user && user == blood_body && heretic?.ascended && heretic.selected_path == PATH_BLOOD && !heretic.role_removed && heretic.get_knowledge(type) == src && !QDELETED(final_knowledge) && final_knowledge.finished && final_knowledge.applied_body == user

/datum/eldritch_knowledge/base_blood/proc/line_clear(atom/start, atom/end, max_distance = HERETIC_BLOOD_RANGE)
	var/turf/origin = get_turf(start)
	var/turf/destination = get_turf(end)
	if(!origin || !destination || origin.z != destination.z || get_dist(origin, destination) > max_distance)
		return FALSE
	for(var/turf/tile as anything in get_line(origin, destination))
		if(!isopenturf(tile) || tile.is_blocked_turf(exclude_mobs = TRUE))
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_blood/proc/valid_victim(mob/living/user, atom/target)
	if(!can_use(user) || !isliving(target))
		return FALSE
	var/mob/living/victim = target
	return victim.stat != DEAD && victim != user && !IS_HERETIC(victim) && !IS_HERETIC_MONSTER(victim) && isturf(victim.loc) && line_clear(user, victim)

/datum/eldritch_knowledge/base_blood/proc/validate_links()
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in seals.Copy())
		seal.validate_link()

/datum/eldritch_knowledge/base_blood/proc/pay_health(mob/living/user, amount)
	if(!can_use(user) || amount <= 0)
		return 0
	var/damage_multiplier = max(1, CONFIG_GET(number/damage_multiplier))
	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		var/wound_multiplier = 1
		for(var/obj/item/bodypart/bodypart as anything in carbon_user.get_damageable_bodyparts())
			wound_multiplier = max(wound_multiplier, bodypart.wound_damage_multiplier)
		// Переполнение конечности повторно применяет множитель к груди.
		damage_multiplier = (damage_multiplier * wound_multiplier) ** 2
	if(user.health <= HERETIC_BLOOD_HEALTH_RESERVE + amount * damage_multiplier)
		return 0
	var/damage_before = user.getBruteLoss()
	var/expected_generation = blood_generation
	user.adjustBruteLoss(amount, forced = TRUE, only_organic = FALSE)
	if(QDELETED(src) || QDELETED(user) || blood_generation != expected_generation || !can_use(user))
		return 0
	return max(0, user.getBruteLoss() - damage_before)

/datum/eldritch_knowledge/base_blood/proc/update_capacity(ignore_vigor = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(blood_body)
	var/datum/eldritch_knowledge/blood_vigor/vigor = heretic?.get_knowledge(/datum/eldritch_knowledge/blood_vigor)
	if(ignore_vigor || QDELETED(vigor))
		vigor = null
	link_limit = vigor ? (vigor.passive_level == 3 ? 3 : 2) : initial(link_limit)
	debt_cap = vigor ? vigor.passive_values[vigor.passive_level] : initial(debt_cap)
	if(can_use_ascension(blood_body))
		link_limit = 3
		debt_cap = 30
	while(length(seals) > link_limit)
		qdel(seals[length(seals)])
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in seals)
		seal.debt = min(seal.debt, debt_cap)
	update_debt()

/datum/eldritch_knowledge/base_blood/proc/update_debt()
	combat_resource = 0
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in seals)
		combat_resource += seal.debt
	combat_resource_max = link_limit * debt_cap
	notify_resource_changed()

/datum/eldritch_knowledge/base_blood/get_combat_resource_data()
	var/list/data = ..()
	data["value"] = round(combat_resource, 0.1)
	data["description"] = "[combat_resource_desc] Связей: [length(seals)]/[link_limit]."
	if(length(seals))
		data["description"] += " Чтобы нанести урон, нажмите индикатор долга и укажите своего должника. Хватка и клинок сами долг не взыскивают."
	else
		data["description"] += " Нажмите индикатор долга и укажите врага, чтобы создать связь."
	var/datum/antagonist/heretic/heretic = IS_HERETIC(blood_body)
	var/datum/eldritch_knowledge/upgrade = heretic?.get_knowledge(/datum/eldritch_knowledge/blood_upgrade)
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in seals)
		var/expected_damage = (seal.collecting ? seal.collection_amount : seal.debt) * (QDELETED(upgrade) ? 2 : 2.25)
		data["description"] += " [html_encode(seal.owner.name)]: [round(seal.debt, 0.1)]/[debt_cap] долга → [round(expected_damage, 0.1)] ушибов[seal.collecting ? "; взыскание началось" : (!isnull(seal.contact_lost_at) ? "; связь слабеет" : "")]."
	return data

/datum/eldritch_knowledge/base_blood/on_mark_detonated(mob/living/user, mob/living/target)
	return

/datum/eldritch_knowledge/base_blood/gain_combat_resource(amount = 1)
	return

/datum/eldritch_knowledge/base_blood/spend_combat_resource(amount = 1)
	return FALSE

/datum/eldritch_knowledge/base_blood/proc/invest(mob/living/user, list/candidates, amount, renew = FALSE, allow_unlinked = FALSE)
	if(!can_use(user))
		return FALSE
	var/list/available = list()
	var/room = 0
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in candidates)
		if(QDELETED(seal) || seal.blood_ref?.resolve() != src || seal.collecting || !seal.validate_link() || seal.debt >= debt_cap)
			continue
		available += seal
		room += debt_cap - seal.debt
	if(!allow_unlinked && (!length(available) || room <= 0))
		return FALSE
	var/payment = pay_health(user, allow_unlinked ? amount : min(amount, room))
	if(!payment)
		return FALSE
	var/remaining = min(payment, room)
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in available)
		if(QDELETED(seal) || !seal.validate_link())
			continue
		var/portion = min(remaining, debt_cap - seal.debt)
		seal.debt += portion
		remaining -= portion
		if(renew)
			seal.expires_at = world.time + HERETIC_BLOOD_LINK_LIFETIME
		if(remaining <= 0)
			break
	update_debt()
	new /obj/effect/temp_visual/heretic_blood/pact(get_turf(user), src)
	return TRUE

/datum/eldritch_knowledge/base_blood/proc/release(mob/living/user, mob/living/victim, partial = FALSE)
	if(!valid_victim(user, victim))
		return FALSE
	var/datum/status_effect/heretic_blood_seal/existing = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(existing)
		return existing.blood_ref?.resolve() == src && existing.begin_collection(src, partial ? HERETIC_BLOOD_PARTIAL_COLLECTION : null)
	if(length(seals) >= link_limit)
		to_chat(user, span_warning("Все кровные связи заняты. Взыщите долг прежнего врага кнопкой «Связать / взыскать» или разорвите связь отходом."))
		return FALSE
	if(!heretic_can_affect(user, victim))
		return TRUE
	var/datum/status_effect/heretic_blood_seal/seal = victim.apply_status_effect(/datum/status_effect/heretic_blood_seal, src)
	if(QDELETED(seal))
		return FALSE
	seal.debt = min(HERETIC_BLOOD_INITIAL_DEBT, debt_cap)
	update_debt()
	to_chat(user, span_notice("[victim] связан: [seal.debt] долга. Ещё раз «Связать / взыскать» по этой цели — нанести урон; клинок — накопить больше."))
	playsound(victim, 'modular_bluemoon/sound/heretic/blood_release.ogg', 45, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_blood/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag || !valid_victim(user, target) || !COOLDOWN_FINISHED(src, resource_harvest) || !heretic_can_affect(user, target, chargecost = 0))
		return
	var/mob/living/victim = target
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(!seal && release(user, victim))
		seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(add_debt(seal, HERETIC_BLOOD_STRIKE_DEBT, renew = TRUE))
		COOLDOWN_START(src, resource_harvest, HERETIC_BLOOD_HARVEST_TIME)

/datum/eldritch_knowledge/base_blood/proc/add_debt(datum/status_effect/heretic_blood_seal/seal, amount, renew = FALSE)
	if(QDELETED(seal) || seal.blood_ref?.resolve() != src || seal.collecting || !seal.validate_link())
		return FALSE
	var/previous_debt = seal.debt
	seal.debt = min(debt_cap, seal.debt + amount)
	if(renew)
		seal.expires_at = max(seal.expires_at, world.time + HERETIC_BLOOD_LINK_LIFETIME)
	update_debt()
	if(previous_debt < debt_cap && seal.debt >= debt_cap)
		to_chat(blood_body, span_notice("Долг [seal.owner] заполнен. «Связать / взыскать» нанесёт накопленный урон; чаша обменяет часть долга на лечение."))
	return TRUE

/datum/eldritch_knowledge/base_blood/proc/lance(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/blood_lance)
	if(QDELETED(required) || !valid_victim(user, victim))
		return FALSE
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(seal && (seal.blood_ref?.resolve() != src || seal.collecting))
		return FALSE
	if(!heretic_can_affect(user, victim))
		qdel(seal)
		return TRUE
	if(!seal && release(user, victim))
		seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	add_debt(seal, HERETIC_BLOOD_STRIKE_DEBT, renew = TRUE)
	victim.adjustBruteLoss(HERETIC_BLOOD_LANCE_DAMAGE)
	if(!can_use(user) || QDELETED(victim) || victim.stat == DEAD)
		return TRUE
	for(var/pull_step in 1 to HERETIC_BLOOD_LANCE_PULL)
		if(victim.anchored || victim.buckled || get_dist(user, victim) <= 1 || !valid_victim(user, victim))
			break
		step_towards(victim, user)
	var/obj/effect/temp_visual/heretic_blood/lance/visual = new(get_turf(victim), src)
	visual.setDir(get_dir(victim, user))
	playsound(victim, 'modular_bluemoon/sound/heretic/blood_grasp.ogg', 45, TRUE)
	log_combat(user, victim, "натягивает кровную связь с")
	return TRUE

/datum/eldritch_knowledge/base_blood/proc/pact(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/blood_pact)
	if(QDELETED(required))
		return FALSE
	if(!invest(user, seals.Copy(), HERETIC_BLOOD_PACT_PAYMENT, renew = TRUE, allow_unlinked = TRUE))
		if(can_use(user))
			to_chat(user, span_warning("Для Договора слишком мало здоровья: новая рана оставит меньше безопасного запаса."))
		return FALSE
	user.apply_status_effect(/datum/status_effect/heretic_blood_rush, src)
	blood_rush = user.has_status_effect(/datum/status_effect/heretic_blood_rush)
	user.visible_message(span_danger("[user] проводит пальцами по свежей ране и резко ускоряется!"))
	return TRUE

/datum/status_effect/heretic_blood_rush
	id = "heretic_blood_rush"
	duration = HERETIC_BLOOD_RUSH_DURATION
	tick_interval = 0.5 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_blood_rush
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/blood_ref

/datum/status_effect/heretic_blood_rush/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_blood/blood)
	if(QDELETED(blood))
		qdel(src)
		return
	blood_ref = WEAKREF(blood)
	return ..()

/datum/status_effect/heretic_blood_rush/on_apply()
	if(!..())
		return FALSE
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_rush)
	return TRUE

/datum/status_effect/heretic_blood_rush/on_remove()
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(blood?.blood_rush == src)
		blood.blood_rush = null
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_rush)
	return ..()

/datum/status_effect/heretic_blood_rush/tick()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(owner)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!blood?.can_use(owner) || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/blood_pact))
		qdel(src)

/datum/movespeed_modifier/heretic_blood_rush
	multiplicative_slowdown = -0.35

/atom/movable/screen/alert/status_effect/heretic_blood_rush
	name = "Горячая кровь"
	desc = "Договор с раной ускоряет вас на 6 секунд. Ускорение не защищает от оглушения и не позволяет пройти сквозь препятствия."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_blood"

/datum/eldritch_knowledge/base_blood/proc/reckoning(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/blood_reckoning)
	if(!can_use(user) || QDELETED(required))
		return FALSE
	var/started = FALSE
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in seals.Copy())
		if(!valid_victim(user, seal.owner))
			continue
		add_debt(seal, HERETIC_BLOOD_STRIKE_DEBT, renew = TRUE)
		if(seal.begin_collection(required))
			started = TRUE
	if(started)
		playsound(user, 'modular_bluemoon/sound/heretic/blood_reckoning.ogg', 70, TRUE)
	return started

/datum/eldritch_knowledge/base_blood/proc/coronation(mob/living/user, mob/living/victim)
	if(!can_use(user) || !can_use_ascension(user) || !valid_victim(user, victim))
		return FALSE
	var/datum/status_effect/heretic_blood_seal/chosen = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(chosen?.blood_ref?.resolve() != src || chosen.collecting || !chosen.validate_link())
		return FALSE
	for(var/datum/status_effect/heretic_blood_seal/donor as anything in seals.Copy())
		if(donor == chosen || donor.collecting || !donor.validate_link())
			continue
		var/transferred = min(donor.debt, debt_cap - chosen.debt)
		chosen.debt += transferred
		donor.debt -= transferred
		if(donor.debt <= 0)
			qdel(donor)
	chosen.expires_at = world.time + HERETIC_BLOOD_LINK_LIFETIME
	update_debt()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return chosen.begin_collection(heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/blood_final))

/datum/eldritch_knowledge/base_blood/proc/mend_wounds(mob/living/user, amount)
	if(!can_use(user) || amount <= 0)
		return 0
	var/old_brute = user.getBruteLoss()
	var/old_burn = user.getFireLoss()
	user.adjustBruteLoss(-min(amount, old_brute), forced = TRUE, only_organic = FALSE)
	if(!can_use(user))
		return 0
	var/healed_brute = max(0, old_brute - user.getBruteLoss())
	user.adjustFireLoss(-min(max(0, amount - healed_brute), old_burn), forced = TRUE, only_organic = FALSE)
	if(!can_use(user))
		return 0
	return healed_brute + max(0, old_burn - user.getFireLoss())

/datum/eldritch_knowledge/base_blood/proc/recover_blood(mob/living/user, amount)
	if(!can_use(user) || !ishuman(user))
		return 0
	var/mob/living/carbon/human/human_user = user
	if((NOBLOOD in human_user.dna.species.species_traits) || !human_user.get_blood_id())
		return 0
	var/recovered = min(max(0, amount), max(0, BLOOD_VOLUME_NORMAL * human_user.blood_ratio - human_user.blood_volume - human_user.integrating_blood))
	human_user.blood_volume += recovered
	human_user.apply_status_effect(/datum/status_effect/heretic_blood_clot, src)
	blood_clot = human_user.has_status_effect(/datum/status_effect/heretic_blood_clot)
	if(recovered > 0)
		to_chat(user, span_notice("Взыскание восполняет [round(recovered, 0.1)] единиц вашей крови."))
	return recovered

/datum/status_effect/heretic_blood_clot
	id = "heretic_blood_clot"
	duration = HERETIC_BLOOD_CLOT_DURATION
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_blood_clot
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/blood_ref
	var/datum/physiology/affected_physiology

/datum/status_effect/heretic_blood_clot/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_blood/blood)
	if(QDELETED(blood))
		qdel(src)
		return
	blood_ref = WEAKREF(blood)
	return ..()

/datum/status_effect/heretic_blood_clot/on_apply()
	if(!..() || !ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/human_owner = owner
	affected_physiology = human_owner.physiology
	affected_physiology.bleed_mod *= HERETIC_BLOOD_CLOT_MULTIPLIER
	to_chat(owner, span_notice("Ваша кровь густеет: кровотечение ослаблено вдвое на 8 секунд."))
	return TRUE

/datum/status_effect/heretic_blood_clot/on_remove()
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(blood?.blood_clot == src)
		blood.blood_clot = null
	if(!QDELETED(affected_physiology))
		affected_physiology.bleed_mod /= HERETIC_BLOOD_CLOT_MULTIPLIER
	affected_physiology = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_blood_clot
	name = "Свёртывание крови"
	desc = "Взыскание вдвое уменьшает потерю крови от кровотечения на 8 секунд. Новое успешное взыскание обновляет длительность. Раны остаются и требуют лечения."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_blood"

/datum/eldritch_knowledge/base_blood/proc/refund(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/blood_relic)
	if(!can_use(user) || QDELETED(required) || !valid_victim(user, victim))
		return FALSE
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(seal?.blood_ref?.resolve() != src || seal.collecting || !seal.validate_link())
		return FALSE
	var/payment = min(HERETIC_BLOOD_REFUND_LIMIT, seal.debt, (user.getBruteLoss() + user.getFireLoss()) / HERETIC_BLOOD_REFUND_MULTIPLIER)
	if(payment <= 0)
		return FALSE
	seal.debt -= payment
	var/drain = payment * HERETIC_BLOOD_REFUND_MULTIPLIER
	var/expected_generation = blood_generation
	var/damage_before = victim.getBruteLoss()
	victim.adjustBruteLoss(drain)
	if(QDELETED(src) || !can_use(user) || blood_generation != expected_generation || QDELETED(victim))
		return TRUE
	var/healed = mend_wounds(user, min(drain, max(0, victim.getBruteLoss() - damage_before)))
	if(QDELETED(src) || !can_use(user) || blood_generation != expected_generation)
		return TRUE
	if(!QDELETED(seal) && seal.debt <= 0)
		qdel(seal)
	else
		update_debt()
	to_chat(user, span_notice("Чаша залечивает [round(healed, 0.1)] ушибов и ожогов.[QDELETED(seal) ? " Долг исчерпан; можно связать новую цель." : " Остаток долга [victim]: [round(seal.debt, 0.1)]."]"))
	new /obj/effect/temp_visual/heretic_blood/pact(get_turf(user), src)
	return TRUE

/datum/status_effect/heretic_blood_seal
	id = "heretic_blood_seal"
	duration = -1
	tick_interval = 0.25 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_blood_seal
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/blood_ref
	var/datum/weakref/collection_knowledge_ref
	var/datum/beam/link_beam
	var/mutable_appearance/seal_overlay
	var/debt = 0
	var/expires_at
	var/collecting = FALSE
	var/collection_ready_at
	var/collection_timer
	var/collection_amount
	var/siphoned = 0
	var/blood_recovered = 0
	var/expected_generation
	var/contact_lost_at

/datum/status_effect/heretic_blood_seal/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_blood/blood)
	if(QDELETED(blood))
		qdel(src)
		return
	blood_ref = WEAKREF(blood)
	expected_generation = blood.blood_generation
	expires_at = world.time + HERETIC_BLOOD_LINK_LIFETIME
	seal_overlay = mutable_appearance('modular_bluemoon/icons/obj/heretic_blood_effects.dmi', "blood_mark", ABOVE_MOB_LAYER)
	return ..()

/datum/status_effect/heretic_blood_seal/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(!blood?.valid_victim(blood.blood_body, owner) || length(blood.seals) >= blood.link_limit)
		return FALSE
	blood.seals += src
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(update_seal_overlay))
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_owner_death))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_owner_moved))
	owner.update_icon()
	link_beam = new(blood.blood_body, owner, 'modular_bluemoon/icons/obj/heretic_blood_effects.dmi', "blood_link", INFINITY, HERETIC_BLOOD_RANGE + 1, /obj/effect/ebeam, null)
	link_beam.Draw()
	to_chat(owner, span_userdanger("От вас к [blood.blood_body] тянется кровяная жила. Его удары увеличивают долг, а взыскание лечит его! Скройтесь за преградой или отойдите дальше пяти клеток на две секунды. Если взыскание уже началось, потеря контакта сразу его сорвёт."))
	return TRUE

/datum/status_effect/heretic_blood_seal/proc/update_seal_overlay(atom/source, list/overlays)
	SIGNAL_HANDLER
	overlays += seal_overlay

/datum/status_effect/heretic_blood_seal/proc/on_owner_death(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_blood_seal/proc/on_owner_moved(datum/source)
	SIGNAL_HANDLER
	validate_link()

/datum/status_effect/heretic_blood_seal/tick()
	validate_link()

/datum/status_effect/heretic_blood_seal/proc/validate_link()
	if(QDELETED(src))
		return FALSE
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(!blood || blood.blood_generation != expected_generation || world.time >= expires_at || !blood.can_maintain(blood.blood_body) || QDELETED(owner) || owner.stat == DEAD || owner == blood.blood_body || IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner) || !isturf(owner.loc) || owner.z != blood.blood_body.z)
		qdel(src)
		return FALSE
	if(!heretic_can_affect(blood.blood_body, owner, chargecost = 0))
		heretic_can_affect(blood.blood_body, owner)
		qdel(src)
		return FALSE
	if(!isnull(contact_lost_at) && world.time >= contact_lost_at + HERETIC_BLOOD_CONTACT_GRACE)
		qdel(src)
		return FALSE
	if(!blood.valid_victim(blood.blood_body, owner))
		if(collecting)
			qdel(src)
			return FALSE
		if(isnull(contact_lost_at))
			contact_lost_at = world.time
			to_chat(blood.blood_body, span_warning("Связь с [owner] слабеет: долг исчезнет через две секунды без контакта."))
			blood.notify_resource_changed()
		QDEL_NULL(link_beam)
		return FALSE
	if(!isnull(contact_lost_at))
		contact_lost_at = null
		blood.notify_resource_changed()
	if(!link_beam)
		link_beam = new(blood.blood_body, owner, 'modular_bluemoon/icons/obj/heretic_blood_effects.dmi', "blood_link", INFINITY, HERETIC_BLOOD_RANGE + 1, /obj/effect/ebeam, null)
		INVOKE_ASYNC(link_beam, TYPE_PROC_REF(/datum/beam, Draw))
	if(link_beam && (link_beam.origin_oldloc != get_turf(blood.blood_body) || link_beam.target_oldloc != get_turf(owner)))
		link_beam.recalculate_in(0)
	return TRUE

/datum/status_effect/heretic_blood_seal/proc/begin_collection(datum/eldritch_knowledge/required, amount)
	if(QDELETED(required) || collecting || debt <= 0 || (!isnull(amount) && amount <= 0) || !validate_link())
		return FALSE
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(blood.blood_body)
	if(heretic.get_knowledge(required.type) != required)
		return FALSE
	var/ready_at = world.time + HERETIC_BLOOD_COLLECTION_DELAY
	if(!isnull(amount) && expires_at <= ready_at)
		to_chat(blood.blood_body, span_warning("До исчезновения связи не остаётся полной секунды для частичного взыскания. Взыщите весь долг или продлите связь ударом клинка."))
		return FALSE
	collecting = TRUE
	collection_amount = isnull(amount) ? debt : clamp(amount, 0, debt)
	collection_knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_owner_death))
	collection_ready_at = ready_at
	if(isnull(amount))
		expires_at = max(expires_at, collection_ready_at + 0.1 SECONDS)
	seal_overlay.icon_state = "blood_warning"
	owner.update_icon()
	collection_timer = addtimer(CALLBACK(src, PROC_REF(detonate)), HERETIC_BLOOD_COLLECTION_DELAY, TIMER_STOPPABLE)
	blood.notify_resource_changed()
	to_chat(blood.blood_body, span_notice("Взыскание [round(collection_amount, 0.1)] долга с [owner] началось: держите цель в пяти клетках без преград ещё секунду.[collection_amount < debt ? " Остаток останется в связи." : ""]"))
	to_chat(owner, span_userdanger("Кровная связь натягивается до предела — взыскание через секунду! Скройтесь за преградой или отойдите от еретика дальше пяти клеток!"))
	blood.blood_body.log_message("Начато взыскание с [key_name(owner)]: долг [round(debt, 0.1)].", LOG_ATTACK)
	return TRUE

/datum/status_effect/heretic_blood_seal/proc/detonate()
	if(QDELETED(src) || !collecting || world.time < collection_ready_at || !validate_link())
		return FALSE
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	var/datum/eldritch_knowledge/required = collection_knowledge_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(blood.blood_body)
	if(!required || heretic?.get_knowledge(required.type) != required)
		qdel(src)
		return FALSE
	if(!heretic_can_affect(blood.blood_body, owner))
		qdel(src)
		return FALSE
	var/datum/eldritch_knowledge/upgrade = heretic.get_knowledge(/datum/eldritch_knowledge/blood_upgrade)
	var/payment = min(debt, collection_amount)
	var/damage = payment * (QDELETED(upgrade) ? 2 : 2.25)
	var/mob/living/victim = owner
	var/mob/living/user = blood.blood_body
	var/damage_before = victim.getBruteLoss()
	var/generation = blood.blood_generation
	var/healing_fraction = QDELETED(upgrade) ? HERETIC_BLOOD_SIPHON_FRACTION : HERETIC_BLOOD_UPGRADED_SIPHON_FRACTION
	var/healing_limit = QDELETED(upgrade) ? HERETIC_BLOOD_SIPHON_LIMIT : HERETIC_BLOOD_UPGRADED_SIPHON_LIMIT
	debt -= payment
	victim.adjustBruteLoss(damage)
	if(!QDELETED(blood) && blood.blood_generation == generation && !QDELETED(victim))
		var/actual_damage = min(damage, max(0, victim.getBruteLoss() - damage_before))
		var/healed = blood.mend_wounds(user, min(max(0, healing_limit - siphoned), actual_damage * healing_fraction))
		if(actual_damage > 0)
			var/recovered = blood.recover_blood(user, min(max(0, HERETIC_BLOOD_RECOVERY_LIMIT - blood_recovered), actual_damage * HERETIC_BLOOD_RECOVERY_FRACTION))
			if(!QDELETED(src))
				blood_recovered += recovered
		if(!QDELETED(src))
			siphoned += healed
		if(healed > 0)
			to_chat(user, span_notice("Взысканная кровь залечивает [round(healed, 0.1)] ушибов и ожогов."))
	if(!QDELETED(victim))
		new /obj/effect/temp_visual/heretic_blood/burst(get_turf(victim), blood)
		playsound(victim, 'modular_bluemoon/sound/heretic/blood_release.ogg', 65, TRUE)
		if(!QDELETED(user))
			log_combat(user, victim, "взыскивает кровный долг с", addition = "заданный урон: [damage]; полученные ушибы: [round(victim.getBruteLoss() - damage_before, 0.1)]")
	if(QDELETED(src))
		return TRUE
	if(debt <= 0 || !validate_link())
		qdel(src)
		return TRUE
	collecting = FALSE
	collection_amount = null
	collection_ready_at = null
	if(collection_timer)
		deltimer(collection_timer)
		collection_timer = null
	UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	collection_knowledge_ref = null
	seal_overlay.icon_state = "blood_mark"
	owner.update_icon()
	blood.update_debt()
	return TRUE

/datum/status_effect/heretic_blood_seal/on_remove()
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(blood)
		blood.seals.Remove(src)
		blood.update_debt()
		if(debt > 0 && blood.can_use(blood.blood_body))
			to_chat(blood.blood_body, span_warning("Связь с [owner] оборвалась: невзысканный долг исчез."))
		if(collecting && debt > 0 && !QDELETED(blood.blood_body) && !QDELETED(owner))
			blood.blood_body.log_message("Связь с [key_name(owner)] потеряна во время взыскания: исчезло [round(debt, 0.1)] долга.", LOG_ATTACK)
	var/datum/eldritch_knowledge/required = collection_knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	if(collection_timer)
		deltimer(collection_timer)
		collection_timer = null
	QDEL_NULL(link_beam)
	if(owner)
		UnregisterSignal(owner, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED, COMSIG_ATOM_UPDATE_OVERLAYS))
		owner.update_icon()
	debt = 0
	return ..()

/datum/status_effect/heretic_blood_seal/Destroy()
	. = ..()
	QDEL_NULL(seal_overlay)
	blood_ref = null
	collection_knowledge_ref = null
	return .

/atom/movable/screen/alert/status_effect/heretic_blood_seal
	name = "Кровная связь"
	desc = "Попадания еретика накапливают долг и обновляют срок связи. Скройтесь за преградой, отойдите дальше пяти клеток или выведите еретика из строя на две секунды. Во время секундного предупреждения взыскания это сразу рвёт связь. Антимагия и потеря сознания еретиком рвут её немедленно. Без новых попаданий связь живёт 15 секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_blood_effects.dmi'
	icon_state = "blood_mark"

/datum/status_effect/eldritch/blood
	id = "blood_mark"
	mark_name = "Метка Крови"
	mark_alert_state = "sigil_blood"
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_blood_effects.dmi'
	effect_sprite = "blood_mark"
	detonation_sound = 'modular_bluemoon/sound/heretic/blood_release.ogg'
	var/datum/weakref/blood_ref

/datum/status_effect/eldritch/blood/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_blood/blood)
	if(blood)
		blood_ref = WEAKREF(blood)
	return ..()

/datum/status_effect/eldritch/blood/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(!blood)
		return FALSE
	blood.marks += src
	return TRUE

/datum/status_effect/eldritch/blood/on_remove()
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	blood?.marks.Remove(src)
	return ..()

/datum/status_effect/eldritch/blood/on_effect()
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	var/datum/status_effect/heretic_blood_seal/seal = owner.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(blood?.valid_victim(blood.blood_body, owner) && seal?.blood_ref?.resolve() == blood && !seal.collecting && seal.validate_link())
		blood.add_debt(seal, HERETIC_BLOOD_STRIKE_DEBT)
		seal.expires_at = min(seal.expires_at + 5 SECONDS, world.time + 20 SECONDS)
	return ..()

/obj/item/melee/sickly_blade/blood
	name = "crimson lancet"
	desc = "Тонкая игла с раздвоенным остриём. В стеклянной ампуле рукояти кровь бьётся в такт чужому сердцу."
	icon = 'modular_bluemoon/icons/obj/heretic_blood.dmi'
	icon_state = "blood_blade"
	item_state = "blood_blade"
	route = PATH_BLOOD
	mark_type = /datum/status_effect/eldritch/blood

/obj/item/melee/sickly_blade/blood/attack(mob/living/target, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/status_effect/heretic_blood_seal/seal = target.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(blood && seal?.blood_ref?.resolve() == blood && !heretic_can_affect(user, target, chargecost = 0))
		qdel(seal)
	return ..()

/obj/item/heretic_path_relic/blood_relic
	name = "clotted chalice"
	desc = "Костяная чаша на ножке из сросшихся сосудов. Возьмите в руку и щёлкните по своему связанному врагу: до 10 долга превратится в 20 ушибов врагу и столько же лечения ваших ушибов и ожогов. Расход зависит от ваших ран. Перезарядка — 12 секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_blood.dmi'
	icon_state = "blood_relic"

/obj/item/heretic_path_relic/blood_relic/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	if(isliving(target))
		drink(user, target)

/obj/item/heretic_path_relic/blood_relic/proc/drink(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!authorized(user) || !blood)
		return FALSE
	if(!COOLDOWN_FINISHED(src, relic_cooldown))
		to_chat(user, span_warning("Чаша ещё наполняется. До следующего глотка: [round(COOLDOWN_TIMELEFT(src, relic_cooldown) / (1 SECONDS), 0.1)] с."))
		return FALSE
	if(user.getBruteLoss() + user.getFireLoss() <= 0)
		to_chat(user, span_notice("У вас нет ушибов или ожогов. Сохраните долг для взыскания."))
		return FALSE
	if(!blood.valid_victim(user, victim))
		to_chat(user, span_warning("Щёлкните чашей по живому должнику в пяти клетках без преград."))
		return FALSE
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(seal?.blood_ref?.resolve() != blood)
		to_chat(user, span_warning("Сначала свяжите эту цель кнопкой «Связать / взыскать» или своим клинком."))
		return FALSE
	if(seal.collecting)
		to_chat(user, span_warning("Этот долг уже взыскивается. Чашей нужно воспользоваться до взыскания."))
		return FALSE
	if(!blood.refund(user, victim))
		return FALSE
	COOLDOWN_START(src, relic_cooldown, HERETIC_BLOOD_REFUND_COOLDOWN)
	playsound(user, 'modular_bluemoon/sound/heretic/blood_grasp.ogg', 35, TRUE)
	return TRUE

/obj/effect/temp_visual/heretic_blood
	icon = 'modular_bluemoon/icons/obj/heretic_blood_effects.dmi'
	icon_state = "blood_burst"
	duration = 0.8 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	var/datum/weakref/blood_ref

/obj/effect/temp_visual/heretic_blood/Initialize(mapload, datum/eldritch_knowledge/base_blood/blood)
	if(!QDELETED(blood))
		blood_ref = WEAKREF(blood)
		blood.visuals += src
	return ..()

/obj/effect/temp_visual/heretic_blood/Destroy()
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	blood?.visuals.Remove(src)
	blood_ref = null
	return ..()

/obj/effect/temp_visual/heretic_blood/grasp
	icon_state = "blood_grasp"

/obj/effect/temp_visual/heretic_blood/lance
	icon_state = "blood_lance"

/obj/effect/temp_visual/heretic_blood/pact
	icon_state = "blood_pact"

/obj/effect/temp_visual/heretic_blood/burst

/obj/effect/temp_visual/heretic_blood/warning
	icon_state = "blood_warning"
	duration = 1 SECONDS

/obj/effect/temp_visual/heretic_blood/reckoning
	icon_state = "blood_reckoning"

/obj/effect/proc_holder/spell/pointed/heretic_blood
	clothes_req = FALSE
	invocation_type = "none"
	range = HERETIC_BLOOD_RANGE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "blood_release"
	action_background_icon_state = "bg_ecult"
	charge_max = 2 SECONDS
	active_msg = "Выберите живого врага в пяти клетках без преград."
	deactive_msg = "Вы отпускаете кровяную нить."

/obj/effect/proc_holder/spell/pointed/heretic_blood/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	return ..() && heretic_check(user, blood?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/pointed/heretic_blood/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	return heretic_check(user, blood?.valid_victim(user, target) && heretic_can_affect(user, target, chargecost = 0), silent, "Нужен доступный живой противник без защиты от магии и чужой кровной связи.", target = target)

/obj/effect/proc_holder/spell/pointed/heretic_blood/release
	name = "Связать / взыскать"
	desc = "Первый выбор врага: бесплатная связь и 10 долга. Повторный выбор после перезарядки в 2 секунды: взыскание по 2 ушиба за долг с секундой предупреждения. В намерении «Разоружить» взыскивает до 10 долга и сохраняет остаток связи с прежним сроком. Четверть фактического урона лечит ваши ушибы и ожоги, суммарно до 10 за одну связь. Клинок добавляет 6 долга раз в 2 секунды и обновляет срок связи до 15 секунд. Вне взыскания на восстановление контакта есть 2 секунды."
	active_msg = "Новый враг — связать бесплатно. Свой должник — взыскать весь долг; в намерении «Разоружить» — до 10, сохранив остаток."

/obj/effect/proc_holder/spell/pointed/heretic_blood/release/can_target(atom/target, mob/user, silent)
	if(!..())
		return FALSE
	var/mob/living/victim = target
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!seal && length(blood.seals) >= blood.link_limit)
		if(!silent)
			to_chat(user, span_warning("Связи заняты: выберите прежнего должника, чтобы взыскать его долг."))
		return FALSE
	if(seal && (seal.blood_ref?.resolve() != blood || seal.collecting))
		if(!silent)
			to_chat(user, span_warning((seal.collecting ? "Взыскание уже началось: удержите дистанцию до удара." : "Эта связь принадлежит другому еретику.")))
		return FALSE
	return TRUE

/obj/effect/proc_holder/spell/pointed/heretic_blood/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!length(targets) || !blood?.release(user, targets[1], partial = user.a_intent == INTENT_DISARM))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_blood/lance
	name = "Натянуть жилу"
	desc = "Нанесите врагу 18 ушибов и притяните на три клетки. Создаёт кровную связь и добавляет 6 долга. Не требует собственного здоровья. Преграды, антимагия, закрепление и пристёгивание защищают от притяжения. Перезарядка — 12 секунд."
	action_icon_state = "blood_lance"
	charge_max = 12 SECONDS
	active_msg = "Выберите врага: ударить и притянуть к клинку. Предварительная связь не нужна."

/obj/effect/proc_holder/spell/pointed/heretic_blood/lance/can_target(atom/target, mob/user, silent)
	if(!..())
		return FALSE
	var/mob/living/victim = target
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic_check(user, !seal || (seal.blood_ref?.resolve() == heretic.get_knowledge(/datum/eldritch_knowledge/base_blood) && !seal.collecting), silent, "Нужен доступный живой противник без защиты от магии и чужой кровной связи.")

/obj/effect/proc_holder/spell/pointed/heretic_blood/lance/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!length(targets) || !blood?.lance(user, targets[1]))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_blood/coronation
	name = "Кровный приговор"
	desc = "Выберите своего связанного должника. В его связь перейдут долги остальных ваших связей до предела 30, затем начнётся взыскание с секундой предупреждения. Остатки долгов сохраняются на прежних целях; перенос ничего не создаёт."
	action_icon_state = "blood_ascend"
	charge_max = 30 SECONDS
	active_msg = "Выберите своего должника: перенести на него остальные долги и взыскать."

/obj/effect/proc_holder/spell/pointed/heretic_blood/coronation/can_target(atom/target, mob/user, silent)
	if(!..())
		return FALSE
	var/mob/living/victim = target
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	return heretic_check(user, blood.can_use_ascension(user) && seal?.blood_ref?.resolve() == blood && !seal.collecting, silent, "Нужны вознесение и ваша кровная связь на цели, по которой ещё не начато взыскание.")

/obj/effect/proc_holder/spell/pointed/heretic_blood/coronation/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!length(targets) || !blood?.coronation(user, targets[1]))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_blood
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "blood_pact"
	action_background_icon_state = "bg_ecult"
	charge_max = 20 SECONDS

/obj/effect/proc_holder/spell/self/heretic_blood/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	return ..() && heretic_check(user, blood?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_blood/pact
	name = "Договор: ускорение"
	desc = "Для погони или отхода: получите 10 ушибов и ускорьтесь на 6 секунд. Работает без должников. Если есть неполные связи, они делят оплаченную рану как долг и вновь живут 15 секунд. Опасная для жизни плата запрещена."

/obj/effect/proc_holder/spell/self/heretic_blood/pact/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!blood?.pact(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_blood/reckoning
	name = "Взыскать долги"
	desc = "Добавьте 6 долга каждой действующей связи и взыщите все долги одновременно. Взыскание лечит вас за урон каждой цели. У должников есть секунда предупреждения, чтобы порвать связь. Посторонние не затрагиваются. Перезарядка — 20 секунд."
	action_icon_state = "blood_reckoning"
	charge_max = 20 SECONDS

/obj/effect/proc_holder/spell/self/heretic_blood/reckoning/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!blood?.reckoning(user))
		heretic_revert_cast(user)

/datum/eldritch_knowledge/base_blood/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !proximity_flag || !istype(target, /obj/effect/decal/cleanable/blood) || !isturf(target.loc))
		return FALSE
	var/obj/effect/decal/cleanable/blood/stain = target
	var/own_dna
	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		own_dna = carbon_user.dna?.unique_enzymes
	var/list/signatures = list()
	for(var/dna_key in stain.blood_DNA)
		if(dna_key == "color" || dna_key == "blendmode" || dna_key == own_dna)
			continue
		signatures += dna_key
	if(!length(signatures))
		return FALSE
	for(var/index in 1 to length(signatures))
		if(!heretic.advance_deed(signatures[index], null, silent = index < length(signatures)))
			continue
		stain.name = heretic.deed.trace_name
		stain.desc = heretic.deed.trace_desc
		return TRUE
	return FALSE

/datum/eldritch_knowledge/blood_grasp
	name = "Красная ладонь"
	desc = "Хватка Мансуса бесплатно создаёт кровную связь. По уже связанному врагу добавляет 6 долга и обновляет срок связи до 15 секунд."
	gain_text = "В моей ладони забился пульс, которого прежде не было."
	cost = 1
	route = PATH_BLOOD

/datum/eldritch_knowledge/blood_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(QDELETED(src) || !proximity_flag || !blood?.valid_victim(user, target) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	return seal ? blood.add_debt(seal, HERETIC_BLOOD_STRIKE_DEBT, renew = TRUE) : blood.release(user, victim)

/datum/eldritch_knowledge/spell/blood_lance
	name = "Натянуть жилу"
	desc = "Натянуть жилу наносит врагу в пяти клетках 18 ушибов и притягивает на три клетки. Создаёт кровную связь и добавляет 6 долга. Работает без подготовки и саморанения; стены и антимагия защищают цель. Перезарядка — 12 секунд."
	gain_text = "Я потянул за нить, и на другом конце сбился чужой шаг."
	cost = 1
	route = PATH_BLOOD
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_blood/lance

/datum/eldritch_knowledge/blood_mark
	name = "Метка отсрочки"
	desc = "Хватка оставляет метку на 15 секунд. Удар багровым ланцетом разбивает её, добавляет 6 долга и продлевает связь на 5 секунд, максимум до 20 секунд от текущего момента."
	gain_text = "Подпись побледнела. Я обвёл её ещё раз."
	cost = 2
	route = PATH_BLOOD

/datum/eldritch_knowledge/blood_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(QDELETED(src) || !proximity_flag || !blood?.valid_victim(user, target) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/blood, blood)
	return TRUE

/datum/eldritch_knowledge/blood_mark/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = combat_resource_owner?.resolve()
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!QDELETED(blood))
		QDEL_LIST(blood.marks)

/datum/eldritch_knowledge/blood_mark/Destroy()
	on_body_lose()
	return ..()

/datum/eldritch_knowledge/blood_relic
	name = "Чаша возвращённого"
	desc = "Стакан и лист серебра создают чашу. Возьмите её в руку и щёлкните по своему должнику: до 10 долга нанесёт ему до 20 ушибов и залечит столько же ваших ушибов и ожогов. Расход ограничен вашими ранами; лечение — фактическим уроном врагу. При нулевом долге связь исчезает. Одна чаша, перезарядка — 12 секунд."
	gain_text = "На дне осталась одна капля. Я узнал её вкус."
	cost = 1
	route = PATH_BLOOD
	required_atoms = list(/obj/item/reagent_containers/food/drinks/drinkingglass, /obj/item/stack/sheet/mineral/silver)
	result_atoms = list(/obj/item/heretic_path_relic/blood_relic)

/datum/eldritch_knowledge/blood_relic/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/blood_relic/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/blood_relic)

/datum/eldritch_knowledge/blood_upgrade
	name = "Право взыскателя"
	desc = "Взыскание наносит по 2,25 ушиба за единицу долга вместо 2 и лечит вас на половину фактического урона, суммарно до 20 за одну связь. Полная начальная связь нанесёт 45 ушибов и сможет залечить 20 ваших ушибов и ожогов. Частичные взыскания делят этот предел."
	gain_text = "Внизу страницы обнаружилась строка, которой прежде не было."
	cost = 2
	route = PATH_BLOOD

/datum/eldritch_knowledge/spell/blood_pact
	name = "Договор с раной"
	desc = "За 10 собственных ушибов получите ускорение на 6 секунд для погони или отхода. Действующие связи делят оплаченную рану как долг и вновь живут 15 секунд; полные и уже взыскиваемые связи пропускаются. Можно ускориться без должников. Опасная для жизни плата запрещена. Перезарядка — 20 секунд."
	gain_text = "В договоре не было имени кредитора. Только место для моего."
	cost = 1
	route = PATH_BLOOD
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_blood/pact

/datum/eldritch_knowledge/spell/blood_pact/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(blood)
		QDEL_NULL(blood.blood_rush)
	return ..()

/datum/eldritch_knowledge/blood_vigor
	name = "Книга обязательств"
	desc = "Позволяет держать две связи вместо одной. Каждая вмещает 20 долга. Второй уровень увеличивает предел до 25, третий разрешает третью связь. Улучшения не создают долг."
	gain_text = "На обороте листа нашлось место для ещё одной подписи."
	cost = 2
	route = PATH_BLOOD
	passive_values = list(20, 25, 25)
	passive_desc = "Связей: 2 / 2 / 3. Долг каждой: 20 / 25 / 25. Вознесение позволяет три связи по 30."

/datum/eldritch_knowledge/blood_vigor/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	blood?.update_capacity()

/datum/eldritch_knowledge/blood_vigor/on_passive_upgrade(mob/living/user)
	on_body_gain(user)

/datum/eldritch_knowledge/blood_vigor/on_lose(mob/user)
	var/datum/antagonist/heretic/heretic = combat_resource_owner?.resolve()
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!QDELETED(blood))
		blood.update_capacity(ignore_vigor = TRUE)
	return ..()

/datum/eldritch_knowledge/blood_vigor/Destroy()
	on_lose()
	return ..()

/datum/eldritch_knowledge/spell/blood_reckoning
	name = "Взыскать долги"
	desc = "Открывает Взыскать долги: бесплатно добавьте 6 долга каждой действующей связи и взыщите все долги одновременно, залечивая раны за урон каждой цели. Каждая жертва получает секунду предупреждения и может порвать собственную связь. Посторонние не затрагиваются. Перезарядка — 20 секунд."
	gain_text = "Книга закрылась. Долги остались снаружи."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_BLOOD
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_blood/reckoning

/datum/eldritch_knowledge/spell/blood_reckoning/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = combat_resource_owner?.resolve()
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!QDELETED(blood))
		for(var/datum/status_effect/heretic_blood_seal/seal as anything in blood.seals.Copy())
			if(seal.collection_knowledge_ref?.resolve() == src)
				qdel(seal)
	return ..()

/datum/eldritch_knowledge/final_eldritch/blood_final
	parallax_scene = ANTAG_SCENE_HERETIC_BLOOD
	name = "Венценосец Багровой Чаши"
	desc = "После трёх назначенных душ принесите на руну три человеческих трупа. Станция узнает место обряда и получит 30 секунд, чтобы помешать. Вознесение позволяет держать три связи по 30 долга и снижает получаемые ушибы и ожоги на четверть. «Кровный приговор» раз в 30 секунд переносит долги других связей в выбранную до предела 30, затем начинает её взыскание. Перенос сохраняет общий долг, а жертва получает секунду предупреждения."
	gain_text = "Из чаши поднялся венец. Все подписи на его ободе были моими."
	route = PATH_BLOOD
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/pointed/heretic_blood/coronation)

/datum/eldritch_knowledge/final_eldritch/blood_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	on_body_gain(user)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/blood_final/on_body_gain(mob/living/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	blood?.update_capacity()

/datum/eldritch_knowledge/final_eldritch/blood_final/on_body_lose(mob/living/user)
	var/was_applied = !isnull(applied_body)
	. = ..()
	if(!was_applied)
		return
	var/datum/antagonist/heretic/heretic = combat_resource_owner?.resolve()
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!QDELETED(blood))
		blood.clear_blood()
		blood.update_capacity()

#undef HERETIC_BLOOD_RANGE
#undef HERETIC_BLOOD_HARVEST_TIME
#undef HERETIC_BLOOD_HEALTH_RESERVE
#undef HERETIC_BLOOD_LINK_LIFETIME
#undef HERETIC_BLOOD_COLLECTION_DELAY
#undef HERETIC_BLOOD_REFUND_LIMIT
#undef HERETIC_BLOOD_CONTACT_GRACE
#undef HERETIC_BLOOD_REFUND_MULTIPLIER
#undef HERETIC_BLOOD_REFUND_COOLDOWN
#undef HERETIC_BLOOD_SIPHON_FRACTION
#undef HERETIC_BLOOD_SIPHON_LIMIT
#undef HERETIC_BLOOD_UPGRADED_SIPHON_FRACTION
#undef HERETIC_BLOOD_UPGRADED_SIPHON_LIMIT
#undef HERETIC_BLOOD_INITIAL_DEBT
#undef HERETIC_BLOOD_STRIKE_DEBT
#undef HERETIC_BLOOD_LANCE_DAMAGE
#undef HERETIC_BLOOD_LANCE_PULL

#undef HERETIC_BLOOD_RUSH_DURATION
#undef HERETIC_BLOOD_PACT_PAYMENT
#undef HERETIC_BLOOD_PARTIAL_COLLECTION
#undef HERETIC_BLOOD_RECOVERY_FRACTION
#undef HERETIC_BLOOD_RECOVERY_LIMIT
#undef HERETIC_BLOOD_CLOT_DURATION
#undef HERETIC_BLOOD_CLOT_MULTIPLIER
