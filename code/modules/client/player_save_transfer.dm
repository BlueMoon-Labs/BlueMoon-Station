// Публичный формат отделён от доверенного дискового: никаких ImportText и произвольных типов.
#define PLAYER_TRANSFER_MAX_BYTES (2 * 1024 * 1024)
#define PLAYER_TRANSFER_MAX_NODES 20000
#define PLAYER_TRANSFER_MAX_DEPTH 6

/// Только явно проверенные поля. Новое поле дискового сейва НЕ становится переносимым автоматически.
/proc/player_transfer_fields()
	var/static/list/fields = list(
		"age" = "scalar",
		"all_quirks" = "list",
		"alt_titles_preferences" = "list",
		"backbag" = "scalar",
		"bark_id" = "scalar",
		"bark_pitch" = "scalar",
		"bark_speed" = "scalar",
		"bark_variance" = "scalar",
		"blood_color" = "scalar",
		"body_is_always_random" = "scalar",
		"body_model" = "scalar",
		"body_size" = "scalar",
		"body_weight" = "scalar",
		"chosen_limb_id" = "scalar",
		"custom_blood_color" = "scalar",
		"custom_emote_panel" = "list",
		"custom_interactions" = "interactions",
		"custom_laugh" = "scalar",
		"custom_species" = "text",
		"custom_speech_verb" = "scalar",
		"custom_tongue" = "scalar",
		"egg_shell" = "scalar",
		"enable_personal_chat_color" = "scalar",
		"erp_pref" = "scalar",
		"extreme_harm" = "scalar",
		"extreme_pref" = "scalar",
		"eye_type" = "scalar",
		"facial_hair_color" = "scalar",
		"facial_style_name" = "scalar",
		"feature_allow_emissives" = "scalar",
		"feature_anus_accessible" = "scalar",
		"feature_anus_color" = "scalar",
		"feature_anus_shape" = "scalar",
		"feature_anus_stuffing" = "scalar",
		"feature_anus_visibility" = "scalar",
		"feature_arachnid_legs" = "scalar",
		"feature_arachnid_mandibles" = "scalar",
		"feature_arachnid_spinneret" = "scalar",
		"feature_balls_accessible" = "scalar",
		"feature_balls_color" = "scalar",
		"feature_balls_fluid" = "fluid",
		"feature_balls_shape" = "scalar",
		"feature_balls_size" = "scalar",
		"feature_balls_stuffing" = "scalar",
		"feature_balls_visibility" = "scalar",
		"feature_belly_accessible" = "scalar",
		"feature_belly_color" = "scalar",
		"feature_belly_size" = "scalar",
		"feature_belly_stuffing" = "scalar",
		"feature_belly_visibility" = "scalar",
		"feature_breasts_accessible" = "scalar",
		"feature_breasts_color" = "scalar",
		"feature_breasts_fluid" = "fluid",
		"feature_breasts_producing" = "scalar",
		"feature_breasts_shape" = "scalar",
		"feature_breasts_size" = "scalar",
		"feature_breasts_stuffing" = "scalar",
		"feature_breasts_visibility" = "scalar",
		"feature_butt_accessible" = "scalar",
		"feature_butt_color" = "scalar",
		"feature_butt_size" = "scalar",
		"feature_butt_stuffing" = "scalar",
		"feature_butt_visibility" = "scalar",
		"feature_cock_accessible" = "scalar",
		"feature_cock_color" = "scalar",
		"feature_cock_diameter_ratio" = "scalar",
		"feature_cock_length" = "scalar",
		"feature_cock_shape" = "scalar",
		"feature_cock_stuffing" = "scalar",
		"feature_cock_taur" = "scalar",
		"feature_cock_visibility" = "scalar",
		"feature_color_scheme" = "scalar",
		"feature_custom_deathgasp" = "text",
		"feature_custom_deathsound" = "text",
		"feature_custom_species_lore" = "text",
		"feature_deco_wings" = "scalar",
		"feature_emissive_eyes" = "scalar",
		"feature_emissive_parts" = "json",
		"feature_flavor_text" = "text",
		"feature_fuzzy" = "scalar",
		"feature_genitals_use_skintone" = "scalar",
		"feature_hardsuit_with_tail" = "scalar",
		"feature_has_anus" = "scalar",
		"feature_has_balls" = "scalar",
		"feature_has_belly" = "scalar",
		"feature_has_breasts" = "scalar",
		"feature_has_butt" = "scalar",
		"feature_has_cock" = "scalar",
		"feature_has_vag" = "scalar",
		"feature_has_womb" = "scalar",
		"feature_horns_color" = "scalar",
		"feature_human_ears" = "scalar",
		"feature_human_tail" = "scalar",
		"feature_inert_eggs" = "scalar",
		"feature_insect_fluff" = "scalar",
		"feature_insect_markings" = "scalar",
		"feature_insect_wings" = "scalar",
		"feature_ipc_antenna" = "scalar",
		"feature_ipc_screen" = "scalar",
		"feature_lizard_frills" = "scalar",
		"feature_lizard_horns" = "scalar",
		"feature_lizard_legs" = "scalar",
		"feature_lizard_snout" = "scalar",
		"feature_lizard_spines" = "scalar",
		"feature_lizard_tail" = "scalar",
		"feature_mam_body_markings" = "json",
		"feature_mam_ears" = "scalar",
		"feature_mam_snouts" = "scalar",
		"feature_mam_tail" = "scalar",
		"feature_mam_tail_animated" = "scalar",
		"feature_mcolor" = "scalar",
		"feature_mcolor2" = "scalar",
		"feature_mcolor3" = "scalar",
		"feature_meat" = "scalar",
		"feature_naked_flavor_text" = "text",
		"feature_neckfire" = "scalar",
		"feature_neckfire_color" = "scalar",
		"feature_puddle_slime_fea" = "scalar",
		"feature_silicon_flavor_text" = "text",
		"feature_taur" = "scalar",
		"feature_vag_accessible" = "scalar",
		"feature_vag_color" = "scalar",
		"feature_vag_shape" = "scalar",
		"feature_vag_stuffing" = "scalar",
		"feature_vag_visibility" = "scalar",
		"feature_wings_color" = "scalar",
		"feature_womb_fluid" = "fluid",
		"feature_xeno_dors" = "scalar",
		"feature_xeno_head" = "scalar",
		"feature_xeno_tail" = "scalar",
		"features_balls_max_size" = "scalar",
		"features_balls_min_size" = "scalar",
		"features_belly_max_size" = "scalar",
		"features_belly_min_size" = "scalar",
		"features_breasts_max_size" = "scalar",
		"features_breasts_min_size" = "scalar",
		"features_butt_max_size" = "scalar",
		"features_butt_min_size" = "scalar",
		"features_cock_max_length" = "scalar",
		"features_cock_min_length" = "scalar",
		"fertile" = "scalar",
		"gender" = "scalar",
		"grad_color" = "scalar",
		"grad_style" = "scalar",
		"hair_color" = "scalar",
		"hair_style_name" = "scalar",
		"job_preferences" = "list",
		"joblessrole" = "scalar",
		"jumpsuit_style" = "scalar",
		"language" = "list",
		"left_eye_color" = "scalar",
		"loadout" = "loadout",
		"loadout_enabled" = "scalar",
		"loadout_slot" = "scalar",
		"lust_tolerance" = "scalar",
		"medical_records" = "text",
		"mobsex_pref" = "scalar",
		"modified_limbs" = "limbs",
		"name_is_always_random" = "scalar",
		"nameless" = "scalar",
		"noncon_pref" = "scalar",
		"normalized_size" = "scalar",
		"onelife_death_type" = "scalar",
		"pda_color" = "scalar",
		"pda_ringtone" = "scalar",
		"pda_skin" = "scalar",
		"pda_style" = "scalar",
		"pda_theme" = "scalar",
		"personal_chat_color" = "scalar",
		"phobia_type" = "scalar",
		"prefered_security_department" = "scalar",
		"preferred_ai_core_display" = "scalar",
		"pregnancy_breast_growth" = "scalar",
		"pregnancy_inflation" = "scalar",
		"real_name" = "text",
		"right_eye_color" = "scalar",
		"security_records" = "text",
		"sexual_potency" = "scalar",
		"shirt_color" = "scalar",
		"shriek_type" = "scalar",
		"silicon_lawset" = "scalar",
		"skin_tone" = "scalar",
		"socks" = "scalar",
		"socks_color" = "scalar",
		"species" = "scalar",
		"summon_nickname" = "text",
		"tattoo_pref" = "scalar",
		"undershirt" = "scalar",
		"underwear" = "scalar",
		"undie_color" = "scalar",
		"unholyhard_pref" = "scalar",
		"unholypref" = "scalar",
		"uplink_loc" = "scalar",
		"use_custom_skin_tone" = "scalar",
		"virile" = "scalar",
		"vore_flags" = "scalar",
		"vore_pref" = "scalar",
		"vore_smell" = "text",
		"vore_taste" = "text",
	)
	return fields


/proc/player_transfer_field_mode(key)
	var/mode = player_transfer_fields()[key]
	if(mode)
		return mode
	var/static/list/dynamic_fields
	if(!dynamic_fields)
		dynamic_fields = list()
		for(var/id in GLOB.preferences_custom_names)
			dynamic_fields["[id]_name"] = "text"
		// Только зарегистрированные аксессуары; список строится один раз, а не для каждого поля файла.
		for(var/feature in GLOB.mutant_reference_list)
			var/list/accessories = GLOB.mutant_reference_list[feature]
			for(var/name in accessories)
				var/datum/sprite_accessory/accessory = accessories[name]
				if(!istype(accessory))
					continue
				var/part = accessory.mutant_part_string
				if(!part && istype(accessory, /datum/sprite_accessory/mam_body_markings))
					part = "mam_body_markings"
				if(part)
					for(var/suffix in list("primary", "secondary", "tertiary"))
						dynamic_fields["feature_[part]_[suffix]"] = "color"
	return dynamic_fields[key]

/// Проверяется всё дерево ДО вызова внутреннего декодера; byond/path/matrix не допускаются.
/proc/player_transfer_validate_value(value, list/budget, depth = 0)
	if(depth > PLAYER_TRANSFER_MAX_DEPTH || --budget[1] < 0)
		throw EXCEPTION("Слишком сложный файл персонажа")
	if(isnull(value) || isnum(value))
		return
	if(istext(value))
		if(length(value) > 65536)
			throw EXCEPTION("Слишком длинное поле персонажа")
		return
	if(!islist(value))
		throw EXCEPTION("Недопустимое значение")
	var/list/node = value
	switch(node["type"])
		if("number", "text")
			if(node.len != 2 || !istext(node["value"]) || length(node["value"]) > 65536)
				throw EXCEPTION("Некорректное скалярное значение")
		if("list")
			var/list/items = node["items"]
			var/list/associations = node["associations"]
			if(node.len != 3 || !islist(items) || !islist(associations) || items.len != associations.len || items.len > 4096)
				throw EXCEPTION("Некорректный список")
			for(var/i in 1 to items.len)
				player_transfer_validate_value(items[i], budget, depth + 1)
				player_transfer_validate_value(associations[i], budget, depth + 1)
		else
			throw EXCEPTION("Этот тип данных нельзя импортировать")

/proc/player_transfer_interaction_fields()
	var/static/list/fields = list("name", "message", "interaction_type", "arousal_level", "partner_arousal_level", "self_orgasm", "partner_orgasm", "scope", "required_body_parts", "requires_tail", "requires_telekinesis", "max_distance", "sound_keys")
	return fields

/proc/player_transfer_encode_field(mode, value)
	if(mode == "fluid")
		return ispath(value) ? "[value]" : null
	if(mode == "interactions")
		var/list/result = list()
		for(var/datum/interaction/custom/custom as anything in value)
			if(!istype(custom))
				continue
			var/list/entry = list()
			for(var/key in player_transfer_interaction_fields())
				entry[key] = custom.vars[key]
			result += list(entry)
		value = result
	return player_save_encode_value(value)

/proc/player_transfer_decode_field(key, mode, encoded, list/budget)
	player_transfer_validate_value(encoded, budget)
	var/value = player_save_decode_value(encoded)
	if(isnull(value))
		return null
	switch(mode)
		if("scalar", "text")
			if(!istext(value) && !isnum(value))
				throw EXCEPTION("Поле [key] должно быть строкой или числом")
			if(mode == "text" && istext(value))
				value = html_encode(html_decode(value))
		if("color")
			if(!istext(value))
				throw EXCEPTION("Некорректный дополнительный цвет")
			return sanitize_hexcolor(value, 6, FALSE)
		if("fluid")
			if(!istext(value))
				throw EXCEPTION("Некорректная жидкость")
			var/resolved = text2path(value)
			if(!ispath(resolved, /datum/reagent) || !(find_reagent_object_from_type(resolved) in GLOB.genital_fluids_list))
				throw EXCEPTION("Недоступная жидкость")
			return resolved
		if("list", "interactions")
			if(!islist(value))
				throw EXCEPTION("Поле [key] должно быть списком")
			if(key == "custom_emote_panel")
				value = player_transfer_escape_list(value)
		if("json", "loadout", "limbs")
			if(!istext(value))
				throw EXCEPTION("Некорректные данные [key]")
			player_transfer_check_json_depth(value)
			var/list/decoded = json_decode(value)
			if(!islist(decoded))
				throw EXCEPTION("Некорректный список [key]")
			player_transfer_validate_value(player_save_encode_value(decoded), budget)
			if(mode == "loadout")
				decoded = player_transfer_escape_list(decoded)
			value = json_encode(decoded)
			if(mode == "limbs")
				var/prosthetics = 0
				for(var/zone in decoded)
					var/list/limb = decoded[zone]
					if(!(zone in LOADOUT_ALLOWED_LIMB_TARGETS) || !islist(limb) || !length(limb) || !(limb[1] in LOADOUT_LIMBS))
						throw EXCEPTION("Недопустимая модификация конечности")
					if(limb[1] == LOADOUT_LIMB_PROSTHETIC)
						if(limb.len != 2 || !(limb[2] in (list("prosthetic") + GLOB.prosthetic_limb_types)))
							throw EXCEPTION("Неизвестный протез")
						prosthetics++
					else if(limb.len != 1)
						throw EXCEPTION("Некорректная модификация конечности")
				if(prosthetics > MAXIMUM_LOADOUT_PROSTHETICS)
					throw EXCEPTION("Превышен лимит протезов")
			if(mode == "loadout")
				if(decoded.len > MAXIMUM_LOADOUT_SAVES)
					throw EXCEPTION("Слишком много наборов экипировки")
				for(var/slot in decoded)
					var/slot_number = istext(slot) ? text2num(copytext(slot, 6)) : null
					if(!slot_number || slot_number != round(slot_number) || slot_number < 1 || slot_number > MAXIMUM_LOADOUT_SAVES || slot != "SAVE_[slot_number]")
						throw EXCEPTION("Неизвестный набор экипировки")
					var/list/entries = decoded[slot]
					if(!islist(entries) || entries.len > 100)
						throw EXCEPTION("Слишком много предметов экипировки")
					for(var/list/entry as anything in entries)
						if(!islist(entry) || !istext(entry[LOADOUT_ITEM]) || !ispath(text2path(entry[LOADOUT_ITEM]), /datum/gear))
							throw EXCEPTION("Неизвестный предмет экипировки")
	if(mode == "interactions")
		var/list/result = list()
		if(length(value) > 100)
			throw EXCEPTION("Слишком много пользовательских действий")
		for(var/list/entry as anything in value)
			if(!islist(entry))
				throw EXCEPTION("Некорректное пользовательское действие")
			for(var/key_name in entry)
				if(!(key_name in player_transfer_interaction_fields()))
					throw EXCEPTION("Недопустимое поле действия")
				if(key_name == "sound_keys")
					if(!islist(entry[key_name]))
						throw EXCEPTION("Некорректный список звуков")
				else if(!istext(entry[key_name]) && !isnum(entry[key_name]) && !isnull(entry[key_name]))
					throw EXCEPTION("Некорректное значение действия")
			var/datum/interaction/custom/custom = new
			for(var/key_name in entry)
				custom.vars[key_name] = entry[key_name]
			custom.sanitize_values()
			result += custom
		return result
	return value

/datum/preferences
	var/tmp/player_transfer_error
	var/tmp/player_transfer_busy = FALSE
	var/tmp/player_transfer_cooldown = 0

/// Возвращает только публичные данные текущего персонажа, без чтения корня аккаунта.
/datum/preferences/proc/export_character_json()
	player_transfer_error = null
	try
		var/savefile/source = write_character(TRUE, TRUE, TRUE)
		if(!istype(source))
			throw EXCEPTION("Не удалось подготовить персонажа")
		var/list/fields = list()
		var/list/budget = list(PLAYER_TRANSFER_MAX_NODES)
		for(var/key in source.dir)
			var/mode = player_transfer_field_mode(key)
			if(!mode)
				continue
			var/value
			source[key] >> value
			var/encoded = player_transfer_encode_field(mode, value)
			player_transfer_validate_value(encoded, budget)
			fields[key] = encoded
		var/text = json_encode(list("format" = "bluemoon-character", "version" = 1, "fields" = fields))
		if(length(text) > PLAYER_TRANSFER_MAX_BYTES)
			throw EXCEPTION("Персонаж превышает лимит файла 2 МиБ")
		return text
	catch(var/exception/failure)
		player_transfer_error = failure.name
		return null

/// Файл сначала полностью проверяется; миграции дискового формата здесь никогда не запускаются.
/proc/player_transfer_parse(text)
	if(!istext(text) || !length(text) || length(text) > PLAYER_TRANSFER_MAX_BYTES)
		throw EXCEPTION("Нужен JSON персонажа размером не более 2 МиБ")
	player_transfer_check_json_depth(text)
	var/list/document = json_decode(text)
	if(!islist(document) || document.len != 3 || document["format"] != "bluemoon-character" || document["version"] != 1)
		throw EXCEPTION("Неподдерживаемый формат персонажа")
	var/list/fields = document["fields"]
	if(!islist(fields) || !length(fields) || fields.len > 512)
		throw EXCEPTION("Некорректный набор полей")
	var/list/result = list()
	var/list/budget = list(PLAYER_TRANSFER_MAX_NODES)
	for(var/key in fields)
		if(!istext(key))
			throw EXCEPTION("Некорректное имя поля")
		var/mode = player_transfer_field_mode(key)
		if(!mode)
			throw EXCEPTION("Поле [copytext(key, 1, 64)] нельзя переносить")
		result[key] = player_transfer_decode_field(key, mode, fields[key], budget)
	return result

/// Пробная загрузка не касается живых prefs. Публикуется только разрешённая часть результата.
/datum/preferences/proc/import_character_json(text)
	player_transfer_error = null
	var/datum/preferences/transfer_staging/staged
	try
		var/list/fields = player_transfer_parse(text)
		if(player_save_blocked || !path)
			throw EXCEPTION("Хранилище персонажа недоступно")
		var/savefile/current = write_character(TRUE, TRUE, TRUE)
		var/savefile/baseline = new
		if(!current)
			throw EXCEPTION("Не удалось подготовить текущий слот")
		player_save_copy_tree(current, baseline)
		for(var/key in fields)
			baseline[key] << fields[key]
		staged = new
		staged.interaction_limit = get_custom_interaction_limit()
		if(length(fields["custom_interactions"]) > staged.interaction_limit)
			throw EXCEPTION("Превышен доступный вашему аккаунту лимит пользовательских действий")
		if(!staged.load_character(null, TRUE, baseline))
			throw EXCEPTION("Не удалось проверить персонажа")
		validate_character_transfer_access(staged, fields)
		var/savefile/sanitized = staged.write_character(TRUE, TRUE, TRUE)
		var/savefile/destination = open_player_save("/character[default_slot]")
		if(!sanitized || !destination)
			throw EXCEPTION("Не удалось подготовить запись персонажа")
		destination.cd = "/character[default_slot]"
		// Не теряем ещё не записанные изменения текущего персонажа, включая коллекции.
		if(length(destination.dir) && savefile_needs_update(destination) == -2)
			throw EXCEPTION("Версия выбранного слота не поддерживается")
		player_save_copy_tree(current, destination)
		for(var/key in fields)
			var/value
			sanitized[key] >> value
			destination[key] << value
		var/current_version
		baseline["version"] >> current_version
		destination["version"] << current_version
		if(!commit_player_save(destination, "/character[default_slot]"))
			throw EXCEPTION("Не удалось записать персонажа; исходный слот сохранён")
		qdel(staged)
		staged = null
		// Все потенциально опасные разборы уже выполнены на пробном объекте.
		return !!load_character(default_slot, TRUE)
	catch(var/exception/failure)
		if(staged)
			qdel(staged)
		player_transfer_error = failure.name
		return FALSE

/datum/preferences/proc/download_character_json(mob/user)
	var/text = export_character_json()
	if(!text)
		to_chat(user, span_warning("Экспорт не выполнен: [html_encode(player_transfer_error)]"))
		return
	var/static/sequence = 0
	var/temp_path = "data/player_transfer/export_[world.realtime]_[++sequence].json"
	if(!text2file(text, temp_path))
		to_chat(user, span_warning("Не удалось создать файл экспорта."))
		return
	var/resource = fcopy_rsc(temp_path)
	fdel(temp_path)
	user << ftp(resource, "bluemoon-character.json")

/datum/preferences/proc/upload_character_json(mob/user)
	if(player_transfer_busy || world.time < player_transfer_cooldown)
		return
	player_transfer_busy = TRUE
	player_transfer_cooldown = world.time + 10 SECONDS
	var/slot = default_slot
	var/upload = input(user, "Выберите JSON персонажа (до 2 МиБ). Изменится только выбранный слот.", "Импорт персонажа") as file|null
	if(!upload || user.client?.prefs != src || slot != default_slot)
		player_transfer_busy = FALSE
		return
	if(length(upload) > PLAYER_TRANSFER_MAX_BYTES)
		to_chat(user, span_warning("Размер файла превышает 2 МиБ."))
		player_transfer_busy = FALSE
		return
	var/text = file2text(upload)
	try
		player_transfer_parse(text)
	catch(var/exception/failure)
		to_chat(user, span_warning("Импорт отклонён: [html_encode(failure.name)]"))
		player_transfer_busy = FALSE
		return
	var/confirmed = tgui_alert(user, "Заменить переносимые настройки слота [slot]? Валюта, коллекции и закрытые данные останутся прежними.", "Импорт персонажа", list("Импортировать", "Отмена"))
	if(confirmed == "Импортировать" && user.client?.prefs == src && default_slot == slot)
		if(import_character_json(text))
			to_chat(user, span_notice("Персонаж импортирован и сохранён в слот [slot]."))
		else
			to_chat(user, span_warning("Импорт не выполнен: [html_encode(player_transfer_error)]"))
	player_transfer_busy = FALSE


/// Те же ограничения, что в редакторе: файл не выдаёт доступ к донатным предметам и обликам.
/datum/preferences/proc/validate_character_transfer_access(datum/preferences/staged, list/fields)
	var/recipient = parent?.ckey
	if("species" in fields)
		var/available = FALSE
		for(var/name in GLOB.roundstart_race_names)
			if(GLOB.roundstart_race_names[name] == staged.pref_species.id)
				available = TRUE
				break
		if(!available)
			throw EXCEPTION("Этот вид недоступен в редакторе персонажа")
	if("bark_id" in fields)
		var/datum/bark/bark = GLOB.bark_list[staged.bark_id]
		var/list/allowed = initial(bark.ckeys_allowed)
		if(initial(bark.ignore) || (length(allowed) && !(recipient in allowed)))
			throw EXCEPTION("Этот голос недоступен вашему аккаунту")
	for(var/feature in GLOB.mutant_reference_list)
		var/list/accessories = GLOB.mutant_reference_list[feature]
		var/selected = staged.features[feature]
		var/list/selections = islist(selected) ? selected : list(selected)
		for(var/selection in selections)
			if(!istext(selection))
				continue
			var/datum/sprite_accessory/accessory = accessories[selection]
			if(istype(accessory) && length(accessory.ckeys_allowed) && !(recipient in accessory.ckeys_allowed))
				throw EXCEPTION("Один из элементов внешности недоступен вашему аккаунту")
	if("language" in fields)
		if(CONFIG_GET(number/max_languages) >= 0 && length(staged.language) > CONFIG_GET(number/max_languages))
			throw EXCEPTION("Превышен лимит языков")
	if(("all_quirks" in fields) || ("body_weight" in fields) || ("modified_limbs" in fields))
		var/list/seen = list()
		var/balance = -mob_size_name_to_quirk_cost(staged.body_weight)
		for(var/quirk in staged.all_quirks)
			if(!istext(quirk) || !SSquirks.quirks[quirk] || (quirk in seen))
				throw EXCEPTION("Неизвестный или повторяющийся квирк")
			seen += quirk
			balance -= SSquirks.quirk_points[quirk]
		for(var/limb in staged.modified_limbs)
			if(staged.modified_limbs[limb][1] == LOADOUT_LIMB_PROSTHETIC)
				balance++
		if(balance < 0 || staged.GetPositiveQuirkCount() > MAX_QUIRKS || SSquirks.check_blacklist_conflicts(staged.all_quirks))
			throw EXCEPTION("Набор квирков не соответствует ограничениям редактора")
	if("loadout" in fields)
		var/points = CONFIG_GET(number/initial_gear_points)
		if(recipient)
			points += (IS_CKEY_DONATOR_GROUP(recipient, DONATOR_GROUP_TIER_1) ? CONFIG_GET(number/subscriber_extra_gear_points) : 0)
			points += (IS_CKEY_DONATOR_GROUP(recipient, DONATOR_GROUP_TIER_2) ? CONFIG_GET(number/sponsor_extra_gear_points) : 0)
		for(var/slot in staged.loadout_data)
			var/list/seen = list()
			var/remaining = points
			for(var/list/entry as anything in staged.loadout_data[slot])
				var/datum/gear/gear_type = text2path(entry[LOADOUT_ITEM])
				var/list/categories = GLOB.loadout_items[initial(gear_type.category)]
				var/list/subcategories = categories?[initial(gear_type.subcategory)]
				var/datum/gear/gear = subcategories?[initial(gear_type.name)]
				if(!gear || (gear_type in seen))
					throw EXCEPTION("Неизвестный или повторяющийся предмет экипировки")
				seen += gear_type
				if((gear.donoritem && (!recipient || !gear.donator_ckey_check(recipient))) || (istype(gear, /datum/gear/unlockable) && !can_use_unlockable(gear)))
					throw EXCEPTION("Один из предметов экипировки ещё не открыт вашим аккаунтом")
				remaining -= gear.cost
			if(remaining < 0)
				throw EXCEPTION("Превышен бюджет экипировки")


/proc/player_transfer_escape_list(value)
	if(istext(value))
		return html_encode(html_decode(value))
	if(!islist(value))
		return value
	var/list/source = value
	var/list/result = list()
	for(var/i in 1 to source.len)
		var/key = source[i]
		var/safe_key = player_transfer_escape_list(key)
		result += list(safe_key)
		if(!isnull(key) && !isnum(key) && !isnull(source[key]))
			result[safe_key] = player_transfer_escape_list(source[key])
	return result


/// BYOND молча обрезает очень глубокий JSON. Проверяем исходный текст до json_decode.
/proc/player_transfer_check_json_depth(text)
	var/depth = 0
	var/in_string = FALSE
	var/escaped = FALSE
	for(var/i in 1 to length(text))
		var/character = text2ascii(text, i)
		if(in_string)
			if(escaped)
				escaped = FALSE
			else if(character == 92)
				escaped = TRUE
			else if(character == 34)
				in_string = FALSE
		else if(character == 34)
			in_string = TRUE
		else if(character == 91 || character == 123)
			if(++depth > 16)
				throw EXCEPTION("Слишком глубокий JSON персонажа")
		else if(character == 93 || character == 125)
			depth--


/// Пробный объект не привязан к клиенту, но учитывает полученные от сервера лимиты аккаунта.
/datum/preferences/transfer_staging
	var/interaction_limit

/datum/preferences/transfer_staging/get_custom_interaction_limit()
	return interaction_limit || ..()
