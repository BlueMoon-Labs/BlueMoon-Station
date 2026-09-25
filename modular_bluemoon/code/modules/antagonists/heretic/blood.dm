#define HERETIC_BLOOD_HARVEST_TIME (2 SECONDS)
#define HERETIC_BLOOD_HEALTH_RESERVE 25
#define HERETIC_BLOOD_LINK_LIFETIME (15 SECONDS)
#define HERETIC_BLOOD_COLLECTION_DELAY (1 SECONDS)
#define HERETIC_BLOOD_REFUND_LIMIT 10
#define HERETIC_BLOOD_REFUND_MULTIPLIER 2
#define HERETIC_BLOOD_REFUND_COOLDOWN (12 SECONDS)
#define HERETIC_BLOOD_SIPHON_FRACTION 0.25
#define HERETIC_BLOOD_SIPHON_LIMIT 10
#define HERETIC_BLOOD_DAMAGE_PER_DEBT 2
#define HERETIC_BLOOD_INITIAL_DEBT 10
#define HERETIC_BLOOD_STRIKE_DEBT 6
#define HERETIC_BLOOD_LANCE_DAMAGE 18
#define HERETIC_BLOOD_LANCE_PULL 3
#define HERETIC_BLOOD_PARTIAL_COLLECTION 10
#define HERETIC_BLOOD_SIGN_CRAFT "blood_sign"
#define HERETIC_BLOOD_SIGN_CLUE "Кровь не засыхает и медленно пульсирует."
#define HERETIC_BLOOD_TRAIL_NEAR 7
#define HERETIC_BLOOD_TRAIL_FAR 20
#define HERETIC_BLOOD_CAPTURE "blood"
#define HERETIC_BLOOD_CHECK_INTERVAL (0.5 SECONDS)
#define HERETIC_BLOOD_DRAIN_REFILL_MARGIN 2
#define HERETIC_BLOOD_DRAIN_TRAIT "heretic_blood_drain"
#define HERETIC_BLOOD_SLIP_TRAIT "heretic_blood_slip"
#define HERETIC_BLOOD_SLIP_HASTE -0.35
#define HERETIC_BLOOD_SLICK_KNOCKDOWN (6 SECONDS)
#define HERETIC_BLOOD_LEASH_MESSAGE_COOLDOWN (1 SECONDS)
#define HERETIC_BLOOD_DRAIN_SEAL_MARGIN (1 SECONDS)
#define HERETIC_BLOOD_EXSANGUINE_SLOWDOWN 0.5
#define HERETIC_BLOOD_EXSANGUINE_BLUR 2
#define HERETIC_BLOOD_RECOVERY_FRACTION 0.25
#define HERETIC_BLOOD_RECOVERY_LIMIT 10
#define HERETIC_BLOOD_TIDE_STREAM_TIME (1.2 SECONDS)
#define HERETIC_BLOOD_DRINK_TIME (0.45 SECONDS)
#define HERETIC_BLOOD_DRINK_SHRINK 0.1
#define HERETIC_BLOOD_DRINK_TURN 120
#define HERETIC_BLOOD_DRINK_RADIUS 18
#define HERETIC_BLOOD_DRINK_ARMS 4
#define HERETIC_BLOOD_DRINK_SWIRL 0.6
#define HERETIC_BLOOD_DRINK_EMIT (0.2 SECONDS)
#define HERETIC_BLOOD_VERDICT_REEL (0.8 SECONDS)
#define HERETIC_BLOOD_VERDICT_THREAD_FADE (0.1 SECONDS)
#define HERETIC_BLOOD_VERDICT_STREAM_TIME (0.6 SECONDS)
#define HERETIC_BLOOD_VERDICT_GATHER_RADIUS 2
#define HERETIC_BLOOD_VERDICT_WAVE_RADIUS 3
#define HERETIC_BLOOD_VERDICT_WAVE_TIME (0.8 SECONDS)
#define HERETIC_BLOOD_VERDICT_FLASH_RANGE 4
#define HERETIC_BLOOD_VERDICT_FLASH_POWER 2
#define HERETIC_BLOOD_VERDICT_FLASH_TIME (0.5 SECONDS)
#define HERETIC_BLOOD_VERDICT_QUAKE 0.15
#define HERETIC_BLOOD_VERDICT_QUAKE_RADIUS 7
#define HERETIC_BLOOD_VERDICT_QUAKE_TIME (0.4 SECONDS)

/datum/heretic_path/blood
	id = PATH_BLOOD
	deed_type = /datum/heretic_deed/blood
	name = "Кровь"
	tagline = "Долг копится ударами, взыскание бьёт и лечит, Кровопускание роняет должника в обморок."
	craft_summary = "Хватка в «Помощи» по чужой крови ведёт к владельцу 3 минуты, пятно на полу становится меткой-ловушкой."
	capture_summary = "Кровопускание держит немого должника на нити 6 секунд до обморока; со 2-й секунды его уводит сердце."
	escape_summary = "Скользкая кровь за 10 своих ушибов на 5 секунд вырывает из захвата; из изнанки выходите к своей метке."
	strength_points = list(
		"Удар клинком сам связывает врага; взыскание бьёт по 2 ушиба за каждую единицу долга.",
		"Взыскание лечит раны, восполняет кровь и на 8 секунд вдвое ослабляет ваше кровотечение.",
		"Чужая кровь ведёт к владельцу 3 минуты, метки на полу сами связывают наступивших.",
		"На время Кровопускания цель немая и без рации, а в изнанке канал доигрывает до обморока.",
		"Скользкая кровь работает в чужой хватке: вырывает, ускоряет, валит преследователей.",
		"Вознёсшийся удваивает кровотечение врагов рядом и пьёт свежую кровь с пола.",
	)
	weakness_points = list(
		"Помеченная кровь не засыхает и пульсирует: швабра, космочист или нулевой жезл снимают метку.",
		"Кровопускание рвут стена, отход, антимагия, жезл, переливание, оглушение еретика и 2 секунды растолкать.",
		"Взыскание требует секунду прямой видимости в 5 клетках; укрытие или оглушение его срывают.",
		"С одной цели лечения не больше 10, пока держится её пустая печать; цель без разума не лечит.",
		"Скользкая кровь стоит 10 своих ушибов и не снимает наручники.",
		"Вознёсшегося держите дальше 3 клеток, перевязывайте раны и убирайте кровь с пола.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_blood,
		/datum/eldritch_knowledge/blood_grasp,
		/datum/eldritch_knowledge/spell/blood_drain,
		/datum/eldritch_knowledge/blood_mark,
		/datum/eldritch_knowledge/blood_relic,
		/datum/eldritch_knowledge/spell/blood_lance,
		/datum/eldritch_knowledge/spell/blood_slip,
		/datum/eldritch_knowledge/blood_vigor,
		/datum/eldritch_knowledge/spell/blood_reckoning,
		/datum/eldritch_knowledge/final_eldritch/blood_final,
	)

/datum/eldritch_knowledge/base_blood
	name = "Первая подпись"
	summary = "Удар клинком связывает врага долгом, «Связать / взыскать» бьёт по долгу; Хватка читает чужую кровь."
	details = list(
		"Нож и стеклянный осколок создают багровый клык: удар им связывает врага и даёт 6 долга раз в 2 секунды.",
		"Взыскание: секунда предупреждения, 2 ушиба за долг; ваше кровотечение 8 секунд вдвое слабее.",
		"Держите цель в 5 клетках без преград: без контакта связь рвётся через 2 секунды.",
		"Четверть урона лечит вас, 25% восполняет кровь - до 10 с цели; пустая печать помнит это 15 секунд.",
		"Хватка в «Помощи» по чужой крови 3 минуты ведёт к владельцу на вашем уровне, след раз в 2 секунды.",
		"Пятно - метка, до 3: враг в ней получает 6 долга раз в 10 секунд, если вы в 5 клетках и связь свободна.",
		"Швабра и жезл снимают метку; кровь нового человека продвигает дело и лечит 5; из изнанки - к метке.",
	)
	role = HERETIC_ROLE_CRAFT
	gain_text = "На белом листе появилась капля. Подпись уже была моей."
	route = PATH_BLOOD
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/shard)
	result_atoms = list(/obj/item/melee/sickly_blade/blood)
	combat_resource = 0
	combat_resource_max = 20
	combat_resource_name = "Кровный долг"
	resource_rules = list(
		"Долг копится на связи: одна связь до 20 долга, Книга обязательств добавляет связи и предел.",
		"«Связать / взыскать»: новый враг - связь и 10 долга, свой должник - 2 ушиба за долг через секунду.",
		"В «Разоружении» взыскивается до 10 долга, остаток и срок связи сохраняются.",
		"Клинок добавляет 6 долга раз в 2 секунды и продлевает связь; метка на полу даёт 6.",
		"Связь рвётся, если 2 секунды нет контакта: цель дальше 5 клеток, за преградой или вы не можете действовать.",
		"Взыскание лечит четверть урона и восполняет кровь, до 10 с одной цели; цель без разума не лечит.",
		"Взыскание на 8 секунд вдвое ослабляет ваше кровотечение.",
		"После взыскания, разрыва связи или смерти цели либо вашей пустая печать 15 секунд хранит пределы лечения с цели.",
		"Чаша тратит долг на лечение, Кровопускание списывает весь долг должника.",
	)
	combat_resource_action = /obj/effect/proc_holder/spell/pointed/heretic_blood/release
	grasp_visual = /obj/effect/temp_visual/heretic_blood/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/blood_grasp.ogg'
	grasp_catchphrase = "KRA'UJAS SKO'LINGAS"
	var/mob/living/blood_body
	var/ability_failure
	var/list/datum/status_effect/heretic_blood_seal/seals = list()
	/// Взысканные до конца связи: слота не занимают, но помнят вылеченное с цели.
	var/list/datum/status_effect/heretic_blood_seal/spent_seals = list()
	var/list/datum/status_effect/eldritch/blood/marks = list()
	var/list/obj/effect/temp_visual/heretic_blood/visuals = list()
	var/blood_generation = 0
	var/link_limit = 1
	var/debt_cap = 20
	var/datum/status_effect/heretic_blood_slip/blood_slip
	var/datum/status_effect/heretic_blood_clot/blood_clot
	var/ascension_active = FALSE
	/// Помеченные пятна, старейшее первым; значение - ловушка.
	var/list/obj/effect/decal/cleanable/blood/signs = list()

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
		blood_body.remove_status_effect(/datum/status_effect/heretic_blood_trail)
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
	QDEL_LIST(spent_seals)
	for(var/obj/effect/decal/cleanable/blood/pool as anything in signs.Copy())
		unmark_sign(pool)
	return ..()

/datum/eldritch_knowledge/base_blood/proc/clear_blood()
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in seals.Copy())
		seal.break_link("утрачена сила или тело еретика")
	seals.Cut()
	blood_generation++
	QDEL_LIST(marks)
	QDEL_LIST(visuals)
	QDEL_NULL(blood_slip)
	QDEL_NULL(blood_clot)
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_blood/proc/can_maintain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && !QDELETED(user) && isliving(user) && user == blood_body && user.stat == CONSCIOUS && isturf(user.loc) && heretic?.selected_path == PATH_BLOOD && !heretic.role_removed && heretic.get_knowledge(type) == src

/datum/eldritch_knowledge/base_blood/proc/can_use(mob/living/user, ignore_grab = FALSE)
	return can_maintain(user) && !user.incapacitated(ignore_grab = ignore_grab)

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
	return !victim_error(user, target)

/datum/eldritch_knowledge/base_blood/proc/victim_error(mob/living/user, atom/target)
	if(!can_use(user))
		return "Способность недоступна вашему пути или текущему телу."
	if(!isliving(target))
		return "Выберите самого противника: пол и предметы не подходят для кровной связи."
	var/mob/living/victim = target
	if(victim.stat == DEAD)
		return "Мёртвую цель нельзя связать кровью."
	if(victim == user || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
		return "Кровную связь нельзя направить на себя или другого служителя Мансуса."
	if(!isturf(victim.loc))
		return "Цель внутри контейнера или укрытия: дождитесь, пока она выйдет на пол."
	if(user.z != victim.z || get_dist(user, victim) > HERETIC_BLOOD_RANGE)
		return "Цель дальше пяти клеток или на другом уровне. Подойдите ближе."
	if(!line_clear(user, victim))
		return "Прямая линия до цели перекрыта. Найдите открытый путь для кровной связи."
	return null

/datum/eldritch_knowledge/base_blood/proc/validate_links()
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in seals.Copy())
		seal.validate_link()

/datum/eldritch_knowledge/base_blood/proc/pay_health(mob/living/user, amount, ignore_grab = FALSE)
	if(!can_use(user, ignore_grab) || amount <= 0)
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
	if(QDELETED(src) || QDELETED(user) || blood_generation != expected_generation || !can_use(user, ignore_grab))
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
	return combat_resource_payload(combat_resource_name, round(combat_resource, 0.1), combat_resource_max)

/datum/eldritch_knowledge/base_blood/combat_resource_state()
	. = "Связей: [length(seals)]/[link_limit]. Меток крови: [length(signs)] из [HERETIC_BLOOD_SIGN_LIMIT]."
	if(length(seals))
		. += " Чтобы нанести урон, нажмите индикатор долга и укажите своего должника. Хватка и клинок сами долг не взыскивают."
	else
		. += " Нажмите индикатор долга и укажите врага, чтобы создать связь."
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in seals)
		var/expected_damage = (seal.collecting ? seal.collection_amount : seal.debt) * HERETIC_BLOOD_DAMAGE_PER_DEBT
		. += " [html_encode(seal.owner.name)]: [round(seal.debt, 0.1)]/[debt_cap] долга → [round(expected_damage, 0.1)] ушибов[seal.collecting ? "; взыскание началось" : (!isnull(seal.contact_lost_at) ? "; связь слабеет" : "")]."

/datum/eldritch_knowledge/base_blood/on_mark_detonated(mob/living/user, mob/living/target)
	return

/datum/eldritch_knowledge/base_blood/gain_combat_resource(amount = 1)
	return

/datum/eldritch_knowledge/base_blood/spend_combat_resource(amount = 1)
	return FALSE

/datum/eldritch_knowledge/base_blood/proc/drop_foreign_spent(mob/living/victim)
	var/datum/status_effect/heretic_blood_seal/seal = victim?.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(seal?.spent && seal.blood_ref?.resolve() != src)
		qdel(seal)

/datum/eldritch_knowledge/base_blood/proc/release(mob/living/user, mob/living/victim, partial = FALSE)
	if(!valid_victim(user, victim))
		return FALSE
	drop_foreign_spent(victim)
	var/datum/status_effect/heretic_blood_seal/existing = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(existing && !existing.spent)
		return existing.blood_ref?.resolve() == src && existing.begin_collection(src, partial ? HERETIC_BLOOD_PARTIAL_COLLECTION : null)
	if(existing && existing.blood_ref?.resolve() != src)
		return FALSE
	if(length(seals) >= link_limit)
		to_chat(user, span_warning("Все кровные связи заняты. Взыщите долг прежнего врага кнопкой «Связать / взыскать» или разорвите связь отходом."))
		return FALSE
	if(!heretic_can_affect(user, victim))
		return TRUE
	var/datum/status_effect/heretic_blood_seal/seal = existing
	if(seal)
		if(!seal.revive(HERETIC_BLOOD_INITIAL_DEBT))
			return FALSE
	else
		seal = victim.apply_status_effect(/datum/status_effect/heretic_blood_seal, src)
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
	if((!seal || seal.spent) && release(user, victim))
		seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(add_debt(seal, HERETIC_BLOOD_STRIKE_DEBT, renew = TRUE))
		COOLDOWN_START(src, resource_harvest, HERETIC_BLOOD_HARVEST_TIME)

/datum/eldritch_knowledge/base_blood/proc/add_debt(datum/status_effect/heretic_blood_seal/seal, amount, renew = FALSE)
	if(QDELETED(seal) || seal.spent || seal.blood_ref?.resolve() != src || seal.collecting || !seal.validate_link())
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
	drop_foreign_spent(victim)
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(seal && (seal.blood_ref?.resolve() != src || seal.collecting))
		return FALSE
	if(!heretic_can_affect(user, victim))
		qdel(seal)
		return TRUE
	if((!seal || seal.spent) && release(user, victim))
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

/datum/eldritch_knowledge/base_blood/proc/blood_source(atom/target)
	if(istype(target, /obj/effect/decal/cleanable/blood))
		return isturf(target.loc)
	if(!isitem(target) || istype(target, /obj/item/melee/touch_attack))
		return FALSE
	return length(target.blood_DNA) || (target.reagents && (locate(/datum/reagent/blood) in target.reagents.reagent_list))

/// Чужие подписи на пятне, предмете и в крови внутри него; своя кровь и служебные ключи не в счёт.
/datum/eldritch_knowledge/base_blood/proc/blood_signatures(atom/source, mob/living/user)
	var/own_dna
	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		own_dna = carbon_user.dna?.unique_enzymes
	var/list/found = list()
	for(var/dna_key in source.blood_DNA)
		found |= dna_key
	if(source.reagents)
		for(var/datum/reagent/blood/sample in source.reagents.reagent_list)
			if(islist(sample.data) && sample.data["blood_DNA"])
				found |= sample.data["blood_DNA"]
	. = list()
	for(var/dna_key in found)
		if(dna_key != "color" && dna_key != "blendmode" && dna_key != own_dna)
			. += dna_key

/datum/eldritch_knowledge/base_blood/proc/blood_owner(signature)
	var/mob/living/carbon/corpse
	for(var/mob/living/carbon/candidate as anything in GLOB.carbon_list)
		if(QDELETED(candidate) || candidate.dna?.unique_enzymes != signature)
			continue
		if(candidate.stat != DEAD)
			return candidate
		if(!corpse)
			corpse = candidate
	return corpse

/datum/eldritch_knowledge/base_blood/proc/read_blood(mob/living/user, atom/source)
	grasp_failure_reason = null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !can_use(user) || QDELETED(source))
		return FALSE
	var/obj/effect/decal/cleanable/blood/stain = istype(source, /obj/effect/decal/cleanable/blood) ? source : null
	if(stain?.dried)
		grasp_failure_reason = "Засохшая кровь не держит подписи: найдите свежую."
		return FALSE
	var/list/signatures = blood_signatures(source, user)
	if(!length(signatures))
		grasp_failure_reason = "Здесь нет чужой подписи крови: собственная кровь и следы без ДНК не подходят."
		return FALSE
	var/fresh_signature
	var/counted_signature
	for(var/candidate in signatures)
		if(heretic.deed && !heretic.deed.complete() && !(candidate in heretic.deed.counted_keys))
			fresh_signature ||= candidate
		else
			counted_signature ||= candidate
	if(fresh_signature)
		var/wait_reason = heretic.deed_wait_reason(fresh_signature)
		if(wait_reason)
			if(!counted_signature)
				grasp_failure_reason = wait_reason
				return FALSE
			fresh_signature = null
	var/signature = fresh_signature || counted_signature
	var/mob/living/carbon/quarry = blood_owner(signature)
	if(quarry)
		user.apply_status_effect(/datum/status_effect/heretic_blood_trail, quarry)
		to_chat(user, span_eldritch("Это кровь [quarry.real_name]. [DisplayTimeText(HERETIC_BLOOD_TRAIL_DURATION)] вы чуете, в какой стороне этот человек и как он далеко, пока он на вашем уровне."))
	else
		to_chat(user, span_warning("Владелец этой крови не отзывается: следа нет."))
	if(stain)
		mark_sign(user, stain)
	log_game("[key_name(user)] читает кровь [quarry ? key_name(quarry) : signature] на [source] ([source.type]) в [AREACOORD(source)].")
	if(fresh_signature)
		heretic.advance_deed(fresh_signature, source)
	return TRUE

/datum/eldritch_knowledge/base_blood/proc/mark_sign(mob/living/user, obj/effect/decal/cleanable/blood/pool)
	if(pool in signs)
		return TRUE
	if(pool.GetComponent(/datum/component/heretic_craft))
		to_chat(user, span_warning("На этой крови уже лежит чужое ремесло: метка не встанет."))
		return FALSE
	for(var/obj/effect/decal/cleanable/blood/neighbour in pool.loc)
		if(neighbour in signs)
			to_chat(user, span_warning("На этой клетке уже есть ваша метка крови."))
			return FALSE
	while(length(signs) >= HERETIC_BLOOD_SIGN_LIMIT)
		var/obj/effect/decal/cleanable/blood/oldest = signs[1]
		log_game("[key_name(user)] теряет метку Крови на [oldest] в [AREACOORD(oldest)]: её вытеснила новая.")
		unmark_sign(oldest)
	pool.AddComponent(/datum/component/heretic_craft, src, HERETIC_BLOOD_SIGN_CRAFT, HERETIC_BLOOD_SIGN_CLUE)
	signs[pool] = new /datum/heretic_blood_sign(pool, src)
	to_chat(user, span_eldritch("Кровь перестаёт засыхать: пятно стало вашей меткой. Меток: [length(signs)] из [HERETIC_BLOOD_SIGN_LIMIT]."))
	log_game("[key_name(user)] ставит метку Крови на [pool] в [AREACOORD(pool)].")
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_blood/proc/unmark_sign(obj/effect/decal/cleanable/blood/pool)
	if(!(pool in signs))
		return
	var/datum/heretic_blood_sign/sign = signs[pool]
	signs -= pool
	qdel(sign)
	qdel(heretic_craft_on(pool, HERETIC_BLOOD_SIGN_CRAFT))
	notify_resource_changed()

/datum/eldritch_knowledge/base_blood/on_craft_removed(atom/crafted, craft_id)
	if(craft_id == HERETIC_BLOOD_SIGN_CRAFT)
		unmark_sign(crafted)

/datum/eldritch_knowledge/base_blood/pocket_exits(mob/living/user)
	. = list()
	for(var/obj/effect/decal/cleanable/blood/pool as anything in signs)
		heretic_add_pocket_exit(., "Кровь - [get_area_name(pool, TRUE)]", heretic_pocket_landing(get_turf(pool)))

/datum/eldritch_knowledge/base_blood/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	return list("name" = "в кровь", "text" = "Кровь под [victim] раскрывается, как рана.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))

/// Своё Кровопускание идёт не меньше HERETIC_BLOOD_DRAIN_DOOR_DELAY (еретик в 3 клетках), цель в обмороке от него или готова к обряду на клетке с кровью (еретик рядом).
/datum/eldritch_knowledge/base_blood/proc/door_holds(mob/living/user, mob/living/victim)
	if(!can_use(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z)
		return FALSE
	var/distance = get_dist(user, victim)
	if(distance <= HERETIC_BLOOD_DRAIN_DOOR_RANGE && drain_opens_door(victim))
		return TRUE
	if(distance > 1)
		return FALSE
	if(knocked_out_by_capture(victim))
		return TRUE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic.hunt_target_ready(victim) && !!(locate(/obj/effect/decal/cleanable/blood) in victim.loc)

/datum/eldritch_knowledge/base_blood/proc/drain_opens_door(mob/living/victim)
	var/datum/status_effect/heretic_blood_drain/drain = victim.has_status_effect(/datum/status_effect/heretic_blood_drain)
	return drain?.blood_ref?.resolve() == src && world.time >= drain.started_at + HERETIC_BLOOD_DRAIN_DOOR_DELAY

/// Должник в изнанке этого еретика: связь цела, пока он внутри, даже если еретик ещё не вошёл следом.
/datum/eldritch_knowledge/base_blood/proc/shares_pocket(mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(blood_body)
	var/datum/heretic_pocket/pocket = heretic?.pocket
	return pocket?.active && pocket.victim == victim && pocket.contains(victim)

/datum/eldritch_knowledge/base_blood/proc/spring_sign(obj/effect/decal/cleanable/blood/pool, mob/living/victim)
	if(!valid_victim(blood_body, victim) || !heretic_can_affect(blood_body, victim, chargecost = 0))
		return FALSE
	drop_foreign_spent(victim)
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(seal && !seal.spent)
		if(!add_debt(seal, HERETIC_BLOOD_TRAP_DEBT, renew = TRUE))
			return FALSE
	else
		if(length(seals) >= link_limit)
			return FALSE
		if(seal)
			if(seal.blood_ref?.resolve() != src || !seal.revive(HERETIC_BLOOD_TRAP_DEBT))
				return FALSE
		else
			seal = victim.apply_status_effect(/datum/status_effect/heretic_blood_seal, src)
			if(!seal || QDELETED(seal))
				return FALSE
			seal.debt = min(HERETIC_BLOOD_TRAP_DEBT, debt_cap)
		update_debt()
	to_chat(blood_body, span_eldritch("[victim] ступает в вашу метку крови ([get_area_name(pool, TRUE)]): [round(seal.debt, 0.1)] долга."))
	to_chat(victim, span_userdanger("Кровь под ногами липнет к подошвам и тянется нитью к [blood_body]!"))
	log_combat(blood_body, victim, "связывает меткой крови", addition = "метка в [AREACOORD(pool)]")
	return TRUE

/// Метка на пятне крови: враг, вошедший на клетку, связывается с еретиком.
/datum/heretic_blood_sign
	var/obj/effect/decal/cleanable/blood/pool
	var/turf/place
	var/datum/eldritch_knowledge/base_blood/blood
	COOLDOWN_DECLARE(trap_cooldown)

/datum/heretic_blood_sign/New(obj/effect/decal/cleanable/blood/pool, datum/eldritch_knowledge/base_blood/blood)
	src.pool = pool
	src.blood = blood
	place = pool.loc
	RegisterSignal(place, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))

/datum/heretic_blood_sign/Destroy()
	if(place)
		UnregisterSignal(place, COMSIG_ATOM_ENTERED)
	pool = null
	place = null
	blood = null
	return ..()

/datum/heretic_blood_sign/proc/on_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(!ishuman(arrived) || !COOLDOWN_FINISHED(src, trap_cooldown))
		return
	if(blood.spring_sign(pool, arrived))
		COOLDOWN_START(src, trap_cooldown, HERETIC_BLOOD_TRAP_COOLDOWN)

/datum/status_effect/heretic_blood_trail
	id = "heretic_blood_trail"
	duration = HERETIC_BLOOD_TRAIL_DURATION
	tick_interval = HERETIC_BLOOD_TRAIL_INTERVAL
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_blood_trail
	var/datum/weakref/quarry_ref
	var/quarry_name
	var/trail_text

/datum/status_effect/heretic_blood_trail/on_creation(mob/living/new_owner, mob/living/quarry)
	quarry_ref = WEAKREF(quarry)
	quarry_name = quarry?.real_name
	. = ..()
	if(!QDELETED(src))
		update_trail()

/datum/status_effect/heretic_blood_trail/tick()
	update_trail()

/datum/status_effect/heretic_blood_trail/proc/update_trail()
	var/mob/living/quarry = quarry_ref?.resolve()
	var/turf/here = get_turf(owner)
	var/turf/there = get_turf(quarry)
	var/state = "blood_trail_null"
	var/direction = SOUTH
	if(!there)
		trail_text = "след оборвался"
	else if(here?.z != there.z)
		trail_text = "след ушёл с уровня"
	else
		var/distance = get_dist(here, there)
		var/side = GLOB.heretic_mansus_directions["[get_dir(here, there)]"]
		if(!distance)
			trail_text = "прямо здесь"
			state = "blood_trail_direct"
		else
			direction = get_dir(here, there)
			if(distance <= HERETIC_BLOOD_TRAIL_NEAR)
				trail_text = "рядом, [side]"
				state = "blood_trail_close"
			else if(distance <= HERETIC_BLOOD_TRAIL_FAR)
				trail_text = "недалеко, [side]"
				state = "blood_trail_medium"
			else
				trail_text = "далеко, [side]"
				state = "blood_trail_far"
	if(!linked_alert)
		return
	linked_alert.name = "След крови: [quarry_name]"
	linked_alert.desc = "[quarry_name]: [trail_text]. След обновляется раз в [HERETIC_BLOOD_TRAIL_INTERVAL / (1 SECONDS)] секунды и виден только на вашем уровне."
	linked_alert.icon_state = state
	linked_alert.setDir(direction)

/atom/movable/screen/alert/status_effect/heretic_blood_trail
	name = "След крови"
	desc = "Прочитанная кровь ведёт к своему владельцу."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "blood_trail_null"

/datum/eldritch_knowledge/base_blood/proc/drain_block_reason(mob/living/user, atom/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/blood_drain)
	if(!can_use(user) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_capture_block_reason(user, target, HERETIC_BLOOD_CAPTURE)
	if(reason)
		return reason
	var/mob/living/carbon/human/victim = target
	if(!ishuman(victim) || (NOBLOOD in victim.dna.species.species_traits) || victim.blood_volume <= 0)
		return "Пускать нечего: у цели нет крови."
	if(victim.has_status_effect(/datum/status_effect/heretic_blood_drain))
		return "Кровь цели уже уходит."
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(seal?.blood_ref?.resolve() != src || seal.spent)
		return "Кровопускание берёт только вашего должника: сначала свяжите цель."
	if(seal.collecting)
		return "С цели уже взыскивается долг: дождитесь удара."
	if(!seal.validate_link())
		return "Нить к должнику прервана: нужна открытая линия не дальше пяти клеток."
	if(seal.debt < HERETIC_BLOOD_DRAIN_DEBT)
		return "Нужно не меньше [HERETIC_BLOOD_DRAIN_DEBT] долга на цели, сейчас [round(seal.debt, 0.1)]."
	return null

/datum/eldritch_knowledge/base_blood/proc/drain(mob/living/user, mob/living/carbon/human/victim)
	ability_failure = drain_block_reason(user, victim)
	if(ability_failure)
		return FALSE
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/status_effect/heretic_blood_drain/effect = victim.apply_status_effect(/datum/status_effect/heretic_blood_drain, src, seal)
	if(!effect || QDELETED(effect))
		ability_failure = "Нить не удержала цель."
		return FALSE
	var/written_off = seal.debt
	seal.debt = 0
	update_debt()
	log_combat(user, victim, "начинает Кровопускание", addition = "списано [round(written_off, 0.1)] долга")
	return TRUE

/datum/status_effect/heretic_blood_drain
	id = "heretic_blood_drain"
	duration = HERETIC_BLOOD_DRAIN_TELEGRAPH + HERETIC_BLOOD_DRAIN_DURATION
	tick_interval = HERETIC_BLOOD_CHECK_INTERVAL
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_blood_drain
	examine_text = span_warning("SUBJECTPRONOUN бледнеет, от кожи к еретику тянется натянутая багровая нить. Уведите за стену, оглушите еретика, коснитесь цели нулевым жезлом, перелейте ей кровь или растолкайте 2 секунды.")
	var/datum/weakref/blood_ref
	var/datum/status_effect/heretic_blood_seal/seal
	var/mob/living/drainer
	var/channel_timer
	var/channel_started = FALSE
	var/channel_starts_at
	var/started_at
	var/drain_goal = 0
	var/drained = 0
	var/last_blood_total = 0
	var/applied = FALSE
	var/interrupted = FALSE
	var/fainted = FALSE
	COOLDOWN_DECLARE(leash_message)

/datum/status_effect/heretic_blood_drain/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_blood/blood, datum/status_effect/heretic_blood_seal/seal)
	blood_ref = WEAKREF(blood)
	src.seal = seal
	drainer = blood?.blood_body
	return ..()

/datum/status_effect/heretic_blood_drain/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(!. || !blood || !ishuman(owner) || QDELETED(drainer) || QDELETED(seal) || seal.blood_ref?.resolve() != blood)
		return FALSE
	applied = TRUE
	started_at = world.time
	channel_starts_at = world.time + HERETIC_BLOOD_DRAIN_TELEGRAPH
	seal.expires_at = max(seal.expires_at, channel_starts_at + HERETIC_BLOOD_DRAIN_SEAL_MARGIN)
	RegisterSignal(seal, COMSIG_PARENT_QDELETING, PROC_REF(on_seal_lost))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, PROC_REF(on_sacrifice_starting))
	RegisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(on_pre_move))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(on_shaken))
	RegisterSignal(drainer, COMSIG_MOVABLE_MOVED, PROC_REF(pull_close))
	heretic_capture_hold(owner, HERETIC_BLOOD_CAPTURE)
	channel_timer = addtimer(CALLBACK(src, PROC_REF(start_channel)), HERETIC_BLOOD_DRAIN_TELEGRAPH, TIMER_STOPPABLE)
	seal.seal_overlay.icon_state = "blood_warning"
	owner.update_icon()
	heretic_vfx_thread(drainer, owner, heretic_path_ink(PATH_BLOOD, TRUE), HERETIC_BLOOD_DRAIN_TELEGRAPH)
	owner.visible_message(span_danger("Кровяная нить между [drainer] и [owner] наливается багровым!"), span_userdanger("Кровяная нить к [drainer] краснеет и натягивается: через секунду из вас потечёт кровь! Уйдите за стену или дальше пяти клеток."))
	playsound(owner, 'modular_bluemoon/sound/heretic/blood_grasp.ogg', 40, TRUE)
	return TRUE

/datum/status_effect/heretic_blood_drain/proc/link_failure()
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(drainer)
	if(!blood || QDELETED(drainer) || !heretic?.get_knowledge(/datum/eldritch_knowledge/spell/blood_drain))
		return "еретик утратил Кровопускание"
	if(owner.stat == DEAD)
		return "цель умерла"
	if(QDELETED(seal) || seal.blood_ref?.resolve() != blood || !seal.validate_link())
		return "кровная связь разорвана"
	return null

/datum/status_effect/heretic_blood_drain/proc/blood_total()
	return owner.blood_volume + owner.integrating_blood

/datum/status_effect/heretic_blood_drain/proc/start_channel()
	deltimer(channel_timer)
	channel_timer = null
	if(channel_started || QDELETED(src))
		return
	var/reason = link_failure()
	if(reason)
		interrupt(reason)
		return
	channel_started = TRUE
	channel_starts_at = world.time
	duration = world.time + HERETIC_BLOOD_DRAIN_DURATION
	seal.expires_at = max(seal.expires_at, duration + HERETIC_BLOOD_DRAIN_SEAL_MARGIN)
	drain_goal = max(0, min(BLOOD_VOLUME_NORMAL * owner.blood_ratio * HERETIC_BLOOD_DRAIN_FRACTION, owner.blood_volume - BLOOD_VOLUME_SAFE))
	last_blood_total = blood_total()
	ADD_TRAIT(owner, TRAIT_MUTE, HERETIC_BLOOD_DRAIN_TRAIT)
	RegisterSignal(owner, COMSIG_MOVABLE_USING_RADIO, PROC_REF(jam_radio))
	owner.visible_message(span_danger("Из пор [owner] проступает кровь и тянется по нити к [drainer]!"), span_userdanger("Кровь уходит по нити к [drainer]: горло сжато, ни крикнуть, ни позвать по рации, а дальше трёх клеток от еретика не отойти!"))
	pull_close()

/datum/status_effect/heretic_blood_drain/tick()
	var/reason = link_failure()
	if(reason)
		interrupt(reason)
		return
	if(!channel_started)
		return
	if(blood_total() > last_blood_total + HERETIC_BLOOD_DRAIN_REFILL_MARGIN)
		interrupt("цели перелили кровь")
		return
	drain_to(drain_goal * min(1, (world.time - channel_starts_at) / HERETIC_BLOOD_DRAIN_DURATION))
	pull_close()
	last_blood_total = blood_total()

/// Кровь не опускается ниже BLOOD_VOLUME_SAFE: ниже начинается удушье от кровопотери.
/datum/status_effect/heretic_blood_drain/proc/drain_to(amount)
	var/take = amount - drained
	if(take <= 0)
		return
	drained += take
	var/before = owner.blood_volume
	owner.blood_volume = max(min(before, BLOOD_VOLUME_SAFE), before - take)

/datum/status_effect/heretic_blood_drain/proc/pull_close()
	SIGNAL_HANDLER
	if(!channel_started || QDELETED(drainer) || QDELETED(src))
		return
	var/turf/anchor = get_turf(drainer)
	for(var/step_index in 1 to HERETIC_BLOOD_DRAIN_LEASH)
		var/turf/here = get_turf(owner)
		if(!anchor || !here || here.z != anchor.z || get_dist(here, anchor) <= HERETIC_BLOOD_DRAIN_LEASH)
			return
		var/turf/next = get_step_towards(here, anchor)
		if(!isopenturf(next) || isgroundlessturf(next) || !owner.Move(next, get_dir(here, next)))
			return

/datum/status_effect/heretic_blood_drain/proc/on_pre_move(atom/movable/source, atom/newloc)
	SIGNAL_HANDLER
	if(!channel_started || QDELETED(drainer))
		return NONE
	var/turf/anchor = get_turf(drainer)
	var/turf/destination = get_turf(newloc)
	var/turf/here = get_turf(owner)
	if(!anchor || !destination || !here || destination.z != anchor.z)
		return NONE
	var/distance = get_dist(destination, anchor)
	if(distance <= HERETIC_BLOOD_DRAIN_LEASH || distance < get_dist(here, anchor))
		return NONE
	if(COOLDOWN_FINISHED(src, leash_message))
		COOLDOWN_START(src, leash_message, HERETIC_BLOOD_LEASH_MESSAGE_COOLDOWN)
		to_chat(owner, span_warning("Кровяная нить держит вас: дальше трёх клеток от еретика не уйти."))
	return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

/datum/status_effect/heretic_blood_drain/proc/jam_radio(atom/movable/source, obj/item/radio/radio)
	SIGNAL_HANDLER
	return COMPONENT_CANNOT_USE_RADIO

/datum/status_effect/heretic_blood_drain/proc/on_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	user.visible_message(span_warning("[user] касается [source] нулевым жезлом, и кровяная нить лопается."), span_notice("Вы касаетесь [source] нулевым жезлом, и кровяная нить лопается."))
	log_game("[key_name(user)] обрывает Кровопускание у [key_name(source)] нулевым жезлом в [AREACOORD(source)].")
	interrupt("нулевой жезл")
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_blood_drain/proc/on_sacrifice_starting(datum/source)
	SIGNAL_HANDLER
	interrupted = TRUE
	qdel(src)

/datum/status_effect/heretic_blood_drain/proc/on_seal_lost(datum/source)
	SIGNAL_HANDLER
	interrupt("кровная связь разорвана")

/datum/status_effect/heretic_blood_drain/proc/on_shaken(datum/source)
	SIGNAL_HANDLER
	interrupt("цель растолкали")

/datum/status_effect/heretic_blood_drain/proc/interrupt(reason)
	if(QDELETED(src))
		return
	interrupted = TRUE
	if(!QDELETED(drainer))
		to_chat(drainer, span_warning("Кровопускание [owner] сорвано: [reason]."))
	to_chat(owner, span_notice("Кровяная нить обрывается: [reason]."))
	qdel(src)

/datum/status_effect/heretic_blood_drain/on_remove()
	if(applied)
		deltimer(channel_timer)
		channel_timer = null
		UnregisterSignal(owner, list(COMSIG_PARENT_ATTACKBY, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_MOVABLE_PRE_MOVE, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_MOVABLE_USING_RADIO))
		REMOVE_TRAIT(owner, TRAIT_MUTE, HERETIC_BLOOD_DRAIN_TRAIT)
		heretic_capture_unhold(owner, HERETIC_BLOOD_CAPTURE)
		if(drainer)
			UnregisterSignal(drainer, COMSIG_MOVABLE_MOVED)
		if(seal)
			UnregisterSignal(seal, COMSIG_PARENT_QDELETING)
		// Истёкший срок без срыва отличает досмотренное Кровопускание от прерванного.
		if(!interrupted && channel_started && world.time >= duration && !link_failure())
			drain_to(drain_goal)
			fainted = TRUE
			owner.Unconscious(HERETIC_BLOOD_DRAIN_FAINT)
			heretic_capture_knock_out(owner, blood_ref?.resolve(), HERETIC_BLOOD_CAPTURE, HERETIC_BLOOD_DRAIN_FAINT)
			owner.visible_message(span_danger("[owner] бледнеет и оседает без сознания."), span_userdanger("Кровь уходит последней каплей, и всё темнеет."))
			log_combat(drainer, owner, "обескровливает до обморока", addition = "потеряно до [round(drained, 0.1)] крови")
		if(!QDELETED(seal) && !seal.collecting)
			seal.seal_overlay.icon_state = "blood_mark"
			owner.update_icon()
		heretic_capture_release(owner, HERETIC_BLOOD_CAPTURE, fainted ? HERETIC_BLOOD_DRAIN_FAINT : 0)
	seal = null
	drainer = null
	blood_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_blood_drain
	name = "Кровопускание"
	desc = "Кровяная нить тянет из вас кровь. Через секунду предупреждения 6 секунд вы не сможете отойти от еретика дальше трёх клеток, не сможете говорить ни вслух, ни по рации, уходит до 15% крови, но не ниже безопасного уровня. Если нить выдержит - обморок на 10 секунд. Уйдите за стену, пусть еретика оглушат, коснутся вас нулевым жезлом, перельют вам кровь или растолкают 2 секунды."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "blood_letting"

/datum/eldritch_knowledge/base_blood/proc/slip_failure(mob/living/user)
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/blood_slip)
	if(!can_use(user, ignore_grab = TRUE) || QDELETED(required))
		return "Скользкая кровь недоступна: нужно изучить её, быть в сознании и в своём теле еретика."
	return null

/datum/eldritch_knowledge/base_blood/proc/slip(mob/living/user)
	ability_failure = slip_failure(user)
	if(ability_failure)
		return FALSE
	if(!pay_health(user, HERETIC_BLOOD_SLIP_PAYMENT, ignore_grab = TRUE))
		ability_failure = can_use(user, ignore_grab = TRUE) ? "Для Скользкой крови слишком мало здоровья: новая рана оставит меньше безопасного запаса." : "Оплата прервана: вы больше не можете действовать."
		return FALSE
	var/datum/status_effect/heretic_blood_slip/effect = user.has_status_effect(/datum/status_effect/heretic_blood_slip)
	if(effect)
		effect.refresh()
	else
		effect = user.apply_status_effect(/datum/status_effect/heretic_blood_slip, src)
	blood_slip = (effect && !QDELETED(effect)) ? effect : null
	new /obj/effect/temp_visual/heretic_blood/pact(get_turf(user), src)
	user.visible_message(span_danger("[user] проводит пальцами по свежей ране, и кровь делает кожу скользкой!"), span_notice("Кровь делает вас скользким: [DisplayTimeText(HERETIC_BLOOD_SLIP_DURATION)] никто вас не удержит."))
	log_game("[key_name(user)] применяет Скользкую кровь в [AREACOORD(user)].")
	return TRUE

/datum/status_effect/heretic_blood_slip
	id = "heretic_blood_slip"
	duration = HERETIC_BLOOD_SLIP_DURATION
	tick_interval = HERETIC_BLOOD_CHECK_INTERVAL
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_blood_slip
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/blood_ref
	var/applied = FALSE

/datum/status_effect/heretic_blood_slip/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_blood/blood)
	if(QDELETED(blood))
		qdel(src)
		return
	blood_ref = WEAKREF(blood)
	return ..()

/datum/status_effect/heretic_blood_slip/on_apply()
	if(!..())
		return FALSE
	applied = TRUE
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_slip)
	ADD_TRAIT(owner, TRAIT_UNPULLABLE, HERETIC_BLOOD_SLIP_TRAIT)
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	break_free()
	return TRUE

/datum/status_effect/heretic_blood_slip/refresh()
	. = ..()
	break_free()

/datum/status_effect/heretic_blood_slip/proc/break_free()
	var/atom/movable/grabber = owner.pulledby
	if(grabber)
		grabber.stop_pulling()
		owner.visible_message(span_warning("[owner] выскальзывает из рук [grabber], оставив на них кровь."), span_notice("Вы выскальзываете из рук [grabber]."))
		log_combat(owner, grabber, "выскальзывает Скользкой кровью из захвата")
	if(ismob(owner.buckled))
		var/mob/living/carrier = owner.buckled
		carrier.unbuckle_mob(owner, TRUE)
		owner.visible_message(span_warning("[owner] соскальзывает с [carrier]."), span_notice("Вы соскальзываете с [carrier]."))
		log_combat(owner, carrier, "соскальзывает Скользкой кровью с")

/datum/status_effect/heretic_blood_slip/tick()
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(owner)
	if(!blood?.can_maintain(owner) || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/blood_slip))
		qdel(src)
		return
	break_free()

/datum/status_effect/heretic_blood_slip/proc/on_moved(atom/movable/source, atom/old_loc)
	SIGNAL_HANDLER
	var/turf/open/left = old_loc
	if(!istype(left) || isgroundlessturf(left) || left == owner.loc)
		return
	var/obj/effect/heretic_blood_slick/slick = locate() in left
	if(slick)
		slick.refresh()
	else
		new /obj/effect/heretic_blood_slick(left, owner, get_dir(left, owner))

/datum/status_effect/heretic_blood_slip/on_remove()
	if(applied)
		UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
		REMOVE_TRAIT(owner, TRAIT_UNPULLABLE, HERETIC_BLOOD_SLIP_TRAIT)
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_slip)
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(blood?.blood_slip == src)
		blood.blood_slip = null
	blood_ref = null
	return ..()

/datum/movespeed_modifier/heretic_blood_slip
	multiplicative_slowdown = HERETIC_BLOOD_SLIP_HASTE

/atom/movable/screen/alert/status_effect/heretic_blood_slip
	name = "Скользкая кровь"
	desc = "5 секунд вы выскальзываете из любого захвата, никто не может схватить вас заново, вы бегаете быстрее, а за вами тянется скользкая кровь. Наручники это не снимает."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "blood_slick"

/// Кровавый след Скользкой крови скользит, как мокрый пол; хозяин и слуги Мансуса проходят.
/obj/effect/heretic_blood_slick
	name = "slick blood"
	desc = "Размазанная кровь блестит, будто не высыхает. На ней поскальзываются, как на мокром полу; шагом пройти можно. Скоро она впитается."
	icon = 'icons/effects/blood.dmi'
	icon_state = "tracks"
	color = BLOOD_COLOR_HUMAN
	blend_mode = BLEND_MULTIPLY
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_NORMAL_TURF_LAYER
	var/datum/weakref/owner_ref
	var/expiry_timer

/obj/effect/heretic_blood_slick/Initialize(mapload, mob/living/owner, direction)
	. = ..()
	owner_ref = WEAKREF(owner)
	if(direction)
		setDir(direction)
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	refresh()

/obj/effect/heretic_blood_slick/Destroy()
	deltimer(expiry_timer)
	expiry_timer = null
	return ..()

/obj/effect/heretic_blood_slick/proc/refresh()
	deltimer(expiry_timer)
	expiry_timer = QDEL_IN_STOPPABLE(src, HERETIC_BLOOD_SLICK_LIFETIME)

/obj/effect/heretic_blood_slick/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(!iscarbon(arrived) || arrived == owner_ref?.resolve())
		return
	var/mob/living/carbon/runner = arrived
	if(IS_HERETIC(runner) || IS_HERETIC_MONSTER(runner))
		return
	runner.slip(HERETIC_BLOOD_SLICK_KNOCKDOWN, src, NO_SLIP_WHEN_WALKING)

/datum/eldritch_knowledge/base_blood/proc/reckoning(mob/living/user)
	ability_failure = null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/blood_reckoning)
	if(!can_use(user) || QDELETED(required))
		ability_failure = "Взыскание недоступно: нужно изучить его и находиться в своём теле еретика."
		return FALSE
	if(!length(seals))
		ability_failure = "Нет кровных связей. Сначала свяжите противника Хваткой или способностью «Связать / взыскать»."
		return FALSE
	var/started = FALSE
	var/already_collecting = FALSE
	for(var/datum/status_effect/heretic_blood_seal/seal as anything in seals.Copy())
		if(QDELETED(seal))
			continue
		if(!valid_victim(user, seal.owner))
			continue
		if(seal.collecting)
			already_collecting = TRUE
			continue
		add_debt(seal, HERETIC_BLOOD_STRIKE_DEBT, renew = TRUE)
		if(seal.begin_collection(required))
			started = TRUE
	if(started)
		playsound(user, 'modular_bluemoon/sound/heretic/blood_reckoning.ogg', 70, TRUE)
	else
		ability_failure = already_collecting ? "С доступных должников уже взыскивается долг. Дождитесь удара." : "Нет доступных должников: восстановите открытую линию до своей цели в пределах пяти клеток или создайте новую связь."
	return started

/datum/eldritch_knowledge/base_blood/proc/coronation(mob/living/user, mob/living/victim)
	if(!can_use(user) || !can_use_ascension(user) || !valid_victim(user, victim))
		return FALSE
	var/datum/status_effect/heretic_blood_seal/chosen = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(chosen?.blood_ref?.resolve() != src || chosen.collecting || !chosen.validate_link())
		return FALSE
	var/list/donor_turfs = list()
	for(var/datum/status_effect/heretic_blood_seal/donor as anything in seals.Copy())
		if(donor == chosen || donor.collecting || !donor.validate_link())
			continue
		var/transferred = min(donor.debt, debt_cap - chosen.debt)
		if(transferred > 0)
			donor_turfs += get_turf(donor.owner)
		chosen.debt += transferred
		donor.debt -= transferred
		if(donor.debt <= 0)
			donor.spend()
	chosen.expires_at = world.time + HERETIC_BLOOD_LINK_LIFETIME
	update_debt()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!chosen.begin_collection(heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/blood_final)))
		return FALSE
	verdict_threads_fx(donor_turfs, victim)
	return TRUE

/// Кровный приговор: нити крови от прочих должников втягиваются в выбранного, вокруг него к удару смыкается кольцо.
/datum/eldritch_knowledge/base_blood/proc/verdict_threads_fx(list/donor_turfs, mob/living/chosen)
	var/ink = heretic_path_ink(PATH_BLOOD, TRUE)
	for(var/turf/donor_turf as anything in donor_turfs)
		var/obj/effect/temp_visual/heretic_vfx/thread/thread = heretic_vfx_thread(donor_turf, chosen, ink, HERETIC_BLOOD_COLLECTION_DELAY)
		if(thread)
			thread.alpha = 0
			thread.reel(HERETIC_BLOOD_VERDICT_REEL)
			animate(thread, alpha = 255, time = HERETIC_BLOOD_VERDICT_THREAD_FADE, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
		heretic_vfx_stream(donor_turf, chosen, /particles/heretic_ascension/blood/verdict, HERETIC_BLOOD_VERDICT_STREAM_TIME)
	heretic_vfx_gather(chosen, ink, HERETIC_BLOOD_VERDICT_GATHER_RADIUS, HERETIC_BLOOD_COLLECTION_DELAY)
	heretic_vfx_pulse(chosen, ink, 2, HERETIC_BLOOD_COLLECTION_DELAY)

/// Удар приговора: багровая волна, выброс крови, вспышка и дрожь земли.
/datum/eldritch_knowledge/base_blood/proc/verdict_strike_fx(mob/living/victim)
	var/ink = heretic_path_ink(PATH_BLOOD, TRUE)
	heretic_vfx_shockwave(victim, ink, HERETIC_BLOOD_VERDICT_WAVE_RADIUS, HERETIC_BLOOD_VERDICT_WAVE_TIME)
	heretic_vfx_burst(victim, /particles/heretic_ascension/blood)
	heretic_vfx_flash(victim, ink, HERETIC_BLOOD_VERDICT_FLASH_RANGE, HERETIC_BLOOD_VERDICT_FLASH_POWER, HERETIC_BLOOD_VERDICT_FLASH_TIME)
	heretic_vfx_quake(victim, HERETIC_BLOOD_VERDICT_QUAKE_RADIUS, HERETIC_BLOOD_VERDICT_QUAKE, HERETIC_BLOOD_VERDICT_QUAKE_TIME)

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
	icon_state = "blood_clot"

/datum/status_effect/heretic_blood_exsanguinated
	id = "heretic_blood_exsanguinated"
	duration = HERETIC_BLOOD_EXSANGUINE_DURATION
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_blood_exsanguinated
	examine_text = span_warning("SUBJECTPRONOUN бледен и пошатывается: кровь отхлынула от лица.")

/datum/status_effect/heretic_blood_exsanguinated/on_apply()
	if(!..())
		return FALSE
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_exsanguinated)
	owner.blur_eyes(HERETIC_BLOOD_EXSANGUINE_BLUR)
	return TRUE

/datum/status_effect/heretic_blood_exsanguinated/refresh()
	. = ..()
	owner.blur_eyes(HERETIC_BLOOD_EXSANGUINE_BLUR)

/datum/status_effect/heretic_blood_exsanguinated/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_exsanguinated)
	return ..()

/datum/movespeed_modifier/heretic_blood_exsanguinated
	multiplicative_slowdown = HERETIC_BLOOD_EXSANGUINE_SLOWDOWN

/atom/movable/screen/alert/status_effect/heretic_blood_exsanguinated
	name = "Обескровлен"
	desc = "Взыскание долгов выпило из вас кровь: 4 секунды вы движетесь медленнее и видите размыто."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "blood_drained"

/datum/eldritch_knowledge/base_blood/proc/refund(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/blood_relic)
	if(!can_use(user) || QDELETED(required) || !valid_victim(user, victim))
		return FALSE
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	if(seal?.blood_ref?.resolve() != src || seal.collecting || !seal.validate_link())
		return FALSE
	if(!victim.mind)
		to_chat(user, span_warning("Кровь без разума не лечит: чаша пьёт только из разумных."))
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
		seal.spend()
	else
		update_debt()
	to_chat(user, span_notice("Чаша залечивает [round(healed, 0.1)] ушибов и ожогов.[QDELETED(seal) || seal.spent ? " Долг исчерпан; можно связать новую цель." : " Остаток долга [victim]: [round(seal.debt, 0.1)]."]"))
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
	var/link_end_reason = "утрачена связь с владельцем"
	var/spent = FALSE

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
	warn_owner(blood)
	return TRUE

/datum/status_effect/heretic_blood_seal/proc/warn_owner(datum/eldritch_knowledge/base_blood/blood)
	to_chat(owner, span_userdanger("От вас к [blood.blood_body] тянется кровяная жила. Его удары увеличивают долг, а взыскание лечит его! Скройтесь за преградой или отойдите дальше пяти клеток на две секунды. Если взыскание уже началось, потеря контакта сразу его сорвёт."))

/datum/status_effect/heretic_blood_seal/proc/update_seal_overlay(atom/source, list/overlays)
	SIGNAL_HANDLER
	if(!spent)
		overlays += seal_overlay

/datum/status_effect/heretic_blood_seal/proc/on_owner_death(datum/source)
	SIGNAL_HANDLER
	if(source != owner)
		link_end_reason = "утрачено знание взыскания"
		qdel(src)
		return
	if(spent)
		return
	// Смерть посреди взыскания: убивший удар detonate() ещё засчитает лечение, поэтому печать пустеет при любом счёте.
	if(!collecting)
		break_link("должник умер")
		return
	link_end_reason = "должник умер"
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(blood)
		announce_loss(blood)
	spend()

/datum/status_effect/heretic_blood_seal/proc/on_owner_moved(datum/source)
	SIGNAL_HANDLER
	validate_link()

/datum/status_effect/heretic_blood_seal/tick()
	if(!spent)
		validate_link()
	else if(world.time >= expires_at)
		qdel(src)

/// Пустая печать после полного взыскания: связи нет, а счётчики лечения и крови с этой цели сохраняются.
/datum/status_effect/heretic_blood_seal/proc/spend()
	if(spent)
		return
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(!blood || QDELETED(owner))
		qdel(src)
		return
	reset_collection()
	spent = TRUE
	debt = 0
	contact_lost_at = null
	expires_at = world.time + HERETIC_BLOOD_SPENT_LIFETIME
	blood.seals -= src
	blood.spent_seals |= src
	QDEL_NULL(link_beam)
	owner.clear_alert(id)
	linked_alert = null
	owner.update_icon()
	blood.update_debt()

/datum/status_effect/heretic_blood_seal/proc/revive(new_debt)
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(!spent || !blood || length(blood.seals) >= blood.link_limit)
		return FALSE
	spent = FALSE
	expected_generation = blood.blood_generation
	blood.spent_seals -= src
	blood.seals |= src
	debt = min(new_debt, blood.debt_cap)
	expires_at = world.time + HERETIC_BLOOD_LINK_LIFETIME
	var/atom/movable/screen/alert/status_effect/alert = owner.throw_alert(id, alert_type)
	if(istype(alert))
		alert.attached_effect = src
		linked_alert = alert
	owner.update_icon()
	warn_owner(blood)
	return validate_link()

/datum/status_effect/heretic_blood_seal/proc/validate_link()
	if(QDELETED(src) || spent)
		return FALSE
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(!blood || blood.blood_generation != expected_generation || !blood.can_maintain(blood.blood_body))
		return break_link("утрачена сила или тело еретика")
	if(QDELETED(owner) || owner.stat == DEAD)
		return break_link("должник умер или исчез")
	if(world.time >= expires_at)
		return break_link("истёк срок кровной связи")
	if(owner == blood.blood_body || IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner))
		return break_link("должник стал союзником Мансуса")
	var/in_pocket = blood.shares_pocket(owner)
	if(!in_pocket && (!isturf(owner.loc) || owner.z != blood.blood_body.z))
		return break_link("должник вошёл в контейнер или сменил уровень")
	if(!heretic_can_affect(blood.blood_body, owner, chargecost = 0))
		heretic_can_affect(blood.blood_body, owner)
		return break_link("должник защищён от магии")
	if(!isnull(contact_lost_at) && world.time >= contact_lost_at + HERETIC_BLOOD_CONTACT_GRACE)
		return break_link("контакт не восстановлен за две секунды")
	var/in_reach = in_pocket ? blood.can_use(blood.blood_body) && isturf(owner.loc) : blood.valid_victim(blood.blood_body, owner)
	if(!in_reach)
		if(collecting)
			if(!in_pocket && !blood.line_clear(blood.blood_body, owner))
				return break_link(get_dist(blood.blood_body, owner) > HERETIC_BLOOD_RANGE ? "должник дальше пяти клеток" : "линию к должнику закрыла преграда")
			reset_collection()
			to_chat(blood.blood_body, span_warning("Взыскание с [owner] прервано: вы не можете действовать. Долг сохранён, если восстановитесь в течение двух секунд."))
			to_chat(owner, span_notice("Взыскание сорвано, но кровная связь ещё держится."))
			blood.blood_body.log_message("Взыскание с [key_name(owner)] прервано контролем: сохранено [round(debt, 0.1)] долга на время восстановления связи.", LOG_ATTACK)
		if(isnull(contact_lost_at))
			contact_lost_at = world.time
			to_chat(blood.blood_body, span_warning("Связь с [owner] слабеет: восстановите видимость и возможность действовать за две секунды, иначе долг исчезнет."))
			blood.notify_resource_changed()
		QDEL_NULL(link_beam)
		return FALSE
	if(!isnull(contact_lost_at))
		contact_lost_at = null
		blood.notify_resource_changed()
	if(owner.z != blood.blood_body.z)
		QDEL_NULL(link_beam)
		return TRUE
	if(!link_beam)
		link_beam = new(blood.blood_body, owner, 'modular_bluemoon/icons/obj/heretic_blood_effects.dmi', "blood_link", INFINITY, HERETIC_BLOOD_RANGE + 1, /obj/effect/ebeam, null)
		INVOKE_ASYNC(link_beam, TYPE_PROC_REF(/datum/beam, Draw))
	if(link_beam && (link_beam.origin_oldloc != get_turf(blood.blood_body) || link_beam.target_oldloc != get_turf(owner)))
		link_beam.recalculate_in(0)
	return TRUE

/// Связь, с которой уже лечились, остаётся пустой печатью: пределы лечения с цели не обнуляются.
/datum/status_effect/heretic_blood_seal/proc/break_link(reason)
	link_end_reason = reason
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(blood && blood.blood_generation == expected_generation && !QDELETED(owner) && (siphoned > 0 || blood_recovered > 0))
		announce_loss(blood)
		spend()
	else
		qdel(src)
	return FALSE

/datum/status_effect/heretic_blood_seal/proc/announce_loss(datum/eldritch_knowledge/base_blood/blood)
	if(debt > 0 && blood.can_use(blood.blood_body))
		to_chat(blood.blood_body, span_warning("Связь с [owner] оборвалась: невзысканный долг исчез."))
	if(collecting && debt > 0 && !QDELETED(blood.blood_body) && !QDELETED(owner))
		to_chat(blood.blood_body, span_warning("Взыскание с [owner] сорвано: [link_end_reason]. Потеряно [round(debt, 0.1)] долга."))
		blood.blood_body.log_message("Связь с [key_name(owner)] потеряна во время взыскания: [link_end_reason]; исчезло [round(debt, 0.1)] долга.", LOG_ATTACK)

/datum/status_effect/heretic_blood_seal/proc/reset_collection()
	collecting = FALSE
	collection_amount = null
	collection_ready_at = null
	if(collection_timer)
		deltimer(collection_timer)
		collection_timer = null
	var/datum/eldritch_knowledge/required = collection_knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	collection_knowledge_ref = null
	seal_overlay.icon_state = "blood_mark"
	owner.update_icon()

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
	var/payment = min(debt, collection_amount)
	var/damage = payment * HERETIC_BLOOD_DAMAGE_PER_DEBT
	var/mob/living/victim = owner
	var/mob/living/user = blood.blood_body
	var/damage_before = victim.getBruteLoss()
	var/generation = blood.blood_generation
	debt -= payment
	victim.adjustBruteLoss(damage)
	if(!QDELETED(blood) && blood.blood_generation == generation && !QDELETED(victim))
		var/actual_damage = min(damage, max(0, victim.getBruteLoss() - damage_before))
		var/healed = victim.mind ? blood.mend_wounds(user, min(max(0, HERETIC_BLOOD_SIPHON_LIMIT - siphoned), actual_damage * HERETIC_BLOOD_SIPHON_FRACTION)) : 0
		if(actual_damage > 0)
			heretic.advance_combat_deed(victim, PATH_BLOOD)
		if(actual_damage > 0 && victim.mind)
			var/recovered = blood.recover_blood(user, min(max(0, HERETIC_BLOOD_RECOVERY_LIMIT - blood_recovered), actual_damage * HERETIC_BLOOD_RECOVERY_FRACTION))
			if(!QDELETED(src))
				blood_recovered += recovered
		if(!QDELETED(src))
			siphoned += healed
		if(healed > 0)
			to_chat(user, span_notice("Взысканная кровь залечивает [round(healed, 0.1)] ушибов и ожогов."))
	if(!QDELETED(victim))
		new /obj/effect/temp_visual/heretic_blood/burst(get_turf(victim), blood)
		if(istype(required, /datum/eldritch_knowledge/final_eldritch/blood_final) && !QDELETED(blood))
			blood.verdict_strike_fx(victim)
		if(istype(required, /datum/eldritch_knowledge/spell/blood_reckoning) && victim.stat != DEAD)
			victim.apply_status_effect(/datum/status_effect/heretic_blood_exsanguinated)
		playsound(victim, 'modular_bluemoon/sound/heretic/blood_release.ogg', 65, TRUE)
		if(!QDELETED(user))
			log_combat(user, victim, "взыскивает кровный долг с", addition = "заданный урон: [damage]; полученные ушибы: [round(victim.getBruteLoss() - damage_before, 0.1)]")
	if(QDELETED(src))
		return TRUE
	if(debt <= 0)
		spend()
		return TRUE
	if(!validate_link())
		if(!QDELETED(src) && !spent)
			break_link(link_end_reason)
		return TRUE
	reset_collection()
	blood.update_debt()
	return TRUE

/datum/status_effect/heretic_blood_seal/on_remove()
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	if(blood)
		blood.seals.Remove(src)
		blood.spent_seals.Remove(src)
		blood.update_debt()
		announce_loss(blood)
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
	desc = "Попадания еретика накапливают долг и обновляют срок связи. Скройтесь за преградой, отойдите дальше пяти клеток или выведите еретика из строя на две секунды. Во время предупреждения взыскания отход или укрытие сразу рвут связь. Краткий контроль срывает взыскание, но даёт еретику две секунды на восстановление связи с прежним долгом. Антимагия и потеря сознания еретиком рвут её немедленно. Без новых попаданий связь живёт 15 секунд."
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
	name = "crimson fang"
	desc = "Зазубренный клинок из запёкшейся крови. Два ребра гарды сжимают живое сердце, и с каждым его ударом по долу к острию бежит свежая кровь."
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
	desc = "Костяная чаша на ножке из сросшихся сосудов. Возьмите в руку и щёлкните по своему связанному врагу: до 10 долга превратится в 20 ушибов врагу и столько же лечения ваших ушибов и ожогов. Расход зависит от ваших ран; из цели без разума чаша не пьёт. Перезарядка — 12 секунд."
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
	if(seal?.blood_ref?.resolve() != blood || seal.spent)
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
	var/reason = blood ? blood.victim_error(user, target) : "Сначала выберите путь Крови."
	if(!heretic_check(user, !reason, silent, reason, target = target))
		return FALSE
	return heretic_check(user, heretic_can_affect(user, target, chargecost = 0), silent, "Цель защищена от магии: кровная связь её не достанет.", target = target)

/obj/effect/proc_holder/spell/pointed/heretic_blood/release
	name = "Связать / взыскать"
	desc = "Первый выбор врага - бесплатная связь и 10 долга, повторный - через секунду 2 ушиба за долг, в «Разоружении» до 10 долга. Четверть урона лечит вас, до 10 с одной цели; цель без разума не лечит."
	summary = "Новый враг - связь и 10 долга, свой должник - взыскание по 2 ушиба за долг через секунду."
	active_msg = "Новый враг — связать бесплатно. Свой должник — взыскать весь долг; в намерении «Разоружить» — до 10, сохранив остаток."

/obj/effect/proc_holder/spell/pointed/heretic_blood/release/can_target(atom/target, mob/user, silent)
	if(!..())
		return FALSE
	var/mob/living/victim = target
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!heretic_check(user, (seal && !seal.spent) || length(blood.seals) < blood.link_limit, silent, "Связи заняты: выберите прежнего должника, чтобы взыскать его долг."))
		return FALSE
	if(!heretic_check(user, !seal || seal.spent || seal.blood_ref?.resolve() == blood, silent, "Эта связь принадлежит другому еретику. Выберите другого противника."))
		return FALSE
	return heretic_check(user, !seal?.collecting, silent, "Взыскание уже началось: удержите дистанцию до удара.")

/obj/effect/proc_holder/spell/pointed/heretic_blood/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!length(targets) || !blood?.release(user, targets[1], partial = user.a_intent == INTENT_DISARM))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_blood/lance
	name = "Натянуть жилу"
	desc = "Враг в пяти клетках получает 18 ушибов, связь и 6 долга и притягивается на три клетки. Преграды, антимагия, закрепление и пристёгивание защищают от притяжения; перезарядка 12 секунд."
	summary = "18 ушибов, притяжение на 3 клетки, связь и 6 долга."
	action_icon_state = "blood_lance"
	charge_max = 12 SECONDS
	active_msg = "Выберите врага: ударить и притянуть к клинку. Предварительная связь не нужна."

/obj/effect/proc_holder/spell/pointed/heretic_blood/lance/can_target(atom/target, mob/user, silent)
	if(!..())
		return FALSE
	var/mob/living/victim = target
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic_check(user, !seal || seal.spent || seal.blood_ref?.resolve() == heretic.get_knowledge(/datum/eldritch_knowledge/base_blood), silent, "Эта связь принадлежит другому еретику. Выберите другого противника."))
		return FALSE
	return heretic_check(user, !seal?.collecting, silent, "Взыскание уже началось: дождитесь удара, прежде чем притягивать цель.")

/obj/effect/proc_holder/spell/pointed/heretic_blood/lance/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!length(targets) || !blood?.lance(user, targets[1]))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_blood/drain
	name = "Кровопускание"
	desc = "Должник с долгом от 16: после секунды предупреждения 6 секунд из него уходит до 15% крови, он немеет и не отходит дальше 3 клеток. Если связь выдержит - обморок на 10 секунд; стена, дальность, антимагия, жезл и переливание рвут нить."
	summary = "Должник с долгом от 16: 6 секунд на нити без голоса и рации, затем обморок."
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "blood_drain"
	charge_max = HERETIC_BLOOD_DRAIN_COOLDOWN
	active_msg = "Выберите своего должника с долгом не меньше 16."

/obj/effect/proc_holder/spell/pointed/heretic_blood/drain/can_target(atom/target, mob/user, silent)
	if(!..())
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/reason = blood.drain_block_reason(user, target)
	return heretic_check(user, !reason, silent, reason, target = target)

/obj/effect/proc_holder/spell/pointed/heretic_blood/drain/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!length(targets) || !blood?.drain(user, targets[1]))
		heretic_revert_cast(user, blood?.ability_failure)

/obj/effect/proc_holder/spell/pointed/heretic_blood/coronation
	name = "Кровный приговор"
	desc = "Долги остальных ваших связей переходят к выбранному должнику до предела 30, остатки остаются на прежних целях. Затем начинается взыскание с секундой предупреждения."
	summary = "Долги других связей переходят в выбранную до 30, затем её взыскание."
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
	if(!heretic_check(user, blood.can_use_ascension(user), silent, "Сначала завершите вознесение пути Крови."))
		return FALSE
	if(!heretic_check(user, seal?.blood_ref?.resolve() == blood && !seal.spent, silent, "На цели нет вашей кровной связи. Сначала свяжите её Хваткой или способностью «Связать / взыскать»."))
		return FALSE
	return heretic_check(user, !seal.collecting, silent, "Взыскание уже началось: дождитесь удара, прежде чем выносить Кровный приговор.")

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
	return ..() && heretic_check(user, blood?.can_use(user, usable_while_grabbed), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_blood/slip
	name = "Скользкая кровь"
	desc = "За 10 собственных ушибов на 5 секунд вырвитесь из любого захвата: вас не схватить заново, вы быстрее, а за вами тянется скользкая кровь. Наручники не снимает и в них недоступна."
	summary = "За 10 ушибов 5 секунд вас не схватить, вы быстрее, за вами скользкий след."
	charge_max = HERETIC_BLOOD_SLIP_COOLDOWN
	usable_while_grabbed = TRUE

/obj/effect/proc_holder/spell/self/heretic_blood/slip/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!blood?.slip(user))
		heretic_revert_cast(user, blood?.ability_failure || "Сначала выберите путь Крови.")

/obj/effect/proc_holder/spell/self/heretic_blood/reckoning
	name = "Взыскать долги"
	desc = "6 долга каждой связи и взыскание всех разом: лечит вас за урон каждой цели, взысканные 4 секунды замедлены и видят размыто. У должников есть секунда предупреждения; перезарядка 20 секунд."
	summary = "6 долга каждой связи и взыскание всех разом; взысканные обескровлены на 4 секунды."
	action_icon_state = "blood_reckoning"
	charge_max = 20 SECONDS

/obj/effect/proc_holder/spell/self/heretic_blood/reckoning/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!blood?.reckoning(user))
		heretic_revert_cast(user, blood?.ability_failure || "Сначала выберите путь Крови.")

/datum/eldritch_knowledge/base_blood/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_failure_reason = null
	if(!proximity_flag || user.a_intent != INTENT_HELP || !blood_source(target))
		return FALSE
	return read_blood(user, target)

/datum/eldritch_knowledge/blood_grasp
	name = "Красная ладонь"
	summary = "Хватка бесплатно связывает врага, по должнику добавляет 6 долга."
	details = list(
		"По уже связанному врагу обновляет срок связи до 15 секунд.",
		"Пустую печать после взыскания Хватка продлевает, а не начинает счёт лечения заново.",
	)
	role = HERETIC_ROLE_GRASP
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
	return seal && !seal.spent ? blood.add_debt(seal, HERETIC_BLOOD_STRIKE_DEBT, renew = TRUE) : blood.release(user, victim)

/datum/eldritch_knowledge/spell/blood_drain
	name = "Кровопускание"
	summary = "Должник с долгом от 16 шесть секунд на нити теряет кровь, немеет и падает в обморок."
	details = list(
		"Нужен должник с долгом от 16 в 5 клетках без преград; секунду нить краснеет, и цель может уйти за стену.",
		"6 секунд: до 15% крови, не ниже безопасного уровня; цель немая, без рации, дальше 3 клеток не уйдёт.",
		"Нить не тянет в космос, пропасть или лаву, а само Кровопускание никого не убивает.",
		"Если связь выдержала - обморок на 10 секунд, цель готова к обряду; долг списывается целиком.",
		"Со 2-й секунды сердце уводит цель в изнанку, если вы в 3 клетках: связь цела, канал доигрывает.",
		"Срывают стена, дальность, антимагия, ваше оглушение, нулевой жезл, переливание и 2 секунды растолкать.",
		"Потом цель минуту невосприимчива, к любому захвату - 15 секунд. Перезарядка 40 секунд.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Я не резал. Я только напомнил крови, кому она должна."
	cost = 1
	route = PATH_BLOOD
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_blood/drain

/datum/eldritch_knowledge/spell/blood_lance
	name = "Натянуть жилу"
	summary = "Врагу в 5 клетках 18 ушибов, притяжение на 3 клетки, связь и 6 долга."
	details = list(
		"Работает без подготовки и саморанения.",
		"Стены и антимагия защищают; закрепление и пристёгивание не дают притянуть.",
		"Перезарядка 12 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Я потянул за нить, и на другом конце сбился чужой шаг."
	cost = 2
	route = PATH_BLOOD
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_blood/lance

/datum/eldritch_knowledge/blood_mark
	name = "Метка отсрочки"
	summary = "Хватка ставит метку на 15 секунд, удар клыком её разбивает и добавляет 6 долга."
	details = list(
		"Взрыв продлевает связь на 5 секунд, но не дальше 20 секунд от текущего момента.",
		"Метка работает только по вашему должнику.",
	)
	role = HERETIC_ROLE_MARK
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
	summary = "Стакан и лист серебра дают чашу: долг должника превращается в лечение ваших ран."
	details = list(
		"Щёлкните чашей по своему должнику: до 10 долга дают ему до 20 ушибов, вам - столько же лечения.",
		"Расход ограничен вашими ранами, лечение - фактическим уроном; из цели без разума чаша не пьёт.",
		"Исчерпанная чашей связь освобождается, пустая печать ещё 15 секунд хранит пределы лечения.",
		"Одна чаша, перезарядка 12 секунд.",
	)
	role = HERETIC_ROLE_RELIC
	gain_text = "На дне осталась одна капля. Я узнал её вкус."
	cost = 1
	route = PATH_BLOOD
	required_atoms = list(/obj/item/reagent_containers/food/drinks/drinkingglass, /obj/item/stack/sheet/mineral/silver)
	result_atoms = list(/obj/item/heretic_path_relic/blood_relic)

/datum/eldritch_knowledge/blood_relic/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/blood_relic/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/blood_relic)

/datum/eldritch_knowledge/spell/blood_slip
	name = "Скользкая кровь"
	summary = "За 10 своих ушибов на 5 секунд вырывает из любого захвата и оставляет скользкий след."
	details = list(
		"Работает в агрессивном грабе, на чужих руках и при таскании; схватить вас заново нельзя.",
		"Вы бегаете быстрее; враги на следу поскальзываются, как на мокром полу, шагом его можно пройти.",
		"След впитывается через 10 секунд, вы сами на нём не скользите.",
		"Наручники, смирительная рубашка и щит разума закрывают способность; смертельная плата запрещена.",
		"Перезарядка 30 секунд.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "Кровь выступила на коже, и ни одна рука не смогла меня удержать."
	cost = 1
	route = PATH_BLOOD
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_blood/slip

/datum/eldritch_knowledge/spell/blood_slip/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(blood)
		QDEL_NULL(blood.blood_slip)
	return ..()

/datum/eldritch_knowledge/blood_vigor
	name = "Книга обязательств"
	summary = "Две связи вместо одной, в каждой до 20 долга."
	details = list(
		"Улучшения: 25 долга, затем третья связь.",
		"Вознесение даёт три связи по 30. Улучшения не создают долг.",
	)
	role = HERETIC_ROLE_PASSIVE
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
	summary = "Все связи получают 6 долга и взыскиваются разом; взысканные обескровлены на 4 секунды."
	details = list(
		"Взыскание лечит вас за урон каждой цели в общих пределах лечения.",
		"Обескровленные замедлены и видят размыто.",
		"Каждая цель получает секунду предупреждения и может порвать связь.",
		"Посторонние не затрагиваются. Перезарядка 20 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
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
	summary = "Кровотечение врагов рядом удваивается, чужая кровь с пола лечит, открывается Кровный приговор."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; станция узнаёт место обряда, он длится 30 секунд.",
		"Общая стойкость вознесения, три связи по 30 долга; смерть снимает усиления, оживление возвращает.",
		"Враги в 3 клетках в поле зрения каждые 2 секунды теряют ещё столько же крови, сколько от своих ран.",
		"Перевязанная, зашитая или прижжённая рана не удваивается.",
		"Раненым вы пьёте свежую чужую лужу под ногами: 3 лечения раз в секунду, сначала ушибы.",
		"Засохшая и своя кровь, следы обуви и кровь ксеноморфов не годятся.",
		"Кровный приговор раз в 30 секунд переносит долги других связей в выбранную до 30 и взыскивает её.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Из чаши поднялся венец. Все подписи на его ободе были моими. Теперь каждая пролитая рядом капля тянулась ко мне."
	route = PATH_BLOOD
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/pointed/heretic_blood/coronation)
	var/datum/weakref/blood_knowledge_ref

/datum/eldritch_knowledge/final_eldritch/blood_final/on_body_gain(mob/living/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	blood?.update_capacity()
	if(!blood || !finished || applied_body != user)
		return
	blood_knowledge_ref = WEAKREF(blood)
	blood.ascension_active = TRUE
	user.AddComponent(/datum/component/heretic_blood_tide, blood)

/datum/eldritch_knowledge/final_eldritch/blood_final/on_body_lose(mob/living/user)
	var/was_applied = !isnull(applied_body)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_blood_tide))
	var/datum/eldritch_knowledge/base_blood/ascended_blood = blood_knowledge_ref?.resolve()
	if(ascended_blood)
		ascended_blood.ascension_active = FALSE
	blood_knowledge_ref = null
	. = ..()
	if(!was_applied)
		return
	var/datum/antagonist/heretic/heretic = combat_resource_owner?.resolve()
	var/datum/eldritch_knowledge/base_blood/blood = heretic?.get_knowledge(/datum/eldritch_knowledge/base_blood)
	if(!QDELETED(blood))
		blood.clear_blood()
		blood.update_capacity()

/// Кровавый прилив: кровотечение врагов рядом удваивается, лужи крови под ногами лечат героя.
/datum/component/heretic_blood_tide
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/blood_ref
	COOLDOWN_DECLARE(pool_heal)
	var/static/list/drinkable_blood = typecacheof(/obj/effect/decal/cleanable/blood) - typecacheof(list(
		/obj/effect/decal/cleanable/blood/footprints,
		/obj/effect/decal/cleanable/blood/hitsplatter,
		/obj/effect/decal/cleanable/blood/xeno,
		/obj/effect/decal/cleanable/blood/splatter/xeno,
		/obj/effect/decal/cleanable/blood/gibs/xeno,
		/obj/effect/decal/cleanable/blood/xtracks,
		/obj/effect/decal/cleanable/blood/gibs/ipc,
		/obj/effect/decal/cleanable/blood/gibs/synth,
	))

/datum/component/heretic_blood_tide/Initialize(datum/eldritch_knowledge/base_blood/blood)
	if(!isliving(parent) || QDELETED(blood))
		return COMPONENT_INCOMPATIBLE
	blood_ref = WEAKREF(blood)

/datum/component/heretic_blood_tide/RegisterWithParent()
	RegisterSignal(parent, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/heretic_blood_tide/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_LIVING_LIFE, COMSIG_MOVABLE_MOVED, COMSIG_PARENT_EXAMINE))

/datum/component/heretic_blood_tide/Destroy()
	blood_ref = null
	return ..()

/datum/component/heretic_blood_tide/proc/active()
	var/mob/living/owner = parent
	var/datum/eldritch_knowledge/base_blood/blood = blood_ref?.resolve()
	return blood?.ascension_active && owner.stat != DEAD && isturf(owner.loc)

/datum/component/heretic_blood_tide/proc/on_life(mob/living/source, seconds, times_fired)
	SIGNAL_HANDLER
	if(!active())
		return
	var/watched = heretic_vfx_watched(source)
	for(var/mob/living/carbon/human/victim in heretic_field_view(HERETIC_BLOOD_TIDE_RADIUS, source))
		if(heretic_can_affect(source, victim, chargecost = 0))
			drain(victim, watched)

/// Условия повторяют handle_blood: где обычное кровотечение стоит, удваивать нечего. Струйка рисуется, только если рядом есть зрители.
/datum/component/heretic_blood_tide/proc/drain(mob/living/carbon/human/victim, watched = FALSE)
	if(victim.bleedsuppress || victim.blood_volume <= 0 || victim.bodytemperature < TCRYO || (NOBLOOD in victim.dna.species.species_traits))
		return
	if(HAS_TRAIT(victim, TRAIT_FAKEDEATH) || HAS_TRAIT(victim, TRAIT_NOMARROW) || HAS_TRAIT(victim, TRAIT_HUSK))
		return
	var/rate = victim.get_total_bleed_rate()
	if(rate <= 0)
		return
	victim.bleed(rate)
	if(watched)
		show_bleeding(victim)

/// Удвоенная кровь тонкой струйкой тянется от раненого к вознёсшемуся.
/datum/component/heretic_blood_tide/proc/show_bleeding(mob/living/victim)
	heretic_vfx_stream(victim, parent, /particles/heretic_ascension/blood/tide_stream, HERETIC_BLOOD_TIDE_STREAM_TIME)

/datum/component/heretic_blood_tide/proc/on_moved(mob/living/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	if(!active() || !COOLDOWN_FINISHED(src, pool_heal) || source.getBruteLoss() + source.getFireLoss() <= 0)
		return
	for(var/obj/effect/decal/cleanable/blood/stain in source.loc)
		if(!drinkable(stain, source))
			continue
		if(heretic_heal_pool(source, HERETIC_BLOOD_TIDE_POOL_HEAL) <= 0)
			return
		COOLDOWN_START(src, pool_heal, HERETIC_BLOOD_TIDE_POOL_COOLDOWN)
		drink_fx(stain, source)
		qdel(stain)
		return

/// Лужа не пропадает, а закручивается воронкой и уходит в вознёсшегося.
/datum/component/heretic_blood_tide/proc/drink_fx(obj/effect/decal/cleanable/blood/stain, mob/living/drinker)
	var/obj/effect/temp_visual/heretic_vfx/ghost/swirl = heretic_vfx_ghost(stain, stain, null, HERETIC_BLOOD_DRINK_TIME)
	if(swirl)
		var/matrix/sucked = matrix(swirl.transform)
		sucked.Scale(HERETIC_BLOOD_DRINK_SHRINK)
		sucked.Turn(HERETIC_BLOOD_DRINK_TURN)
		animate(swirl, transform = sucked, alpha = 0, time = HERETIC_BLOOD_DRINK_TIME, easing = QUAD_EASING | EASE_IN)
	heretic_vfx_converge(drinker, /particles/heretic_ascension/blood/drink, HERETIC_BLOOD_DRINK_RADIUS, HERETIC_BLOOD_DRINK_TIME, HERETIC_BLOOD_DRINK_EMIT, HERETIC_BLOOD_DRINK_ARMS, HERETIC_BLOOD_DRINK_SWIRL)
	heretic_vfx_pulse(drinker, heretic_path_ink(PATH_BLOOD, TRUE), 1, HERETIC_BLOOD_DRINK_TIME)

/datum/component/heretic_blood_tide/proc/drinkable(obj/effect/decal/cleanable/blood/stain, mob/living/drinker)
	if(QDELETED(stain) || stain.dried || !is_type_in_typecache(stain, drinkable_blood))
		return FALSE
	var/own_dna
	if(iscarbon(drinker))
		var/mob/living/carbon/carbon_drinker = drinker
		own_dna = carbon_drinker.dna?.unique_enzymes
	for(var/dna_key in stain.blood_DNA)
		if(dna_key != "color" && dna_key != "blendmode" && dna_key != own_dna)
			return TRUE
	return FALSE

/// Кровь: тонкая струйка капель от раненого к вознёсшемуся.
/particles/heretic_ascension/blood/tide_stream
	icon_state = list("blood_wisp_1" = 2, "blood_wisp_2" = 1)
	count = 10
	spawning = 0.6
	position = generator("circle", 0, 3)
	lifespan = 0.8 SECONDS
	fade = 0.25 SECONDS
	fadein = 0.1 SECONDS

/// Кровь: выпитая лужа воронкой стекается к ногам.
/particles/heretic_ascension/blood/drink
	icon_state = list("blood_wisp_1" = 2, "blood_drop_2" = 1)
	count = 8
	spawning = 4

/// Кровь: поток долга по нити в выбранного должника.
/particles/heretic_ascension/blood/verdict
	icon_state = list("blood_wisp_1" = 2, "blood_wisp_2" = 2, "blood_drop_1" = 1)
	count = 20
	spawning = 4
	position = generator("circle", 0, 4)
	lifespan = 0.5 SECONDS
	fade = 0.15 SECONDS

/datum/component/heretic_blood_tide/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Кровь тянется к нему: раны рядом с ним кровоточат вдвое сильнее, а свежие лужи чужой крови у него под ногами исчезают и затягивают его раны. Держитесь дальше трёх клеток, перевязывайте раны и убирайте кровь с пола.")

#undef HERETIC_BLOOD_HARVEST_TIME
#undef HERETIC_BLOOD_HEALTH_RESERVE
#undef HERETIC_BLOOD_LINK_LIFETIME
#undef HERETIC_BLOOD_COLLECTION_DELAY
#undef HERETIC_BLOOD_REFUND_LIMIT
#undef HERETIC_BLOOD_REFUND_MULTIPLIER
#undef HERETIC_BLOOD_REFUND_COOLDOWN
#undef HERETIC_BLOOD_SIPHON_FRACTION
#undef HERETIC_BLOOD_SIPHON_LIMIT
#undef HERETIC_BLOOD_DAMAGE_PER_DEBT
#undef HERETIC_BLOOD_INITIAL_DEBT
#undef HERETIC_BLOOD_STRIKE_DEBT
#undef HERETIC_BLOOD_LANCE_DAMAGE
#undef HERETIC_BLOOD_LANCE_PULL
#undef HERETIC_BLOOD_PARTIAL_COLLECTION
#undef HERETIC_BLOOD_SIGN_CRAFT
#undef HERETIC_BLOOD_SIGN_CLUE
#undef HERETIC_BLOOD_TRAIL_NEAR
#undef HERETIC_BLOOD_TRAIL_FAR
#undef HERETIC_BLOOD_CAPTURE
#undef HERETIC_BLOOD_CHECK_INTERVAL
#undef HERETIC_BLOOD_DRAIN_REFILL_MARGIN
#undef HERETIC_BLOOD_DRAIN_TRAIT
#undef HERETIC_BLOOD_SLIP_TRAIT
#undef HERETIC_BLOOD_SLIP_HASTE
#undef HERETIC_BLOOD_SLICK_KNOCKDOWN
#undef HERETIC_BLOOD_LEASH_MESSAGE_COOLDOWN
#undef HERETIC_BLOOD_DRAIN_SEAL_MARGIN
#undef HERETIC_BLOOD_EXSANGUINE_SLOWDOWN
#undef HERETIC_BLOOD_EXSANGUINE_BLUR
#undef HERETIC_BLOOD_RECOVERY_FRACTION
#undef HERETIC_BLOOD_RECOVERY_LIMIT
#undef HERETIC_BLOOD_TIDE_STREAM_TIME
#undef HERETIC_BLOOD_DRINK_TIME
#undef HERETIC_BLOOD_DRINK_SHRINK
#undef HERETIC_BLOOD_DRINK_TURN
#undef HERETIC_BLOOD_DRINK_RADIUS
#undef HERETIC_BLOOD_DRINK_ARMS
#undef HERETIC_BLOOD_DRINK_SWIRL
#undef HERETIC_BLOOD_DRINK_EMIT
#undef HERETIC_BLOOD_VERDICT_REEL
#undef HERETIC_BLOOD_VERDICT_THREAD_FADE
#undef HERETIC_BLOOD_VERDICT_STREAM_TIME
#undef HERETIC_BLOOD_VERDICT_GATHER_RADIUS
#undef HERETIC_BLOOD_VERDICT_WAVE_RADIUS
#undef HERETIC_BLOOD_VERDICT_WAVE_TIME
#undef HERETIC_BLOOD_VERDICT_FLASH_RANGE
#undef HERETIC_BLOOD_VERDICT_FLASH_POWER
#undef HERETIC_BLOOD_VERDICT_FLASH_TIME
#undef HERETIC_BLOOD_VERDICT_QUAKE
#undef HERETIC_BLOOD_VERDICT_QUAKE_RADIUS
#undef HERETIC_BLOOD_VERDICT_QUAKE_TIME
