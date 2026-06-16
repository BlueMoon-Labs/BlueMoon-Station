/// Portable music box — Ratwood dmusicbox-style user .ogg playback (sponsor loadout).

#define PERSONAL_MUSIC_BOX_MAX_FILE_SIZE 6485760 // 6 MiB
#define PERSONAL_MUSIC_BOX_UPLOAD_COOLDOWN 30 SECONDS
#define PERSONAL_MUSIC_BOX_FILE_CHANGE_COOLDOWN 3 MINUTES
#define PERSONAL_MUSIC_BOX_PLAY_COOLDOWN 10 SECONDS
#define PERSONAL_MUSIC_BOX_DEFAULT_TRACK_LENGTH 20 MINUTES
#define PERSONAL_MUSIC_BOX_DEFAULT_VOLUME 100

GLOBAL_VAR_INIT(personal_music_boxes_last_upload, 0)
GLOBAL_VAR_INIT(personal_music_boxes_last_play, 0)

/datum/component/jukebox/personal_music_box
	dupe_type = /datum/component/jukebox/personal_music_box
	var/datum/track/custom_track

/datum/component/jukebox/personal_music_box/Initialize(_volume, _on_music_toggle)
	. = ..(FALSE, PRICE_FREE, _volume, _on_music_toggle)
	if(. == COMPONENT_INCOMPATIBLE)
		return
	repeat = TRUE
	UnregisterSignal(parent, COMSIG_ITEM_ATTACK_SELF)

/datum/component/jukebox/personal_music_box/ui_status(mob/user)
	return UI_CLOSE

/datum/component/jukebox/personal_music_box/proc/set_custom_track(track_path, track_name)
	QDEL_NULL(custom_track)
	if(!track_path)
		return
	custom_track = new(track_name, file(track_path), PERSONAL_MUSIC_BOX_DEFAULT_TRACK_LENGTH, 50, "personal_[REF(parent)]")

/datum/component/jukebox/personal_music_box/proc/stop_playback()
	if(!active && !playing)
		return
	stop = 0

/datum/component/jukebox/personal_music_box/activate_music()
	var/obj/item/personal_music_box/box = parent
	if(playing || !queuedplaylist.len)
		return FALSE
	if(!SSjukeboxes.freejukeboxchannels.len)
		return FALSE
	if(!check_area(TRUE))
		return FALSE
	playing = queuedplaylist[1]
	var/jukeboxslottotake = SSjukeboxes.addjukebox(box, playing, volume / 35, personal = TRUE)
	if(!jukeboxslottotake)
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

/datum/component/jukebox/personal_music_box/Destroy()
	QDEL_NULL(custom_track)
	return ..()

/obj/item/personal_music_box
	name = "personal music box"
	desc = "A portable music box. You can load your own .ogg tracks from your computer and play them nearby."
	icon = 'modular_citadel/icons/obj/personal_music_box.dmi'
	righthand_file = 'modular_citadel/icons/obj/boombox_righthand.dmi'
	lefthand_file = 'modular_citadel/icons/obj/boombox_lefthand.dmi'
	icon_state = "mbox0"
	verb_say = "states"
	var/curfile_path
	var/song_name
	var/has_track = FALSE
	var/last_file_change = 0

/obj/item/personal_music_box/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/jukebox/personal_music_box, PERSONAL_MUSIC_BOX_DEFAULT_VOLUME, CALLBACK(src, PROC_REF(on_music_toggle)))

/obj/item/personal_music_box/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/personal_music_box/Destroy()
	if(is_playing())
		halt_playback()
	return ..()

/obj/item/personal_music_box/proc/get_jukebox_component()
	return GetComponent(/datum/component/jukebox/personal_music_box)

/obj/item/personal_music_box/proc/is_playing()
	var/datum/component/jukebox/personal_music_box/J = get_jukebox_component()
	return J?.active

/obj/item/personal_music_box/proc/on_music_toggle(active)
	update_icon()

/obj/item/personal_music_box/examine(mob/user)
	. = ..()
	. += span_notice("Нажмите на шкатулку, чтобы открыть меню.")
	if(has_track)
		. += span_notice("Загружен трек: [song_name].")

/obj/item/personal_music_box/update_icon()
	icon_state = is_playing() ? "mboxon" : (has_track ? "mbox1" : "mbox0")
	item_state = is_playing() ? "mboxon" : (has_track ? "mbox1" : "mbox0")

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
	var/datum/component/jukebox/personal_music_box/J = get_jukebox_component()
	var/list/data = list()
	data["playing"] = is_playing()
	data["has_track"] = has_track && curfile_path
	data["track_name"] = song_name
	data["volume"] = J?.volume || PERSONAL_MUSIC_BOX_DEFAULT_VOLUME
	data["in_hand"] = (loc == user)
	data["upload_ready"] = can_upload(user)
	data["play_ready"] = can_start_playback()
	data["upload_cooldown"] = get_upload_cooldown_text()
	data["play_cooldown"] = get_play_cooldown_text()
	data["file_change_cooldown"] = get_file_change_cooldown_text()
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
		if("upload")
			if(!can_upload(living_user))
				return
			playsound(loc, 'sound/machines/ping.ogg', 50, FALSE)
			INVOKE_ASYNC(src, PROC_REF(upload_file), living_user)
			return TRUE
		if("set_volume")
			var/datum/component/jukebox/personal_music_box/J = get_jukebox_component()
			if(!J)
				return
			var/new_volume = text2num(params["volume"])
			if(!isnum(new_volume))
				return
			J.volume = clamp(round(new_volume), 0, 100)
			var/juke_index = SSjukeboxes.findjukeboxindex(src)
			if(juke_index)
				SSjukeboxes.updatejukebox(juke_index, jukefalloff = J.volume / 35)
			return TRUE

/obj/item/personal_music_box/proc/can_upload(mob/user)
	if(is_playing())
		return FALSE
	if(loc != user)
		return FALSE
	if(!user.ckey)
		return FALSE
	if(last_file_change && world.time < last_file_change + PERSONAL_MUSIC_BOX_FILE_CHANGE_COOLDOWN)
		return FALSE
	if(world.time < GLOB.personal_music_boxes_last_upload + PERSONAL_MUSIC_BOX_UPLOAD_COOLDOWN)
		return FALSE
	return TRUE

/obj/item/personal_music_box/proc/can_start_playback()
	if(is_playing() || !curfile_path)
		return FALSE
	if(world.time < GLOB.personal_music_boxes_last_play + PERSONAL_MUSIC_BOX_PLAY_COOLDOWN)
		return FALSE
	if(!SSjukeboxes.freejukeboxchannels.len)
		return FALSE
	return TRUE

/obj/item/personal_music_box/proc/get_upload_cooldown_text()
	var/remaining = GLOB.personal_music_boxes_last_upload + PERSONAL_MUSIC_BOX_UPLOAD_COOLDOWN - world.time
	return remaining > 0 ? DisplayTimeText(remaining) : null

/obj/item/personal_music_box/proc/get_play_cooldown_text()
	var/remaining = GLOB.personal_music_boxes_last_play + PERSONAL_MUSIC_BOX_PLAY_COOLDOWN - world.time
	return remaining > 0 ? DisplayTimeText(remaining) : null

/obj/item/personal_music_box/proc/get_file_change_cooldown_text()
	if(!last_file_change)
		return null
	var/remaining = last_file_change + PERSONAL_MUSIC_BOX_FILE_CHANGE_COOLDOWN - world.time
	return remaining > 0 ? DisplayTimeText(remaining) : null

/obj/item/personal_music_box/proc/upload_file(mob/living/user)
	set waitfor = FALSE
	var/infile = input(user, "Choose an .ogg file to load:", name) as null|file
	if(!infile || QDELETED(src))
		return
	if(is_playing())
		return
	if(!can_upload(user))
		return

	var/filename = "[infile]"
	var/lower_filename = lowertext(filename)
	if(!findtext(lower_filename, ".ogg", -4))
		to_chat(user, span_warning("Трек должен быть в формате .ogg."))
		return
	var/file_size = length(infile)
	if(file_size > PERSONAL_MUSIC_BOX_MAX_FILE_SIZE)
		to_chat(user, span_warning("Файл слишком большой. Максимум 6 МБ."))
		return

	if(!GLOB.log_directory)
		to_chat(user, span_warning("Загрузка треков недоступна до начала раунда."))
		return

	var/logged_filename = "[GLOB.log_directory]/jukebox_upload_[user.ckey]_[world.time].ogg"
	if(fexists(logged_filename))
		fdel(logged_filename)
	if(!fcopy(infile, logged_filename))
		to_chat(user, span_warning("Не удалось загрузить трек."))
		return
	if(QDELETED(user) || QDELETED(src))
		if(fexists(logged_filename))
			fdel(logged_filename)
		return

	if(!fexists(logged_filename) || length(file(logged_filename)) != file_size)
		if(fexists(logged_filename))
			fdel(logged_filename)
		curfile_path = null
		to_chat(user, span_warning("Не удалось загрузить трек."))
		return
	var/file_header = copytext(file2text(logged_filename), 1, 5)
	if(file_header != "OggS")
		if(fexists(logged_filename))
			fdel(logged_filename)
		curfile_path = null
		to_chat(user, span_warning("Файл не является валидным OGG (ожидался заголовок OggS)."))
		return

	curfile_path = logged_filename

	last_file_change = world.time
	GLOB.personal_music_boxes_last_upload = world.time
	user.log_message("uploaded personal music box track: [logged_filename]", LOG_GAME)

	song_name = get_personal_music_box_track_name(filename)
	has_track = TRUE
	var/datum/component/jukebox/personal_music_box/J = get_jukebox_component()
	J?.set_custom_track(curfile_path, song_name)
	update_icon()
	to_chat(user, span_notice("Трек «[song_name]» загружен."))

/obj/item/personal_music_box/proc/toggle_playback(mob/living/user)
	playsound(loc, 'sound/machines/ping.ogg', 50, FALSE)
	var/datum/component/jukebox/personal_music_box/J = get_jukebox_component()
	if(!J)
		return
	if(!J.active)
		if(!curfile_path || !J.custom_track)
			to_chat(user, span_warning("Сначала загрузите трек."))
			return
		if(!SSjukeboxes.freejukeboxchannels.len)
			to_chat(user, span_warning("Слишком много музыкальных автоматов играют одновременно."))
			return
		if(world.time < GLOB.personal_music_boxes_last_play + PERSONAL_MUSIC_BOX_PLAY_COOLDOWN)
			to_chat(user, span_warning("Подождите немного перед воспроизведением."))
			return
		GLOB.personal_music_boxes_last_play = world.time
		J.queuedplaylist = list(J.custom_track)
		if(!J.activate_music())
			to_chat(user, span_warning("Не удалось начать воспроизведение."))
			return
		update_icon()
		visible_message(span_notice("[user] включает [src]."), span_notice("Вы включаете [src]."), vision_distance = COMBAT_MESSAGE_RANGE)
		user.log_message("played personal music box track: [curfile_path]", LOG_GAME)
	else
		halt_playback(user)

/obj/item/personal_music_box/proc/halt_playback(mob/living/user)
	var/datum/component/jukebox/personal_music_box/J = get_jukebox_component()
	if(!J || (!J.active && !J.playing))
		return
	J.stop_playback()
	update_icon()
	if(user && curfile_path)
		user.log_message("stopped personal music box track: [curfile_path]", LOG_GAME)

/proc/get_personal_music_box_track_name(filename)
	var/track_label = filename
	var/slash_pos = findlasttext(track_label, "/")
	var/backslash_pos = findlasttext(track_label, "\\")
	var/path_sep = max(slash_pos, backslash_pos)
	if(path_sep)
		track_label = copytext(track_label, path_sep + 1)
	var/dot_pos = findlasttext(track_label, ".")
	if(dot_pos > 1)
		track_label = copytext(track_label, 1, dot_pos)
	return length(track_label) ? track_label : "Custom track"

#undef PERSONAL_MUSIC_BOX_MAX_FILE_SIZE
#undef PERSONAL_MUSIC_BOX_UPLOAD_COOLDOWN
#undef PERSONAL_MUSIC_BOX_FILE_CHANGE_COOLDOWN
#undef PERSONAL_MUSIC_BOX_PLAY_COOLDOWN
#undef PERSONAL_MUSIC_BOX_DEFAULT_TRACK_LENGTH
#undef PERSONAL_MUSIC_BOX_DEFAULT_VOLUME
