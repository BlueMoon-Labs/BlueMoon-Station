#define ANTAG_TRAINING_POINTS 100

/datum/antag_training_program
	var/name
	var/list/options = list()

/datum/antag_training_program/proc/setup(datum/antag_training_session/session)
	return FALSE

/datum/antag_training_program/proc/handle_choice(datum/antag_training_session/session, mob/living/user, choice)
	return

/datum/antag_training_program/proc/target_created(datum/antag_training_session/session, mob/living/carbon/human/target)
	return

/datum/antag_training_program/heretic
	name = "Еретик — все пути"
	options = list("Добавить очки знаний", "Предметы изученного рецепта", "Компоненты изученного рецепта", "Подготовить вознесение")

/datum/antag_training_program/heretic/setup(datum/antag_training_session/session)
	var/datum/antagonist/heretic/training/heretic = new
	heretic.training = session
	session.avatar.mind.add_antag_datum(heretic)
	session.avatar.put_in_hands(heretic.get_forbidden_book())
	return TRUE

/datum/antag_training_program/heretic/target_created(datum/antag_training_session/session, mob/living/carbon/human/target)
	var/mob/living/user = session.current_body
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(heretic && heretic.hunt_target_available(target.mind, selecting = TRUE))
		heretic.set_hunt_target(target.mind)
		to_chat(session.current_body, span_notice("[target.real_name] назначена целью охоты. Призовите сердце, начертите руну кодексом и проведите Обряд возвращения."))

/datum/antag_training_program/heretic/handle_choice(datum/antag_training_session/session, mob/living/user, choice)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic)
		return
	if(choice == "Добавить очки знаний")
		heretic.knowledge_points = max(heretic.knowledge_points, ANTAG_TRAINING_POINTS)
		heretic.side_knowledge_points = max(heretic.side_knowledge_points, ANTAG_TRAINING_POINTS)
		heretic.refresh_book_ui()
		to_chat(user, span_notice("Вы получили запас очков. Откройте кодекс, чтобы изучить нужные ступени и улучшения."))
		return
	if(choice == "Подготовить вознесение")
		var/datum/heretic_path/path = GLOB.heretic_paths[heretic.selected_path]
		if(!path)
			to_chat(user, span_warning("Сначала выберите путь в кодексе."))
			return
		heretic.total_sacrifices = max(heretic.total_sacrifices, HERETIC_ASCENSION_SACRIFICES)
		heretic.knowledge_points = max(heretic.knowledge_points, ANTAG_TRAINING_POINTS)
		for(var/knowledge_type in path.knowledge)
			if(!heretic.get_knowledge(knowledge_type))
				heretic.research_knowledge(knowledge_type, user)
		to_chat(user, span_notice("Все ступени пути изучены. Создайте три тела, уложите их у руны и проведите заключительный обряд. Учебное вознесение не выдаёт достижений."))
		return
	if(world.time < session.next_supply_at)
		to_chat(user, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return
	var/list/recipes = list()
	for(var/knowledge_type in heretic.researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = heretic.researched_knowledge[knowledge_type]
		if(length(choice == "Предметы изученного рецепта" ? knowledge.result_atoms : knowledge.required_atoms))
			recipes[knowledge.name] = knowledge
	var/recipe_name = tgui_input_list(user, "Выберите изученный рецепт. Предметы появятся на полу рядом с вами.", choice, recipes)
	if(!recipe_name || QDELETED(src) || QDELETED(session) || !session.can_control(user) || world.time < session.next_supply_at)
		return
	var/datum/eldritch_knowledge/recipe = recipes[recipe_name]
	if(QDELETED(recipe) || heretic.get_knowledge(recipe.type) != recipe)
		return
	session.next_supply_at = world.time + 5 SECONDS
	var/list/items = choice == "Предметы изученного рецепта" ? recipe.result_atoms : recipe.required_atoms
	for(var/item_type in items)
		if(!ispath(item_type, /obj/item) && !ispath(item_type, /obj/structure) && !ispath(item_type, /obj/effect/decal/cleanable))
			continue
		var/count = items[item_type] || 1
		if(ispath(item_type, /obj/item/stack))
			if(!session.arena.issue_item(item_type, get_turf(user), count, session))
				break
		else
			for(var/index in 1 to count)
				if(!session.arena.issue_item(item_type, get_turf(user), creator = session))
					break

/datum/antagonist/heretic/training
	simulated = TRUE
	name = "Учебный еретик"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	prevent_roundtype_conversion = FALSE
	soft_antag = TRUE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	var/datum/antag_training_session/training

/datum/antagonist/heretic/training/forge_primary_objectives()
	return

/datum/antagonist/heretic/training/threat()
	return 0

/datum/antagonist/heretic/training/greet()
	to_chat(owner, span_boldnotice("Тренировка еретика: призовите кодекс и выберите любой путь. Настройки полигона позволяют выдать очки, снаряжение и учебную цель."))

/datum/antagonist/heretic/training/announce_threat()
	ascension_notice_sent = TRUE
	ascension_ready_at = world.time
	return FALSE

/datum/antagonist/heretic/training/hunt_target_unavailable_reason(datum/mind/candidate, selecting = FALSE)
	if(!training || QDELETED(candidate) || !(candidate in training.arena.target_minds) && !(candidate in training.arena.participant_minds()) || QDELETED(candidate.current) || get_area(candidate.current) != training.arena.room)
		return "Создайте учебную цель через настройки полигона."
	if(candidate in sacrificed_minds)
		return "Эта учебная душа уже принята. Создайте новый манекен."
	if(candidate == owner || IS_HERETIC(candidate.current) || IS_HERETIC_MONSTER(candidate.current))
		return "Слуга не подходит для подношения."
	if(selecting && candidate.current.stat == DEAD)
		return "Для назначения нужен живой манекен."
	return null

/datum/antagonist/heretic/training/prepare_hunt_choices()
	hunt_candidates.Cut()
	var/list/choices = list()
	for(var/datum/mind/candidate as anything in training.arena.target_minds + training.arena.participant_minds())
		if(!hunt_target_available(candidate, selecting = TRUE))
			continue
		var/datum/weakref/candidate_ref = WEAKREF(candidate)
		hunt_candidates += candidate_ref
		choices[candidate.current.real_name] = candidate_ref
	return choices

/datum/antagonist/heretic/training/get_hunt_return_turf()
	return training?.arena.zones["laboratory"]["target"]

/datum/antagonist/heretic/training/Destroy()
	training = null
	return ..()

#undef ANTAG_TRAINING_POINTS

/datum/antagonist/heretic/training/deed_key_for(atom/target)
	var/turf/tile = get_turf(target)
	if(!training?.arena || !training.arena.inside_bounds(tile, training.arena.zones["laboratory"]["bounds"]))
		return ..()
	return "workplace_[clamp(round((tile.x - 5) / 6), 0, 2)]_[clamp(round((tile.y - 33) / 6), 0, 2)]"
