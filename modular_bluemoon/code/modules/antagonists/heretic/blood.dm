#define HERETIC_BLOOD_RANGE 5
#define HERETIC_BLOOD_HARVEST_TIME (6 SECONDS)
#define HERETIC_BLOOD_HEALTH_RESERVE 25
#define HERETIC_BLOOD_LINK_LIFETIME (15 SECONDS)
#define HERETIC_BLOOD_COLLECTION_DELAY (1 SECONDS)
#define HERETIC_BLOOD_REFUND_LIMIT 8
#define HERETIC_BLOOD_INITIAL_DEBT 10
#define HERETIC_BLOOD_STRIKE_DEBT 6
#define HERETIC_BLOOD_LANCE_DAMAGE 18
#define HERETIC_BLOOD_LANCE_PULL 2

/datum/heretic_path/blood
	id = PATH_BLOOD
	deed_type = /datum/heretic_deed/blood
	name = "Кровь"
	desc = "Свяжите противника кровью, притяните к клинку и взыщите долг. Чаша обращает его раны в ваше лечение."
	strengths = "Бесплатная связь, притяжение с уроном, накопление долга в ближнем бою и лечение за счёт врага."
	weaknesses = "Стены, дистанция, антимагия и недееспособность разрывают связь. Взыскание предупреждает жертву за секунду."
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
	desc = "Нож и стеклянный осколок создают багровый ланцет. Свяжите врага Кровным обязательством или ударом клинка, затем повторно примените Обязательство, чтобы нанести накопленный урон. Попадания клинком увеличивают долг без саморанения. Держитесь рядом: за стеной или дальше пяти клеток связь рвётся."
	gain_text = "На белом листе появилась капля. Подпись уже была моей."
	route = PATH_BLOOD
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/shard)
	result_atoms = list(/obj/item/melee/sickly_blade/blood)
	combat_resource = 0
	combat_resource_max = 20
	combat_resource_name = "Кровный долг"
	combat_resource_desc = "Связь создаёт 10 долга; клинок, хватка и Натяжение добавляют по 6. Договор добровольно усиливает связи вашими ранами. Повторное Обязательство взыскивает долг после секунды предупреждения. Чаша расходует долг на кражу здоровья. За стеной, дальше пяти клеток, при антимагии или вашей недееспособности связь рвётся."
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
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_blood/proc/can_use(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && isliving(user) && user == blood_body && user.stat == CONSCIOUS && !user.incapacitated() && isturf(user.loc) && heretic?.selected_path == PATH_BLOOD && !heretic.role_removed && heretic.get_knowledge(type) == src

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
	data["description"] = "[combat_resource_desc] Связей: [length(seals)]/[link_limit], предел долга каждой — [debt_cap]."
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in seals)
		data["description"] += " [html_encode(seal.owner.name)] — долг [round(seal.debt, 0.1)][seal.collecting ? " (взыскание)" : ""]."
	return data

/datum/eldritch_knowledge/base_blood/on_mark_detonated(mob/living/user, mob/living/target)
	return

/datum/eldritch_knowledge/base_blood/gain_combat_resource(amount = 1)
	return

/datum/eldritch_knowledge/base_blood/spend_combat_resource(amount = 1)
	return FALSE

/datum/eldritch_knowledge/base_blood/proc/invest(mob/living/user, list/candidates, amount, renew = FALSE)
	if(!can_use(user))
		return FALSE
	var/list/available = list()
	var/room = 0
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in candidates)
		if(QDELETED(seal) || seal.blood_ref?.resolve() != src || seal.collecting || !seal.validate_link() || seal.debt >= debt_cap)
			continue
		available += seal
		room += debt_cap - seal.debt
	if(!length(available) || room <= 0)
		return FALSE
	var/payment = pay_health(user, min(amount, room))
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

/datum/eldritch_knowledge/base_blood/proc/release(mob/living/user, mob/living/victim)
	if(!valid_victim(user, victim))
		return FALSE
	var/datum/status_effect/heretic_blood_seal/existing = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(existing)
		return existing.blood_ref?.resolve() == src && existing.begin_collection(src)
	if(length(seals) >= link_limit)
		return FALSE
	if(!heretic_can_affect(user, victim))
		return TRUE
	var/datum/status_effect/heretic_blood_seal/seal = victim.apply_status_effect(/datum/status_effect/heretic_blood_seal, src)
	if(QDELETED(seal))
		return FALSE
	seal.debt = min(HERETIC_BLOOD_INITIAL_DEBT, debt_cap)
	update_debt()
	playsound(victim, 'modular_bluemoon/sound/heretic/blood_release.ogg', 45, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_blood/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag || !valid_victim(user, target) || !COOLDOWN_FINISHED(src, resource_harvest) || !heretic_can_affect(user, target, chargecost = 0))
		return
	var/mob/living/victim = target
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(!seal && release(user, victim))
		seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(add_debt(seal, HERETIC_BLOOD_STRIKE_DEBT))
		COOLDOWN_START(src, resource_harvest, HERETIC_BLOOD_HARVEST_TIME)

/datum/eldritch_knowledge/base_blood/proc/add_debt(datum/status_effect/heretic_blood_seal/seal, amount, renew = FALSE)
	if(QDELETED(seal) || seal.blood_ref?.resolve() != src || seal.collecting || !seal.validate_link())
		return FALSE
	seal.debt = min(debt_cap, seal.debt + amount)
	if(renew)
		seal.expires_at = world.time + HERETIC_BLOOD_LINK_LIFETIME
	update_debt()
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
	return invest(user, seals.Copy(), 10, renew = TRUE)

/datum/eldritch_knowledge/base_blood/proc/reckoning(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/blood_reckoning)
	if(!can_use(user) || QDELETED(required))
		return FALSE
	var/started = FALSE
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in seals.Copy())
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

/datum/eldritch_knowledge/base_blood/proc/refund(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/blood_relic)
	if(!can_use(user) || QDELETED(required) || !valid_victim(user, victim))
		return FALSE
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(seal?.blood_ref?.resolve() != src || seal.collecting || !seal.validate_link())
		return FALSE
	var/payment = min(HERETIC_BLOOD_REFUND_LIMIT, seal.debt, user.getBruteLoss())
	if(payment <= 0)
		return FALSE
	seal.debt -= payment
	var/expected_generation = blood_generation
	var/damage_before = victim.getBruteLoss()
	victim.adjustBruteLoss(payment)
	if(QDELETED(src) || !can_use(user) || blood_generation != expected_generation || QDELETED(victim))
		return TRUE
	payment = min(payment, max(0, victim.getBruteLoss() - damage_before))
	user.adjustBruteLoss(-payment, forced = TRUE, only_organic = FALSE)
	update_debt()
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
	var/expected_generation

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
	. = ..()
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
	to_chat(owner, span_userdanger("От вас к [blood.blood_body] тянется кровяная жила. Его клинок и хватка увеличивают ваш долг! Скройтесь за преградой или отойдите дальше пяти клеток, чтобы разорвать связь."))
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
	if(!blood || blood.blood_generation != expected_generation || world.time >= expires_at || !blood.valid_victim(blood.blood_body, owner))
		qdel(src)
		return FALSE
	if(!heretic_can_affect(blood.blood_body, owner, chargecost = 0))
		heretic_can_affect(blood.blood_body, owner)
		qdel(src)
		return FALSE
	if(link_beam && (link_beam.origin_oldloc != get_turf(blood.blood_body) || link_beam.target_oldloc != get_turf(owner)))
		link_beam.recalculate_in(0)
	return TRUE

/datum/status_effect/heretic_blood_seal/proc/begin_collection(datum/eldritch_knowledge/required)
	if(QDELETED(required) || collecting || debt <= 0 || !validate_link())
		return FALSE
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(blood.blood_body)
	if(heretic.get_knowledge(required.type) != required)
		return FALSE
	collecting = TRUE
	collection_knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_owner_death))
	collection_ready_at = world.time + HERETIC_BLOOD_COLLECTION_DELAY
	expires_at = max(expires_at, collection_ready_at + 0.1 SECONDS)
	seal_overlay.icon_state = "blood_warning"
	owner.update_icon()
	collection_timer = addtimer(CALLBACK(src, PROC_REF(detonate)), HERETIC_BLOOD_COLLECTION_DELAY, TIMER_STOPPABLE)
	blood.notify_resource_changed()
	to_chat(owner, span_userdanger("Кровная связь натягивается до предела — взыскание через секунду! Скройтесь за преградой или отойдите от еретика дальше пяти клеток!"))
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
	var/damage = debt * (QDELETED(upgrade) ? 2 : 2.25)
	var/mob/living/victim = owner
	var/mob/living/user = blood.blood_body
	debt = 0
	victim.adjustBruteLoss(damage)
	if(!QDELETED(victim))
		new /obj/effect/temp_visual/heretic_blood/burst(get_turf(victim), blood)
		playsound(victim, 'modular_bluemoon/sound/heretic/blood_release.ogg', 65, TRUE)
		if(!QDELETED(user))
			log_combat(user, victim, "взыскивает кровный долг с")
	qdel(src)
	return TRUE

/datum/status_effect/heretic_blood_seal/on_remove()
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(blood)
		blood.seals.Remove(src)
		blood.update_debt()
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
	name = "Кровное обязательство"
	desc = "Попадания еретика накапливают ваш долг. Взыскание предупреждает за секунду. Стены, дистанция больше пяти клеток, антимагия и недееспособность еретика рвут связь; без взыскания она исчезнет через 15 секунд."
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
	desc = "Багровое лезвие с раздвоенным остриём. Тонкая жила внутри рукояти пульсирует в такт чужому сердцу."
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
	desc = "Чаша с неподвижной каплей над краем. Укажите своего должника: до 8 долга превратится в ушибы врага и столько же лечения ваших ушибов. Требует раненого владельца; перезарядка — 20 секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_blood.dmi'
	icon_state = "blood_relic"

/obj/item/heretic_path_relic/blood_relic/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	if(isliving(target))
		drink(user, target)

/obj/item/heretic_path_relic/blood_relic/proc/drink(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!authorized(user) || !COOLDOWN_FINISHED(src, relic_cooldown) || !blood?.refund(user, victim))
		return FALSE
	COOLDOWN_START(src, relic_cooldown, 20 SECONDS)
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
	active_msg = "Укажите должника для кровного обязательства."
	deactive_msg = "Вы отпускаете кровяную нить."

/obj/effect/proc_holder/spell/pointed/heretic_blood/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	return ..() && blood?.can_use(user)

/obj/effect/proc_holder/spell/pointed/heretic_blood/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	return blood?.valid_victim(user, target) && heretic_can_affect(user, target, chargecost = 0)

/obj/effect/proc_holder/spell/pointed/heretic_blood/release
	name = "Кровное обязательство"
	desc = "Бесплатно свяжите врага на 15 секунд и создайте 10 долга. Повторное применение через секунду наносит по 2 ушиба за единицу долга. Клинок добавляет 6 долга раз в 6 секунд. Преграды, дистанция больше пяти клеток и антимагия рвут связь."

/obj/effect/proc_holder/spell/pointed/heretic_blood/release/can_target(atom/target, mob/user, silent)
	if(!..())
		return FALSE
	var/mob/living/victim = target
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !seal || (seal.blood_ref?.resolve() == heretic.get_knowledge(/datum/eldritch_knowledge/base_blood) && !seal.collecting)

/obj/effect/proc_holder/spell/pointed/heretic_blood/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!length(targets) || !blood?.release(user, targets[1]))
		revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_blood/lance
	name = "Натянуть жилу"
	desc = "Нанесите врагу 18 ушибов и притяните на две клетки. Создаёт кровную связь и добавляет 6 долга. Не требует собственного здоровья. Преграды, антимагия, закрепление и пристёгивание защищают от притяжения."
	action_icon_state = "blood_lance"
	charge_max = 15 SECONDS

/obj/effect/proc_holder/spell/pointed/heretic_blood/lance/can_target(atom/target, mob/user, silent)
	if(!..())
		return FALSE
	var/mob/living/victim = target
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !seal || (seal.blood_ref?.resolve() == heretic.get_knowledge(/datum/eldritch_knowledge/base_blood) && !seal.collecting)

/obj/effect/proc_holder/spell/pointed/heretic_blood/lance/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!length(targets) || !blood?.lance(user, targets[1]))
		revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_blood/coronation
	name = "Кровный приговор"
	desc = "Выберите своего связанного должника. В его связь перейдут долги остальных ваших связей до предела 30, затем начнётся взыскание с секундой предупреждения. Остатки долгов сохраняются на прежних целях; перенос ничего не создаёт."
	action_icon_state = "blood_ascend"
	charge_max = 30 SECONDS

/obj/effect/proc_holder/spell/pointed/heretic_blood/coronation/can_target(atom/target, mob/user, silent)
	if(!..())
		return FALSE
	var/mob/living/victim = target
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	return blood.can_use_ascension(user) && seal?.blood_ref?.resolve() == blood && !seal.collecting

/obj/effect/proc_holder/spell/pointed/heretic_blood/coronation/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!length(targets) || !blood?.coronation(user, targets[1]))
		revert_cast(user)

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
	return ..() && blood?.can_use(user)

/obj/effect/proc_holder/spell/self/heretic_blood/pact
	name = "Договор с раной"
	desc = "Вложите до 10 собственных ушибов в действующие связи по порядку их создания. Оплаченный урон распределяется одним общим бюджетом; связи, получившие плату, вновь живут 15 секунд. Нет связей или места для долга — нет платы."

/obj/effect/proc_holder/spell/self/heretic_blood/pact/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!blood?.pact(user))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_blood/reckoning
	name = "Взыскать долги"
	desc = "Начните взыскание всех действующих кровных связей. У каждого должника есть секунда предупреждения, чтобы порвать свою связь. Посторонние не затрагиваются; площадь и стены вокруг них не определяют список целей."
	action_icon_state = "blood_reckoning"
	charge_max = 30 SECONDS

/obj/effect/proc_holder/spell/self/heretic_blood/reckoning/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!blood?.reckoning(user))
		revert_cast(user)

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
	desc = "Натянуть жилу наносит врагу в пяти клетках 18 ушибов и притягивает на две клетки. Создаёт кровную связь и добавляет 6 долга. Работает без подготовки и саморанения; стены и антимагия защищают цель. Перезарядка — 15 секунд."
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
	desc = "Стеклянный стакан и лист серебра создают чашу. Держа её в руке, укажите связанного врага: потратьте до 8 долга, чтобы нанести столько же ушибов и вылечить свои. Лечение зависит от реального урона; здоровый владелец не может пить. Одна чаша, перезарядка — 20 секунд."
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
	desc = "Взыскание наносит по 2,25 ушиба за единицу долга вместо 2. Полная начальная связь нанесёт 45 ушибов."
	gain_text = "Внизу страницы обнаружилась строка, которой прежде не было."
	cost = 2
	route = PATH_BLOOD

/datum/eldritch_knowledge/spell/blood_pact
	name = "Договор с раной"
	desc = "Открывает Договор с раной: вложите до 10 собственных ушибов в действующие связи по порядку их создания. Каждая получает лишь свою часть общей платы и срок 15 секунд. Полные и уже взыскиваемые связи пропускаются; нет места для долга — нет платы. Перезарядка — 20 секунд."
	gain_text = "В договоре не было имени кредитора. Только место для моего."
	cost = 1
	route = PATH_BLOOD
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_blood/pact

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
	desc = "Открывает Взыскать долги: начните взыскание всех действующих связей одновременно. Каждая жертва получает секунду предупреждения и может порвать собственную связь. Посторонние не затрагиваются. Перезарядка — 30 секунд."
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
#undef HERETIC_BLOOD_INITIAL_DEBT
#undef HERETIC_BLOOD_STRIKE_DEBT
#undef HERETIC_BLOOD_LANCE_DAMAGE
#undef HERETIC_BLOOD_LANCE_PULL
