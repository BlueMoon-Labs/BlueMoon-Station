/datum/eldritch_knowledge
	var/passive_level = 1
	var/list/passive_values
	var/passive_desc

/datum/eldritch_knowledge/ash_blade_upgrade
	passive_values = list(1, 2, 3)
	passive_desc = "Огненный клинок наносит 2 / 4 / 6 прямых ожогов и добавляет 1 / 2 / 3 заряда горения за удар. Прямой урон работает и по негорящей цели."

/datum/eldritch_knowledge/rust_regen
	passive_values = list(1, 1.25, 1.5)
	passive_desc = "Лечение Ржавой поступи усиливается до 100 / 125 / 150%: ушибы, ожоги, отравление и выносливость. Работает только на ржавом полу."

/datum/eldritch_knowledge/flesh_blade_upgrade
	passive_values = list(2, 3, 4)
	passive_desc = "Иссекающая сталь наносит 2 / 3 / 4 дополнительных ушиба и поддерживает кровотечение на 2 / 3 / 4 тика. Продление кровотечения не увеличивает скорость потери крови; прямой урон действует и на бескровные тела."

/datum/eldritch_knowledge/void_grasp
	passive_values = list(30, 40, 50)
	passive_desc = "Хватка Пустоты снижает температуру тела врага на 30 / 40 / 50 градусов. На втором и третьем уровнях хватка по уже скованной Пустотой цели также наносит 5 / 10 ожогов. На всех уровнях замедление длится 4 секунды; молчание не усиливается."

/datum/eldritch_knowledge/blade_guard
	passive_values = list(10, 15, 20)
	passive_desc = "Успешное парирование восстанавливает 10 / 15 / 20 выносливости. Стойка даёт четыре блока на три секунды; между блоками 0,1 секунды."

/datum/eldritch_knowledge/moon_shroud
	passive_values = list(60 SECONDS, 75 SECONDS, 90 SECONDS)
	passive_desc = "Новые отражения живут 60 / 75 / 90 секунд. Уже созданные копии сохраняют прежний срок жизни."

/datum/eldritch_knowledge/cosmic_resonance
	passive_values = list(70, 85, 100)
	passive_desc = "Прочность звёзд составляет 70 / 85 / 100. Улучшение усиливает и существующие звёзды, сохраняя полученный ими урон."

/datum/eldritch_knowledge/proc/on_passive_upgrade(mob/living/user)
	return

/datum/eldritch_knowledge/cosmic_resonance/on_passive_upgrade(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	for(var/obj/structure/heretic_star/star as anything in knowledge?.stars)
		var/damage = star.max_integrity - star.obj_integrity
		star.max_integrity = passive_values[passive_level]
		star.obj_integrity = max(0, star.max_integrity - damage)

/datum/antagonist/heretic/proc/passive_upgrade_error(knowledge_type)
	var/datum/heretic_path/path = GLOB.heretic_paths[selected_path]
	if(role_removed || !path || !(knowledge_type in path.knowledge))
		return "Это улучшение недоступно на вашем пути."
	var/datum/eldritch_knowledge/knowledge = get_knowledge(knowledge_type)
	if(!knowledge)
		return "Сначала изучите это знание."
	if(!length(knowledge.passive_values))
		return "У этого знания нет улучшений пассивки."
	if(knowledge.passive_level >= length(knowledge.passive_values))
		return "Достигнут максимальный уровень."
	if(knowledge_points + side_knowledge_points < knowledge.passive_level)
		return "Не хватает знаний: нужно [knowledge.passive_level]."
	return null

/datum/antagonist/heretic/proc/upgrade_passive(knowledge_type, mob/living/user, expected_level)
	if(!user || user.mind != owner || IS_HERETIC(user) != src || user.incapacitated())
		return FALSE
	var/error_message = passive_upgrade_error(knowledge_type)
	if(error_message)
		to_chat(user, span_warning(error_message))
		return FALSE
	var/datum/eldritch_knowledge/knowledge = get_knowledge(knowledge_type)
	if(expected_level != knowledge.passive_level)
		return FALSE
	var/side_payment = min(side_knowledge_points, knowledge.passive_level)
	side_knowledge_points -= side_payment
	knowledge_points -= knowledge.passive_level - side_payment
	knowledge.passive_level++
	knowledge.on_passive_upgrade(user)
	refresh_book_ui()
	to_chat(user, span_notice("[knowledge.name]: пассивка улучшена до уровня [knowledge.passive_level]."))
	log_game("[key_name(user)] улучшает пассивку [knowledge.name] до уровня [knowledge.passive_level].")
	return TRUE

/datum/antagonist/heretic/proc/passive_upgrade_data()
	var/list/data = list()
	var/datum/heretic_path/path = GLOB.heretic_paths[selected_path]
	for(var/knowledge_type in path?.knowledge)
		var/datum/eldritch_knowledge/knowledge = get_knowledge(knowledge_type)
		if(!length(knowledge?.passive_values))
			continue
		var/reason = passive_upgrade_error(knowledge_type)
		data["[knowledge_type]"] = list(
			"level" = knowledge.passive_level,
			"max_level" = length(knowledge.passive_values),
			"cost" = knowledge.passive_level < length(knowledge.passive_values) ? knowledge.passive_level : 0,
			"available" = !reason,
			"reason" = reason,
			"description" = knowledge.passive_desc,
		)
	return data
