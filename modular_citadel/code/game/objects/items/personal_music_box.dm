/// Личная музыкальная шкатулка из спонсорского лоадаута: игрок заливает свои .ogg и играет их рядом с собой.

/// Сколько треков игрок может залить за раунд. Это же размер его библиотеки.
#define PERSONAL_MUSIC_BOX_MAX_UPLOADS_PER_ROUND 10
/// Пауза между заливками одного игрока
#define PERSONAL_MUSIC_BOX_PLAYER_UPLOAD_COOLDOWN (1 MINUTES)
/// Пауза между заливками на весь сервер
#define PERSONAL_MUSIC_BOX_UPLOAD_COOLDOWN (30 SECONDS)
/// Пауза между запусками любых шкатулок на сервере
#define PERSONAL_MUSIC_BOX_PLAY_COOLDOWN (10 SECONDS)
/// Потолок длины трека на случай, если заголовок файла врёт
#define PERSONAL_MUSIC_BOX_MAX_TRACK_LENGTH (20 MINUTES)
#define PERSONAL_MUSIC_BOX_MAX_TRACK_NAME_LEN 64
#define PERSONAL_MUSIC_BOX_TRACK_BEAT 50
#define PERSONAL_MUSIC_BOX_DEFAULT_VOLUME 100
/// Страховка флага открытого диалога: рантайм или обрыв связи во время input() не дают снять его штатно
#define PERSONAL_MUSIC_BOX_UPLOAD_LOCK_TIMEOUT (5 MINUTES)

GLOBAL_VAR_INIT(personal_music_boxes_last_upload, 0)
GLOBAL_VAR_INIT(personal_music_boxes_last_play, 0)
/// ckey -> world.time последней заливки. Кулдаун на игроке, а не на шкатулке, иначе его обходят второй шкатулкой.
GLOBAL_LIST_EMPTY(personal_music_boxes_last_player_upload)
/// ckey -> залитые за раунд треки, list("path", "name", "length", "duration").
/// Файлы лежат в PERSONAL_MUSIC_BOX_UPLOAD_DIR до конца раунда: библиотека переживает шкатулку.
GLOBAL_LIST_EMPTY(personal_music_boxes_library)
/// ckey тех, у кого прямо сейчас открыт диалог выбора файла
GLOBAL_LIST_EMPTY(personal_music_boxes_uploading)

/datum/component/jukebox/personal_music_box
	dupe_type = /datum/component/jukebox/personal_music_box
	var/datum/track/custom_track

/datum/component/jukebox/personal_music_box/Initialize(_volume, _on_music_toggle)
	. = ..(FALSE, PRICE_FREE, _volume, _on_music_toggle)
	if(. == COMPONENT_INCOMPATIBLE)
		return
	repeat = TRUE
	UnregisterSignal(parent, COMSIG_ITEM_ATTACK_SELF)

/datum/component/jukebox/personal_music_box/Destroy()
	clear_custom_track()
	return ..()

/datum/component/jukebox/personal_music_box/ui_status(mob/user)
	return UI_CLOSE

/datum/component/jukebox/personal_music_box/proc/set_custom_track(track_path, track_name, track_length)
	clear_custom_track()
	if(!track_path)
		return
	if(!isnum(track_length) || track_length <= 0)
		track_length = PERSONAL_MUSIC_BOX_MAX_TRACK_LENGTH
	custom_track = new(track_name, file(track_path), track_length, PERSONAL_MUSIC_BOX_TRACK_BEAT, "personal_[REF(parent)]")

/datum/component/jukebox/personal_music_box/proc/clear_custom_track()
	var/datum/track/old_track = custom_track
	if(!old_track)
		return
	custom_track = null
	queuedplaylist -= old_track
	if(selectedtrack == old_track)
		selectedtrack = null
	if(playing == old_track)
		dance_over()
		active = FALSE
		playing = null
	qdel(old_track)

/// Трек доигрывает до ближайшего process() компонента, там же шкатулка гаснет через on_music_toggle
/datum/component/jukebox/personal_music_box/proc/stop_playback()
	if(!active && !playing)
		return
	stop = 0

/datum/component/jukebox/personal_music_box/activate_music()
	if(playing || !length(queuedplaylist))
		return FALSE
	if(!length(SSjukeboxes.freejukeboxchannels) || !check_area(TRUE))
		return FALSE
	playing = queuedplaylist[1]
	if(!SSjukeboxes.addjukebox(parent, playing, volume / JUKEBOX_VOLUME_TO_FALLOFF, personal = TRUE))
		playing = null
		return FALSE
	active = TRUE
	START_PROCESSING(SSobj, src)
	stop = world.time + playing.song_length
	if(repeat)
		queuedplaylist += queuedplaylist[1]
	queuedplaylist.Cut(1, 2)
	on_music_toggle?.Invoke(TRUE)
	return TRUE

/obj/item/personal_music_box
	name = "personal music box"
	desc = "A portable music box. You can load your own .ogg tracks from your computer and play them nearby."
	icon = 'modular_citadel/icons/obj/personal_music_box.dmi'
	righthand_file = 'modular_citadel/icons/obj/boombox_righthand.dmi'
	lefthand_file = 'modular_citadel/icons/obj/boombox_lefthand.dmi'
	icon_state = "mbox0"
	item_state = "mbox0"
	verb_say = "states"
	/// Файл текущего трека на диске сервера
	var/curfile_path
	var/song_name

/obj/item/personal_music_box/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/jukebox/personal_music_box, PERSONAL_MUSIC_BOX_DEFAULT_VOLUME, CALLBACK(src, PROC_REF(on_music_toggle)))

/obj/item/personal_music_box/proc/get_jukebox_component()
	return GetComponent(/datum/component/jukebox/personal_music_box)

/obj/item/personal_music_box/proc/is_playing()
	var/datum/component/jukebox/personal_music_box/jukebox = get_jukebox_component()
	return jukebox?.active

/obj/item/personal_music_box/proc/on_music_toggle(active)
	update_icon()

/obj/item/personal_music_box/update_icon_state()
	. = ..()
	icon_state = is_playing() ? "mboxon" : (curfile_path ? "mbox1" : "mbox0")
	if(item_state == icon_state)
		return
	item_state = icon_state
	if(ismob(loc))
		var/mob/holder = loc
		holder.update_inv_hands()

/obj/item/personal_music_box/examine(mob/user)
	. = ..()
	. += span_notice("Нажмите на шкатулку, чтобы открыть меню.")
	if(curfile_path)
		. += span_notice("Загружен трек: [song_name].")

/obj/item/personal_music_box/attack_self(mob/user)
	. = ..()
	if(.)
		return
	if(!isliving(user))
		return
	user.DelayNextAction(CLICK_CD_MELEE)
	ui_interact(user)

/obj/item/personal_music_box/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PersonalMusicBox", name)
		ui.open()

/obj/item/personal_music_box/ui_data(mob/user)
	var/datum/component/jukebox/personal_music_box/jukebox = get_jukebox_component()
	var/upload_block_reason = get_upload_block_reason(user)
	var/play_block_reason = get_play_block_reason()
	var/list/data = list()
	data["playing"] = !!jukebox?.active
	data["repeat"] = !!jukebox?.repeat
	data["has_track"] = !!curfile_path
	data["track_name"] = song_name
	data["track_duration"] = jukebox?.custom_track ? DisplayTimeText(jukebox.custom_track.song_length) : null
	data["volume"] = jukebox ? jukebox.volume : PERSONAL_MUSIC_BOX_DEFAULT_VOLUME
	data["in_hand"] = loc == user
	data["upload_ready"] = isnull(upload_block_reason)
	data["upload_block_reason"] = upload_block_reason
	data["play_ready"] = isnull(play_block_reason)
	data["play_block_reason"] = play_block_reason

	var/list/library = user?.ckey ? GLOB.personal_music_boxes_library[user.ckey] : null
	var/list/library_data = list()
	for(var/index in 1 to length(library))
		var/list/entry = library[index]
		library_data += list(list(
			"index" = index,
			"name" = entry["name"],
			"duration" = entry["duration"],
			"current" = entry["path"] == curfile_path,
		))
	data["library"] = library_data
	data["uploads_max"] = PERSONAL_MUSIC_BOX_MAX_UPLOADS_PER_ROUND
	return data

/obj/item/personal_music_box/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!isliving(usr))
		return
	var/mob/living/living_user = usr
	switch(action)
		if("toggle")
			toggle_playback(living_user)
			return TRUE
		if("repeat")
			return toggle_repeat()
		if("select_track")
			return select_library_track(living_user, text2num(params["index"]))
		if("upload")
			var/block_reason = get_upload_block_reason(living_user)
			if(block_reason)
				to_chat(living_user, span_warning(block_reason))
				return
			playsound(loc, 'sound/machines/ping.ogg', 50, FALSE)
			INVOKE_ASYNC(src, PROC_REF(upload_file), living_user)
			return TRUE
		if("set_volume")
			var/datum/component/jukebox/personal_music_box/jukebox = get_jukebox_component()
			return jukebox?.set_volume(params["volume"])

/**
 * Причина отказа в заливке трека, либо null, если заливать можно.
 *
 * ignore_own_lock нужен повторной сверке в do_upload_file(): флаг открытого диалога там стоит свой собственный.
 */
/obj/item/personal_music_box/proc/get_upload_block_reason(mob/user, ignore_own_lock = FALSE)
	if(is_playing())
		return "Сначала выключите шкатулку."
	if(loc != user)
		return "Шкатулка должна быть в руках."
	if(!user?.ckey)
		return "Некому загружать трек."
	if(!ignore_own_lock && GLOB.personal_music_boxes_uploading[user.ckey])
		return "У вас уже открыт диалог выбора файла."
	if(length(GLOB.personal_music_boxes_library[user.ckey]) >= PERSONAL_MUSIC_BOX_MAX_UPLOADS_PER_ROUND)
		return "Вы исчерпали лимит загрузок на раунд (максимум [PERSONAL_MUSIC_BOX_MAX_UPLOADS_PER_ROUND]). Загруженные треки можно выбрать в библиотеке."
	var/last_player_upload = GLOB.personal_music_boxes_last_player_upload[user.ckey]
	var/player_remaining = last_player_upload ? last_player_upload + PERSONAL_MUSIC_BOX_PLAYER_UPLOAD_COOLDOWN - world.time : 0
	if(player_remaining > 0)
		return "Новый трек можно загрузить через [DisplayTimeText(player_remaining)]."
	var/global_remaining = GLOB.personal_music_boxes_last_upload + PERSONAL_MUSIC_BOX_UPLOAD_COOLDOWN - world.time
	if(global_remaining > 0)
		return "Кто-то недавно загружал трек. Подождите [DisplayTimeText(global_remaining)]."
	return null

/// Причина, по которой трек сейчас нельзя включить, либо null
/obj/item/personal_music_box/proc/get_play_block_reason()
	var/datum/component/jukebox/personal_music_box/jukebox = get_jukebox_component()
	if(!curfile_path || !jukebox?.custom_track)
		return "Сначала загрузите трек."
	if(jukebox.active)
		return "Шкатулка уже играет."
	if(!length(SSjukeboxes.freejukeboxchannels))
		return "Слишком много музыкальных автоматов играют одновременно."
	var/play_remaining = GLOB.personal_music_boxes_last_play + PERSONAL_MUSIC_BOX_PLAY_COOLDOWN - world.time
	if(play_remaining > 0)
		return "Включить можно через [DisplayTimeText(play_remaining)]."
	return null

/// Длительность аудиофайла в децисекундах, либо 0, если это не аудио.
/// rust-g читает заголовок потоком; file2text() в запасной ветке грузит в память весь файл и нужен только без soundlen.
/obj/item/personal_music_box/proc/get_audio_track_length(file_path)
	var/reported_length
	try
		reported_length = rustg_sound_length(file_path)
	catch(var/exception/error)
		stack_trace("personal music box: rustg_sound_length недоступен ([error]), проверяем заголовок вручную")
		return copytext(file2text(file_path), 1, 5) == "OggS" ? PERSONAL_MUSIC_BOX_MAX_TRACK_LENGTH : 0
	if(!isnum(reported_length) || reported_length <= 0)
		return 0
	return min(reported_length, PERSONAL_MUSIC_BOX_MAX_TRACK_LENGTH)

/// Диалог выбора файла усыпляет прок, так что флаг не даёт двум диалогам разом обойти лимиты.
/obj/item/personal_music_box/proc/upload_file(mob/living/user)
	var/user_ckey = user.ckey
	if(!user_ckey || GLOB.personal_music_boxes_uploading[user_ckey])
		return
	GLOB.personal_music_boxes_uploading[user_ckey] = TRUE
	var/lock_timer = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(clear_personal_music_box_upload_lock), user_ckey), PERSONAL_MUSIC_BOX_UPLOAD_LOCK_TIMEOUT, TIMER_STOPPABLE)
	do_upload_file(user)
	deltimer(lock_timer)
	GLOB.personal_music_boxes_uploading -= user_ckey

/// Глобальный прок: страховочный таймер должен сработать, даже если шкатулку или моба уже удалили.
/proc/clear_personal_music_box_upload_lock(user_ckey)
	if(!user_ckey)
		return
	GLOB.personal_music_boxes_uploading -= user_ckey

/obj/item/personal_music_box/proc/do_upload_file(mob/living/user)
	var/infile = input(user, "Выберите файл .ogg:", name) as null|file
	if(!infile || QDELETED(src) || QDELETED(user))
		return
	store_upload(user, infile, "[infile]")

/// Проверяет залитый файл, копирует его в каталог загрузок раунда и ставит в шкатулку
/obj/item/personal_music_box/proc/store_upload(mob/living/user, infile, filename)
	var/block_reason = get_upload_block_reason(user, ignore_own_lock = TRUE)
	if(block_reason)
		to_chat(user, span_warning(block_reason))
		return FALSE
	if(!findtext(lowertext(filename), ".ogg", -4))
		to_chat(user, span_warning("Трек должен быть в формате .ogg."))
		return FALSE
	var/file_size = length(infile)
	if(file_size > PERSONAL_MUSIC_BOX_MAX_FILE_SIZE)
		to_chat(user, span_warning("Файл слишком большой. Максимум 6 МБ."))
		return FALSE

	var/stored_path = "[PERSONAL_MUSIC_BOX_UPLOAD_DIR][user.ckey]_[num2text(world.time, 12)].ogg"
	fdel(stored_path)
	if(!fcopy(infile, stored_path) || length(file(stored_path)) != file_size)
		fdel(stored_path)
		to_chat(user, span_warning("Не удалось загрузить трек."))
		return FALSE
	var/track_length = get_audio_track_length(stored_path)
	if(!track_length)
		fdel(stored_path)
		to_chat(user, span_warning("Файл не распознан как аудио."))
		return FALSE

	GLOB.personal_music_boxes_last_player_upload[user.ckey] = world.time
	GLOB.personal_music_boxes_last_upload = world.time
	var/track_name = get_personal_music_box_track_name(filename)
	user.log_message("uploaded personal music box track \"[track_name]\" ([file_size] bytes): [stored_path]", LOG_GAME)

	var/list/entry = list(
		"path" = stored_path,
		"name" = track_name,
		"length" = track_length,
		"duration" = DisplayTimeText(track_length),
	)
	var/list/library = GLOB.personal_music_boxes_library[user.ckey]
	if(!library)
		library = list()
		GLOB.personal_music_boxes_library[user.ckey] = library
	library += list(entry)
	load_track(entry)
	to_chat(user, span_notice("Трек «[song_name]» загружен."))
	return TRUE

/obj/item/personal_music_box/proc/load_track(list/entry)
	curfile_path = entry["path"]
	song_name = entry["name"]
	var/datum/component/jukebox/personal_music_box/jukebox = get_jukebox_component()
	jukebox?.set_custom_track(curfile_path, song_name, entry["length"])
	update_icon()

/// Ставит в шкатулку трек, уже залитый этим игроком за раунд. Лимит загрузок и кулдауны не тратит.
/obj/item/personal_music_box/proc/select_library_track(mob/living/user, index)
	if(!user?.ckey || is_playing() || loc != user)
		return FALSE
	var/list/library = GLOB.personal_music_boxes_library[user.ckey]
	if(!isnum(index) || index != round(index) || index < 1 || index > length(library))
		return FALSE
	var/list/entry = library[index]
	if(entry["path"] == curfile_path)
		return FALSE
	if(!fexists(entry["path"]))
		to_chat(user, span_warning("Файл трека больше не найден на сервере."))
		return FALSE
	load_track(entry)
	user.log_message("selected personal music box track: [curfile_path]", LOG_GAME)
	return TRUE

/obj/item/personal_music_box/proc/toggle_playback(mob/living/user)
	playsound(loc, 'sound/machines/ping.ogg', 50, FALSE)
	if(is_playing())
		halt_playback(user)
		return
	var/block_reason = get_play_block_reason()
	if(block_reason)
		to_chat(user, span_warning(block_reason))
		return
	var/datum/component/jukebox/personal_music_box/jukebox = get_jukebox_component()
	GLOB.personal_music_boxes_last_play = world.time
	jukebox.queuedplaylist = list(jukebox.custom_track)
	if(!jukebox.activate_music())
		to_chat(user, span_warning("Не удалось начать воспроизведение."))
		return
	visible_message(span_notice("[user] включает [src]."), span_notice("Вы включаете [src]."), vision_distance = COMBAT_MESSAGE_RANGE)
	user.log_message("played personal music box track: [curfile_path]", LOG_GAME)

/obj/item/personal_music_box/proc/halt_playback(mob/living/user)
	var/datum/component/jukebox/personal_music_box/jukebox = get_jukebox_component()
	if(!jukebox || (!jukebox.active && !jukebox.playing))
		return
	jukebox.stop_playback()
	if(user && curfile_path)
		user.log_message("stopped personal music box track: [curfile_path]", LOG_GAME)

/// Очередь играющего трека меняется сразу, а не со следующего запуска.
/obj/item/personal_music_box/proc/toggle_repeat()
	var/datum/component/jukebox/personal_music_box/jukebox = get_jukebox_component()
	if(!jukebox)
		return FALSE
	jukebox.repeat = !jukebox.repeat
	if(jukebox.active && jukebox.custom_track)
		if(jukebox.repeat)
			if(!(jukebox.custom_track in jukebox.queuedplaylist))
				jukebox.queuedplaylist += jukebox.custom_track
		else
			jukebox.queuedplaylist -= jukebox.custom_track
	return TRUE

/// Название трека из имени файла: без пути и расширения, без < > и не длиннее PERSONAL_MUSIC_BOX_MAX_TRACK_NAME_LEN символов
/proc/get_personal_music_box_track_name(filename)
	var/track_label = filename
	var/path_separator = max(findlasttext(track_label, "/"), findlasttext(track_label, "\\"))
	if(path_separator)
		track_label = copytext(track_label, path_separator + 1)
	var/dot_position = findlasttext(track_label, ".")
	if(dot_position)
		track_label = copytext(track_label, 1, dot_position)
	track_label = trim(strip_html_simple(track_label), PERSONAL_MUSIC_BOX_MAX_TRACK_NAME_LEN + 1)
	return length(track_label) ? track_label : "Свой трек"

#undef PERSONAL_MUSIC_BOX_MAX_UPLOADS_PER_ROUND
#undef PERSONAL_MUSIC_BOX_PLAYER_UPLOAD_COOLDOWN
#undef PERSONAL_MUSIC_BOX_UPLOAD_COOLDOWN
#undef PERSONAL_MUSIC_BOX_PLAY_COOLDOWN
#undef PERSONAL_MUSIC_BOX_MAX_TRACK_LENGTH
#undef PERSONAL_MUSIC_BOX_MAX_TRACK_NAME_LEN
#undef PERSONAL_MUSIC_BOX_TRACK_BEAT
#undef PERSONAL_MUSIC_BOX_DEFAULT_VOLUME
#undef PERSONAL_MUSIC_BOX_UPLOAD_LOCK_TIMEOUT
