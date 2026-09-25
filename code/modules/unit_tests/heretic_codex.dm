/datum/eldritch_knowledge/codex_probe
	name = "Проба кодекса"
	summary = "Лид пробы."
	details = list("Первый факт.", "Второй факт.")
	role = HERETIC_ROLE_CRAFT
	ritual_hints = list("Первая подсказка.", "Вторая подсказка.")
	combat_resource_name = "Проба"
	resource_rules = list("Первое правило.", "Второе правило.")

/datum/eldritch_knowledge/codex_legacy_probe
	name = "Проба прежнего описания"
	desc = "Прежнее описание."
	combat_resource_name = "Прежний запас"
	combat_resource_desc = "Прежнее правило запаса."

/datum/heretic_path/codex_legacy_probe
	name = "Проба прежнего пути"
	desc = "Прежнее описание пути."
	strengths = "Прежние сильные стороны."
	weaknesses = "Прежние слабые стороны."

/datum/unit_test/proc/heretic_codex_roles()
	var/static/list/roles = list(
		HERETIC_ROLE_CRAFT,
		HERETIC_ROLE_CAPTURE,
		HERETIC_ROLE_ESCAPE,
		HERETIC_ROLE_ATTACK,
		HERETIC_ROLE_CONTROL,
		HERETIC_ROLE_DEFENSE,
		HERETIC_ROLE_SUPPORT,
		HERETIC_ROLE_PASSIVE,
		HERETIC_ROLE_RELIC,
		HERETIC_ROLE_MARK,
		HERETIC_ROLE_GRASP,
		HERETIC_ROLE_RITUAL,
		HERETIC_ROLE_ASCENSION,
	)
	return roles

/datum/unit_test/proc/heretic_codex_spells(datum/eldritch_knowledge/knowledge)
	. = list()
	if(knowledge.combat_resource_action)
		. += knowledge.combat_resource_action
	if(istype(knowledge, /datum/eldritch_knowledge/spell))
		var/datum/eldritch_knowledge/spell/spell_knowledge = knowledge
		if(spell_knowledge.spell_to_add)
			. += spell_knowledge.spell_to_add
	if(istype(knowledge, /datum/eldritch_knowledge/final_eldritch))
		var/datum/eldritch_knowledge/final_eldritch/final_knowledge = knowledge
		. += final_knowledge.ascension_spells

/// Каталог книги передаёт лид, факты и роль знаний в допустимой форме, а ритуал не повторяет описание.
/datum/unit_test/heretic_codex_payload/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/reader = heretic.owner.current
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	var/list/static_data = book.ui_static_data(reader)
	var/list/roles = heretic_codex_roles()
	var/list/knowledge_by_id = list()
	for(var/list/entry as anything in static_data["knowledge"])
		knowledge_by_id[entry["id"]] = entry
		TEST_ASSERT(length(entry["desc"]), "У знания [entry["id"]] есть описание для чата и фолбэка.")
		TEST_ASSERT(isnull(entry["role"]) || (entry["role"] in roles), "Роль [entry["id"]] берётся из HERETIC_ROLE_*: [entry["role"]].")
		var/list/details = entry["details"]
		TEST_ASSERT(islist(details), "Факты [entry["id"]] передаются списком.")
		if(!entry["summary"])
			TEST_ASSERT(!length(details), "Факты [entry["id"]] без лида не показываются.")
			continue
		TEST_ASSERT(length_char(entry["summary"]) <= HERETIC_CODEX_SUMMARY_LIMIT, "Лид [entry["id"]] длиннее [HERETIC_CODEX_SUMMARY_LIMIT] символов.")
		TEST_ASSERT(length(details) >= HERETIC_CODEX_DETAILS_MIN && length(details) <= HERETIC_CODEX_DETAILS_MAX, "У [entry["id"]] от [HERETIC_CODEX_DETAILS_MIN] до [HERETIC_CODEX_DETAILS_MAX] фактов, а не [length(details)].")
		for(var/line in details)
			TEST_ASSERT(istext(line) && length(line) && length_char(line) <= HERETIC_CODEX_DETAIL_LIMIT, "Факт [entry["id"]] пуст или длиннее [HERETIC_CODEX_DETAIL_LIMIT] символов: [line]")
		TEST_ASSERT(entry["role"], "У записи [entry["id"]] с лидом есть роль.")
	var/datum/eldritch_knowledge/final_eldritch/final_type = /datum/eldritch_knowledge/final_eldritch
	TEST_ASSERT_EQUAL(initial(final_type.role), HERETIC_ROLE_ASCENSION, "Вознесения наследуют роль от общего предка.")
	for(var/entry_id in knowledge_by_id)
		if(!ispath(text2path(entry_id), final_type))
			continue
		var/list/final_entry = knowledge_by_id[entry_id]
		TEST_ASSERT_EQUAL(final_entry["role"], HERETIC_ROLE_ASCENSION, "Вознесение [entry_id] приходит в каталог с ролью вознесения.")
	for(var/list/recipe as anything in static_data["rituals"])
		var/list/entry = knowledge_by_id[recipe["id"]]
		TEST_ASSERT(islist(recipe["hints"]), "Подсказки ритуала [recipe["id"]] передаются списком.")
		TEST_ASSERT_EQUAL(recipe["desc"], entry["summary"] || entry["desc"], "Ритуал [recipe["id"]] показывает лид, а без лида - прежнее описание.")
	for(var/list/path_data as anything in static_data["paths"])
		var/datum/heretic_path/path = GLOB.heretic_paths[path_data["id"]]
		TEST_ASSERT_EQUAL(path_data["tagline"], path.tagline, "Шапка пути [path.id] приходит из DM.")
		TEST_ASSERT_EQUAL(path_data["craft"], path.craft_summary, "Строка ремесла [path.id] приходит из DM.")
		TEST_ASSERT_EQUAL(path_data["capture"], path.capture_summary, "Строка захвата [path.id] приходит из DM.")
		TEST_ASSERT_EQUAL(path_data["escape"], path.escape_summary, "Строка ухода [path.id] приходит из DM.")
		TEST_ASSERT_EQUAL(path_data["practice"], path.combat_practice, "Совет [path.id] совпадает с упражнением полигона.")
		TEST_ASSERT(islist(path_data["strength_points"]) && islist(path_data["weakness_points"]), "Стороны пути [path.id] передаются списками.")
		TEST_ASSERT_EQUAL(jointext(path_data["strength_points"], "|"), jointext(path.strength_points || list(), "|"), "Сильные стороны [path.id] приходят без изменений.")
		TEST_ASSERT_EQUAL(jointext(path_data["weakness_points"], "|"), jointext(path.weakness_points || list(), "|"), "Слабые стороны [path.id] приходят без изменений.")

/// Описание, подсказка обряда и правила запаса собираются из структурированных полей, прежние тексты не трогаются.
/datum/unit_test/heretic_codex_text_assembly/Run()
	var/datum/eldritch_knowledge/codex_probe/probe = allocate(/datum/eldritch_knowledge/codex_probe)
	TEST_ASSERT_EQUAL(probe.desc, "Лид пробы. Первый факт. Второй факт.", "Описание для чата собирается из лида и фактов.")
	TEST_ASSERT_EQUAL(probe.ritual_hint, "Первая подсказка. Вторая подсказка.", "Подсказка обряда собирается из строк.")
	TEST_ASSERT_EQUAL(probe.combat_resource_desc, "Первое правило. Второе правило.", "Описание запаса для значка собирается из правил.")
	var/list/resource = probe.get_combat_resource_data()
	TEST_ASSERT_EQUAL(jointext(resource["rules"], "|"), "Первое правило.|Второе правило.", "Правила запаса идут списком строк.")
	TEST_ASSERT_EQUAL(resource["state"], "", "Без живых счётчиков состояние пустое.")
	TEST_ASSERT_EQUAL(resource["description"], probe.combat_resource_desc, "Описание без состояния совпадает с правилами.")
	var/datum/eldritch_knowledge/codex_legacy_probe/legacy = allocate(/datum/eldritch_knowledge/codex_legacy_probe)
	TEST_ASSERT_EQUAL(legacy.desc, "Прежнее описание.", "Знание без лида сохраняет своё описание.")
	var/datum/heretic_path/codex_legacy_probe/legacy_path = allocate(/datum/heretic_path/codex_legacy_probe)
	TEST_ASSERT_EQUAL(legacy_path.desc, "Прежнее описание пути.", "Путь без шапки сохраняет прежнее описание.")
	TEST_ASSERT_EQUAL(legacy_path.strengths, "Прежние сильные стороны.", "Путь без списков сохраняет прежний абзац.")
	TEST_ASSERT(!(null in GLOB.heretic_paths), "Путь без id не попадает в каталог путей.")

/// Запас силы отдаёт прежнее описание одной строкой правил, а живые счётчики - отдельной строкой состояния.
/datum/unit_test/heretic_codex_resource/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_glass, user), "Еретик выбирает Стекло.")
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/list/resource = glass.get_combat_resource_data()
	TEST_ASSERT_EQUAL(resource["state"], "Призм: 0 из 3. Настроено стёкол: 0 из [HERETIC_GLASS_ATTUNE_LIMIT].", "Состояние граней отдельной строкой.")
	TEST_ASSERT_EQUAL(resource["description"], "[jointext(resource["rules"], " ")] [resource["state"]]", "Значок получает правила и состояние одним текстом.")
	var/datum/eldritch_knowledge/codex_legacy_probe/legacy = allocate(/datum/eldritch_knowledge/codex_legacy_probe)
	var/list/legacy_resource = legacy.get_combat_resource_data()
	var/list/legacy_rules = legacy_resource["rules"]
	TEST_ASSERT_EQUAL(length(legacy_rules), 1, "Знание без правил по строкам отдаёт прежнее описание одной строкой.")
	TEST_ASSERT_EQUAL(legacy_rules[1], legacy.combat_resource_desc, "Фолбэк правил совпадает с прежним описанием.")
	var/datum/eldritch_knowledge/base_sand/sand = allocate(/datum/eldritch_knowledge/base_sand)
	var/list/sand_resource = sand.get_combat_resource_data()
	TEST_ASSERT_EQUAL(jointext(sand_resource["rules"], "|"), jointext(sand.resource_rules, "|"), "Правила песка идут списком строк.")
	TEST_ASSERT_EQUAL(sand_resource["state"], "Засечек: 0 из [HERETIC_SAND_ANCHOR_LIMIT].", "Счётчик засечек вынесен в состояние.")
	var/datum/eldritch_knowledge/base_ash/ash = allocate(/datum/eldritch_knowledge/base_ash)
	var/list/ash_resource = ash.get_combat_resource_data()
	TEST_ASSERT_EQUAL(ash_resource["state"], "", "Путь без живых счётчиков не выдумывает состояние.")
	TEST_ASSERT_EQUAL(ash_resource["description"], jointext(ash_resource["rules"], " "), "Описание без состояния совпадает с правилами.")
	var/datum/eldritch_knowledge/base_moon/moon = allocate(/datum/eldritch_knowledge/base_moon)
	var/list/moon_resource = moon.get_combat_resource_data()
	TEST_ASSERT_EQUAL(moon_resource["state"], "Двойника на посту нет. Голос двойника выключен.", "Двойник на посту и его голос вынесены в состояние.")
	TEST_ASSERT_EQUAL(jointext(moon_resource["rules"], "|"), jointext(moon.resource_rules, "|"), "Правила отражений идут списком строк.")

/// Стекло отдаёт кодексу лид вместо описания в рецептах, короткие строки способностей и правила граней по строкам.
/datum/unit_test/heretic_codex_glass/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/reader = heretic.owner.current
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	var/list/static_data = book.ui_static_data(reader)
	var/list/rituals_by_id = list()
	for(var/list/recipe as anything in static_data["rituals"])
		rituals_by_id[recipe["id"]] = recipe
	var/datum/eldritch_knowledge/glass_relic/relic = allocate(/datum/eldritch_knowledge/glass_relic)
	var/list/relic_recipe = rituals_by_id["[relic.type]"]
	TEST_ASSERT_EQUAL(relic_recipe["desc"], relic.summary, "Рецепт линзы показывает лид.")
	TEST_ASSERT(relic_recipe["desc"] != relic.desc, "Рецепт линзы не повторяет полное описание знания.")
	var/datum/eldritch_knowledge/glass_mark/mark = allocate(/datum/eldritch_knowledge/glass_mark)
	TEST_ASSERT_EQUAL(mark.desc, "[mark.summary] [jointext(mark.details, " ")]", "Описание Метки Стекла для чата собирается из лида и фактов.")
	var/datum/heretic_path/glass_path = GLOB.heretic_paths[PATH_GLASS]
	TEST_ASSERT_EQUAL(glass_path.desc, glass_path.tagline, "Описание Стекла для полигона берётся из шапки.")
	TEST_ASSERT_EQUAL(glass_path.strengths, jointext(glass_path.strength_points, " "), "Сильные стороны Стекла собираются из списка.")
	TEST_ASSERT_EQUAL(glass_path.weaknesses, jointext(glass_path.weakness_points, " "), "Слабые стороны Стекла собираются из списка.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_glass, reader), "Читатель выбирает Стекло.")
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	TEST_ASSERT(length(glass.resource_rules), "Грани описаны правилами по строкам.")
	var/list/resource = glass.get_combat_resource_data()
	TEST_ASSERT_EQUAL(jointext(resource["rules"], "|"), jointext(glass.resource_rules, "|"), "Правила граней идут списком строк.")
	TEST_ASSERT_EQUAL(glass.combat_resource_desc, jointext(glass.resource_rules, " "), "Описание граней для чата и значка собирается из правил.")
	var/list/data = book.ui_data(reader)
	var/obj/effect/proc_holder/spell/release = /obj/effect/proc_holder/spell/pointed/heretic_glass/release
	var/found_release = FALSE
	for(var/list/ability as anything in data["combat_abilities"])
		if(ability["id"] != "[release]")
			continue
		found_release = TRUE
		TEST_ASSERT(length(ability["summary"]), "Луч Стекла приходит с короткой строкой.")
		TEST_ASSERT_EQUAL(ability["summary"], initial(release.summary), "Строка способности берётся из самого заклинания.")
	TEST_ASSERT(found_release, "Луч Стекла виден в списке способностей.")

/// Лид, факты, роль, собранное описание, подсказки обряда, правила запаса и строки способностей одного знания.
/datum/unit_test/proc/heretic_codex_check_knowledge(datum/eldritch_knowledge/knowledge, list/roles)
	var/knowledge_type = knowledge.type
	TEST_ASSERT(length(knowledge.summary) && length_char(knowledge.summary) <= HERETIC_CODEX_SUMMARY_LIMIT, "Лид [knowledge_type] пуст или длиннее [HERETIC_CODEX_SUMMARY_LIMIT] символов.")
	TEST_ASSERT(islist(knowledge.details) && length(knowledge.details) >= HERETIC_CODEX_DETAILS_MIN && length(knowledge.details) <= HERETIC_CODEX_DETAILS_MAX, "У [knowledge_type] от [HERETIC_CODEX_DETAILS_MIN] до [HERETIC_CODEX_DETAILS_MAX] фактов.")
	for(var/line in knowledge.details)
		TEST_ASSERT(istext(line) && length(line) && length_char(line) <= HERETIC_CODEX_DETAIL_LIMIT, "Факт [knowledge_type] пуст или длиннее [HERETIC_CODEX_DETAIL_LIMIT] символов: [line]")
	TEST_ASSERT(knowledge.role in roles, "У [knowledge_type] роль из HERETIC_ROLE_*.")
	TEST_ASSERT_EQUAL(knowledge.desc, "[knowledge.summary] [jointext(knowledge.details, " ")]", "Описание [knowledge_type] собирается из лида и фактов.")
	for(var/hint in knowledge.ritual_hints)
		TEST_ASSERT(istext(hint) && length(hint) && length_char(hint) <= HERETIC_CODEX_DETAIL_LIMIT, "Подсказка обряда [knowledge_type] пуста или длиннее [HERETIC_CODEX_DETAIL_LIMIT] символов: [hint]")
	if(knowledge.combat_resource_name)
		TEST_ASSERT(length(knowledge.resource_rules), "Запас [knowledge_type] описан правилами по строкам.")
	for(var/obj/effect/proc_holder/spell/spell_type as anything in heretic_codex_spells(knowledge))
		var/spell_summary = initial(spell_type.summary)
		TEST_ASSERT(length(spell_summary) && length_char(spell_summary) <= HERETIC_CODEX_SUMMARY_LIMIT, "У способности [spell_type] короткая строка до [HERETIC_CODEX_SUMMARY_LIMIT] символов.")

/// Все пути каталога заполняют шапку, модель, стороны и тексты всех своих записей.
/datum/unit_test/heretic_codex_structured_paths/Run()
	var/list/roles = heretic_codex_roles()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		TEST_ASSERT(length(path.tagline) && length_char(path.tagline) <= HERETIC_CODEX_TAGLINE_LIMIT, "Шапка [path_id] пуста или длиннее [HERETIC_CODEX_TAGLINE_LIMIT] символов.")
		for(var/line in list(path.craft_summary, path.capture_summary, path.escape_summary))
			TEST_ASSERT(length(line) && length_char(line) <= HERETIC_CODEX_SUMMARY_LIMIT, "Строка модели [path_id] пуста или длиннее [HERETIC_CODEX_SUMMARY_LIMIT] символов: [line]")
		for(var/list/points as anything in list(path.strength_points, path.weakness_points))
			TEST_ASSERT(islist(points) && length(points) >= HERETIC_CODEX_POINTS_MIN && length(points) <= HERETIC_CODEX_POINTS_MAX, "У [path_id] от [HERETIC_CODEX_POINTS_MIN] до [HERETIC_CODEX_POINTS_MAX] сильных и слабых сторон.")
			for(var/point in points)
				TEST_ASSERT(length(point) && length_char(point) <= HERETIC_CODEX_POINT_LIMIT, "Сторона [path_id] длиннее [HERETIC_CODEX_POINT_LIMIT] символов: [point]")
		for(var/knowledge_type in path.knowledge)
			heretic_codex_check_knowledge(allocate(knowledge_type), roles)

/// Стартовые и побочные знания записаны лидом, фактами и ролью, а их описание собирается из этих полей.
/datum/unit_test/heretic_codex_shared_knowledge/Run()
	var/list/roles = heretic_codex_roles()
	for(var/knowledge_type in GLOB.heretic_start_knowledge + GLOB.heretic_side_knowledge)
		heretic_codex_check_knowledge(allocate(knowledge_type), roles)
	var/datum/eldritch_knowledge/final_eldritch/final_type = /datum/eldritch_knowledge/final_eldritch
	var/datum/eldritch_knowledge/final_eldritch/finale = allocate(final_type)
	TEST_ASSERT(length(finale.ritual_hints), "Общая подсказка вознесения идёт списком строк.")
	for(var/hint in finale.ritual_hints)
		TEST_ASSERT(length_char(hint) <= HERETIC_CODEX_DETAIL_LIMIT, "Строка общей подсказки вознесения длиннее [HERETIC_CODEX_DETAIL_LIMIT] символов: [hint]")
	for(var/parent_type in list(/datum/eldritch_knowledge/curse, /datum/eldritch_knowledge/summon))
		var/datum/eldritch_knowledge/parent = allocate(parent_type)
		TEST_ASSERT(length(parent.ritual_hints), "Общая подсказка [parent_type] идёт списком строк.")

/datum/unit_test/proc/heretic_codex_text(knowledge_type)
	var/datum/eldritch_knowledge/knowledge = allocate(knowledge_type)
	return knowledge.desc

/// Числа в текстах Пепла, Ржавчины, Плоти, Пустоты и общих знаний берутся из дефайнов и переменных механик.
/datum/unit_test/heretic_codex_oldpath_numbers/Run()
	var/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash/shift = /obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash
	var/obj/effect/proc_holder/spell/self/heretic_power/ash/ember = /obj/effect/proc_holder/spell/self/heretic_power/ash
	var/obj/effect/proc_holder/spell/pointed/nightwatchers_rite/rite = /obj/effect/proc_holder/spell/pointed/nightwatchers_rite
	var/obj/effect/proc_holder/spell/targeted/fiery_rebirth/rebirth = /obj/effect/proc_holder/spell/targeted/fiery_rebirth
	var/obj/effect/proc_holder/spell/pointed/cleave/cleave = /obj/effect/proc_holder/spell/pointed/cleave
	var/obj/effect/proc_holder/spell/self/heretic_power/rust/root = /obj/effect/proc_holder/spell/self/heretic_power/rust
	var/obj/effect/heretic_combat_zone/rust/hearth = /obj/effect/heretic_combat_zone/rust
	var/obj/effect/proc_holder/spell/aoe_turf/rust_conversion/conversion = /obj/effect/proc_holder/spell/aoe_turf/rust_conversion
	var/obj/effect/proc_holder/spell/targeted/touch/grasp_of_decay/decay = /obj/effect/proc_holder/spell/targeted/touch/grasp_of_decay
	var/datum/status_effect/corrosion_curse/lesser/decay_effect = /datum/status_effect/corrosion_curse/lesser
	var/obj/effect/proc_holder/spell/cone/staggered/entropic_plume/plume = /obj/effect/proc_holder/spell/cone/staggered/entropic_plume
	var/obj/effect/proc_holder/spell/aimed/rust_wave/rust_wave = /obj/effect/proc_holder/spell/aimed/rust_wave
	var/obj/item/projectile/magic/spell/rust_wave/rust_bolt = /obj/item/projectile/magic/spell/rust_wave
	var/obj/effect/proc_holder/spell/self/rust_corrosive_wave/corrosive_wave = /obj/effect/proc_holder/spell/self/rust_corrosive_wave
	var/obj/effect/proc_holder/spell/self/heretic_power/flesh/mend = /obj/effect/proc_holder/spell/self/heretic_power/flesh
	var/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/stitch = /obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch
	var/obj/effect/proc_holder/spell/targeted/touch/mad_touch/madness = /obj/effect/proc_holder/spell/targeted/touch/mad_touch
	var/obj/effect/proc_holder/spell/pointed/blood_siphon/siphon = /obj/effect/proc_holder/spell/pointed/blood_siphon
	var/obj/effect/proc_holder/spell/targeted/shed_human_form/shed = /obj/effect/proc_holder/spell/targeted/shed_human_form
	var/obj/effect/heretic_combat_zone/void/winter = /obj/effect/heretic_combat_zone/void
	var/obj/effect/proc_holder/spell/pointed/void_blink/blink = /obj/effect/proc_holder/spell/pointed/void_blink
	var/obj/effect/proc_holder/spell/targeted/void_pull/pull = /obj/effect/proc_holder/spell/targeted/void_pull
	var/obj/effect/proc_holder/spell/pointed/boogie_woogie/swap = /obj/effect/proc_holder/spell/pointed/boogie_woogie
	var/obj/effect/proc_holder/spell/aoe_turf/domain_expansion/domain = /obj/effect/proc_holder/spell/aoe_turf/domain_expansion
	var/datum/eldritch_knowledge/void_blade_upgrade/seeking = /datum/eldritch_knowledge/void_blade_upgrade
	var/obj/effect/proc_holder/spell/self/heretic_last_waltz/waltz = /obj/effect/proc_holder/spell/self/heretic_last_waltz
	var/datum/eldritch_knowledge/spell/basic/basic = /datum/eldritch_knowledge/spell/basic
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/grasp = /obj/effect/proc_holder/spell/targeted/touch/mansus_grasp
	var/obj/effect/proc_holder/spell/self/heretic_summon/book/book = /obj/effect/proc_holder/spell/self/heretic_summon/book
	var/obj/effect/proc_holder/spell/pointed/trigger/mute/eldritch/silence = /obj/effect/proc_holder/spell/pointed/trigger/mute/eldritch
	var/obj/effect/proc_holder/spell/targeted/genetic/mute/mute = /obj/effect/proc_holder/spell/targeted/genetic/mute
	var/obj/structure/eldritch_crucible/crucible = /obj/structure/eldritch_crucible
	var/obj/item/melee/rune_knife/carver = /obj/item/melee/rune_knife
	var/datum/eldritch_knowledge/curse/corrosion/corrosion = /datum/eldritch_knowledge/curse/corrosion
	var/datum/eldritch_knowledge/curse/paralysis/paralysis = /datum/eldritch_knowledge/curse/paralysis
	var/datum/eldritch_knowledge/summon/summon = /datum/eldritch_knowledge/summon
	var/datum/heretic_path/ash_path = GLOB.heretic_paths[PATH_ASH]
	var/datum/heretic_path/rust_path = GLOB.heretic_paths[PATH_RUST]
	var/datum/heretic_path/flesh_path = GLOB.heretic_paths[PATH_FLESH]
	var/datum/heretic_path/void_path = GLOB.heretic_paths[PATH_VOID]
	var/shift_time = replacetext("[initial(shift.jaunt_duration) / (1 SECONDS)]", ".", ",")
	var/list/facts = list(
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/ashen_shift), "[shift_time] секунды свободно", "Перезарядка [initial(shift.charge_max) / (1 SECONDS)] секунд"),
		list(ash_path.escape_summary, "на [shift_time] секунды"),
		list(heretic_codex_text(/datum/eldritch_knowledge/base_ash), "Перезарядка Угасания [initial(ember.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/nightwatchers_rite), "на [initial(rite.range)] клеток", "Перезарядка [initial(rite.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/flame_birth), "Перезарядка [initial(rebirth.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/cleave), "в [initial(cleave.range)] клетках", "Перезарядка [initial(cleave.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/final_eldritch/ash_final), "по [HERETIC_ASH_LORD_HEAL] ожога", "горит [HERETIC_ASH_TRAIL_DURATION / (1 SECONDS)] секунды", "на [HERETIC_ASH_CASCADE_RANGE] клеток", "перезарядка [HERETIC_ASH_FIRE_SWORN_COOLDOWN / (1 MINUTES)] минуты", "на [HERETIC_ASH_WET_DURATION / (1 SECONDS)] секунд"),
		list(jointext(ash_path.weakness_points, " "), "[HERETIC_ASH_WET_DURATION / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/base_rust), "очаг на [initial(hearth.duration) / (1 SECONDS)] секунд", "Перезарядка [initial(root.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/area_conversion), "к [initial(conversion.range)] клеткам", "Перезарядка [initial(conversion.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/grasp_of_decay), "Распад [initial(decay_effect.duration) / (1 SECONDS)] секунд", "Перезарядка [initial(decay.charge_max) / (1 MINUTES)] минуты"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/entropic_plume), "Перезарядка [initial(plume.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/rust_wave), "на [initial(rust_bolt.range)] клеток", "на [initial(rust_bolt.damage)] отравления", "Перезарядка [initial(rust_wave.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/final_eldritch/rust_final), "на [HERETIC_RUST_HEART_INTEGRITY] прочности", "[HERETIC_RUST_WAVE_CORROSION] коррозии врагам в [HERETIC_RUST_WAVE_RANGE] клетках", "раз в [HERETIC_RUST_WAVE_COOLDOWN / (1 SECONDS)] секунд"),
		list(initial(corrosive_wave.desc), "[HERETIC_RUST_WAVE_CORROSION] урона коррозией", "перезарядка [HERETIC_RUST_WAVE_COOLDOWN / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/base_flesh), "Перезарядка [initial(mend.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/flesh_grasp), "роль [HERETIC_SERVANT_POLL_DURATION / (1 SECONDS)] секунд", "Живой шов на [initial(stitch.range)] клеток", "Перезарядка [initial(stitch.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/touch_of_madness), "Перезарядка [initial(madness.charge_max) / (1 MINUTES)] минуты"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/blood_siphon), "в [initial(siphon.range)] клетках", "Перезарядка [initial(siphon.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/final_eldritch/flesh_final), "перезарядка [initial(shed.charge_max) / (1 SECONDS)] секунд", "за [HERETIC_FLESH_WORM_FEED_TIME / (1 SECONDS)] секунды", "+[HERETIC_FLESH_WORM_FEED_HEAL] здоровья", "до [HERETIC_FLESH_WORM_MAX_LENGTH] сегментов", "через [HERETIC_FLESH_WORM_DEATH_COOLDOWN / (1 MINUTES)] минуты"),
		list(jointext(flesh_path.strength_points, " "), "до [HERETIC_FLESH_WORM_MAX_LENGTH] сегментов"),
		list(heretic_codex_text(/datum/eldritch_knowledge/base_void), "на [initial(winter.duration) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/void_phase), "в 3-[initial(blink.range)] клетках", "Перезарядка [initial(blink.charge_max) / (1 SECONDS)] секунд"),
		list(void_path.escape_summary, "на 3-[initial(blink.range)] клеток"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/voidpull), "Перезарядка [initial(pull.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/boogiewoogie), "в [initial(swap.range)] клетках", "Перезарядка [initial(swap.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/domain_expansion), "[HERETIC_VOID_DOMAIN_BLINK_COOLDOWN / (1 SECONDS)] секунды вместо [HERETIC_VOID_BLINK_COOLDOWN / (1 SECONDS)]", "Перезарядка [initial(domain.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(seeking), "холодом на [initial(seeking.blade_damage)]", "восстанавливается [HERETIC_VOID_BLINK_COOLDOWN / (1 SECONDS)] секунд", "пустоте - [HERETIC_VOID_DOMAIN_BLINK_COOLDOWN / (1 SECONDS)] секунды"),
		list(heretic_codex_text(/datum/eldritch_knowledge/final_eldritch/void_final), "веером [HERETIC_VOID_DEFLECT_CHANCE]% снарядов", "на [HERETIC_VOID_HEAT_MARGIN] градусов выше нормы", "такт: [initial(waltz.burst_damage)] холодовых ожогов", "перезарядка [initial(waltz.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(basic), "обряд длится [initial(basic.ritual_time) / (1 SECONDS)] секунд", "даёт [HERETIC_LIVE_SACRIFICE_KNOWLEDGE] очка знаний и [HERETIC_LIVE_SACRIFICE_SIDE_KNOWLEDGE] побочное", "перезарядка [initial(grasp.charge_max) / (1 SECONDS)] секунд"),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/summon/book), "после [initial(book.recovery_time) / (1 SECONDS)] секунд неподвижности", "после [initial(book.container_recovery_time) / (1 SECONDS)] секунд;"),
		list(heretic_codex_text(/datum/eldritch_knowledge/codex_cicatrix), "за [initial(book.recovery_time) / (1 SECONDS)] секунд", "за [initial(book.container_recovery_time) / (1 SECONDS)] секунд."),
		list(initial(book.desc), "после [initial(book.recovery_time) / (1 SECONDS)] секунд неподвижности", "после [initial(book.container_recovery_time) / (1 SECONDS)] секунд."),
		list(heretic_codex_text(/datum/eldritch_knowledge/spell/silence), "[initial(mute.duration) / (1 SECONDS)] секунд она не может", "Перезарядка [initial(silence.charge_max) / (1 MINUTES)] минуты"),
		list(heretic_codex_text(/datum/eldritch_knowledge/crucible), "раз в [initial(crucible.refill_time) / (1 SECONDS)] секунд", "из [initial(crucible.max_mass)] долей"),
		list(heretic_codex_text(/datum/eldritch_knowledge/rune_carver), "до [initial(carver.max_rune_amt)] рун"),
		list(heretic_codex_text(corrosion), "[initial(corrosion.timer) / (1 MINUTES)] минуты рвоты"),
		list(heretic_codex_text(paralysis), "[initial(paralysis.timer) / (1 MINUTES)] минут он не может"),
		list(heretic_codex_text(/datum/eldritch_knowledge/summon/stalker), "держится до [initial(summon.summon_limit)]"),
	)
	for(var/list/fact_line as anything in facts)
		var/fact_text = fact_line[1]
		for(var/index in 2 to length(fact_line))
			TEST_ASSERT(findtext(fact_text, fact_line[index]), "Текст называет «[fact_line[index]]»: [fact_text]")
	TEST_ASSERT_EQUAL(HERETIC_RUST_ASCENDED_STAMINA_MOD, 0.5, "Клятва Посланника обещает вдвое меньше урона выносливости.")
	for(var/datum/heretic_path/path as anything in list(ash_path, rust_path, flesh_path, void_path))
		TEST_ASSERT(findtext(path.capture_summary, "в изнанку"), "Строка захвата [path.id] называет свою дверь в изнанку.")

/// Метки, запасы, улучшения, слуги, реликвии и финалы старых путей называют числа из кода, а Коррозийный вал - свои ограничения.
/datum/unit_test/heretic_codex_oldpath_details/Run()
	var/datum/status_effect/eldritch/mark = /datum/status_effect/eldritch
	var/datum/eldritch_knowledge/base_ash/resource_owner = /datum/eldritch_knowledge/base_ash
	var/obj/effect/heretic_combat_zone/ash/ember_zone = /obj/effect/heretic_combat_zone/ash
	var/obj/effect/heretic_combat_zone/rust/rooted/rooted = /obj/effect/heretic_combat_zone/rust/rooted
	var/obj/item/heretic_relic/censer/censer = /obj/item/heretic_relic/censer
	var/obj/effect/proc_holder/spell/targeted/fire_sworn/fire_sworn = /obj/effect/proc_holder/spell/targeted/fire_sworn
	var/obj/effect/proc_holder/spell/self/rust_corrosive_wave/corrosive_wave = /obj/effect/proc_holder/spell/self/rust_corrosive_wave
	var/obj/item/projectile/magic/spell/rust_wave/short/short_bolt = /obj/item/projectile/magic/spell/rust_wave/short
	for(var/mark_type in list(/datum/eldritch_knowledge/ash_mark, /datum/eldritch_knowledge/rust_mark, /datum/eldritch_knowledge/flesh_mark, /datum/eldritch_knowledge/void_mark))
		TEST_ASSERT(findtext(heretic_codex_text(mark_type), "метку на [initial(mark.duration) / (1 SECONDS)] секунд"), "[mark_type] называет срок метки.")
	for(var/base_type in list(/datum/eldritch_knowledge/base_ash, /datum/eldritch_knowledge/base_rust, /datum/eldritch_knowledge/base_flesh, /datum/eldritch_knowledge/base_void))
		var/datum/eldritch_knowledge/base = allocate(base_type)
		TEST_ASSERT(findtext(base.combat_resource_desc, "Запас до [initial(resource_owner.combat_resource_max)] "), "[base_type] называет предел запаса.")
	for(var/ascension_type in list(/datum/eldritch_knowledge/final_eldritch/ash_final, /datum/eldritch_knowledge/final_eldritch/rust_final, /datum/eldritch_knowledge/final_eldritch/flesh_final, /datum/eldritch_knowledge/final_eldritch/void_final))
		TEST_ASSERT(findtext(heretic_codex_text(ascension_type), "Нужны [HERETIC_ASCENSION_SACRIFICES] назначенные души и [HERETIC_ASCENSION_BODIES] человеческих трупа"), "[ascension_type] называет цену вознесения.")
	var/datum/eldritch_knowledge/ash_blade_upgrade/ash_blade = allocate(/datum/eldritch_knowledge/ash_blade_upgrade)
	var/list/ash_values = ash_blade.passive_values
	TEST_ASSERT(findtext(ash_blade.desc, "[2 * ash_values[1]] / [2 * ash_values[2]] / [2 * ash_values[3]] ожогов и [ash_values[1]] / [ash_values[2]] / [ash_values[3]] заряда"), "Огненный клинок называет уровни.")
	var/datum/eldritch_knowledge/flesh_blade_upgrade/flesh_blade = allocate(/datum/eldritch_knowledge/flesh_blade_upgrade)
	var/list/flesh_values = flesh_blade.passive_values
	TEST_ASSERT(findtext(flesh_blade.desc, "[flesh_values[1]] / [flesh_values[2]] / [flesh_values[3]] ушиба"), "Иссекающая сталь называет уровни.")
	var/datum/eldritch_knowledge/void_grasp/void_grasp = allocate(/datum/eldritch_knowledge/void_grasp)
	var/list/void_values = void_grasp.passive_values
	TEST_ASSERT(findtext(void_grasp.desc, "[void_values[1]] / [void_values[2]] / [void_values[3]] градусов"), "Хватка Пустоты называет уровни охлаждения.")
	var/datum/eldritch_knowledge/rust_regen/rust_regen = allocate(/datum/eldritch_knowledge/rust_regen)
	var/list/rust_values = rust_regen.passive_values
	TEST_ASSERT(findtext(rust_regen.desc, "до [rust_values[2] * 100] и [rust_values[3] * 100]%"), "Ржавая поступь называет уровни лечения.")
	TEST_ASSERT(findtext(heretic_codex_text(/datum/eldritch_knowledge/flame_immunity), "до [initial(censer.max_fire)] зарядов"), "Кадильница называет запас пламени.")
	TEST_ASSERT(findtext(heretic_codex_text(/datum/eldritch_knowledge/base_ash), "огонь на [initial(ember_zone.duration) / (1 SECONDS)] секунд"), "Угасание называет срок огня.")
	TEST_ASSERT(findtext(heretic_codex_text(/datum/eldritch_knowledge/spell/area_conversion), "очаг 5×5 на [initial(rooted.duration) / (1 SECONDS)] секунд"), "Семя называет срок очага.")
	TEST_ASSERT(findtext(heretic_codex_text(/datum/eldritch_knowledge/final_eldritch/ash_final), "Клятва огня: [initial(fire_sworn.duration) / (1 SECONDS)] секунд"), "Клятва огня называет срок кольца.")
	var/list/summons = list(
		/datum/eldritch_knowledge/summon/raw_prophet = /mob/living/simple_animal/hostile/eldritch/raw_prophet,
		/datum/eldritch_knowledge/summon/stalker = /mob/living/simple_animal/hostile/eldritch/stalker,
		/datum/eldritch_knowledge/summon/ashy = /mob/living/simple_animal/hostile/eldritch/ash_spirit,
		/datum/eldritch_knowledge/summon/rusty = /mob/living/simple_animal/hostile/eldritch/rust_spirit,
	)
	for(var/summon_type in summons)
		var/mob/living/simple_animal/servant = summons[summon_type]
		var/summon_text = heretic_codex_text(summon_type)
		TEST_ASSERT(findtext(summon_text, "на [initial(servant.maxHealth)] здоровья"), "[summon_type] называет здоровье слуги.")
		if(summon_type != /datum/eldritch_knowledge/summon/raw_prophet)
			TEST_ASSERT(findtext(summon_text, "бьёт на [initial(servant.melee_damage_lower)]-[initial(servant.melee_damage_upper)]"), "[summon_type] называет удар слуги.")
	TEST_ASSERT(findtext(heretic_codex_text(/datum/eldritch_knowledge/summon/rusty), "на [initial(short_bolt.range)] клеток"), "Ржавый ходок называет дальность заряда.")
	var/wave_text = "[initial(corrosive_wave.desc)] [heretic_codex_text(/datum/eldritch_knowledge/final_eldritch/rust_final)]"
	for(var/limit in list("наружные", "корпус шаттла", "укреплённые только", "двери", "не оглушает"))
		TEST_ASSERT(findtext(wave_text, limit), "Коррозийный вал называет ограничение «[limit]».")
	TEST_ASSERT(!findtext("[initial(corrosive_wave.summary)] [wave_text]", "обычные стены рушатся"), "Вал не обещает рушить любые обычные стены.")

/datum/unit_test/proc/heretic_codex_seconds(time)
	return replacetext("[time / (1 SECONDS)]", ".", ",")

/datum/unit_test/proc/heretic_codex_spell_text(spell_type)
	var/obj/effect/proc_holder/spell/spell = spell_type
	return "[initial(spell.desc)] [initial(spell.summary)]"

/// Числа в текстах, которые менял аудит Стекла, Песка, Пучины, Эха и Крови, берутся из дефайнов механик.
/datum/unit_test/heretic_codex_audit_numbers/Run()
	var/glass = heretic_codex_text(/datum/eldritch_knowledge/base_glass)
	TEST_ASSERT(findtext(glass, "[heretic_codex_seconds(HERETIC_GLASS_THEFT_TIME)] с, раз в [heretic_codex_seconds(HERETIC_GLASS_THEFT_COOLDOWN)] с"), "Кража сквозь стекло называет свои числа.")
	var/haste = heretic_codex_text(/datum/eldritch_knowledge/sand_haste)
	TEST_ASSERT(findtext(haste, "не дальше [HERETIC_SAND_HASTE_RANGE] клеток") && findtext(haste, "вход в [HERETIC_SAND_HASTE_RANGE] клетках"), "Течение часа называет радиус засечки и в изнанке.")
	var/datum/eldritch_knowledge/base_tide/tide = allocate(/datum/eldritch_knowledge/base_tide)
	TEST_ASSERT(findtext(tide.desc, "Уйти в слив доступен сразу: [HERETIC_TIDE_DIVE_COST] давления, перезарядка [heretic_codex_seconds(HERETIC_TIDE_DIVE_COOLDOWN)] секунд"), "Ранний уход в слив называет цену и перезарядку.")
	TEST_ASSERT(findtext(tide.combat_resource_desc, "Уйти в слив - [HERETIC_TIDE_DIVE_COST], с Течением [HERETIC_TIDE_DIVE_FLOW_COST]"), "Правила давления называют обе цены ухода.")
	var/current = heretic_codex_text(/datum/eldritch_knowledge/spell/tide_current)
	TEST_ASSERT(findtext(current, "стоит [HERETIC_TIDE_DIVE_FLOW_COST] давление и перезаряжается [heretic_codex_seconds(HERETIC_TIDE_DIVE_FLOW_COOLDOWN)] секунд вместо [heretic_codex_seconds(HERETIC_TIDE_DIVE_COOLDOWN)]"), "Течение называет новую цену ухода.")
	var/dive = heretic_codex_spell_text(/obj/effect/proc_holder/spell/self/heretic_tide/dive)
	TEST_ASSERT(findtext(dive, "Стоит [HERETIC_TIDE_DIVE_COST] давления, перезарядка [heretic_codex_seconds(HERETIC_TIDE_DIVE_COOLDOWN)] секунд") && findtext(dive, "[HERETIC_TIDE_DIVE_FLOW_COST] давление и [heretic_codex_seconds(HERETIC_TIDE_DIVE_FLOW_COOLDOWN)] секунд"), "Способность ухода называет обе цены и перезарядки.")
	var/drown = heretic_codex_text(/datum/eldritch_knowledge/spell/tide_drown)
	TEST_ASSERT(findtext(drown, "[heretic_codex_seconds(HERETIC_TIDE_DROWN_DURATION)] секунд захлёбывается") && findtext(drown, "сознание на [heretic_codex_seconds(HERETIC_TIDE_DROWN_SLEEP)] секунд"), "Захлёб называет срок и беспамятство.")
	var/drown_oxy = HERETIC_TIDE_DROWN_OXY_PER_TICK * HERETIC_TIDE_DROWN_DURATION / (1 SECONDS)
	TEST_ASSERT(findtext(drown, "[HERETIC_TIDE_DROWN_OXY_PER_TICK] удушья в секунду, за захлёб до [drown_oxy], выше [HERETIC_TIDE_DROWN_OXY_CAP] не поднимает"), "Захлёб называет настоящий предел удушья: до [drown_oxy].")
	TEST_ASSERT(findtext(heretic_codex_spell_text(/obj/effect/proc_holder/spell/pointed/heretic_tide/drown), "за захлёб до [drown_oxy]"), "Способность захлёба называет тот же предел.")
	var/lullaby = heretic_codex_text(/datum/eldritch_knowledge/spell/echo_lullaby)
	TEST_ASSERT(findtext(lullaby, "шаг на [HERETIC_ECHO_LULLABY_SLOWDOWN * 100]% медленнее"), "Колыбельная называет замедление напева.")
	var/ether = heretic_codex_text(/datum/eldritch_knowledge/spell/echo_ether)
	TEST_ASSERT(findtext(ether, "Через [heretic_codex_seconds(HERETIC_ECHO_ETHER_TIME)] секунды") && findtext(ether, "перезарядка [heretic_codex_seconds(HERETIC_ECHO_ETHER_COOLDOWN)] секунд") && findtext(ether, "4 секунды почти невидимы"), "Уйти в эфир называет канал, перезарядку и срок Тишины.")
	TEST_ASSERT_EQUAL(HERETIC_ECHO_ETHER_COST, 1, "Текст говорит о единице резонанса.")
	TEST_ASSERT_EQUAL(HERETIC_ECHO_HUSH_DURATION, 4 SECONDS, "Текст говорит о 4 секундах Тишины.")
	var/drain = heretic_codex_text(/datum/eldritch_knowledge/spell/blood_drain)
	TEST_ASSERT(findtext(drain, "долгом от [HERETIC_BLOOD_DRAIN_DEBT]") && findtext(drain, "[heretic_codex_seconds(HERETIC_BLOOD_DRAIN_DURATION)] секунд: до 15% крови") && findtext(drain, "обморок на [heretic_codex_seconds(HERETIC_BLOOD_DRAIN_FAINT)] секунд"), "Кровопускание называет долг, канал и обморок.")
	TEST_ASSERT(findtext(drain, "Со [heretic_codex_seconds(HERETIC_BLOOD_DRAIN_DOOR_DELAY)]-й секунды") && findtext(drain, "если вы в [HERETIC_BLOOD_DRAIN_DOOR_RANGE] клетках"), "Дверь Крови называет секунду и дальность.")
	var/datum/eldritch_knowledge/base_blood/blood = allocate(/datum/eldritch_knowledge/base_blood)
	TEST_ASSERT(findtext(blood.desc, "пустая печать помнит это [heretic_codex_seconds(HERETIC_BLOOD_SPENT_LIFETIME)] секунд") && findtext(blood.combat_resource_desc, "пустая печать [heretic_codex_seconds(HERETIC_BLOOD_SPENT_LIFETIME)] секунд"), "Пустая печать называет свой срок.")
	TEST_ASSERT_EQUAL(HERETIC_BLOOD_CLOT_MULTIPLIER, 0.5, "Текст говорит, что кровотечение вдвое слабее.")
	TEST_ASSERT(findtext(blood.desc, "кровотечение [heretic_codex_seconds(HERETIC_BLOOD_CLOT_DURATION)] секунд вдвое слабее") && findtext(blood.combat_resource_desc, "на [heretic_codex_seconds(HERETIC_BLOOD_CLOT_DURATION)] секунд вдвое ослабляет"), "Взыскание называет срок ослабления кровотечения.")
	TEST_ASSERT(findtext(blood.desc, "связь рвётся через [heretic_codex_seconds(HERETIC_BLOOD_CONTACT_GRACE)] секунды") && findtext(blood.combat_resource_desc, "если [heretic_codex_seconds(HERETIC_BLOOD_CONTACT_GRACE)] секунды нет контакта"), "Связь называет срок без контакта.")
	TEST_ASSERT(findtext(blood.desc, "раз в [heretic_codex_seconds(HERETIC_BLOOD_TRAP_COOLDOWN)] секунд, если вы в [HERETIC_BLOOD_RANGE] клетках и связь свободна"), "Метка называет условие срабатывания.")
	TEST_ASSERT(findtext(blood.desc, "след раз в [heretic_codex_seconds(HERETIC_BLOOD_TRAIL_INTERVAL)] секунды"), "След называет частоту обновления.")
