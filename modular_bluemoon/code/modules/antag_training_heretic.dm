/datum/antag_training_program
	var/name
	var/category = "Общее"
	var/desc
	/// id сектора, куда программа ставит куклу при старте; null - ядро полигона.
	var/sector
	var/list/options = list()
	/// Какие должности участника применяются поверх программы.
	var/allowed_roles = ANTAG_TRAINING_ROLES_NONE
	/// Вариант -> подсказка на кнопке пульта.
	var/list/option_hints = list()
	/// Имя куклы, которое вход не заменяет именем призрака.
	var/avatar_name
	/// Подпись кнопки учебной цели, которая зовёт target_created(); null - кнопки нет.
	var/target_action
	/// Тип-заготовка, равный своему типу: каталог, пульт и вход его не принимают.
	var/abstract_type
	/// Иконка Font Awesome и цвет палитры tgui в каталоге и пульте.
	var/icon
	var/color
	/// «Что вы освоите»: пункты через «|», потому что initial() не читает списки.
	var/learn
	var/difficulty
	/// Место в «С чего начать»; 0 - программы там нет.
	var/order = 0

/proc/antag_training_program_selectable(program_type)
	var/datum/antag_training_program/program = program_type
	return ispath(program_type, /datum/antag_training_program) && program_type != /datum/antag_training_program && initial(program.abstract_type) != program_type

/datum/antag_training_program/proc/setup(datum/antag_training_session/session)
	return FALSE

/datum/antag_training_program/proc/handle_choice(datum/antag_training_session/session, mob/living/user, choice)
	return

/datum/antag_training_program/proc/target_created(datum/antag_training_session/session, mob/living/carbon/human/target)
	return

/// Сеанс потерял тело: TRUE, если программа сама вернула участнику тело и сеанс продолжается.
/datum/antag_training_program/proc/body_lost(datum/antag_training_session/session)
	return FALSE

/// Восстановление тела без здоровья (камера-моб): TRUE, если программа создала участнику новое тело.
/datum/antag_training_program/proc/rebuild_body(datum/antag_training_session/session)
	return FALSE

/datum/antag_training_program/heretic
	name = "Еретик — все пути"
	category = "Культы и магия"
	desc = "Любой путь Мансуса: ступени кодекса, рецепты обрядов, охота и подношения учебных целей, вознесение."
	icon = "book-skull"
	color = "green"
	learn = "Выбор пути и ступени кодекса|Рецепты обрядов и их компоненты|Охота: цель, сердце и подношение|Вознесение своего пути"
	difficulty = 3
	order = 5
	target_action = "Цель охоты"
	options = list("Добавить очки знаний", "Предметы изученного рецепта", "Компоненты изученного рецепта", "Подготовить вознесение")

/datum/antag_training_program/heretic/New()
	. = ..()
	option_hints = list(
		"Добавить очки знаний" = "Очки знаний и побочных знаний вырастут до [ANTAG_TRAINING_POINTS], если их меньше. Жмите, когда кодексу не хватает очков на следующую ступень пути или улучшение, затем изучайте их в кодексе. В раунде очки дают разрывы влияния и подношения.",
		"Предметы изученного рецепта" = "Выберите изученный рецепт: рядом на полу появится то, что даёт его обряд, без компонентов и руны. Жмите, чтобы сразу опробовать клинок, амулет или другой результат. Если предмет рецепта уже есть, сначала верните или удалите прежний.",
		"Компоненты изученного рецепта" = "Выберите изученный рецепт: рядом лягут его компоненты, а нужные обряду тела - учебными трупами, из центра и переходов - в лаборатории. Жмите, чтобы отработать обряд целиком: начертите руну кодексом у компонентов и проведите его.",
		"Подготовить вознесение" = "Все ступени выбранного пути изучаются сразу, а подношений засчитывается [HERETIC_ASCENSION_SACRIFICES]. Жмите, когда путь выбран и хочется сразу к финалу: затем «Компоненты изученного рецепта» у финального обряда дадут тела, а руна у них - вознесение. В раунде до вознесения идут всю смену.",
	)

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
		to_chat(session.current_body, span_notice("[target.real_name] назначена целью охоты. Призовите сердце, обезвредьте цель и коснитесь её сердцем. Можно и начертить руну кодексом и провести Обряд возвращения на ней."))

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
		to_chat(user, span_notice("Все ступени пути изучены. Встаньте в секторе и нажмите «Компоненты» у финального обряда в «Моей роли»: три тела лягут рядом с вами. Начертите руну у тел и проведите заключительный обряд. Учебное вознесение не выдаёт достижений."))
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
	session.issue_recipe(recipe, choice == "Компоненты изученного рецепта")

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
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/heretic/training/proc/brief()
	to_chat(owner, span_boldnotice("Тренировка еретика: призовите кодекс и выберите любой путь. «Пульт полигона» выдаёт очки, компоненты и предметы изученных рецептов, учебную цель и снимает с вас любые травмы."))
	to_chat(owner, span_notice("Другие еретики и их слуги защищены от ваших боевых заклинаний. Для проверки урона создайте учебную цель или попросите участника выбрать другую роль. Жатва Духа бьёт второй раз, пока связь цела: цель дальше одной клетки от своей души получает полный удар, неподвижная цель возле неё — ослабленный."))

/datum/antagonist/heretic/training/announce_threat()
	ascension_notice_sent = TRUE
	ascension_ready_at = world.time
	return FALSE

/datum/antagonist/heretic/training/hunt_target_unavailable_reason(datum/mind/candidate, selecting = FALSE)
	if(!training || QDELETED(candidate) || !(candidate in training.arena.target_minds) && !(candidate in training.arena.participant_minds()) || QDELETED(candidate.current) || !training.arena.owns_area(get_area(heretic_pocket_anchor(get_turf(candidate.current)))))
		return "Создайте учебную цель в «Пульте полигона»."
	if(candidate in sacrificed_minds)
		return "Эта учебная душа уже принята. Создайте новый манекен."
	if(candidate == owner || IS_HERETIC(candidate.current) || IS_HERETIC_MONSTER(candidate.current))
		return "Слуга не подходит для подношения."
	if(selecting && candidate.current.stat == DEAD)
		return "Для назначения нужен живой манекен."
	return null

/datum/antagonist/heretic/training/claim_is_crew_player(mob/living/carbon/human/victim)
	return TRUE

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


/datum/antagonist/heretic/training/deed_key_for(atom/target)
	var/turf/tile = get_turf(target)
	if(!training?.arena || !training.arena.inside_bounds(tile, training.arena.zones["laboratory"]["bounds"]))
		return ..()
	return "workplace_[clamp(round((tile.x - 5) / 6), 0, 2)]_[clamp(round((tile.y - 33) / 6), 0, 2)]"
