/// allocate() подставляет турф первым аргументом, а для mind это ключ.
/datum/unit_test/proc/allocate_mind()
	var/datum/mind/mind = new
	allocated += mind
	return mind

/datum/unit_test/proc/allocate_heretic(turf/location)
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, location || run_loc_floor_bottom_left)
	var/datum/mind/mind = allocate_mind()
	mind.current = body
	body.mind = mind
	var/datum/antagonist/heretic/heretic = allocate(/datum/antagonist/heretic)
	heretic.owner = mind
	heretic.silent = TRUE
	mind.antag_datums = list(heretic)
	return heretic

/// Независимые пути укладываются в бюджет охоты.
/datum/unit_test/heretic_knowledge/Run()
	TEST_ASSERT_EQUAL(length(GLOB.heretic_paths), 12, "В каталоге должны быть все двенадцать путей.")
	var/list/registered = GLOB.heretic_start_knowledge.Copy()
	registered |= GLOB.heretic_side_knowledge
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		TEST_ASSERT_EQUAL(path.id, path_id, "Идентификатор пути должен совпадать с ключом каталога.")
		TEST_ASSERT_EQUAL(length(path.knowledge), 10, "У каждого пути десять последовательных ступеней.")
		var/list/unique_nodes = list()
		var/total_cost = 0
		for(var/index in 1 to length(path.knowledge))
			var/datum/eldritch_knowledge/knowledge = path.knowledge[index]
			TEST_ASSERT(ispath(knowledge, /datum/eldritch_knowledge), "Все ступени должны быть знаниями.")
			TEST_ASSERT(!(knowledge in unique_nodes), "В пути не должно быть повторных ступеней.")
			TEST_ASSERT(!(knowledge in registered), "Главное знание не должно принадлежать двум путям или боковой ветви.")
			TEST_ASSERT_EQUAL(initial(knowledge.route), path.id, "Ступень должна принадлежать своему пути.")
			unique_nodes += knowledge
			total_cost += initial(knowledge.cost)
		var/datum/eldritch_knowledge/starting_knowledge = path.knowledge[1]
		TEST_ASSERT_EQUAL(initial(starting_knowledge.cost), 0, "Первый выбор пути бесплатный.")
		TEST_ASSERT(ispath(path.knowledge[length(path.knowledge)], /datum/eldritch_knowledge/final_eldritch), "Путь завершается вознесением.")
		TEST_ASSERT(total_cost <= HERETIC_STARTING_KNOWLEDGE + HERETIC_INFLUENCE_LIMIT + HERETIC_DEED_TIERS * HERETIC_DEED_KNOWLEDGE + HERETIC_LIVE_SACRIFICE_KNOWLEDGE * HERETIC_ASCENSION_SACRIFICES, "Бюджета разломов, дела пути и живых душ должно хватать на весь основной путь.")
		registered |= unique_nodes
	var/list/abstract_types = list(/datum/eldritch_knowledge/spell, /datum/eldritch_knowledge/spell/summon, /datum/eldritch_knowledge/curse, /datum/eldritch_knowledge/summon, /datum/eldritch_knowledge/final_eldritch)
	for(var/datum/eldritch_knowledge/knowledge_type as anything in subtypesof(/datum/eldritch_knowledge) - abstract_types)
		TEST_ASSERT(knowledge_type in registered, "Знание [knowledge_type] должно присутствовать в каталоге.")

/datum/unit_test/heretic_research_authority/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(run_loc_floor_bottom_left, EAST))
	heretic.knowledge_points = 0
	TEST_ASSERT(!heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, other.owner.current), "Нельзя исследовать знания от лица чужого еретика.")
	TEST_ASSERT(!heretic.research_knowledge(/obj/item/pen, user), "Произвольный typepath не должен приниматься.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, user), "Бесплатный выбор пути доступен без очков.")
	TEST_ASSERT_EQUAL(heretic.selected_path, PATH_ASH, "Выбранный путь фиксируется на еретике.")
	TEST_ASSERT(!heretic.research_knowledge(/datum/eldritch_knowledge/base_rust, user), "Второй путь недоступен после выбора.")
	TEST_ASSERT(!heretic.research_knowledge(/datum/eldritch_knowledge/ashen_grasp, user), "Без очков нельзя купить следующую ступень.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, 0, "Неудачные покупки не меняют баланс.")
	heretic.knowledge_points = 100
	TEST_ASSERT(!heretic.research_knowledge(/datum/eldritch_knowledge/ash_mark, user), "Нельзя перескочить через ступени даже с достаточным балансом.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/ashen_grasp, user), "Следующая ступень доступна.")
	var/points_after = heretic.knowledge_points
	TEST_ASSERT(!heretic.research_knowledge(/datum/eldritch_knowledge/ashen_grasp, user), "Нельзя оплатить одно знание дважды.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, points_after, "Повторный запрос не списывает очки.")

/datum/unit_test/heretic_research_sacrifices/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.path_stage = 9
	heretic.knowledge_points = 100
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES - 1
	TEST_ASSERT(!heretic.research_knowledge(/datum/eldritch_knowledge/final_eldritch/cosmic_final, user), "Финальное знание требует все назначенные души независимо от баланса.")
	heretic.total_sacrifices++
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/final_eldritch/cosmic_final, user), "Пять душ открывают финальное знание.")
	TEST_ASSERT(!heretic.ascended, "Исследование рецепта само по себе не возносит еретика.")

/datum/unit_test/heretic_knowledge_spell_lifecycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/effect/proc_holder/spell/foreign_spell = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	heretic.owner.AddSpell(foreign_spell)
	TEST_ASSERT(heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic), "Стартовая хватка должна выдаваться.")
	var/datum/eldritch_knowledge/spell/basic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/obj/effect/proc_holder/spell/own_spell = knowledge.granted_spell
	knowledge.on_body_gain(user)
	TEST_ASSERT_EQUAL(knowledge.granted_spell, own_spell, "Повторное применение эффектов не выдаёт вторую способность.")
	knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(own_spell), "Снятие знания удаляет свой экземпляр заклинания.")
	TEST_ASSERT(!QDELETED(foreign_spell), "Снятие знания сохраняет однотипное заклинание из другого источника.")
	TEST_ASSERT(foreign_spell in heretic.owner.spell_list, "Чужое заклинание остаётся в mind.")
	knowledge.on_body_gain(user)
	TEST_ASSERT(!QDELETED(knowledge.granted_spell), "В новом теле способность выдаётся повторно.")

/datum/unit_test/heretic_codex_personal_progress/Run()
	var/datum/antagonist/heretic/first = allocate_heretic()
	var/datum/antagonist/heretic/second = allocate_heretic(get_step(run_loc_floor_bottom_left, EAST))
	first.knowledge_points = 7
	second.knowledge_points = 2
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	var/list/first_data = book.ui_data(first.owner.current)
	var/list/second_data = book.ui_data(second.owner.current)
	TEST_ASSERT_EQUAL(first_data["points"], 7, "Одна книга показывает баланс первого читателя.")
	TEST_ASSERT_EQUAL(second_data["points"], 2, "Следующий читатель видит свой баланс.")
	qdel(book)
	var/obj/item/forbidden_book/replacement = allocate(/obj/item/forbidden_book)
	var/list/replacement_data = replacement.ui_data(first.owner.current)
	TEST_ASSERT_EQUAL(replacement_data["points"], 7, "Уничтожение книги не уничтожает прогресс.")
	var/list/static_data = replacement.ui_static_data(first.owner.current)
	var/list/paths = static_data["paths"]
	TEST_ASSERT_EQUAL(length(paths), length(GLOB.heretic_paths), "Статический каталог новой книги содержит все пути.")
	for(var/list/path_data as anything in paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_data["id"]]
		TEST_ASSERT(path, "Статический каталог ссылается на существующий путь.")
		TEST_ASSERT_EQUAL(path_data["name"], path.name, "Имя пути соответствует его описанию.")
		var/list/strengths = path_data["strengths"]
		TEST_ASSERT(islist(strengths) && length(strengths) == 1, "Особенности пути передаются интерфейсу непустым списком.")
		TEST_ASSERT_EQUAL(strengths[1], path.strengths, "Список содержит реальные преимущества пути.")

/datum/unit_test/heretic_ascension_body_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/cosmic_final)
	var/brute_before = user.physiology.brute_mod
	var/burn_before = user.physiology.burn_mod
	ADD_TRAIT(user, TRAIT_NOBREATH, "other_source")
	knowledge.finished = TRUE
	knowledge.on_body_gain(user)
	knowledge.on_body_gain(user)
	TEST_ASSERT_EQUAL(user.physiology.heretic_ascension_mod, knowledge.damage_modifier, "Повторная выдача не умножает защиту второй раз.")
	knowledge.on_body_lose(user)
	knowledge.on_body_lose(user)
	TEST_ASSERT_EQUAL(user.physiology.brute_mod, brute_before, "Снятие возвращает исходную защиту от травм.")
	TEST_ASSERT_EQUAL(user.physiology.burn_mod, burn_before, "Снятие возвращает исходную защиту от ожогов.")
	TEST_ASSERT_EQUAL(user.physiology.heretic_ascension_mod, 1, "Снятие убирает отдельную защиту вознесения.")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_NOBREATH), "Чужой источник отсутствия дыхания сохраняется.")
	REMOVE_TRAIT(user, TRAIT_NOBREATH, "other_source")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_NOBREATH), "После снятия чужого источника эффект вознесения не остаётся.")

/// Смена тела переносит знания и HUD, а прямое удаление роли снимает все эффекты.
/datum/unit_test/heretic_role_transfer_and_deletion/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/old_body = heretic.owner.current
	heretic.apply_innate_effects(old_body)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	heretic.research_knowledge(/datum/eldritch_knowledge/base_cosmic, old_body)
	heretic.knowledge_points = 5
	var/datum/eldritch_knowledge/spell/basic/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/obj/effect/proc_holder/spell/old_grasp = grasp.granted_spell
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT(!("heretics" in old_body.faction), "Старое тело теряет принадлежность еретикам.")
	TEST_ASSERT("heretics" in new_body.faction, "Новое тело получает принадлежность еретикам.")
	TEST_ASSERT_EQUAL(heretic.innate_body, new_body, "Эффекты роли отслеживают новое тело.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, 5, "Смена тела сохраняет знания.")
	TEST_ASSERT_EQUAL(heretic.selected_path, PATH_COSMIC, "Смена тела сохраняет выбранный путь.")
	TEST_ASSERT(QDELETED(old_grasp), "Старый экземпляр хватки удаляется при переносе.")
	TEST_ASSERT(!QDELETED(grasp.granted_spell), "Новое тело получает хватку.")
	var/obj/effect/proc_holder/spell/new_grasp = grasp.granted_spell
	qdel(heretic)
	TEST_ASSERT(!("heretics" in new_body.faction), "Прямое удаление роли снимает принадлежность еретикам.")
	TEST_ASSERT(QDELETED(new_grasp), "Прямое удаление роли снимает заклинание.")
	TEST_ASSERT(!IS_HERETIC(new_body), "Удалённой роли нет в разуме нового тела.")

/// Запоздалая смерть старого тела не снимает роль с нового, а очистка использует тело регистрации.
/datum/unit_test/heretic_servant_registration_lifecycle/Run()
	var/datum/antagonist/heretic/fixture = allocate_heretic()
	var/datum/mind/soul = fixture.owner
	var/mob/living/carbon/human/old_body = soul.current
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human)
	var/datum/antagonist/heretic_monster/voiceless_dead/servant = allocate(/datum/antagonist/heretic_monster/voiceless_dead)
	servant.owner = soul
	servant.silent = TRUE
	servant.health_cap = 80
	soul.antag_datums += servant
	var/old_health = old_body.maxHealth
	var/new_health = new_body.maxHealth
	servant.apply_innate_effects(old_body)
	var/previous_generation = servant.body_generation
	soul.transfer_to(new_body, TRUE)
	servant.remove_dead_body_role(previous_generation)
	TEST_ASSERT(!QDELETED(servant), "Запоздалая смерть не снимает уже перенесённую роль.")
	TEST_ASSERT_EQUAL(servant.innate_body, new_body, "Регистрации привязаны к новому телу.")
	TEST_ASSERT_EQUAL(old_body.maxHealth, old_health, "Старое тело восстановило свой предел здоровья.")
	TEST_ASSERT_EQUAL(new_body.maxHealth, servant.health_cap, "Новое тело получило предел здоровья слуги.")
	soul.current = null
	servant.remove_innate_effects()
	soul.current = new_body
	TEST_ASSERT_NULL(servant.innate_body, "Отсутствие owner.current не оставляет тело зарегистрированным.")
	TEST_ASSERT_EQUAL(new_body.maxHealth, new_health, "Очистка восстановила здоровье нужного тела.")
	TEST_ASSERT(!HAS_TRAIT(new_body, TRAIT_MUTE), "Очистка сняла молчание с зарегистрированного тела.")
