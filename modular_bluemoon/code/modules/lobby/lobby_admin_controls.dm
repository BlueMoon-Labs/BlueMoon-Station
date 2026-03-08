/client/proc/bm_admin_change_lobby_image()
	set name = "Лобби: Сменить картинку"
	set desc = "Загрузить или выбрать новое фоновое изображение для лобби."
	set category = "Admin.Fun"
	if(!check_rights(R_FUN))
		return
	if(!SStitle_bm)
		to_chat(mob, span_warning("SStitle_bm не инициализирован!"))
		return
	var/mob/user = mob
	log_admin("[key_name(user)] меняет картинку лобби BlueMoon.")
	message_admins("[key_name_admin(user)] меняет картинку лобби BlueMoon.")

	var/choice = tgui_input_list(
		user,
		"Выберите источник новой картинки:",
		"Смена картинки лобби",
		list("Загрузить файл", "Случайный SFW", "Случайный NSFW", "Сбросить (дефолт)")
	)
	if(!choice)
		return
	if(!SStitle_bm)
		return

	switch(choice)
		if("Загрузить файл")
			var/new_file = input(user, "Выберите изображение для лобби (PNG / JPG / GIF / DMI):", "Картинка лобби") as icon|null
			if(!new_file)
				return
			SStitle_bm.change_image(new_file)
			message_admins("[key_name_admin(user)] установил новую картинку лобби (загружен файл).")

		if("Случайный SFW")
			if(!LAZYLEN(SStitle_bm.sfw_images))
				to_chat(user, span_warning("SFW-пул картинок пустой! Добавьте файлы в config/title_screens/"))
				return
			SStitle_bm.change_image(null)
			message_admins("[key_name_admin(user)] выбрал случайную SFW-картинку лобби.")

		if("Случайный NSFW")
			if(!LAZYLEN(SStitle_bm.nsfw_images))
				to_chat(user, span_warning("NSFW-пул пустой! Добавьте файлы в config/title_screens/NSFW/"))
				return
			SStitle_bm.change_image(pick(SStitle_bm.nsfw_images))
			message_admins("[key_name_admin(user)] выбрал случайную NSFW-картинку лобби.")

		if("Сбросить (дефолт)")
			SStitle_bm.change_image(BM_LOBBY_DEFAULT_IMAGE)
			message_admins("[key_name_admin(user)] сбросил картинку лобби на дефолтную.")


// 2. БАННЕР-ОБЪЯВЛЕНИЕ
/client/proc/bm_admin_set_lobby_notice()
	set name = "Лобби: Установить объявление"
	set desc = "Показать красный текст-баннер на лобби."
	set category = "Admin.Fun"
	if(!check_rights(R_FUN))
		return
	if(!SStitle_bm)
		to_chat(mob, span_warning("SStitle_bm не инициализирован!"))
		return
	var/mob/user = mob
	log_admin("[key_name(user)] устанавливает объявление на лобби BlueMoon.")
	message_admins("[key_name_admin(user)] устанавливает объявление на лобби.")

	var/new_notice = input(user, "Введите текст объявления (пусто = убрать):", "Объявление на лобби", SStitle_bm.current_notice) as text|null
	if(isnull(new_notice))
		return
	if(!SStitle_bm)
		return
	SStitle_bm.set_notice(new_notice)

	if(new_notice)
		message_admins("[key_name_admin(user)] установил объявление: [new_notice]")
		for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
			to_chat(player, span_boldannounce("ОБЪЯВЛЕНИЕ ЛОББИ: [new_notice]"))
	else
		message_admins("[key_name_admin(user)] убрал объявление с лобби.")

// 3. ВСТАВИТЬ ВИДЕО/GIF ПО ССЫЛКЕ
/client/proc/bm_admin_set_lobby_video()
	set name = "Лобби: Видео/GIF по ссылке"
	set desc = "Вставить видео или GIF как фон лобби по HTTP-ссылке."
	set category = "Admin.Fun"
	if(!check_rights(R_FUN))
		return
	if(!SStitle_bm)
		to_chat(mob, span_warning("SStitle_bm не инициализирован!"))
		return
	var/mob/user = mob
	log_admin("[key_name(user)] меняет фон лобби на видео/GIF.")
	message_admins("[key_name_admin(user)] меняет фон лобби на видео/GIF.")

	var/type_choice = tgui_input_list(user, "Тип медиа:", "Медиа для лобби", list("GIF (картинка)", "Видео (MP4/WebM)", "YouTube"))
	if(!type_choice)
		return

	var/input_hint
	if(type_choice == "YouTube")
		input_hint = "Вставьте любую YouTube-ссылку:\nhttps://youtu.be/VIDEO_ID\nhttps://www.youtube.com/watch?v=VIDEO_ID\nhttps://www.youtube.com/embed/VIDEO_ID"
	else if(type_choice == "Видео (MP4/WebM)")
		input_hint = "Прямая ссылка на MP4 или WebM файл:"
	else
		input_hint = "Прямая ссылка на GIF/JPG/PNG:"

	var/media_url = input(user, input_hint, "URL медиа") as text|null
	if(!media_url)
		return
	media_url = trim(media_url)  // убираем пробелы и переносы строк

	// Валидация URL
	var/static/regex/url_check = regex("^https?://")
	if(!url_check.Find(media_url))
		to_chat(user, span_warning("Некорректный URL! Должен начинаться с http:// или https://"))
		return

	// Авто-конвертация YouTube-ссылок в embed-формат
	var/media_type = "image"
	if(type_choice == "YouTube")
		media_type = "iframe"
		var/video_id = ""
		// Формат youtu.be/VIDEO_ID
		var/short_pos = findtext(media_url, "youtu.be/")
		if(short_pos)
			var/id_start = short_pos + 9
			var/q_pos = findtext(media_url, "?", id_start)
			video_id = q_pos ? copytext(media_url, id_start, q_pos) : copytext(media_url, id_start)
		// Формат youtube.com/embed/VIDEO_ID
		if(!video_id)
			var/embed_pos = findtext(media_url, "youtube.com/embed/")
			if(embed_pos)
				var/id_start = embed_pos + 18
				var/q_pos = findtext(media_url, "?", id_start)
				video_id = q_pos ? copytext(media_url, id_start, q_pos) : copytext(media_url, id_start)
		// Формат youtube.com/watch?v=VIDEO_ID
		if(!video_id)
			var/v_pos = findtext(media_url, "?v=")
			if(!v_pos)
				v_pos = findtext(media_url, "&v=")
			if(v_pos)
				var/id_start = v_pos + 3
				var/amp_pos = findtext(media_url, "&", id_start)
				video_id = amp_pos ? copytext(media_url, id_start, amp_pos) : copytext(media_url, id_start)
		if(video_id)
			// Передаём только video_id BYOND обрезает строку на & при output. JS сам строит embed URL.
			media_url = video_id
		else
			to_chat(user, span_warning("Не удалось извлечь video_id! Используется URL как есть: [media_url]"))
	else if(type_choice == "Видео (MP4/WebM)")
		media_type = "video"

	var/list/payload_data = list("url" = media_url, "type" = media_type)
	var/payload = json_encode(payload_data)
	if(!SStitle_bm)
		return
	SStitle_bm.set_video(payload)

	message_admins("[key_name_admin(user)] установил [media_type] как фон лобби: [media_url]")
	to_chat(user, span_notice("Фон лобби обновлён для всех игроков."))

// 4. ПОЧИНКА ЛОББИ (Уклонение от хуев в ютубе)
/client/verb/bm_fix_lobby_screen()
	set name = "Починить экран лобби"
	set desc = "Экран лобби завис/пустой? Нажмите это."
	set category = "OOC"

	if(istype(mob, /mob/dead/new_player))
		var/mob/dead/new_player/player = mob
		player.bm_show_lobby()
	else
		winset(src, "bm_lobby_browser", "is-disabled=true;is-visible=false")
		winset(src, "status_bar", "is-visible=true")

// 5. ПЕРЕЗАГРУЗКА HTML/CSS ЛОББИ (администратор)
/client/proc/bm_admin_reload_lobby_html()
	set name = "Лобби: Перезагрузить HTML/CSS"
	set desc = "НЕ ИСПОЛЬЗОВАТЬ БЕЗ НУЖДЫ. Перечитать lobby_html.txt с диска и обновить стили для всех игроков в лобби."
	set category = "Admin.Fun"
	if(!check_rights(R_ADMIN))
		return
	var/mob/user = mob
	log_admin("[key_name(user)] перезагружает HTML/CSS лобби BlueMoon.")
	message_admins("[key_name_admin(user)] перезагружает HTML/CSS лобби.")
	if(!SStitle_bm)
		to_chat(user, span_warning("SStitle_bm не инициализирован!"))
		return
	var/refreshed = SStitle_bm.reload_lobby_html()
	to_chat(user, span_notice("HTML/CSS лобби перезагружен. Обновлено клиентов: [refreshed]."))
	message_admins("[key_name_admin(user)] перезагрузил HTML/CSS лобби. Обновлено клиентов: [refreshed].")
