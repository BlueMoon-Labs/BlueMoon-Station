// Джоб менюшка похуй может потом доделаю все по красоте.
// В этот раз без пидор_бэк дефайнов.
#define JOB_MENU_LATEJOIN "latejoin"
#define JOB_MENU_PREFS "prefs"
/// Потолок холста превью в пикселях: и base64, и обход канвасом остаются разумными
#define JOB_MENU_PREVIEW_LIMIT 128

/mob/dead/new_player
	var/datum/job_menu/job_menu

/datum/preferences
	var/datum/job_menu/job_menu

// Жёсткие враждебные гост-роли, которые помечаем в меню черепом
GLOBAL_LIST_INIT(job_menu_antag_spawners, list(
	/obj/effect/mob_spawn/human/ash_walker,
	/obj/effect/mob_spawn/human/ash_walkers_slave,
	/obj/effect/mob_spawn/human/raider,
	/obj/effect/mob_spawn/human/vox_scavenger,
	/obj/effect/mob_spawn/human/medieval,
	/obj/effect/mob_spawn/human/pirate,
	/obj/effect/mob_spawn/human/slavers,
	/obj/effect/mob_spawn/human/changeling_extended,
	/obj/effect/mob_spawn/human/clockremnant,
	/obj/effect/mob_spawn/human/bloodremnant,
	/obj/effect/mob_spawn/swarmer,
))

/datum/job_menu /// Один из JOB_MENU
	var/mode
	var/datum/preferences/prefs
	var/selected
	var/selected_ghost
	var/list/previews
	var/pushed_preview
	var/cached_slot

/datum/job_menu/New(new_mode, datum/preferences/new_prefs)
	mode = new_mode
	prefs = new_prefs
	previews = list()

/datum/job_menu/Destroy(force, ...)
	SStgui.close_uis(src)
	previews = null
	prefs = null
	return ..()

 // заменяет тело старого на новый
/mob/dead/new_player/proc/open_job_menu()
	if(QDELETED(job_menu))
		job_menu = new(JOB_MENU_LATEJOIN, client?.prefs)
	job_menu.ui_interact(src)

/datum/preferences/proc/open_job_menu(mob/user)
	if(QDELETED(job_menu))
		job_menu = new(JOB_MENU_PREFS, src)
	job_menu.ui_interact(user)

// Основные стейты для УИ, подсасывает старые значения не меняя их
/datum/job_menu/ui_state(mob/user)
	if(mode == JOB_MENU_LATEJOIN)
		return GLOB.new_player_state
	return GLOB.always_state

/datum/job_menu/ui_status(mob/user, datum/ui_state/state)
	if(!user?.client)
		return UI_CLOSE
	// Вот эту логику копируйте для всех переходящих в обсерв гостов если у нас появится подобие такой же менюшки, например для мини-игр или типа того.
	if(mode == JOB_MENU_LATEJOIN)
		return GLOB.new_player_state.can_use_topic(src, user)
	return (user.client.prefs == prefs) ? UI_INTERACTIVE : UI_CLOSE // на всякий случай я ебу

/datum/job_menu/ui_interact(mob/user, datum/tgui/ui)
	if(!prefs && user?.client)
		prefs = user.client.prefs
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui) // Единственное место где может наебнуться меню, изначально окно загружается без кэша.
		pushed_preview = null
		var/window_title = (mode == JOB_MENU_LATEJOIN) ? "Выберите профессию" : "Настройка профессий"
		ui = new(user, src, "JobMenu", window_title)
		ui.open()
		ui.set_autoupdate(FALSE)

// Дата
/datum/job_menu/ui_data(mob/user)
	var/list/data = list()
	if(!prefs && user?.client)
		prefs = user.client.prefs

	if(prefs && prefs.default_slot != cached_slot)
		previews.Cut()
		pushed_preview = null
		cached_slot = prefs.default_slot

	data["mode"] = mode
	data["selected"] = selected
	data["selectedGhost"] = selected_ghost

	// Один слот под последнее отправленное превью, дальше гоняем ключи
	var/preview_target = selected
	if(!preview_target && selected_ghost)
		preview_target = "ghost:[selected_ghost]"

	if(preview_target && pushed_preview != preview_target)
		var/preview_image = previews[preview_target]
		if(isnull(preview_image))
			preview_image = selected ? generate_preview(selected, user) : generate_ghost_preview(selected_ghost, user)
			previews[preview_target] = preview_image
		pushed_preview = preview_target
		if(length(preview_image))
			data["preview"] = preview_image
			data["previewJob"] = preview_target

	data["departments"] = build_departments(user)

	if(mode == JOB_MENU_LATEJOIN)
		data["ghostRoles"] = build_ghost_roles()
		// Описания тянем только для выбранной роли, всё остальное описано в списке
		if(selected_ghost)
			data["ghostInfo"] = build_ghost_info(selected_ghost)
		data["round"] = build_round_info()
	else
		data["joblessrole"] = build_jobless_text()
		data["overflowRole"] = SSjob.overflow_role

	return data

 // Повторяем группировку отделов с старого меню, порядок меняется позицией в листе.
/datum/job_menu/proc/build_departments(mob/user)
	. = list()
	if(!SSjob || !length(SSjob.occupations))
		return

	var/list/categories = list(
		GLOB.command_positions,
		GLOB.supply_positions,
		GLOB.engineering_positions,
		GLOB.nonhuman_positions - "pAI",
		GLOB.civilian_positions,
		GLOB.law_positions,
		GLOB.medical_positions,
		GLOB.science_positions,
		GLOB.security_positions,
	)

	// Главы отделов у каждой категории первая профессия и есть её начальник
	var/list/heads = list()
	for(var/list/head_category in categories)
		if(length(head_category))
			heads |= head_category[1]

	var/latejoin_mode = (mode == JOB_MENU_LATEJOIN)

	if(latejoin_mode)
		for(var/datum/job/prioritized_job in SSjob.prioritized_jobs.Copy())
			if(prioritized_job.current_positions >= prioritized_job.total_positions)
				SSjob.prioritized_jobs -= prioritized_job

	var/list/emitted = list()
	var/group_index = 0

	for(var/list/category in categories)
		group_index++
		if(!length(category))
			continue
		var/datum/job/head_job = SSjob.name_occupations[category[1]]
		if(!head_job)
			continue

		var/list/jobs = list()
		for(var/job_title in category)
			var/datum/job/job_datum = SSjob.name_occupations[job_title] // Проверка на датум, у которого поменялось название. Например Бриг педик это не валидное значение, делаем его валидным.
			if(!job_datum)
				continue
			// Часть профессий попадают под несколько отделов, например КМ состоит и в главах и в карго.
			var/is_head = (job_title == category[1])
			if(!is_head && (job_datum.title in emitted))
				continue
			emitted += job_datum.title
			if(latejoin_mode)
				var/mob/dead/new_player/J = user
				// Вакансии которые ваще не доступны скрываем
				if(!istype(J) || J.IsJobUnavailable(job_datum.title, TRUE) != JOB_AVAILABLE)
					continue
			jobs += list(build_job_entry(job_datum, user, heads))

		var/department_type = head_job.exp_type_department
		. += list(list(
			"name" = (GLOB.exp_type_department_ru[department_type] || department_type),
			"color" = head_job.selection_color,
			"command" = (group_index == 1),
			"jobs" = jobs,
		))

/// строка профессии
/datum/job_menu/proc/build_job_entry(datum/job/job_datum, mob/user, list/heads)
	var/list/entry = list(
		"title" = job_datum.title,
		"command" = (job_datum.title in GLOB.command_positions),
		"head" = (length(heads) && (job_datum.title in heads)),
		"current" = job_datum.current_positions,
		"total" = job_datum.total_positions,
	)

	if(prefs)
		var/display_title = job_datum.title
		if(prefs.alt_titles_preferences[job_datum.title])
			display_title = prefs.alt_titles_preferences[job_datum.title]
		entry["displayTitle"] = display_title

	if(length(job_datum.alt_titles))
		entry["hasAltTitles"] = TRUE

	if(mode == JOB_MENU_LATEJOIN)
		if(job_datum in SSjob.prioritized_jobs)
			entry["pinned"] = TRUE
		return entry

	var/blocked_reason = prefs_blocked_reason(job_datum, user)
	if(blocked_reason)
		entry["blocked"] = blocked_reason

	var/priority = prefs.job_preferences["[job_datum.title]"]
	if(priority)
		entry["priority"] = priority

	if(job_datum.title == SSjob.overflow_role)
		entry["overflow"] = TRUE
	else if(prefers_overflow_locked(job_datum, user))
		entry["locked"] = TRUE

	return entry

// даем инфо о блоке профессии
/datum/job_menu/proc/prefs_blocked_reason(datum/job/job_datum, mob/user)
	if(!user?.client || !prefs)
		return null
	var/rank = job_datum.title

	if(jobban_isbanned(user, rank))
		return "ЗАБАНЕН"

	var/required_playtime_remaining = job_datum.required_playtime_remaining(user.client)
	if(required_playtime_remaining)
		return "[get_exp_format(required_playtime_remaining)] как [job_datum.get_exp_req_type()]"

	if(!job_datum.player_old_enough(user.client))
		return "ЧЕРЕЗ [job_datum.available_in_days(user.client)] ДН."

	if(!prefs.pref_species.qualifies_for_rank(rank, prefs.features))
		if(prefs.pref_species.id == SPECIES_HUMAN)
			return "МУТАНТ"
		return "НЕ ЧЕЛОВЕК"

	if(job_datum.is_species_blacklisted(user.client))
		return "РАСА ЗАПРЕЩЕНА"

	return null

/// флажок клоуна
/datum/job_menu/proc/prefers_overflow_locked(datum/job/job_datum, mob/user)
	if(!prefs || job_datum.title == SSjob.overflow_role)
		return FALSE
	if(prefs.job_preferences["[SSjob.overflow_role]"] != JP_LOW)
		return FALSE
	if(user && jobban_isbanned(user, SSjob.overflow_role))
		return FALSE
	return TRUE

/// Гост роли список
/datum/job_menu/proc/build_ghost_roles()
	. = list()
	for(var/spawner_key in GLOB.mob_spawners)
		var/list/spawner_list = GLOB.mob_spawners[spawner_key]
		if(!length(spawner_list))
			continue

		var/list/usable = list()
		for(var/candidate in spawner_list)
			if(!istype(candidate, /obj/effect/mob_spawn))
				continue
			var/obj/effect/mob_spawn/check = candidate
			if(check.can_latejoin())
				usable += check
		if(!length(usable))
			continue

		var/obj/effect/mob_spawn/first = usable[1]
		var/list/entry = list(
			"name" = spawner_key,
			"category" = first.category,
			"group" = ghost_role_group(usable),
			"amount" = length(usable),
		)

		var/can_load = 0
		var/is_antag = FALSE
		var/is_infinite = FALSE
		var/is_silicon = FALSE
		var/is_animal = FALSE
		var/is_human = FALSE
		for(var/obj/effect/mob_spawn/check in usable)
			if(check.can_load_appearance > can_load)
				can_load = check.can_load_appearance
			if(check.uses < 0)
				is_infinite = TRUE
			if(ghost_role_is_antag(check))
				is_antag = TRUE
			if(ispath(check.mob_type, /mob/living/silicon))
				is_silicon = TRUE
			else if(ispath(check.mob_type, /mob/living/carbon/human))
				is_human = TRUE
			else if(ispath(check.mob_type, /mob/living/simple_animal))
				is_animal = TRUE

		if(can_load)
			entry["canLoad"] = can_load
		if(is_infinite)
			entry["infinite"] = TRUE
		if(is_antag)
			entry["antag"] = TRUE
		if(ghost_previewable(first))
			entry["previewable"] = TRUE
		if(is_silicon)
			entry["kind"] = "silicon"
		else if(is_animal && !is_human)
			entry["kind"] = "animal"
		else if(!is_human && !is_animal && !is_silicon)
			entry["kind"] = "other"
		. += list(entry)

/// Явно враждебный спавнер?
/datum/job_menu/proc/ghost_role_is_antag(obj/effect/mob_spawn/spawn_landmark)
	for(var/antag_type in GLOB.job_menu_antag_spawners)
		if(ispath(spawn_landmark.type, antag_type))
			return TRUE
	return FALSE

/// Соберётся ли для роли нормальное превью. Зеркалит generate_ghost_preview чтобы UI не ждал картинку впустую.
/datum/job_menu/proc/ghost_previewable(obj/effect/mob_spawn/spawn_landmark)
	if(ispath(spawn_landmark.mob_type, /mob/living/silicon/ai) || ispath(spawn_landmark.mob_type, /mob/living/silicon/robot))
		return TRUE
	if(ispath(spawn_landmark.mob_type, /mob/living/carbon/human))
		return istype(spawn_landmark, /obj/effect/mob_spawn/human)
	if(!ispath(spawn_landmark.mob_type, /mob))
		return FALSE
	var/atom/mob_proto = spawn_landmark.mob_type
	var/icon_file = initial(mob_proto.icon)
	var/icon_state = initial(mob_proto.icon_state)
	if(!icon_file || !icon_state)
		return FALSE
	return (icon_state in icon_states(icon_file))

/// подстатус гост-роли внутри её категории DS-1, Тарков, Гост-Кафе и т.п.
/// ключ в GLOB.mob_spawners склеивает сразу несколько путей спавнеров job_description,
/// так что подпись выбираем по большинству голосов среди спавнеров этой роли.
/datum/job_menu/proc/ghost_role_group(list/usable)
	var/list/counts = list()
	for(var/obj/effect/mob_spawn/spawn_landmark in usable)
		var/root = ghost_role_root(spawn_landmark.type)
		if(!root)
			continue
		counts[root] = isnull(counts[root]) ? 1 : counts[root] + 1
	if(!length(counts))
		return null

	var/best
	for(var/root in counts)
		if(isnull(best))
			best = root
		else if(counts[root] > counts[best])
			best = root
		else if(counts[root] == counts[best] && root < best)
			best = root
	return ghost_role_group_label(best)

/// Первый говорящий сегмент пути после /obj/effect/mob_spawn/, без обобщений вида human/corpse/space.
/datum/job_menu/proc/ghost_role_root(spawner_type)
	if(!ispath(spawner_type, /obj/effect/mob_spawn))
		return null
	var/static/list/generic_roots = list("human" = TRUE, "corpse" = TRUE, "space" = TRUE, "robot" = TRUE, "alive" = TRUE)
	var/list/segments = splittext("[spawner_type]", "/")
	var/index = segments.Find("mob_spawn")
	if(!index)
		return null
	for(var/i in index + 1 to segments.len)
		if(generic_roots[segments[i]])
			continue
		return segments[i]
	return (index < segments.len) ? segments[index + 1] : null

/// Человекочитаемые подписи для известных подтипов, остальное просто раскрашиваем по underscore.
/datum/job_menu/proc/ghost_role_group_label(root)
	var/static/list/labels = list(
		"lavaland_syndicate" = "DS-1",
		"ds2" = "DS-2",
		"tarkon" = "Тарков",
		"ghostcafe" = "Гост-Кафе",
		"ghostcafeVR" = "Гост-Кафе VR",
		"ghostcafe_space" = "Гост-Кафе",
		"inteqspace" = "InteQ",
		"solfed" = "Солнечная Федерация",
		"syndicate" = "Синдикат",
		"syndicatesoldier" = "Синдикат",
		"black_mesa" = "Black Mesa",
		"hlscientist" = "Black Mesa",
		"hlguard" = "Black Mesa",
		"deadhecu" = "Black Mesa",
		"hotel_staff" = "Космический Отель",
		"ash_walker" = "Пеплоходцы",
		"ash_walkers_slave" = "Пеплоходцы",
		"seed_vault" = "Хранилище Семян",
		"golem" = "Големы",
		"hermit" = "Отшельник",
		"wandering_hermit" = "Отшельник",
		"exile" = "Изгнанники",
		"prisoner_transport" = "Каторжники",
		"oldsec" = "Старая Станция",
		"oldeng" = "Старая Станция",
		"oldsci" = "Старая Станция",
		"pirate" = "Пираты",
		"medieval" = "Средневековье",
		"raider" = "Налётчики",
		"vox_scavenger" = "Вокс-Мародёры",
		"ftu_crew" = "ФТУ",
		"centcom_syndicate" = "Стажёры ЦК",
		"centcom_nanotrasen" = "Стажёры ЦК",
		"fugitive" = "Беглецы",
		"slavers" = "Работорговцы",
		"clockremnant" = "Останки Культа",
		"bloodremnant" = "Кровавые Останки",
		"changeling_extended" = "Мутанты",
		"ert" = "Экстренный Отряд",
		"swarmer" = "Свармеры",
		"mouse" = "Разумные Животные",
		"cow" = "Разумные Животные",
		"slime" = "Разумные Животные",
		"qareen" = "Кварены", // отсылко
		"imaginary_friend" = "Воображаемый Друг",
		"antag_training" = "Тренировка Антагониста",
		"ipc_shell" = "Оболочки ИПЦ",
		"AICorpse" = "ИИ",
		"robot" = "Роботы",
		"facehugger" = "Лицехваты",
		"zombie" = "Зомби",
		"skeleton" = "Скелеты",
	)
	if(labels[root])
		return labels[root]
	return capitalize(replacetext(root, "_", " "))

/// Описание выбранной гост-роли
/datum/job_menu/proc/build_ghost_info(spawner_key)
	var/list/spawner_list = GLOB.mob_spawners[spawner_key]
	if(!length(spawner_list))
		return null

	var/obj/effect/mob_spawn/spawn_landmark
	for(var/candidate in spawner_list)
		if(!istype(candidate, /obj/effect/mob_spawn))
			continue
		var/obj/effect/mob_spawn/check = candidate
		if(check.can_latejoin())
			spawn_landmark = check
			break
	if(!spawn_landmark)
		return null

	var/list/info = list(
		"short" = clean_ghost_text(spawn_landmark.short_desc, 700),
		"flavour" = clean_ghost_text(spawn_landmark.flavour_text, 6000),
		"warning" = clean_ghost_text(spawn_landmark.important_info, 2000),
	)

	// Правила доп спавнера показываем только вне станции, как и делает сам спавнер
	var/turf/spawn_turf = get_turf(spawn_landmark)
	if(spawn_landmark.addition_warning && (!spawn_turf || !is_station_level(spawn_turf.z)))
		info["addition"] = clean_ghost_text(spawn_landmark.addition_warning, 900)

	return info

/// Чистим описания
/datum/job_menu/proc/clean_ghost_text(text, limit)
	if(!text)
		return ""
	var/cleaned = strip_html_tags(text, TRUE)
	if(!cleaned || cleaned == "The mapper forgot to set this!")
		return ""
	if(limit && length_char(cleaned) > limit)
		cleaned = copytext_char(cleaned, 1, limit + 1) + "…"
	return cleaned

/// Баннер сверху о состоянии раунда. Время, код и цвет
/datum/job_menu/proc/build_round_info()
	var/list/info = list()
	if(SSticker && SSticker.IsRoundInProgress())
		info["duration"] = DisplayTimeText(world.time - SSticker.round_start_time)
		info["alert"] = capitalize(SECURITY_LEVEL_NAME_RU(GLOB.security_level) || SECURITY_LEVEL_NAME_RU(SEC_LEVEL_GREEN) || "зелёный")
		info["alertColor"] = SECURITY_LEVEL_COLOR(GLOB.security_level)

	if(SSshuttle.emergency)
		switch(SSshuttle.emergency.mode)
			if(SHUTTLE_ESCAPE)
				info["shuttle"] = "Экипаж станции эвакуировался."
			if(SHUTTLE_CALL)
				if(!SSshuttle.canRecall())
					info["shuttle"] = "Станция сейчас проводит процедуру эвакуации экипажа."

	return info

/// Что делать, если приоритеты не подойдут
/datum/job_menu/proc/build_jobless_text()
	if(!prefs)
		return null
	switch(prefs.joblessrole)
		if(BEOVERFLOW)
			return "Стать [SSjob.overflow_role], если префы недоступны"
		if(BERANDOMJOB)
			return "Случайная работа, если префы недоступны"
		if(RETURNTOLOBBY)
			return "Вернуться в лобби, если префы недоступны"
	return "Стать [SSjob.overflow_role], если префы недоступны"

// ПРЕВЬЮ

/datum/job_menu/proc/generate_preview(job_title, mob/user)
	var/datum/preferences/preview_prefs = prefs || user?.client?.prefs
	if(!preview_prefs || !SSjob)
		return ""
	var/datum/job/job_datum = SSjob.GetJob(job_title)
	if(!job_datum)
		return ""

	// Синтетики
	if(istype(job_datum, /datum/job/ai))
		return encode_preview_icon(icon('icons/mob/AI.dmi', resolve_ai_icon(preview_prefs.preferred_ai_core_display), SOUTH, 1))
	if(istype(job_datum, /datum/job/cyborg))
		return encode_preview_icon(icon('icons/mob/robots.dmi', "robot", SOUTH, 1))

	var/icon/flat_icon = get_flat_human_icon(null, job_datum, preview_prefs, null, list(SOUTH))
	return encode_preview_icon(flat_icon)

/// Превью гост роли
/datum/job_menu/proc/generate_ghost_preview(spawner_key, mob/user)
	var/list/spawner_list = GLOB.mob_spawners[spawner_key]
	if(!length(spawner_list))
		return ""
	var/obj/effect/mob_spawn/spawn_landmark
	for(var/candidate in spawner_list)
		if(!istype(candidate, /obj/effect/mob_spawn))
			continue
		var/obj/effect/mob_spawn/check = candidate
		if(check.can_latejoin())
			spawn_landmark = check
			break
	if(!spawn_landmark)
		return ""

	var/datum/preferences/preview_prefs = prefs || user?.client?.prefs

	// Синтетики
	if(ispath(spawn_landmark.mob_type, /mob/living/silicon/ai))
		return encode_preview_icon(icon('icons/mob/AI.dmi', resolve_ai_icon(preview_prefs?.preferred_ai_core_display), SOUTH, 1))
	if(ispath(spawn_landmark.mob_type, /mob/living/silicon/robot))
		return encode_preview_icon(icon('icons/mob/robots.dmi', "robot", SOUTH, 1))

	// учитывается только реальный человек, у мнимых друзей тут спрайт не тот
	if(ispath(spawn_landmark.mob_type, /mob/living/carbon/human))
		if(!istype(spawn_landmark, /obj/effect/mob_spawn/human))
			return ""
		var/obj/effect/mob_spawn/human/human_spawn = spawn_landmark
		var/outfit_path = istype(human_spawn.outfit) ? human_spawn.outfit.type : human_spawn.outfit
		var/datum/preferences/role_prefs = (human_spawn.can_load_appearance && preview_prefs) ? preview_prefs : null
		return encode_preview_icon(get_flat_human_icon(null, null, role_prefs, null, list(SOUTH), outfit_path))

	// остальное спрайт самого моба
	if(!ispath(spawn_landmark.mob_type, /mob))
		return ""
	var/atom/mob_proto = spawn_landmark.mob_type
	var/icon_file = initial(mob_proto.icon)
	var/icon_state = initial(mob_proto.icon_state)
	if(!icon_file || !icon_state)
		return ""
	if(!(icon_state in icon_states(icon_file)))
		return ""
	return encode_preview_icon(icon(icon_file, icon_state, SOUTH, 1))

/datum/job_menu/proc/fit_preview_icon(icon/target)
	if(!isicon(target))
		return target
	var/width = target.Width()
	var/height = target.Height()
	if(!isnum(width) || !isnum(height) || width <= 0 || height <= 0)
		return target

	var/longest = max(width, height)
	if(longest <= JOB_MENU_PREVIEW_LIMIT)
		return target

	// Нужен был целый делитель для вмещения куклы ровно по центру превью без скейла. Во бля
	var/factor = 1
	while(longest / factor > JOB_MENU_PREVIEW_LIMIT)
		factor++

	var/icon/result = new /icon(target)
	result.Scale(max(1, round(width / factor, 1)), max(1, round(height / factor, 1)))
	return result

/datum/job_menu/proc/encode_preview_icon(icon/target)
	if(!isicon(target))
		return ""
	var/encoded = icon2base64(fit_preview_icon(target))
	return istext(encoded) ? encoded : ""

// АКТы

/datum/job_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	. = TRUE
	// опять забавный вар на всякий случай
	var/mob/ui_user = usr

	switch(action)
		if("refresh")
			return

		if("select")
			var/job_title = params["job"]
			if(!istext(job_title) || !SSjob?.GetJob(job_title))
				return
			selected = job_title
			selected_ghost = null
			return

		if("select_ghost")
			var/spawner_key = params["spawner"]
			if(!istext(spawner_key) || !GLOB.mob_spawners[spawner_key])
				return
			selected_ghost = spawner_key
			selected = null
			return

		if("join")
			if(mode != JOB_MENU_LATEJOIN || !isnewplayer(ui_user))
				return
			var/job_title = params["job"]
			if(!istext(job_title))
				return
			if(!SSticker || !SSticker.IsRoundInProgress())
				to_chat(ui_user, "<span class='danger'>Раунд ещё не начался или уже закончился...</span>")
				return
			if(!entry_allowed(ui_user))
				return
			var/mob/dead/new_player/joiner = ui_user
			joiner.AttemptLateSpawn(job_title)
			return

		if("join_ghost")
			if(mode != JOB_MENU_LATEJOIN || !isnewplayer(ui_user))
				return
			var/spawner_key = params["spawner"]
			if(!istext(spawner_key))
				return
			if(!entry_allowed(ui_user))
				return
			var/list/spawner_list = GLOB.mob_spawners[spawner_key]
			if(!length(spawner_list))
				to_chat(ui_user, "<span class='warning'>Эта роль больше недоступна.</span>")
				return
			var/list/usable_spawns = list()
			for(var/candidate in spawner_list)
				if(!istype(candidate, /obj/effect/mob_spawn))
					continue
				var/obj/effect/mob_spawn/check = candidate
				if(check.can_latejoin())
					usable_spawns += check
			if(!length(usable_spawns))
				to_chat(ui_user, "<span class='warning'>Эта роль больше недоступна.</span>")
				return
			var/obj/effect/mob_spawn/spawn_landmark = pick(usable_spawns)
			if(spawn_landmark.attack_ghost(ui_user, latejoinercalling = TRUE))
				SSticker.queued_players -= ui_user
				SSticker.queue_delay = 4
				qdel(ui_user)
			return

		if("set_priority")
			if(mode != JOB_MENU_PREFS || !prefs)
				return
			set_priority(ui_user, params["job"], params["level"])
			return

		if("joblessrole")
			if(mode != JOB_MENU_PREFS || !prefs)
				return
			switch(prefs.joblessrole)
				if(RETURNTOLOBBY)
					prefs.joblessrole = jobban_isbanned(ui_user, SSjob.overflow_role) ? BERANDOMJOB : BEOVERFLOW
				if(BEOVERFLOW)
					prefs.joblessrole = BERANDOMJOB
				else
					prefs.joblessrole = RETURNTOLOBBY
			prefs.save_character(silent = TRUE)
			return

		if("reset")
			if(mode != JOB_MENU_PREFS || !prefs)
				return
			prefs.ResetJobs()
			prefs.save_character(silent = TRUE)
			return

		if("alt_title")
			if(!prefs)
				return
			var/job_title = params["job"]
			var/datum/job/job_datum = SSjob?.GetJob(job_title)
			if(!job_datum)
				return
			var/list/titles_list = list(job_title)
			for(var/alt_title in job_datum.alt_titles)
				titles_list += alt_title
			var/chosen_title = tgui_input_list(ui_user, "Выберите название должности:", "Настройка профессий", titles_list)
			if(chosen_title)
				if(chosen_title == job_title)
					prefs.alt_titles_preferences.Remove(job_title)
				else
					prefs.alt_titles_preferences[job_title] = chosen_title
				prefs.save_character(silent = TRUE)
			return

		if("close")
			if(prefs)
				prefs.save_character(silent = TRUE)
			ui?.close()
			return

 // Проверки входа в раунд при разных условиях
/datum/job_menu/proc/entry_allowed(mob/user)
	if(!GLOB.enter_allowed)
		to_chat(user, "<span class='notice'>Администрация запретила вход в игру!</span>")
		return FALSE

	var/relevant_cap
	var/hpc = CONFIG_GET(number/hard_popcap)
	var/epc = CONFIG_GET(number/extreme_popcap)
	if(hpc && epc)
		relevant_cap = min(hpc, epc)
	else
		relevant_cap = max(hpc, epc)

	if(length(SSticker.queued_players) && !(user.ckey in GLOB.admin_datums))
		if((living_player_count() >= relevant_cap) || (user != SSticker.queued_players[1]))
			to_chat(user, "<span class='warning'>Сервер заполнен.</span>") // лол
			return FALSE

	return TRUE

/datum/job_menu/proc/set_priority(mob/user, job_title, level)
	if(!prefs || !istext(job_title))
		return
	var/datum/job/job_datum = SSjob?.GetJob(job_title)
	if(!job_datum || !length(SSjob.occupations))
		return

	var/new_level = level
	if(!isnum(new_level))
		new_level = text2num("[new_level]")
	if(isnull(new_level) || new_level < 0 || new_level > JP_HIGH)
		return

	if(job_title == SSjob.overflow_role)
		// Переполнение - это простое "Да/Нет": Да означает JP_LOW.
		if(new_level)
			prefs.job_preferences["[job_title]"] = JP_LOW
		else
			prefs.job_preferences -= "[job_title]"
	else if(prefers_overflow_locked(job_datum, user))
		return
	else if(!new_level)
		prefs.job_preferences -= "[job_title]"
	else
		prefs.SetJobPreferenceLevel(job_datum, new_level)

	prefs.save_character(silent = TRUE)

#undef JOB_MENU_LATEJOIN
#undef JOB_MENU_PREFS
#undef JOB_MENU_PREVIEW_LIMIT
