/datum/asset/spritesheet_batched/chat
	name = "chat"
	// Единственный лист, который нельзя собирать отложенно: классы спрайтов отсюда
	// подставляет речь (language.dm, hearted.dm, emoji_parse.dm), а не окно tgui.
	// Речь зовут проки с SHOULD_NOT_SLEEP, дособрать лист по требованию оттуда нельзя -
	// значит он обязан быть готов ещё с инициализации.
	load_immediately = TRUE
	/// Файл, из которого языки берут иконку по умолчанию.
	var/default_language_file = 'icons/misc/language.dmi'

/datum/asset/spritesheet_batched/chat/create_spritesheets()
	insert_all_icons("emoji", 'icons/emoji.dmi')
	insert_all_icons("emoji", 'icons/emoji_32.dmi')
	// pre-loading all lanugage icons also helps to avoid meta
	insert_all_icons("language", default_language_file)
	// catch languages which are pulling icons from another file
	var/list/states_by_file = list()
	for(var/datum/language/language_type as anything in typesof(/datum/language))
		var/icon/language_icon = initial(language_type.icon)
		if(language_icon == default_language_file)
			continue
		var/language_state = initial(language_type.icon_state)
		// Старый DM-путь молча пропускал спрайт, если такого стейта в файле нет
		// (Insert возвращал FALSE), а rust-g на неизвестный стейт валит весь лист.
		// В дереве языков есть абстрактные родители с icon_state = null - раньше они
		// давали спрайт-пустышку "language-", который никто не запрашивал. Сверяемся
		// заранее и кэшируем набор стейтов на файл, чтобы не читать DMI по разу на тип.
		var/list/states = states_by_file["[language_icon]"]
		if(isnull(states))
			states = icon_states(language_icon)
			states_by_file["[language_icon]"] = states
		if(!(language_state in states))
			continue
		insert_icon("language-[language_state]", uni_icon(language_icon, language_state))
