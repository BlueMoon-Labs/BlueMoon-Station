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
	/datum/eldritch_knowledge/unshielded_mind = 6,
	/datum/eldritch_knowledge/summon/ashy = 7,
	/datum/eldritch_knowledge/summon/rusty = 7,
	/datum/eldritch_knowledge/spell/cleave = 8,
))

/proc/init_heretic_paths()
	var/list/paths = list()
	for(var/datum/heretic_path/path_type as anything in subtypesof(/datum/heretic_path))
		if(!initial(path_type.id))
			continue
		var/datum/heretic_path/path = new path_type
		paths[path.id] = path
	return paths

/datum/heretic_path
	var/id
	var/name
	var/desc
	var/strengths
	var/weaknesses
	/// Одна строка шапки пути в кодексе.
	var/tagline
	var/craft_summary
	var/capture_summary
	var/escape_summary
	var/list/strength_points
	var/list/weakness_points
	var/list/knowledge = list()

/datum/heretic_path/New()
	. = ..()
	desc ||= tagline
	if(!strengths && length(strength_points))
		strengths = jointext(strength_points, " ")
	if(!weaknesses && length(weakness_points))
		weaknesses = jointext(weakness_points, " ")

/datum/heretic_path/ash
	id = PATH_ASH
	deed_type = /datum/heretic_deed/ash
	name = "Пепел"
	tagline = "Поджигает хваткой и клинком, копит угольки и уходит сквозь стены пепельным переходом."
	craft_summary = "Хваткой гасите огонь на полу в новых отделах - это дело пути, а погашенное пламя даёт уголёк."
	capture_summary = "Хватка валит на 2 секунды, огонь выматывает; готовую цель на своём огне уводите в изнанку за 1 секунду."
	escape_summary = "Пепельный переход на 1,5 секунды проводит сквозь стены даже из хватки, Угасание оставляет огонь погоне."
	strength_points = list(
		"Хватка, клинок, Угасание и потоки поджигают, а горящие враги кормят вас угольками.",
		"Угасание за уголёк тушит вас, лечит и оставляет огонь на пути погони.",
		"Пепельный переход проводит сквозь стены, огонь и жара вам не страшны.",
		"Метка Пепла перескакивает по толпе и выматывает всех по очереди.",
		"Возрождение ночного дозорного лечит вас за счёт до 4 горящих врагов в 4 клетках.",
	)
	weakness_points = list(
		"Хватка, клинок и метка бьют только вплотную.",
		"Огнетушитель и вода тушат поджоги, а мокрая цель не загорается и угольков не даёт.",
		"Защита от магии не даёт поджечь цель хваткой и потоками.",
		"Вознёсшегося гасят вода и пена: 7 секунд без огненного следа и без лечения.",
		"До вознесения под оглушением и в стамкрите заклинания пути молчат; в захвате - Хватка и Пепельный переход.",
	)
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
	tagline = "Ржавит станцию хваткой, ломает стены и шлюзы и лечится на своей ржавчине."
	craft_summary = "Хваткой ржавьте пол в новых отделах - это дело пути; свежая ржавчина даёт нарост раз в 15 секунд."
	capture_summary = "Хватка распада валит на 2 секунды; готовую цель на ржавчине своего очага уводите в изнанку за 1 секунду."
	escape_summary = "Хватка ломает шлюз и ржавую стену: уходите насквозь на свою ржавчину; из изнанки - к своему очагу."
	strength_points = list(
		"Хватка ломает обычные шлюзы, а после Хватки Ржавчины рушит и обычную стену с одного касания.",
		"На ржавом полу вы лечитесь, а очаг Укоренения лечит и вас, и свиту.",
		"Метка и клинок разъедают тело коррозией, метка ржавит вещи в руках и одежду.",
		"Энтропийное облако слепит врагов и стравливает их друг с другом.",
		"Мерзкая хватка ржавит пол 3×3 под врагом: плацдарм для лечения даже вдали от очага.",
	)
	weakness_points = list(
		"Вне своей ржавчины вы заметно слабее, поэтому вас выманивают с неё.",
		"Ржавчина видна всем и выдаёт вашу территорию.",
		"Укреплённые стены поддаются хватке лишь с шансом 50%.",
		"Ржавое сердце вознёсшегося разбивается оружием, и ржавый пол теряет силу вознесения.",
		"До вознесения под оглушением и в стамкрите заклинания пути молчат; в чужом захвате работает лишь Хватка.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_rust,
		/datum/eldritch_knowledge/rust_fist,
		/datum/eldritch_knowledge/spell/area_conversion,
		/datum/eldritch_knowledge/rust_mark,
		/datum/eldritch_knowledge/rust_regen,
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
	tagline = "Поднимает свиту из мёртвых, сшивает её раны и бьёт живым швом издалека."
	craft_summary = "Хваткой поглощайте извлечённые органы: новый вид идёт в дело пути, каждый даёт биомассу для свиты."
	capture_summary = "Касание безумия валит на 3 секунды; готовую цель у гуля, мертвеца или ползуна уводите в изнанку из 7 клеток."
	escape_summary = "Своего ухода нет: прикрывает свита, лечит Сшивание; из изнанки - к живому гулю, мертвецу или ползуну."
	strength_points = list(
		"Свита до 4 слуг: гули, Безмолвные мертвецы, пророк, преследователь и ползун.",
		"Живой шов бьёт врага на 5 клеток или вытаскивает раненого слугу из боя.",
		"Сшивание и игла лечат свиту и возвращают слугам руки и ноги.",
		"Пророк разведывает сквозь стены и держит связь всей свиты.",
		"Вознёсшийся червь пожирает трупы, лечится и растёт до 16 сегментов.",
	)
	weakness_points = list(
		"Призывам нужны добровольцы-призраки: без отклика слуги не будет.",
		"Потерянную свиту приходится собирать заново за биомассу и органы.",
		"Щит разума, синтетика и истощённое тело гулем не поднять.",
		"Без слуг нечем прикрыть отход, а вырубленный слуга или оттащенная от него цель срывают увод в изнанку.",
		"Червь огромен и заметен, сегменты рубятся по одному, и с каждым отпадает хвост.",
		"До вознесения под оглушением и в стамкрите заклинания пути молчат; в чужом захвате работает лишь Хватка.",
	)
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
	tagline = "Сковывает врагов холодом, глушит голоса и выбирает дистанцию прыжками и обменом."
	craft_summary = "Хваткой гасите светильники в новых отделах - это дело пути; холод копит осколки для Зимнего предела."
	capture_summary = "Скованность и молчание, Притяжение валит вплотную; готовую цель в своём поле - в изнанку за 1 секунду."
	escape_summary = "Пустотный сдвиг переносит на 3-7 клеток даже из хватки, Аплодисменты меняют местами с кем-то вдали."
	strength_points = list(
		"Хватка, метка, Ищущий клинок, поля и заклинания замедляют врага, каждое попадание обновляет срок.",
		"Хватка, метка и Зимний предел ненадолго лишают врага голоса.",
		"Сдвиг, Аплодисменты и Ищущий клинок дают выбрать дистанцию боя.",
		"В холоде вы лечитесь, не дышите и не мёрзнете.",
		"Буря вознёсшегося разворачивает часть пуль назад.",
	)
	weakness_points = list(
		"Скованность спадает через 4 секунды без новых попаданий или поля.",
		"Защита от магии снимает холод, молчание и сдвиг клинком.",
		"В тепле осколки копятся лишь до 2, а Аристократ лечит только в ваших полях.",
		"Вознёсшегося глушит тепло: горящий или разогретый не отклоняет пули и не сковывает.",
		"До вознесения под оглушением и в стамкрите заклинания пути молчат; в захвате - Хватка и Пустотный сдвиг.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_void,
		/datum/eldritch_knowledge/void_grasp,
		/datum/eldritch_knowledge/spell/void_phase,
		/datum/eldritch_knowledge/void_mark,
		/datum/eldritch_knowledge/cold_snap,
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
	tagline = "Вызывает на дуэль, берёт заложника клинком у горла, отбивает пули в сторону."
	craft_summary = "Вызов человеку рядом: принявший дерётся с вами в изнанке, проигравшего 12 секунд держит клятва."
	capture_summary = "Клинок у горла держит сбитого или обезоруженного соседа до 12 секунд, цель охоты уводит разрезом."
	escape_summary = "Выжидание гасит выстрелы и отбивает пули вбок; из изнанки выводит разрез в 5-9 клетках от входа."
	strength_points = list(
		"Парирование гасит удары и даёт бесплатный ответ на 18 ушибов.",
		"Ответ и взрыв метки выбивают оружие, щит или дубинку из руки.",
		"Выпад сближает на 5 клеток и сбивает с ног на 1,5 секунды.",
		"Клинок у горла держит заложника 12 секунд, цель охоты за 1,5 секунды уходит разрезом в изнанку.",
		"Выжидание гасит выстрелы с любой стороны, пули и лазеры спереди уходят вбок.",
		"Принятый вызов уводит обоих в изнанку без свидетелей, над целью охоты обряд идёт там же.",
	)
	weakness_points = list(
		"Для Выжидания нужна пустая вторая рука, а блоков всего 3-4 на 2-3 секунды.",
		"Каждый выстрел тратит блок Выжидания, так что очередь или картечь быстро его пробивают.",
		"Заложника освобождают 15+ урона вам одним ударом, оглушение, шаг дальше клетки, жезл или 2 секунды растолкать.",
		"Вызов называет имя, в дуэли только клинок; проигрыш обнуляет Темп и 5 минут метит шею порезом.",
		"Орбиту вознесённого сдирает один выстрел картечи.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_blade,
		/datum/eldritch_knowledge/spell/blade_lunge,
		/datum/eldritch_knowledge/spell/blade_dance,
		/datum/eldritch_knowledge/spell/blade_throat,
		/datum/eldritch_knowledge/blade_disarm,
		/datum/eldritch_knowledge/blade_guard,
		/datum/eldritch_knowledge/spell/blade_recall,
		/datum/eldritch_knowledge/blade_mark,
		/datum/eldritch_knowledge/blade_riposte,
		/datum/eldritch_knowledge/final_eldritch/blade_final,
	)

/datum/heretic_path/moon
	id = PATH_MOON
	deed_type = /datum/heretic_deed/moon
	name = "Луна"
	tagline = "Ставит двойника-алиби, уводит жертву во сне к своей копии и уходит в своё отражение."
	craft_summary = "Хватка в «Помощи» ставит двойника: 10 минут стоит за вас, а отдел станции, где его увидят, идёт в дело."
	capture_summary = "Сомнамбула: цель спит на ходу 10 секунд, а у вашей копии её откуда угодно уводит в изнанку отражение."
	escape_summary = "Возвращение в отражение за 2 секунды меняет вас с двойником на посту; из изнанки - к двойнику или копии."
	strength_points = list(
		"Отражения изматывают, гонятся за целью клинка и ловят за вас выстрелы.",
		"Двойник на посту - алиби: выглядит как вы, бродит на месте и повторяет вашу речь.",
		"Хватка вешает помутнение, и Сомнамбула ведёт спящую цель к копии или к вам, цель охоты - и к двойнику.",
		"Спящую у копии или двойника цель охоты вы уводите в изнанку с любого места уровня.",
		"Возвращение в отражение уводит из чужой хватки к двойнику в другом конце уровня.",
		"Обмен, Шествие миражей и Затмение путают, кто из вас настоящий.",
	)
	weakness_points = list(
		"Копии хрупкие: 30 урона, пара ударов или выстрелов их разбивает.",
		"Двойник не моргает и запаздывает в стекле; нулевой жезл или вспышка рядом его рассеивают.",
		"Сомнамбула берёт только цель под помутнением от Хватки, метки, Затмения или Осколков.",
		"Спящую растолкают за 2 секунды; будят и нулевой жезл или вспышка в 3 клетках.",
		"Без двойника на посту уходить некуда; наручники и зоны без телепортации держат вас.",
		"Вознёсшегося выдаёт свет: чужая вспышка в 3 клетках разбивает копии и слепит его.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_moon,
		/datum/eldritch_knowledge/moon_grasp,
		/datum/eldritch_knowledge/spell/moon_sleepwalk,
		/datum/eldritch_knowledge/moon_mark,
		/datum/eldritch_knowledge/moon_shroud,
		/datum/eldritch_knowledge/spell/moon_exchange,
		/datum/eldritch_knowledge/spell/moon_mirage,
		/datum/eldritch_knowledge/moon_refraction,
		/datum/eldritch_knowledge/spell/moon_eclipse,
		/datum/eldritch_knowledge/final_eldritch/moon_final,
	)

/datum/heretic_path/cosmic
	id = PATH_COSMIC
	deed_type = /datum/heretic_deed/cosmic
	name = "Космос"
	tagline = "Ставит звёзды с жгучими нитями, выводит жертву на орбиту, уходит к путеводной звезде."
	craft_summary = "Хваткой в «Помощи» по полу зажгите путеводную звезду: до 4, по одной на отдел, это дело пути."
	capture_summary = "Орбита 10 секунд держит у вашей звезды сбитую или скованную нитью цель, сердце уводит её к звёздам."
	escape_summary = "Звёздная дорога за 2 секунды уводит к путеводной звезде на уровне, даже из чужой хватки."
	strength_points = list(
		"Пара звёзд с нитью ставится одним нажатием: нить натягивается сразу.",
		"Нить сама жжёт, валит и замедляет всех, кто её пересекает или стоит на ней.",
		"Орбита держит цель у звезды 10 секунд, её не утащить, за секунду сердце уводит её в изнанку.",
		"Готовую цель у своей путеводной звезды сердце уводит в изнанку ещё до Орбиты.",
		"Путеводные звёзды - отходы по уровню и выходы из изнанки, дорога к ним открыта и в чужой хватке.",
		"Схлопывание бьёт по площади и стягивает всех поражённых к звёздам.",
	)
	weakness_points = list(
		"Звёзды видны и разбиваются, нулевой жезл гасит их касанием.",
		"Без своих звёзд рядом пульс, схлопывание и Орбита не работают.",
		"Орбиту рвут разбитая звезда, жезл по звезде или пленнику и 2 секунды растолкать пленника.",
		"Дорогу к путеводной звезде срывает любой сдвиг: 2 секунды нужно стоять на месте.",
		"Путеводную звезду экипаж замечает по холодной точке света без тени.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_cosmic,
		/datum/eldritch_knowledge/cosmic_grasp,
		/datum/eldritch_knowledge/spell/cosmic_step,
		/datum/eldritch_knowledge/spell/cosmic_orbit,
		/datum/eldritch_knowledge/cosmic_expansion,
		/datum/eldritch_knowledge/cosmic_mark,
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
			return "Сначала изучите ступень [GLOB.heretic_side_knowledge[knowledge_type]] своего пути."
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

/proc/heretic_ascension_happened()
	for(var/datum/antagonist/heretic/heretic in GLOB.antagonists)
		if(heretic.ascended && !heretic.simulated)
			return TRUE
	return FALSE

/datum/antagonist/heretic/proc/announce_threat()
	if(ascension_notice_sent)
		return FALSE
	ascension_notice_sent = TRUE
	if(world.time < GLOB.heretic_threat_warning_until)
		ascension_ready_at = GLOB.heretic_threat_warning_until
		return FALSE
	GLOB.heretic_threat_warning_until = world.time + HERETIC_THREAT_WARNING_TIME
	ascension_ready_at = GLOB.heretic_threat_warning_until
	priority_announce("Зафиксировано усиление оккультной активности: последователи запретных путей уже приносят экипаж в жертву. [heretic_ascension_happened() ? "Один из них уже разорвал завесу, остальные могут последовать за ним." : "Вознесения пока не было."] О начале заключительного обряда станция получит отдельное оповещение, и оно возможно не раньше чем через три минуты. Сообщайте службе безопасности о ритуальных знаках и необъяснимых исчезновениях экипажа. Задержанного еретика держите в наручниках или смирительной рубашке, а для долгого содержания установите ему имплант защиты разума: так магия запретных путей, их обряды и побег через разбитый клинок недоступны.", "Предупреждение об оккультной активности", 'sound/misc/notice1.ogg')
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
	var/announce_start = !selected_path
	if(!selected_path)
		for(var/path_id in GLOB.heretic_paths)
			var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
			if(path.knowledge[1] == knowledge_type)
				selected_path = path.id
				break
		create_deed()
	if(!(knowledge_type in GLOB.heretic_side_knowledge))
		path_stage++
		var/datum/heretic_path/current_path = GLOB.heretic_paths[selected_path]
		if(path_stage == length(current_path.knowledge) - 1)
			announce_threat()
	gain_knowledge(knowledge_type)
	if(announce_start)
		announce_path_start(user)
	attune_books(user)
	attune_robes(user)
	attune_amulets(user)
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
	var/datum/eldritch_knowledge/base_knowledge = get_knowledge(path.knowledge[1])
	var/datum/heretic_innate/innate = path.innate_type
	to_chat(user, span_notice("Врождённая черта «[initial(innate.name)]»: [initial(innate.desc)]"))
	if(base_knowledge?.combat_resource_desc)
		to_chat(user, span_notice("[base_knowledge.combat_resource_name]: [base_knowledge.combat_resource_desc]"))
	if(deed)
		to_chat(user, span_notice("Дело пути «[deed.name]»: [deed.desc] Каждая ступень даёт очко знаний."))
