//
// Vore management panel for players
//

#define BELLIES_MAX 40
#define BELLIES_NAME_MIN 2
#define BELLIES_NAME_MAX 40
#define BELLIES_DESC_MAX 4096
#define FLAVOR_MAX 400
#define BELLIES_MSG_MAX 10

//
// Глаголы, жизненный цикл окна, кэш иконок
//

/mob/living
	var/datum/vore_look/vorePanel

/mob/living/proc/insidePanel()
	set name = "Vore Panel"
	set category = "Vore"

	if(!vorePanel)
		log_game("VORE: [src] ([type], \ref[src]) didn't have a vorePanel and tried to use the verb.")
		vorePanel = new(src)

	vorePanel.ui_interact(src)

/mob/living/proc/updateVRPanel() //Panel popup update call from belly events.
	SStgui.update_uis(vorePanel)

//
// Vore panel
//
/datum/vore_look
	var/mob/living/host // Note, we do this in case we ever want to allow people to view others vore panels
	var/unsaved_changes = FALSE
	var/show_pictures = TRUE
	var/export_text // JSON выбранного нутра для вкладки «Общие»

/datum/vore_look/New(mob/living/new_host)
	if(istype(new_host))
		host = new_host
	. = ..()

/datum/vore_look/Destroy()
	host = null
	. = ..()

/datum/vore_look/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "VorePanel", "Меню Воре")
		ui.open()

// This looks weird, but all tgui_host is used for is state checking
// So this allows us to use the self_state just fine.
/datum/vore_look/ui_host(mob/user)
	return host

// Note, in order to allow others to look at others vore panels, this state would need
// to be modified.
/datum/vore_look/ui_state(mob/user)
	return GLOB.ui_vorepanel_state

// Превью полноэкранных стилей
/datum/asset/simple/vore_previews
	assets = list(
		"vore_preview_dark.png" = 'html/vore_previews/vore_preview_dark.png',
		"vore_preview_blue.png" = 'html/vore_previews/vore_preview_blue.png',
		"vore_preview_flesh.png" = 'html/vore_previews/vore_preview_flesh.png',
	)

/datum/vore_look/ui_assets(mob/user)
	. = ..() || list()
	. += get_asset_datum(/datum/asset/simple/vore_previews)

/datum/vore_look
	var/static/list/nom_icons

/datum/vore_look/proc/cached_nom_icon(atom/target)
	LAZYINITLIST(nom_icons)

	var/key = ""
	if(isobj(target))
		key = "[target.type]"
	else if(ismob(target))
		var/mob/M = target
		key = "\ref[target][M.real_name]"
	if(nom_icons[key])
		. = nom_icons[key]
	else
		. = icon2base64(getFlatIcon(target,defdir=SOUTH,no_anim=TRUE))
		nom_icons[key] = .

//
// Сборка данных ui_data() и его хелперы.
// Форма всего, что уходит во фронтенд, описана в VorePanel/types.ts.
//

/datum/vore_look/proc/build_content_list(obj/belly/B, mob/living/skip)
	var/list/result = list()
	for(var/atom/movable/O in B)
		if(O == skip)
			continue

		var/list/info = list(
			"name" = "[O]",
			"absorbed" = FALSE,
			"stat" = 0,
			"ref" = "\ref[O]",
			"outside" = (B == host.vore_selected),
		)
		if(show_pictures)
			info["icon"] = cached_nom_icon(O)
		if(ismob(O))
			var/mob/M = O
			info["name"] = M.name
		if(isliving(O))
			var/mob/living/L = O
			info["stat"] = L.stat
			if(L.vore_flags & ABSORBED)
				info["absorbed"] = TRUE
		result.Add(list(info))
	return result

// Ключи ассоциативного списка
/datum/vore_look/proc/list_keys(list/haystack)
	var/list/result = list()
	for(var/item_name in haystack)
		result |= item_name
	return result

// Полное состояние одного нутра для интерфейса
/datum/vore_look/proc/belly_state(obj/belly/B)
	var/list/state = list(
		"ref" = "\ref[B]",
		"name" = B.name,
		"display_name" = B.display_name,
		"vore_types" = B.vore_types,
		"mode_addons" = B.mode_addons,
		"digest_mode" = B.digest_mode,
		"digest_modes" = B.digest_modes.Copy(),
		"desc" = B.desc || "",
		"absorbed_desc" = B.absorbed_desc || "",
		"vore_verb" = B.vore_verb,
		"release_verb" = B.release_verb,
		"immutable" = B.immutable,

		"vore_sound" = B.vore_sound,
		"vore_sounds" = list_keys(GLOB.pred_vore_sounds),
		"release_sound" = B.release_sound,
		"release_sounds" = list_keys(GLOB.pred_release_sounds),
		"sound_volume" = B.sound_volume,
		"noise_freq" = B.noise_freq,

		"can_taste" = B.can_taste,
		"feedable" = B.feedable,
		"is_wet" = B.is_wet,
		"wet_loop" = B.wet_loop,
		"can_victim_see" = B.can_victim_see,

		"bulge_size" = B.bulge_size,
		"emote_time" = B.emote_time,
		"emote_active" = B.emote_active,
		"human_prey_swallow_time" = B.human_prey_swallow_time,
		"nonhuman_prey_swallow_time" = B.nonhuman_prey_swallow_time,
		"digest_brute" = B.digest_brute,
		"digest_burn" = B.digest_burn,
		"digest_oxy" = B.digest_oxy,
		"digest_tox" = B.digest_tox,
		"digest_clone" = B.digest_clone,
		"nutrition_percent" = B.nutrition_percent,
		"item_mode" = B.item_mode,
		"belly_temperature" = B.belly_temperature,
		"temperature_damage" = B.temperature_damage,
		"vore_capacity" = B.vore_capacity,

		"escapable" = B.escapable,
		"escapechance" = B.escapechance,
		"escapetime" = B.escapetime,
		"transferchance" = B.transferchance,
		"transferlocation" = B.transferlocation,
		"absorbchance" = B.absorbchance,
		"digestchance" = B.digestchance,
		"autotransferchance" = B.autotransferchance,
		"autotransferwait" = B.autotransferwait,
		"save_digest_mode" = B.save_digest_mode,
		"eating_privacy" = B.eating_privacy,
		"private_struggle" = B.private_struggle,
		"drain_mode" = B.drain_mode,
		"entrance_logs" = B.entrance_logs,
		"item_digest_logs" = B.item_digest_logs,
		"absorbedrename_enabled" = B.absorbedrename_enabled,
		"absorbedrename_name" = B.absorbedrename_name,
		"belly_fullscreen" = B.belly_fullscreen,
		"fullscreen_color" = B.fullscreen_color,
		"fullscreen_alpha" = B.fullscreen_alpha,
	)

	// Куда можно сбрасывать сопротивляющуюся жертву - остальные по имени
	var/list/transfer_options = list()
	for(var/belly in host.vore_organs)
		var/obj/belly/other = belly
		if(other != B)
			transfer_options |= other.name
	state["transfer_options"] = transfer_options
	state["destination"] = B.destination
	state["show_liquids"] = B.show_liquids
	state["show_liq_fullness"] = B.show_liq_fullness
	state["contaminates"] = B.contaminates
	state["contaminate_color"] = B.contaminate_color
	state["contaminate_flavor"] = B.contaminate_flavor
	state["liquid_reagent"] = B.liquid_reagent
	state["liquid_rate"] = B.liquid_rate
	state["liquid_nutrition"] = B.owner ? round(B.owner.nutrition) : 0

	var/list/liquid_list = list()
	var/liquid_total = 0
	if(B.liquids)
		for(var/datum/reagent/R in B.liquids.reagent_list)
			liquid_list.Add(list(list("name" = R.name, "volume" = round(R.volume, 0.1))))
		liquid_total = round(B.liquids.total_volume, 0.1)
	state["liquids"] = liquid_list
	state["liquid_total"] = liquid_total

	state["messages"] = list(
		"dmp" = B.get_messages("dmp"),
		"dmo" = B.get_messages("dmo"),
		"smo" = B.get_messages("smo"),
		"smi" = B.get_messages("smi"),
		"em" = B.get_messages("em"),
	)

	state["absorbed_messages"] = list(
		"dmp" = B.get_absorbed_messages("dmp"),
		"dmo" = B.get_absorbed_messages("dmo"),
		"smo" = B.get_absorbed_messages("smo"),
		"smi" = B.get_absorbed_messages("smi"),
		"em" = B.get_absorbed_messages("em"),
	)

	var/list/emote_state = list()
	for(var/mode in B.digest_modes)
		emote_state[mode] = B.get_emote_messages(mode)
	state["emote_lists"] = emote_state

	state["contents"] = build_content_list(B)
	return state

/datum/vore_look/ui_data(mob/user)
	var/list/data = list()

	if(!host)
		return data

	data["unsaved_changes"] = unsaved_changes
	data["show_pictures"] = show_pictures
	data["export_text"] = export_text
	var/vore_backup_path
	if(host.client?.prefs?.vr_path)
		vore_backup_path = "[host.client.prefs.vr_path]/character_[host.client.prefs.default_slot]_v2.json.bak"
	data["has_vore_backup"] = vore_backup_path ? fexists(vore_backup_path) : FALSE
	data["limits"] = list(
		"name_min" = BELLIES_NAME_MIN,
		"name_max" = BELLIES_NAME_MAX,
		"desc_max" = BELLIES_DESC_MAX,
		"msg_max" = BELLIES_MSG_MAX,
	)
	data["vore_type_options"] = GLOB.vore_type_options
	data["vore_addon_options"] = GLOB.vore_addon_options
	var/list/liquid_options = list()
	for(var/liquid_name in GLOB.vore_liquid_reagents)
		liquid_options.Add(list(list(
			"name" = liquid_name,
			"path" = "[GLOB.vore_liquid_reagents[liquid_name]]",
		)))
	data["liquid_options"] = liquid_options

	// Секция "Внутри", где мы сейчас находимся
	var/atom/hostloc = host.loc
	var/list/inside = list("ref" = null)
	if(isbelly(hostloc))
		var/obj/belly/inside_belly = hostloc
		inside = list(
			"ref" = "\ref[inside_belly]",
			"pred" = inside_belly.owner?.name || "кто-то",
			"absorbed" = !!(host.vore_flags & ABSORBED),
			"belly_name" = inside_belly.name,
			"display_name" = inside_belly.display_name,
			"belly_mode" = inside_belly.digest_mode,
			"desc" = inside_belly.desc || "Описание отсутствует.",
			"contents" = build_content_list(inside_belly, skip = host),
		)
	data["inside"] = inside

	// Список нутров и выбранный для редактирования
	var/list/our_bellies = list()
	for(var/belly in host.vore_organs)
		var/obj/belly/B = belly
		our_bellies.Add(list(list(
			"ref" = "\ref[B]",
			"name" = B.name,
			"display_name" = B.display_name,
			"digest_mode" = B.digest_mode,
			"contents" = LAZYLEN(B.contents),
			"selected" = (B == host.vore_selected),
			"immutable" = B.immutable,
		)))
	data["our_bellies"] = our_bellies
	data["selected"] = host.vore_selected ? belly_state(host.vore_selected) : null

	data["prefs"] = list(
		"digestable" = (host.vore_flags & DIGESTABLE),
		"devourable" = (host.vore_flags & DEVOURABLE),
		"feeding" = (host.vore_flags & FEEDING),
		"absorbable" = (host.vore_flags & ABSORBABLE),
		"allowmobvore" = (host.vore_flags & MOBVORE),
		"no_healbelly" = (host.vore_flags & NO_HEALBELLY),
		"no_temperature" = (host.vore_flags & NO_TEMPERATURE),
		"no_autotransfer" = (host.vore_flags & NO_AUTOTRANSFER),
		"no_remains" = (host.vore_flags & NO_REMAINS),
		"no_afk_prey" = (host.vore_flags & NO_AFK_PREY),
		"no_afk_pred" = (host.vore_flags & NO_AFK_PRED),
		"eating_privacy_global" = host.eating_privacy_global,
		"vore_sounds" = (host.client?.prefs?.cit_toggles & EATING_NOISES),
		"digestion_sounds" = (host.client?.prefs?.cit_toggles & DIGESTION_NOISES),
	)
	data["vore_taste"] = host.client?.prefs?.vore_taste || ""
	data["vore_smell"] = host.client?.prefs?.vore_smell || ""

	return data

//
// Обработка действий ui_act() и проки-хендлеры.
// Таблица "действие -Ю хендлер"
//

/datum/vore_look/ui_act(action, params)
	if(..())
		return TRUE

	switch(action)
		if("show_pictures")
			show_pictures = !show_pictures
			return TRUE
		if("set_taste")
			if(!host.client?.prefs || !istext(params["text"]))
				return FALSE
			var/new_taste = copytext(params["text"], 1, MAX_TASTE_LEN)
			host.client.prefs.vore_taste = new_taste
			host.taste_desc = new_taste
			unsaved_changes = TRUE
			return TRUE
		if("set_smell")
			if(!host.client?.prefs || !istext(params["text"]))
				return FALSE
			var/new_smell = copytext(params["text"], 1, MAX_TASTE_LEN)
			host.client.prefs.vore_smell = new_smell
			host.smell_desc = new_smell
			unsaved_changes = TRUE
			return TRUE
		if("int_help")
			tgui_alert(usr, "Эти настройки определяют, как ваше нутро реагирует на сопротивление жертвы. Процент шанса каждого события указан ниже; 0% полностью отключает событие. \
					Взаимодействия работают только при включённых взаимодействиях нутра. Помните: смена режима (переваривание/высасывание) затронет всех в нутре, \
					а при одновременном срабатывании нескольких событий первым выполнится ближайшее в списке: побег > перемещение > высасывание > переваривание.", "Справка")
			return TRUE

		// Host is inside someone else, and is trying to interact with something else inside that person.
		if("pick_from_inside")
			return pick_from_inside(usr, params)

		// Host is trying to interact with something in host's belly.
		if("pick_from_outside")
			return pick_from_outside(usr, params)

		if("eject_all")
			return eject_all_act(usr)

		if("move_all")
			return move_all_act(usr)

		if("newbelly")
			if(host.vore_organs.len >= BELLIES_MAX)
				return FALSE

			var/new_name = tgui_input_text(usr,"Имя нового нутра. \nИмя должно быть не меньше [BELLIES_NAME_MIN] символов.","Новое нутро", "", BELLIES_NAME_MAX, FALSE, TRUE)

			var/failure_msg = validate_belly_name(new_name)
			if(failure_msg)
				tgui_alert_async(usr, failure_msg, "Ошибка!")
				return TRUE

			var/obj/belly/NB = new(host)
			NB.name = new_name
			host.vore_selected = NB
			unsaved_changes = TRUE
			return TRUE

		if("bellypick")
			var/obj/belly/picked_belly = locate(params["bellypick"]) in host.vore_organs
			if(picked_belly)
				host.vore_selected = picked_belly
			return TRUE

		if("move_belly")
			var/dir = text2num(params["dir"])
			if(LAZYLEN(host.vore_organs) <= 1)
				to_chat(usr, "<span class='warning'>У вас всего одно нутро - перемещать нечего...</span>")
				return TRUE

			var/current_index = host.vore_organs.Find(host.vore_selected)
			if(current_index)
				var/new_index = clamp(current_index + dir, 1, LAZYLEN(host.vore_organs))
				host.vore_organs.Swap(current_index, new_index)
				unsaved_changes = TRUE
			return TRUE

		if("set_field")
			return set_field(usr, params)

		if("set_messages")
			return set_messages_act(usr, params)

		if("set_absorbed_messages")
			return set_absorbed_messages_act(usr, params)

		if("toggle_type")
			return toggle_type_act(usr, params)

		if("toggle_addon")
			return toggle_addon_act(usr, params)

		if("set_emotes")
			return set_emotes_act(usr, params)

		if("reset_messages")
			return reset_messages_act(usr)

		if("delete_belly")
			return delete_belly_act(usr)

		if("purge_liquids")
			return purge_liquids_act(usr)

		if("export_belly")
			return export_belly_act(usr)

		if("clear_export")
			export_text = null
			return TRUE

		if("import_belly")
			return import_belly_act(usr, params)

		if("test_sound")
			return test_sound_act(usr, params)

		if("saveprefs")
			if(!host.copy_to_prefs_vr())
				tgui_alert_async(usr, "<span class='warning'>Настройки нутров не сохранены!</span>", "Ошибка")
				log_admin("Could not save vore prefs on USER: [usr].")
			else
				to_chat(usr, "<span class='notice'>Настройки нутров сохранены!</span>")
				unsaved_changes = FALSE
			return TRUE
		if("reloadprefs")
			var/alert = tgui_alert(usr, "Вы уверены, что хотите перезагрузить настройки из активного слота персонажа? Текущие нутры будут удалены, а их содержимое выпущено.","Подтверждение",list("Перезагрузить","Отмена"))
			if(alert != "Перезагрузить")
				return FALSE
			if(!host.copy_from_prefs_vr())
				tgui_alert_async(usr, "Ошибка: настройки воре не применились!","Ошибка")
			else
				to_chat(usr, "<span class='notice'>Настройки воре загружены из активного слота!</span>")
				unsaved_changes = FALSE
			return TRUE

		if("internal_loop_refresh")
			return host.preyloop_refresh()

		if("escapeOOC")
			return host.escapeOOC()

		if("restore_vore_backup")
			return restore_vore_backup_act(usr)

		if("toggle_flag")
			return toggle_flag_act(usr, params)

		if("toggle_sound_pref")
			return toggle_sound_pref_act(usr, params)

// Восстановление вор-настроек из последней непустой копии
/datum/vore_look/proc/restore_vore_backup_act(mob/user)
	if(!host.client?.prefs?.vr_path)
		return FALSE
	var/datum/preferences/P = host.client.prefs
	var/backup_path = "[P.vr_path]/character_[P.default_slot]_v2.json.bak"
	if(!fexists(backup_path))
		return FALSE
	var/list/backup_data = json_decode(file2text(backup_path))
	if(!islist(backup_data) || !islist(backup_data["belly_prefs"]) || !length(backup_data["belly_prefs"]))
		return FALSE
	P.belly_prefs = backup_data["belly_prefs"]
	if(!host.copy_from_prefs_vr())
		return FALSE
	P.save_character()
	unsaved_changes = FALSE
	to_chat(user, "<span class='notice'>Вор-настройки восстановлены из резервной копии.</span>")
	return TRUE

// Проверка имени нутра, возвращает строку ошибки или null
/datum/vore_look/proc/validate_belly_name(new_name, obj/belly/ignore)
	if(length(new_name) < BELLIES_NAME_MIN)
		return "Введённое имя нутра слишком короткое (минимальное количество символов [BELLIES_NAME_MIN])."
	for(var/belly in host.vore_organs)
		var/obj/belly/B = belly
		if(B == ignore)
			continue
		if(lowertext(new_name) == lowertext(B.name))
			return "Введённое имя нутра уже существует!"
	return null

/datum/vore_look/proc/toggle_flag_act(mob/user, params)
	var/flag = params["flag"]
	switch(flag)
		if("digestable")
			host.vore_flags ^= DIGESTABLE
			if(host.client?.prefs)
				COPY_SPECIFIC_BITFIELDS(host.client.prefs.vore_flags, host.vore_flags, DIGESTABLE)
		if("devourable")
			host.vore_flags ^= DEVOURABLE
			if(host.client?.prefs)
				COPY_SPECIFIC_BITFIELDS(host.client.prefs.vore_flags, host.vore_flags, DEVOURABLE)
		if("feeding")
			host.vore_flags ^= FEEDING
			if(host.client?.prefs)
				COPY_SPECIFIC_BITFIELDS(host.client.prefs.vore_flags, host.vore_flags, FEEDING)
		if("absorbable")
			host.vore_flags ^= ABSORBABLE
			if(host.client?.prefs)
				COPY_SPECIFIC_BITFIELDS(host.client.prefs.vore_flags, host.vore_flags, ABSORBABLE)
		if("mobvore")
			host.vore_flags ^= MOBVORE
			if(host.client?.prefs)
				COPY_SPECIFIC_BITFIELDS(host.client.prefs.vore_flags, host.vore_flags, MOBVORE)
		if("healbelly")
			host.vore_flags ^= NO_HEALBELLY
			if(host.client?.prefs)
				COPY_SPECIFIC_BITFIELDS(host.client.prefs.vore_flags, host.vore_flags, NO_HEALBELLY)
		if("temperature")
			host.vore_flags ^= NO_TEMPERATURE
			if(host.client?.prefs)
				COPY_SPECIFIC_BITFIELDS(host.client.prefs.vore_flags, host.vore_flags, NO_TEMPERATURE)
		if("autotransfer")
			host.vore_flags ^= NO_AUTOTRANSFER
			if(host.client?.prefs)
				COPY_SPECIFIC_BITFIELDS(host.client.prefs.vore_flags, host.vore_flags, NO_AUTOTRANSFER)
		if("remains")
			host.vore_flags ^= NO_REMAINS
			if(host.client?.prefs)
				COPY_SPECIFIC_BITFIELDS(host.client.prefs.vore_flags, host.vore_flags, NO_REMAINS)
		if("afk_prey")
			host.vore_flags ^= NO_AFK_PREY
			if(host.client?.prefs)
				COPY_SPECIFIC_BITFIELDS(host.client.prefs.vore_flags, host.vore_flags, NO_AFK_PREY)
		if("afk_pred")
			host.vore_flags ^= NO_AFK_PRED
			if(host.client?.prefs)
				COPY_SPECIFIC_BITFIELDS(host.client.prefs.vore_flags, host.vore_flags, NO_AFK_PRED)
		if("privacy")
			host.eating_privacy_global = !host.eating_privacy_global
			if(host.client?.prefs)
				host.client.prefs.eating_privacy_global = host.eating_privacy_global
		else
			return FALSE
	unsaved_changes = TRUE
	return TRUE

/datum/vore_look/proc/toggle_sound_pref_act(mob/user, params)
	if(!host.client?.prefs)
		return FALSE
	switch(params["pref"])
		if("vore_sounds")
			host.client.prefs.cit_toggles ^= EATING_NOISES
		if("digestion_sounds")
			host.client.prefs.cit_toggles ^= DIGESTION_NOISES
		else
			return FALSE
	unsaved_changes = TRUE
	return TRUE

// Инлайн-редактирование поля выбранного нутра.
/datum/vore_look/proc/set_field(mob/user, params)
	if(!host.vore_selected)
		return FALSE

	var/obj/belly/B = host.vore_selected
	var/field = params["field"]
	var/new_value = params["value"]
	var/num_value = isnum(new_value) ? new_value : text2num(new_value)

	var/success = TRUE
	switch(field)
		if("name")
			var/failure_msg = validate_belly_name(new_value, ignore = B)
			if(failure_msg)
				tgui_alert_async(user, failure_msg, "Ошибка!")
				return FALSE
			B.name = new_value
		if("display_name")
			var/trimmed_display = trim(new_value)
			if(length(trimmed_display) > BELLIES_NAME_MAX)
				tgui_alert_async(user, "Слишком длинное отображаемое имя. Предел [BELLIES_NAME_MAX] символов.","Ошибка")
				return FALSE
			B.display_name = length(trimmed_display) ? trimmed_display : null
		if("desc")
			if(length(new_value) > BELLIES_DESC_MAX)
				tgui_alert_async(user, "Слишком длинное описание. Предел [BELLIES_DESC_MAX] символов.","Ошибка")
				return FALSE
			B.desc = new_value ? html_encode_readable(trim(new_value)) : ""
		if("absorbed_desc")
			if(length(new_value) > BELLIES_DESC_MAX)
				tgui_alert_async(user, "Слишком длинное описание. Предел [BELLIES_DESC_MAX] символов.","Ошибка")
				return FALSE
			B.absorbed_desc = new_value ? html_encode_readable(trim(new_value)) : null
		if("vore_verb")
			if(length(new_value) < BELLIES_NAME_MIN)
				tgui_alert_async(user, "Введённый глагол слишком короткий (минимальное количество символов [BELLIES_NAME_MIN])","Ошибка")
				return FALSE
			B.vore_verb = trim(new_value)
		if("release_verb")
			if(length(new_value) < BELLIES_NAME_MIN)
				tgui_alert_async(user, "Введённый глагол освобождения слишком короткий (минимум [BELLIES_NAME_MIN] символа)","Ошибка")
				return FALSE
			B.release_verb = trim(new_value)
		if("digest_mode")
			if(!(new_value in B.digest_modes))
				return FALSE
			B.digest_mode = new_value
		if("vore_sound")
			if(!(new_value in GLOB.pred_vore_sounds))
				return FALSE
			B.vore_sound = new_value
		if("release_sound")
			if(!(new_value in GLOB.pred_release_sounds))
				return FALSE
			B.release_sound = new_value
		if("sound_volume")
			B.sound_volume = clamp(round(num_value), 0, 100)
		if("noise_freq")
			B.noise_freq = clamp(round(num_value), 0, 100000)
		if("transferlocation")
			if(!length(new_value) || new_value == "none")
				B.transferlocation = null
			else
				var/valid = FALSE
				for(var/belly in host.vore_organs)
					var/obj/belly/other = belly
					if(other != B && other.name == new_value)
						valid = TRUE
						break
				if(!valid)
					return FALSE
				B.transferlocation = new_value
		if("destination")
			if(!length(new_value) || new_value == "none")
				B.destination = null
			else
				var/valid_dest = FALSE
				for(var/belly in host.vore_organs)
					var/obj/belly/other = belly
					if(other != B && other.name == new_value)
						valid_dest = TRUE
						break
				if(!valid_dest)
					return FALSE
				B.destination = new_value
		if("show_liquids")
			B.show_liquids = isnull(new_value) ? !B.show_liquids : new_value
		if("show_liq_fullness")
			B.show_liq_fullness = isnull(new_value) ? !B.show_liq_fullness : new_value
		if("contaminates")
			B.contaminates = isnull(new_value) ? !B.contaminates : new_value
			if(B.contaminates)
				for(var/obj/item/I in B.contents)
					I.vore_contaminate(B.contaminate_color, B.contaminate_flavor)
		if("contaminate_color")
			if(length(new_value) == 7 && copytext(new_value, 1, 2) == "#" && isnum(hex2num(copytext(new_value, 2, 8))))
				B.contaminate_color = new_value
			else
				return FALSE
		if("contaminate_flavor")
			if(length(new_value) > 200)
				return FALSE
			B.contaminate_flavor = trim(new_value)
		if("liquid_reagent")
			var/reagent_path = text2path(new_value)
			if(!reagent_path || !(reagent_path in GLOB.chemical_reagents_list))
				return FALSE
			B.liquid_reagent = new_value
		if("liquid_rate")
			B.liquid_rate = clamp(round(num_value), 0, 10)
		if("can_taste")
			B.can_taste = isnull(new_value) ? !B.can_taste : new_value
		if("feedable")
			B.feedable = isnull(new_value) ? !B.feedable : new_value
		if("emote_active")
			B.emote_active = isnull(new_value) ? !B.emote_active : new_value
		if("is_wet")
			B.is_wet = isnull(new_value) ? !B.is_wet : new_value
		if("wet_loop")
			B.wet_loop = isnull(new_value) ? !B.wet_loop : new_value
		if("can_victim_see")
			B.can_victim_see = isnull(new_value) ? !B.can_victim_see : new_value
			for(var/mob/living/L in B.contents)
				B.set_blinding(L)
		if("escapable")
			B.escapable = isnull(new_value) ? !B.escapable : new_value
		if("bulge_size") // UI присылает проценты
			B.bulge_size = clamp(num_value, 0, 200) / 100
		if("escapechance")
			B.escapechance = clamp(num_value, 0, 100)
		if("transferchance")
			B.transferchance = clamp(num_value, 0, 100)
		if("absorbchance")
			B.absorbchance = clamp(num_value, 0, 100)
		if("digestchance")
			B.digestchance = clamp(num_value, 0, 100)
		if("autotransferchance")
			B.autotransferchance = clamp(num_value, 0, 100)
		if("escapetime")
			B.escapetime = clamp(num_value, 1, 600) * 10
		if("autotransferwait")
			B.autotransferwait = clamp(num_value, 1, 600) * 10
		if("emote_time")
			B.emote_time = clamp(num_value, 1, 600) * 10
		if("human_prey_swallow_time")
			B.human_prey_swallow_time = clamp(num_value, 1, 600) * 10
		if("nonhuman_prey_swallow_time")
			B.nonhuman_prey_swallow_time = clamp(num_value, 1, 600) * 10
		if("digest_brute")
			B.digest_brute = clamp(num_value, 0, 50)
		if("digest_burn")
			B.digest_burn = clamp(num_value, 0, 50)
		if("digest_oxy")
			B.digest_oxy = clamp(num_value, 0, 50)
		if("digest_tox")
			B.digest_tox = clamp(num_value, 0, 50)
		if("digest_clone")
			B.digest_clone = clamp(num_value, 0, 50)
		if("nutrition_percent")
			B.nutrition_percent = clamp(num_value, 0, 100)
		if("item_mode")
			if(!(new_value in list("Follow", "Hold", "Digest")))
				return FALSE
			B.item_mode = new_value
		if("belly_temperature") // UI присылает °C
			B.belly_temperature = clamp(num_value, -100, 200) + T0C
		if("temperature_damage")
			B.temperature_damage = isnull(new_value) ? !B.temperature_damage : new_value
		if("save_digest_mode")
			B.save_digest_mode = isnull(new_value) ? !B.save_digest_mode : new_value
		if("eating_privacy")
			if(!(new_value in list("Default", "Subtle", "Loud")))
				return FALSE
			B.eating_privacy = new_value
		if("private_struggle")
			B.private_struggle = isnull(new_value) ? !B.private_struggle : new_value
		if("drain_mode")
			if(!(new_value in list("Absorb", "Release")))
				return FALSE
			B.drain_mode = new_value
		if("entrance_logs")
			B.entrance_logs = isnull(new_value) ? !B.entrance_logs : new_value
		if("item_digest_logs")
			B.item_digest_logs = isnull(new_value) ? !B.item_digest_logs : new_value
		if("absorbedrename_enabled")
			B.absorbedrename_enabled = isnull(new_value) ? !B.absorbedrename_enabled : new_value
		if("absorbedrename_name")
			if(!length(trim(new_value)))
				return FALSE
			B.absorbedrename_name = copytext(trim(new_value), 1, 41)
		if("belly_fullscreen")
			if(new_value == "" || new_value == "none")
				B.belly_fullscreen = null
			else if(new_value in list("dark", "blue", "flesh"))
				B.belly_fullscreen = new_value
			else
				return FALSE
			B.update_fullscreen()
		if("fullscreen_alpha")
			B.fullscreen_alpha = clamp(round(num_value), 0, 255)
			B.update_fullscreen()
		if("fullscreen_color")
			if(!length(new_value) || new_value == "none")
				B.fullscreen_color = null
			else if(length(new_value) == 7 && copytext(new_value, 1, 2) == "#" && isnum(hex2num(copytext(new_value, 2, 8))))
				B.fullscreen_color = new_value
			else
				return FALSE
			B.update_fullscreen()
		if("vore_capacity")
			B.vore_capacity = clamp(round(num_value), 1, 10)
		else
			success = FALSE

	if(success)
		unsaved_changes = TRUE
	return success

/datum/vore_look/proc/set_messages_act(mob/user, params)
	if(!host.vore_selected)
		return FALSE
	var/msgtype = params["msgtype"]
	if(msgtype != "dmp" && msgtype != "dmo" && msgtype != "smo" && msgtype != "smi" && msgtype != "em")
		return FALSE
	if(!istext(params["text"]))
		return FALSE
	host.vore_selected.set_messages(params["text"], msgtype)
	unsaved_changes = TRUE
	return TRUE

/datum/vore_look/proc/toggle_type_act(mob/user, params)
	if(!host.vore_selected)
		return FALSE
	var/vtype = params["type"]
	if(!(vtype in GLOB.vore_type_options))
		return FALSE
	var/obj/belly/B = host.vore_selected
	if(vtype in B.vore_types)
		B.vore_types -= vtype
	else
		B.vore_types += vtype
	unsaved_changes = TRUE
	return TRUE

/datum/vore_look/proc/toggle_addon_act(mob/user, params)
	if(!host.vore_selected)
		return FALSE
	var/addon = params["addon"]
	if(!(addon in GLOB.vore_addon_options))
		return FALSE
	var/obj/belly/B = host.vore_selected
	if(addon in B.mode_addons)
		B.mode_addons -= addon
	else
		B.mode_addons += addon
	unsaved_changes = TRUE
	return TRUE

/datum/vore_look/proc/set_emotes_act(mob/user, params)
	if(!host.vore_selected)
		return FALSE
	var/obj/belly/B = host.vore_selected
	var/mode = params["mode"]
	if(!(mode in B.digest_modes))
		return FALSE
	if(!istext(params["text"]))
		return FALSE
	B.set_emote_messages(params["text"], mode)
	unsaved_changes = TRUE
	return TRUE

/datum/vore_look/proc/set_absorbed_messages_act(mob/user, params)
	if(!host.vore_selected)
		return FALSE
	var/msgtype = params["msgtype"]
	if(msgtype != "dmp" && msgtype != "dmo" && msgtype != "smo" && msgtype != "smi" && msgtype != "em")
		return FALSE
	if(!istext(params["text"]))
		return FALSE
	host.vore_selected.set_absorbed_messages(params["text"], msgtype)
	unsaved_changes = TRUE
	return TRUE

/datum/vore_look/proc/reset_messages_act(mob/user)
	if(!host.vore_selected)
		return FALSE
	var/obj/belly/B = host.vore_selected
	B.digest_messages_prey = initial(B.digest_messages_prey)
	B.digest_messages_owner = initial(B.digest_messages_owner)
	B.struggle_messages_outside = initial(B.struggle_messages_outside)
	B.struggle_messages_inside = initial(B.struggle_messages_inside)
	B.examine_messages = initial(B.examine_messages)
	B.emote_lists = initial(B.emote_lists)
	B.absorbed_messages.Cut()
	unsaved_changes = TRUE
	return TRUE

/datum/vore_look/proc/delete_belly_act(mob/user)
	if(!host.vore_selected)
		return FALSE

	var/failure_msg = ""

	var/dest_for
	for(var/belly in host.vore_organs)
		var/obj/belly/B = belly
		if(B.transferlocation == host.vore_selected.name)
			dest_for = B.name
			failure_msg += "Это нутро указано как место перемещения для '[dest_for]'. Сначала уберите его оттуда. "
			break

	if(host.vore_selected.contents.len)
		failure_msg += "Нельзя удалить нутро с содержимым! "
	if(host.vore_selected.immutable)
		failure_msg += "Это нутро помечено как неудаляемый. "
	if(host.vore_organs.len == 1)
		failure_msg += "У вас должно остаться хотя бы одно нутро. "

	if(failure_msg)
		tgui_alert_async(user,failure_msg,"Ошибка!")
		return FALSE

	qdel(host.vore_selected)
	host.vore_selected = host.vore_organs[1]
	unsaved_changes = TRUE
	return TRUE

/datum/vore_look/proc/export_belly_act(mob/user)
	if(!host.vore_selected)
		return FALSE
	var/obj/belly/B = host.vore_selected

	var/list/exported = list(
		"name" = B.name,
		"display_name" = B.display_name,
		"vore_types" = B.vore_types,
		"mode_addons" = B.mode_addons,
		"desc" = B.desc,
		"absorbed_desc" = B.absorbed_desc,
		"digest_mode" = B.digest_mode,
		"vore_verb" = B.vore_verb,
		"release_verb" = B.release_verb,
		"vore_sound" = B.vore_sound,
		"release_sound" = B.release_sound,
		"sound_volume" = B.sound_volume,
		"noise_freq" = B.noise_freq,
		"can_taste" = B.can_taste,
		"feedable" = B.feedable,
		"is_wet" = B.is_wet,
		"wet_loop" = B.wet_loop,
		"can_victim_see" = B.can_victim_see,
		"bulge_size" = B.bulge_size,
		"emote_time" = B.emote_time,
		"emote_active" = B.emote_active,
		"human_prey_swallow_time" = B.human_prey_swallow_time,
		"nonhuman_prey_swallow_time" = B.nonhuman_prey_swallow_time,
		"digest_brute" = B.digest_brute,
		"digest_burn" = B.digest_burn,
		"digest_oxy" = B.digest_oxy,
		"digest_tox" = B.digest_tox,
		"digest_clone" = B.digest_clone,
		"nutrition_percent" = B.nutrition_percent,
		"item_mode" = B.item_mode,
		"belly_temperature" = B.belly_temperature,
		"temperature_damage" = B.temperature_damage,
		"vore_capacity" = B.vore_capacity,
		"escapable" = B.escapable,
		"escapechance" = B.escapechance,
		"escapetime" = B.escapetime,
		"transferchance" = B.transferchance,
		"transferlocation" = B.transferlocation,
		"destination" = B.destination,
		"absorbchance" = B.absorbchance,
		"digestchance" = B.digestchance,
		"autotransferchance" = B.autotransferchance,
		"autotransferwait" = B.autotransferwait,
		"save_digest_mode" = B.save_digest_mode,
		"eating_privacy" = B.eating_privacy,
		"private_struggle" = B.private_struggle,
		"drain_mode" = B.drain_mode,
		"entrance_logs" = B.entrance_logs,
		"item_digest_logs" = B.item_digest_logs,
		"absorbedrename_enabled" = B.absorbedrename_enabled,
		"absorbedrename_name" = B.absorbedrename_name,
		"belly_fullscreen" = B.belly_fullscreen,
		"fullscreen_color" = B.fullscreen_color,
		"fullscreen_alpha" = B.fullscreen_alpha,
		"show_liquids" = B.show_liquids,
		"show_liq_fullness" = B.show_liq_fullness,
		"contaminates" = B.contaminates,
		"contaminate_color" = B.contaminate_color,
		"contaminate_flavor" = B.contaminate_flavor,
		"liquid_reagent" = B.liquid_reagent,
		"liquid_rate" = B.liquid_rate,
		"messages" = list(
			"dmp" = B.get_messages("dmp"),
			"dmo" = B.get_messages("dmo"),
			"smo" = B.get_messages("smo"),
			"smi" = B.get_messages("smi"),
			"em" = B.get_messages("em"),
		),
		"absorbed_messages" = list(
			"dmp" = B.get_absorbed_messages("dmp"),
			"dmo" = B.get_absorbed_messages("dmo"),
			"smo" = B.get_absorbed_messages("smo"),
			"smi" = B.get_absorbed_messages("smi"),
			"em" = B.get_absorbed_messages("em"),
		),
	)

	export_text = json_encode(exported)
	return TRUE

/datum/vore_look/proc/import_num(var/list/data, var/key, var/default, var/min_value, var/max_value)
	var/value = data[key]
	if(!isnum(value))
		return default
	return clamp(value, min_value, max_value)

/datum/vore_look/proc/import_belly_act(mob/user, params)
	var/limit = BELLIES_MAX
	if(LAZYLEN(host.vore_organs) >= limit)
		tgui_alert_async(user, "Достигнут лимит нутров ([limit]).", "Импорт")
		return FALSE

	var/raw = params["text"]
	if(!istext(raw) || !length(raw))
		tgui_alert_async(user, "Пустой текст импорта.", "Импорт")
		return FALSE
	if(length(raw) > 20000)
		tgui_alert_async(user, "Слишком большой JSON: предел 20000 символов.", "Импорт")
		return FALSE

	var/list/data = json_decode(raw)
	if(!islist(data))
		tgui_alert_async(user, "Не удалось разобрать JSON. Скопируй его из экспорта целиком.", "Импорт")
		return FALSE

	var/obj/belly/B = new(host)

	var/new_name = data["name"]
	if(!istext(new_name) || validate_belly_name(new_name, ignore = B))
		new_name = "Импорт [LAZYLEN(host.vore_organs)]"
	B.name = copytext(new_name, 1, BELLIES_NAME_MAX + 1)

	if(istext(data["display_name"]))
		B.display_name = copytext(trim(data["display_name"]), 1, BELLIES_NAME_MAX + 1)
	if(istext(data["desc"]))
		B.desc = html_encode_readable(html_decode(copytext(trim(data["desc"]), 1, BELLIES_DESC_MAX + 1)))
	if(istext(data["absorbed_desc"]))
		B.absorbed_desc = length(trim(data["absorbed_desc"])) ? html_encode_readable(html_decode(copytext(trim(data["absorbed_desc"]), 1, BELLIES_DESC_MAX + 1))) : null
	if(islist(data["vore_types"]))
		B.vore_types = list()
		for(var/vtype in data["vore_types"])
			if(vtype in GLOB.vore_type_options)
				B.vore_types |= vtype
	if(islist(data["mode_addons"]))
		B.mode_addons = list()
		for(var/addon in data["mode_addons"])
			if(addon in GLOB.vore_addon_options)
				B.mode_addons |= addon
	if(istext(data["vore_verb"]) && length(data["vore_verb"]) >= BELLIES_NAME_MIN)
		B.vore_verb = copytext(data["vore_verb"], 1, BELLIES_NAME_MAX + 1)
	if(istext(data["release_verb"]) && length(data["release_verb"]) >= BELLIES_NAME_MIN)
		B.release_verb = copytext(data["release_verb"], 1, BELLIES_NAME_MAX + 1)
	if(data["digest_mode"] in B.digest_modes)
		B.digest_mode = data["digest_mode"]
	if(data["vore_sound"] in GLOB.pred_vore_sounds)
		B.vore_sound = data["vore_sound"]
	if(data["release_sound"] in GLOB.pred_release_sounds)
		B.release_sound = data["release_sound"]

	if(data["item_mode"] in list("Follow", "Hold", "Digest"))
		B.item_mode = data["item_mode"]
	if(!isnull(data["can_taste"]))
		B.can_taste = data["can_taste"] ? TRUE : FALSE
	if(!isnull(data["feedable"]))
		B.feedable = data["feedable"] ? TRUE : FALSE
	if(!isnull(data["is_wet"]))
		B.is_wet = data["is_wet"] ? TRUE : FALSE
	if(!isnull(data["wet_loop"]))
		B.wet_loop = data["wet_loop"] ? TRUE : FALSE
	if(!isnull(data["can_victim_see"]))
		B.can_victim_see = data["can_victim_see"] ? TRUE : FALSE
	if(!isnull(data["emote_active"]))
		B.emote_active = data["emote_active"] ? TRUE : FALSE
	if(!isnull(data["escapable"]))
		B.escapable = data["escapable"] ? TRUE : FALSE
	if(!isnull(data["save_digest_mode"]))
		B.save_digest_mode = data["save_digest_mode"] ? TRUE : FALSE
	if(istext(data["eating_privacy"]) && (data["eating_privacy"] in list("Default", "Subtle", "Loud")))
		B.eating_privacy = data["eating_privacy"]
	if(!isnull(data["private_struggle"]))
		B.private_struggle = data["private_struggle"] ? TRUE : FALSE
	if(istext(data["drain_mode"]) && (data["drain_mode"] in list("Absorb", "Release")))
		B.drain_mode = data["drain_mode"]
	if(!isnull(data["entrance_logs"]))
		B.entrance_logs = data["entrance_logs"] ? TRUE : FALSE
	if(!isnull(data["item_digest_logs"]))
		B.item_digest_logs = data["item_digest_logs"] ? TRUE : FALSE
	if(!isnull(data["absorbedrename_enabled"]))
		B.absorbedrename_enabled = data["absorbedrename_enabled"] ? TRUE : FALSE
	if(istext(data["absorbedrename_name"]) && length(trim(data["absorbedrename_name"])))
		B.absorbedrename_name = copytext(trim(data["absorbedrename_name"]), 1, 41)
	if(!isnull(data["temperature_damage"]))
		B.temperature_damage = data["temperature_damage"] ? TRUE : FALSE
	if(!isnull(data["show_liquids"]))
		B.show_liquids = data["show_liquids"] ? TRUE : FALSE
	if(!isnull(data["show_liq_fullness"]))
		B.show_liq_fullness = data["show_liq_fullness"] ? TRUE : FALSE
	if(!isnull(data["contaminates"]))
		B.contaminates = data["contaminates"] ? TRUE : FALSE
	if(istext(data["contaminate_color"]) && length(data["contaminate_color"]) == 7 && copytext(data["contaminate_color"], 1, 2) == "#")
		B.contaminate_color = data["contaminate_color"]
	if(istext(data["contaminate_flavor"]))
		B.contaminate_flavor = copytext(data["contaminate_flavor"], 1, 201)
	if(istext(data["liquid_reagent"]))
		var/import_reagent = text2path(data["liquid_reagent"])
		if(import_reagent && (import_reagent in GLOB.chemical_reagents_list))
			B.liquid_reagent = data["liquid_reagent"]
	B.liquid_rate = round(import_num(data, "liquid_rate", B.liquid_rate, 0, 10))
	if(istext(data["belly_fullscreen"]) && (data["belly_fullscreen"] in list("dark", "blue", "flesh")))
		B.belly_fullscreen = data["belly_fullscreen"]
	if(istext(data["fullscreen_color"]) && length(data["fullscreen_color"]) == 7 && copytext(data["fullscreen_color"], 1, 2) == "#")
		B.fullscreen_color = data["fullscreen_color"]

	B.sound_volume = import_num(data, "sound_volume", B.sound_volume, 0, 100)
	B.noise_freq = import_num(data, "noise_freq", B.noise_freq, 0, 100000)
	B.bulge_size = import_num(data, "bulge_size", B.bulge_size, 0, 2)
	B.emote_time = import_num(data, "emote_time", B.emote_time, 50, 6000)
	B.human_prey_swallow_time = import_num(data, "human_prey_swallow_time", B.human_prey_swallow_time, 10, 6000)
	B.nonhuman_prey_swallow_time = import_num(data, "nonhuman_prey_swallow_time", B.nonhuman_prey_swallow_time, 10, 6000)
	B.digest_brute = import_num(data, "digest_brute", B.digest_brute, 0, 50)
	B.digest_burn = import_num(data, "digest_burn", B.digest_burn, 0, 50)
	B.digest_oxy = import_num(data, "digest_oxy", B.digest_oxy, 0, 50)
	B.digest_tox = import_num(data, "digest_tox", B.digest_tox, 0, 50)
	B.digest_clone = import_num(data, "digest_clone", B.digest_clone, 0, 50)
	B.nutrition_percent = import_num(data, "nutrition_percent", B.nutrition_percent, 0, 100)
	B.belly_temperature = import_num(data, "belly_temperature", B.belly_temperature, 173.15, 473.15)
	B.fullscreen_alpha = round(import_num(data, "fullscreen_alpha", B.fullscreen_alpha, 0, 255))
	B.vore_capacity = round(import_num(data, "vore_capacity", B.vore_capacity, 1, 10))
	B.escapechance = import_num(data, "escapechance", B.escapechance, 0, 100)
	B.escapetime = import_num(data, "escapetime", B.escapetime, 10, 6000)
	B.transferchance = import_num(data, "transferchance", B.transferchance, 0, 100)
	B.absorbchance = import_num(data, "absorbchance", B.absorbchance, 0, 100)
	B.digestchance = import_num(data, "digestchance", B.digestchance, 0, 100)
	B.autotransferchance = import_num(data, "autotransferchance", B.autotransferchance, 0, 100)
	B.autotransferwait = import_num(data, "autotransferwait", B.autotransferwait, 10, 6000)

	var/dest = data["transferlocation"]
	if(istext(dest))
		for(var/belly in host.vore_organs)
			var/obj/belly/other = belly
			if(other != B && other.name == dest)
				B.transferlocation = dest
				break

	var/import_dest = data["destination"]
	if(istext(import_dest))
		for(var/belly in host.vore_organs)
			var/obj/belly/other = belly
			if(other != B && other.name == import_dest)
				B.destination = import_dest
				break

	var/list/imported_messages = data["messages"]
	if(islist(imported_messages))
		for(var/msgtype in list("dmp", "dmo", "smo", "smi", "em"))
			if(istext(imported_messages[msgtype]))
				B.set_messages(imported_messages[msgtype], msgtype)

	var/list/imported_absorbed = data["absorbed_messages"]
	if(islist(imported_absorbed))
		for(var/msgtype in list("dmp", "dmo", "smo", "smi", "em"))
			if(istext(imported_absorbed[msgtype]))
				B.set_absorbed_messages(imported_absorbed[msgtype], msgtype)

	host.vore_selected = B
	export_text = null
	unsaved_changes = TRUE
	return TRUE

/datum/vore_look/proc/purge_liquids_act(mob/user)
	if(!host.vore_selected || !host.vore_selected.liquids)
		return FALSE
	host.vore_selected.liquids.clear_reagents()
	return TRUE

/datum/vore_look/proc/eject_all_act(mob/user)
	if(!host.vore_selected || !LAZYLEN(host.vore_selected.contents))
		return FALSE
	if(host.stat)
		to_chat(user, span_warning("Вы не в том состоянии, чтобы это делать!"))
		return TRUE
	host.vore_selected.release_all_contents()
	return TRUE

/datum/vore_look/proc/move_all_act(mob/user)
	if(!host.vore_selected || !host.vore_selected.destination)
		return FALSE
	if(host.stat)
		to_chat(user, span_warning("Вы не в том состоянии, чтобы это делать!"))
		return TRUE

	var/obj/belly/dest
	for(var/belly in host.vore_organs)
		var/obj/belly/other = belly
		if(other.name == host.vore_selected.destination)
			dest = other
			break
	if(!dest)
		host.vore_selected.destination = null
		tgui_alert_async(user, "Нутро-назначение больше не существует. Выберите другое.", "Ошибка")
		return FALSE

	var/first = TRUE
	for(var/atom/movable/AM in host.vore_selected.contents.Copy())
		host.vore_selected.transfer_contents(AM, dest, !first)
		first = FALSE
	return TRUE

/datum/vore_look/proc/test_sound_act(mob/user, params)
	if(!host.vore_selected)
		return FALSE
	var/sound/test
	switch(params["which"])
		if("vore")
			test = GLOB.pred_vore_sounds[host.vore_selected.vore_sound]
		if("release")
			test = GLOB.pred_release_sounds[host.vore_selected.release_sound]
	if(test)
		SEND_SOUND(user, test)
	return FALSE // Тест звука ничего не меняет

//
// Взаимодействие с содержимым попап-меню pick_from_*
// (Осмотреть / выпустить / переместить и т.п.)
//

/datum/vore_look/proc/pick_from_inside(mob/user, params)
	var/atom/movable/target = locate(params["pick"])
	var/obj/belly/OB = locate(params["belly"])

	if(!istype(OB) || user.loc != OB || !(target in OB))
		return TRUE // Aren't here anymore, need to update menu

	var/intent = "Осмотреть"
	if(ismob(target))
		intent = tgui_alert(usr, "Что вы хотите сделать?","Действие",list("Осмотреть","Помочь выбраться","Съесть"))

	else if(istype(target, /obj/item))
		intent = tgui_alert(usr, "Что вы хотите сделать?","Действие",list("Осмотреть","Использовать руками"))

	switch(intent)
		if("Осмотреть") //Examine a mob inside another mob
			host.examinate(target)
			return TRUE

		if("Использовать как руками")
			if(host.stat)
				to_chat(user, "<span class='warning'>Вы не в том состоянии, чтобы это делать!</span>")
				return TRUE

			host.ClickOn(target)
			return TRUE

	if(!isliving(target))
		return

	var/mob/living/M = target
	switch(intent)
		if("Помочь выбраться") //Help the inside-mob out
			if(host.stat || host.vore_flags & ABSORBED || M.vore_flags & ABSORBED)
				to_chat(user, "<span class='warning'>Вы не в том состоянии, чтобы это делать!</span>")
				return TRUE

			to_chat(user,"<font color='green'>Вы начинаете выталкивать [M] наружу!</font>")
			to_chat(M,"[host] начинает выталкивать вас наружу!")
			to_chat(M.loc,"<span class='warning'>Кто-то пытается выбраться из вас!</span>")
			sleep(50)
			if(prob(33))
				OB.release_specific_contents(M)
				to_chat(user,"<font color='green'>Вам удалось помочь [M] выбраться!</font>")
				to_chat(M,"<font color='green'>[host] выталкивает вас наружу!</font>")
				to_chat(OB.owner,"<span class='alert'>[M] с боем пробирается наружу из вашего тела!</span>")
			else
				to_chat(user,"<span class='alert'>[M] соскальзывает обратно, несмотря на ваши усилия.</span>")
				to_chat(M,"<span class='alert'> Даже с помощью [host] вы снова соскальзываете внутрь.</span>")
				to_chat(OB.owner,"<font color='green'>Ваше тело ловко отправляет [M] обратно на место.</font>")
			return TRUE

		if("Съесть") //Eat the inside mob
			if(host.stat || host.vore_flags & ABSORBED)
				to_chat(user,"<span class='warning'>Вы не в том состоянии, чтобы это делать!</span>")
				return TRUE

			if(!host.vore_selected)
				to_chat(user,"<span class='warning'>Сначала выберите нутро на себе!</span>")
				return TRUE

			var/obj/belly/TB = host.vore_selected
			if((host.vore_flags & ABSORBED) && !("Absorbed Prey Can Devour" in TB.mode_addons))
				to_chat(user, span_warning("Поглощённая добыча не может есть других без дополнения режима «Absorbed Prey Can Devour»."))
				return TRUE
			to_chat(user,"<span class='warning'>Вы начинаете [lowertext(TB.vore_verb)] [M] в свой [lowertext(TB.name)]!</span>")
			to_chat(M,"<span class='warning'>[host] начинает [lowertext(TB.vore_verb)] вас в свой [lowertext(TB.name)]!</span>")
			to_chat(OB.owner,"<span class='warning'>Кто-то у вас внутри кого-то ест!</span>")

			sleep(TB.nonhuman_prey_swallow_time) //Can't do after, in a stomach, weird things abound.
			if((host in OB) && (M in OB)) //Make sure they're still here.
				to_chat(user,"<span class='warning'>Вам удалось [lowertext(TB.vore_verb)] [M] в свой [lowertext(TB.name)]!</span>")
				to_chat(M,"<span class='warning'>[host] сумел(а) [lowertext(TB.vore_verb)] вас в свой [lowertext(TB.name)]!</span>")
				to_chat(OB.owner,"<span class='warning'>Кто-то у вас внутри кого-то съел!</span>")
				TB.nom_mob(M)

/datum/vore_look/proc/pick_from_outside(mob/user, params)
	var/intent

	//Handle the [All] choice. Ugh inelegant. Someone make this pretty.
	if(params["pickall"])
		intent = tgui_alert(usr, "Выпустить всех, переместить всех?","Действие",list("Выпустить всех","Отмена","Переместить всех"))
		switch(intent)
			if("Отмена")
				return TRUE

			if("Выпустить всех")
				if(host.stat)
					to_chat(user,"<span class='warning'>Вы не в том состоянии, чтобы это делать!</span>")
					return TRUE

				host.vore_selected.release_all_contents()
				return TRUE

			if("Переместить всех")
				if(host.stat)
					to_chat(user,"<span class='warning'>Вы не в том состоянии, чтобы это делать!</span>")
					return TRUE

				var/obj/belly/choice = tgui_input_list(usr, "Куда переместить всех?","Выбор нутра", host.vore_organs)
				if(!choice)
					return FALSE

				for(var/atom/movable/target in host.vore_selected)
					to_chat(target,"<span class='warning'>Вас перемещает из [lowertext(host.vore_selected.name)] [host] в [lowertext(choice.name)]!</span>")
					host.vore_selected.transfer_contents(target, choice, 1)
				return TRUE
		return

	var/atom/movable/target = locate(params["pick"])
	if(!(target in host.vore_selected))
		return TRUE // Not in our X anymore, update UI
	var/list/available_options = list("Осмотреть", "Выпустить", "Переместить")
	intent = tgui_alert(user, "Что вы хотите сделать с [target]?", "Действие", available_options)
	switch(intent)
		if("Осмотреть")
			host.examinate(target)
			return TRUE

		if("Выпустить")
			if(host.stat)
				to_chat(user,"<span class='warning'>Вы не в том состоянии, чтобы это делать!</span>")
				return TRUE

			host.vore_selected.release_specific_contents(target)
			return TRUE

		if("Переместить")
			if(host.stat)
				to_chat(user,"<span class='warning'>Вы не в том состоянии, чтобы это делать!</span>")
				return TRUE

			var/obj/belly/choice = tgui_input_list(usr, "Куда переместить [target]?","Выбор нутра", host.vore_organs)
			if(!choice || !(target in host.vore_selected))
				return TRUE

			to_chat(target,"<span class='warning'>Вас перемещает из [lowertext(host.vore_selected.name)] [host] в [lowertext(choice.name)]!</span>")
			host.vore_selected.transfer_contents(target, choice)
			return TRUE
