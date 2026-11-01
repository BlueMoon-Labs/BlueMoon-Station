// Перенос с старых работ, подробнее лс - pingva
#define CHARACTER_SETUP_INTERFACE "CharacterSetup"
#define CHARACTER_SETUP_HEADSHOT_MAX_LEN 400
#define FEATURE_BOOL "bool"
#define FEATURE_NUM "num"
#define FEATURE_LIST "list"
#define FEATURE_COLOR "color"
#define FEATURE_CYCLE "cycle"
#define FEATURE_SCOPE_FEATURE "feature"
#define FEATURE_SCOPE_PREF "pref"
#define FEATURE_COLOR_PLAIN "plain"
#define FEATURE_COLOR_LIMITED "limited"
#define FEATURE_COLOR_MUTANT "mutant"
#define FEATURE_COLOR_RESET "reset"
#define FEATURE_MISMATCH_HINT "Показывать части и маркинги, не соответствующие текущему виду."
#define FEATURE_HETEROCHROMIA_HINT "Особые глаза с гетерохромией: wide, big, bigcyclops, skrell, third, thirdbig."
#define FEATURE_ERP_HINT "Эротические взаимодействия."
#define FEATURE_NONCON_HINT "No — сексуальное насилие над персонажем запрещено, включая применение секс-игрушек и ERP-реагентов без отдельного OOC-согласия.\n\nAsk — согласие на насильственные ERP-действия с правом потребовать остановить сцену в LOOC. Секс-игрушки — только с отдельного OOC-согласия.\n\nYes — автоматическое согласие на сексуальное насилие над персонажем.\n\nЭмоуты и непристойные глаголы при No/Ask требуют OOC-согласия. Промывка мозгов и законы силиконов согласие не заменяют. После начала сцены, включая похищение и другие подготовительные агрессивные действия, запрещено менять Non-Con/Unholy/Extreme/Harmful со значения Yes."
#define FEATURE_VORE_HINT "Пожирание и переваривание."
#define FEATURE_MOBSEX_HINT "Особые мобы попытаются вас изнасиловать."
#define FEATURE_TATTOO_HINT "Другие игроки смогут оставлять тату на вас."
#define FEATURE_UNHOLY_HINT "Разрешение на грязные взаимодействия: моча, смегма."
#define FEATURE_UNHOLY_HARD_HINT "Особые грязные взаимодействия: копро, выделения, газы."
#define FEATURE_EXTREME_HINT "Экстремальные сцены: в глаза, уши, удушение, укусы."
#define FEATURE_EXTREME_HARM_HINT "Особые жестокие сцены с возможным летальным исходом: сдавливание головы ляжками, отстрел яиц, другое."
#define FEATURE_SPRITE_SCALE_HINT "Размер вашего спрайта повлияет на это."
#define FEATURE_REAGENT "reagent"
#define FEATURE_GENITAL_SIZE_HINT "0 - отключить ограничение."
#define FEATURE_CUM_MAX_HINT "По умолчанию зависит от размера яичек."
#define FEATURE_CUM_RATE_HINT "По умолчанию [CUM_RATE] единиц за 10 секунд."

/datum/preferences
	var/datum/character_setup/character_setup_ui

/datum/character_setup
	var/datum/preferences/prefs
	var/tmp/preview_dirty = TRUE
	var/tmp/preview_update_pending = FALSE
	var/list/feature_field_cache
	var/list/marking_options_cache
	var/list/language_icons_cache
	var/list/options_cache
	var/list/mutant_labels_cache
	var/tmp/heavy_static_pending = FALSE
	var/character_revision = 0
	var/loadout_selected = FALSE
	var/list/viewer_screens
	var/preview_mode = PREVIEW_PREF_JOB
	var/preview_auto_fit = TRUE
	var/preview_aroused = FALSE
	var/saved_character_state
	var/save_notice
	var/selected_character_preset
	var/sound_preview_channel
	var/sound_preview_kind
	var/sound_preview_until = 0
	var/sound_preview_generation = 0
	var/next_sound_preview = 0
	var/preview_direction = SOUTH
	var/preview_zoom = 1
	var/preview_reference = FALSE
	var/preview_background_style = "texture"
	var/heavy_static_ready = FALSE

/datum/character_setup/New(datum/preferences/new_prefs)
	prefs = new_prefs
	record_saved_state()

/datum/character_setup/Destroy(force, ...)
	stop_sound_preview()
	SStgui.close_uis(src)
	QDEL_LIST_ASSOC_VAL(viewer_screens)
	prefs = null
	return ..()

// Сравниваем значения, а не нажатия: отменённый диалог и возврат к сохранённому значению не создают изменений.
/datum/character_setup/proc/character_state()
	var/static/list/keys = list(
		"real_name", "character_slot_name", "nameless", "age", "gender", "custom_species", "custom_names", "be_random_name",
		"hide_ckey", "custom_blood_color", "blood_color", "prefered_security_department", "preferred_ai_core_display",
		"pda_color", "pda_style", "pda_skin", "pda_ringtone", "pda_theme", "silicon_lawset", "jumpsuit_style",
		"features", "skin_tone", "use_custom_skin_tone", "eye_type", "split_eye_colors", "left_eye_color", "right_eye_color",
		"hair_style", "hair_color", "facial_hair_style", "facial_hair_color", "grad_style", "grad_color",
		"modified_limbs", "organ_mods", "implant_mods", "chosen_limb_id", "body_weight", "scars_list", "bgstate",
		"custom_speech_verb", "custom_speech_verb_ru", "custom_tongue", "custom_laugh", "language",
		"bark_id", "bark_speed", "bark_pitch", "bark_variance", "enable_personal_chat_color", "personal_chat_color",
		"loadout_slot", "loadout_enabled", "loadout_data", "all_quirks", "antag_opt_in_level",
		"phobia_type", "shriek_type", "onelife_death_type", "summon_nickname", "distant_start_enabled", "vore_taste", "vore_smell",
		"security_records", "medical_records", "underwear", "undershirt", "socks", "undie_color", "shirt_color", "socks_color",
		"job_preferences", "joblessrole", "alt_titles_preferences", "persistent_tattoos", "tattoos_string", "pending_tattoo_removals",
		"character_presets", "active_character_preset",
	)
	var/list/state = list("slot" = prefs.default_slot, "species" = prefs.pref_species?.type)
	for(var/key in keys)
		state[key] = prefs.vars[key]
	for(var/list/field in get_feature_fields())
		if(field["scope"] == FEATURE_SCOPE_PREF && field["key"] != "show_mismatched_markings")
			state[field["key"]] = prefs.vars[field["key"]]
	return md5(json_encode(state))

/datum/character_setup/proc/record_saved_state()
	if(prefs)
		saved_character_state = character_state()

// Белый список не позволяет пресету менять внешность, описания и остальные настройки куклы.
/datum/preferences/proc/character_preset_fields()
	var/static/list/fields = list(
		"job_preferences", "joblessrole", "alt_titles_preferences", "prefered_security_department",
		"all_quirks", "phobia_type", "shriek_type", "onelife_death_type", "summon_nickname", "loadout_enabled",
		"organ_mods", "implant_mods", "distant_start_enabled",
	)
	return fields

/datum/preferences/proc/sanitize_character_presets()
	var/list/sanitized = list()
	if(islist(character_presets))
		for(var/preset_name in character_presets)
			if(length(sanitized) >= MAX_CHARACTER_PRESETS)
				break
			if(!istext(preset_name) || !length(trimtext(preset_name)) || length_char(preset_name) > MAX_NAME_LEN)
				continue
			var/list/preset = character_presets[preset_name]
			if(!islist(preset) || !islist(preset["job_preferences"]) || !islist(preset["all_quirks"]) || !islist(preset["loadout"]))
				continue
			var/list/snapshot = list()
			for(var/field in character_preset_fields())
				snapshot[field] = deepCopyList(preset[field])
			snapshot["alt_titles_preferences"] = SANITIZE_LIST(snapshot["alt_titles_preferences"])
			snapshot["loadout"] = deepCopyList(preset["loadout"])
			// Старые пресеты хранят эти модификации в квирках; переносим каждый набор независимо.
			snapshot["organ_mods"] = SANITIZE_LIST(snapshot["organ_mods"])
			snapshot["implant_mods"] = SANITIZE_LIST(snapshot["implant_mods"])
			snapshot["distant_start_enabled"] = sanitize_integer(snapshot["distant_start_enabled"], FALSE, TRUE, TRUE)
			migrate_legacy_body_mods(snapshot["all_quirks"], snapshot["organ_mods"], snapshot["implant_mods"])
			sanitized[preset_name] = snapshot
	character_presets = sanitized
	if(!istext(active_character_preset) || !islist(character_presets[active_character_preset]))
		active_character_preset = null

/datum/preferences/proc/capture_character_preset()
	var/list/snapshot = list()
	for(var/field in character_preset_fields())
		snapshot[field] = deepCopyList(vars[field])
	// Копируем только выбранный комплект; вложенные цвета, матрицы и подписи тоже независимы.
	snapshot["loadout"] = deepCopyList(SANITIZE_LIST(loadout_data["SAVE_[loadout_slot]"]))
	return snapshot

/datum/character_setup/proc/character_preset_error(list/preset, mob/user)
	if(!SSquirks || !length(SSquirks.quirks) || !SSjob?.initialized || !length(GLOB.loadout_items))
		return "Справочники профессий, квирков или экипировки ещё загружаются."
	var/list/quirks = preset["all_quirks"]
	var/positive_count = 0
	for(var/quirk_name in quirks)
		if(!istext(quirk_name))
			return "Список квирков пресета повреждён."
		var/datum/quirk/quirk_datum = SSquirks.quirks[quirk_name]
		if(!quirk_datum)
			return "В пресете есть квирк, которого больше нет: [quirk_name]."
		var/reason = quirk_lock_reason(quirk_name, quirk_datum, quirks)
		if(reason)
			return "Квирк «[quirk_name]» недоступен: [reason]."
		if(initial(quirk_datum.value) > 0)
			positive_count++
	if(positive_count > MAX_QUIRKS)
		return "В пресете больше [MAX_QUIRKS] положительных квирков."
	var/points = available_gear_points(user)
	var/list/seen_gear = list()
	for(var/raw_entry in preset["loadout"])
		if(!islist(raw_entry))
			return "Комплект пресета содержит повреждённую запись."
		var/list/entry = raw_entry
		if(!istext(entry[LOADOUT_ITEM]))
			return "Комплект пресета содержит повреждённый идентификатор предмета."
		var/datum/gear/gear = find_loadout_gear(entry[LOADOUT_ITEM])
		if(!gear)
			return "В комплекте пресета есть предмет, которого больше нет: [entry[LOADOUT_ITEM]]."
		if(gear.type in seen_gear)
			return "В комплекте пресета повторяется предмет «[gear.name]»."
		seen_gear += gear.type
		if(gear.donoritem && !gear.donator_ckey_check(user?.key))
			return "Предмет «[gear.name]» недоступен по уровню поддержки."
		if(istype(gear, /datum/gear/unlockable) && !prefs.can_use_unlockable(gear))
			return "Предмет «[gear.name]» ещё не разблокирован."
		points -= gear.cost
	if(points < 0)
		return "Для комплекта пресета не хватает очков экипировки."
	return null

// Убираем устаревшие и недоступные записи, сохраняя остальную часть пресета.
/datum/character_setup/proc/clean_character_preset(list/preset, mob/user)
	var/list/removed = list()
	var/list/quirks = preset["all_quirks"]
	var/positive_count = 0
	for(var/quirk_name in quirks.Copy())
		var/datum/quirk/quirk_datum = istext(quirk_name) ? SSquirks.quirks[quirk_name] : null
		if(!quirk_datum || quirk_lock_reason(quirk_name, quirk_datum, quirks))
			quirks -= list(quirk_name)
			removed += "[quirk_name]"
			continue
		if(initial(quirk_datum.value) > 0 && ++positive_count > MAX_QUIRKS)
			quirks -= quirk_name
			removed += quirk_name
	var/list/clean_loadout = list()
	var/list/seen_gear = list()
	var/points = available_gear_points(user)
	for(var/raw_entry in preset["loadout"])
		var/list/entry = islist(raw_entry) ? raw_entry : null
		var/datum/gear/gear = entry && istext(entry[LOADOUT_ITEM]) ? find_loadout_gear(entry[LOADOUT_ITEM]) : null
		if(!gear)
			removed += "предмет [entry ? entry[LOADOUT_ITEM] : "без идентификатора"]"
			continue
		if((gear.type in seen_gear) || (gear.donoritem && !gear.donator_ckey_check(user?.key)) || (istype(gear, /datum/gear/unlockable) && !prefs.can_use_unlockable(gear)) || gear.cost > points)
			removed += gear.name
			continue
		points -= gear.cost
		seen_gear += gear.type
		clean_loadout += list(entry)
	preset["loadout"] = clean_loadout
	var/list/jobs = preset["job_preferences"]
	for(var/job_title in jobs.Copy())
		if(!istext(job_title) || !SSjob.GetJob(job_title))
			jobs -= list(job_title)
			removed += "профессия [job_title]"
	return removed

/datum/character_setup/proc/manage_character_preset(action, list/params, mob/user)
	var/slot = prefs.default_slot
	var/revision = character_revision
	var/preset_name = params["name"]
	var/list/preset = istext(preset_name) ? prefs.character_presets[preset_name] : null
	if(action == "preset_select")
		if(islist(preset))
			selected_character_preset = preset_name
		return
	if(action == "preset_create" || action == "preset_rename")
		if(action == "preset_rename" && !islist(preset))
			return
		if(action == "preset_create" && length(prefs.character_presets) >= MAX_CHARACTER_PRESETS)
			save_notice = "У персонажа уже есть [MAX_CHARACTER_PRESETS] пресетов."
			return
		var/new_name = tgui_input_text(user, "Название пресета персонажа:", "Пресеты", action == "preset_rename" ? preset_name : null, MAX_NAME_LEN)
		// Пока открыт диалог, другое окно могло переключить персонажа или применить пресет.
		if(QDELETED(src) || !prefs || user?.client?.prefs != prefs || prefs.default_slot != slot || character_revision != revision || isnull(new_name))
			return
		new_name = trimtext(strip_control_chars(new_name))
		if(!length(new_name) || length_char(new_name) > MAX_NAME_LEN)
			return
		if(new_name == preset_name && action == "preset_rename")
			return
		if(new_name in prefs.character_presets)
			save_notice = "Пресет «[new_name]» уже существует."
			return
		if(action == "preset_create")
			if(length(prefs.character_presets) >= MAX_CHARACTER_PRESETS)
				return
			prefs.character_presets[new_name] = prefs.capture_character_preset()
			activate_character_preset_loadout(new_name, prefs.character_presets[new_name])
		else
			if(prefs.character_presets[preset_name] != preset)
				return
			prefs.character_presets[new_name] = preset
			prefs.character_presets -= preset_name
			if(prefs.active_character_preset == preset_name)
				prefs.active_character_preset = new_name
		selected_character_preset = new_name
		save_notice = "Пресет «[new_name]» [action == "preset_create" ? "создан" : "переименован"]. Нажмите «Сохранить», чтобы записать персонажа."
		return
	if(!islist(preset))
		return
	switch(action)
		if("preset_save")
			prefs.character_presets[preset_name] = prefs.capture_character_preset()
			activate_character_preset_loadout(preset_name, prefs.character_presets[preset_name])
			save_notice = "Пресет «[preset_name]» обновлён из текущих настроек. Нажмите «Сохранить», чтобы записать персонажа."
		if("preset_delete")
			prefs.character_presets -= preset_name
			if(prefs.active_character_preset == preset_name)
				prefs.active_character_preset = null
			selected_character_preset = null
			save_notice = "Пресет «[preset_name]» удалён. Текущие настройки персонажа оставлены без изменений."
		if("preset_apply")
			if(!length(SSquirks?.quirks) || !SSjob?.initialized || !length(GLOB.loadout_items))
				save_notice = "Справочники профессий, квирков или экипировки ещё загружаются."
				return
			preset = deepCopyList(preset)
			var/list/removed = clean_character_preset(preset, user)
			var/error = character_preset_error(preset, user)
			if(error)
				save_notice = "Пресет не применён: [error]"
				return
			// Сначала проверяем весь пресет и лишь затем меняем настройки: частичного применения нет.
			for(var/field in prefs.character_preset_fields())
				prefs.vars[field] = deepCopyList(preset[field])
			prefs.joblessrole = sanitize_inlist(prefs.joblessrole, list(RETURNTOLOBBY, BEOVERFLOW, BERANDOMJOB), RETURNTOLOBBY)
			prefs.loadout_enabled = sanitize_integer(prefs.loadout_enabled, FALSE, TRUE, TRUE)
			prefs.sanitize_body_mods()
			prefs.distant_start_enabled = sanitize_integer(prefs.distant_start_enabled, FALSE, TRUE, TRUE)
			prefs.prefered_security_department = sanitize_inlist(prefs.prefered_security_department, GLOB.security_depts_prefs, SEC_DEPT_RANDOM)
			prefs.shriek_type = sanitize_inlist(prefs.shriek_type, GLOB.shriek_types, SHRIEK_TYPE_GENERIC)
			prefs.onelife_death_type = sanitize_inlist(prefs.onelife_death_type, GLOB.onelife_death_forms, "Пепел")
			if(SStraumas)
				prefs.phobia_type = SStraumas.sanitize_phobia_type(prefs.phobia_type)
			prefs.character_presets[preset_name] = preset
			activate_character_preset_loadout(preset_name, preset)
			if(prefs.job_menu)
				prefs.job_menu.previews.Cut()
				prefs.job_menu.pushed_preview = null
				SStgui.update_uis(prefs.job_menu)
			save_notice = "Применён пресет «[preset_name]». Используется отдельный комплект «Пресет»."
			if(length(removed))
				save_notice += " Отключены недоступные записи: [jointext(removed, ", ")]."
			if(quirk_balance() < 0)
				save_notice += " Не хватает очков особенностей: скорректируйте их набор или модификации перед входом в раунд."

/datum/character_setup/proc/activate_character_preset_loadout(preset_name, list/preset)
	prefs.loadout_data["SAVE_[LOADOUT_PRESET_SLOT]"] = deepCopyList(preset["loadout"])
	prefs.loadout_slot = LOADOUT_PRESET_SLOT
	prefs.active_character_preset = preset_name
	selected_character_preset = preset_name
	if(prefs.loadout_color_handler)
		SStgui.close_uis(prefs.loadout_color_handler)
		QDEL_NULL(prefs.loadout_color_handler)
	character_revision++
	preview_dirty = TRUE

/datum/preferences/proc/open_character_setup(mob/user)
	if(QDELETED(character_setup_ui))
		character_setup_ui = new(src)
	character_setup_ui.ui_interact(user)

// Большинство игроков открывает редактор: справочники готовим после входа, без создания манекена.
/datum/preferences/proc/prewarm_character_setup()
	if(!parent || QDELETED(parent))
		return
	if(!SSjob.initialized || !SSlanguage.initialized)
		addtimer(CALLBACK(src, PROC_REF(prewarm_character_setup)), 2 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
		return
	if(QDELETED(character_setup_ui))
		character_setup_ui = new(src)
	character_setup_ui.prewarm()
	character_setup_ui.heavy_static_ready = TRUE

// Единый список стилей окна.
/datum/preferences/proc/setup_theme_options()
	var/static/list/themes = list(
		"default" = "Стандарт", "kpk" = "КПК", "terminal" = "Терминал",
		"syndie" = "Синдикат", "cat" = "Котик", "synth" = "Синт", "hotpink" = "Фуксия",
		"hackerman" = "Хакер", "malfunction" = "Сбой", "heretic" = "Еретик",
		"wizard" = "Волшебник", "darkmode" = "Графит", "pact" = "Пакт",
		"abductor" = "Абдуктор", "neutral" = "Янтарь", "inteq" = "Охра",
		"chat" = "Чат", "chat_pink" = "Розовый", "chat_violet" = "Фиолет",
		"chat_green" = "Зелёный", "chat_amber" = "Янтарный",
	)
	return themes

/datum/preferences/proc/valid_setup_theme(theme)
	return (theme in setup_theme_options())

/datum/character_setup/ui_state(mob/user)
	return GLOB.always_state

/datum/character_setup/ui_status(mob/user, datum/ui_state/state)
	. = ..()
	if(. <= UI_DISABLED)
		return
	if(!user?.client || !prefs || user.client.prefs != prefs)
		return UI_CLOSE
	return .

/datum/character_setup/ui_assets()
	. = ..() || list()
	. += get_asset_datum(/datum/asset/spritesheet_batched/jobs)

/datum/character_setup/ui_close(mob/user)
	var/atom/movable/screen/map_view/character_setup_screen/viewer_screen = LAZYACCESS(viewer_screens, user)
	LAZYREMOVE(viewer_screens, user)
	qdel(viewer_screen)
	if(!length(viewer_screens))
		stop_sound_preview()

/datum/character_setup/ui_interact(mob/user, datum/tgui/ui)
	var/atom/movable/screen/map_view/character_setup_screen/viewer_screen = LAZYACCESS(viewer_screens, user)
	if(!viewer_screen)
		viewer_screen = new
		viewer_screen.generate_view("character_setup_[REF(src)]_[REF(user)]_map")
		LAZYSET(viewer_screens, user, viewer_screen)
		preview_dirty = TRUE
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, CHARACTER_SETUP_INTERFACE, "Создание персонажа")
		ui.open()
	// Справочники отправляем отдельно; повторное открытие использует уже готовый кэш.
	if(!heavy_static_ready && !heavy_static_pending)
		heavy_static_pending = TRUE
		addtimer(CALLBACK(src, PROC_REF(push_heavy_static)), 0.1 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
	ui.set_autoupdate(FALSE)

/datum/character_setup/ui_static_data(mob/user, datum/tgui/ui, datum/ui_state/state)
	var/list/data = list()
	if(!prefs)
		return data

	data["tabs"] = build_tabs_data()
	data["maxSlots"] = prefs.max_save_slots
	data["previewModes"] = list(PREVIEW_PREF_JOB, PREVIEW_PREF_LOADOUT, PREVIEW_PREF_NAKED)
	data["ageMin"] = AGE_MIN
	data["ageMax"] = AGE_MAX_INPUT
	data["quirksEnabled"] = !!CONFIG_GET(flag/roundstart_traits)
	data["siliconLawsDisabled"] = !CONFIG_GET(flag/allow_silicon_choosing_laws)
	if(heavy_static_ready)
		data["featureFields"] = get_feature_fields()
		data["options"] = build_options_static()
		data["mutantPartLabels"] = build_mutant_labels()
		data["markingOptions"] = build_marking_options_data()
		data["languageIcons"] = build_language_icons()
	return data

// Статика принадлежит окну, а не одноразовому флагу в ui_data(): её не потеряет соседнее обновление.
/datum/character_setup/proc/push_heavy_static()
	if(!heavy_static_ready)
		prewarm()
		heavy_static_ready = TRUE
	update_static_data_for_all_viewers(ignore_cooldown = TRUE)
	for(var/datum/tgui/ui as anything in SStgui.get_all_open_uis(src))
		if(!ui.initialized)
			// При холодной загрузке браузер ещё не принимает обновления; справочники не должны потеряться.
			addtimer(CALLBACK(src, PROC_REF(push_heavy_static)), 0.1 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
			return
	heavy_static_pending = FALSE

// Справочники строятся по требованию. Манекен до готовности нативной карты не создаём.
/datum/character_setup/proc/prewarm()
	if(!prefs)
		return
	get_feature_fields()
	build_options_static()
	build_mutant_labels()
	build_marking_options_data()
	build_language_icons()

/datum/character_setup/proc/build_mutant_labels()
	if(mutant_labels_cache)
		return mutant_labels_cache
	var/list/part_labels = list()
	for(var/part in GLOB.all_mutant_parts)
		if(part != "mam_body_markings")
			part_labels[part] = ru_strings["[part]"] || GLOB.all_mutant_parts[part] || part
	mutant_labels_cache = part_labels
	return mutant_labels_cache

/datum/character_setup/proc/get_feature_fields()
	if(!feature_field_cache)
		feature_field_cache = build_feature_descriptors()
	return feature_field_cache

/datum/character_setup/proc/build_feature_descriptors()
	var/list/fields = list()

	var/list/consent_cycle = list("Yes" = "Да", "Ask" = "Спросить", "No" = "Нет")
	var/list/consent_binary = list("Yes" = "Да", "No" = "Нет")

	fields += list(ff("show_mismatched_markings", "Чужие части и маркинги", FEATURE_BOOL, FEATURE_SCOPE_PREF, FEATURE_MISMATCH_HINT))
	fields += list(ff("allow_emissives", "Разрешить свечение", FEATURE_BOOL, FEATURE_SCOPE_FEATURE, "Общий переключатель свечения глаз, частей тела, гениталий и маркингов. Отдельные элементы включаются кнопками с лампочкой."))
	fields += list(ff("be_random_body", "Всегда случайное тело", FEATURE_BOOL, FEATURE_SCOPE_PREF))

	fields += list(color_ff("mcolor", "Основной цвет тела", FEATURE_COLOR_MUTANT))
	fields += list(color_ff("mcolor2", "Вторичный цвет тела", FEATURE_COLOR_MUTANT))
	fields += list(color_ff("mcolor3", "Третичный цвет тела", FEATURE_COLOR_MUTANT))
	fields += list(ff("genitals_use_skintone", "Гениталии в цвет кожи", FEATURE_BOOL))

	var/list/body_size_field = num_ff("body_size", "Размер тела, %", CONFIG_GET(number/body_size_min) * 100, CONFIG_GET(number/body_size_max) * 100)
	body_size_field["scale"] = 100
	fields += list(body_size_field)
	var/list/norm_field = num_ff("normalized_size", "Нормализованный размер, %", max(CONFIG_GET(number/body_size_min), 0.81) * 100, min(CONFIG_GET(number/body_size_max), 1.2) * 100)
	norm_field["scale"] = 100
	fields += list(norm_field)
	fields += list(ff("fuzzy", "Размытые пиксели", FEATURE_BOOL, FEATURE_SCOPE_PREF))

	fields += list(ff("split_eye_colors", "Гетерохромия", FEATURE_BOOL, FEATURE_SCOPE_PREF, FEATURE_HETEROCHROMIA_HINT))
	fields += list(color_ff("left_eye_color", "Цвет левого глаза", FEATURE_COLOR_PLAIN, FEATURE_SCOPE_PREF))
	fields += list(color_ff("right_eye_color", "Цвет правого глаза", FEATURE_COLOR_PLAIN, FEATURE_SCOPE_PREF))

	fields += list(color_ff("hair_color", "Цвет волос", FEATURE_COLOR_PLAIN, FEATURE_SCOPE_PREF))
	fields += list(color_ff("facial_hair_color", "Цвет бороды", FEATURE_COLOR_PLAIN, FEATURE_SCOPE_PREF))
	fields += list(color_ff("grad_color", "Цвет градиента", FEATURE_COLOR_PLAIN, FEATURE_SCOPE_PREF))

	var/list/backbag_options = list()
	for(var/option in GLOB.backbaglist)
		backbag_options += "[option]"
	fields += list(list_ff("backbag", "Рюкзак", backbag_options, FEATURE_SCOPE_PREF))
	fields += list(list_ff("uplink_spawn_loc", "Место аплинка", GLOB.uplink_spawn_loc_list, FEATURE_SCOPE_PREF))
	fields += list(ff("persistent_scars", "Постоянные шрамы", FEATURE_BOOL, FEATURE_SCOPE_PREF))

	fields += list(cycle_ff("erppref", "ERP", consent_cycle, FEATURE_ERP_HINT))
	fields += list(cycle_ff("nonconpref", "Non-Con", consent_cycle, FEATURE_NONCON_HINT))
	fields += list(cycle_ff("vorepref", "Vore", consent_cycle, FEATURE_VORE_HINT))
	fields += list(cycle_ff("mobsexpref", "Mob Non-Con Sex", consent_binary, FEATURE_MOBSEX_HINT))
	fields += list(cycle_ff("tattoopref", "Tattoo", consent_cycle, FEATURE_TATTOO_HINT))
	fields += list(cycle_ff("unholypref", "Unholy", consent_cycle, FEATURE_UNHOLY_HINT))
	fields += list(cycle_ff("unholyhardpref", "Unholy Hard", consent_cycle, FEATURE_UNHOLY_HARD_HINT))
	fields += list(cycle_ff("extremepref", "Extreme", consent_cycle, FEATURE_EXTREME_HINT))
	fields += list(cycle_ff("extremeharm", "Extreme Harm", consent_binary, FEATURE_EXTREME_HARM_HINT))

	var/list/lust_limits = list(25, 200)
	fields += list(num_ff("lust_tolerance", "Сексуальная чувствительность", lust_limits[1], lust_limits[2], FEATURE_SCOPE_PREF))
	var/list/potency_limits = list(-1, 25)
	fields += list(num_ff("sexual_potency", "Сексуальная потенция", potency_limits[1], potency_limits[2], FEATURE_SCOPE_PREF))

	fields += list(num_ff("virility", "Шанс оплодотворения, %", 0, 100, FEATURE_SCOPE_PREF))
	fields += list(num_ff("fertility", "Шанс забеременеть, %", 0, 100, FEATURE_SCOPE_PREF))
	fields += list(ff("inert_eggs", "Откладывать неоплодотворённые яйца", FEATURE_BOOL))
	fields += list(ff("pregnancy_inflation", "Увеличение живота при беременности", FEATURE_BOOL, FEATURE_SCOPE_PREF))
	fields += list(ff("pregnancy_breast_growth", "Рост груди при беременности", FEATURE_BOOL, FEATURE_SCOPE_PREF))
	fields += list(list_ff("egg_shell", "Вид яйца", GLOB.egg_skins, FEATURE_SCOPE_PREF))

	var/list/visibility_options = CONFIG_GET(str_list/safe_visibility_toggles)
	var/list/breast_cups = list()
	for(var/cup_name in CONFIG_GET(keyed_list/breasts_cups_prefs))
		breast_cups += cup_name

	fields += list(ff("has_cock", "Иметь пенис", FEATURE_BOOL))
	fields += list(color_ff("cock_color", "Цвет пениса", FEATURE_COLOR_LIMITED))
	fields += list(num_ff("cock_length", "Длина пениса, см", CONFIG_GET(number/penis_min_inches_prefs), CONFIG_GET(number/penis_max_inches_prefs)))
	var/list/cock_max_field = num_ff("cock_max_length", "Максимальная длина, см", 0, CONFIG_GET(number/penis_max_inches_prefs))
	cock_max_field["deletable"] = TRUE
	cock_max_field["clampTo"] = "cock_length"
	cock_max_field["clampAbove"] = TRUE
	fields += list(cock_max_field)
	var/list/cock_min_field = num_ff("cock_min_length", "Минимальная длина, см", 0, CONFIG_GET(number/penis_max_inches_prefs))
	cock_min_field["deletable"] = TRUE
	cock_min_field["clampTo"] = "cock_length"
	cock_min_field["clampBelow"] = TRUE
	fields += list(cock_min_field)
	var/list/cock_ratio_field = num_ff("cock_diameter_ratio", "Коэффициент диаметра", CONFIG_GET(number/diameter_ratio_min_size_prefs), CONFIG_GET(number/diameter_ratio_max_size_prefs), FEATURE_SCOPE_FEATURE, FEATURE_SPRITE_SCALE_HINT)
	cock_ratio_field["step"] = 0.01
	fields += list(cock_ratio_field)
	fields += list(list_ff("cock_visibility", "Видимость пениса", visibility_options))
	fields += list(ff("cock_accessible", "Пенис всегда доступен", FEATURE_BOOL))
	fields += list(ff("cock_stuffing", "Игрушки и пополнение", FEATURE_BOOL))

	fields += list(ff("has_balls", "Иметь яички", FEATURE_BOOL))
	fields += list(color_ff("balls_color", "Цвет яичек", FEATURE_COLOR_LIMITED))
	fields += list(list_ff("balls_shape", "Форма яичек", genital_shape_options(GLOB.balls_shapes_list)))
	fields += list(num_ff("balls_size", "Размер яичек", BALLS_SIZE_MIN, BALLS_SIZE_MAX))
	fields += list(list_ff("balls_visibility", "Видимость яичек", visibility_options))
	fields += list(ff("balls_accessible", "Яички всегда доступны", FEATURE_BOOL))
	fields += list(ff("balls_stuffing", "Игрушки и пополнение", FEATURE_BOOL))
	var/list/balls_max_field = num_ff("balls_max_size", "Максимальный размер", 0, BALLS_SIZE_MAX, FEATURE_SCOPE_FEATURE, FEATURE_GENITAL_SIZE_HINT)
	balls_max_field["deletable"] = TRUE
	fields += list(balls_max_field)
	var/list/balls_min_field = num_ff("balls_min_size", "Минимальный размер", 0, BALLS_SIZE_MAX, FEATURE_SCOPE_FEATURE, FEATURE_GENITAL_SIZE_HINT)
	balls_min_field["deletable"] = TRUE
	fields += list(balls_min_field)
	fields += list(reagent_ff("balls_fluid", "Произведено", genital_fluid_options(/datum/reagent/consumable/semen)))
	var/list/cum_max_field = num_ff("balls_cum_max", "Макс. объём выделений", 1, 150, FEATURE_SCOPE_FEATURE, FEATURE_CUM_MAX_HINT)
	cum_max_field["deletable"] = TRUE
	cum_max_field["zeroLabel"] = "По умолчанию"
	fields += list(cum_max_field)
	var/list/cum_rate_field = num_ff("balls_cum_rate", "Скорость восстановления", 0.1, 20, FEATURE_SCOPE_FEATURE, FEATURE_CUM_RATE_HINT)
	cum_rate_field["step"] = 0.1
	fields += list(cum_rate_field)

	fields += list(ff("has_vag", "Иметь влагалище", FEATURE_BOOL))
	fields += list(list_ff("vag_shape", "Форма влагалища", genital_shape_options(GLOB.vagina_shapes_list)))
	fields += list(color_ff("vag_color", "Цвет влагалища", FEATURE_COLOR_LIMITED))
	fields += list(list_ff("vag_visibility", "Видимость влагалища", visibility_options))
	fields += list(ff("vag_accessible", "Влагалище всегда доступно", FEATURE_BOOL))
	fields += list(ff("vag_stuffing", "Игрушки и пополнение", FEATURE_BOOL))
	fields += list(ff("has_womb", "Иметь матку", FEATURE_BOOL))
	fields += list(reagent_ff("womb_fluid", "Произведено", genital_fluid_options(/datum/reagent/consumable/semen/femcum)))

	fields += list(ff("has_breasts", "Иметь грудь", FEATURE_BOOL))
	fields += list(color_ff("breasts_color", "Цвет груди", FEATURE_COLOR_LIMITED))
	fields += list(list_ff("breasts_sprite_variant", "Вариант груди", list("New" = "Новый", "Old" = "Старый")))
	fields += list(ff("breasts_nipples", "Цветные соски", FEATURE_BOOL))
	fields += list(color_ff("breasts_nipples_color", "Цвет сосков", FEATURE_COLOR_LIMITED))
	fields += list(list_ff("breasts_size", "Размер чашечки", breast_cups))
	fields += list(list_ff("breasts_shape", "Форма груди", genital_shape_options(GLOB.breasts_shapes_list)))
	fields += list(list_ff("breasts_visibility", "Видимость груди", visibility_options))
	fields += list(ff("breasts_producing", "Лактирует", FEATURE_BOOL))
	fields += list(ff("breasts_stuffing", "Игрушки и пополнение", FEATURE_BOOL))
	var/list/breast_limits = genital_shape_options(GLOB.breast_values)
	var/list/breasts_max_field = list_ff("breasts_max_size", "Максимальный размер", breast_limits, FEATURE_SCOPE_FEATURE, FEATURE_GENITAL_SIZE_HINT)
	breasts_max_field["deletable"] = TRUE
	breasts_max_field["zeroLabel"] = "Отключено"
	fields += list(breasts_max_field)
	var/list/breasts_min_field = list_ff("breasts_min_size", "Минимальный размер", breast_limits, FEATURE_SCOPE_FEATURE, FEATURE_GENITAL_SIZE_HINT)
	breasts_min_field["deletable"] = TRUE
	breasts_min_field["zeroLabel"] = "Отключено"
	fields += list(breasts_min_field)
	fields += list(reagent_ff("breasts_fluid", "Произведено", genital_fluid_options(/datum/reagent/consumable/milk)))

	fields += list(ff("has_butt", "Иметь попу", FEATURE_BOOL))
	fields += list(color_ff("butt_color", "Цвет попы", FEATURE_COLOR_LIMITED))
	fields += list(num_ff("butt_size", "Размер попы", CONFIG_GET(number/butt_min_size_prefs), CONFIG_GET(number/butt_max_size_prefs)))
	fields += list(list_ff("butt_visibility", "Видимость попы", visibility_options))
	fields += list(ff("butt_accessible", "Попа всегда доступна", FEATURE_BOOL))
	fields += list(ff("butt_stuffing", "Игрушки и пополнение", FEATURE_BOOL))
	var/list/butt_max_field = num_ff("butt_max_size", "Максимальный размер", 0, CONFIG_GET(number/butt_max_size_prefs), FEATURE_SCOPE_FEATURE, FEATURE_GENITAL_SIZE_HINT)
	butt_max_field["deletable"] = TRUE
	butt_max_field["clampTo"] = "butt_size"
	butt_max_field["clampAbove"] = TRUE
	fields += list(butt_max_field)
	var/list/butt_min_field = num_ff("butt_min_size", "Минимальный размер", 0, CONFIG_GET(number/butt_max_size_prefs), FEATURE_SCOPE_FEATURE, FEATURE_GENITAL_SIZE_HINT)
	butt_min_field["deletable"] = TRUE
	butt_min_field["clampTo"] = "butt_size"
	butt_min_field["clampBelow"] = TRUE
	fields += list(butt_min_field)
	fields += list(ff("has_anus", "Иметь анус", FEATURE_BOOL))
	fields += list(color_ff("anus_color", "Цвет ануса", FEATURE_COLOR_LIMITED))
	fields += list(list_ff("anus_shape", "Форма ануса", genital_shape_options(GLOB.anus_shapes_list)))
	fields += list(list_ff("anus_visibility", "Видимость ануса", visibility_options))
	fields += list(ff("anus_accessible", "Анус всегда доступен", FEATURE_BOOL))
	fields += list(ff("anus_stuffing", "Игрушки и пополнение", FEATURE_BOOL))

	fields += list(ff("has_belly", "Иметь живот", FEATURE_BOOL))
	fields += list(color_ff("belly_color", "Цвет живота", FEATURE_COLOR_LIMITED))
	fields += list(num_ff("belly_size", "Размер живота", CONFIG_GET(number/belly_min_size_prefs), CONFIG_GET(number/belly_max_size_prefs)))
	var/list/belly_max_field = num_ff("belly_max_size", "Максимальный размер", 0, CONFIG_GET(number/belly_max_size_prefs), FEATURE_SCOPE_FEATURE, FEATURE_GENITAL_SIZE_HINT)
	belly_max_field["deletable"] = TRUE
	belly_max_field["clampTo"] = "belly_size"
	belly_max_field["clampAbove"] = TRUE
	fields += list(belly_max_field)
	var/list/belly_min_field = num_ff("belly_min_size", "Минимальный размер", 0, CONFIG_GET(number/belly_max_size_prefs), FEATURE_SCOPE_FEATURE, FEATURE_GENITAL_SIZE_HINT)
	belly_min_field["deletable"] = TRUE
	belly_min_field["clampTo"] = "belly_size"
	belly_min_field["clampBelow"] = TRUE
	fields += list(belly_min_field)
	fields += list(list_ff("belly_visibility", "Видимость живота", visibility_options))
	fields += list(ff("belly_stuffing", "Игрушки и пополнение", FEATURE_BOOL))
	fields += list(ff("belly_accessible", "Живот всегда доступен", FEATURE_BOOL))

	fields += list(ff("neckfire", "Иметь огонь шеи", FEATURE_BOOL))
	fields += list(color_ff("neckfire_color", "Цвет огня", FEATURE_COLOR_LIMITED))

	return fields

/datum/character_setup/proc/ff(key, label, type, scope = FEATURE_SCOPE_FEATURE, hint)
	var/list/field = list(
		"key" = key,
		"label" = label,
		"type" = type,
		"scope" = scope,
	)
	if(hint)
		field["hint"] = hint
	return field

/datum/character_setup/proc/color_ff(key, label, flavor, scope = FEATURE_SCOPE_FEATURE)
	var/list/field = ff(key, label, FEATURE_COLOR, scope)
	field["colorCheck"] = flavor
	return field

/datum/character_setup/proc/num_ff(key, label, min_value, max_value, scope = FEATURE_SCOPE_FEATURE, hint)
	var/list/field = ff(key, label, FEATURE_NUM, scope, hint)
	field["min"] = min_value
	field["max"] = max_value
	return field

/datum/character_setup/proc/list_ff(key, label, options, scope = FEATURE_SCOPE_FEATURE, hint)
	var/list/field = ff(key, label, FEATURE_LIST, scope, hint)
	field["options"] = options
	return field

/datum/character_setup/proc/reagent_ff(key, label, options, scope = FEATURE_SCOPE_FEATURE, hint)
	var/list/field = ff(key, label, FEATURE_REAGENT, scope, hint)
	field["options"] = options
	return field

/datum/character_setup/proc/cycle_ff(key, label, cycle, hint)
	var/list/field = ff(key, label, FEATURE_CYCLE, FEATURE_SCOPE_PREF, hint)
	field["options"] = cycle
	return field

/datum/character_setup/proc/build_appearance_data(mob/user, full = TRUE)
	var/list/data = list()
	var/datum/species/species = prefs.pref_species
	if(!species)
		return data

	data["values"] = build_feature_values()

	if(prefs.left_eye_color != prefs.right_eye_color)
		prefs.split_eye_colors = TRUE
	if(length(species.allowed_limb_ids) && (!prefs.chosen_limb_id || !(prefs.chosen_limb_id in species.allowed_limb_ids)))
		prefs.chosen_limb_id = species.limbs_id || species.id
	data["hasPuddleSlime"] = (species.type == /datum/species/jelly/roundstartslime)
	data["puddleSlime"] = !!prefs.features["puddle_slime_fea"]
	data["hasScars"] = (HAS_FLESH in species.species_traits) || (HAS_BONE in species.species_traits)
	data["jumpsuitStyle"] = prefs.jumpsuit_style
	data["jumpsuitStyles"] = list(PREF_SUIT = "Комбинезон", PREF_SKIRT = "Юбка")
	data["antagOptIn"] = build_antag_opt_in_data()

	// срезаю часть меню, чтобы оно рендерилось только при открытии.
	if(!full)
		return data

	data["gender"] = prefs.gender
	data["genderOptions"] = list(MALE = "Мужской", FEMALE = "Женский", PLURAL = "Небинарный", NEUTER = "Объект")
	data["bodyModel"] = prefs.features["body_model"]
	data["bodyModelOptions"] = list(MALE = "Маскулинное", FEMALE = "Фемининное")
	data["speciesSexes"] = !!species.sexes
	data["species"] = species.name
	var/list/species_names = list()
	for(var/species_name in GLOB.roundstart_race_names)
		species_names += species_name
	data["speciesList"] = species_names
	data["customSpecies"] = prefs.custom_species
	data["advancedColors"] = (prefs.features["color_scheme"] == ADVANCED_CHARACTER_COLORING)

	data["useSkintones"] = !!species.use_skintones
	data["skinTone"] = prefs.skin_tone
	data["useCustomSkinTone"] = !!prefs.use_custom_skin_tone
	data["skinToneOptions"] = skin_tone_options()
	data["skinToneCustom"] = !!CONFIG_GET(flag/allow_custom_skintones)
	data["hasMutantColors"] = (MUTCOLORS in species.species_traits) || (MUTCOLORS_PARTSONLY in species.species_traits)

	data["hasEyes"] = !(NOEYES in species.species_traits)
	data["hasEyecolor"] = (EYECOLOR in species.species_traits)
	data["eyeType"] = prefs.eye_type
	data["eyeTypes"] = GLOB.eye_types.Copy()
	data["eyesGlow"] = emissive_part_enabled(prefs.features, "eyes")

	data["hasHair"] = (HAIR in species.species_traits)
	data["hairStyle"] = prefs.hair_style
	data["facialHairStyle"] = prefs.facial_hair_style
	data["gradStyle"] = prefs.grad_style
	data["hairOptions"] = list(
		"hair" = hair_style_options(GLOB.hair_styles_list, user?.ckey),
		"facial" = hair_style_options(GLOB.facial_hair_styles_list, user?.ckey),
		"grad" = hair_style_options(GLOB.hair_gradients_list, user?.ckey),
	)

	data["mutantParts"] = build_mutant_parts_data(user)

	data["genitals"] = build_genitals_data()

	data["bodySprite"] = prefs.chosen_limb_id
	data["bodySprites"] = species.allowed_limb_ids ? species.allowed_limb_ids.Copy() : list()

	var/weight_locked = !!prefs.all_quirks.Find(/datum/quirk/bluemoon_devourer::name)
	data["bodyWeight"] = weight_locked ? NAME_WEIGHT_NORMAL : prefs.body_weight
	data["weightOptions"] = GLOB.mob_sizes
	data["weightLocked"] = weight_locked

	return data

/datum/character_setup/proc/build_feature_values()
	var/list/values = list()
	for(var/list/field in get_feature_fields())
		var/value = read_feature_value(field)
		if(!isnull(value))
			values[field["key"]] = value
	return values

/datum/character_setup/proc/read_feature_value(list/field)
	var/key = field["key"]
	var/raw
	if(field["scope"] == FEATURE_SCOPE_PREF)
		if(!(key in prefs.vars))
			return null
		raw = prefs.vars[key]
	else
		var/list/feats = prefs.features
		raw = feats ? feats[key] : null

	if(isnull(raw))
		return null
	if(field["type"] == FEATURE_NUM)
		if(!isnum(raw))
			return null
		return raw * (field["scale"] || 1)
	if(field["type"] == FEATURE_COLOR)
		return color_to_ui(raw)
	if(field["type"] == FEATURE_REAGENT)
		return "[raw]"
	return raw

/datum/character_setup/proc/color_to_ui(value)
	if(!istext(value) || !length(value))
		return null
	var/hex = value[1] == "#" ? copytext(value, 2) : value
	if(length(hex) == 3)
		hex = "[copytext(hex, 1, 2)][copytext(hex, 1, 2)][copytext(hex, 2, 3)][copytext(hex, 2, 3)][copytext(hex, 3, 4)][copytext(hex, 3, 4)]"
	if(length(hex) != 6)
		return null
	return "#[hex]"

/datum/character_setup/proc/read_feature_raw(key, scope)
	if(scope == FEATURE_SCOPE_PREF)
		return (key in prefs.vars) ? prefs.vars[key] : null
	var/list/feats = prefs.features
	return feats ? feats[key] : null

/datum/character_setup/proc/mutant_part_options(part, for_cycle = FALSE)
	var/list/options = list()
	var/list/reference = mutant_part_reference_list(part)
	if(!reference || !prefs.parent)
		return options

	if(!mutant_part_needs_species_filter(part))
		var/list/filtered = prefs.filter_accessories_by_ckey(reference, prefs.parent.ckey)
		for(var/option_name in filtered)
			options += option_name
		return options

	var/needs_species_filter = !prefs.show_mismatched_markings
	for(var/option_name in reference)
		var/datum/sprite_accessory/accessory = reference[option_name]
		if(!istype(accessory))
			continue
		if(needs_species_filter && accessory.recommended_species && !accessory.recommended_species.Find(prefs.pref_species.id))
			continue
		// Пасхалка: Как в старом редакторе, стрелки обходят ignore, а меню скрывает такие варианты.
		if(part == "taur" && accessory.ignore && !for_cycle)
			continue
		if(!accessory.is_allowed_for(prefs.parent.ckey))
			continue
		options += option_name
	return options

/datum/character_setup/proc/mutant_part_needs_species_filter(part)
	switch(part)
		if("ipc_antenna", "tail_human", "mam_tail", "snout", "mam_snouts", "taur", "ears", "mam_ears")
			return TRUE
	return FALSE

/datum/character_setup/proc/mutant_part_reference_list(part)
	if(part == "wings")
		return GLOB.r_wings_list
	var/list/reference = GLOB.mutant_reference_list[part]
	if(reference)
		return reference
	if(part == "meat_type")
		return GLOB.meat_types
	return null

/datum/character_setup/proc/genital_shape_options(list/reference)
	var/list/options = list()
	for(var/option_name in reference)
		options += option_name
	return options

/datum/character_setup/proc/genital_fluid_options(preferred_type)
	var/list/options = list()
	var/datum/reagent/lead = find_reagent_object_from_type(preferred_type)
	for(var/datum/reagent/fluid in GLOB.genital_fluids_list)
		if(lead && fluid.type == lead.type)
			continue
		options += list(list("name" = fluid.name, "type" = "[fluid.type]"))
	if(!lead)
		return options
	var/list/headed = list(list("name" = lead.name, "type" = "[lead.type]"))
	headed += options
	return headed

/datum/character_setup/proc/cock_taur_shapes()
	var/list/shapes = list()
	var/list/feats = prefs.features
	if(!prefs.parent?.can_have_part("taur"))
		return shapes
	var/datum/sprite_accessory/taur/taur_part = GLOB.taur_list[feats["taur"]]
	if(!taur_part)
		return shapes
	for(var/shape_name in GLOB.cock_shapes_list)
		var/datum/sprite_accessory/penis/penis_part = GLOB.cock_shapes_list[shape_name]
		if(!istype(penis_part))
			continue
		if(!penis_part.taur_icon)
			continue
		if(taur_part.taur_mode & penis_part.accepted_taurs)
			shapes["[shape_name] (Taur)"] = shape_name
	return shapes

/datum/character_setup/proc/build_cock_shape_data()
	var/list/feats = prefs.features
	var/list/options = genital_shape_options(GLOB.cock_shapes_list)
	var/list/tauric = cock_taur_shapes()
	for(var/taur_name in tauric)
		options += taur_name

	var/stored = feats["cock_shape"]
	var/display = stored
	if(feats["cock_taur"] && tauric["[stored] (Taur)"])
		display = "[stored] (Taur)"
	return list("value" = display, "options" = options)

/datum/character_setup/proc/build_genitals_data()
	var/list/data = list()
	var/list/feats = prefs.features
	var/datum/species/species = prefs.pref_species
	if(!species)
		return data

	if(NOGENITALS in species.species_traits)
		data["supported"] = FALSE
		return data
	data["supported"] = TRUE

	data["colorOverride"] = !!species.use_skintones && !!feats["genitals_use_skintone"]
	data["cockShape"] = build_cock_shape_data()

	var/list/parts = list()
	parts += list(genital_part_block("penis", "has_cock", "Пенис", list(
		"cock_color", "cock_shape", "cock_length", "cock_max_length", "cock_min_length",
		"cock_diameter_ratio", "cock_visibility", "cock_accessible", "cock_stuffing",
	)))
	parts += list(genital_part_block("testicles", "has_balls", "Яички", list(
		"balls_color", "balls_shape", "balls_size", "balls_visibility",
		"balls_accessible", "balls_stuffing", "balls_max_size", "balls_min_size",
		"balls_fluid", "balls_cum_max", "balls_cum_rate",
	)))
	parts += list(genital_part_block("vagina", "has_vag", "Влагалище", list(
		"vag_shape", "vag_color", "vag_visibility", "vag_accessible", "vag_stuffing",
		"has_womb", "womb_fluid",
	)))
	parts += list(genital_part_block("breasts", "has_breasts", "Грудь", list(
		"breasts_color", "breasts_sprite_variant", "breasts_nipples", "breasts_nipples_color",
		"breasts_size", "breasts_shape", "breasts_visibility",
		"breasts_producing", "breasts_stuffing", "breasts_max_size", "breasts_min_size",
		"breasts_fluid",
	)))
	parts += list(genital_part_block("butt", "has_butt", "Попа", list(
		"butt_color", "butt_size", "butt_visibility", "butt_accessible", "butt_stuffing",
		"butt_max_size", "butt_min_size", "has_anus", "anus_glow",
		"anus_color", "anus_shape", "anus_visibility", "anus_accessible", "anus_stuffing",
	), "anus"))
	parts += list(genital_part_block("belly", "has_belly", "Живот", list(
		"belly_color", "belly_size", "belly_max_size", "belly_min_size",
		"belly_visibility", "belly_stuffing", "belly_accessible",
	)))
	data["parts"] = parts

	data["hasNeckfire"] = !!prefs.all_quirks.Find(/datum/quirk/dullahan::name)
	data["neckfire"] = !!feats["neckfire"]

	return data

/datum/character_setup/proc/genital_part_block(glow_key, active_key, label, list/fields, sub_glow_key)
	var/list/feats = prefs.features
	var/list/shown = list()
	if(feats[active_key])
		for(var/field_key in fields)
			if(genital_field_visible(field_key))
				shown += field_key

	var/list/block = list(
		"key" = glow_key,
		"label" = label,
		"activeKey" = active_key,
		"active" = !!feats[active_key],
		"glow" = emissive_part_enabled(feats, glow_key),
		"fields" = shown,
	)
	if(sub_glow_key)
		block["subGlowKey"] = sub_glow_key
		block["subGlow"] = emissive_part_enabled(feats, sub_glow_key)
	return block

/datum/character_setup/proc/genital_field_visible(key)
	var/list/feats = prefs.features
	switch(key)
		if("womb_fluid")
			return !!feats["has_womb"]
		if("anus_glow", "anus_color", "anus_shape", "anus_visibility", "anus_accessible", "anus_stuffing")
			return !!feats["has_anus"]
		if("breasts_sprite_variant")
			return feats["breasts_shape"] == "Pair"
		if("breasts_nipples", "breasts_nipples_color")
			return feats["breasts_sprite_variant"] != "Old"
		if("breasts_fluid")
			return !!feats["breasts_producing"]
	return TRUE

/datum/character_setup/proc/markings_type()
	if(!prefs.parent)
		return null
	if(!prefs.parent.can_have_part("mam_body_markings"))
		return null
	return "mam_body_markings"

/datum/character_setup/proc/markings_list()
	var/marking_type = markings_type()
	if(!marking_type)
		return null
	var/list/entries = prefs.features[marking_type]
	return islist(entries) ? entries : null

/datum/character_setup/proc/marking_limb_choices()
	return list("Head", "Chest", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "All")

/datum/character_setup/proc/marking_limb_label(limb)
	switch(limb)
		if("Head")
			return "Голова"
		if("Chest")
			return "Грудь"
		if("Left Arm")
			return "Левая рука"
		if("Right Arm")
			return "Правая рука"
		if("Left Leg")
			return "Левая нога"
		if("Right Leg")
			return "Правая нога"
		if("All")
			return "Всё тело"
	return limb

/datum/character_setup/proc/marking_name_options(limb)
	var/list/options = list()
	if(!prefs.parent)
		return options
	for(var/path in GLOB.mam_body_markings_list)
		var/datum/sprite_accessory/S = GLOB.mam_body_markings_list[path]
		if(!istype(S))
			continue
		if(istype(S, /datum/sprite_accessory/mam_body_markings))
			var/datum/sprite_accessory/mam_body_markings/marking = S
			if(limb != "All" && !(limb in marking.covered_limbs))
				continue
		if(!S.is_allowed_for(prefs.parent.ckey))
			continue
		options[S.name] = path
	return options

/datum/character_setup/proc/marking_colors(list/entry)
	if(length(entry) >= 3 && islist(entry[3]))
		return entry[3]
	var/first = "#FFFFFF"
	var/second = "#FFFFFF"
	var/third = "#FFFFFF"
	var/list/feats = prefs.features
	if(feats["mcolor"])
		first = "#[feats["mcolor"]]"
	if(feats["mcolor2"])
		second = "#[feats["mcolor2"]]"
	if(feats["mcolor3"])
		third = "#[feats["mcolor3"]]"
	var/list/colors = list(first, second, third)
	if(length(entry) < 3)
		entry.len = 3
	entry[3] = colors
	return colors

/datum/character_setup/proc/build_marking_options_data()
	if(marking_options_cache)
		return marking_options_cache
	var/list/data = list()
	for(var/limb in marking_limb_choices())
		var/list/options = marking_name_options(limb)
		var/list/names = list()
		for(var/option in options)
			names += option
		data[limb] = names
	marking_options_cache = data
	return data

/datum/character_setup/proc/marking_color_chips(list/entry, matrixed)
	var/list/all_colors = marking_colors(entry)
	var/primary = 1
	var/secondary = 2
	var/tertiary = 3
	switch(matrixed)
		if(MATRIX_GREEN)
			primary = 2
		if(MATRIX_BLUE)
			primary = 3
		if(MATRIX_RED_BLUE)
			secondary = 3
		if(MATRIX_GREEN_BLUE)
			primary = 2
			secondary = 3
	var/list/positions = list(primary)
	if(matrixed in list(MATRIX_RED_BLUE, MATRIX_GREEN_BLUE, MATRIX_RED_GREEN, MATRIX_ALL))
		positions += secondary
	if(matrixed == MATRIX_ALL)
		positions += tertiary
	var/list/chips = list()
	for(var/position in positions)
		var/chip_value = all_colors[position]
		chips += list(list("index" = position, "value" = chip_value || "#FFFFFF"))
	return chips

/datum/character_setup/proc/build_markings_data()
	var/list/data = list()
	if(!markings_type())
		data["supported"] = FALSE
		return data
	data["supported"] = TRUE

	var/list/entries = prefs.features["mam_body_markings"]
	if(!islist(entries))
		entries = list()
		prefs.features["mam_body_markings"] = entries
	data["hasMarkings"] = length(entries) > 0
	data["total"] = length(entries)

	var/list/grid = list("Head", "Chest", "Left Arm", "Right Arm", "Left Leg", "Right Leg")
	var/list/limbs = list()
	for(var/limb in grid)
		var/list/rows = list()
		for(var/i in 1 to length(entries))
			var/list/entry = entries[i]
			if(!islist(entry) || length(entry) < 2)
				continue
			var/limb_value = text2num("[entry[1]]")
			if(GLOB.bodypart_names[num2text(limb_value)] != limb)
				continue
			rows += list(build_marking_row(i, entry, limb))
		limbs += list(list(
			"name" = limb,
			"label" = marking_limb_label(limb),
			"markings" = rows,
		))
	data["limbs"] = limbs
	return data

/datum/character_setup/proc/build_marking_row(index, list/entry, limb)
	var/datum/sprite_accessory/mam_body_markings/marking = GLOB.mam_body_markings_list[entry[2]]
	var/list/chips = list()
	if(marking && marking.covered_limbs)
		var/matrixed = marking.covered_limbs[limb]
		if(matrixed)
			chips = marking_color_chips(entry, matrixed)
	return list(
		"index" = index,
		"name" = "[entry[2]]",
		"colors" = chips,
		"glow" = length(entry) >= 4 && entry[4] ? TRUE : FALSE,
	)

/datum/character_setup/proc/add_marking(list/params)
	var/list/entries = markings_list()
	if(!entries)
		return
	var/list/limb_choices = marking_limb_choices()
	var/selected_limb = params["limb"]
	if(!(selected_limb in limb_choices))
		return
	var/list/options = marking_name_options(selected_limb)
	if(!length(options))
		return
	var/selected_marking = params["value"]
	if(!(selected_marking in options))
		return

	if(selected_limb == "All")
		var/datum/sprite_accessory/mam_body_markings/marking = GLOB.mam_body_markings_list[options[selected_marking]]
		if(!istype(marking) || !length(marking.covered_limbs))
			return
		for(var/limb in marking.covered_limbs)
			var/limb_text = GLOB.bodypart_values[limb]
			if(!limb_text)
				continue
			entries += list(marking_entry(text2num(limb_text), selected_marking))
	else
		entries += list(marking_entry(text2num(GLOB.bodypart_values[selected_limb]), selected_marking))
	preview_dirty = TRUE

/datum/character_setup/proc/marking_entry(limb_value, marking_name)
	return list(limb_value, marking_name, list("#FFFFFF", "#FFFFFF", "#FFFFFF"))

/datum/character_setup/proc/clear_limb_markings(list/params)
	var/list/entries = markings_list()
	if(!entries)
		return
	var/list/limb_choices = marking_limb_choices()
	var/selected_limb = params["limb"]
	if(!(selected_limb in limb_choices))
		selected_limb = tgui_input_list(prefs.parent?.mob, "Выберите часть тела для очистки.", "Настройка персонажа", limb_choices)
	if(!selected_limb)
		return
	if(selected_limb == "All")
		clearlist(entries)
	else
		var/limb_value = text2num(GLOB.bodypart_values[selected_limb])
		for(var/i = length(entries), i >= 1, i--)
			var/list/entry = entries[i]
			if(!islist(entry))
				continue
			if(text2num("[entry[1]]") == limb_value)
				entries.Cut(i, i + 1)
	preview_dirty = TRUE

/datum/character_setup/proc/clear_all_markings()
	var/list/entries = markings_list()
	if(!entries)
		return
	clearlist(entries)
	preview_dirty = TRUE

/datum/character_setup/proc/move_marking(list/params)
	var/list/entries = markings_list()
	if(!entries)
		return
	var/index = text2num("[params["index"]]")
	if(!index || index < 1 || index > length(entries))
		return
	if(!islist(entries[index]))
		return
	switch(params["mode"])
		if("top")
			if(index <= 1)
				return
			for(var/i = index, i > 1, i--)
				entries.Swap(i, i - 1)
		if("up")
			if(index <= 1 || !islist(entries[index - 1]))
				return
			entries.Swap(index, index - 1)
		if("down")
			if(index >= length(entries) || !islist(entries[index + 1]))
				return
			entries.Swap(index, index + 1)
		if("bottom")
			if(index >= length(entries))
				return
			for(var/i = index, i < length(entries), i++)
				entries.Swap(i, i + 1)
		else
			return
	preview_dirty = TRUE

/datum/character_setup/proc/cycle_marking(list/params)
	var/list/entries = markings_list()
	if(!entries || !prefs.parent)
		return
	var/index = text2num("[params["index"]]")
	var/direction = params["dir"]
	if(!index || index < 1 || index > length(entries))
		return
	if(isnull(params["value"]) && direction != "prev" && direction != "next")
		return
	var/list/entry = entries[index]
	if(!islist(entry) || length(entry) < 2)
		return
	var/actual_name = GLOB.bodypart_names[num2text(text2num("[entry[1]]"))]
	if(!actual_name)
		return
	var/user_key = prefs.parent.ckey
	var/list/available = list()
	for(var/name in GLOB.mam_body_markings_list)
		var/datum/sprite_accessory/S = GLOB.mam_body_markings_list[name]
		if(!istype(S, /datum/sprite_accessory/mam_body_markings))
			continue
		var/datum/sprite_accessory/mam_body_markings/marking = S
		if(!(actual_name in marking.covered_limbs))
			continue
		if(S.is_allowed_for(user_key))
			available += name
	if(!length(available))
		return
	if(!isnull(params["value"]))
		if(!(params["value"] in available))
			return
		entry[2] = params["value"]
		if(length(entry) >= 3 && entry[3])
			entry[3] = list("#FFFFFF", "#FFFFFF", "#FFFFFF")
		preview_dirty = TRUE
		return
	var/current_pos = available.Find(entry[2])
	if(!current_pos)
		current_pos = 0
	var/new_pos = current_pos + (direction == "next" ? 1 : -1)
	if(new_pos < 1)
		new_pos = length(available)
	else if(new_pos > length(available))
		new_pos = 1
	entry[2] = available[new_pos]
	if(length(entry) >= 3 && entry[3])
		entry[3] = list("#FFFFFF", "#FFFFFF", "#FFFFFF")
	preview_dirty = TRUE

/datum/character_setup/proc/remove_marking(list/params)
	var/list/entries = markings_list()
	if(!entries)
		return
	var/index = text2num("[params["index"]]")
	if(!index || index < 1 || index > length(entries))
		return
	entries.Cut(index, index + 1)
	preview_dirty = TRUE

/datum/character_setup/proc/toggle_marking_glow(list/params)
	var/list/entries = markings_list()
	if(!entries)
		return
	var/index = text2num("[params["index"]]")
	if(!index || index < 1 || index > length(entries))
		return
	var/list/entry = entries[index]
	if(!islist(entry) || !length(entry))
		return
	if(length(entry) < 4)
		entry.len = 4
	entry[4] = !entry[4]
	if(entry[4])
		prefs.features["allow_emissives"] = TRUE
	preview_dirty = TRUE

/datum/character_setup/proc/set_marking_color(list/params)
	var/list/entries = markings_list()
	if(!entries)
		return
	var/index = text2num("[params["index"]]")
	if(!index || index < 1 || index > length(entries))
		return
	var/list/entry = entries[index]
	if(!islist(entry) || length(entry) < 2)
		return
	var/color_index = text2num("[params["colorIndex"]]")
	if(!color_index || color_index < 1 || color_index > 3)
		return
	var/clean = sanitize_color_value(params["color"], FEATURE_COLOR_MUTANT, null, null, TRUE)
	if(isnull(clean))
		return
	if(length(entry) < 3 || !islist(entry[3]))
		return
	entry[3][color_index] = "#[clean]"
	preview_dirty = TRUE

/datum/character_setup/proc/open_tattoo_manager()
	prefs.parent?.open_tattoo_manager()

/datum/character_setup/proc/build_speech_data()
	var/list/data = list()

	var/verb_count = min(length(GLOB.speech_verbs), length(GLOB.speech_verbs_ru))
	var/list/verb_options = list()
	for(var/i in 1 to verb_count)
		verb_options += list(list("value" = GLOB.speech_verbs[i], "label" = GLOB.speech_verbs_ru[i]))
	data["verb"] = speech_verb_value()
	data["verbOptions"] = verb_options
	data["verbRu"] = !!prefs.custom_speech_verb_ru

	var/list/tongue_options = list()
	for(var/en_key in GLOB.roundstart_tongues)
		var/tongue_value = GLOB.roundstart_tongues[en_key]
		var/label = en_key
		for(var/ru_key in GLOB.roundstart_tongues_ru)
			if(GLOB.roundstart_tongues_ru[ru_key] == tongue_value)
				label = ru_key
				break
		tongue_options += list(list("value" = en_key, "label" = label))
	data["tongue"] = prefs.custom_tongue
	data["tongueOptions"] = tongue_options

	var/laugh_count = min(length(GLOB.mob_laughs), length(GLOB.mob_laughs_ru))
	var/list/laugh_options = list()
	for(var/i in 1 to laugh_count)
		laugh_options += list(list("value" = GLOB.mob_laughs[i], "label" = GLOB.mob_laughs_ru[i]))
	data["laugh"] = prefs.custom_laugh
	data["laughOptions"] = laugh_options
	data["laughPreviewable"] = prefs.custom_laugh != "Default"

	data["chatColorEnabled"] = !!prefs.enable_personal_chat_color
	data["chatColor"] = prefs.personal_chat_color

	data["maxLanguages"] = CONFIG_GET(number/max_languages)
	data["languages"] = build_language_options()

	data["bark"] = build_bark_data()
	data["deathsound"] = prefs.features["custom_deathsound"]
	var/list/death_sounds = list()
	for(var/sound_name in GLOB.deathgasp_sounds)
		death_sounds += sound_name
	data["deathsounds"] = death_sounds
	return data

/datum/character_setup/proc/speech_verb_value()
	var/index = GLOB.speech_verbs.Find(prefs.custom_speech_verb)
	if(index)
		return GLOB.speech_verbs[index]
	index = GLOB.speech_verbs_ru.Find(prefs.custom_speech_verb)
	if(index)
		return GLOB.speech_verbs[index]
	return GLOB.speech_verbs[1]

/datum/character_setup/proc/set_speech_verb(list/params)
	var/value = params["value"]
	if(!istext(value))
		return
	var/index = GLOB.speech_verbs.Find(value)
	if(!index)
		return
	prefs.custom_speech_verb = prefs.custom_speech_verb_ru ? GLOB.speech_verbs_ru[index] : GLOB.speech_verbs[index]

/datum/character_setup/proc/toggle_speech_verb_ru()
	if(!prefs.get_default_speech_verb(prefs.custom_speech_verb))
		var/list/source_list = prefs.custom_speech_verb_ru ? GLOB.speech_verbs_ru : GLOB.speech_verbs
		var/list/target_list = prefs.custom_speech_verb_ru ? GLOB.speech_verbs : GLOB.speech_verbs_ru
		var/verb_index = source_list.Find(prefs.custom_speech_verb)
		if(verb_index)
			prefs.custom_speech_verb = target_list[verb_index]
	prefs.custom_speech_verb_ru = !prefs.custom_speech_verb_ru

/datum/character_setup/proc/set_tongue(list/params)
	var/value = params["value"]
	if(!istext(value))
		return
	var/found = FALSE
	for(var/en_key in GLOB.roundstart_tongues)
		if(en_key == value)
			found = TRUE
			break
	if(!found)
		return
	prefs.custom_tongue = value

/datum/character_setup/proc/set_laugh(list/params)
	var/value = params["value"]
	if(!isnull(params["dir"]))
		var/count = min(length(GLOB.mob_laughs), length(GLOB.mob_laughs_ru))
		value = cycle_choice(prefs.custom_laugh, GLOB.mob_laughs.Copy(1, count + 1), params["dir"])
	if(!(value in GLOB.mob_laughs))
		return
	prefs.custom_laugh = value

/datum/character_setup/proc/preview_laugh()
	var/mob/user = prefs.parent?.mob
	if(!user || prefs.custom_laugh == "Default")
		return
	if(SSticker.current_state == GAME_STATE_STARTUP)
		to_chat(user, span_warning("Звук смеха нельзя прослушать во время инициализации!"))
		return
	if(!start_sound_preview("laugh", 3 SECONDS))
		return
	user.playsound_local(user, pick(get_laugh_sound(prefs.custom_laugh, FALSE)), 50, channel = sound_preview_channel)

/datum/character_setup/proc/build_language_options()
	var/list/options = list()
	if(!SSlanguage || !length(SSlanguage.languages_by_name))
		return options
	for(var/lang_name in SSlanguage.languages_by_name)
		var/datum/language/L = SSlanguage.languages_by_name[lang_name]
		if(!L)
			continue
		if(L.restricted && !(lang_name in prefs.pref_species.languagewhitelist))
			var/quirk_allowed = FALSE
			for(var/qname in prefs.all_quirks)
				var/datum/quirk/Q = SSquirks ? SSquirks.quirks[qname] : null
				if(Q && (lang_name in Q.languagewhitelist))
					quirk_allowed = TRUE
					break
			if(!quirk_allowed)
				continue
		options += list(list(
			"name" = lang_name,
			"desc" = L.desc,
			"selected" = (lang_name in prefs.language) ? TRUE : FALSE,
		))
	return options

/datum/character_setup/proc/toggle_language_pref(list/params)
	var/lang = params["value"]
	if(!istext(lang))
		return
	if(!SSlanguage || !SSlanguage.languages_by_name[lang])
		return
	if(!prefs.toggle_language(lang))
		return
	prefs.language = sort_list(prefs.language)

/datum/character_setup/proc/reset_languages()
	prefs.language = list()

/proc/language_icon_b64(icon_file, icon_state)
	if(!icon_file || !istext(icon_state) || !icon_state)
		return null
	var/static/list/states_cache = list()
	var/cache_states_key = "[icon_file]"
	var/list/states = states_cache[cache_states_key]
	if(!states)
		states = icon_states(icon_file)
		states_cache[cache_states_key] = states
	if(!(icon_state in states))
		return null
	var/static/list/cache = list()
	var/cache_key = "[icon_file]|[icon_state]"
	var/cached = cache[cache_key]
	if(cached != null)
		return cached || null
	cached = icon2base64(icon(icon_file, icon_state))
	cache[cache_key] = cached || ""
	return cached || null

/datum/character_setup/proc/build_language_icons()
	if(language_icons_cache)
		return language_icons_cache
	var/list/icons = list()
	if(!SSlanguage)
		return icons
	for(var/lang_name in SSlanguage.languages_by_name)
		var/datum/language/L = SSlanguage.languages_by_name[lang_name]
		if(!L)
			continue
		var/icon_file = initial(L.icon)
		var/icon_state = initial(L.icon_state)
		if(!icon_file || !icon_state)
			continue
		var/encoded = language_icon_b64(icon_file, icon_state)
		if(encoded)
			icons[lang_name] = encoded
	if(length(icons))
		language_icons_cache = icons
	return icons

/datum/character_setup/proc/toggle_personal_chat_color()
	prefs.enable_personal_chat_color = !prefs.enable_personal_chat_color

/datum/character_setup/proc/set_personal_chat_color(list/params)
	var/raw = params["color"]
	if(!istext(raw))
		return
	if(!findtext(raw, "#"))
		raw = "#[raw]"
	if(color_hex2num(raw) <= 200)
		var/mob/user = prefs.parent?.mob
		if(user)
			to_chat(user, span_danger("Неверный цвет. Выбранный цвет недостаточно яркий."))
		return
	prefs.personal_chat_color = sanitize_hexcolor(raw, 6, TRUE)

/datum/character_setup/proc/build_bark_data()
	var/list/data = list()
	var/list/options = list()
	if(prefs.parent)
		for(var/bark_id in GLOB.bark_datums)
			var/datum/bark/B = GLOB.bark_datums[bark_id]
			if(!B || B.ignore)
				continue
			if(!B.is_allowed_for(prefs.parent.ckey))
				continue
			options += list(list("value" = B.id, "label" = B.name))
	data["options"] = options
	data["id"] = prefs.bark_id
	var/datum/bark/path = GLOB.bark_list[prefs.bark_id]
	if(!path)
		data["valid"] = FALSE
		return data
	data["valid"] = TRUE
	data["name"] = initial(path.name)
	data["speed"] = prefs.bark_speed
	data["pitch"] = prefs.bark_pitch
	data["variance"] = prefs.bark_variance
	data["minSpeed"] = initial(path.minspeed)
	data["maxSpeed"] = initial(path.maxspeed)
	data["minPitch"] = initial(path.minpitch)
	data["maxPitch"] = initial(path.maxpitch)
	data["minVariance"] = initial(path.minvariance)
	data["maxVariance"] = initial(path.maxvariance)
	return data

/datum/character_setup/proc/set_bark_sound(list/params)
	var/id = params["value"]
	if(!prefs.parent)
		return
	if(!isnull(params["dir"]))
		var/list/bark_data = build_bark_data()
		var/list/options = list()
		for(var/list/option in bark_data["options"])
			options += option["value"]
		id = cycle_choice(prefs.bark_id, options, params["dir"])
	if(!istext(id))
		return
	var/datum/bark/B = GLOB.bark_datums[id]
	if(!B || B.ignore)
		return
	if(!B.is_allowed_for(prefs.parent.ckey))
		return
	prefs.bark_id = B.id
	clamp_bark_numbers()

/datum/character_setup/proc/clamp_bark_numbers()
	var/datum/bark/path = GLOB.bark_list[prefs.bark_id]
	if(!path)
		return
	prefs.bark_speed = round(clamp(prefs.bark_speed, initial(path.minspeed), initial(path.maxspeed)), 1)
	prefs.bark_pitch = clamp(prefs.bark_pitch, initial(path.minpitch), initial(path.maxpitch))
	prefs.bark_variance = clamp(prefs.bark_variance, initial(path.minvariance), initial(path.maxvariance))

/datum/character_setup/proc/set_bark_number(list/params)
	var/next = num_param(params["value"])
	if(isnull(next))
		return
	var/datum/bark/path = GLOB.bark_list[prefs.bark_id]
	if(!path)
		return
	switch(params["key"])
		if("speed")
			prefs.bark_speed = round(clamp(next, initial(path.minspeed), initial(path.maxspeed)), 1)
		if("pitch")
			prefs.bark_pitch = clamp(next, initial(path.minpitch), initial(path.maxpitch))
		if("variance")
			prefs.bark_variance = clamp(next, initial(path.minvariance), initial(path.maxvariance))

/datum/character_setup/proc/preview_bark()
	var/mob/user = prefs.parent?.mob
	if(!user)
		return
	if(SSticker.current_state == GAME_STATE_STARTUP)
		to_chat(user, span_warning("Звук речи нельзя прослушать во время инициализации!"))
		return
	var/datum/bark/path = GLOB.bark_list[prefs.bark_id]
	if(!path || prefs.bark_speed <= 0)
		return
	if(!start_sound_preview("voice", 5 SECONDS))
		return
	var/generation = sound_preview_generation
	var/total_delay
	for(var/i in 1 to (round((32 / prefs.bark_speed)) + 1))
		addtimer(CALLBACK(src, PROC_REF(play_bark_preview), generation, initial(path.soundpath), BARK_DO_VARY(prefs.bark_pitch, prefs.bark_variance)), total_delay)
		total_delay += rand(DS2TICKS(prefs.bark_speed/4), DS2TICKS(prefs.bark_speed/4) + DS2TICKS(prefs.bark_speed/4)) TICKS
	sound_preview_until = world.time + total_delay + 1 SECONDS

// Один канал и номер сеанса не дают прошлому голосу продолжить играть после запуска нового звука.
/datum/character_setup/proc/start_sound_preview(kind, duration)
	if(world.time < next_sound_preview)
		return FALSE
	next_sound_preview = world.time + 0.3 SECONDS
	stop_sound_preview()
	if(!sound_preview_channel)
		sound_preview_channel = SSsounds.reserve_sound_channel(src)
	if(!sound_preview_channel)
		return FALSE
	sound_preview_kind = kind
	sound_preview_until = world.time + duration
	addtimer(CALLBACK(src, PROC_REF(sound_preview_finished)), duration, TIMER_UNIQUE | TIMER_OVERRIDE)
	return TRUE

/datum/character_setup/proc/sound_preview_finished()
	SStgui.update_uis(src)

/datum/character_setup/proc/stop_sound_preview()
	sound_preview_generation++
	sound_preview_kind = null
	sound_preview_until = 0
	if(sound_preview_channel)
		prefs?.parent?.mob?.stop_sound_channel(sound_preview_channel)

/datum/character_setup/proc/play_bark_preview(generation, sound_path, pitch)
	if(generation != sound_preview_generation || world.time >= sound_preview_until)
		return
	var/mob/user = prefs?.parent?.mob
	if(user)
		user.playsound_local(user, sound_path, round(user.client.prefs.get_sound_volume("bark") * 0.7), vary = TRUE, frequency = pitch, channel = sound_preview_channel)

/proc/loadout_ui_label(key)
	switch(key)
		if(LOADOUT_CATEGORY_BACKPACK)
			return "Рюкзак"
		if(LOADOUT_CATEGORY_NECK)
			return "Шея"
		if(LOADOUT_CATEGORY_MASK)
			return "Маска"
		if(LOADOUT_CATEGORY_HANDS)
			return "Руки"
		if(LOADOUT_CATEGORY_UNIFORM)
			return "Форма"
		if(LOADOUT_CATEGORY_ACCESSORY)
			return "Аксессуары"
		if(LOADOUT_CATEGORY_SUIT)
			return "Верхняя одежда"
		if(LOADOUT_CATEGORY_HEAD)
			return "Голова"
		if(LOADOUT_CATEGORY_SHOES)
			return "Обувь"
		if(LOADOUT_CATEGORY_GLOVES)
			return "Перчатки"
		if(LOADOUT_CATEGORY_GLASSES)
			return "Очки"
		if(LOADOUT_CATEGORY_DONATOR)
			return "Донат"
		if(LOADOUT_CATEGORY_UNLOCKABLE)
			return "Открываемое"
		if(LOADOUT_CATEGORY_GENERAL_UNDER)
			return "Нижнее бельё"
		if(LOADOUT_CATEGORY_WRISTS)
			return "Запястья"
		if(LOADOUT_CATEGORY_ERROR)
			return "Ошибки"
		if(LOADOUT_SUBCATEGORY_NONE)
			return "Разное"
		if(LOADOUT_SUBCATEGORY_BACKPACK_GENERAL, LOADOUT_SUBCATEGORY_NECK_GENERAL, LOADOUT_SUBCATEGORY_UNIFORM_GENERAL, LOADOUT_SUBCATEGORY_SUIT_GENERAL, LOADOUT_SUBCATEGORY_HEAD_GENERAL)
			return "Общее"
		if(LOADOUT_SUBCATEGORY_BACKPACK_TOYS)
			return "Игрушки"
		if(LOADOUT_SUBCATEGORY_BACKPACK_ACCESSORIES)
			return "Аксессуары"
		if(LOADOUT_SUBCATEGORY_NECK_TIE)
			return "Галстуки"
		if(LOADOUT_SUBCATEGORY_NECK_SCARVES)
			return "Шарфы"
		if(LOADOUT_SUBCATEGORY_UNIFORM_JOBS, LOADOUT_SUBCATEGORY_SUIT_JOBS, LOADOUT_SUBCATEGORY_HEAD_JOBS)
			return "Работа"
		if(LOADOUT_SUBCATEGORY_UNIFORM_SUITS)
			return "Комбинезоны"
		if(LOADOUT_SUBCATEGORY_UNIFORM_SKIRTS)
			return "Юбки"
		if(LOADOUT_SUBCATEGORY_UNIFORM_DRESSES)
			return "Платья"
		if(LOADOUT_SUBCATEGORY_UNIFORM_SWEATERS)
			return "Свитера"
		if(LOADOUT_SUBCATEGORY_UNIFORM_PANTS)
			return "Штаны"
		if(LOADOUT_SUBCATEGORY_UNIFORM_SHORTS)
			return "Шорты"
		if(LOADOUT_SUBCATEGORY_SUIT_COATS)
			return "Пальто"
		if(LOADOUT_SUBCATEGORY_SUIT_JACKETS)
			return "Куртки"
		if(LOADOUT_SUBCATEGORY_UNDERWEAR)
			return "Бельё"
		if(LOADOUT_SUBCATEGORY_SHIRT)
			return "Рубашки"
		if(LOADOUT_SUBCATEGORY_SOCKS)
			return "Носки"
		if(LOADOUT_SUBCATEGORY_WATCHES)
			return "Часы"
	return key

/datum/character_setup/proc/build_loadout_data(mob/user)
	var/list/data = list()
	if(!prefs)
		return data

	if(!length(GLOB.loadout_items))
		data["empty"] = TRUE
		return data

	sanitize_loadout_navigation(prefs)
	calc_gear_points(user)

	var/list/categories = list()
	for(var/category in GLOB.loadout_categories)
		categories += list(list("value" = category, "label" = loadout_ui_label(category)))
	data["categories"] = categories
	data["category"] = prefs.gear_category
	data["points"] = prefs.gear_points
	data["errors"] = prefs.loadout_errors

	var/list/subcategories = list()
	var/list/subcategory_source = GLOB.loadout_categories[prefs.gear_category]
	if(islist(subcategory_source))
		for(var/subcategory in subcategory_source)
			subcategories += list(list("value" = subcategory, "label" = loadout_ui_label(subcategory)))
	data["subcategories"] = subcategories
	data["subcategory"] = prefs.gear_subcategory

	data["slot"] = prefs.loadout_slot
	data["slotCount"] = MAXIMUM_LOADOUT_SAVES
	data["presetSlot"] = LOADOUT_PRESET_SLOT
	data["presetName"] = prefs.active_character_preset
	data["enabled"] = !!prefs.loadout_enabled
	data["selectedView"] = loadout_selected
	var/datum/job/planned_job = prefs.get_highest_job()
	data["plannedJob"] = planned_job?.title
	// Индексы общие для всей выдачи: строки каталога не обходят выбранные вещи заново.
	var/list/selected_by_type = list()
	var/list/conflicts_by_slot = list()
	var/list/selected_gear = list()
	var/list/row_context = list("selected" = selected_by_type, "conflicts" = conflicts_by_slot, "job" = planned_job)
	var/list/selected_items = list()
	var/selected_count = 0
	var/list/chosen_gear = prefs.loadout_data["SAVE_[prefs.loadout_slot]"]
	for(var/list/entry in chosen_gear)
		var/datum/gear/gear = find_loadout_gear(entry[LOADOUT_ITEM])
		if(istype(gear))
			selected_count++
			selected_gear += gear
			if(!selected_by_type["[gear.type]"])
				selected_by_type["[gear.type]"] = entry
			if(planned_job && length(gear.restricted_roles) && !(planned_job.title in gear.restricted_roles))
				continue
			if(gear.donoritem && !gear.donator_ckey_check(prefs.parent?.key))
				continue
			LAZYADD(conflicts_by_slot["[gear.slot]"], list(list("type" = gear.type, "name" = entry[LOADOUT_CUSTOM_NAME] || gear.name)))
	data["selectedCount"] = selected_count

	data["showCkeyId"] = (prefs.gear_category == LOADOUT_CATEGORY_DONATOR && prefs.gear_subcategory == LOADOUT_SUBCATEGORIES_DON03)
	if(loadout_selected)
		for(var/datum/gear/gear as anything in selected_gear)
			selected_items += list(build_loadout_row(gear, gear.name, row_context))
		data["items"] = selected_items
		data["invalid"] = list()
		return data

	if(prefs.gear_category == LOADOUT_CATEGORY_ERROR)
		data["items"] = list()
		data["invalid"] = build_invalid_loadout_rows()
		return data

	data["invalid"] = list()
	data["items"] = build_loadout_rows(user, row_context)
	return data

/datum/character_setup/proc/available_gear_points(mob/user)
	. = CONFIG_GET(number/initial_gear_points)
	if(IS_CKEY_DONATOR_GROUP(user?.ckey, DONATOR_GROUP_TIER_1))
		. += CONFIG_GET(number/subscriber_extra_gear_points)
	if(IS_CKEY_DONATOR_GROUP(user?.ckey, DONATOR_GROUP_TIER_2))
		. += CONFIG_GET(number/sponsor_extra_gear_points)

/datum/character_setup/proc/calc_gear_points(mob/user)
	prefs.gear_points = available_gear_points(user)

	prefs.loadout_errors = 0
	var/list/chosen_gear = prefs.loadout_data["SAVE_[prefs.loadout_slot]"]
	for(var/list/entry in chosen_gear)
		var/loadout_item_path = entry[LOADOUT_ITEM]
		if(loadout_item_path)
			var/datum/gear/loadout_gear = text2path(loadout_item_path)
			if(loadout_gear)
				prefs.gear_points -= initial(loadout_gear.cost)
			else
				prefs.loadout_errors++
		else
			prefs.loadout_errors++

/datum/character_setup/proc/build_loadout_rows(mob/user, list/row_context)
	var/list/rows = list()
	var/list/subcategory_items = GLOB.loadout_items[prefs.gear_category]?[prefs.gear_subcategory]
	for(var/item_name in subcategory_items)
		var/datum/gear/gear = subcategory_items[item_name]
		if(!istype(gear))
			continue
		if(gear.donoritem && !gear.donator_ckey_check(user?.key))
			continue
		rows += list(build_loadout_row(gear, item_name, row_context))
	return rows

/datum/character_setup/proc/build_loadout_row(datum/gear/gear, item_name, list/row_context)
	var/list/row = list("name" = item_name)
	row["id"] = "[gear.type]"
	row["category"] = loadout_ui_label(gear.category)
	row["cost"] = gear.cost
	row["preview"] = gear.get_base64icon()
	row["donor"] = !!gear.donoritem
	row["isClothing"] = ispath(gear.path, /obj/item/clothing)
	row["isCollar"] = ispath(gear.path, /obj/item/clothing/neck/petcollar)
	row["canName"] = !!(gear.loadout_flags & LOADOUT_CAN_NAME)
	row["canDescription"] = !!(gear.loadout_flags & LOADOUT_CAN_DESCRIPTION)
	row["canPoly"] = !!(gear.loadout_flags & LOADOUT_CAN_COLOR_POLYCHROMIC)
	row["isLipstick"] = (gear.path == /obj/item/lipstick/loadout)

	var/restrictions = gear.restricted_desc
	if(!restrictions && islist(gear.restricted_roles) && length(gear.restricted_roles))
		restrictions = "Разрешённые профессии: [gear.restricted_roles.Join(", ")]"
	row["restrictions"] = restrictions

	var/unlocked = TRUE
	if(istype(gear, /datum/gear/unlockable))
		var/datum/gear/unlockable/unlockable_gear = gear
		unlocked = prefs.can_use_unlockable(unlockable_gear)
		var/progress_made = prefs.unlockable_loadout_data[unlockable_gear.progress_key] || 0
		row["progress"] = "[min(progress_made, unlockable_gear.progress_required)]/[unlockable_gear.progress_required]"
	row["unlocked"] = unlocked

	row["description"] = gear.description

	var/list/selected_by_type = row_context["selected"]
	var/list/entry = selected_by_type["[gear.type]"]
	row["selected"] = !!entry
	row["noPoints"] = !entry && (prefs.gear_points < gear.cost)
	var/availability_reason
	if(gear.donoritem && !gear.donator_ckey_check(prefs.parent?.key))
		availability_reason = "Нет доступа к донатному предмету."
	else if(!unlocked)
		availability_reason = "Не выполнены условия разблокировки. Прогресс: [row["progress"]]."
	else if(!entry && !prefs.is_loadout_slot_available(gear.category))
		availability_reason = "Достигнут лимит вещей этой категории. Сначала уберите одну из выбранных."
	else if(row["noPoints"])
		availability_reason = "Не хватает очков: нужно [gear.cost], осталось [prefs.gear_points]."
	row["availabilityReason"] = availability_reason
	row["canBuy"] = !entry && !availability_reason
	var/datum/job/planned_job = row_context["job"]
	row["roleMismatch"] = planned_job && length(gear.restricted_roles) && !(planned_job.title in gear.restricted_roles)
	if(row["roleMismatch"])
		row["roleWarning"] = "Не выдаётся для профессии «[planned_job.title]». Итоговая проверка зависит от назначенной профессии."

	// Для отдельных носимых слотов показываем конфликты между доступными предметами набора.
	if(gear.slot && !(gear.slot in list(ITEM_SLOT_BACKPACK, ITEM_SLOT_HANDS, ITEM_SLOT_ACCESSORY)))
		var/list/conflicts = list()
		var/list/conflicts_by_slot = row_context["conflicts"]
		for(var/list/other in conflicts_by_slot["[gear.slot]"])
			if(other["type"] == gear.type)
				continue
			conflicts += other["name"]
		row["conflicts"] = conflicts
	if(row["roleMismatch"])
		row["conflicts"] = list()

	if(!entry)
		return row

	row["description"] = entry[LOADOUT_CUSTOM_DESCRIPTION] || gear.description
	row["customName"] = entry[LOADOUT_CUSTOM_NAME]
	row["isHeirloom"] = !!entry[LOADOUT_IS_HEIRLOOM]
	row["tagName"] = entry["loadout_custom_tagname"]

	var/list/examtooltip = entry["loadout_examtooltip"]
	if(islist(examtooltip) && length(examtooltip))
		row["examTooltip"] = examtooltip[1]
		row["examTooltipAlways"] = !examtooltip[2]

	var/list/raw_colors = entry[LOADOUT_COLOR]
	if(islist(raw_colors))
		gear.pad_polychromic_colors(entry)
		raw_colors = entry[LOADOUT_COLOR]
		var/list/colors = list()
		for(var/raw_color in raw_colors)
			colors += list(list("value" = istext(raw_color) ? raw_color : null, "matrix" = !istext(raw_color)))
		row["colors"] = colors
	return row

/datum/character_setup/proc/find_loadout_gear(name)
	// В обзоре выбранного вещи относятся к разным категориям; идентификатор проверяем по каталогу.
	var/gear_path = text2path(name)
	if(ispath(gear_path, /datum/gear))
		var/datum/gear/gear_type = gear_path
		var/datum/gear/gear = GLOB.loadout_items[initial(gear_type.category)]?[initial(gear_type.subcategory)]?[initial(gear_type.name)]
		return gear?.type == gear_path ? gear : null
	var/list/subcategory_items = GLOB.loadout_items[prefs.gear_category]?[prefs.gear_subcategory]
	return subcategory_items?[name]

/datum/character_setup/proc/build_invalid_loadout_rows()
	var/list/rows = list()
	var/list/chosen_gear = prefs.loadout_data["SAVE_[prefs.loadout_slot]"]
	for(var/list/entry in chosen_gear)
		var/raw_path = entry[LOADOUT_ITEM]
		if(text2path(raw_path))
			continue
		rows += list(list("item" = "[raw_path]", "data" = json_encode(entry - LOADOUT_ITEM)))
	return rows

/datum/character_setup/proc/loadout_select_slot(list/params)
	var/next_slot = num_param(params["slot"])
	if(isnull(next_slot))
		return
	next_slot = floor(next_slot)
	if(next_slot < LOADOUT_PRESET_SLOT || next_slot > MAXIMUM_LOADOUT_SAVES)
		return
	prefs.loadout_slot = next_slot
	sanitize_loadout_navigation(prefs)

/datum/character_setup/proc/loadout_select_category(list/params)
	loadout_selected = FALSE
	prefs.gear_category = "[params["value"]]"
	var/list/subcategories = GLOB.loadout_categories[prefs.gear_category]
	if(length(subcategories))
		prefs.gear_subcategory = subcategories[1]
	sanitize_loadout_navigation(prefs)

/datum/character_setup/proc/loadout_select_subcategory(list/params)
	prefs.gear_subcategory = "[params["value"]]"
	sanitize_loadout_navigation(prefs)

/datum/character_setup/proc/loadout_copy_slot(list/params)
	var/mob/user = prefs.parent?.mob
	var/character_slot = prefs.default_slot
	var/revision = character_revision
	var/source_slot = prefs.loadout_slot
	var/list/slots = list()
	if(source_slot != LOADOUT_PRESET_SLOT)
		slots["Пресет"] = LOADOUT_PRESET_SLOT
	for(var/i in 1 to MAXIMUM_LOADOUT_SAVES)
		if(i == source_slot)
			continue
		slots["[i]"] = i
	var/next_slot = num_param(params["target"])
	if(isnull(next_slot))
		var/asked = tgui_input_list(user, "Выберите слот для копирования текущего лодаута.", "Копирование лодаута", slots)
		if(isnull(asked) || !(asked in slots))
			return
		next_slot = slots[asked]
	if(QDELETED(src) || !prefs || prefs.default_slot != character_slot || character_revision != revision)
		return
	if(next_slot != round(next_slot) || next_slot < LOADOUT_PRESET_SLOT || next_slot > MAXIMUM_LOADOUT_SAVES || next_slot == source_slot)
		return
	// Правки цветов и подписей копии не должны менять исходный общий лодаут или сохранённый пресет.
	prefs.loadout_data["SAVE_[next_slot]"] = deepCopyList(SANITIZE_LIST(prefs.loadout_data["SAVE_[source_slot]"]))
	if(params["activate"])
		prefs.loadout_slot = next_slot

/datum/character_setup/proc/loadout_toggle_gear(list/params)
	var/datum/gear/gear = find_loadout_gear("[params["name"]]")
	if(!gear)
		return
	var/list/existing = prefs.has_loadout_gear(prefs.loadout_slot, "[gear.type]")
	if(existing)
		prefs.remove_gear_from_loadout(prefs.loadout_slot, "[gear.type]")
		return

	var/mob/user = prefs.parent?.mob
	if(!prefs.is_loadout_slot_available(gear.category))
		to_chat(user, span_danger("Слишком много вещей одной категории!"))
		return
	if(gear.donoritem && !gear.donator_ckey_check(user?.key))
		to_chat(user, span_danger("Эта вещь доступна только донорам."))
		return
	if(istype(gear, /datum/gear/unlockable) && !prefs.can_use_unlockable(gear))
		to_chat(user, span_danger("Чтобы взять эту вещь, нужно выполнить условия её разблокировки."))
		return
	if(prefs.gear_points < gear.cost)
		return

	if(gear.path == /obj/item/lipstick/loadout)
		loadout_pick_lipstick_color(params)
		return

	prefs.gear_points -= gear.cost
	var/list/new_entry = list(LOADOUT_ITEM = "[gear.type]")
	var/list/initial_colors = gear.loadout_initial_colors
	new_entry[LOADOUT_COLOR] = length(initial_colors) ? initial_colors.Copy() : list("#FFFFFF")
	var/list/chosen_slot = prefs.loadout_data["SAVE_[prefs.loadout_slot]"]
	if(islist(chosen_slot))
		chosen_slot += list(new_entry)
	else
		prefs.loadout_data["SAVE_[prefs.loadout_slot]"] = list(new_entry)

/datum/character_setup/proc/loadout_lipstick_palette()
	return list(
		"#FF0000" = "Красный",
		"#800080" = "Пурпурный",
		"#00FF00" = "Нефрит",
		"#000000" = "Чёрный",
		"#FFFF00" = "Жёлтый",
		"#0000FF" = "Синий",
		"#008080" = "Бирюзовый",
		"#FF00FF" = "Фуксия",
		"#000080" = "Тёмно-синий",
		"#00FFFF" = "Циан",
		"#FFFFFF" = "Белый",
	)

/datum/character_setup/proc/loadout_pick_lipstick_color(list/params)
	var/mob/user = prefs.parent?.mob
	var/datum/gear/gear = find_loadout_gear("[params["name"]]")
	if(!gear || gear.path != /obj/item/lipstick/loadout)
		return
	var/list/palette = loadout_lipstick_palette()
	var/chosen_name = tgui_input_list(user, "Выберите цвет помады.", "Помада", palette)
	if(!chosen_name)
		return
	var/chosen_color = palette[chosen_name]
	if(!chosen_color)
		return

	var/list/existing = prefs.has_loadout_gear(prefs.loadout_slot, "[gear.type]")
	if(existing)
		existing[LOADOUT_COLOR] = list(sanitize_hexcolor(chosen_color, 6, TRUE, "#FF0000"))
		return
	if(prefs.gear_points < gear.cost)
		return
	prefs.gear_points -= gear.cost
	var/list/lipstick_entry = list(LOADOUT_ITEM = "[gear.type]", LOADOUT_COLOR = list(sanitize_hexcolor(chosen_color, 6, TRUE, "#FF0000")))
	if(islist(prefs.loadout_data["SAVE_[prefs.loadout_slot]"]))
		prefs.loadout_data["SAVE_[prefs.loadout_slot]"] += list(lipstick_entry)
	else
		prefs.loadout_data["SAVE_[prefs.loadout_slot]"] = list(lipstick_entry)

/datum/character_setup/proc/open_loadout_color(list/params)
	var/datum/gear/gear = find_loadout_gear("[params["name"]]")
	var/list/entry = gear ? prefs.has_loadout_gear(prefs.loadout_slot, "[gear.type]") : null
	if(!entry)
		return

	if(prefs.loadout_color_handler)
		SStgui.close_uis(prefs.loadout_color_handler)
	if(!length(entry[LOADOUT_COLOR]))
		entry[LOADOUT_COLOR] = list("#FFFFFF")

	var/datum/loadout_color_handler/lch = new
	prefs.loadout_color_handler = lch
	lch.prefs = prefs
	lch.user = prefs.parent?.mob
	lch.gear_name = gear.name
	lch.loadout_slot = prefs.loadout_slot
	lch.user_gear = entry
	lch.gear = gear

	var/raw_color = entry[LOADOUT_COLOR][1]
	var/saved_mode = entry[LOADOUT_COLOR_MODE]
	if(!isnum(saved_mode))
		saved_mode = COLORMATE_HSV
	else
		switch(saved_mode)
			if(COLORMATE_TINT)
				if(!istext(raw_color))
					saved_mode = COLORMATE_HSV
			if(COLORMATE_MATRIX, COLORMATE_HSV)
				if(!islist(raw_color) || length(raw_color) < 12)
					saved_mode = COLORMATE_TINT
	lch.active_mode = saved_mode
	var/list/matrix_color
	if(islist(raw_color))
		matrix_color = raw_color
	switch(saved_mode)
		if(COLORMATE_TINT)
			if(istext(raw_color))
				lch.activecolor = raw_color
		if(COLORMATE_MATRIX)
			if(length(matrix_color) >= 12)
				lch.color_matrix_last = matrix_color.Copy()
		if(COLORMATE_HSV)
			if(length(matrix_color) >= 12)
				lch.color_matrix_last = matrix_color.Copy()
			var/list/hsv = entry[LOADOUT_COLOR_HSV_DATA]
			if(length(hsv) == 3)
				lch.build_hue = hsv[1]
				lch.build_sat = hsv[2]
				lch.build_val = hsv[3]
	lch.open(lch.user)

/datum/character_setup/proc/loadout_set_poly_color(list/params)
	var/datum/gear/gear = find_loadout_gear("[params["name"]]")
	var/list/entry = gear ? prefs.has_loadout_gear(prefs.loadout_slot, "[gear.type]") : null
	if(!entry)
		return
	gear.pad_polychromic_colors(entry)
	var/list/colors = entry[LOADOUT_COLOR]
	var/index = num_param(params["index"])
	if(isnull(index) || index < 1 || index > length(colors))
		return
	var/current = colors[index]
	var/fallback = (istext(current) && (length(current) == 3 || length(current) == 6)) ? current : "#FFFFFF"
	colors[index] = sanitize_hexcolor("[params["color"]]", 6, TRUE, fallback)

/datum/character_setup/proc/loadout_set_name(list/params)
	var/datum/gear/gear = find_loadout_gear("[params["name"]]")
	var/list/entry = gear ? prefs.has_loadout_gear(prefs.loadout_slot, "[gear.type]") : null
	if(!entry || !(gear.loadout_flags & LOADOUT_CAN_NAME))
		return
	var/mob/user = prefs.parent?.mob
	var/new_name = tgui_input_text(user, "Введите новое имя предмета.", "Название вещи", entry[LOADOUT_CUSTOM_NAME], MAX_NAME_LEN, FALSE, TRUE)
	if(!isnull(new_name))
		entry[LOADOUT_CUSTOM_NAME] = new_name

/datum/character_setup/proc/loadout_set_description(list/params)
	var/datum/gear/gear = find_loadout_gear("[params["name"]]")
	var/list/entry = gear ? prefs.has_loadout_gear(prefs.loadout_slot, "[gear.type]") : null
	if(!entry || !(gear.loadout_flags & LOADOUT_CAN_DESCRIPTION))
		return
	var/mob/user = prefs.parent?.mob
	var/new_description = tgui_input_text(user, "Введите новое описание вещи.", "Описание вещи", entry[LOADOUT_CUSTOM_DESCRIPTION], 500, TRUE, TRUE)
	if(!isnull(new_description))
		entry[LOADOUT_CUSTOM_DESCRIPTION] = new_description

/datum/character_setup/proc/loadout_set_tagname(list/params)
	var/datum/gear/gear = find_loadout_gear("[params["name"]]")
	var/list/entry = gear ? prefs.has_loadout_gear(prefs.loadout_slot, "[gear.type]") : null
	if(!entry)
		return
	var/mob/user = prefs.parent?.mob
	var/new_tagname = tgui_input_text(user, "Хотите изменить имя на бирке?", "Имя на бирке", entry["loadout_custom_tagname"], MAX_NAME_LEN, FALSE, TRUE)
	if(!isnull(new_tagname))
		entry["loadout_custom_tagname"] = new_tagname

/datum/character_setup/proc/loadout_set_examtooltip(list/params)
	var/datum/gear/gear = find_loadout_gear("[params["name"]]")
	var/list/entry = gear ? prefs.has_loadout_gear(prefs.loadout_slot, "[gear.type]") : null
	if(!entry)
		return
	var/mob/user = prefs.parent?.mob
	var/list/current = entry["loadout_examtooltip"]
	var/new_text = tgui_input_text(user, "Это описание будет видно при осмотре персонажа с вещью. Отмена - очистить.", "Дополнительное описание", islist(current) ? current[1] : null, MAX_MESSAGE_LEN, TRUE, TRUE)
	if(!new_text)
		entry -= "loadout_examtooltip"
		return
	entry["loadout_examtooltip"] = list(new_text, TRUE)
	var/keep = tgui_alert(user, "Оставлять описание даже после снятия предмета с персонажа?", "Постоянное описание", list("Нет", "Да"))
	if(keep == "Да")
		entry["loadout_examtooltip"][2] = FALSE

/datum/character_setup/proc/loadout_set_heirloom(list/params)
	var/datum/gear/gear = find_loadout_gear("[params["name"]]")
	var/list/entry = gear ? prefs.has_loadout_gear(prefs.loadout_slot, "[gear.type]") : null
	if(!entry)
		return
	var/mob/user = prefs.parent?.mob
	if(!params["value"])
		entry[LOADOUT_IS_HEIRLOOM] = FALSE
		return
	if(ispath_in_list(gear.path, LOADOUT_IS_DISALLOWED_HEIRLOOM))
		to_chat(user, span_danger("Это не подойдёт в качестве семейной реликвии!"))
		return
	if(prefs.find_gear_with_property(prefs.loadout_slot, LOADOUT_IS_HEIRLOOM, TRUE))
		to_chat(user, span_danger("У вас уже выбрана ваша семейная реликвия!"))
		return
	entry[LOADOUT_IS_HEIRLOOM] = TRUE

/datum/character_setup/proc/loadout_clear_invalid(list/params)
	var/raw_path = "[params["item"]]"
	if(!length(raw_path))
		return
	var/list/chosen_gear = prefs.loadout_data["SAVE_[prefs.loadout_slot]"]
	for(var/list/entry in chosen_gear)
		if(entry[LOADOUT_ITEM] == raw_path)
			chosen_gear -= list(entry)
			break

/datum/character_setup/proc/loadout_show_ckey_id()
	var/mob/user = prefs.parent?.mob
	if(!user)
		return
	var/ckey_id = gear_ckey_id(user.key)
	if(ckey_id)
		to_chat(user, span_notice("При добавлении персональной вещи вы можете отправить этот ID разработчику вместо вашего ckey: <b>«<code>[ckey_id]</code>»</b>."), confidential = TRUE)
	else
		to_chat(user, span_warning("Не удалось получить ckey ID. Сообщите администрации: шифрование лодаута недоступно."), confidential = TRUE)

/datum/character_setup/proc/build_mutant_parts_data(mob/user)
	var/list/parts = list()
	var/datum/species/species = prefs.pref_species
	if(!species || !prefs.parent)
		return parts
	for(var/part in GLOB.all_mutant_parts)
		if(part == "mam_body_markings")
			continue
		var/show_part = prefs.parent.can_have_part(part)
		if(part in GLOB.mismatched_toggle_parts)
			show_part = show_part && species.id == SPECIES_XENOHYBRID
		if(!show_part && !(prefs.show_mismatched_markings && (part in GLOB.mismatched_toggle_parts)))
			continue

		var/emissive_key = part
		switch(part)
			if("mam_tail", "tail_lizard", "tail_human")
				emissive_key = "tail"
			if("mam_ears")
				emissive_key = "ears"
			if("mam_snouts")
				emissive_key = "snout"

		var/part_label = ru_strings["[part]"] || GLOB.all_mutant_parts[part] || part
		parts += list(list(
			"key" = part,
			"label" = part_label,
			"value" = prefs.features[part] || "",
			"options" = mutant_part_options(part),
			"glowKey" = emissive_key,
			"hasGlow" = (emissive_key in GLOB.emissive_parts_list),
			"glow" = emissive_part_enabled(prefs.features, emissive_key),
			"colors" = mutant_part_colors(part),
		))
	return parts

/datum/character_setup/proc/mutant_part_colors(part)
	var/list/rows = list()
	if(!(part in GLOB.all_mutant_parts))
		return rows
	var/list/feats = prefs.features
	var/list/species_parts = prefs.pref_species.mutant_bodyparts
	var/color_type = GLOB.colored_mutant_parts[part]
	if(color_type)
		if(!feats[color_type])
			feats[color_type] = feats["wings_color"]
		rows += list(part_color_row("Цвет", color_type, feats[color_type]))

		var/part_value = feats[part] || (species_parts ? species_parts[part] : null)
		var/list/reference = GLOB.mutant_reference_list[part]
		if(!part_value || part_value == "None" || !reference)
			return rows
		var/datum/sprite_accessory/accessory_extra = reference[part_value]
		if(!accessory_extra?.extra)
			return rows
		if(accessory_extra.extra_color_src != MUTCOLORS && accessory_extra.extra_color_src != MUTCOLORS2 && accessory_extra.extra_color_src != MUTCOLORS3)
			return rows
		if(feats["color_scheme"] != ADVANCED_CHARACTER_COLORING)
			if(!feats["mcolor2"])
				feats["mcolor2"] = "FFFFFF"
			if(!feats["mcolor3"])
				feats["mcolor3"] = "FFFFFF"
			rows += list(part_color_row("Вторичный цвет", "mcolor2", feats["mcolor2"]))
			if(accessory_extra.extra2 && (accessory_extra.extra2_color_src == MUTCOLORS || accessory_extra.extra2_color_src == MUTCOLORS2 || accessory_extra.extra2_color_src == MUTCOLORS3))
				rows += list(part_color_row("Третичный цвет", "mcolor3", feats["mcolor3"]))
			return rows
		var/mutant_string_extra = accessory_extra.mutant_part_string
		var/secondary_extra = "[mutant_string_extra]_secondary"
		var/tertiary_extra = "[mutant_string_extra]_tertiary"
		if(!feats[secondary_extra])
			feats[secondary_extra] = feats["mcolor2"]
		if(!feats[tertiary_extra])
			feats[tertiary_extra] = feats["mcolor3"]
		rows += list(part_color_row("Вторичный цвет", secondary_extra, feats[secondary_extra]))
		if(accessory_extra.extra2 && (accessory_extra.extra2_color_src == MUTCOLORS || accessory_extra.extra2_color_src == MUTCOLORS2 || accessory_extra.extra2_color_src == MUTCOLORS3))
			rows += list(part_color_row("Третичный цвет", tertiary_extra, feats[tertiary_extra]))
		return rows

	if(feats["color_scheme"] != ADVANCED_CHARACTER_COLORING)
		return rows
	var/part_value = feats[part] || (species_parts ? species_parts[part] : null)
	var/list/reference = GLOB.mutant_reference_list[part]
	if(!part_value || part_value == "None" || !reference)
		return rows
	var/datum/sprite_accessory/accessory = reference[part_value]
	if(!accessory)
		return rows
	if(accessory.color_src != MATRIXED && accessory.color_src != MUTCOLORS && accessory.color_src != MUTCOLORS2 && accessory.color_src != MUTCOLORS3)
		return rows

	var/mutant_string = accessory.mutant_part_string
	var/primary = "[mutant_string]_primary"
	var/secondary = "[mutant_string]_secondary"
	var/tertiary = "[mutant_string]_tertiary"
	if(!feats[primary])
		feats[primary] = feats["mcolor"]
	if(!feats[secondary])
		feats[secondary] = feats["mcolor2"]
	if(!feats[tertiary])
		feats[tertiary] = feats["mcolor3"]

	var/matrixed_sections = accessory.matrixed_sections
	if(accessory.color_src == MATRIXED && !matrixed_sections)
		message_admins("Sprite Accessory Failure (customization): Accessory [accessory.type] is a matrixed item without any matrixed sections set!")
		return rows
	else if(accessory.color_src == MATRIXED)
		switch(matrixed_sections)
			if(MATRIX_GREEN)
				primary = secondary
			if(MATRIX_BLUE)
				primary = tertiary
			if(MATRIX_RED_BLUE)
				secondary = tertiary
			if(MATRIX_GREEN_BLUE)
				primary = secondary
				secondary = tertiary

	rows += list(part_color_row("Основной цвет", primary, feats[primary]))
	var/show_secondary = (accessory.color_src == MATRIXED && (matrixed_sections == MATRIX_RED_BLUE || matrixed_sections == MATRIX_GREEN_BLUE || matrixed_sections == MATRIX_RED_GREEN || matrixed_sections == MATRIX_ALL)) || (accessory.extra && (accessory.extra_color_src == MUTCOLORS || accessory.extra_color_src == MUTCOLORS2 || accessory.extra_color_src == MUTCOLORS3))
	if(!show_secondary)
		return rows
	rows += list(part_color_row("Вторичный цвет", secondary, feats[secondary]))
	var/show_tertiary = (accessory.color_src == MATRIXED && matrixed_sections == MATRIX_ALL) || (accessory.extra2 && (accessory.extra2_color_src == MUTCOLORS || accessory.extra2_color_src == MUTCOLORS2 || accessory.extra2_color_src == MUTCOLORS3))
	if(show_tertiary)
		rows += list(part_color_row("Третичный цвет", tertiary, feats[tertiary]))
	return rows

/datum/character_setup/proc/part_color_row(label, key, value)
	var/list/row = list(
		"label" = label,
		"key" = key,
		"value" = color_to_ui(value) || "#ffffff",
		"colorCheck" = mutant_color_flavor(key),
	)
	var/black_reset = mutant_color_black_reset(key)
	if(black_reset)
		row["blackReset"] = black_reset
	return row

/datum/character_setup/proc/mutant_color_flavor(key)
	switch(key)
		if("horns_color", "wings_color", "insect_fluff_color", "insect_markings_color")
			return FEATURE_COLOR_RESET
		if("mcolor", "mcolor2", "mcolor3")
			return FEATURE_COLOR_MUTANT
	return FEATURE_COLOR_LIMITED

/datum/character_setup/proc/mutant_color_black_reset(key)
	switch(key)
		if("horns_color")
			return "85615A"
		if("wings_color", "insect_fluff_color", "insect_markings_color")
			return "FFFFFF"
	return null

/datum/character_setup/proc/apply_mutant_part_cascade(part, value)
	if(!value || value == "None")
		return
	var/list/features = prefs.features
	switch(part)
		if("tail_lizard")
			features["taur"] = "None"
			features["tail_human"] = "None"
			features["mam_tail"] = "None"
		if("tail_human")
			features["taur"] = "None"
			features["tail_lizard"] = "None"
			features["mam_tail"] = "None"
		if("mam_tail")
			features["taur"] = "None"
			features["tail_human"] = "None"
			features["tail_lizard"] = "None"
		if("xenotail")
			features["mam_tail"] = "None"
			features["taur"] = "None"
			features["tail_human"] = "None"
			features["tail_lizard"] = "None"
		if("taur")
			features["mam_tail"] = "None"
			features["xenotail"] = "None"
			features["tail_human"] = "None"
			features["tail_lizard"] = "None"
			features["arachnid_spinneret"] = "None"
		if("snout")
			features["mam_snouts"] = "None"
		if("mam_snouts")
			features["snout"] = "None"

/datum/character_setup/proc/build_antag_opt_in_data()
	var/list/levels = list()
	for(var/level in ANTAG_OPT_IN_NOT_TARGET to ANTAG_OPT_IN_ROUND_REMOVE)
		levels += list(list(
			"value" = level,
			"name" = antag_opt_in_level_name(level),
			"color" = antag_opt_in_level_color(level),
			"description" = GLOB.antag_opt_in_descriptions["[level]"],
		))
	var/pref_level = prefs.get_antag_opt_in_pref_level()
	var/forced_level = CONFIG_GET(number/antag_opt_in_antag_enabled_min)
	var/list/forced = null
	if(forced_level > pref_level && antag_opt_in_prefs_force_minimum(prefs))
		forced = list(
			"name" = antag_opt_in_level_name(forced_level),
			"color" = antag_opt_in_level_color(forced_level),
		)
	return list(
		"level" = pref_level,
		"custom" = !isnull(prefs.antag_opt_in_level),
		"levels" = levels,
		"thresholds" = antag_opt_in_thresholds_text(),
		"disclaimer" = GLOB.antag_opt_in_disclaimer,
		"forced" = forced,
	)

/datum/character_setup/proc/sanitize_color_value(raw, flavor, black_reset, current_value, no_black_reset)
	if(!istext(raw))
		return null
	if(!findtext(raw, "#"))
		raw = "#[raw]"
	if(!no_black_reset && flavor != FEATURE_COLOR_PLAIN && raw == "#000000")
		var/reset_to = black_reset || prefs.pref_species?.default_color
		if(reset_to && current_value != reset_to)
			return reset_to
	if(flavor == FEATURE_COLOR_PLAIN || flavor == FEATURE_COLOR_RESET)
		return sanitize_hexcolor(raw, 6)
	var/temp_hsv = RGBtoHSV(raw)
	var/bright_enough = ReadHSV(temp_hsv)[3] >= ReadHSV(MINIMUM_MUTANT_COLOR)[3]
	var/parts_only = (flavor == FEATURE_COLOR_MUTANT) && (MUTCOLORS_PARTSONLY in prefs.pref_species.species_traits)
	if(!parts_only && !bright_enough && CONFIG_GET(flag/character_color_limits))
		to_chat(usr, span_danger("Этот цвет слишком тёмный для выбранной части тела."))
		return null
	return sanitize_hexcolor(raw, 6)

/datum/character_setup/proc/set_feature(list/params)
	var/key = params["key"]
	if(!istext(key))
		return
	var/list/field
	for(var/list/candidate in get_feature_fields())
		if(candidate["key"] == key)
			field = candidate
			break
	if(!field)
		return

	var/scope = field["scope"]
	var/raw = params["value"]
	if(!isnull(params["dir"]))
		var/list/options = list()
		var/current = read_feature_raw(key, scope)
		switch(field["type"])
			if(FEATURE_LIST)
				for(var/option in field["options"])
					options += option
				if(field["deletable"])
					options.Insert(1, "")
					if(!current)
						current = ""
			if(FEATURE_REAGENT)
				for(var/list/option in field["options"])
					options += option["type"]
				current = "[current]"
			else
				return
		raw = cycle_choice(current, options, params["dir"])
		if(isnull(raw))
			return
	switch(field["type"])
		if(FEATURE_BOOL)
			write_feature(key, raw ? TRUE : FALSE, scope)
			apply_bool_cascade(key, raw ? TRUE : FALSE)

		if(FEATURE_NUM)
			var/number = num_param(raw)
			if(isnull(number))
				return
			if(field["deletable"] && !number)
				prefs.features -= key
				preview_dirty = TRUE
				return
			if(!isnull(field["min"]))
				number = max(number, field["min"])
			if(!isnull(field["max"]))
				number = min(number, field["max"])
			if(field["clampTo"])
				var/limit = num_param(read_feature_raw(field["clampTo"], FEATURE_SCOPE_FEATURE))
				if(!isnull(limit))
					number = field["clampBelow"] ? min(number, limit) : max(number, limit)
			if(field["scale"])
				number = number / field["scale"]
			write_feature(key, number, scope)

		if(FEATURE_LIST)
			if(field["deletable"] && (isnull(raw) || !length("[raw]")))
				prefs.features -= key
				preview_dirty = TRUE
				return
			if(!(raw in field["options"]))
				return
			write_feature(key, raw, scope)
			apply_list_cascade(key, raw)

		if(FEATURE_REAGENT)
			var/allowed_fluid = FALSE
			for(var/list/option in field["options"])
				if(option["type"] == raw)
					allowed_fluid = TRUE
					break
			if(!allowed_fluid)
				return
			var/fluid_type = text2path(raw)
			if(!fluid_type)
				return
			write_feature(key, fluid_type, scope)

		if(FEATURE_COLOR)
			var/current = read_feature_raw(key, scope)
			var/new_color = sanitize_color_value(isnull(raw) ? params["color"] : raw, field["colorCheck"], null, current)
			if(isnull(new_color))
				return
			write_feature(key, new_color, scope)

		if(FEATURE_CYCLE)
			if(!(raw in field["options"]))
				return
			var/old_value = read_feature_value(field)
			write_feature(key, raw, scope)
			apply_consent_cascade(key, raw, old_value)

/datum/character_setup/proc/write_feature(key, value, scope)
	if(scope == FEATURE_SCOPE_PREF)
		if(!(key in prefs.vars))
			return FALSE
		prefs.vars[key] = value
		preview_dirty = TRUE
		return TRUE
	if(!prefs.features)
		prefs.features = list()
	prefs.features[key] = value
	preview_dirty = TRUE
	return TRUE

/datum/character_setup/proc/apply_bool_cascade(key, new_value)
	switch(key)
		if("split_eye_colors")
			prefs.right_eye_color = prefs.left_eye_color
		if("has_cock")
			if(!new_value)
				prefs.features["has_balls"] = FALSE
		if("has_vag")
			if(!new_value)
				prefs.features["has_womb"] = FALSE
		if("has_breasts")
			if(!new_value)
				prefs.features["breasts_producing"] = FALSE
		if("has_butt")
			if(!new_value)
				prefs.features["has_anus"] = FALSE
		if("has_belly")
			if(!new_value)
				prefs.features["belly_size"] = BELLY_SIZE_DEF

/datum/character_setup/proc/apply_list_cascade(key, new_value)
	switch(key)
		if("breasts_sprite_variant")
			if(new_value == "Old")
				prefs.features["breasts_nipples"] = FALSE

/datum/character_setup/proc/set_cock_shape(list/params)
	var/choice = params["value"]
	if(!isnull(params["dir"]))
		var/list/shapes = build_cock_shape_data()
		choice = cycle_choice(shapes["value"], shapes["options"], params["dir"])
	if(!istext(choice))
		return
	var/list/tauric = cock_taur_shapes()
	var/tauric_choice = FALSE
	var/stored = choice
	if(tauric[choice])
		stored = tauric[choice]
		tauric_choice = TRUE
	if(!(stored in GLOB.cock_shapes_list))
		return
	prefs.features["cock_taur"] = tauric_choice
	prefs.features["cock_shape"] = stored
	preview_dirty = TRUE

/datum/character_setup/proc/apply_consent_cascade(key, new_value, old_value)
	switch(key)
		if("extremepref")
			if(new_value == "No" && old_value != "No")
				prefs.extremeharm = "No"
		if("nonconpref")
			var/mob/living/body = usr?.mind?.current
			if(isliving(body))
				message_admins("[usr.ckey]/[body.real_name] [ADMIN_FLW(body)][body.stat == DEAD ? " (DEAD)" : ""] меняет Non-Con с [old_value] на [new_value].")
				log_admin("[usr.ckey]/[body.real_name][body.stat == DEAD ? " (DEAD)" : ""] меняет Non-Con с [old_value] на [new_value].")
				body.balloon_alert_to_viewers("Non-Con: [old_value] -> [new_value]")

/datum/character_setup/proc/set_part_color(list/params)
	var/part = params["part"]
	var/key = params["key"]
	if(!istext(part) || !istext(key))
		return
	var/list/row
	for(var/list/candidate in mutant_part_colors(part))
		if(candidate["key"] == key)
			row = candidate
			break
	if(!row)
		return
	var/new_color = sanitize_color_value(params["color"], row["colorCheck"], row["blackReset"], prefs.features[key])
	if(isnull(new_color))
		return
	prefs.features[key] = new_color
	preview_dirty = TRUE

/datum/character_setup/proc/set_mutant_part(list/params)
	var/part = params["part"]
	if(!istext(part))
		return
	if(!(part in GLOB.all_mutant_parts) || part == "mam_body_markings")
		return
	var/is_cycle = !isnull(params["dir"])
	var/list/options = mutant_part_options(part, is_cycle)
	var/new_value = is_cycle ? cycle_choice(prefs.features[part], options, params["dir"]) : params["value"]
	if(!istext(new_value) || !(new_value in options))
		return
	prefs.features[part] = new_value
	apply_mutant_part_cascade(part, new_value)
	preview_dirty = TRUE

/datum/character_setup/proc/cycle_choice(current, list/options, direction)
	if(!length(options) || !(direction in list("prev", "next")))
		return null
	// После смены вида сохранённая часть может отсутствовать среди доступных вариантов.
	if(!options.Find(current))
		return direction == "next" ? options[1] : options[length(options)]
	return direction == "next" ? next_list_item(current, options) : previous_list_item(current, options)

/datum/character_setup/proc/hair_style_options(list/reference, user_key)
	var/list/options = list()
	for(var/style in prefs.filter_accessories_by_ckey(reference, user_key))
		options += style
	return options

/datum/character_setup/proc/cycle_hair_style(list/params)
	if(!prefs.parent || !prefs.pref_species)
		return
	var/pref_key
	var/list/reference
	var/required_trait = HAIR
	switch(params["kind"])
		if("hair")
			pref_key = "hair_style"
			reference = GLOB.hair_styles_list
		if("facial")
			pref_key = "facial_hair_style"
			reference = GLOB.facial_hair_styles_list
			required_trait = FACEHAIR
		if("grad")
			pref_key = "grad_style"
			reference = GLOB.hair_gradients_list
		else
			return
	if(!(required_trait in prefs.pref_species.species_traits))
		return
	var/list/options = prefs.filter_accessories_by_ckey(reference, prefs.parent.ckey)
	var/new_value = isnull(params["dir"]) ? params["value"] : cycle_choice(prefs.vars[pref_key], options, params["dir"])
	if(!(new_value in options))
		return
	if(isnull(new_value))
		return
	prefs.vars[pref_key] = new_value
	preview_dirty = TRUE

/datum/character_setup/proc/bg_state_options()
	return list("000", "midgrey", "FFF", "white", "steel", "techmaint", "dark", "plating", "reinforced")

/datum/character_setup/proc/apply_species_change(species_name)
	if(!istext(species_name))
		return
	var/species_id = GLOB.roundstart_race_names[species_name]
	var/newtype = species_id ? GLOB.species_list[species_id] : null
	if(!newtype)
		return

	prefs.pref_species = new newtype()
	prefs.drop_locked_body_mods()
	prefs.custom_species = null
	if(!prefs.parent?.can_have_part("mam_body_markings"))
		prefs.features["mam_body_markings"] = list()
	if(prefs.parent?.can_have_part("mam_body_markings") && prefs.features["mam_body_markings"] == "None")
		prefs.features["mam_body_markings"] = list()
	if(prefs.parent?.can_have_part("tail_lizard"))
		prefs.features["tail_lizard"] = "Smooth"
	if(prefs.pref_species.id == "felinid")
		prefs.features["mam_tail"] = "Cat"
		prefs.features["mam_ears"] = "Cat"

	if(prefs.pref_species.id == SPECIES_XENOHYBRID)
		prefs.features["xenohead"] = "Standard"
		prefs.features["xenodorsal"] = "Standard"
	else
		prefs.features["xenohead"] = "None"
		prefs.features["xenodorsal"] = "None"

	recheck_mutant_colors()
	prefs.eye_type = prefs.pref_species.eye_type
	preview_dirty = TRUE

/datum/character_setup/proc/recheck_mutant_colors()
	var/list/features = prefs.features
	var/datum/species/species = prefs.pref_species
	var/temp_hsv = RGBtoHSV(features["mcolor"])
	for(var/color_key in list("mcolor", "mcolor2", "mcolor3"))
		if(features[color_key] == "#000000" || (!(MUTCOLORS_PARTSONLY in species.species_traits) && ReadHSV(temp_hsv)[3] < ReadHSV("#202020")[3]))
			features[color_key] = species.default_color

/datum/character_setup/proc/skin_tone_options()
	var/list/choices = list()
	for(var/tone in (GLOB.skin_tones - GLOB.nonstandard_skin_tones))
		choices += tone
	if(CONFIG_GET(flag/allow_custom_skintones))
		choices += "custom"
	return choices

/datum/character_setup/proc/apply_skin_tone(value)
	if(!istext(value))
		return
	var/list/choices = skin_tone_options()

	if(value == "custom")
		if(!("custom" in choices))
			return
		var/default = prefs.use_custom_skin_tone ? prefs.skin_tone : null
		var/custom_tone = tgui_input_color(usr, "Выберите свой тон кожи.", "Настройка персонажа", default)
		if(!custom_tone)
			return
		apply_custom_skin_tone(custom_tone)
		preview_dirty = TRUE
		return

	if(findtext(value, "#"))
		if(!apply_custom_skin_tone(value))
			return
		preview_dirty = TRUE
		return

	if(!(value in choices))
		return
	prefs.use_custom_skin_tone = FALSE
	prefs.skin_tone = value
	preview_dirty = TRUE

/datum/character_setup/proc/apply_custom_skin_tone(custom_tone)
	if(!istext(custom_tone))
		return FALSE
	if(!findtext(custom_tone, "#"))
		custom_tone = "#[custom_tone]"
	var/temp_hsv = RGBtoHSV(custom_tone)
	if(ReadHSV(temp_hsv)[3] < ReadHSV("#333333")[3] && CONFIG_GET(flag/character_color_limits))
		to_chat(usr, span_danger("Invalid color. Your color is not bright enough."))
		return FALSE
	prefs.use_custom_skin_tone = TRUE
	prefs.skin_tone = custom_tone
	return TRUE

/datum/character_setup/proc/apply_body_weight(new_weight)
	if(!istext(new_weight) || !(new_weight in GLOB.mob_sizes))
		return
	if(prefs.all_quirks.Find(/datum/quirk/bluemoon_devourer::name))
		to_chat(usr, span_warning("Квирк Пожиратель несовместим с любым весом кроме стандартного."))
		return
	var/balance = quirk_balance()
	var/balance_check = balance - prefs.mob_size_name_to_quirk_cost(new_weight) + prefs.mob_size_name_to_quirk_cost(prefs.body_weight)
	if(balance_check < min(0, balance))
		to_chat(usr, span_warning("Для взятия данного веса нужно ещё [abs(balance_check)] очков квирков."))
		return
	prefs.body_weight = new_weight
	preview_dirty = TRUE

/datum/character_setup/proc/set_limb_modification(list/params)
	var/zone = "[params["zone"]]"
	if(!(zone in LOADOUT_ALLOWED_LIMB_TARGETS))
		return
	var/value = "[params["value"]]"
	var/kind
	var/brand
	if(value in LOADOUT_LIMBS)
		kind = value
	else if(value == "prosthetic" || (value in GLOB.prosthetic_limb_types))
		var/list/current = prefs.modified_limbs[zone]
		if(!islist(current) || current[1] != LOADOUT_LIMB_PROSTHETIC)
			return
		brand = value
		kind = LOADOUT_LIMB_PROSTHETIC
	else
		return
	var/old_bonus = 0
	var/list/current_entry = prefs.modified_limbs[zone]
	if(islist(current_entry) && length(current_entry))
		old_bonus = prefs.limb_modification_bonus(current_entry[1])
	var/new_bonus = prefs.limb_modification_bonus(kind)
	if(new_bonus < old_bonus && quirk_balance() - old_bonus + new_bonus < 0)
		to_chat(usr, span_warning("Изменение этой конечности увёло бы баланс в минус!"))
		return
	if(kind == LOADOUT_LIMB_NORMAL)
		prefs.modified_limbs -= zone
		preview_dirty = TRUE
		return
	if(kind == LOADOUT_LIMB_PROSTHETIC)
		if(!brand)
			var/list/previous = prefs.modified_limbs[zone]
			if(islist(previous) && length(previous) > 1)
				brand = previous[2]
		if(brand != "prosthetic" && !(brand in GLOB.prosthetic_limb_types))
			brand = "prosthetic"
		var/prosthetic_count = 0
		for(var/modified_limb in prefs.modified_limbs)
			if(prefs.modified_limbs[modified_limb][1] == LOADOUT_LIMB_PROSTHETIC && modified_limb != zone)
				prosthetic_count++
		if(prosthetic_count >= MAXIMUM_LOADOUT_PROSTHETICS)
			to_chat(usr, span_danger("Нельзя иметь больше [MAXIMUM_LOADOUT_PROSTHETICS] протезов!"))
			return
		prefs.modified_limbs[zone] = list(kind, brand)
	else
		prefs.modified_limbs[zone] = list(kind)
	preview_dirty = TRUE

/datum/character_setup/proc/set_organ_modification(list/params)
	var/mob/user = prefs.parent?.mob
	if(!user)
		return
	var/slot = "[params["slot"]]"
	var/list/option = prefs.body_mod_organ_option(slot, "[params["value"]]")
	if(!option)
		return
	if(prefs.body_mod_organ_locked(slot))
		to_chat(user, span_warning("Вид этого персонажа не позволяет заменить этот орган."))
		return
	var/old_cost = 0
	var/list/old_option = prefs.body_mod_organ_option(slot, prefs.organ_mods[slot])
	if(old_option)
		old_cost = old_option["cost"]
	if(isnull(option["path"]))
		prefs.organ_mods -= slot
		return
	var/balance = quirk_balance()
	if(balance + old_cost - option["cost"] < min(0, balance))
		to_chat(user, span_warning("Недостаточно баланса: нужно ещё [option["cost"] - quirk_balance() - old_cost] очков квирков."))
		return
	prefs.organ_mods[slot] = option["id"]

/datum/character_setup/proc/toggle_body_implant(list/params)
	var/mob/user = prefs.parent?.mob
	if(!user)
		return
	var/implant_id = "[params["id"]]"
	var/list/option = prefs.body_mod_implant_option(implant_id)
	if(!option)
		return
	var/balance = quirk_balance()
	if(prefs.implant_mods[implant_id])
		if(balance + option["cost"] < min(0, balance))
			to_chat(user, span_warning("Возврат этого импланта увёл бы баланс в минус!"))
			return
		prefs.implant_mods -= implant_id
		return
	if(balance - option["cost"] < min(0, balance))
		to_chat(user, span_warning("Недостаточно баланса для этого импланта!"))
		return
	prefs.implant_mods[implant_id] = TRUE

/datum/character_setup/proc/build_options_static()
	if(options_cache)
		return options_cache
	var/list/pda_theme_options = list()
	for(var/theme_name in GLOB.pda_name_to_theme)
		pda_theme_options += list(list("label" = theme_name, "value" = GLOB.pda_name_to_theme[theme_name]))

	var/list/pda_skin_options = list()
	for(var/skin_name in GLOB.pda_reskins)
		pda_skin_options += skin_name

	var/list/lawset_options = list("None")
	var/list/config_laws = CONFIG_GET(keyed_list/choosable_laws)
	for(var/lawset_name in config_laws)
		lawset_options += lawset_name

	options_cache = list(
		"securityDepts" = GLOB.security_depts_prefs,
		"aiCoreScreens" = GLOB.ai_core_display_screens,
		"pdaStyles" = GLOB.pda_styles,
		"pdaReskins" = pda_skin_options,
		"pdaThemes" = pda_theme_options,
		"lawsets" = lawset_options,
	)
	return options_cache

/datum/character_setup/ui_data(mob/user)
	var/list/data = preview_data(user)
	if(!prefs)
		return data

	data["slotNames"] = prefs.get_slot_names() || list()
	data["slotCustomNames"] = prefs.get_slot_custom_names() || list()
	data["characterSlotName"] = prefs.character_slot_name
	data["slotNameReplace"] = prefs.character_slot_name_replace
	data["defaultSlot"] = prefs.default_slot
	data["characterRevision"] = character_revision
	data["characterName"] = prefs.real_name
	data["speciesName"] = prefs.pref_species.name
	data["tab"] = prefs.character_settings_tab
	data["theme"] = prefs.character_setup_theme
	data["autoSaveOnSwitch"] = prefs.character_setup_autosave
	data["autoSaveActivePreset"] = prefs.character_setup_preset_autosave
	var/list/presets_data = list()
	var/static/list/job_icon_states = icon_states('icons/ui_icons/tgui/jobs.dmi')
	for(var/preset_name in prefs.character_presets)
		var/list/preset = prefs.character_presets[preset_name]
		var/datum/job/highest_job = prefs.get_highest_job(preset["job_preferences"])
		var/job_icon = ckey(highest_job?.title)
		presets_data += list(list(
			"name" = preset_name,
			"jobs" = length(preset["job_preferences"]),
			"quirks" = length(preset["all_quirks"]),
			"items" = length(preset["loadout"]),
			"jobTitle" = highest_job?.title,
			"jobIcon" = (highest_job && (job_icon in job_icon_states)) ? job_icon : "no_id",
		))
	data["characterPresets"] = presets_data
	data["presetLimit"] = MAX_CHARACTER_PRESETS
	data["activeCharacterPreset"] = prefs.active_character_preset
	data["selectedCharacterPreset"] = selected_character_preset
	data["emissivesAllowed"] = !!prefs.features["allow_emissives"]
	data["hasUnsavedChanges"] = character_state() != saved_character_state
	data["saveNotice"] = save_notice
	data["playingSoundPreview"] = world.time < sound_preview_until ? sound_preview_kind : null

	data["localStorageName"] = prefs.get_local_storage_name(user.client)
	data["offerActive"] = !!prefs.offer
	if(prefs.offer)
		data["redemptionCode"] = prefs.offer.redemption_code

	switch(prefs.character_settings_tab)
		if(GENERAL_CHAR_TAB)
			data["general"] = build_general_data(user)
		if(BACKGROUND_CHAR_TAB)
			data["background"] = build_background_data()
		if(MARKINGS_CHAR_TAB)
			data["markings"] = build_markings_data()
		if(SPEECH_CHAR_TAB)
			data["speech"] = build_speech_data()
		if(LOADOUT_CHAR_TAB)
			data["loadout"] = build_loadout_data(user)
		if(QUIRKS_CHAR_TAB)
			data["quirksTab"] = build_quirks_data()
		if(MODIFICATIONS_CHAR_TAB)
			data["modsTab"] = build_modifications_data()

	if(prefs.character_settings_tab == GENERAL_CHAR_TAB || prefs.character_settings_tab == APPEARANCE_CHAR_TAB)
		data["appearance"] = build_appearance_data(user, prefs.character_settings_tab == APPEARANCE_CHAR_TAB)

	schedule_preview_update()
	return data

// Камера не меняет настройки вкладки: отправляем только её собственные поля.
/datum/character_setup/proc/preview_data(mob/user)
	var/list/data = list()
	if(!prefs)
		return data
	data["previewPref"] = preview_mode
	data["previewAroused"] = preview_aroused
	data["previewSingleView"] = prefs.character_setup_single_view
	data["previewDirection"] = preview_direction
	data["previewZoom"] = preview_zoom
	data["previewReference"] = preview_reference
	data["previewBackgroundStyle"] = preview_background_style
	data["previewBackground"] = prefs.bgstate
	data["previewBackgrounds"] = bg_state_options()
	var/atom/movable/screen/map_view/character_setup_screen/viewer_screen = LAZYACCESS(viewer_screens, user)
	data["previewRef"] = viewer_screen?.assigned_map
	data["previewAutoFit"] = preview_auto_fit
	data["previewViewportReady"] = viewer_screen && !isnull(viewer_screen.viewport_aspect)
	data["previewDirty"] = preview_dirty
	return data

/datum/character_setup/proc/build_tabs_data()
	return list(
		list("id" = GENERAL_CHAR_TAB, "label" = "Общее", "icon" = "user"),
		list("id" = BACKGROUND_CHAR_TAB, "label" = "Прошлое", "icon" = "book"),
		list("id" = APPEARANCE_CHAR_TAB, "label" = "Внешность", "icon" = "palette"),
		list("id" = MARKINGS_CHAR_TAB, "label" = "Маркинги", "icon" = "highlighter"),
		list("id" = MODIFICATIONS_CHAR_TAB, "label" = "Модификации", "icon" = "robot"),
		list("id" = SPEECH_CHAR_TAB, "label" = "Речь", "icon" = "comment"),
		list("id" = QUIRKS_CHAR_TAB, "label" = "Особенности", "icon" = "brain"),
		list("id" = LOADOUT_CHAR_TAB, "label" = "Экипировка", "icon" = "tshirt"),
	)

/datum/character_setup/proc/build_general_data(mob/user)
	var/list/data = list()

	data["name"] = prefs.real_name
	data["nameless"] = prefs.nameless
	data["age"] = prefs.age
	data["beRandomName"] = prefs.be_random_name
	data["hideCkey"] = prefs.hide_ckey
	data["customBloodColor"] = prefs.custom_blood_color
	data["bloodColor"] = prefs.blood_color
	data["hardsuitWithTail"] = !!prefs.features["hardsuit_with_tail"]

	data["secDept"] = prefs.prefered_security_department
	data["aiCoreDisplay"] = prefs.preferred_ai_core_display

	data["pdaColor"] = prefs.pda_color
	data["pdaStyle"] = prefs.pda_style
	data["pdaSkin"] = prefs.pda_skin
	data["pdaRingtone"] = prefs.pda_ringtone
	var/pda_theme_display = "Неизвестно"
	for(var/theme_name in GLOB.pda_name_to_theme)
		if(GLOB.pda_name_to_theme[theme_name] == prefs.pda_theme)
			pda_theme_display = theme_name
			break
	data["pdaTheme"] = prefs.pda_theme
	data["pdaThemeLabel"] = pda_theme_display

	data["siliconLawset"] = prefs.silicon_lawset
	if(prefs.silicon_lawset)
		var/list/config_laws = CONFIG_GET(keyed_list/choosable_laws)
		var/datum/ai_laws/law_datum = GLOB.all_law_datums[config_laws[prefs.silicon_lawset]]
		if(law_datum)
			data["siliconLawTitle"] = "[law_datum]"
			data["siliconLaws"] = law_datum.get_law_list(TRUE)

	if(CONFIG_GET(flag/roundstart_traits))
		data["quirkBalance"] = quirk_balance()
		data["quirks"] = prefs.all_quirks
		data["quirkValues"] = selected_quirk_values()

	var/list/custom_names_data = list()
	for(var/custom_name_id in GLOB.preferences_custom_names)
		var/list/namedata = prefs.get_custom_namedata(custom_name_id)
		if(!namedata)
			continue
		custom_names_data += list(list(
			"id" = custom_name_id,
			"label" = namedata["pref_name"],
			"hint" = namedata["qdesc"],
			"value" = prefs.custom_names[custom_name_id],
		))
	data["customNames"] = custom_names_data

	return data

/datum/character_setup/proc/selected_quirk_values()
	var/list/values = list()
	if(SSquirks)
		for(var/quirk_name in prefs.all_quirks)
			values[quirk_name] = SSquirks.quirk_points_by_name(quirk_name)
	return values

/datum/character_setup/proc/quirk_balance(list/selected_quirks)
	if(isnull(selected_quirks))
		selected_quirks = prefs.all_quirks
	return prefs.quirk_balance(selected_quirks)

/datum/character_setup/proc/quirk_lock_reason(quirk_name, datum/quirk/quirk_datum, list/selected_quirks)
	if(isnull(selected_quirks))
		selected_quirks = prefs.all_quirks
	if(!SSquirks)
		return "Подсистема особенностей не готова."
	if(initial(quirk_datum.mood_quirk) && CONFIG_GET(flag/disable_human_mood))
		return "Настроение отключено."
	for(var/list/blacklist in SSquirks.quirk_blacklist)
		if(!(quirk_name in blacklist))
			continue
		for(var/other in selected_quirks)
			if(other == quirk_name)
				continue
			if(other in blacklist)
				return "Несовместимо с: [other]"
	return null

/datum/character_setup/proc/sanitize_quirks()
	if(!SSquirks || !length(prefs.all_quirks))
		return
	for(var/quirk_name in prefs.all_quirks.Copy())
		var/datum/quirk/quirk_datum = SSquirks.quirks[quirk_name]
		if(!quirk_datum || quirk_lock_reason(quirk_name, quirk_datum))
			prefs.all_quirks -= quirk_name

/datum/character_setup/proc/quirk_matches_category(value, category)
	if(value > 0)
		return category == QUIRK_POSITIVE
	if(value < 0)
		return category == QUIRK_NEGATIVE
	return category == QUIRK_NEUTRAL

/datum/character_setup/proc/build_quirk_row(quirk_name, datum/quirk/quirk_datum, value)
	var/list/row = list("name" = quirk_name, "value" = value)
	row["desc"] = initial(quirk_datum.desc)
	var/selected = (quirk_name in prefs.all_quirks)
	row["selected"] = selected
	row["cost"] = selected ? value : -value
	var/lock_reason = quirk_lock_reason(quirk_name, quirk_datum)
	row["locked"] = !!lock_reason
	row["lockReason"] = lock_reason
	return row

/datum/character_setup/proc/build_quirks_data()
	var/list/data = list()
	data["enabled"] = !!CONFIG_GET(flag/roundstart_traits)
	if(!data["enabled"])
		return data
	if(!SSquirks || !length(SSquirks.quirks))
		data["loading"] = TRUE
		return data

	sanitize_quirks()

	data["balance"] = quirk_balance()
	data["positiveCount"] = prefs.GetPositiveQuirkCount()
	data["maxPositive"] = MAX_QUIRKS
	data["category"] = prefs.quirk_category
	data["categories"] = list(
		list("value" = QUIRK_POSITIVE, "label" = "Позитивные"),
		list("value" = QUIRK_NEUTRAL, "label" = "Нейтральные"),
		list("value" = QUIRK_NEGATIVE, "label" = "Негативные"),
	)
	data["current"] = prefs.all_quirks
	data["quirkValues"] = selected_quirk_values()

	data["shriek"] = prefs.shriek_type
	var/list/shriek_options = list()
	for(var/shriek in GLOB.shriek_types)
		shriek_options += shriek
	data["shriekOptions"] = shriek_options

	data["summonNickname"] = prefs.summon_nickname
	data["distantStartEnabled"] = prefs.distant_start_enabled

	data["phobia"] = prefs.phobia_type || "Случайная"
	var/list/phobia_options = list("Случайная")
	if(SStraumas && length(SStraumas.phobia_types))
		for(var/phobia in SStraumas.phobia_types)
			phobia_options += phobia
	data["phobiaOptions"] = phobia_options

	data["onelife"] = prefs.onelife_death_type
	var/list/onelife_options = list()
	for(var/form_name in GLOB.onelife_death_forms)
		onelife_options += form_name
	data["onelifeOptions"] = onelife_options

	var/list/selected_rows = list()
	var/list/other_rows = list()
	for(var/quirk_name in SSquirks.quirks)
		var/datum/quirk/quirk_datum = SSquirks.quirks[quirk_name]
		var/value = initial(quirk_datum.value)
		if(!quirk_matches_category(value, prefs.quirk_category))
			continue
		var/list/row = build_quirk_row(quirk_name, quirk_datum, value)
		if(row["selected"])
			selected_rows += list(row)
		else
			other_rows += list(row)

	var/list/rows = list()
	for(var/packed in selected_rows)
		rows += list(packed)
	for(var/packed in other_rows)
		rows += list(packed)
	data["items"] = rows
	return data

/datum/character_setup/proc/build_modifications_data()
	var/list/data = list()
	data["balance"] = quirk_balance()

	var/list/limbs = list()
	var/prosthetic_count = 0
	var/amputation_count = 0
	var/limb_bonus = 0
	for(var/zone in LOADOUT_ALLOWED_LIMB_TARGETS)
		var/list/entry = prefs.modified_limbs[zone]
		var/list/row = list("zone" = zone, "kind" = LOADOUT_LIMB_NORMAL)
		if(islist(entry) && length(entry))
			row["kind"] = entry[1]
			if(length(entry) > 1)
				row["brand"] = entry[2]
		if(row["kind"] == LOADOUT_LIMB_PROSTHETIC)
			prosthetic_count++
		else if(row["kind"] == LOADOUT_LIMB_AMPUTATED)
			amputation_count++
		limb_bonus += prefs.limb_modification_bonus(row["kind"])
		limbs += list(row)
	data["limbs"] = limbs
	data["limbKinds"] = LOADOUT_LIMBS
	data["limbBrands"] = list("prosthetic") + GLOB.prosthetic_limb_types
	data["prostheticCount"] = prosthetic_count
	data["amputationCount"] = amputation_count
	data["limbBonus"] = limb_bonus
	data["maxProsthetics"] = MAXIMUM_LOADOUT_PROSTHETICS
	data["prostheticBonus"] = prefs.limb_modification_bonus(LOADOUT_LIMB_PROSTHETIC)
	data["amputationBonus"] = prefs.limb_modification_bonus(LOADOUT_LIMB_AMPUTATED)
	data["limbMaxDamage"] = /obj/item/bodypart/l_arm::max_damage
	data["prostheticMaxDamage"] = /obj/item/bodypart/l_arm/robot/surplus::max_damage

	var/list/groups = list()
	for(var/list/group in GLOB.body_mod_organ_groups)
		var/slot = group["slot"]
		var/locked = prefs.body_mod_organ_locked(slot)
		var/selected = null
		var/stored = prefs.organ_mods[slot]
		if(stored)
			selected = stored
		else
			for(var/list/default_option in group["options"])
				if(isnull(default_option["path"]))
					selected = default_option["id"]
					break
		var/list/options = list()
		for(var/list/option in group["options"])
			options += list(list("id" = option["id"], "label" = option["label"], "cost" = option["cost"]))
		var/list/group_row = list(
			"slot" = slot,
			"label" = group["label"],
			"options" = options,
			"selected" = selected,
			"locked" = locked,
		)
		if(locked)
			group_row["lockReason"] = "Вид этого персонажа не позволяет заменить этот орган."
		groups += list(group_row)
	data["organs"] = groups

	var/list/implants = list()
	for(var/list/option in GLOB.body_mod_implants)
		implants += list(list(
			"id" = option["id"],
			"label" = option["label"],
			"desc" = option["desc"],
			"cost" = option["cost"],
			"selected" = !!prefs.implant_mods[option["id"]],
		))
	data["implants"] = implants
	return data

/datum/character_setup/proc/quirk_select_category(list/params)
	var/next = "[params["value"]]"
	if(!(next in list(QUIRK_POSITIVE, QUIRK_NEGATIVE, QUIRK_NEUTRAL)))
		return
	prefs.quirk_category = next

/datum/character_setup/proc/quirk_toggle(list/params)
	if(!SSquirks || !length(SSquirks.quirks))
		return
	var/quirk_name = "[params["name"]]"
	if(!SSquirks.quirks[quirk_name])
		return
	var/mob/user = prefs.parent?.mob
	if(!user)
		return

	var/datum/quirk/quirk_datum = SSquirks.quirks[quirk_name]
	var/value = SSquirks.quirk_points[quirk_name]
	// После очистки старого пресета дефицит можно исправлять постепенно, не сбрасывая весь набор.
	var/balance = quirk_balance()

	if(quirk_name in prefs.all_quirks)
		if(balance + value < min(0, balance))
			to_chat(user, span_warning("Возврат этого квирка увёл бы баланс в минус!"))
			return
		prefs.all_quirks -= quirk_name
		return

	var/lock_reason = quirk_lock_reason(quirk_name, quirk_datum)
	if(lock_reason)
		to_chat(user, span_warning("Квирк недоступен: [lock_reason]"))
		return
	if(prefs.GetPositiveQuirkCount() >= MAX_QUIRKS && value > 0)
		to_chat(user, span_warning("Нельзя взять больше [MAX_QUIRKS] позитивных квирков!"))
		return
	if(balance - value < min(0, balance))
		to_chat(user, span_warning("Недостаточно баланса для этого квирка!"))
		return
	prefs.all_quirks += quirk_name

/datum/character_setup/proc/quirk_reset()
	prefs.all_quirks = list()
	if(quirk_balance() < 0)
		prefs.body_weight = NAME_WEIGHT_NORMAL
		preview_dirty = TRUE
		if(quirk_balance() < 0)
			prefs.organ_mods = list()
			prefs.implant_mods = list()

/datum/character_setup/proc/quirk_set_phobia(list/params)
	var/next = "[params["value"]]"
	if(next == "Случайная")
		prefs.phobia_type = null
		return
	if(SStraumas && length(SStraumas.phobia_types) && (next in SStraumas.phobia_types))
		prefs.phobia_type = next

/datum/character_setup/proc/quirk_set_shriek(list/params)
	var/next = "[params["value"]]"
	if(next in GLOB.shriek_types)
		prefs.shriek_type = next

/datum/character_setup/proc/quirk_set_onelife(list/params)
	var/next = "[params["value"]]"
	if(next in GLOB.onelife_death_forms)
		prefs.onelife_death_type = next

/datum/character_setup/proc/quirk_set_nickname(list/params)
	var/mob/user = prefs.parent?.mob
	var/asked = tgui_input_text(user, "Задайте прозвище во время призыва вашего персонажа:", "Особенности", prefs.summon_nickname, MAX_NAME_LEN)
	if(!asked)
		return
	var/checked = reject_bad_name(asked, allow_numbers = TRUE)
	if(!checked)
		to_chat(user, span_warning("Недопустимое имя: от 2 до [MAX_NAME_LEN] символов, только буквы, дефис, апостроф и точка."))
		return
	prefs.summon_nickname = checked

/datum/character_setup/proc/slot_export()
	var/mob/user = prefs.parent?.mob
	if(!user?.client)
		return
	var/savefile/S = prefs.save_character(export = TRUE)
	if(!istype(S, /savefile))
		to_chat(user, span_warning("Не удалось экспортировать персонажа."))
		return
	user.client.local_storage_name_read = FALSE
	user.client.Export(S)
	to_chat(user, span_notice("Персонаж экспортирован в локальную копию."))

/datum/character_setup/proc/slot_import()
	var/mob/user = prefs.parent?.mob
	if(!user?.client)
		return
	var/savefile/S = new(user.client.Import())
	if(!istype(S, /savefile))
		to_chat(user, span_warning("Не удалось импортировать персонажа из локальной копии."))
		return
	if(!prefs.load_character(provided = S))
		to_chat(user, span_warning("Не удалось импортировать персонажа из локальной копии."))
		return
	character_revision++
	preview_dirty = TRUE
	to_chat(user, span_notice("Персонаж импортирован из локальной копии."))
	prefs.save_character(TRUE)

/datum/character_setup/proc/slot_give()
	var/mob/user = prefs.parent?.mob
	if(!user)
		return
	if(prefs.offer)
		qdel(prefs.offer)
		return
	var/savefile/S = prefs.save_character(export = TRUE)
	if(!istype(S, /savefile))
		tgui_alert_async(user, "Не удалось подготовить передачу, попробуйте позже.")
		return
	var/datum/character_offer_instance/offer_datum = new(user.ckey, S)
	if(QDELETED(offer_datum))
		tgui_alert_async(user, "Не удалось подготовить передачу, попробуйте позже.")
		return
	offer_datum.RegisterSignal(user, COMSIG_MOB_CLIENT_LOGOUT, TYPE_PROC_REF(/datum/character_offer_instance, on_quit))
	prefs.offer = offer_datum
	tgui_alert_async(user, "Код передачи: [offer_datum.redemption_code] - отправьте его получателю.")

/datum/character_setup/proc/slot_retrieve()
	var/mob/user = prefs.parent?.mob
	if(!user)
		return
	if(!length(GLOB.character_offers))
		tgui_alert_async(user, "Активных предложений нет.")
		return
	var/retrieve_code = tgui_input_text(user, "Введите 5-значный код передачи.", "Получение персонажа", null, 5)
	if(!retrieve_code)
		return
	if(!text2num(retrieve_code))
		tgui_alert_async(user, "Подходят только цифры.")
		return
	if(length(retrieve_code) != 5)
		tgui_alert_async(user, "Ровно 5 цифр, не больше и не меньше.")
		return
	var/datum/character_offer_instance/offer_datum = LAZYACCESS(GLOB.character_offers, retrieve_code)
	if(!offer_datum)
		tgui_alert_async(user, "Такого кода нет.")
		return
	if(prefs.offer == offer_datum)
		tgui_alert_async(user, "Нельзя принять собственное предложение.")
		return

	var/savefile/offered_file = offer_datum.character_savefile
	var/mob/living/the_owner = get_mob_by_ckey(offer_datum.owner_ckey)
	if(prefs.savefile_needs_update(offered_file) == -2)
		tgui_alert_async(user, "Этот сейвфайл повреждён.")
		to_chat(the_owner, span_boldwarning("Что-то пошло не так при передаче, она отменена."))
		qdel(offer_datum)
		return

	var/character_name
	offered_file["real_name"] >> character_name
	var/confirm = tgui_alert(user, "Вы перезапишете текущий слот персонажем [character_name]. Продолжить?", "Подтверждение", list("Да", "Нет"))
	if(confirm != "Да")
		return
	if(QDELETED(offer_datum))
		tgui_alert_async(user, "Этот персонаж уже недоступен.")
		return
	to_chat(the_owner, span_boldwarning("[user.key] забрал вашего персонажа, [character_name]!"))
	if(!prefs.load_character(provided = offered_file))
		tgui_alert_async(user, "Что-то пошло не так при загрузке сейвфайла, сообщите об этом администрации.")
		to_chat(the_owner, span_boldwarning("Что-то пошло не так на последнем шаге передачи, сообщите об этом."))
		qdel(offer_datum)
		return
	character_revision++
	preview_dirty = TRUE
	tgui_alert_async(user, "Персонаж [character_name] получен!")
	prefs.save_character(TRUE)
	qdel(offer_datum)

/datum/character_setup/proc/format_help_text()
	return {"Форматирование описания персонажа:

*текст* или _текст_ — курсив
!текст! — жирный
^текст^ — крупный шрифт
|текст| — по центру
((текст)) — мелкий шрифт
# Заголовок, ## Подзаголовок, ### и ####
- Списки: строка начинается с * (поддерживаются вложенные)
--- — горизонтальная линия
-=RRGGBB текст =- — цвет (hex, например -=ff0000 красный=- , -=00ff00 зелёный=-)
Экранирование: \\* \\! \\_ \\^ \\| \\( \\)
"}

/datum/character_setup/proc/format_help()
	var/mob/user = prefs.parent?.mob
	tgui_alert(user, format_help_text(), "Помощь по форматированию", list("OK"))

/datum/character_setup/proc/apply_text_edit(field, text)
	switch(field)
		if("flavor_text")
			prefs.features["flavor_text"] = clip_text(text, MAX_FLAVOR_LEN)
		if("naked_flavor_text")
			prefs.features["naked_flavor_text"] = clip_text(text, MAX_FLAVOR_LEN)
		if("silicon_flavor_text")
			prefs.features["silicon_flavor_text"] = clip_text(text, MAX_FLAVOR_LEN)
		if("taste")
			prefs.vore_taste = clip_text(text, MAX_TASTE_LEN)
		if("smell")
			prefs.vore_smell = clip_text(text, MAX_TASTE_LEN)
		if("species_lore")
			prefs.features["custom_species_lore"] = clip_text(text, MAX_FLAVOR_LEN)
		if("ooc_notes")
			prefs.features["ooc_notes"] = clip_text(text, MAX_FLAVOR_LEN)
		if("security_records")
			prefs.security_records = clip_text(text, MAX_FLAVOR_LEN)
		if("medical_records")
			prefs.medical_records = clip_text(text, MAX_FLAVOR_LEN)
		if("deathgasp")
			if(isnull(text))
				return
			prefs.features["custom_deathgasp"] = strip_html_simple("[text]", MAX_DEATHGASP_LEN)
		else
			return FALSE
	return TRUE

/datum/character_setup/proc/edit_text_field(list/params)
	var/field = "[params["field"]]"
	var/list/config
	switch(field)
		if("flavor_text")
			config = list("Описание при осмотре", prefs.features["flavor_text"], MAX_FLAVOR_LEN)
		if("naked_flavor_text")
			config = list("Описание без одежды", prefs.features["naked_flavor_text"], MAX_FLAVOR_LEN)
		if("silicon_flavor_text")
			config = list("Описание силикона", prefs.features["silicon_flavor_text"], MAX_FLAVOR_LEN)
		if("taste")
			config = list("Описание вкуса", prefs.vore_taste, MAX_TASTE_LEN)
		if("smell")
			config = list("Описание запаха", prefs.vore_smell, MAX_TASTE_LEN)
		if("species_lore")
			config = list("Предыстория вида", prefs.features["custom_species_lore"], MAX_FLAVOR_LEN)
		if("ooc_notes")
			config = list("OOC-заметки", prefs.features["ooc_notes"], MAX_FLAVOR_LEN)
		if("security_records")
			config = list("Охранные записи", prefs.security_records, MAX_FLAVOR_LEN)
		if("medical_records")
			config = list("Медицинские записи", prefs.medical_records, MAX_FLAVOR_LEN)
		if("deathgasp")
			config = list("Эмоут смерти", prefs.features["custom_deathgasp"], MAX_DEATHGASP_LEN)
		else
			return
	var/opened_slot = prefs.default_slot
	var/mob/user = prefs.parent?.mob
	var/new_text = tgui_input_text(user, "", config[1], config[2], config[3], TRUE, FALSE, 0, FALSE, format_help_text())
	if(isnull(new_text))
		return TRUE
	if(prefs.default_slot != opened_slot)
		return TRUE
	return apply_text_edit(field, new_text)

/datum/character_setup/proc/build_background_data()
	var/list/data = list()

	data["flavorText"] = prefs.features["flavor_text"]
	data["nakedFlavorText"] = prefs.features["naked_flavor_text"]
	data["siliconFlavorText"] = prefs.features["silicon_flavor_text"]
	data["tasteText"] = prefs.vore_taste
	data["smellText"] = prefs.vore_smell
	data["speciesLore"] = prefs.features["custom_species_lore"]
	data["oocNotes"] = prefs.features["ooc_notes"]
	data["deathgasp"] = prefs.features["custom_deathgasp"]
	data["securityRecords"] = prefs.security_records
	data["medicalRecords"] = prefs.medical_records

	data["headshots"] = build_headshot_slots(prefs.features["headshot_links"], MAX_HEADSHOTS)
	data["nakedHeadshots"] = build_headshot_slots(prefs.features["headshot_naked_links"], MAX_HEADSHOTS_NAKED)
	data["headshotMaxLen"] = CHARACTER_SETUP_HEADSHOT_MAX_LEN
	data["assPhoto"] = prefs.features["ass_photo"] || ""

	data["flavorMaxLen"] = MAX_FLAVOR_LEN
	data["tasteMaxLen"] = MAX_TASTE_LEN
	data["deathgaspMaxLen"] = MAX_DEATHGASP_LEN
	return data

/datum/character_setup/proc/build_headshot_slots(list/links, max_slots)
	var/list/slots = new /list(max_slots)
	if(!islist(links))
		return slots
	for(var/index in 1 to min(length(links), max_slots))
		if(links[index])
			slots[index] = links[index]
	return slots

/datum/character_setup/proc/schedule_preview_update()
	// Превью собирается отдельным тиком: сборка манекена в тике открытия или действия даёт статтер.
	if(!preview_dirty || preview_update_pending)
		return
	prune_viewer_screens()
	var/viewport_ready = FALSE
	for(var/viewer in viewer_screens)
		var/atom/movable/screen/map_view/character_setup_screen/viewer_screen = viewer_screens[viewer]
		if(viewer_screen.viewport_width)
			viewport_ready = TRUE
			break
	if(!viewport_ready)
		return
	preview_update_pending = TRUE
	addtimer(CALLBACK(src, PROC_REF(run_preview_update)), SSjob.initialized ? 0.1 SECONDS : 1 SECONDS)

/datum/character_setup/proc/run_preview_update()
	try
		update_preview()
	catch(var/exception/error)
		preview_dirty = TRUE
		preview_update_pending = FALSE
		stack_trace("Ошибка сборки превью персонажа: [error]")
		return
	preview_update_pending = FALSE
	if(!QDELETED(src))
		schedule_preview_update()

/datum/character_setup/proc/update_preview()
	if(!prefs?.parent || !SSjob.initialized || !preview_dirty || !length(viewer_screens))
		return
	// Пока общий манекен занят, сборка может уснуть. Новая правка должна оставить новую заявку.
	preview_dirty = FALSE
	var/mutable_appearance/appearance_source = prefs.build_preview_appearance(preview_aroused, preview_mode)
	if(!appearance_source)
		preview_dirty = TRUE
		return
	if(QDELETED(src) || !prefs || preview_dirty)
		return
	show_preview_appearance(appearance_source)

/datum/character_setup/proc/show_preview_appearance(mutable_appearance/appearance_source)
	prune_viewer_screens()
	// Новые слои меряются попиксельно, по 1-2 мс на слой: замеряем их заранее с уступкой тика.
	for(var/viewer in viewer_screens)
		var/atom/movable/screen/map_view/character_setup_screen/viewer_screen = viewer_screens[viewer]
		viewer_screen.prewarm_preview_bounds(appearance_source)
		break
	if(QDELETED(src) || !prefs || preview_dirty)
		return
	prune_viewer_screens()
	for(var/viewer in viewer_screens)
		var/atom/movable/screen/map_view/character_setup_screen/viewer_screen = viewer_screens[viewer]
		viewer_screen.update_character(appearance_source, prefs.bgstate, preview_auto_fit, prefs.character_setup_single_view, preview_direction, preview_zoom, preview_reference, preview_background_style)
	push_preview_update()

// Экран зрителя мог удалиться мимо ui_close (смена моба, харддел): запись без живого экрана роняет обходы.
/datum/character_setup/proc/prune_viewer_screens()
	for(var/mob/viewer as anything in viewer_screens)
		var/atom/movable/screen/map_view/character_setup_screen/viewer_screen = viewer_screens[viewer]
		if(QDELETED(viewer_screen))
			LAZYREMOVE(viewer_screens, viewer)

/datum/character_setup/proc/push_preview_update(character_changed = FALSE)
	for(var/datum/tgui/ui as anything in SStgui.get_all_open_uis(src))
		var/list/data = preview_data(ui.user)
		if(character_changed)
			data["hasUnsavedChanges"] = character_state() != saved_character_state
		ui.send_update(data)

// Камера использует готовую внешность: поворот, фон и масштаб не пересоздают манекен.
/datum/character_setup/proc/refresh_preview_camera(character_changed = FALSE)
	prune_viewer_screens()
	for(var/viewer in viewer_screens)
		var/atom/movable/screen/map_view/character_setup_screen/viewer_screen = viewer_screens[viewer]
		if(viewer_screen.cached_source)
			viewer_screen.update_character(viewer_screen.cached_source, prefs.bgstate, preview_auto_fit, prefs.character_setup_single_view, preview_direction, preview_zoom, preview_reference, preview_background_style)
	push_preview_update(character_changed)

/datum/character_setup/ui_act(action, list/params)
	. = ..()
	if(. || !prefs)
		return
	// Запоздалый ввод из редактора прежнего персонажа не должен менять новый слот.
	if(!isnull(params["character_slot"]) && num_param(params["character_slot"]) != prefs.default_slot)
		return

	switch(action)
		if("edit_slot_name")
			var/slot = prefs.default_slot
			var/revision = character_revision
			var/mob/user = usr
			var/new_name = tgui_input_text(user, "Название выбранного слота. Оставьте пустым, чтобы убрать название.", "Название слота [slot]", prefs.character_slot_name, MAX_NAME_LEN)
			if(QDELETED(src) || !prefs || user?.client?.prefs != prefs || prefs.default_slot != slot || character_revision != revision || isnull(new_name))
				return
			prefs.character_slot_name = copytext_char(trimtext(strip_control_chars(new_name)), 1, MAX_NAME_LEN + 1)
			return TRUE

		if("set_slot_name_replace")
			prefs.character_slot_name_replace = !!params["value"]
			prefs.save_pref_var("character_slot_name_replace")
			return TRUE

		if("preset_select", "preset_create", "preset_save", "preset_rename", "preset_delete", "preset_apply")
			manage_character_preset(action, params, usr)
			return TRUE

		if("pick_theme")
			var/list/themes = prefs.setup_theme_options()
			var/list/choices = list()
			for(var/theme_id in themes)
				choices[themes[theme_id]] = theme_id
			var/mob/user = usr
			var/choice = tgui_input_list(user, "Выберите оформление окна настройки персонажа.", "Тема меню персонажа", choices, themes[prefs.character_setup_theme])
			if(!choice || !choices[choice] || !prefs || user?.client?.prefs != prefs)
				return
			prefs.character_setup_theme = choices[choice]
			prefs.save_pref_var("character_setup_theme")
			return TRUE

		if("set_tab")
			var/new_tab = num_param(params["tab"])
			if(isnull(new_tab) || new_tab < GENERAL_CHAR_TAB || new_tab > MODIFICATIONS_CHAR_TAB)
				return
			prefs.character_settings_tab = new_tab
			return TRUE

		if("set_theme")
			var/new_theme = params["theme"]
			if(!prefs.valid_setup_theme(new_theme) || new_theme == prefs.character_setup_theme)
				return
			prefs.character_setup_theme = new_theme
			prefs.save_pref_var("character_setup_theme")
			return TRUE

		if("switch_slot")
			var/new_slot = num_param(params["slot"])
			if(isnull(new_slot) || new_slot != round(new_slot) || new_slot < 1 || new_slot > prefs.max_save_slots || new_slot == prefs.default_slot)
				return
			var/previous_name = prefs.real_name
			var/save_previous = prefs.character_setup_autosave
			if(save_previous)
				// Завершаем запись старого слота до загрузки нового, включая отложенное сохранение.
				if(!prefs.save_character(bypass_cooldown = TRUE, silent = TRUE))
					return
			else
				// Отложенное сохранение старого персонажа не должно сработать уже в новом слоте.
				if(prefs.char_queue)
					deltimer(prefs.char_queue)
				prefs.char_queue = null
				prefs.char_queue_deadline = 0
			var/list/slot_names = prefs.get_slot_names()
			if(slot_names?[new_slot])
				var/old_slot = prefs.default_slot
				if(!prefs.load_character(new_slot, bypass_cooldown = TRUE))
					prefs.default_slot = old_slot
					return
			else
				if(!prefs.create_character(new_slot))
					return
			prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
			prefs.parent?.tgui_panel?.emotes_send_list()
			stop_sound_preview()
			save_notice = save_previous ? "[previous_name]: сохранён автоматически при переключении." : null
			character_revision++
			preview_dirty = TRUE
			return TRUE

		if("set_autosave_on_switch")
			prefs.character_setup_autosave = !!params["value"]
			prefs.save_pref_var("character_setup_autosave")
			save_notice = null
			return TRUE

		if("set_active_preset_autosave")
			prefs.character_setup_preset_autosave = !!params["value"]
			prefs.save_pref_var("character_setup_preset_autosave")
			return TRUE

		if("save")
			if(prefs.save_character(bypass_cooldown = TRUE))
				save_notice = prefs.character_setup_preset_autosave && prefs.active_character_preset ? "Персонаж и активный пресет сохранены." : "Персонаж сохранён."
			else
				save_notice = "Не удалось сохранить персонажа. Изменения остаются в редакторе."
			return TRUE

		if("load")
			if(!prefs.load_character(prefs.default_slot, bypass_cooldown = TRUE))
				save_notice = "Не удалось загрузить сохранённого персонажа."
				return TRUE
			save_notice = "Восстановлено последнее сохранение."
			character_revision++
			preview_dirty = TRUE
			if(prefs.job_menu)
				prefs.job_menu.previews.Cut()
				prefs.job_menu.pushed_preview = null
				SStgui.update_uis(prefs.job_menu)
			return TRUE

		if("delete_slot")
			var/del_slot = num_param(params["slot"])
			if(isnull(del_slot))
				del_slot = prefs.default_slot
			prefs.delete_character(del_slot)
			character_revision++
			preview_dirty = TRUE
			return TRUE

		if("randomize")
			prefs.random_character()
			preview_dirty = TRUE
			return TRUE

		if("set_preview_mode")
			var/new_mode = params["mode"]
			if(!(new_mode in list(PREVIEW_PREF_JOB, PREVIEW_PREF_LOADOUT, PREVIEW_PREF_NAKED)))
				return
			preview_mode = new_mode
			preview_dirty = TRUE
			return TRUE

		if("set_preview_aroused")
			preview_aroused = !!params["value"]
			preview_dirty = TRUE
			return TRUE

		if("set_preview_auto_fit")
			preview_auto_fit = !!params["value"]
			refresh_preview_camera()
			return FALSE

		if("set_preview_single_view")
			prefs.character_setup_single_view = !!params["value"]
			prefs.save_pref_var("character_setup_single_view")
			refresh_preview_camera()
			return FALSE

		if("rotate_preview")
			if(params["direction"] == "left")
				preview_direction = turn(preview_direction, 90)
			else if(params["direction"] == "right")
				preview_direction = turn(preview_direction, -90)
			else if(params["direction"] == "front")
				preview_direction = SOUTH
			else
				return
			refresh_preview_camera()
			return FALSE

		if("set_preview_zoom")
			var/new_zoom = num_param(params["value"])
			if(isnull(new_zoom))
				return
			preview_zoom = clamp(round(new_zoom, 0.05), 0.5, 3)
			refresh_preview_camera()
			return FALSE

		if("reset_preview_camera")
			preview_zoom = 1
			refresh_preview_camera()
			return FALSE

		if("set_preview_reference")
			preview_reference = !!params["value"]
			refresh_preview_camera()
			return FALSE

		if("set_preview_background")
			var/list/options = list("transparent", "checker", "light", "dark")
			for(var/state in bg_state_options())
				options += "texture:[state]"
			var/choice = params["value"]
			if(!isnull(params["dir"]))
				var/current = preview_background_style == "texture" ? "texture:[prefs.bgstate]" : preview_background_style
				choice = cycle_choice(current, options, params["dir"])
			if(!(choice in options))
				return
			if(findtext(choice, "texture:") == 1)
				preview_background_style = "texture"
				prefs.bgstate = copytext(choice, length("texture:") + 1)
			else
				preview_background_style = choice
			refresh_preview_camera(character_changed = TRUE)
			return FALSE

		if("set_preview_viewport")
			var/width = num_param(params["width"])
			var/height = num_param(params["height"])
			if(isnull(width) || isnull(height) || width <= 0 || height <= 0)
				return
			var/atom/movable/screen/map_view/character_setup_screen/viewer_screen = LAZYACCESS(viewer_screens, usr)
			if(!viewer_screen)
				return
			var/was_ready = !isnull(viewer_screen.viewport_aspect)
			if(!viewer_screen.set_viewport_size(width, height))
				return
			if(!was_ready)
				// Замер приходит после winset из ByondUi: подкарту уже создали, можно регистрировать плоскости.
				viewer_screen.display_to_client(usr.client)
				push_preview_update()
			schedule_preview_update()
			return FALSE

		if("set_name")
			var/new_name = reject_bad_name("[params["name"]]", allow_numbers = TRUE)
			if(!new_name)
				to_chat(usr, span_warning("Некорректное имя: от 2 до [MAX_NAME_LEN] символов, допустимы A-Z, a-z, А-Я, а-я, 0-9, -, ' и ."))
				return
			prefs.real_name = new_name
			return TRUE

		if("random_name")
			prefs.real_name = prefs.pref_species.random_name(prefs.gender, 1)
			return TRUE

		if("set_age")
			var/new_age = num_param(params["age"])
			if(isnull(new_age))
				return
			prefs.age = clamp(round(new_age), AGE_MIN, AGE_MAX_INPUT)
			return TRUE

		if("toggle_nameless")
			prefs.nameless = !prefs.nameless
			return TRUE

		if("toggle_random_name")
			prefs.be_random_name = !prefs.be_random_name
			return TRUE

		if("toggle_hide_ckey")
			prefs.hide_ckey = !prefs.hide_ckey
			usr.mind?.hide_ckey = prefs.hide_ckey
			return TRUE

		if("toggle_custom_blood_color")
			prefs.custom_blood_color = !prefs.custom_blood_color
			return TRUE

		if("set_blood_color")
			prefs.blood_color = sanitize_hexcolor("[params["color"]]", 6, 1, initial(prefs.blood_color))
			prefs.custom_blood_color = TRUE
			return TRUE

		if("toggle_hardsuit_with_tail")
			prefs.features["hardsuit_with_tail"] = !prefs.features["hardsuit_with_tail"]
			preview_dirty = TRUE
			return TRUE

		if("set_sec_dept")
			var/new_dept = params["value"]
			if(!(new_dept in GLOB.security_depts_prefs))
				return
			prefs.prefered_security_department = new_dept
			return TRUE

		if("set_ai_core")
			var/new_core = params["value"]
			if(!(new_core in GLOB.ai_core_display_screens))
				return
			prefs.preferred_ai_core_display = new_core
			preview_dirty = TRUE
			return TRUE

		if("set_pda_color")
			prefs.pda_color = sanitize_hexcolor("[params["color"]]", 6, 1, initial(prefs.pda_color))
			return TRUE

		if("set_pda_style")
			var/new_style = params["value"]
			if(!(new_style in GLOB.pda_styles))
				return
			prefs.pda_style = new_style
			return TRUE

		if("set_pda_skin")
			var/new_skin = params["value"]
			if(!(new_skin in GLOB.pda_reskins))
				return
			prefs.pda_skin = new_skin
			return TRUE

		if("set_pda_ringtone")
			var/new_ringtone = reject_bad_name("[params["value"]]", TRUE)
			if(!new_ringtone)
				return
			prefs.pda_ringtone = new_ringtone
			return TRUE

		if("set_pda_theme")
			var/new_theme = params["value"]
			for(var/theme_name in GLOB.pda_name_to_theme)
				if(GLOB.pda_name_to_theme[theme_name] == new_theme)
					prefs.pda_theme = new_theme
					return TRUE
			return

		if("set_silicon_lawset")
			var/new_lawset = params["value"]
			if(isnull(new_lawset) || new_lawset == "None")
				prefs.silicon_lawset = null
				return TRUE
			var/list/config_laws = CONFIG_GET(keyed_list/choosable_laws)
			if(!(new_lawset in config_laws))
				return
			prefs.silicon_lawset = new_lawset
			return TRUE

		if("set_custom_name")
			var/name_id = params["id"]
			if(!(name_id in GLOB.preferences_custom_names))
				return
			var/list/namedata = prefs.get_custom_namedata(name_id)
			if(!namedata)
				return
			var/raw_value = "[params["value"]]"
			if(!length(raw_value))
				if(namedata["allow_null"])
					prefs.custom_names[name_id] = prefs.get_default_name(name_id)
					return TRUE
				return
			var/sanitized_name = reject_bad_name(raw_value, namedata["allow_numbers"])
			if(!sanitized_name)
				to_chat(usr, "<font color='red'>Некорректное имя для «[namedata["pref_name"]]».</font>")
				return
			prefs.custom_names[name_id] = sanitized_name
			return TRUE

		if("open_jobs")
			prefs.SetChoices(usr)
			return TRUE

		if("edit_text")
			return edit_text_field(params)

		if("set_flavor_text")
			return apply_text_edit("flavor_text", params["text"])

		if("set_naked_flavor_text")
			return apply_text_edit("naked_flavor_text", params["text"])

		if("set_silicon_flavor_text")
			return apply_text_edit("silicon_flavor_text", params["text"])

		if("set_taste")
			return apply_text_edit("taste", params["text"])

		if("set_smell")
			return apply_text_edit("smell", params["text"])

		if("set_species_lore")
			return apply_text_edit("species_lore", params["text"])

		if("set_ooc_notes")
			return apply_text_edit("ooc_notes", params["text"])

		if("set_security_records")
			return apply_text_edit("security_records", params["text"])

		if("set_medical_records")
			return apply_text_edit("medical_records", params["text"])

		if("set_deathgasp")
			return apply_text_edit("deathgasp", params["text"])

		if("set_deathsound")
			var/new_sound = params["value"]
			if(!isnull(params["dir"]))
				var/current_sound = prefs.features["custom_deathsound"] || "По умолчанию"
				new_sound = cycle_choice(current_sound, GLOB.deathgasp_sounds, params["dir"])
			if(!(new_sound in GLOB.deathgasp_sounds))
				return
			prefs.features["custom_deathsound"] = new_sound
			return TRUE

		if("preview_deathsound")
			preview_deathsound()
			return TRUE

		if("set_headshot")
			set_headshot(params["list"], params["slot"], params["url"])
			return TRUE

		if("set_feature")
			set_feature(params)
			return TRUE

		if("set_part_color")
			set_part_color(params)
			return TRUE

		if("set_mutant_part")
			set_mutant_part(params)
			return TRUE

		if("set_cock_shape")
			set_cock_shape(params)
			return TRUE

		if("open_tattoo_manager")
			open_tattoo_manager()
			return TRUE

		if("marking_add")
			add_marking(params)
			return TRUE

		if("marking_clear_limb")
			clear_limb_markings(params)
			return TRUE

		if("markings_remove")
			clear_all_markings()
			return TRUE

		if("marking_move")
			move_marking(params)
			return TRUE

		if("marking_cycle")
			cycle_marking(params)
			return TRUE

		if("marking_set")
			cycle_marking(params)
			return TRUE

		if("marking_remove")
			remove_marking(params)
			return TRUE

		if("marking_glow")
			toggle_marking_glow(params)
			return TRUE

		if("set_marking_color")
			set_marking_color(params)
			return TRUE

		if("set_speech_verb")
			set_speech_verb(params)
			return TRUE

		if("toggle_speech_verb_ru")
			toggle_speech_verb_ru()
			return TRUE

		if("set_tongue")
			set_tongue(params)
			return TRUE

		if("set_laugh")
			set_laugh(params)
			return TRUE

		if("preview_laugh")
			preview_laugh()
			return TRUE

		if("toggle_language")
			toggle_language_pref(params)
			return TRUE

		if("reset_languages")
			reset_languages()
			return TRUE

		if("toggle_personal_chat_color")
			toggle_personal_chat_color()
			return TRUE

		if("set_personal_chat_color")
			set_personal_chat_color(params)
			return TRUE

		if("set_bark_sound")
			set_bark_sound(params)
			return TRUE

		if("set_bark_number")
			set_bark_number(params)
			return TRUE

		if("preview_bark")
			preview_bark()
			return TRUE

		if("stop_sound_preview")
			stop_sound_preview()
			return TRUE

		if("loadout_select_slot")
			loadout_select_slot(params)
			preview_dirty = TRUE
			return TRUE

		if("loadout_select_category")
			loadout_select_category(params)
			return TRUE

		if("loadout_selected")
			loadout_selected = TRUE
			return TRUE

		if("loadout_select_subcategory")
			loadout_select_subcategory(params)
			return TRUE

		if("loadout_toggle_enabled")
			prefs.loadout_enabled = !prefs.loadout_enabled
			preview_dirty = TRUE
			return TRUE

		if("loadout_toggle_gear")
			loadout_toggle_gear(params)
			preview_dirty = TRUE
			return TRUE

		if("loadout_clear")
			prefs.loadout_data["SAVE_[prefs.loadout_slot]"] = list()
			preview_dirty = TRUE
			return TRUE

		if("loadout_copy_slot")
			loadout_copy_slot(params)
			preview_dirty = TRUE
			return TRUE

		if("loadout_open_color")
			open_loadout_color(params)
			return TRUE

		if("loadout_set_poly_color")
			loadout_set_poly_color(params)
			preview_dirty = TRUE
			return TRUE

		if("loadout_set_name")
			loadout_set_name(params)
			return TRUE

		if("loadout_set_description")
			loadout_set_description(params)
			return TRUE

		if("loadout_set_tagname")
			loadout_set_tagname(params)
			return TRUE

		if("loadout_set_examtooltip")
			loadout_set_examtooltip(params)
			return TRUE

		if("loadout_set_heirloom")
			loadout_set_heirloom(params)
			return TRUE

		if("loadout_pick_lipstick_color")
			loadout_pick_lipstick_color(params)
			preview_dirty = TRUE
			return TRUE

		if("loadout_show_ckey_id")
			loadout_show_ckey_id()
			return TRUE

		if("loadout_clear_invalid")
			loadout_clear_invalid(params)
			preview_dirty = TRUE
			return TRUE

		if("quirk_select_category")
			quirk_select_category(params)
			return TRUE

		if("quirk_toggle")
			quirk_toggle(params)
			return TRUE

		if("quirk_reset")
			quirk_reset()
			return TRUE

		if("quirk_set_shriek")
			quirk_set_shriek(params)
			return TRUE

		if("quirk_set_phobia")
			quirk_set_phobia(params)
			return TRUE

		if("quirk_set_onelife")
			quirk_set_onelife(params)
			return TRUE

		if("quirk_set_nickname")
			quirk_set_nickname(params)
			return TRUE

		if("quirk_set_distant_start")
			prefs.distant_start_enabled = !!params["value"]
			return TRUE

		if("slot_export")
			slot_export()
			return TRUE

		if("slot_import")
			slot_import()
			return TRUE

		if("slot_give")
			slot_give()
			return TRUE

		if("slot_retrieve")
			slot_retrieve()
			return TRUE

		if("format_help")
			format_help()
			return TRUE

		if("set_gender")
			var/new_gender = params["value"]
			if(!(new_gender in list(MALE, FEMALE, PLURAL, NEUTER)))
				return
			switch(new_gender)
				if(PLURAL)
					prefs.gender = PLURAL
					prefs.features["body_model"] = pick(MALE, FEMALE)
				if(NEUTER)
					prefs.gender = NEUTER
					prefs.features["body_model"] = MALE
				else
					prefs.gender = new_gender
					prefs.features["body_model"] = new_gender
			preview_dirty = TRUE
			return TRUE

		if("set_body_model")
			var/new_model = params["value"]
			if(!(new_model in list(MALE, FEMALE)))
				return
			prefs.features["body_model"] = new_model
			preview_dirty = TRUE
			return TRUE

		if("set_species")
			apply_species_change(params["value"])
			return TRUE

		if("set_custom_species")
			var/raw_species = "[params["value"]]"
			if(!length(trimtext(raw_species)))
				prefs.custom_species = null
				return TRUE
			var/new_species = reject_bad_name(raw_species, allow_numbers = TRUE)
			if(new_species)
				prefs.custom_species = new_species
			return TRUE

		if("toggle_color_scheme")
			prefs.features["color_scheme"] = (prefs.features["color_scheme"] == ADVANCED_CHARACTER_COLORING) ? OLD_CHARACTER_COLORING : ADVANCED_CHARACTER_COLORING
			preview_dirty = TRUE
			return TRUE

		if("set_skin_tone")
			var/tone_value = params["value"]
			if(!isnull(params["dir"]))
				var/current_tone = prefs.use_custom_skin_tone ? "custom" : prefs.skin_tone
				tone_value = cycle_choice(current_tone, skin_tone_options(), params["dir"])
			if(isnull(tone_value))
				tone_value = params["color"]
			apply_skin_tone(tone_value)
			return TRUE

		if("set_eye_type")
			var/new_eye_type = isnull(params["dir"]) ? params["value"] : cycle_choice(prefs.eye_type, GLOB.eye_types, params["dir"])
			if(!(new_eye_type in GLOB.eye_types))
				return
			prefs.eye_type = new_eye_type
			preview_dirty = TRUE
			return TRUE

		if("set_eye_color")
			var/new_eye_color = sanitize_color_value(params["color"], FEATURE_COLOR_PLAIN, null, prefs.left_eye_color)
			if(isnull(new_eye_color))
				return
			prefs.left_eye_color = new_eye_color
			prefs.right_eye_color = new_eye_color
			preview_dirty = TRUE
			return TRUE

		if("toggle_emissive_part")
			var/part = params["part"]
			if(!istext(part))
				return
			toggle_emissive_part(prefs.features, part)
			preview_dirty = TRUE
			return TRUE

		if("set_bgstate")
			var/new_bgstate = isnull(params["dir"]) ? params["value"] : cycle_choice(prefs.bgstate, bg_state_options(), params["dir"])
			if(!(new_bgstate in bg_state_options()))
				return
			prefs.bgstate = new_bgstate
			preview_dirty = TRUE
			return TRUE

		if("set_body_sprite")
			var/new_sprite = params["value"]
			if(!istext(new_sprite) || !prefs.pref_species)
				return
			if(!(new_sprite in prefs.pref_species.allowed_limb_ids))
				return
			prefs.chosen_limb_id = new_sprite
			preview_dirty = TRUE
			return TRUE

		if("set_jumpsuit")
			var/new_jumpsuit = params["value"]
			if(!(new_jumpsuit in list(PREF_SUIT, PREF_SKIRT)))
				return
			prefs.jumpsuit_style = new_jumpsuit
			return TRUE

		if("set_antag_opt_in")
			var/new_level = sanitize_antag_opt_in_level(num_param(params["value"]))
			if(isnull(new_level))
				return
			prefs.antag_opt_in_level = new_level
			return TRUE

		if("set_body_weight")
			apply_body_weight(params["value"])
			return TRUE

		if("cycle_hair_style", "set_hair_style")
			cycle_hair_style(params)
			return TRUE

		if("pick_hair_style")
			var/hair_tab = params["kind"]
			if(!(hair_tab in list("hair", "facial", "grad")))
				return
			prefs.open_hair_style_picker(usr, hair_tab)
			return TRUE

		if("set_limb")
			set_limb_modification(params)
			return TRUE

		if("set_organ")
			set_organ_modification(params)
			return TRUE

		if("toggle_implant")
			toggle_body_implant(params)
			return TRUE

		if("clear_scars")
			to_chat(usr, "<span class='notice'>All scar slots cleared. Please save character to confirm.</span>")
			for(var/scar_slot in 1 to 5)
				prefs.scars_list["[scar_slot]"] = ""
			return TRUE

		if("set_puddle_slime")
			prefs.features["puddle_slime_fea"] = params["value"] ? TRUE : FALSE
			preview_dirty = TRUE
			return TRUE

/datum/character_setup/proc/clip_text(value, max_len)
	if(isnull(value))
		return ""
	return copytext_char("[value]", 1, max_len)

/datum/character_setup/proc/set_headshot(list_kind, slot_index, raw_link)
	if(list_kind == "ass")
		if(isnull(raw_link) || !length("[raw_link]"))
			prefs.features["ass_photo"] = ""
			return
		var/validated_photo = prefs.validate_headshot_link(usr, "[raw_link]")
		if(!validated_photo || validated_photo == prefs.features["ass_photo"])
			return
		prefs.features["ass_photo"] = validated_photo
		return

	var/is_naked_list = (list_kind == "naked")
	var/list/links = is_naked_list ? prefs.features["headshot_naked_links"] : prefs.features["headshot_links"]
	if(!islist(links))
		return
	var/index = num_param(slot_index)
	var/max_index = is_naked_list ? MAX_HEADSHOTS_NAKED : MAX_HEADSHOTS
	if(isnull(index) || index < 1 || index > max_index)
		return

	if(isnull(raw_link) || !length("[raw_link]"))
		links[index] = null
		return

	var/validated = prefs.validate_headshot_link(usr, "[raw_link]")
	if(!validated)
		return
	links[index] = validated

/datum/character_setup/proc/preview_deathsound()
	if(SSticker.current_state == GAME_STATE_STARTUP)
		to_chat(usr, span_warning("Предпросмотр звука смерти недоступен при инициализации!"))
		return

	var/picked_name = prefs.features["custom_deathsound"]
	var/picked_path
	if(picked_name)
		if(picked_name == "По умолчанию")
			picked_path = pick('sound/voice/deathgasp1.ogg', 'sound/voice/deathgasp2.ogg')
		if(picked_name == "Беззвучный")
			picked_path = 0
		if(GLOB.deathgasp_sounds[picked_name])
			picked_path = GLOB.deathgasp_sounds[picked_name]
	if(picked_path)
		if(start_sound_preview("death", 3 SECONDS))
			usr.playsound_local(usr, picked_path, 60, channel = sound_preview_channel)
	else
		stop_sound_preview()
		to_chat(usr, span_warning("Выбран беззвучный вариант или звук отсутствует!"))

/datum/character_setup/proc/num_param(value)
	if(isnum(value))
		return value
	return text2num("[value]")

/proc/dir_to_text(dir_value)
	switch(dir_value)
		if(NORTH)
			return "north"
		if(SOUTH)
			return "south"
		if(EAST)
			return "east"
		if(WEST)
			return "west"
	return "south"

#undef CHARACTER_SETUP_INTERFACE
#undef CHARACTER_SETUP_HEADSHOT_MAX_LEN

// Замеры видимых границ слоёв общие для всех окон: экран окна удаляется при закрытии, а ресурсы за раунд не меняются.
GLOBAL_LIST_EMPTY(character_preview_icon_bounds)
#define CHARACTER_PREVIEW_BOUNDS_CACHE_MAX 8192
GLOBAL_LIST_EMPTY(character_preview_backgrounds)
#define CHARACTER_PREVIEW_BACKGROUND_CACHE_MAX 64

// Исходная внешность в нативной карте BYOND: четыре ракурса или один поворачиваемый.
/atom/movable/screen/map_view/character_setup_screen
	name = "character setup screen"
	icon = null
	layer = SPACE_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/list/previews = list()
	var/shown_offset = 0
	var/viewport_aspect
	var/mutable_appearance/cached_source
	var/cached_background_state
	var/cached_auto_fit
	var/list/reference_previews = list()
	var/viewport_width
	var/viewport_height
	var/cached_single_view = FALSE
	var/cached_direction = SOUTH
	var/cached_zoom = 1
	var/cached_reference = FALSE
	var/cached_background_style = "texture"
	var/native_zoom = 0
	var/list/view_bounds_cache = list()
	var/list/reference_bounds_cache = list()
	var/icon/background_cache
	var/background_cache_key
	var/prepared_plane_count = 0
	var/client/prepared_for_client

/atom/movable/screen/map_view/character_setup_screen/Destroy()
	hide_from()
	vis_contents.Cut()
	QDEL_LIST_ASSOC_VAL(previews)
	QDEL_LIST_ASSOC_VAL(reference_previews)
	cached_source = null
	view_bounds_cache = null
	reference_bounds_cache = null
	background_cache = null
	prepared_for_client = null
	return ..()

/atom/movable/screen/map_view/character_setup_screen/display_to_client(client/show_to)
	. = ..()
	apply_native_camera()

/atom/movable/screen/map_view/character_setup_screen/proc/apply_native_camera()
	if(registered_client)
		winset(registered_client, assigned_map, list("zoom" = native_zoom, "background-color" = cached_background_style == "transparent" ? "none" : "#202020"))

/atom/movable/screen/map_view/character_setup_screen/ensure_plane_group()
	if(!popup_plane_group)
		popup_plane_group = new /datum/plane_master_group/popup/on_demand/character_setup(PLANE_GROUP_POPUP_WINDOW(src), assigned_map)
	popup_plane_group.ensure_popup_depth(shown_offset)
	// Фильтры зависят от зрителя и набора плоскостей, но не от поворота или масштаба камеры.
	if(prepared_plane_count == length(popup_plane_group.plane_masters) && prepared_for_client == registered_client)
		return popup_plane_group
	prepared_plane_count = length(popup_plane_group.plane_masters)
	prepared_for_client = registered_client
	for(var/plane_key in popup_plane_group.plane_masters)
		var/atom/movable/screen/plane_master/plane_master = popup_plane_group.plane_masters[plane_key]
		// Предпросмотр не использует маски зрения, свет и общие render_target основной карты.
		plane_master.filters = null
	return popup_plane_group

/datum/plane_master_group/popup/on_demand/character_setup/get_plane_types()
	return list(
		/atom/movable/screen/plane_master/character_setup,
		/atom/movable/screen/plane_master/character_setup/emissive,
	)

// Нативная внешность сохраняет матрицы и слои, но не участвует в графе рендера игровой карты.
/atom/movable/screen/plane_master/character_setup
	name = "character preview plane master"
	plane = GAME_PLANE

/atom/movable/screen/plane_master/character_setup/emissive
	name = "character preview emissive mask"
	plane = EMISSIVE_PLANE
	alpha = 0

/atom/movable/screen/map_view/character_setup_screen/proc/set_viewport_size(width, height)
	var/new_aspect = clamp(width / height, 0.1, 10)
	if(viewport_width == width && viewport_height == height)
		return FALSE
	viewport_aspect = new_aspect
	viewport_width = width
	viewport_height = height
	if(cached_source)
		update_character(cached_source, cached_background_state, cached_auto_fit, cached_single_view, cached_direction, cached_zoom, cached_reference, cached_background_style)
	return TRUE

/atom/movable/screen/map_view/character_setup_screen/proc/update_character(mutable_appearance/appearance_source, background_state, auto_fit = TRUE, single_view = FALSE, view_direction = SOUTH, zoom_factor = 1, show_reference = FALSE, background_style = "texture")
	var/source_changed = cached_source != appearance_source
	if(source_changed)
		view_bounds_cache.Cut()
		reference_bounds_cache.Cut()
	cached_source = appearance_source
	cached_background_state = background_state
	cached_auto_fit = auto_fit
	cached_single_view = single_view
	cached_direction = view_direction
	cached_zoom = zoom_factor
	cached_reference = show_reference
	cached_background_style = background_style
	var/list/view_bounds = list()
	var/list/reference_bounds_by_dir = list()
	var/list/directions = single_view ? list(view_direction) : GLOB.cardinals
	var/draw_reference = show_reference && !auto_fit
	// Простые спрайты рисуем оверлеями карты, как в меню профессий.
	var/use_overlays = !length(appearance_source.overlays) && !length(appearance_source.underlays)
	vis_contents.Cut()
	cut_overlays()
	var/reference_width = world.icon_size * 2
	var/reference_height = world.icon_size
	var/max_width = 0
	var/max_height = 0
	var/mutable_appearance/reference
	if(!auto_fit)
		reference = new /mutable_appearance(appearance_source)
		reference.transform = null
	for(var/direction in GLOB.cardinals)
		var/atom/movable/screen/preview = previews["[direction]"]
		if(!preview)
			preview = new
			previews["[direction]"] = preview
		if(!use_overlays && (direction in directions))
			vis_contents += preview
		// Положение обеих разновидностей фигур рассчитывается в координатах общего холста.
		preview.appearance = appearance_source
		preview.dir = direction
		preview.vis_flags = VIS_INHERIT_PLANE
		// Фигура должна оставаться над фоном независимо от слоя исходной внешности.
		preview.layer = max(MOB_LAYER, preview.layer)
		preview.appearance_flags &= ~TILE_BOUND
		var/list/bounds = view_bounds_cache["[direction]"]
		if(!bounds)
			bounds = measure_preview_bounds(preview, GLOB.character_preview_icon_bounds) || list(0, 0, world.icon_size, world.icon_size)
			view_bounds_cache["[direction]"] = bounds
		view_bounds["[direction]"] = bounds
		max_width = max(max_width, bounds[3] - bounds[1])
		max_height = max(max_height, bounds[4] - bounds[2])
		if(reference)
			reference.setDir(direction)
			var/list/reference_bounds = reference_bounds_cache["[direction]"]
			if(!reference_bounds)
				reference_bounds = measure_preview_bounds(reference, GLOB.character_preview_icon_bounds)
				if(reference_bounds)
					reference_bounds_cache["[direction]"] = reference_bounds
			if(reference_bounds)
				reference_bounds_by_dir["[direction]"] = reference_bounds
				reference_width = max(reference_width, reference_bounds[3] - reference_bounds[1])
				reference_height = max(reference_height, reference_bounds[4] - reference_bounds[2])
			if(draw_reference)
				var/atom/movable/screen/reference_preview = reference_previews["[direction]"]
				if(!reference_preview)
					reference_preview = new
					reference_previews["[direction]"] = reference_preview
				reference_preview.appearance = reference
				reference_preview.dir = direction
				reference_preview.vis_flags = VIS_INHERIT_PLANE
				reference_preview.layer = MOB_LAYER - 0.1
				reference_preview.appearance_flags |= KEEP_TOGETHER
				reference_preview.appearance_flags &= ~TILE_BOUND
				reference_preview.color = list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1, 0.5,0.6,0.7,0)
				reference_preview.alpha = 90
				if(!use_overlays && (direction in directions))
					vis_contents += reference_preview

	var/padding = 2
	// По умолчанию приближаем текущее тело; тела меньше 100% сохраняют относительный размер.
	var/frame_width = CEILING(max(world.icon_size, max_width) + padding * 2, 1)
	var/frame_height = CEILING(max(world.icon_size, max_height) + padding * 2, 1)
	if(single_view)
		frame_width = CEILING(max(world.icon_size, max_width + padding * 2), 1)
		frame_height = CEILING(max(world.icon_size, max_height + padding * 2), 1)
	if(!auto_fit)
		// Общая камера нужна для сравнения размеров, но оставляет запас вокруг обычного тела.
		var/max_scale = max(2, CONFIG_GET(number/body_size_max))
		frame_width = max(frame_width, CEILING(reference_width * max_scale + padding * 2, 1))
		frame_height = max(frame_height, CEILING(reference_height * max_scale + padding * 2, 1))
		if(draw_reference)
			frame_width = max(frame_width, CEILING(reference_width * (max_scale + 1) + 6 + padding * 2, 1))
	var/map_height = frame_height * length(directions)
	// Вторичная карта округляет габариты до клеток: закрашиваем также её правый и верхний запас.
	var/canvas_width = CEILING(frame_width, world.icon_size)
	var/canvas_height = CEILING(map_height, world.icon_size)
	if(!isnull(viewport_aspect))
		// Расширяем только фон. При заполнении контрола обрежется этот запас, а не фигуры.
		if(canvas_width / canvas_height < viewport_aspect)
			canvas_width = CEILING(canvas_height * viewport_aspect, world.icon_size)
		else
			canvas_height = CEILING(canvas_width / viewport_aspect, world.icon_size)
	// Явный zoom карты сохраняет нативную отрисовку спрайтов. Размер контрола уже передан в физических пикселях.
	native_zoom = 0
	if(zoom_factor != 1 && viewport_width && viewport_height)
		native_zoom = max(viewport_width / canvas_width, viewport_height / canvas_height) * zoom_factor
		if(zoom_factor < 1)
			// При отдалении продолжаем фон за исходный холст, чтобы не возникали чёрные полосы.
			canvas_width = CEILING(canvas_width / zoom_factor, world.icon_size)
			canvas_height = CEILING(canvas_height / zoom_factor, world.icon_size)
	var/background_key = "[canvas_width]x[canvas_height]|[background_style]|[background_style == "texture" ? background_state : ""]"
	if(background_cache_key != background_key)
		// Готовый фон общий для окон одного размера: повороты и повторные открытия не создают новую иконку.
		var/background = GLOB.character_preview_backgrounds[background_key]
		if(!background)
			var/icon/background_canvas = icon('icons/mob/map_backgrounds.dmi', "clear")
			background_canvas.Crop(1, 1, canvas_width, canvas_height)
			switch(background_style)
				if("light", "dark")
					background_canvas.DrawBox(background_style == "light" ? "#E4E4E4" : "#202020", 1, 1, canvas_width, canvas_height)
				if("checker")
					for(var/x = 0, x < canvas_width, x += 8)
						for(var/y = 0, y < canvas_height, y += 8)
							background_canvas.DrawBox((x / 8 + y / 8) % 2 ? "#7A7A7A" : "#B0B0B0", x + 1, y + 1, min(x + 8, canvas_width), min(y + 8, canvas_height))
				if("texture")
					var/icon/background_tile = icon('modular_citadel/icons/ui/backgrounds.dmi', background_state, SOUTH, 1)
					for(var/x = 0, x < canvas_width, x += background_tile.Width())
						for(var/y = 0, y < canvas_height, y += background_tile.Height())
							background_canvas.Blend(background_tile, ICON_OVERLAY, x + 1, y + 1)
			background = fcopy_rsc(background_canvas)
			GLOB.character_preview_backgrounds[background_key] = background
			if(length(GLOB.character_preview_backgrounds) > CHARACTER_PREVIEW_BACKGROUND_CACHE_MAX)
				GLOB.character_preview_backgrounds.Cut(1, CHARACTER_PREVIEW_BACKGROUND_CACHE_MAX / 4 + 1)
		background_cache = background
		background_cache_key = background_key
	icon = background_cache
	plane = appearance_source.plane

	var/position = 0
	for(var/direction in directions)
		var/atom/movable/screen/preview = previews["[direction]"]
		var/list/bounds = view_bounds["[direction]"]
		// Центрируем в координатах фона; pixel_x/y хранят только целые пиксели.
		preview.pixel_x = round(canvas_width / 2 - (bounds[1] + bounds[3]) / 2, 1)
		preview.pixel_y = round((canvas_height - map_height) / 2 + (position + 0.5) * frame_height - (bounds[2] + bounds[4]) / 2, 1)
		if(draw_reference)
			var/list/reference_bounds = reference_bounds_by_dir["[direction]"] || list(0, 0, world.icon_size, world.icon_size)
			var/width = bounds[3] - bounds[1]
			var/ref_width = reference_bounds[3] - reference_bounds[1]
			var/group_left = (canvas_width - width - ref_width - 6) / 2
			var/baseline = (canvas_height - map_height) / 2 + position * frame_height + (frame_height - max(bounds[4] - bounds[2], reference_bounds[4] - reference_bounds[2])) / 2
			var/atom/movable/screen/reference_preview = reference_previews["[direction]"]
			reference_preview.pixel_x = round(group_left - reference_bounds[1], 1)
			reference_preview.pixel_y = round(baseline - reference_bounds[2], 1)
			preview.pixel_x = round(group_left + ref_width + 6 - bounds[1], 1)
			preview.pixel_y = round(baseline - bounds[2], 1)
		position++
	if(use_overlays)
		var/list/figures = list()
		for(var/direction in directions)
			var/image/figure = image(previews["[direction]"], dir = direction)
			figure.plane = FLOAT_PLANE
			figures += figure
			if(draw_reference)
				var/image/reference_figure = image(reference_previews["[direction]"], dir = direction)
				reference_figure.plane = FLOAT_PLANE
				figures += reference_figure
		add_overlay(figures)
	shown_offset = PLANE_TO_OFFSET(appearance_source.plane)
	ensure_plane_group()
	apply_native_camera()

// Границы видимых пикселей слоёв: слева, снизу, справа, сверху. Картинку персонажа не пересобираем.
/atom/movable/screen/map_view/character_setup_screen/proc/prewarm_preview_bounds(mutable_appearance/appearance_source)
	var/mutable_appearance/probe = new(appearance_source)
	for(var/direction in GLOB.cardinals)
		probe.dir = direction
		measure_preview_bounds(probe, GLOB.character_preview_icon_bounds, allow_sleep = TRUE)

/atom/movable/screen/map_view/character_setup_screen/proc/measure_preview_bounds(image/source, list/icon_sizes, inherited_icon, inherited_state, inherited_dir = SOUTH, allow_sleep = FALSE)
	if(source.alpha <= 0)
		return null
	var/icon_file = source.icon || inherited_icon
	var/state = source.icon_state || inherited_state
	var/direction = (!source.dir || source.dir == SOUTH) ? inherited_dir : source.dir
	var/width = world.icon_size
	var/height = world.icon_size
	var/list/bounds
	if(icon_file)
		var/file_name = "[icon_file]"
		var/cache_prefix = "[length(file_name) ? file_name : REF(icon_file)]|[state]|"
		var/list/size = icon_sizes["[cache_prefix][direction]"]
		if(!size)
			var/icon_dir = icon_state_has_directional_frames(icon_file, state) ? direction : SOUTH
			size = icon_sizes["[cache_prefix][icon_dir]"]
			if(!size)
				var/icon/measured = icon(icon_file, state, icon_dir, 1)
				size = list(measured.Width(), measured.Height(), measure_pixel_bounds(measured))
				icon_sizes["[cache_prefix][icon_dir]"] = size
			icon_sizes["[cache_prefix][direction]"] = size
			// Храним только числа; смена одежды и причёсок не должна растить кэш бесконечно.
			if(length(icon_sizes) > CHARACTER_PREVIEW_BOUNDS_CACHE_MAX)
				icon_sizes.Cut(1, CHARACTER_PREVIEW_BOUNDS_CACHE_MAX / 4 + 1)
			if(allow_sleep)
				CHECK_TICK
		width = size[1]
		height = size[2]
		var/list/pixel_bounds = size[3]
		bounds = pixel_bounds?.Copy()

	var/list/untransformed_bounds
	for(var/image/child as anything in source.underlays + source.overlays)
		var/list/child_bounds = measure_preview_bounds(child, icon_sizes, icon_file, state, direction, allow_sleep)
		if(!child_bounds)
			continue
		child_bounds[1] += child.pixel_x + child.pixel_w
		child_bounds[2] += child.pixel_y + child.pixel_z
		child_bounds[3] += child.pixel_x + child.pixel_w
		child_bounds[4] += child.pixel_y + child.pixel_z
		var/keep_together = (source.appearance_flags & KEEP_TOGETHER) && !(child.appearance_flags & KEEP_APART)
		if((child.appearance_flags & RESET_TRANSFORM) && !keep_together)
			if(!untransformed_bounds)
				untransformed_bounds = child_bounds.Copy()
			else
				untransformed_bounds[1] = min(untransformed_bounds[1], child_bounds[1])
				untransformed_bounds[2] = min(untransformed_bounds[2], child_bounds[2])
				untransformed_bounds[3] = max(untransformed_bounds[3], child_bounds[3])
				untransformed_bounds[4] = max(untransformed_bounds[4], child_bounds[4])
			continue
		if(!bounds)
			bounds = child_bounds.Copy()
		else
			bounds[1] = min(bounds[1], child_bounds[1])
			bounds[2] = min(bounds[2], child_bounds[2])
			bounds[3] = max(bounds[3], child_bounds[3])
			bounds[4] = max(bounds[4], child_bounds[4])

	var/matrix/transform = source.transform
	if(bounds && transform)
		var/list/transformed_bounds
		for(var/x in list(bounds[1], bounds[3]))
			for(var/y in list(bounds[2], bounds[4]))
				// BYOND применяет матрицу относительно центра базовой иконки, а не всей стопки оверлеев.
				var/transformed_x = transform.a * (x - width / 2) + transform.b * (y - height / 2) + transform.c + width / 2
				var/transformed_y = transform.d * (x - width / 2) + transform.e * (y - height / 2) + transform.f + height / 2
				if(!transformed_bounds)
					transformed_bounds = list(transformed_x, transformed_y, transformed_x, transformed_y)
				else
					transformed_bounds[1] = min(transformed_bounds[1], transformed_x)
					transformed_bounds[2] = min(transformed_bounds[2], transformed_y)
					transformed_bounds[3] = max(transformed_bounds[3], transformed_x)
					transformed_bounds[4] = max(transformed_bounds[4], transformed_y)
		bounds = transformed_bounds
	if(untransformed_bounds)
		if(!bounds)
			return untransformed_bounds
		bounds[1] = min(bounds[1], untransformed_bounds[1])
		bounds[2] = min(bounds[2], untransformed_bounds[2])
		bounds[3] = max(bounds[3], untransformed_bounds[3])
		bounds[4] = max(bounds[4], untransformed_bounds[4])
	return bounds

// Ищем крайние непрозрачные строки и столбцы от краёв к центру: пустые поля не обходятся целиком.
/atom/movable/screen/map_view/character_setup_screen/proc/measure_pixel_bounds(icon/measured)
	var/width = measured.Width()
	var/height = measured.Height()
	var/min_y
	for(var/y in 1 to height)
		for(var/x in 1 to width)
			if(measured.GetPixel(x, y))
				min_y = y
				break
		if(min_y)
			break
	if(!min_y)
		return null
	var/max_y
	for(var/y = height, y > min_y && !max_y, y--)
		for(var/x in 1 to width)
			if(measured.GetPixel(x, y))
				max_y = y
				break
	max_y ||= min_y
	var/min_x
	for(var/x in 1 to width)
		for(var/y in min_y to max_y)
			if(measured.GetPixel(x, y))
				min_x = x
				break
		if(min_x)
			break
	var/max_x
	for(var/x = width, x > min_x && !max_x, x--)
		for(var/y in min_y to max_y)
			if(measured.GetPixel(x, y))
				max_x = x
				break
	max_x ||= min_x
	return list(min_x - 1, min_y - 1, max_x, max_y)

#undef CHARACTER_PREVIEW_BOUNDS_CACHE_MAX
#undef CHARACTER_PREVIEW_BACKGROUND_CACHE_MAX
