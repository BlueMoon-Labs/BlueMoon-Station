SUBSYSTEM_DEF(title_bm)
	name = "BlueMoon Title Screen"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_TITLE - 1

	var/current_image
	var/list/sfw_images = list()
	var/list/nsfw_images = list()
	var/lobby_html = ""
	var/current_notice
	var/loading_image = BM_LOBBY_LOADING_GIF
	var/current_video_payload
	var/cached_static_html = ""
	var/cached_js_url = ""           // URL JS-библиотеки — вычисляется один раз в _build_static_html
	var/cached_notice_js = ""        // JS-вызов для текущего объявления — кешируется в set_notice
	var/current_sfw_image
	var/current_nsfw_image

/// Перечитывает lobby_html.txt с диска и пересылает свежий HTML всем игрокам в лобби.
/// Возвращает количество обновлённых клиентов.
/datum/controller/subsystem/title_bm/proc/reload_lobby_html()
	if(fexists(BM_LOBBY_HTML_FILE))
		lobby_html = _parse_lobby_html(file2text(BM_LOBBY_HTML_FILE))
	else
		lobby_html = _parse_lobby_html(file2text('config/bluemoon/lobby_html.txt'))
	var/refreshed = 0
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(!player.client)
			continue
		INVOKE_ASYNC(player, TYPE_PROC_REF(/mob/dead/new_player, bm_update_lobby_html))
		refreshed++
	return refreshed

/datum/controller/subsystem/title_bm/proc/_parse_lobby_html(full_html)
	var/head_end = findtext(full_html, "</head>")
	var/search_from = head_end ? head_end : 1
	var/body_pos = findtext(full_html, "<body", search_from)
	if(body_pos)
		var/tag_end = findtext(full_html, ">", body_pos)
		return tag_end ? copytext(full_html, 1, tag_end + 1) : full_html
	return full_html

/datum/controller/subsystem/title_bm/Initialize()
	if(fexists(BM_LOBBY_HTML_FILE))
		lobby_html = _parse_lobby_html(file2text(BM_LOBBY_HTML_FILE))
	else
		lobby_html = _parse_lobby_html(file2text('config/bluemoon/lobby_html.txt'))

	_load_title_images()

	if(fexists(loading_image))
		loading_image = fcopy_rsc(loading_image)
	else
		log_game("[name]: Файл загрузочного GIF '[loading_image]' не найден. Фон лобби будет пустым до подбора картинки.")
		loading_image = null
	current_image = loading_image || BM_LOBBY_DEFAULT_IMAGE

	RegisterSignal(SSticker, COMSIG_TICKER_ENTER_PREGAME, PROC_REF(_on_enter_pregame))
	RegisterSignal(SSticker, COMSIG_TICKER_ENTER_SETTING_UP, PROC_REF(_on_enter_setting_up))

	_build_static_html()

	initialized = TRUE
	return SS_INIT_SUCCESS

/datum/controller/subsystem/title_bm/Destroy()
	UnregisterSignal(SSticker, list(COMSIG_TICKER_ENTER_PREGAME, COMSIG_TICKER_ENTER_SETTING_UP))
	sfw_images = null
	nsfw_images = null
	current_sfw_image = null
	current_nsfw_image = null
	cached_static_html = ""
	cached_js_url = ""
	cached_notice_js = ""
	return ..();

/datum/controller/subsystem/title_bm/Recover()
	current_image         = SStitle_bm.current_image
	loading_image         = SStitle_bm.loading_image
	sfw_images            = SStitle_bm.sfw_images
	nsfw_images           = SStitle_bm.nsfw_images
	current_notice        = SStitle_bm.current_notice
	current_video_payload = SStitle_bm.current_video_payload
	if(fexists(BM_LOBBY_HTML_FILE))
		lobby_html = _parse_lobby_html(file2text(BM_LOBBY_HTML_FILE))
	else
		lobby_html = SStitle_bm.lobby_html
	cached_static_html      = SStitle_bm.cached_static_html
	cached_js_url           = SStitle_bm.cached_js_url
	cached_notice_js        = SStitle_bm.cached_notice_js
	current_sfw_image   = SStitle_bm.current_sfw_image
	current_nsfw_image  = SStitle_bm.current_nsfw_image

/datum/controller/subsystem/title_bm/proc/_build_static_html()
	var/list/parts = list()
	parts += {"<img id=\"bm-bg\" class=\"bg\" src=\"loading_screen.gif\" alt=\"\">"}
	parts += {"<div id=\"bm-overlay\"></div>"}
	parts += {"<div id=\"bm-toasts\"></div>"}
	parts += {"<div id=\"bm-toggle-btn\" onclick=\"bmToggleSidebar()\" title=\"Свернуть/развернуть меню\">&#9654;</div>"}
	cached_static_html = parts.Join("")

/datum/controller/subsystem/title_bm/proc/_load_images_from_dir(dir_path, list/target_list)
	if(!fexists(dir_path))
		return
	var/list/files = flist(dir_path)
	if(!islist(files))
		return
	for(var/filename in files)
		if(filename == "exclude" || filename == "blank.png")
			continue
		if(copytext(filename, length(filename)) == "/")
			continue
		var/lower = lowertext(filename)
		var/len = length(lower)
		var/is_image = (copytext(lower, len - 3) == ".png") \
			|| (copytext(lower, len - 3) == ".jpg") \
			|| (copytext(lower, len - 3) == ".gif") \
			|| (copytext(lower, len - 3) == ".dmi") \
			|| (copytext(lower, len - 4) == ".jpeg")
		if(!is_image)
			continue
		var/full_path = "[dir_path][filename]"
		target_list += fcopy_rsc(full_path)

/datum/controller/subsystem/title_bm/proc/_load_title_images()
	_load_images_from_dir(BM_LOBBY_IMAGES_SFW, sfw_images)
	_load_images_from_dir(BM_LOBBY_IMAGES_NSFW, nsfw_images)

/datum/controller/subsystem/title_bm/proc/get_image_for_player(show_nsfw = FALSE, show_admin_bg = TRUE)
	if(loading_image && current_image == loading_image)
		return loading_image
	if(show_admin_bg && current_image)
		return current_image
	if(show_nsfw && current_nsfw_image)
		return current_nsfw_image
	if(current_sfw_image)
		return current_sfw_image
	// fallback: если кеш ещё не заполнен — выбрать случайно
	var/list/pool = show_nsfw && LAZYLEN(nsfw_images) ? nsfw_images : sfw_images
	if(!LAZYLEN(pool))
		return BM_LOBBY_DEFAULT_IMAGE
	return pick(pool)

/datum/controller/subsystem/title_bm/proc/_rotate_current_images()
	if(LAZYLEN(sfw_images))
		current_sfw_image = pick(sfw_images)
	if(LAZYLEN(nsfw_images))
		current_nsfw_image = pick(nsfw_images)
	else
		current_nsfw_image = current_sfw_image

/datum/controller/subsystem/title_bm/proc/set_video(payload)
	current_video_payload = payload
	current_image = null
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(!player.bm_lobby_ready || !player.client)
			continue
		if(!player.client.prefs || player.client.prefs.bm_lobby_show_admin_bg)
			player.client << output(payload, "bm_lobby_browser:bm_set_background")

/datum/controller/subsystem/title_bm/proc/change_image(file_or_icon)
	current_video_payload = null
	if(file_or_icon)
		current_image = file_or_icon
	else
		current_image = null

	// Готовым — только меняем картинку через JS (без перезагрузки HTML → музыка не прерывается)
	// Не готовым — полный показ лобби с нуля
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(player.spawning || player.new_character)
			continue
		if(player.bm_lobby_ready)
			INVOKE_ASYNC(player, TYPE_PROC_REF(/mob/dead/new_player, bm_push_background))
		else
			INVOKE_ASYNC(player, TYPE_PROC_REF(/mob/dead/new_player, bm_show_lobby))

/datum/controller/subsystem/title_bm/proc/show_to_all()
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(player.spawning || player.new_character)
			continue
		INVOKE_ASYNC(player, TYPE_PROC_REF(/mob/dead/new_player, bm_show_lobby))

/datum/controller/subsystem/title_bm/proc/set_notice(notice_text)
	current_notice = notice_text ? sanitize_text(notice_text) : null
	// Кешируем escaped-версию для подстановки в _bm_build_html новых игроков
	var/escaped = ""
	if(current_notice)
		escaped = replacetext(current_notice, "\\", "\\\\")
		escaped = replacetext(escaped, "'", "\\'")
		escaped = replacetext(escaped, "\n", "\\n")
		cached_notice_js = "bm_show_notice('[escaped]');"
	else
		cached_notice_js = ""
	var/toast_type = current_notice ? "'error'" : "'info'"
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(!player.bm_lobby_ready || !player.client)
			continue
		player.client << output("'[escaped]',[toast_type]", "bm_lobby_browser:bm_show_notice")

/datum/controller/subsystem/title_bm/proc/update_character_name(mob/dead/new_player/user, name)
	if(!(istype(user) && user.bm_lobby_ready && user.client))
		return
	user.client << output(name, "bm_lobby_browser:bm_update_character")

/datum/controller/subsystem/title_bm/proc/_get_player_counts()
	var/ready = 0
	for(var/mob/dead/new_player/np as anything in GLOB.new_player_list)
		if(QDELETED(np))
			continue
		if(np.ready)
			ready++
	return list(length(GLOB.clients), length(GLOB.new_player_list), ready)

/// Вызывается при изменении ready-статуса игрока. Пересчитывает счётчик и рассылает payload.
/datum/controller/subsystem/title_bm/proc/on_player_ready_change(delta)
	update_player_counts_all()

/datum/controller/subsystem/title_bm/proc/_build_counts_payload()
	var/list/counts = _get_player_counts()
	var/timer_s = (SSticker?.timeLeft > 0) ? round(SSticker.timeLeft / 10) : -1
	var/is_pregame = (!SSticker || SSticker.current_state <= GAME_STATE_PREGAME) ? 1 : 0
	return "[counts[1]],[counts[2]],[counts[3]],[timer_s],[is_pregame]"

/datum/controller/subsystem/title_bm/proc/push_player_count_to(mob/dead/new_player/player)
	if(!(istype(player) && player.bm_lobby_ready && player.client))
		return
	player.client << output(_build_counts_payload(), "bm_lobby_browser:bm_update_counts")

/datum/controller/subsystem/title_bm/proc/update_player_counts_all()
	var/payload = _build_counts_payload()
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(QDELETED(player) || !player.bm_lobby_ready || !player.client)
			continue
		player.client << output(payload, "bm_lobby_browser:bm_update_counts")

/datum/controller/subsystem/title_bm/proc/_on_enter_pregame()
	SIGNAL_HANDLER
	_rotate_current_images()  // выбираем случайную картинку один раз при старте прегейма
	change_image(null)
	if(SSticker?.login_music)
		for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
			if(!player.bm_lobby_ready || !player.client || player.bm_lobby_music_path)
				continue
			INVOKE_ASYNC(player.client, TYPE_PROC_REF(/client, bm_push_lobby_music))

/datum/controller/subsystem/title_bm/proc/_on_enter_setting_up()
	SIGNAL_HANDLER
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(player.spawning || player.new_character)
			continue
		if(!player.client)
			continue
		INVOKE_ASYNC(player, TYPE_PROC_REF(/mob/dead/new_player, bm_update_lobby_html))
