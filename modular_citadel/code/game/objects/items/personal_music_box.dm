/// Portable music box — Ratwood dmusicbox-style user .ogg playback (sponsor loadout).

#define PERSONAL_MUSIC_BOX_MAX_FILE_SIZE 6485760 // 6 MiB
#define PERSONAL_MUSIC_BOX_UPLOAD_COOLDOWN 30 SECONDS
#define PERSONAL_MUSIC_BOX_FILE_CHANGE_COOLDOWN 3 MINUTES
#define PERSONAL_MUSIC_BOX_PLAY_COOLDOWN 10 SECONDS
/// Потолок длительности трека. Реальная длина снимается с файла при заливке; потолок
/// страхует от файлов, у которых заголовок врёт про длину.
#define PERSONAL_MUSIC_BOX_MAX_TRACK_LENGTH 20 MINUTES
#define PERSONAL_MUSIC_BOX_DEFAULT_VOLUME 100
/// Сколько треков один игрок может залить за раунд. Кулдаун сам по себе ничего не ограничивает:
/// в раунде 10137 один человек залил шесть файлов на 13.3 МБ, просто дождавшись таймера.
#define PERSONAL_MUSIC_BOX_MAX_UPLOADS_PER_ROUND 3
/// Через сколько флаг "диалог выбора файла открыт" снимается принудительно.
/// Рантайм внутри do_upload_file() или разрыв связи с открытым нативным input() не
/// возвращают управление в upload_file(), и без страховки ckey оставался бы помеченным
/// до конца раунда: игрок терял право на заливку молча, ни одна причина отказа об этом
/// не говорила.
#define PERSONAL_MUSIC_BOX_UPLOAD_LOCK_TIMEOUT (5 MINUTES)

GLOBAL_VAR_INIT(personal_music_boxes_last_upload, 0)
GLOBAL_VAR_INIT(personal_music_boxes_last_play, 0)
/// ckey -> world.time последней смены трека. Кулдаун привязан к игроку, а не к предмету:
/// на самой шкатулке он обходился второй такой же шкатулкой в другой руке.
GLOBAL_LIST_EMPTY(personal_music_boxes_last_change)
/// ckey -> сколько треков игрок успешно залил за раунд
GLOBAL_LIST_EMPTY(personal_music_boxes_upload_count)
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

/datum/component/jukebox/personal_music_box/ui_status(mob/user)
	return UI_CLOSE

/datum/component/jukebox/personal_music_box/proc/set_custom_track(track_path, track_name, track_length)
	clear_custom_track()
	if(!track_path)
		return
	// song_length решает, когда компонент считает трек законченным. Прежний дефолт в 20 минут
	// означал, что после конца короткого трека шкатулка ещё четверть часа "играла" тишину,
	// а повтор перезапускал музыку только по истечении этих 20 минут.
	if(!isnum(track_length) || track_length <= 0)
		track_length = PERSONAL_MUSIC_BOX_MAX_TRACK_LENGTH
	custom_track = new(track_name, file(track_path), track_length, 50, "personal_[REF(parent)]")

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
	clear_custom_track()
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

/obj/item/personal_music_box/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/jukebox/personal_music_box, PERSONAL_MUSIC_BOX_DEFAULT_VOLUME, CALLBACK(src, PROC_REF(on_music_toggle)))

/obj/item/personal_music_box/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/personal_music_box/Destroy()
	if(is_playing())
		halt_playback()
	// curfile_path намеренно не удаляется: файл лежит в GLOB.log_directory и является тем самым
	// артефактом, на который ссылается log_message() при заливке и включении трека. Снести его
	// вместе со шкатулкой - значит оставить админам строчку лога, указывающую в пустоту, ровно
	// тогда, когда надо проверить, что именно крутили на станции. Рост объёма ограничен лимитом
	// PERSONAL_MUSIC_BOX_MAX_UPLOADS_PER_ROUND, а сама папка чистится вместе с логами раунда.
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
	data["repeat"] = J?.repeat
	data["has_track"] = has_track && curfile_path
	data["track_name"] = song_name
	data["volume"] = J?.volume || PERSONAL_MUSIC_BOX_DEFAULT_VOLUME
	data["in_hand"] = (loc == user)
	data["repeat"] = J ? J.repeat : FALSE
	data["track_duration"] = J?.custom_track ? DisplayTimeText(J.custom_track.song_length) : null
	data["upload_ready"] = can_upload(user)
	data["play_ready"] = can_start_playback()
	// Кнопка загрузки задизейблена, нажать её и получить объяснение в чат нельзя -
	// причина отказа обязана быть видна прямо в окне.
	data["upload_block_reason"] = get_upload_block_reason(user)
	data["play_cooldown"] = get_play_cooldown_text()
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
			var/datum/component/jukebox/personal_music_box/J = get_jukebox_component()
			if(!J)
				return
			J.repeat = !J.repeat
			return TRUE
		if("upload")
			var/block_reason = get_upload_block_reason(living_user)
			if(block_reason)
				to_chat(living_user, span_warning(block_reason))
				return
			playsound(loc, 'sound/machines/ping.ogg', 50, FALSE)
			INVOKE_ASYNC(src, PROC_REF(upload_file), living_user)
			return TRUE
		if("repeat")
			return toggle_repeat()
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

/**
 * Причина отказа в заливке трека, либо null если заливать можно.
 *
 * ignore_own_lock снимает проверку флага "у этого игрока диалог уже открыт". Нужен ровно
 * одному вызову - повторной сверке лимитов внутри do_upload_file() после того, как игрок
 * закрыл диалог: там флаг стоит НАШ собственный, и без этого аргумента заливка отказывала
 * бы сама себе.
 */
/obj/item/personal_music_box/proc/get_upload_block_reason(mob/user, ignore_own_lock = FALSE)
	if(is_playing())
		return "Сначала выключите шкатулку."
	if(loc != user)
		return "Шкатулка должна быть в руках."
	if(!user?.ckey)
		return "Некому загружать трек."
	// Флаг был невидим снаружи: игрок, у которого он залип, получал отказ без причины -
	// кнопка просто ничего не делала.
	if(!ignore_own_lock && GLOB.personal_music_boxes_uploading[user.ckey])
		return "У вас уже открыт диалог выбора файла."
	var/uploads_done = GLOB.personal_music_boxes_upload_count[user.ckey]
	if(uploads_done && uploads_done >= PERSONAL_MUSIC_BOX_MAX_UPLOADS_PER_ROUND)
		return "Вы исчерпали лимит загрузок на раунд (максимум [PERSONAL_MUSIC_BOX_MAX_UPLOADS_PER_ROUND])."
	var/remaining = get_file_change_cooldown_remaining(user)
	if(remaining > 0)
		return "Слишком часто меняете трек. Подождите [DisplayTimeText(remaining)]."
	var/global_remaining = GLOB.personal_music_boxes_last_upload + PERSONAL_MUSIC_BOX_UPLOAD_COOLDOWN - world.time
	if(global_remaining > 0)
		return "Кто-то недавно загружал трек. Подождите [DisplayTimeText(global_remaining)]."
	return null

/obj/item/personal_music_box/proc/can_upload(mob/user, ignore_own_lock = FALSE)
	return isnull(get_upload_block_reason(user, ignore_own_lock))

/obj/item/personal_music_box/proc/can_start_playback()
	if(is_playing() || !curfile_path)
		return FALSE
	if(world.time < GLOB.personal_music_boxes_last_play + PERSONAL_MUSIC_BOX_PLAY_COOLDOWN)
		return FALSE
	if(!SSjukeboxes.freejukeboxchannels.len)
		return FALSE
	return TRUE

/obj/item/personal_music_box/proc/get_play_cooldown_text()
	var/remaining = GLOB.personal_music_boxes_last_play + PERSONAL_MUSIC_BOX_PLAY_COOLDOWN - world.time
	return remaining > 0 ? DisplayTimeText(remaining) : null

/// Сколько децисекунд игроку ещё ждать до следующей смены трека
/obj/item/personal_music_box/proc/get_file_change_cooldown_remaining(mob/user)
	if(!user?.ckey)
		return 0
	var/last_change = GLOB.personal_music_boxes_last_change[user.ckey]
	if(!last_change)
		return 0
	return max(last_change + PERSONAL_MUSIC_BOX_FILE_CHANGE_COOLDOWN - world.time, 0)

/// Длительность залитого аудиофайла в децисекундах, либо 0, если файл не распознан как аудио.
/// ЦЕНА: прежняя проверка звала file2text() и материализовала строкой ВЕСЬ файл (до шести
/// мегабайт, см. PERSONAL_MUSIC_BOX_MAX_FILE_SIZE) ради четырёх байт заголовка "OggS". Разовый
/// запрос непрерывного блока такого размера во фрагментированной куче 32-битного DreamDaemon -
/// нежелательный класс аллокации. rust-g разбирает заголовок сам, потоком, и отдаёт в DM одно
/// число, так что шестимегабайтной строки не возникает. Если в сборке rust-g нет soundlen,
/// откатываемся на старую проверку заголовка, чтобы не сломать заливку целиком, - длина
/// тогда неизвестна и падает в потолок PERSONAL_MUSIC_BOX_MAX_TRACK_LENGTH.
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

/obj/item/personal_music_box/proc/upload_file(mob/living/user)
	set waitfor = FALSE
	// Диалог выбора файла усыпляет прок, а лимиты сверяются до и после него. Без флага
	// два одновременно открытых диалога проходят обе проверки и обходят счётчик за раунд.
	var/user_ckey = user.ckey
	if(!user_ckey || GLOB.personal_music_boxes_uploading[user_ckey])
		return
	GLOB.personal_music_boxes_uploading[user_ckey] = TRUE
	// Страховка от залипшего флага. Рантайм в do_upload_file() или разрыв связи с открытым
	// нативным input() обрывают прок, и строка снятия ниже просто не выполняется -
	// в этом случае флаг снимет таймер.
	var/lock_timer = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(clear_personal_music_box_upload_lock), user_ckey), PERSONAL_MUSIC_BOX_UPLOAD_LOCK_TIMEOUT, TIMER_STOPPABLE)
	do_upload_file(user)
	deltimer(lock_timer)
	GLOB.personal_music_boxes_uploading -= user_ckey

/// Снимает флаг открытого диалога заливки. Глобальным проком: страховочный таймер обязан
/// пережить и шкатулку, и моба, а колбек на qdel'нутый датум просто не сработал бы.
/proc/clear_personal_music_box_upload_lock(user_ckey)
	if(!user_ckey)
		return
	GLOB.personal_music_boxes_uploading -= user_ckey

/obj/item/personal_music_box/proc/do_upload_file(mob/living/user)
	var/infile = input(user, "Choose an .ogg file to load:", name) as null|file
	if(!infile || QDELETED(src))
		return
	if(is_playing())
		return
	// Свой собственный флаг заливки тут игнорируем - он поставлен вызывающим upload_file().
	if(!can_upload(user, TRUE))
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
	var/track_length = get_audio_track_length(logged_filename)
	if(!track_length)
		if(fexists(logged_filename))
			fdel(logged_filename)
		curfile_path = null
		to_chat(user, span_warning("Файл не распознан как аудио."))
		return

	curfile_path = logged_filename

	GLOB.personal_music_boxes_last_change[user.ckey] = world.time
	GLOB.personal_music_boxes_upload_count[user.ckey] = (GLOB.personal_music_boxes_upload_count[user.ckey] || 0) + 1
	GLOB.personal_music_boxes_last_upload = world.time
	user.log_message("uploaded personal music box track: [logged_filename]", LOG_GAME)

	song_name = get_personal_music_box_track_name(filename)
	has_track = TRUE
	var/datum/component/jukebox/personal_music_box/J = get_jukebox_component()
	J?.set_custom_track(curfile_path, song_name, track_length)
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

/// Переключает повтор трека. Кнопка в интерфейсе была, а обработчика действия не было -
/// переключатель не делал ничего.
/obj/item/personal_music_box/proc/toggle_repeat()
	var/datum/component/jukebox/personal_music_box/J = get_jukebox_component()
	if(!J)
		return FALSE
	J.repeat = !J.repeat
	// Трек уже играет: очередь повтора следует за переключателем сразу, а не со следующего запуска.
	if(J.active && J.custom_track)
		if(J.repeat)
			if(!(J.custom_track in J.queuedplaylist))
				J.queuedplaylist += J.custom_track
		else
			J.queuedplaylist -= J.custom_track
	return TRUE

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
#undef PERSONAL_MUSIC_BOX_MAX_TRACK_LENGTH
#undef PERSONAL_MUSIC_BOX_DEFAULT_VOLUME
#undef PERSONAL_MUSIC_BOX_MAX_UPLOADS_PER_ROUND
#undef PERSONAL_MUSIC_BOX_UPLOAD_LOCK_TIMEOUT
