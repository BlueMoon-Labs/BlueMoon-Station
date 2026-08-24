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
			previous_icon = new(previous_path)
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

	icon = new(fcopy_rsc(file_path))

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
				if(splash_turf)
					splash_turf.icon = icon

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
	splash_turf = SStitle.splash_turf
	file_path = SStitle.file_path
	previous_icon = SStitle.previous_icon

	// Recover the sound path
	if(fexists("data/previous_title_sound.dat"))
		sound_path = file2text("data/previous_title_sound.dat")

/// Вес файла заставки в байтах, 0 если файла нет. Отдельным проком: `length()` на /file
/// читается неочевидно, а место у него ровно одно - решение "разворачивать или нет".
/proc/title_screen_file_size(path)
	if(!path || !fexists(path))
		return 0
	return length(file(path))

#undef TITLE_SCREEN_MAX_BYTES
