/// Потолок веса файла заставки. Заставка проходит через `new /icon(...)`, а это единственная
/// непрерывная аллокация такого размера за всю инициализацию: анимированный GIF на 25 МБ,
/// который лежал в `config/title_screens/images/` на проде, разворачивался в 500 МБ и ронял
/// пик VmSize на столько же (замер 24.08.2026, Delta: 876 -> 1376 -> 876 МБ за полторы секунды).
/// В 32-битном DreamDaemon с потолком 4093 МБ такой запрос - это заряженное ружьё: тот же
/// `icon()` посреди раунда просит непрерывный блок во фрагментированной куче и не получает его.
#define TITLE_SCREEN_MAX_BYTES (4 * 1024 * 1024)

SUBSYSTEM_DEF(title)
	name = "Title Screen"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_TITLE

	var/file_path
	var/icon/icon
	var/icon/previous_icon
	/// Та же заставка, но записью в .rsc, а не датумом /icon. Присваивание /icon в atom.icon
	/// заставляет BYOND расплющить изменяемый битмап в ресурс на КАЖДОМ присваивании, а
	/// сплеш-экран присваивается поштучно каждому клиенту: на старте раунда - всем ста с
	/// лишним разом, в Shutdown() - ещё раз всем. Ссылка на готовую запись .rsc копируется
	/// указателем. Сам /icon остаётся: у него спрашивают Width() и его правят через VV.
	var/icon_source
	/// То же для прошлой заставки (сервер-хоп, конец раунда).
	var/previous_icon_source
	var/turf/closed/indestructible/splashscreen/splash_turf
	var/sound_path

/datum/controller/subsystem/title/Initialize()
	if(file_path && icon)
		return

	if(fexists("data/previous_title.dat"))
		var/previous_path = file2text("data/previous_title.dat")
		// Прошлая заставка грузится только если она проходит тот же потолок веса: файл
		// назван прошлым раундом и мог быть каким угодно. Читается previous_path, а не
		// previous_icon - прежняя строка `new(previous_icon)` разворачивала null и клала
		// в previous_icon пустую иконку.
		if(istext(previous_path) && fexists(previous_path) && title_screen_file_size(previous_path) <= TITLE_SCREEN_MAX_BYTES)
			previous_icon_source = fcopy_rsc(previous_path)
			previous_icon = new(previous_icon_source)
	fdel("data/previous_title.dat")

	var/list/provisional_title_screens = flist("[global.config.directory]/title_screens/images/")
	var/list/title_screens = list()
	var/use_rare_screens = prob(1)

	SSmapping.HACK_LoadMapConfig()
	var/list/oversized = list()
	for(var/S in provisional_title_screens)
		var/list/L = splittext(S,"+")
		var/eligible = FALSE
		if(L.len == 1 && L[1] != "exclude" && L[1] != "blank.png")
			eligible = TRUE
		else if(L.len > 1)
			if((use_rare_screens && lowertext(L[1]) == "rare") || (lowertext(L[1]) == lowertext(SSmapping.config.map_name)))
				eligible = TRUE
			else if(findtext(L[2], "{") && findtext(L[2], "}"))
				eligible = TRUE
		if(!eligible)
			continue
		var/candidate_size = title_screen_file_size("[global.config.directory]/title_screens/images/[S]")
		if(candidate_size > TITLE_SCREEN_MAX_BYTES)
			oversized += "[S] ([round(candidate_size / (1024 * 1024), 0.1)] МБ)"
			continue
		title_screens += S
	if(length(oversized))
		log_world("## MEMORY: заставки крупнее [round(TITLE_SCREEN_MAX_BYTES / (1024 * 1024), 0.1)] МБ пропущены (icon() развернул бы их в сотни мегабайт): [oversized.Join(", ")]")

	if(length(title_screens))
		file_path = "[global.config.directory]/title_screens/images/[pick(title_screens)]"

	if(!file_path)
		file_path = "icons/runtime/default_title.dmi"

	ASSERT(fexists(file_path))

	icon_source = fcopy_rsc(file_path)
	icon = new(icon_source)

	// Check for a corresponding sound file
	var/list/L = splittext(file_path, "+")
	if(L.len > 1)
		var/sound_suffix = replacetext(L[2], ".dmi", "")
		var/sound_file = "[global.config.directory]/title_music/sounds/[sound_suffix].ogg"
		if(fexists(sound_file))
			sound_path = sound_file
	else
		sound_path = null

	if(splash_turf)
		splash_turf.icon = icon
		splash_turf.handle_generic_titlescreen_sizes()

	return ..()

/datum/controller/subsystem/title/vv_edit_var(var_name, var_value)
	. = ..()
	if(.)
		switch(var_name)
			if(NAMEOF(src, icon))
				set_title_icon(icon)

/**
 * Подменить заставку и пересобрать её .rsc-ссылку.
 *
 * Единственная точка записи в icon/icon_source после инициализации. Правок заставки через
 * VV две (сам SStitle и турф заставки), и разъехавшаяся пара оставила бы турф с новой
 * картинкой, а сплеш-экран - со старой: title_splash_icon() предпочитает icon_source.
 */
/datum/controller/subsystem/title/proc/set_title_icon(icon/new_icon)
	icon = new_icon
	icon_source = new_icon ? fcopy_rsc(new_icon) : null
	if(splash_turf)
		splash_turf.icon = icon
		splash_turf.handle_generic_titlescreen_sizes()

/datum/controller/subsystem/title/Shutdown()
	if(file_path)
		var/F = file("data/previous_title.dat")
		WRITE_FILE(F, file_path)

	for(var/thing in GLOB.clients)
		if(!thing)
			continue
		var/atom/movable/screen/splash/S = new(null, thing, FALSE)
		S.Fade(FALSE,FALSE)

	// Save the sound path
	if(sound_path)
		var/F = file("data/previous_title_sound.dat")
		WRITE_FILE(F, sound_path)

/datum/controller/subsystem/title/Recover()
	icon = SStitle.icon
	icon_source = SStitle.icon_source
	splash_turf = SStitle.splash_turf
	file_path = SStitle.file_path
	previous_icon = SStitle.previous_icon
	previous_icon_source = SStitle.previous_icon_source

	// Recover the sound path
	if(fexists("data/previous_title_sound.dat"))
		sound_path = file2text("data/previous_title_sound.dat")

/**
 * Что положить в icon сплеш-экрана.
 *
 * Предпочитается ЗАПИСЬ В .rsc, а не датум /icon: сплеш заводится поштучно на каждого
 * клиента - на старте раунда всем ста с лишним разом, в Shutdown() ещё раз всем, - а
 * присваивание /icon в atom.icon каждый раз заставляет BYOND расплющивать изменяемый
 * битмап заставки в ресурс. Ссылка на .rsc копируется указателем.
 *
 * Откат на сам /icon обязателен: заставку можно подменить через VV на турфе
 * (splashscreen/vv_edit_var пишет SStitle.icon напрямую, мимо icon_source), и без отката
 * сплеш в такой раунд ушёл бы пустым. null означает "заставки нет вовсе".
 */
/proc/title_splash_icon(use_previous_title)
	if(use_previous_title)
		return SStitle.previous_icon_source || SStitle.previous_icon
	return SStitle.icon_source || SStitle.icon

/// Вес файла заставки в байтах, 0 если файла нет. Отдельным проком: `length()` на /file
/// читается неочевидно, а место у него ровно одно - решение "разворачивать или нет".
/proc/title_screen_file_size(path)
	if(!path || !fexists(path))
		return 0
	return length(file(path))

#undef TITLE_SCREEN_MAX_BYTES
