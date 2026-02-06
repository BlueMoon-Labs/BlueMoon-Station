SUBSYSTEM_DEF(mail)
	name = "Mail"
	flags = SS_BACKGROUND | SS_NO_TICK_CHECK
	priority = FIRE_PRIORITY_MAIL
	runlevels = RUNLEVEL_GAME
	init_order = INIT_ORDER_MAIL
	wait = 5 MINUTES
	/// Mails on station, which was not opened yet
	var/list/obj/item/mail/sealed_mails = list()
	/// Total amount of arrived letters during the round
	var/total_mails_count = 0

	/// Count of mails, created by SSmail in main storage, waiting to be sent to station. Nullifies when storage was sent.
	var/mail_waiting = 0
	/// Main storage of SSmail, where mails are created
	var/obj/structure/closet/crate/mail/main_storage = null
	/// Turf, where main mail storage of SSmail will be spawned
	var/turf/main_storage_spawnpoint = null


	/// Assoc list 'mail category' = 'mail category weight'
	var/static/list/mail_categories_with_weights = list(
		MAIL_CATEGORY_MISC = 5,
		MAIL_CATEGORY_ANTAG = 2,
		MAIL_CATEGORY_MONEY = 5,
		MAIL_CATEGORY_FAMILY = 5,
		MAIL_CATEGORY_JOB = 8,
		MAIL_CATEGORY_SHOP = 6,
		MAIL_CATEGORY_SPAM = 5,
		MAIL_CATEGORY_LEWD = 4
	)
	/// Assoc list 'mail category' = 'mail category color'
	var/static/list/mail_categories_with_colors = list(
		MAIL_CATEGORY_MISC = "#ffffffff",
		MAIL_CATEGORY_ANTAG = "#ff2828ff",
		MAIL_CATEGORY_FAMILY = "#02eaffff",
		MAIL_CATEGORY_JOB = "#3dff08ff",
		MAIL_CATEGORY_MONEY = "#f2ff00ff",
		MAIL_CATEGORY_SHOP = "#4e3dffff",
		MAIL_CATEGORY_SPAM = "#ff9d00ff",
		MAIL_CATEGORY_LEWD = "#ff19d9ff"
	)
	/// Assoc list 'mail category' = 'mail category name'. Used in admin panel
	var/static/list/mail_categories_with_names = list(
		MAIL_CATEGORY_MISC = "Разное",
		MAIL_CATEGORY_ANTAG = "Антагонисты",
		MAIL_CATEGORY_FAMILY = "Семейные",
		MAIL_CATEGORY_JOB = "По работе",
		MAIL_CATEGORY_MONEY = "Финансы",
		MAIL_CATEGORY_SHOP = "Рассылки магазинов",
		MAIL_CATEGORY_SPAM = "Спам",
		MAIL_CATEGORY_LEWD = "Пошлости"
	)

	/// Assoc list of all patterns by categories, initialized in SSmail/Initialize() proc
	var/static/list/all_patterns_by_category = list()

	/// Assoc list: pattern_name = pattern_info_list with info about all patterns, used in admin panel. Initialized in SSmail init.
	var/static/list/all_patterns_info = list()

	/// Assoc list: pattern_name = pattern_object with all patterns, used in admin panel. Initialized in SSmail init.
	var/static/list/all_patterns = list()

/datum/controller/subsystem/mail/Initialize(start_timeofday)
	. = ..()
	for(var/category in mail_categories_with_weights)
		all_patterns_by_category[category] = list()
		var/list/types_of_category = typesof(text2path("/datum/mail_pattern/[category]"))
		for(var/P in types_of_category)
			var/datum/mail_pattern/pattern_path = P
			// Избавляемся от базовых паттернов
			if(pattern_path.type in MAIL_BASE_TYPE_LIST)
				continue
			var/datum/mail_pattern/new_pattern = new pattern_path()
			all_patterns[new_pattern.name] = new_pattern
			all_patterns_by_category[category] += new_pattern
			all_patterns_info[new_pattern.name] = get_pattern_info(new_pattern)
	create_main_storage()

/datum/controller/subsystem/mail/Recover()
	sealed_mails |= SSmail.sealed_mails
	total_mails_count = SSmail.total_mails_count
	main_storage = SSmail.main_storage
	main_storage_spawnpoint = SSmail.main_storage_spawnpoint

/datum/controller/subsystem/mail/fire(resumed = 0)
	delete_obsolete_mails()
	if(sealed_mails.len > MAX_SEALED_MESSAGES)
		return
	if(main_storage && mail_waiting >= main_storage.storage_capacity)
		return
	var/mail_gen_count = clamp(living_player_count() / rand(1, 5), 1, MAX_MAIL_PER_FIRE)
	if(mail_gen_count)
		generate_mails(mail_gen_count)

/datum/controller/subsystem/mail/proc/get_pattern_info(datum/mail_pattern/pattern)

	var/restriction_string = ""
	if(pattern.whitelisted_roundtypes.len)
		restriction_string += " - Доступен только в [jointext(pattern.whitelisted_roundtypes, ", ")].\n"
	if(pattern.blacklisted_roundtypes.len)
		restriction_string += " - Недоступен в [jointext(pattern.whitelisted_roundtypes, ", ")].\n"
	if(pattern.whitelisted_jobs.len)
		restriction_string += " - Доступен только для [jointext(pattern.whitelisted_jobs, ", ")].\n"
	if(pattern.blacklisted_jobs.len)
		restriction_string += " - Недоступен для [jointext(pattern.blacklisted_jobs, ", ")].\n"
	if(pattern.whitelisted_gender.len)
		restriction_string += " - Доступен только для пола: [jointext(pattern.whitelisted_gender, ", ")].\n"
	if(pattern.blacklisted_gender.len)
		restriction_string += " - Недоступен для пола: [jointext(pattern.blacklisted_gender, ", ")].\n"
	if(pattern.whitelisted_species.len)
		var/list/species_names = list()
		for(var/S in pattern.whitelisted_species)
			var/datum/species/species = S
			species_names += species.name
		restriction_string += " - Доступен только для [jointext(species_names, ", ")].\n"
	if(pattern.blacklisted_species.len)
		var/list/species_names = list()
		for(var/S in pattern.blacklisted_species)
			var/datum/species/species = S
			species_names += species.name
		restriction_string += " - Недоступен для [jointext(species_names, ", ")].\n"
	if(pattern.whitelisted_quirks.len)
		var/list/quirk_names = list()
		for(var/Q in pattern.whitelisted_quirks)
			var/datum/quirk/quirk = Q
			quirk_names += quirk.name
		restriction_string += " - Доступен только для обладающих квирками: [jointext(quirk_names, ", ")].\n"
	if(pattern.blacklisted_quirks.len)
		var/list/quirk_names = list()
		for(var/Q in pattern.blacklisted_quirks)
			var/datum/quirk/quirk = Q
			quirk_names += quirk.name
		restriction_string += " - Недоступен для обладающих квирками: [jointext(quirk_names, ", ")].\n"
	restriction_string += pattern.bad_feeling ? "Обладает плохим предчувствием" : "Не обладает плохим предчувствием"

	var/contents_string = ""
	if(pattern.letter_html)
		contents_string += ">[pattern.letter_title]<"
	for(var/C in pattern.initial_contents)
		var/obj/item/content = C
		contents_string += "[contents_string ? ", " : ""][initial(content.name)]"

	var/list/pattern_info = list(
		"category" = pattern.category,
		"weight" = pattern.weight,
		"desc" = pattern.description,
		"restriction_string" = restriction_string,
		"contents" = contents_string
	)
	return pattern_info

/// Registers mail, adding it to general list, where it will be destroyed in MAIL_DISAPPEAR_TIME if not opened
/datum/controller/subsystem/mail/proc/register_mail(obj/item/mail)
	sealed_mails[mail] = world.time + MAIL_DISAPPEAR_TIME

/// Unregister mail, removing it from lists
/datum/controller/subsystem/mail/proc/unregister_mail(obj/item/mail)
	if(mail in sealed_mails)
		sealed_mails[mail] = null
		sealed_mails -= mail

/// Deleting mails from sealed_mails list, which lifetime was expired, calling their mail/disappear() proc
/datum/controller/subsystem/mail/proc/delete_obsolete_mails()
	var/deleted_mails_count = 0
	for(var/obj/item/mail/sealed_mail in sealed_mails)
		if(world.time > sealed_mails[sealed_mail])
			sealed_mails[sealed_mail] = null
			sealed_mails -= sealed_mail
			INVOKE_ASYNC(sealed_mail, TYPE_PROC_REF(/obj/item/mail, disappear))
			deleted_mails_count++
	if(deleted_mails_count)
		log_subsystem(src, "Удалено [deleted_mails_count] старых неоткрытых писем")

/// Generate 'mail_gen_count' number of mails for random valid recipients in main_storage
/datum/controller/subsystem/mail/proc/generate_mails(mail_gen_count)
	if(!istype(main_storage))
		create_main_storage()

	var/list/mail_recipients = list()

	for(var/mob/living/carbon/human/human in GLOB.player_list)
		if(human.stat == DEAD || !human.mind)
			continue
		// Отправляем письма только тем, у кого валидная работа, чтобы отфильтровать всяких ноунеймичей
		if(!(human.mind.assigned_role in get_all_jobs()))
			continue

		mail_recipients += human

	for(var/i in 1 to mail_gen_count)
		var/mob/living/carbon/human/recipient = pick_n_take(mail_recipients)
		if(!recipient)
			continue
		if(main_storage.contents.len >= main_storage.storage_capacity)
			break
		create_mail_for_recipient(recipient, main_storage)

	main_storage.update_icon()

/// Creates a mail for a specific recipient
/datum/controller/subsystem/mail/proc/create_mail_for_recipient(mob/living/carbon/human/recipient, atom/mail_holder, datum/mail_pattern/pattern = null, add_to_waiting_mails = TRUE)

	var/datum/job/this_job = SSjob.name_occupations[recipient.mind.assigned_role]

	if(!this_job)
		return FALSE

	if(!recipient.dna.uni_identity)
		return FALSE

	if(!pattern)
		pattern = choose_pattern(recipient)
	else
		pattern = new pattern.type()
	if(!istype(pattern, /datum/mail_pattern))
		return FALSE

	var/obj/item/mail/new_mail = new(mail_holder)

	new_mail.recipient_name = recipient.mind.name
	new_mail.recipient_job = recipient.mind.assigned_role
	new_mail.recipient_fingerprint = md5(recipient.dna.uni_identity)

	new_mail.name = "[initial(new_mail.name)] for [new_mail.recipient_name] ([new_mail.recipient_job])"

	if(this_job.paycheck_department && new_mail.department_colors[this_job.paycheck_department])
		new_mail.color = new_mail.department_colors[this_job.paycheck_department]

	new_mail.pattern = pattern
	pattern.parent = new_mail

	pattern.apply(recipient)

	if(add_to_waiting_mails)
		mail_waiting++

	return new_mail

/// Choosing mail pattern for specific recipient in accordance to all weights
/datum/controller/subsystem/mail/proc/choose_pattern(mob/living/carbon/human/recipient)
	. = TRUE
	if(!istype(recipient))
		return FALSE
	var/list/local_categories_with_weights = mail_categories_with_weights.Copy()
	// if(recipient.client.prefs.preferred_mail_category)
	// 		picked_mail_category[preferred_mail_category] *= 3
	var/picked_mail_category = pickweight(local_categories_with_weights)
	var/list/modified_patterns_list = regenerate_all_weights(recipient, picked_mail_category)
	if(modified_patterns_list.len == 0)
		modified_patterns_list = regenerate_all_weights(recipient, MAIL_ALL_CATEGORIES)
		if(modified_patterns_list.len == 0)
			return FALSE
	var/datum/mail_pattern/chosen_pattern = pickweight(modified_patterns_list)
	if(!chosen_pattern)
		return FALSE
	return (new chosen_pattern())



/// Returns 'pattern type = modified weight' assoc list for specific recipient.
/// If you want zero-chance patterns to be included in list, use include_zeros. Used in adminpanel.
/// Filtering goes for specific categories, category or list of them passed in the 'categories' parameter.
/// If 'MAIL_ALL_CATEGORIES' parameter was selected search goes for all categories
/// Modification of weight for specific pattern can be specified in switch-case construction in this proc
/// This modification can filter out incompatible (cookies for synths) patterns or take in accout recipient's prefs
/datum/controller/subsystem/mail/proc/regenerate_all_weights(mob/living/carbon/human/recipient, categories = MAIL_ALL_CATEGORIES, include_zeros = FALSE)
	. = list()

	var/list/sanitized_categories = sanitize_islist(categories, list(categories))
	var/list/patterns_list = list()
	var/multiply_by_category_weight = FALSE

	if(sanitized_categories[1] == MAIL_ALL_CATEGORIES)
		multiply_by_category_weight = TRUE
		sanitized_categories -= sanitized_categories[1]
		for(var/category in mail_categories_with_names)
			sanitized_categories += category
	for(var/category in sanitized_categories)
		var/list/types_of_category = all_patterns_by_category[category]
		patterns_list.Add(types_of_category)

	for(var/P in patterns_list)
		var/datum/mail_pattern/pattern = P
		var/weight = pattern.regenerate_weight(recipient)
		if(!include_zeros && weight == 0)
			continue
		.[pattern.type] = weight * (multiply_by_category_weight ? mail_categories_with_weights[pattern.category] : 1)

	return .

/// Creates beatiful (maybe) HTML string from weights_assoc_list for debugging
/datum/controller/subsystem/mail/proc/parse_weights_to_html(list/weights_assoc_list)
	var/html = "<html><body>"
	if(!islist(weights_assoc_list) || !weights_assoc_list.len)
		return "<center><br><br><b>Доступные паттерны отсутствуют!</b></center>"
	var/list/patterns_in_categories = list()
	for(var/P in weights_assoc_list)
		var/datum/mail_pattern/pattern = P
		if(initial(pattern.category) in patterns_in_categories)
			patterns_in_categories[initial(pattern.category)][initial(pattern.name)] = weights_assoc_list[pattern]
		else
			patterns_in_categories[initial(pattern.category)] = list(initial(pattern.name) = weights_assoc_list[pattern])
	for(var/category in patterns_in_categories)
		html += "<br><br><b color='[category_colorize(category)]'>[category_to_text(category)]</b><hr>"
		for(var/pattern_name in patterns_in_categories[category])
			var/pattern_weight = patterns_in_categories[category][pattern_name]
			html += "<br><i color='[category_colorize(category)]'>[pattern_name]</i> - [pattern_weight ? pattern_weight : "<span color='#ff2828ff'>НЕДОСТУПЕН</span>"]"
	html += "</body></html>"
	return html

/// Converts subsystem to color
/datum/controller/subsystem/mail/proc/category_colorize(category = MAIL_CATEGORY_MISC)
	return mail_categories_with_colors[category]

/// Converts subsystem to readable text
/datum/controller/subsystem/mail/proc/category_to_text(category = MAIL_CATEGORY_MISC)
	return mail_categories_with_names[category]

/// Creates new main_storage on specific turf
/datum/controller/subsystem/mail/proc/create_main_storage()
	if(!main_storage_spawnpoint || !isturf(main_storage_spawnpoint))
		var/list/turf/postal_turfs = get_area_turfs(/area/mail_spawner)
		if(!postal_turfs.len)
			flags |= SS_NO_FIRE
			message_admins("Подсистема [src] отключена из-за невозможности спавна почтовых контейнеров в связи с уничтожением почтового маяка и кабинки")
			log_subsystem(src, "Подсистема отключена из-за невозможности спавна почтовых контейнеров в связи с уничтожением почтового маяка и кабинки")
			return
		for(var/turf/T in postal_turfs)
			var/obj/structure/marker_beacon/yellow/mail_beacon/our_beacon = locate() in T
			if(!QDELETED(our_beacon))
				main_storage_spawnpoint = get_turf(our_beacon)
				break
		if(!istype(main_storage_spawnpoint))
			main_storage_spawnpoint = pick(postal_turfs)
			new /obj/structure/marker_beacon/yellow/mail_beacon(main_storage_spawnpoint)
	main_storage = new /obj/structure/closet/crate/mail(main_storage_spawnpoint)
	main_storage.desc = "Великое и ужасное ГЛАВНОЕ ХРАНИЛИЩЕ, куда все письма галактики стекаются, чтобы быть отправленными дурацким космонавтам с [GLOB.station_name]..."
	main_storage.name = "ГЛАВНОЕ ПОЧТОВОЕ ХРАНИЛИЩЕ"
	main_storage.resistance_flags |= INDESTRUCTIBLE

/// Sends storage to cargo shuttle and creating new
/datum/controller/subsystem/mail/proc/send_storage(turf/destination)
	if(!istype(main_storage))
		create_main_storage()
		return
	main_storage.wrap()
	main_storage.forceMove(destination)
	log_subsystem(src, "Ящик, содержащий [main_storage.initial_mails_count] писем отправлен на шаттл карго")
	main_storage = null
	mail_waiting = 0
	create_main_storage()


/**
 *
 * ПАНЕЛЬКА ДЛЯ АДМИНОВ, ПОЗВОЛЯЮЩАЯ СОЗДАВАТЬ ПИСЬМА ПО ШАБЛОНУ
 *
 */

/client/proc/mail_panel()
	set name = "✉️ Почтовая Панель"
	set desc = "Позволяет создавать письма и посылки для определённых игроков."
	set category = "Admin.Game"
	if(!check_rights(R_ADMIN))
		return
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Mail Panel") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	if(!SSticker || SSticker.current_state != GAME_STATE_PLAYING || !SSmail.initialized)
		to_chat(usr, span_warning("В данный момент нельзя использовать почтовую панель!"))
		return
	if(!istype(usr, /mob/dead/observer) && !istype(usr, /mob/living))
		to_chat(usr, span_warning("Вы должны быть живым мобом или наблюдателем, чтобы использовать почтовую панель!"))
		return
	var/datum/mail_panel_gui/tgui = new(usr)
	tgui.ui_interact(usr)

/datum/mail_panel_gui
	var/mob/holder
	var/list/players_assoc_list = list()
	var/list/player_names = list()
	var/mob/living/carbon/human/chosen_recipient = null
	var/displayed_category = null
	var/datum/mail_pattern/displayed_pattern = null

/datum/mail_panel_gui/New(mob/user)
	holder = user
	load_player_list()

/datum/mail_panel_gui/Destroy(force, ...)
	holder = null
	players_assoc_list = null
	player_names = null
	chosen_recipient = null
	displayed_pattern = null
	. = ..()

/datum/mail_panel_gui/proc/load_player_list()
	players_assoc_list = list()
	player_names = list()
	if(istype(holder, /mob/living/carbon/human))
		players_assoc_list["_Для меня!"] = holder
		player_names += "_Для меня!"
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(!istype(player))
			continue
		if(player == holder)
			continue
		players_assoc_list[player.real_name] = player
		player_names += player.real_name
	player_names = sort_list(player_names)

/datum/mail_panel_gui/ui_state(mob/user)
	if(!istype(holder, /mob))
		return UI_CLOSE
	return GLOB.admin_state

/datum/mail_panel_gui/ui_close()
	qdel(src)

/datum/mail_panel_gui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MailAdminPanel")
		ui.open()

/datum/mail_panel_gui/ui_data(mob/user)
	var/list/data = list()

	data["total_mails"] = SSmail.total_mails_count
	data["unopen_mails"] = SSmail.sealed_mails.len
	data["waiting_mails"] = SSmail.mail_waiting
	data["next_fire"] = STATION_TIME_TIMESTAMP("hh:mm:ss", SSmail.next_fire)

	if(displayed_category)
		var/list/available_patterns = list()
		for(var/P in SSmail.all_patterns_by_category[displayed_category])
			var/datum/mail_pattern/pattern = P
			available_patterns += pattern.name
		data["available_patterns"] = available_patterns
	else
		data["available_patterns"] = null

	if(displayed_pattern)
		data["info_on_displayed_pattern"] = SSmail.all_patterns_info[displayed_pattern.name]

	if(chosen_recipient && chosen_recipient.mind)
		data["chosen_player_name"] = chosen_recipient.real_name
		data["chosen_player_ckey"] = chosen_recipient.ckey
		data["chosen_player_assignment"] = chosen_recipient.mind.assigned_role
	return data

/datum/mail_panel_gui/ui_static_data(mob/user)
	. = ..()
	var/list/data = list()

	data["player_names"] = player_names

	var/list/available_categories_names = list()

	for(var/category in SSmail.mail_categories_with_names)
		available_categories_names += SSmail.mail_categories_with_names[category]

	data["available_categories"] = available_categories_names

	return data

/datum/mail_panel_gui/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		/**
		 * Автообсёрвнуть главное хранилище
		 */
		if("jump_to_storage")
			if(!istype(SSmail.main_storage))
				to_chat(holder, span_warning("Главное хранилище не существует!"))
				return
			holder.client?.admin_follow(SSmail.main_storage)
			return
		/**
		 * Проверить веса паттернов для получателя
		 */
		if("check_weights")
			if(!istype(chosen_recipient))
				to_chat(holder, span_warning("Получатель не указан или не валиден!"))
			var/html_with_checked_weights = SSmail.parse_weights_to_html(SSmail.regenerate_all_weights(chosen_recipient, MAIL_ALL_CATEGORIES, TRUE))
			var/datum/browser/browser = new(holder, "mail_admin_panel_weights", "Веса для игрока")
			browser.set_content(html_with_checked_weights)
			browser.open()
			return
		/**
		 * Выбрать получателя
		 */
		if("select_player")
			var/mob/living/carbon/human/chosen = players_assoc_list[params["player_name"]]
			if(!chosen || !istype(chosen))
				to_chat(holder, span_warning("Игрок не выбран или не валиден!"))
				return
			chosen_recipient = chosen
			return
		/**
		 * Обновить список игроков
		 */
		if("update_players")
			load_player_list()
			update_static_data(holder)
			return
		/**
		 * Выбрать категорию паттернов
		 */
		if("choose_category")
			var/chosen_category_name = params["chosen_category"]
			for(var/category in SSmail.mail_categories_with_names)
				if(SSmail.mail_categories_with_names[category] == chosen_category_name)
					displayed_category = category
			if(!displayed_category)
				to_chat(holder, span_warning("Произошла какая-то ошибка! Категория не выбрана!"))
			return
		/**
		 * Выбрать паттерн
		 */
		if("choose_pattern")
			var/chosen_pattern_name = params["chosen_pattern"]
			var/datum/mail_pattern/chosen_pattern = SSmail.all_patterns[chosen_pattern_name]
			if(chosen_pattern)
				displayed_pattern = chosen_pattern
			else
				to_chat(holder, span_warning("Произошла какая-то ошибка! Паттерн не выбран!"))
			return
		/**
		 * Запланировать письмо для отправки в почтовом хранилище
		 */
		if("create_in_storage")
			if(!istype(chosen_recipient))
				to_chat(holder, span_warning("Получатель не выбран или невалиден!"))
				return
			if(!istype(displayed_pattern))
				to_chat(holder, span_warning("Шаблон не выбран или невалиден!"))
				return
			if(!istype(SSmail.main_storage))
				to_chat(holder, span_warning("Проблемы с главным хранилищем!"))
				return
			var/obj/item/mail/new_envelope = SSmail.create_mail_for_recipient(chosen_recipient, SSmail.main_storage, displayed_pattern, TRUE)
			if(istype(new_envelope))
				to_chat(holder, span_notice("Письмо создано в главном хранилище!"))
				message_admins("[holder] создал письмо для [chosen_recipient] с шаблоном [displayed_pattern] в главном хранилище.")
			else
				to_chat(holder, span_warning("Не получилось! Проверьте введённые данные!"))
			return
		/**
		 * Создать письмо под собой
		 */
		if("create_under_me")
			if(!istype(chosen_recipient))
				to_chat(holder, span_warning("Получатель не выбран или невалиден!"))
				return
			if(!istype(displayed_pattern))
				to_chat(holder, span_warning("Шаблон не выбран или невалиден!"))
				return
			if(!isturf(get_turf(holder)))
				to_chat(holder, span_warning("Тайл под вами невалиден или произошла какая-то ошибка!"))
				return
			var/obj/item/mail/new_envelope = SSmail.create_mail_for_recipient(chosen_recipient, get_turf(holder), displayed_pattern, FALSE)
			if(istype(new_envelope))
				SSmail.register_mail(new_envelope)
				new_envelope.arrive_time = "[GLOB.current_date_string] [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]"
				to_chat(holder, span_notice("Письмо создано под вами!"))
				do_fake_sparks(3, 2, new_envelope)
				if(!isobserver(holder))
					new_envelope.visible_message(span_warning("Под [holder] внезапно появляется [new_envelope]!"))
				else
					new_envelope.visible_message(span_warning("Внезапно [new_envelope] материализуется из неоткуда!"))
				message_admins("[holder] создал письмо для [chosen_recipient] с шаблоном [displayed_pattern] под собой.")
			else
				to_chat(holder, span_warning("Не получилось! Проверьте введённые данные!"))
			return
		/**
		 * Создать письмо прямо под ногами получателя
		 */
		if("create_under_them")
			if(!istype(chosen_recipient))
				to_chat(holder, span_warning("Получатель не выбран или невалиден!"))
				return
			if(!istype(displayed_pattern))
				to_chat(holder, span_warning("Шаблон не выбран или невалиден!"))
				return
			if(!isturf(get_turf(chosen_recipient)))
				to_chat(holder, span_warning("Тайл под получателем невалиден или произошла какая-то ошибка!"))
				return
			var/obj/item/mail/new_envelope = SSmail.create_mail_for_recipient(chosen_recipient, get_turf(chosen_recipient), displayed_pattern, FALSE)
			if(istype(new_envelope))
				SSmail.register_mail(new_envelope)
				new_envelope.arrive_time = "[GLOB.current_date_string] [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]"
				to_chat(holder, span_notice("Письмо создано под [chosen_recipient]!"))
				do_fake_sparks(3, 2, new_envelope)
				chosen_recipient.visible_message(span_warning("Под [chosen_recipient] внезапно появляется [new_envelope]!"), span_boldwarning("Что это у меня под ногами?.."))
				message_admins("[holder] создал письмо для [chosen_recipient] с шаблоном [displayed_pattern] под получателем.")
			else
				to_chat(holder, span_warning("Не получилось! Проверьте введённые данные!"))
			return
