/// Portable music box — Ratwood dmusicbox-style user .ogg playback (sponsor loadout).

#define PERSONAL_MUSIC_BOX_MAX_FILE_SIZE 6485760 // 6 MiB
#define PERSONAL_MUSIC_BOX_UPLOAD_COOLDOWN 30 SECONDS
#define PERSONAL_MUSIC_BOX_FILE_CHANGE_COOLDOWN 3 MINUTES
#define PERSONAL_MUSIC_BOX_PLAY_COOLDOWN 10 SECONDS
#define PERSONAL_MUSIC_BOX_LOOP_INTERVAL 20 MINUTES
#define PERSONAL_MUSIC_BOX_DEFAULT_VOLUME 100
#define PERSONAL_MUSIC_BOX_EXTRA_RANGE 10

#define CHANNEL_PERSONAL_MUSIC_1 988
#define CHANNEL_PERSONAL_MUSIC_2 987
#define CHANNEL_PERSONAL_MUSIC_3 986
#define CHANNEL_PERSONAL_MUSIC_4 985

GLOBAL_LIST_EMPTY(personal_music_boxes)
GLOBAL_VAR_INIT(personal_music_boxes_last_upload, 0)
GLOBAL_VAR_INIT(personal_music_boxes_last_play, 0)

/datum/looping_sound/personal_music_box
	mid_sounds = list()
	mid_length = PERSONAL_MUSIC_BOX_LOOP_INTERVAL
	volume = PERSONAL_MUSIC_BOX_DEFAULT_VOLUME
	extra_range = PERSONAL_MUSIC_BOX_EXTRA_RANGE
	var/sound_channel = 0
	var/stopped = TRUE

/datum/looping_sound/personal_music_box/start(atom/on_behalf_of)
	stopped = FALSE
	return ..()

/datum/looping_sound/personal_music_box/get_sound(starttime, _mid_sounds)
	var/sounds = _mid_sounds || mid_sounds
	if(!islist(sounds))
		return sounds
	if(!length(sounds))
		return null
	return sounds[1]

/datum/looping_sound/personal_music_box/play(soundfile, volume_override)
	if(!parent || !sound_channel || stopped)
		return
	var/sound/S = sound(soundfile)
	S.channel = sound_channel
	S.repeat = 1
	S.wait = 0
	S.volume = volume_override || volume
	playsound(parent, S, S.volume, FALSE, extra_range, channel = sound_channel, pressure_affected = FALSE)

/datum/looping_sound/personal_music_box/proc/halt()
	stopped = TRUE
	if(sound_channel)
		for(var/mob/M in GLOB.player_list)
			if(M.client)
				M.stop_sound_channel(sound_channel)
		sound_channel = 0
	if(timerid)
		deltimer(timerid)
		timerid = null
	loop_started = FALSE

/obj/item/personal_music_box
	name = "personal music box"
	desc = "A portable music box. You can load your own .ogg tracks from your computer and play them nearby."
	icon = 'modular_citadel/icons/obj/personal_music_box.dmi'
	icon_state = "mbox0"
	w_class = WEIGHT_CLASS_BULKY
	verb_say = "states"
	var/datum/looping_sound/personal_music_box/soundloop
	var/curfile
	var/song_name
	var/playing = FALSE
	var/has_track = FALSE
	var/last_file_change = 0
	var/curvol = PERSONAL_MUSIC_BOX_DEFAULT_VOLUME

/obj/item/personal_music_box/Initialize(mapload)
	. = ..()
	GLOB.personal_music_boxes += src
	soundloop = new(src, FALSE)
	update_icon()

/obj/item/personal_music_box/Destroy()
	GLOB.personal_music_boxes -= src
	if(playing)
		halt_playback()
	QDEL_NULL(soundloop)
	return ..()

/obj/item/personal_music_box/examine(mob/user)
	. = ..()
	. += span_notice("Нажмите на шкатулку, чтобы открыть меню.")
	if(has_track)
		. += span_notice("Загружен трек: [song_name].")

/obj/item/personal_music_box/update_icon()
	icon_state = playing ? "mboxon" : (has_track ? "mbox1" : "mbox0")

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
	var/list/data = list()
	data["playing"] = playing
	data["has_track"] = has_track && curfile
	data["track_name"] = song_name
	data["volume"] = curvol
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
			var/new_volume = text2num(params["volume"])
			if(!isnum(new_volume))
				return
			curvol = clamp(round(new_volume), 0, 100)
			soundloop.volume = curvol
			return TRUE

/obj/item/personal_music_box/proc/can_upload(mob/user)
	if(playing)
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
	if(playing || !curfile)
		return FALSE
	if(world.time < GLOB.personal_music_boxes_last_play + PERSONAL_MUSIC_BOX_PLAY_COOLDOWN)
		return FALSE
	if(!find_free_channel())
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
	if(playing)
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

	curfile = file(logged_filename)
	if(!curfile || length(curfile) != file_size)
		if(fexists(logged_filename))
			fdel(logged_filename)
		curfile = null
		to_chat(user, span_warning("Не удалось загрузить трек."))
		return
	var/file_header = copytext(file2text(logged_filename), 1, 5)
	if(file_header != "OggS")
		if(fexists(logged_filename))
			fdel(logged_filename)
		curfile = null
		to_chat(user, span_warning("Файл не является валидным OGG (ожидался заголовок OggS)."))
		return

	last_file_change = world.time
	GLOB.personal_music_boxes_last_upload = world.time
	user.log_message("uploaded personal music box track: [logged_filename]", LOG_GAME)

	song_name = get_personal_music_box_track_name(filename)
	has_track = TRUE
	update_icon()
	to_chat(user, span_notice("Трек «[song_name]» загружен."))

/obj/item/personal_music_box/proc/toggle_playback(mob/living/user)
	playsound(loc, 'sound/machines/ping.ogg', 50, FALSE)
	if(!playing)
		if(!curfile)
			to_chat(user, span_warning("Сначала загрузите трек."))
			return
		var/new_channel = find_free_channel()
		if(!new_channel)
			to_chat(user, span_warning("Слишком много музыкальных шкатулок играют одновременно."))
			return
		if(world.time < GLOB.personal_music_boxes_last_play + PERSONAL_MUSIC_BOX_PLAY_COOLDOWN)
			to_chat(user, span_warning("Подождите немного перед воспроизведением."))
			return
		GLOB.personal_music_boxes_last_play = world.time
		playing = TRUE
		soundloop.sound_channel = new_channel
		soundloop.volume = curvol
		soundloop.mid_sounds = list(curfile)
		soundloop.start()
		update_icon()
		visible_message(span_notice("[user] включает [src]."), span_notice("Вы включаете [src]."), vision_distance = COMBAT_MESSAGE_RANGE)
		user.log_message("played personal music box track: [curfile]", LOG_GAME)
	else
		halt_playback(user)

/obj/item/personal_music_box/proc/halt_playback(mob/living/user)
	if(!playing && soundloop.stopped)
		return
	playing = FALSE
	soundloop.halt()
	update_icon()
	if(user && curfile)
		user.log_message("stopped personal music box track: [curfile]", LOG_GAME)

/obj/item/personal_music_box/proc/find_free_channel()
	var/free_mask = 1|2|4|8
	for(var/obj/item/personal_music_box/box in GLOB.personal_music_boxes)
		if(!box.playing || box.soundloop.stopped)
			continue
		switch(box.soundloop.sound_channel)
			if(CHANNEL_PERSONAL_MUSIC_1)
				free_mask &= ~1
			if(CHANNEL_PERSONAL_MUSIC_2)
				free_mask &= ~2
			if(CHANNEL_PERSONAL_MUSIC_3)
				free_mask &= ~4
			if(CHANNEL_PERSONAL_MUSIC_4)
				free_mask &= ~8
	if(!free_mask)
		return 0
	if(free_mask & 1)
		return CHANNEL_PERSONAL_MUSIC_1
	if(free_mask & 2)
		return CHANNEL_PERSONAL_MUSIC_2
	if(free_mask & 4)
		return CHANNEL_PERSONAL_MUSIC_3
	if(free_mask & 8)
		return CHANNEL_PERSONAL_MUSIC_4
	return 0

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
#undef PERSONAL_MUSIC_BOX_LOOP_INTERVAL
#undef PERSONAL_MUSIC_BOX_DEFAULT_VOLUME
#undef PERSONAL_MUSIC_BOX_EXTRA_RANGE
#undef CHANNEL_PERSONAL_MUSIC_1
#undef CHANNEL_PERSONAL_MUSIC_2
#undef CHANNEL_PERSONAL_MUSIC_3
#undef CHANNEL_PERSONAL_MUSIC_4
