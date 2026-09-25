#define GHOUL_MAX_HEALTH 50
#define VOICELESS_DEAD_MAX_HEALTH 90
#define HERETIC_SERVANT_LIMIT 4
#define HERETIC_ASCENDED_FLESH_SERVANT_LIMIT 8
#define HERETIC_FLESH_KIND_LIMIT 2
#define HERETIC_ASCENDED_FLESH_KIND_LIMIT 4

/mob/living/carbon/human
	var/heretic_flesh_raised = FALSE

/datum/antagonist/heretic/proc/flesh_ascension_active()
	var/datum/eldritch_knowledge/final_eldritch/flesh_final/finale = get_knowledge(/datum/eldritch_knowledge/final_eldritch/flesh_final)
	return finale?.ascension_active

/datum/antagonist/heretic/proc/flesh_kind_limit()
	return flesh_ascension_active() ? HERETIC_ASCENDED_FLESH_KIND_LIMIT : HERETIC_FLESH_KIND_LIMIT

/datum/antagonist/heretic/proc/can_add_servant()
	var/servant_limit = flesh_ascension_active() ? HERETIC_ASCENDED_FLESH_SERVANT_LIMIT : HERETIC_SERVANT_LIMIT
	var/list/servants = list()
	for(var/knowledge_type in researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = researched_knowledge[knowledge_type]
		servants |= knowledge.flesh_servants
	return length(servants) < servant_limit

/datum/eldritch_knowledge/base_flesh
	name = "Принцип голода"
	summary = "Хватка поглощает извлечённые органы ради биомассы, Сшивание за неё лечит вас и свиту."
	details = list(
		"Хватка по извлечённому органу на полу поглощает его: +1 биомасса, новый вид органа идёт в дело пути.",
		"Взрыв Метки Плоти клинком тоже даёт биомассу.",
		"Сшивание за 1 биомассу лечит вам 10 ушибов, своим слугам в 5 клетках - по 25 ушибов и ожогов. Перезарядка 15 секунд.",
		"Кровотечение ран у слуг слабеет вдвое; вся свита - не больше 4 слуг, как бы они ни были призваны.",
		"Готовую цель у своего гуля, мертвеца или ползуна сжатое сердце уводит в изнанку из 7 клеток за 1,5 секунды.",
		"Увод срывается, если слуга потеряет сознание, цель оттащат от него или вы отойдёте дальше 7 клеток.",
		"Нож и лужа крови на руне дают клинок плоти.",
	)
	role = HERETIC_ROLE_CRAFT
	resource_rules = list(
		"Запас до 4 биомассы.",
		"Поглощённый хваткой орган и взрыв Метки Плоти дают по 1 биомассе.",
		"Сшивание, шов по слуге, гуль и игла стоят 1, ползун и Безмолвный мертвец - 2.",
	)
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

/datum/eldritch_knowledge/proc/poll_servant_candidates(question, mob/living/body, duration)
	return pollCandidatesForMob(question, ROLE_HERETIC, null, ROLE_HERETIC, duration, body)

/datum/eldritch_knowledge/proc/release_flesh_servants()
	for(var/datum/antagonist/heretic_monster/servant as anything in flesh_servants.Copy())
		UnregisterSignal(servant, COMSIG_PARENT_QDELETING)
		servant.owner?.remove_antag_datum(servant.type)
	flesh_servants.Cut()

/datum/eldritch_knowledge/flesh_grasp
	parent_type = /datum/eldritch_knowledge/spell
	name = "Хватка Плоти"
	summary = "Хватка поднимает гулей и шьёт ползунов, Живой шов бьёт врага издали или спасает слугу."
	details = list(
		"Хватка по мёртвому человеку за 1 биомассу поднимает гуля с 50 здоровья; держится до 2 гулей.",
		"Без души роль 10 секунд ждёт призраков; щит разума, синтетики, скелеты и истощённые тела не встают.",
		"Хватка в «Разоружении» по органу на полу за 2 биомассы шьёт ползуна: 40 здоровья, 6 урона раз в 2 секунды.",
		"Ползун один, живёт 90 секунд, дальше 9 клеток от вас распадается; касание на «Помощи» - за вами, иначе ждать.",
		"Живой шов на 5 клеток: враг получает 15 ушибов, замедление на 3 секунды и становится целью ползуна.",
		"Шов по слуге за 1 биомассу лечит 15 ушибов и ожогов и тянет к вам; здорового ползуна - только после 30 секунд.",
		"Пристёгнутого слугу шов лечит, но не тянет; стены и двери рвут шов. Перезарядка 15 секунд.",
	)
	role = HERETIC_ROLE_GRASP
	gain_text = "Одна рука не соберёт тело. Значит, нужны новые руки."
	cost = 1
	route = PATH_FLESH
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch
	var/ghoul_poll_pending = FALSE

/datum/eldritch_knowledge/flesh_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!ishuman(target) || target == user)
		return FALSE
	var/mob/living/carbon/human/victim = target
	if(!can_raise_ghoul(user, victim))
		return FALSE
	var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
	if(heretic.simulated)
		if(!victim.mind)
			victim.mind_initialize()
		return raise_ghoul(user, victim)
	victim.grab_ghost()
	if(victim.mind && victim.client)
		return raise_ghoul(user, victim)
	if(ghoul_poll_pending)
		to_chat(user, span_warning("Мансус уже зовёт блуждающих духов. Дождитесь ответа."))
		return FALSE
	to_chat(user, span_notice("Душа этого тела не возвращается. Мансус зовёт блуждающих духов: ответ придёт через [DisplayTimeText(HERETIC_SERVANT_POLL_DURATION)]."))
	INVOKE_ASYNC(src, PROC_REF(call_ghoul_spirit), user, victim)
	return TRUE

/datum/eldritch_knowledge/flesh_grasp/proc/can_raise_ghoul(mob/living/user, mob/living/carbon/human/victim)
	if(QDELETED(victim) || victim.stat != DEAD)
		return FALSE
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	var/datum/eldritch_knowledge/base_flesh/path = heretic?.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	if(!path || path.combat_resource < 1 || length(flesh_servants) >= heretic.flesh_kind_limit() || !heretic.can_add_servant())
		to_chat(user, span_warning("Недостаточно биомассы или нет места в свите."))
		return FALSE
	var/block_reason = heretic_conversion_block_reason(victim)
	if(block_reason)
		to_chat(user, span_warning(block_reason))
		return FALSE
	return TRUE

/datum/eldritch_knowledge/flesh_grasp/proc/call_ghoul_spirit(mob/living/user, mob/living/carbon/human/victim)
	ghoul_poll_pending = TRUE
	var/list/mob/dead/observer/candidates = poll_servant_candidates("Хотите стать гулем, слугой [user.real_name]?", victim, HERETIC_SERVANT_POLL_DURATION)
	ghoul_poll_pending = FALSE
	if(QDELETED(src) || QDELETED(user) || !can_raise_ghoul(user, victim))
		return FALSE
	if(!victim.client)
		var/mob/dead/observer/chosen = length(candidates) ? pick(candidates) : null
		if(!chosen?.key)
			to_chat(user, span_warning("Ни один дух не откликнулся: тело остаётся мёртвым, биомасса сохранена."))
			return FALSE
		victim.ghostize(FALSE)
		victim.key = chosen.key
	return raise_ghoul(user, victim)

/datum/eldritch_knowledge/flesh_grasp/proc/raise_ghoul(mob/living/user, mob/living/carbon/human/victim)
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	var/datum/eldritch_knowledge/base_flesh/path = heretic?.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	if(!victim.mind || !path?.spend_combat_resource())
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
	summary = "Мёртвый человек, мак и 2 биомассы дают Безмолвного мертвеца с 90 здоровья."
	details = list(
		"Безмолвный мертвец подчиняется вам и не может говорить; держится до 2.",
		"Если душа не вернётся, роль ждёт призраков; без отклика компоненты сохранятся.",
		"Щит разума, синтетики, скелеты, истощённые и уже поднятые тела не подходят.",
		"Мертвец занимает место в общей свите.",
	)
	role = HERETIC_ROLE_RITUAL
	gain_text = "Плоть услышала меня. Голос ей больше не понадобится."
	cost = 1
	required_atoms = list(/mob/living/carbon/human, /obj/item/reagent_containers/food/snacks/grown/poppy)
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_ghoul/recipe_block_reason(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_flesh/path = heretic?.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	if(!path)
		return "Обряд требует открытого Пути Плоти."
	if(path.combat_resource < 2)
		return "Нужно 2 биомассы, у вас [round(path.combat_resource, 0.1)]. Биомасса собирается из меток Плоти и извлечённых органов."
	if(length(flesh_servants) >= heretic.flesh_kind_limit())
		return "Вы уже удерживаете предельное число Безмолвных мертвецов: [heretic.flesh_kind_limit()]."
	if(!heretic.can_add_servant())
		return "Свита заполнена: новый слуга не поместится, пока вы не потеряете одного из прежних."
	return null

/datum/eldritch_knowledge/flesh_ghoul/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return ..() && !recipe_block_reason(user)

/datum/eldritch_knowledge/flesh_ghoul/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/mob/living/carbon/human/victim = locate() in atoms
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	var/datum/eldritch_knowledge/base_flesh/path = heretic?.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	if(QDELETED(victim) || victim.stat != DEAD || length(flesh_servants) >= heretic.flesh_kind_limit() || !path || path.combat_resource < 2 || !heretic.can_add_servant())
		return FALSE
	var/block_reason = heretic_conversion_block_reason(victim)
	if(block_reason)
		to_chat(user, span_warning(block_reason))
		return FALSE
	victim.grab_ghost()
	if(!victim.mind || !victim.client)
		var/list/mob/dead/observer/candidates = poll_servant_candidates("Хотите стать Безмолвным мертвецом, слугой [user.real_name]?", victim, HERETIC_SERVANT_POLL_DURATION)
		if(!length(candidates))
			to_chat(user, span_warning("Ни одна душа не откликнулась, и тело осталось пустым. Компоненты не израсходованы."))
			return FALSE
		if(!ritual_still_valid(user, atoms, get_turf(loc)) || victim.stat != DEAD || length(flesh_servants) >= heretic.flesh_kind_limit() || heretic_conversion_block_reason(victim) || QDELETED(path) || path.combat_resource < 2 || !heretic.can_add_servant())
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
	if(heretic.simulated)
		servant.show_in_roundend = FALSE
		servant.soft_antag = TRUE
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
	summary = "Хватка ставит метку на 15 секунд, удар клинком плоти её взрывает."
	details = list(
		"Взрыв открывает на случайной конечности среднюю резаную рану и усиливает кровотечение.",
		"Взрыв даёт биомассу для гулей, ползуна и Сшивания.",
		"Без удара клинком метка спадает через 15 секунд.",
	)
	role = HERETIC_ROLE_MARK
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
	summary = "Клинок плоти добавляет 2 ушиба и поддерживает кровотечение."
	details = list(
		"Улучшения: 2 / 3 / 4 ушиба и столько же тиков кровотечения за удар.",
		"Кровь течёт дольше, но не быстрее.",
		"Бескровные тела получают прямой урон.",
	)
	role = HERETIC_ROLE_PASSIVE
	gain_text = "Маршал показал мне разницу между раной и разрезом."
	cost = 2
	route = PATH_FLESH

/datum/eldritch_knowledge/flesh_blade_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(!iscarbon(target))
		return
	var/mob/living/carbon/victim = target
	if(!length(victim.bodyparts))
		return
	victim.adjustBruteLoss(passive_values[passive_level])
	var/obj/item/bodypart/limb = pick(victim.bodyparts)
	limb.generic_bleedstacks += passive_values[passive_level]

/datum/eldritch_knowledge/summon/raw_prophet
	name = "Нечестивый ритуал"
	summary = "Глаза, левая рука и кровь призывают сырого пророка - хрупкого разведчика на 50 здоровья."
	details = list(
		"Пророк видит сквозь стены и дальше обычного, пеплом проходит сквозь стены на 7,5 секунды.",
		"Связь Мансуса подключает к мысленной речи живых без щита разума и защиты от магии.",
		"Пророк умеет ослеплять врагов и говорить мысленно.",
		"Нужен призрак-доброволец, иначе компоненты сохранятся; этого слуги держится до 2.",
	)
	role = HERETIC_ROLE_RITUAL
	gain_text = "Я попросил глаза, способные увидеть больше моего голода."
	cost = 1
	required_atoms = list(/obj/item/organ/eyes, /obj/item/bodypart/l_arm, /obj/effect/decal/cleanable/blood)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/raw_prophet
	route = PATH_FLESH

/datum/eldritch_knowledge/summon/stalker
	name = "Одинокий ритуал"
	summary = "Нож, свеча, ручка и бумага призывают преследователя на 300 здоровья."
	details = list(
		"Преследователь бьёт на 15-20, пеплом проходит сквозь стены и меняет облик.",
		"Его импульс ЭМИ выводит из строя технику вокруг.",
		"Нужен призрак-доброволец, иначе компоненты сохранятся; этого слуги держится до 2.",
	)
	role = HERETIC_ROLE_RITUAL
	gain_text = "На пустой странице уже стояла подпись того, кто придёт."
	cost = 1
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/candle, /obj/item/pen, /obj/item/paper)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/stalker
	route = PATH_FLESH

/datum/eldritch_knowledge/summon/ashy
	name = "Пепельный ритуал"
	summary = "Пепел, отрубленная голова и книга призывают пепельного духа на 75 здоровья."
	details = list(
		"Дух бьёт на 15-20, пеплом проходит сквозь стены, режет Рассечением и бьёт Огненным каскадом.",
		"Нужен призрак-доброволец, иначе компоненты сохранятся; этого слуги держится до 2.",
	)
	role = HERETIC_ROLE_RITUAL
	gain_text = "Огонь тоже умеет быть голодным."
	cost = 1
	required_atoms = list(/obj/effect/decal/cleanable/ash, /obj/item/bodypart/head, /obj/item/book)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/ash_spirit

/datum/eldritch_knowledge/summon/rusty
	name = "Ржавый ритуал"
	summary = "Рвота, отрубленная голова и книга призывают ржавого ходока на 200 здоровья."
	details = list(
		"Ходок бьёт на 25-35, ржавит всё вокруг и стреляет зарядами ржавчины на 7 клеток.",
		"Вся свита - не больше 4 слуг, после вознесения Плоти - 8.",
		"Нужен призрак-доброволец, иначе компоненты сохранятся; этого слуги держится до 2.",
	)
	role = HERETIC_ROLE_RITUAL
	gain_text = "Кузнец не возражал, когда его сад научился ходить."
	cost = 1
	required_atoms = list(/obj/effect/decal/cleanable/vomit, /obj/item/bodypart/head, /obj/item/book)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/rust_spirit

/datum/eldritch_knowledge/spell/blood_siphon
	name = "Кровавый сифон"
	summary = "Вытягивает из врага в 6 клетках 20 здоровья вам, а часть ваших ран переходит к нему."
	details = list(
		"Укажите врага: он получает 20 ушибов, вы лечите 20 и забираете до 20 единиц его крови.",
		"Каждая ваша рана с шансом 50% переходит на ту же конечность цели.",
		"Защита от магии срывает сифон. Перезарядка 15 секунд.",
	)
	role = HERETIC_ROLE_SUPPORT
	gain_text = "Маршал назвал кровь ещё одной дорогой."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/blood_siphon

/datum/eldritch_knowledge/flesh_blade_upgrade_2
	name = "Воспоминание"
	summary = "Клинок плоти вывихивает конечности, а зажим, нить и орган дают сшивающую иглу."
	details = list(
		"Удар клинком плоти вывихивает случайную часть тела, не чаще раза в 8 секунд.",
		"Зажим, шовная нить и извлечённый орган на руне дают сшивающую иглу.",
		"Игла по своему живому слуге: 3 секунды и 1 биомасса - отрастает утраченная рука или нога.",
		"Если конечности целы, игла останавливает кровотечение. Задержка 10 секунд.",
		"На посторонних и защищённых от магии игла не действует.",
	)
	role = HERETIC_ROLE_RELIC
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
	summary = "Касание: 60 урона мозгу, падение на 3 секунды и случайная фобия."
	details = list(
		"Подготовьте руку и коснитесь врага: он падает на 3 секунды, мозг получает 60 урона.",
		"Цель получает случайную фобию.",
		"Пока цель лежит, она готова к обряду живым сердцем.",
		"Защита от магии отражает касание, заряд тратится. Перезарядка 3 минуты.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Мой голод смотрит на них изнутри."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	spell_to_add = /obj/effect/proc_holder/spell/targeted/touch/mad_touch
	route = PATH_FLESH

/datum/eldritch_knowledge/final_eldritch/flesh_final
	name = "Последний гимн жреца"
	summary = "Облик Повелителя Ночи: червь пожирает трупы и растёт, а свита вырастает до 8."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; станция узнаёт место и 30 секунд может помешать.",
		"Человек получает общую стойкость вознесения; «Сбросить облик» меняет его на червя, перезарядка 10 секунд.",
		"Голова червя за 3 секунды пожирает труп: +100 здоровья и сегмент, до 16 сегментов.",
		"Вещи и органы съеденного, включая мозг, падают; еретиков, слуг и трупы в шкафах и мешках червь не ест.",
		"Гулей и Безмолвных мертвецов - до 4 каждого вида, всей свиты - до 8.",
		"Убитый червь выбрасывает вас человеком; облик вернётся через 2 минуты с половиной здоровья.",
		"Слабость: червь огромен, сегменты рубятся по одному; урон, шаг червя или сдвиг трупа срывают трапезу.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Маршал уступил мне место во главе процессии."
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	cost = 3
	sacs_needed = HERETIC_ASCENSION_SACRIFICES
	route = PATH_FLESH
	parallax_scene = ANTAG_SCENE_HERETIC_FLESH
	ascension_spells = list(/obj/effect/proc_holder/spell/targeted/shed_human_form)
	var/list/shed_form_health
	var/ascension_active = FALSE

/datum/eldritch_knowledge/final_eldritch/flesh_final/on_body_gain(mob/living/user)
	. = ..()
	if(finished && applied_body == user)
		ascension_active = TRUE

/datum/eldritch_knowledge/final_eldritch/flesh_final/on_body_lose(mob/living/user)
	ascension_active = FALSE
	var/worm_killed = FALSE
	if(applied_body == user && istype(user, /mob/living/simple_animal/hostile/eldritch/armsy/prime))
		worm_killed = user.stat == DEAD
		shed_form_health = list()
		var/mob/living/simple_animal/hostile/eldritch/armsy/segment = user
		while(segment)
			shed_form_health += worm_killed ? segment.maxHealth * HERETIC_FLESH_WORM_REVIVE_HEALTH_RATIO : max(1, segment.health)
			segment = segment.back
	. = ..()
	if(worm_killed)
		ascension_spell_ready_at[/obj/effect/proc_holder/spell/targeted/shed_human_form] = world.time + HERETIC_FLESH_WORM_DEATH_COOLDOWN

/datum/eldritch_knowledge/final_eldritch/flesh_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	if(!simulated)
		user.client?.give_award(/datum/award/achievement/misc/flesh_ascension, user)
	return TRUE

#undef GHOUL_MAX_HEALTH
#undef VOICELESS_DEAD_MAX_HEALTH
#undef HERETIC_SERVANT_LIMIT
#undef HERETIC_ASCENDED_FLESH_SERVANT_LIMIT
#undef HERETIC_FLESH_KIND_LIMIT
#undef HERETIC_ASCENDED_FLESH_KIND_LIMIT
