GLOBAL_LIST_INIT(heretic_start_knowledge, list(
	/datum/eldritch_knowledge/spell/basic,
	/datum/eldritch_knowledge/spell/summon/heart,
	/datum/eldritch_knowledge/spell/summon/book,
	/datum/eldritch_knowledge/living_heart,
	/datum/eldritch_knowledge/codex_cicatrix,
))
GLOBAL_LIST_INIT(heretic_paths, init_heretic_paths())
GLOBAL_VAR_INIT(heretic_threat_warning_until, 0)
GLOBAL_LIST_INIT(heretic_side_knowledge, list(
	/datum/eldritch_knowledge/spell/silence = 1,
	/datum/eldritch_knowledge/armor = 2,
	/datum/eldritch_knowledge/ashen_eyes = 2,
	/datum/eldritch_knowledge/essence = 3,
	/datum/eldritch_knowledge/void_cloak = 3,
	/datum/eldritch_knowledge/spell/rust_wave = 4,
	/datum/eldritch_knowledge/rune_carver = 4,
	/datum/eldritch_knowledge/curse/corrosion = 5,
	/datum/eldritch_knowledge/curse/paralysis = 5,
	/datum/eldritch_knowledge/spell/blood_siphon = 6,
	/datum/eldritch_knowledge/crucible = 6,
	/datum/eldritch_knowledge/summon/ashy = 7,
	/datum/eldritch_knowledge/summon/rusty = 7,
	/datum/eldritch_knowledge/spell/cleave = 8,
))

/proc/init_heretic_paths()
	var/list/paths = list()
	for(var/path_type in subtypesof(/datum/heretic_path))
		var/datum/heretic_path/path = new path_type
		paths[path.id] = path
	return paths

/datum/heretic_path
	var/id
	var/name
	var/desc
	var/strengths
	var/weaknesses
	var/list/knowledge = list()

/datum/heretic_path/ash
	id = PATH_ASH
	deed_type = /datum/heretic_deed/ash
	name = "Пепел"
	desc = "Сжигайте метки, копите угольки и разрывайте дистанцию огненным сбросом."
	strengths = "Мобильность, цепные поджоги, восстановление в бою."
	weaknesses = "Нужна близкая дистанция; огнетушитель лишает вас части давления."
	knowledge = list(
		/datum/eldritch_knowledge/base_ash,
		/datum/eldritch_knowledge/ashen_grasp,
		/datum/eldritch_knowledge/spell/ashen_shift,
		/datum/eldritch_knowledge/ash_mark,
		/datum/eldritch_knowledge/mad_mask,
		/datum/eldritch_knowledge/ash_blade_upgrade,
		/datum/eldritch_knowledge/spell/flame_birth,
		/datum/eldritch_knowledge/flame_immunity,
		/datum/eldritch_knowledge/spell/nightwatchers_rite,
		/datum/eldritch_knowledge/final_eldritch/ash_final,
	)

/datum/heretic_path/rust
	id = PATH_RUST
	deed_type = /datum/heretic_deed/rust
	name = "Ржавчина"
	desc = "Выращивайте наросты и превращайте выбранное помещение в свою территорию."
	strengths = "Подготовленные позиции, разрушение укреплений и лечение на ржавчине."
	weaknesses = "За пределами подготовленной территории вы заметно слабее."
	knowledge = list(
		/datum/eldritch_knowledge/base_rust,
		/datum/eldritch_knowledge/rust_fist,
		/datum/eldritch_knowledge/rust_regen,
		/datum/eldritch_knowledge/rust_mark,
		/datum/eldritch_knowledge/spell/area_conversion,
		/datum/eldritch_knowledge/rust_blade_upgrade,
		/datum/eldritch_knowledge/spell/entropic_plume,
		/datum/eldritch_knowledge/rust_fist_upgrade,
		/datum/eldritch_knowledge/spell/grasp_of_decay,
		/datum/eldritch_knowledge/final_eldritch/rust_final,
	)

/datum/heretic_path/flesh
	id = PATH_FLESH
	deed_type = /datum/heretic_deed/flesh
	name = "Плоть"
	desc = "Собирайте биомассу и сшивайте раны своей свиты прямо в сражении."
	strengths = "Слуги, разведка, истощение противника и лечение группы."
	weaknesses = "Призывы требуют добровольцев; потерянную свиту нужно восстанавливать."
	knowledge = list(
		/datum/eldritch_knowledge/base_flesh,
		/datum/eldritch_knowledge/flesh_grasp,
		/datum/eldritch_knowledge/flesh_ghoul,
		/datum/eldritch_knowledge/flesh_mark,
		/datum/eldritch_knowledge/summon/raw_prophet,
		/datum/eldritch_knowledge/flesh_blade_upgrade,
		/datum/eldritch_knowledge/summon/stalker,
		/datum/eldritch_knowledge/flesh_blade_upgrade_2,
		/datum/eldritch_knowledge/spell/touch_of_madness,
		/datum/eldritch_knowledge/final_eldritch/flesh_final,
	)

/datum/heretic_path/void
	id = PATH_VOID
	deed_type = /datum/heretic_deed/void
	name = "Пустота"
	desc = "Расставляйте очаги зимы, лишайте врагов голоса и выбирайте место схватки."
	strengths = "Контроль пространства, замедление, молчание и перемещение."
	weaknesses = "Зоны неподвижны, а контроль требует времени и близости врага."
	knowledge = list(
		/datum/eldritch_knowledge/base_void,
		/datum/eldritch_knowledge/void_grasp,
		/datum/eldritch_knowledge/cold_snap,
		/datum/eldritch_knowledge/void_mark,
		/datum/eldritch_knowledge/spell/void_phase,
		/datum/eldritch_knowledge/void_blade_upgrade,
		/datum/eldritch_knowledge/spell/voidpull,
		/datum/eldritch_knowledge/spell/boogiewoogie,
		/datum/eldritch_knowledge/spell/domain_expansion,
		/datum/eldritch_knowledge/final_eldritch/void_final,
	)

/datum/heretic_path/blade
	id = PATH_BLADE
	deed_type = /datum/heretic_deed/blade
	name = "Клинок"
	desc = "Сближайтесь выпадом, отбивайте клинком удары и снаряды, отвечайте тяжёлой контратакой."
	strengths = "Короткая защита от огнестрела, сильный ответ и пополнение Темпа обычными ударами."
	weaknesses = "Для парирования нужна пустая вторая рука; очередь пробивает защиту между блоками."
	knowledge = list(
		/datum/eldritch_knowledge/base_blade,
		/datum/eldritch_knowledge/blade_grasp,
		/datum/eldritch_knowledge/spell/blade_lunge,
		/datum/eldritch_knowledge/blade_mark,
		/datum/eldritch_knowledge/blade_guard,
		/datum/eldritch_knowledge/blade_upgrade,
		/datum/eldritch_knowledge/spell/blade_recall,
		/datum/eldritch_knowledge/blade_riposte,
		/datum/eldritch_knowledge/spell/blade_dance,
		/datum/eldritch_knowledge/final_eldritch/blade_final,
	)

/datum/heretic_path/moon
	id = PATH_MOON
	deed_type = /datum/heretic_deed/moon
	name = "Луна"
	desc = "Изматывайте врагов двойниками, прикрывайтесь ими от выстрелов и меняйтесь с ними местами."
	strengths = "Давление на выносливость, перехват снарядов и быстрый обмен местами."
	weaknesses = "Двойники хрупки; их атаки не наносят ранений, а обмен требует видимости и свободного пола."
	knowledge = list(
		/datum/eldritch_knowledge/base_moon,
		/datum/eldritch_knowledge/moon_grasp,
		/datum/eldritch_knowledge/spell/moon_exchange,
		/datum/eldritch_knowledge/moon_mark,
		/datum/eldritch_knowledge/moon_shroud,
		/datum/eldritch_knowledge/moon_upgrade,
		/datum/eldritch_knowledge/spell/moon_mirage,
		/datum/eldritch_knowledge/moon_refraction,
		/datum/eldritch_knowledge/spell/moon_eclipse,
		/datum/eldritch_knowledge/final_eldritch/moon_final,
	)

/datum/heretic_path/cosmic
	id = PATH_COSMIC
	deed_type = /datum/heretic_deed/cosmic
	name = "Космос"
	desc = "Ставьте пару звёзд прямо в бою, пересекайте созвездие и схлопывайте его на врагах."
	strengths = "Быстрая расстановка ловушек, перемещение между звёздами и взрыв по площади."
	weaknesses = "Звёзды видны и разрушаются; на неподготовленной позиции мало возможностей."
	knowledge = list(
		/datum/eldritch_knowledge/base_cosmic,
		/datum/eldritch_knowledge/cosmic_grasp,
		/datum/eldritch_knowledge/spell/cosmic_step,
		/datum/eldritch_knowledge/cosmic_mark,
		/datum/eldritch_knowledge/cosmic_expansion,
		/datum/eldritch_knowledge/cosmic_upgrade,
		/datum/eldritch_knowledge/spell/cosmic_pulse,
		/datum/eldritch_knowledge/cosmic_resonance,
		/datum/eldritch_knowledge/spell/cosmic_collapse,
		/datum/eldritch_knowledge/final_eldritch/cosmic_final,
	)

/datum/antagonist/heretic/proc/research_error(knowledge_type)
	if(role_removed || !ispath(knowledge_type, /datum/eldritch_knowledge))
		return "Это знание недоступно."
	if(researched_knowledge[knowledge_type])
		return "Знание уже изучено."
	var/datum/heretic_path/path = GLOB.heretic_paths[selected_path]
	if(!path)
		var/is_start = FALSE
		for(var/path_id in GLOB.heretic_paths)
			var/datum/heretic_path/candidate = GLOB.heretic_paths[path_id]
			if(candidate.knowledge[1] == knowledge_type)
				is_start = TRUE
				break
		if(!is_start)
			return "Сначала выберите путь."
	else if(knowledge_type in GLOB.heretic_side_knowledge)
		if(path_stage < GLOB.heretic_side_knowledge[knowledge_type])
			return "Продвиньтесь дальше по своему пути."
	else if(path_stage >= length(path.knowledge) || path.knowledge[path_stage + 1] != knowledge_type)
		return "Сначала изучите предыдущую ступень выбранного пути."
	var/datum/eldritch_knowledge/knowledge = knowledge_type
	if(total_sacrifices < initial(knowledge.sacs_needed))
		return "Не хватает назначенных душ: нужно [initial(knowledge.sacs_needed)]."
	var/available_points = knowledge_points
	if(knowledge_type in GLOB.heretic_side_knowledge)
		available_points += side_knowledge_points
	if(available_points < initial(knowledge.cost))
		return "Не хватает знаний: нужно [initial(knowledge.cost)]."
	return null

/datum/antagonist/heretic
	var/ascension_notice_sent = FALSE
	var/ascension_ready_at = 0

/datum/antagonist/heretic/proc/announce_threat()
	if(ascension_notice_sent)
		return FALSE
	ascension_notice_sent = TRUE
	if(world.time < GLOB.heretic_threat_warning_until)
		ascension_ready_at = GLOB.heretic_threat_warning_until
		return FALSE
	GLOB.heretic_threat_warning_until = world.time + HERETIC_THREAT_WARNING_TIME
	ascension_ready_at = GLOB.heretic_threat_warning_until
	priority_announce("Зафиксировано усиление оккультной активности. Последователи запретных путей готовят заключительный обряд. До возможного разрыва завесы остаётся не менее трёх минут. Сообщайте службе безопасности о ритуальных знаках и необъяснимых исчезновениях экипажа.", "Предупреждение об оккультной активности", 'sound/misc/notice1.ogg')
	return TRUE

/datum/antagonist/heretic/proc/research_knowledge(knowledge_type, mob/living/user)
	if(!user || user.mind != owner || IS_HERETIC(user) != src || user.incapacitated())
		return FALSE
	var/error_message = research_error(knowledge_type)
	if(error_message)
		to_chat(user, span_warning(error_message))
		return FALSE
	var/datum/eldritch_knowledge/knowledge = knowledge_type
	var/side_payment = 0
	if(knowledge_type in GLOB.heretic_side_knowledge)
		side_payment = min(side_knowledge_points, initial(knowledge.cost))
	side_knowledge_points -= side_payment
	knowledge_points -= initial(knowledge.cost) - side_payment
	if(!selected_path)
		for(var/path_id in GLOB.heretic_paths)
			var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
			if(path.knowledge[1] == knowledge_type)
				selected_path = path.id
				break
		create_deed()
		announce_path_start(user)
	if(!(knowledge_type in GLOB.heretic_side_knowledge))
		path_stage++
		var/datum/heretic_path/current_path = GLOB.heretic_paths[selected_path]
		if(path_stage == length(current_path.knowledge) - 1)
			announce_threat()
	gain_knowledge(knowledge_type)
	attune_books(user)
	attune_robes(user)
	refresh_book_ui()
	log_game("[key_name(user)] изучает [initial(knowledge.name)] на пути [selected_path].")
	return TRUE

/datum/antagonist/heretic/proc/get_researchable_knowledge()
	var/list/researchable = list()
	if(!selected_path)
		for(var/path_id in GLOB.heretic_paths)
			var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
			researchable += path.knowledge[1]
		return researchable
	var/datum/heretic_path/path = GLOB.heretic_paths[selected_path]
	if(path_stage < length(path.knowledge))
		researchable += path.knowledge[path_stage + 1]
	for(var/knowledge_type in GLOB.heretic_side_knowledge)
		if(!researched_knowledge[knowledge_type] && path_stage >= GLOB.heretic_side_knowledge[knowledge_type])
			researchable += knowledge_type
	return researchable

/datum/antagonist/heretic/proc/announce_path_start(mob/living/user)
	var/datum/heretic_path/path = GLOB.heretic_paths[selected_path]
	if(!user || !path)
		return
	var/datum/eldritch_knowledge/base_knowledge = path.knowledge[1]
	var/resource_desc = initial(base_knowledge.combat_resource_desc)
	if(resource_desc)
		to_chat(user, span_notice("[initial(base_knowledge.combat_resource_name)]: [resource_desc]"))
	if(deed)
		to_chat(user, span_notice("Дело пути «[deed.name]»: [deed.desc] Каждая ступень даёт очко знаний, каждое действие пополняет запас силы."))
