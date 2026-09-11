#define GHOUL_MAX_HEALTH 50
#define VOICELESS_DEAD_MAX_HEALTH 90
#define HERETIC_SERVANT_LIMIT 4
#define HERETIC_ASCENDED_FLESH_SERVANT_LIMIT 8

/mob/living/carbon/human
	var/heretic_flesh_raised = FALSE

/datum/antagonist/heretic/proc/can_add_servant()
	var/servant_limit = ascended && selected_path == PATH_FLESH ? HERETIC_ASCENDED_FLESH_SERVANT_LIMIT : HERETIC_SERVANT_LIMIT
	var/list/servants = list()
	for(var/knowledge_type in researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = researched_knowledge[knowledge_type]
		servants |= knowledge.flesh_servants
	return length(servants) < servant_limit

/datum/eldritch_knowledge/base_flesh
	name = "Принцип голода"
	desc = "Открывает Путь Плоти: собирайте биомассу из меток и извлечённых органов, поднимайте свиту и сшивайте её раны. Кухонный нож и кровь превращаются в клинок плоти. Сшивание расходует биомассу для лечения ваших слуг. Общий предел всей свиты — четыре слуги независимо от способа призыва."
	gain_text = "Голод оказался не недостатком, а инструментом."
	required_atoms = list(/obj/item/kitchen/knife, /obj/effect/decal/cleanable/blood)
	result_atoms = list(/obj/item/melee/sickly_blade/flesh)
	cost = 0
	route = PATH_FLESH

/// Храним роль, а не тело: свита остаётся под контролем после клонирования и пересадки мозга.
/datum/eldritch_knowledge
	var/list/flesh_servants = list()

/datum/eldritch_knowledge/proc/track_flesh_servant(datum/antagonist/heretic_monster/servant)
	flesh_servants |= servant
	RegisterSignal(servant, COMSIG_PARENT_QDELETING, PROC_REF(forget_flesh_servant))

/datum/eldritch_knowledge/proc/forget_flesh_servant(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	flesh_servants -= source

/datum/eldritch_knowledge/proc/release_flesh_servants()
	for(var/datum/antagonist/heretic_monster/servant as anything in flesh_servants.Copy())
		UnregisterSignal(servant, COMSIG_PARENT_QDELETING)
		servant.owner?.remove_antag_datum(servant.type)
	flesh_servants.Cut()

/datum/eldritch_knowledge/flesh_grasp
	name = "Хватка Плоти"
	desc = "Хватка поднимает мёртвого человека с присутствующей душой в гуля за 1 биомассу. Гуль имеет 50 здоровья, выглядит иссохшим и подчиняется вам. Одновременно можно удерживать двух гулей. Защита разума, синтетики и скелеты не поддаются обращению. Истощённые и уже поднятые тела не подходят."
	gain_text = "Одна рука не соберёт тело. Значит, нужны новые руки."
	cost = 1
	route = PATH_FLESH
	var/ghoul_amt = 2

/datum/eldritch_knowledge/flesh_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!ishuman(target) || target == user)
		return FALSE
	var/mob/living/carbon/human/victim = target
	if(victim.stat != DEAD)
		return FALSE
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	var/datum/eldritch_knowledge/base_flesh/path = heretic?.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	if(!path || path.combat_resource < 1 || length(flesh_servants) >= ghoul_amt || !heretic.can_add_servant())
		to_chat(user, span_warning("Недостаточно биомассы или нет места в свите."))
		return FALSE
	var/block_reason = heretic_conversion_block_reason(victim)
	if(block_reason)
		to_chat(user, span_warning(block_reason))
		return FALSE
	victim.grab_ghost()
	if(!victim.mind || !victim.client)
		to_chat(user, span_warning("В этом теле нет души, готовой вернуться."))
		return FALSE
	if(!path.spend_combat_resource())
		return FALSE
	victim.revive(full_heal = TRUE, admin_revive = TRUE)
	var/datum/antagonist/heretic_monster/ghoul/servant = new
	servant.health_cap = GHOUL_MAX_HEALTH
	servant.set_master(heretic)
	victim.mind.add_antag_datum(servant)
	track_flesh_servant(servant)
	log_game("[key_name(user)] поднял [key_name(victim)] как гуля еретика.")
	return TRUE

/datum/eldritch_knowledge/flesh_grasp/on_lose(mob/user)
	release_flesh_servants()
	return ..()

/datum/eldritch_knowledge/flesh_ghoul
	name = "Незавершённый ритуал"
	desc = "Мёртвый человек, мак и 2 биомассы создают Безмолвного мертвеца: слугу с 90 здоровья, лишённого голоса. Одновременно можно удерживать двух. Если душа тела не возвращается, роль предлагается призракам. Истощённые и уже поднятые тела не подходят."
	gain_text = "Плоть услышала меня. Голос ей больше не понадобится."
	cost = 1
	required_atoms = list(/mob/living/carbon/human, /obj/item/reagent_containers/food/snacks/grown/poppy)
	route = PATH_FLESH
	var/max_amt = 2

/datum/eldritch_knowledge/flesh_ghoul/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/mob/living/carbon/human/victim = locate() in atoms
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	var/datum/eldritch_knowledge/base_flesh/path = heretic?.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	if(QDELETED(victim) || victim.stat != DEAD || length(flesh_servants) >= max_amt || !path || path.combat_resource < 2 || !heretic.can_add_servant())
		return FALSE
	var/block_reason = heretic_conversion_block_reason(victim)
	if(block_reason)
		to_chat(user, span_warning(block_reason))
		return FALSE
	victim.grab_ghost()
	if(!victim.mind || !victim.client)
		var/list/mob/dead/observer/candidates = pollCandidatesForMob("Хотите стать Безмолвным мертвецом, слугой [user.real_name]?", ROLE_HERETIC, null, ROLE_HERETIC, 5 SECONDS, victim)
		if(!length(candidates))
			return FALSE
		if(!ritual_still_valid(user, atoms, get_turf(loc)) || victim.stat != DEAD || length(flesh_servants) >= max_amt || heretic_conversion_block_reason(victim) || QDELETED(path) || path.combat_resource < 2 || !heretic.can_add_servant())
			return FALSE
		var/mob/dead/observer/chosen = pick(candidates)
		if(!chosen?.key || victim.client)
			return FALSE
		victim.ghostize(FALSE)
		victim.key = chosen.key
	if(!path.spend_combat_resource(2))
		return FALSE
	victim.revive(full_heal = TRUE, admin_revive = TRUE)
	var/datum/antagonist/heretic_monster/voiceless_dead/servant = new
	servant.health_cap = VOICELESS_DEAD_MAX_HEALTH
	servant.set_master(heretic)
	victim.mind.add_antag_datum(servant)
	track_flesh_servant(servant)
	atoms -= victim
	log_game("[key_name(user)] raised [key_name(victim)] as a voiceless dead.")
	return TRUE

/datum/eldritch_knowledge/flesh_ghoul/on_lose(mob/user)
	release_flesh_servants()
	return ..()

/datum/antagonist/heretic_monster/ghoul/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/body = innate_body
	if(QDELETED(body))
		return
	if(ishuman(body))
		var/mob/living/carbon/human/human_body = body
		human_body.heretic_flesh_raised = TRUE
		human_body.become_husk(REF(src))

/datum/antagonist/heretic_monster/ghoul/remove_innate_effects(mob/living/mob_override)
	var/mob/living/body = mob_override || innate_body
	if(!QDELETED(body) && body == innate_body)
		if(ishuman(body))
			var/mob/living/carbon/human/human_body = body
			human_body.cure_husk(list(REF(src)))
	return ..()

/datum/antagonist/heretic_monster/voiceless_dead/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/body = innate_body
	if(QDELETED(body))
		return
	ADD_TRAIT(body, TRAIT_MUTE, REF(src))
	if(ishuman(body))
		var/mob/living/carbon/human/human_body = body
		human_body.heretic_flesh_raised = TRUE
		human_body.become_husk(REF(src))

/datum/antagonist/heretic_monster/voiceless_dead/remove_innate_effects(mob/living/mob_override)
	var/mob/living/body = mob_override || innate_body
	if(!QDELETED(body) && body == innate_body)
		REMOVE_TRAIT(body, TRAIT_MUTE, REF(src))
		if(ishuman(body))
			var/mob/living/carbon/human/human_body = body
			human_body.cure_husk(list(REF(src)))
	return ..()

/datum/eldritch_knowledge/flesh_mark
	name = "Метка Плоти"
	desc = "Хватка накладывает Метку Плоти. Удар клинком плоти активирует её, открывая кровоточащую рану и давая биомассу для подъёма и лечения свиты."
	gain_text = "Каждая чужая рана становится швом в моей работе."
	cost = 2
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!heretic_can_affect(user, target))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/flesh)
	return TRUE

/datum/eldritch_knowledge/flesh_blade_upgrade
	name = "Иссекающая сталь"
	desc = "Ранения клинком плоти усиливают кровотечение. Избегайте затяжного одиночного боя: свита должна удержать врага, пока тот слабеет."
	gain_text = "Маршал показал мне разницу между раной и разрезом."
	cost = 2
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_blade_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(!iscarbon(target))
		return
	var/mob/living/carbon/victim = target
	if(!length(victim.bodyparts))
		return
	var/obj/item/bodypart/limb = pick(victim.bodyparts)
	limb.generic_bleedstacks += passive_values[passive_level]

/datum/eldritch_knowledge/summon/raw_prophet
	name = "Нечестивый ритуал"
	desc = "Соедините глаза, левую руку и кровь, чтобы призвать сырого пророка. Это хрупкий разведчик с расширенным зрением, проходом сквозь стены и телепатической сетью."
	gain_text = "Я попросил глаза, способные увидеть больше моего голода."
	cost = 1
	required_atoms = list(/obj/item/organ/eyes, /obj/item/bodypart/l_arm, /obj/effect/decal/cleanable/blood)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/raw_prophet
	route = PATH_FLESH

/datum/eldritch_knowledge/summon/stalker
	name = "Одинокий ритуал"
	desc = "Соедините кухонный нож, свечу, ручку и бумагу, чтобы призвать преследователя. Этот слуга умеет менять форму, проходить сквозь стены и испускать ЭМИ."
	gain_text = "На пустой странице уже стояла подпись того, кто придёт."
	cost = 1
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/candle, /obj/item/pen, /obj/item/paper)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/stalker
	route = PATH_FLESH

/datum/eldritch_knowledge/summon/ashy
	name = "Пепельный ритуал"
	desc = "Соедините пепел, отрубленную голову и книгу, чтобы призвать пепельного духа. Он умеет проходить сквозь стены и выпускать каскад огня."
	gain_text = "Огонь тоже умеет быть голодным."
	cost = 1
	required_atoms = list(/obj/effect/decal/cleanable/ash, /obj/item/bodypart/head, /obj/item/book)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/ash_spirit

/datum/eldritch_knowledge/summon/rusty
	name = "Ржавый ритуал"
	desc = "Соедините рвоту, отрубленную голову и книгу, чтобы призвать ржавого ходока. Общий предел свиты — четыре слуги; после вознесения Плоти — восемь. Он распространяет ржавчину и стреляет отравляющими зарядами."
	gain_text = "Кузнец не возражал, когда его сад научился ходить."
	cost = 1
	required_atoms = list(/obj/effect/decal/cleanable/vomit, /obj/item/bodypart/head, /obj/item/book)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/rust_spirit

/datum/eldritch_knowledge/spell/blood_siphon
	name = "Кровавый сифон"
	desc = "Высосите жизненную силу из живого врага, чтобы восстановить свои раны. Часть кровотечения и ран может перейти к жертве."
	gain_text = "Маршал назвал кровь ещё одной дорогой."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/blood_siphon

/datum/eldritch_knowledge/flesh_blade_upgrade_2
	name = "Воспоминание"
	desc = "Раз в 8 секунд ранение клинком плоти может вывихнуть конечность. Соедините зажим, шовную нить и извлечённый орган, чтобы создать сшивающую иглу. За одну биомассу инструмент восстанавливает руку или ногу вашего живого слуги; если конечности целы, останавливает кровотечение."
	required_atoms = list(/obj/item/hemostat, /obj/item/stack/medical/suture, /obj/item/organ)
	result_atoms = list(/obj/item/heretic_relic/suture_needle)
	gain_text = "Кость помнит форму. Я могу предложить ей другую."
	cost = 2
	route = PATH_FLESH
	COOLDOWN_DECLARE(fracture_cooldown)

/datum/eldritch_knowledge/flesh_blade_upgrade_2/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(!iscarbon(target) || !COOLDOWN_FINISHED(src, fracture_cooldown))
		return
	var/mob/living/carbon/victim = target
	if(!length(victim.bodyparts))
		return
	var/obj/item/bodypart/limb = pick(victim.bodyparts)
	var/datum/wound/blunt/moderate/wound = new
	wound.apply_wound(limb)
	COOLDOWN_START(src, fracture_cooldown, 8 SECONDS)

/datum/eldritch_knowledge/spell/touch_of_madness
	name = "Касание безумия"
	desc = "Навяжите врагу видение Мансуса: страх, короткая дезориентация и психическая травма отвлекут его от вашей свиты."
	gain_text = "Мой голод смотрит на них изнутри."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	spell_to_add = /obj/effect/proc_holder/spell/targeted/touch/mad_touch
	route = PATH_FLESH

/datum/eldritch_knowledge/final_eldritch/flesh_final
	name = "Последний гимн жреца"
	desc = "После трёх подношений принесите три мёртвых тела на руну. Начало обряда раскроет его место всей станции и даст экипажу 30 секунд, чтобы помешать. Вознесение позволяет принять форму Повелителя Ночи. Предел гулей и Безмолвных мертвецов увеличивается до четырёх каждого вида; общий предел всей свиты — восемь слуг."
	gain_text = "Маршал уступил мне место во главе процессии."
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	cost = 3
	sacs_needed = HERETIC_ASCENSION_SACRIFICES
	route = PATH_FLESH
	parallax_scene = ANTAG_SCENE_HERETIC_FLESH
	ascension_spells = list(/obj/effect/proc_holder/spell/targeted/shed_human_form)

/datum/eldritch_knowledge/final_eldritch/flesh_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	on_body_gain(user)
	user.client?.give_award(/datum/award/achievement/misc/flesh_ascension, user)
	var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
	var/datum/eldritch_knowledge/flesh_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/flesh_ghoul/ritual = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_ghoul)
	if(grasp)
		grasp.ghoul_amt = 4
	if(ritual)
		ritual.max_amt = 4
	return TRUE

#undef GHOUL_MAX_HEALTH
#undef VOICELESS_DEAD_MAX_HEALTH
#undef HERETIC_SERVANT_LIMIT
#undef HERETIC_ASCENDED_FLESH_SERVANT_LIMIT
