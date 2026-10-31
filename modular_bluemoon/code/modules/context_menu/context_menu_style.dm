/// Варианты каждой настройки вида меню действий; первый - по умолчанию.
/// Непрозрачность - число в пределах CONTEXT_MENU_OPACITY_*, акцент - свой цвет "#rrggbb" или "" (цвет темы).
GLOBAL_LIST_INIT(context_menu_style_choices, list(
	"renderer" = list("html", "map"),
	"layout" = list("list", "columns", "pills"),
	"theme" = list("dark", "slate", "nanotrasen", "ocean", "forest", "syndicate", "rose", "terminal", "brass", "cult", "mono", "light", "contrast"),
	"font" = list("segoe", "calibri", "candara", "tahoma", "verdana", "arial", "trebuchet", "georgia", "consolas", "pixel"),
	"weight" = list("normal", "medium", "bold"),
	"scale" = list(100, 90, 80, 110, 125, 150, 200),
	"density" = list("compact", "normal", "roomy"),
	"width" = list("auto", "narrow", "wide"),
	"animation" = list("none", "fade", "slide", "zoom", "drop", "cascade"),
	"anim_speed" = list("normal", "fast", "slow"),
	"hints" = list("none", "hover", "inline"),
	"position" = list("right", "left", "center", "above"),
	"icons" = list(TRUE, FALSE),
	"icon_size" = list(16, 24, 32),
	"icon_side" = list("left", "right"),
	"hover" = list("fill", "accent", "outline", "invert"),
	"border" = list(TRUE, FALSE),
	"header" = list(TRUE, FALSE),
	"smooth_hover" = list(FALSE, TRUE),
	"stripe" = list(FALSE, TRUE),
	"shadow" = list(FALSE, TRUE),
	"separators" = list(FALSE, TRUE),
	"caps" = list(FALSE, TRUE),
	"outline" = list(FALSE, TRUE),
	"page_rows" = list(10, 8, 14, 20),
	"text_size" = list(12, 11, 13, 14, 16),
	"hint_style" = list("text", "badge"),
	"header_icon" = list(TRUE, FALSE),
	"offset" = list(4, 12, 24),
	"close_on_move" = list("far", "always", "never"),
	"auto_close" = list(0, 3, 6),
	"danger_order" = list("normal", "bottom"),
	"confirm_danger" = list(FALSE, TRUE),
	"show_examine" = list(TRUE, FALSE),
	"show_point" = list(TRUE, FALSE),
	"intents" = list("submenu", "inline"),
	"admin_pos" = list("bottom", "top", "hidden"),
	"sound" = list("off", "click", "soft"),
))

/// Звуки меню по настройке sound
GLOBAL_LIST_INIT(context_menu_sounds, list(
	"click" = 'sound/machines/click.ogg',
	"soft" = 'sound/machines/terminal_button01.ogg',
))

/**
 * Готовые наборы вида: id -> list("name", "desc", "style"). Набор заменяет весь вид, раскладку ПКМ не трогает.
 * Порядок - порядок кнопок в настройках и в вербе «Вид меню ПКМ».
 */
GLOBAL_LIST_INIT(context_menu_style_presets, list(
	"default" = list("name" = "Стандарт", "desc" = "Обычное меню: Segoe UI, без подсказок управления и анимаций", "style" = list()),
	"tiles" = list("name" = "Плашки", "desc" = "Действия плашками в несколько рядов, крупные значки", "style" = list(
		"layout" = "pills", "theme" = "slate", "icon_size" = 24, "hints" = "hover", "hover" = "outline",
	)),
	"columns" = list("name" = "Две колонки", "desc" = "Короткое меню в два столбца", "style" = list(
		"layout" = "columns", "hints" = "hover", "width" = "wide",
	)),
	"minimal" = list("name" = "Минимализм", "desc" = "Без шапки, значков, рамки и хоткеев", "style" = list(
		"header" = FALSE, "icons" = FALSE, "hints" = "none", "border" = FALSE, "theme" = "mono", "hover" = "invert",
	)),
	"readable" = list("name" = "Крупно и чётко", "desc" = "Большой контрастный текст, хоткеи в строке", "style" = list(
		"theme" = "contrast", "font" = "verdana", "scale" = 150, "density" = "roomy", "hints" = "inline",
		"opacity" = 100, "stripe" = TRUE, "weight" = "medium", "icon_size" = 24,
	)),
	"retro" = list("name" = "Ретро", "desc" = "Пиксельный терминал с каскадом строк", "style" = list(
		"theme" = "terminal", "font" = "consolas", "animation" = "cascade", "caps" = TRUE, "separators" = TRUE, "hover" = "invert",
	)),
	"nanotrasen" = list("name" = "Нанотрейзен", "desc" = "Синий корпоративный, выезд снизу, тень", "style" = list(
		"theme" = "nanotrasen", "density" = "normal", "animation" = "slide", "smooth_hover" = TRUE, "stripe" = TRUE, "hover" = "accent",
	)),
	"syndicate" = list("name" = "Синдикат", "desc" = "Красный, шторка, хоткеи в строке", "style" = list(
		"theme" = "syndicate", "font" = "trebuchet", "animation" = "drop", "stripe" = TRUE, "weight" = "medium",
	)),
	"cult" = list("name" = "Культ", "desc" = "Кровавый, медленный каскад, обводка", "style" = list(
		"theme" = "cult", "font" = "georgia", "animation" = "cascade", "anim_speed" = "slow", "outline" = TRUE, "smooth_hover" = TRUE,
	)),
	"brass" = list("name" = "Латунь", "desc" = "Шестерёнки и шторка, разделители", "style" = list(
		"theme" = "brass", "font" = "georgia", "animation" = "drop", "separators" = TRUE,
	)),
	"light" = list("name" = "Светлое", "desc" = "Светлый фон, просторные строки", "style" = list(
		"theme" = "light", "density" = "normal", "opacity" = 100, "hover" = "accent",
	)),
	"speedrun" = list("name" = "Быстро", "desc" = "Мельче, 20 пунктов на странице, без значков", "style" = list(
		"page_rows" = 20, "hints" = "none", "icons" = FALSE, "scale" = 90,
	)),
))

/// Цвета тем: фон шапки и строк, строка текущего интента, наведение, тексты, админ-пункт, плашка хоткея, рамка, акцент (полоска), обводка текста
GLOBAL_LIST_INIT(context_menu_themes, list(
	"dark" = list(
		"header_bg" = "#121218", "header_text" = "#ffffff", "mode_text" = "#6f7488",
		"row_bg" = "#1d1d26", "current_bg" = "#24324a", "hover_bg" = "#454566",
		"text" = "#e8e8e8", "danger" = "#ff8a80", "service" = "#9aa0b4",
		"admin_text" = "#ffc46b", "admin_bg" = "#2a2218",
		"hint_bg" = "#121218", "hint_text" = "#8a8fa3", "border" = "#4a4a66", "accent" = "#7c8cff", "outline" = "#000000",
	),
	"slate" = list(
		"header_bg" = "#1e232b", "header_text" = "#f2f4f8", "mode_text" = "#7c8696",
		"row_bg" = "#2a303a", "current_bg" = "#34404f", "hover_bg" = "#3f4b5c",
		"text" = "#e3e7ee", "danger" = "#ff8f8f", "service" = "#9aa4b4",
		"admin_text" = "#ffc46b", "admin_bg" = "#3a3226",
		"hint_bg" = "#1e232b", "hint_text" = "#8c96a6", "border" = "#46505f", "accent" = "#5fa8ff", "outline" = "#000000",
	),
	"ocean" = list(
		"header_bg" = "#06202a", "header_text" = "#e0fbff", "mode_text" = "#5f9aa8",
		"row_bg" = "#0b2d3a", "current_bg" = "#0f4757", "hover_bg" = "#156478",
		"text" = "#d4f3fa", "danger" = "#ff9a8a", "service" = "#86b9c6",
		"admin_text" = "#ffd27a", "admin_bg" = "#2d2a1a",
		"hint_bg" = "#06202a", "hint_text" = "#7fb3c0", "border" = "#1d6d80", "accent" = "#38d9c0", "outline" = "#000000",
	),
	"forest" = list(
		"header_bg" = "#13200f", "header_text" = "#eef6e4", "mode_text" = "#7b9468",
		"row_bg" = "#1b2c15", "current_bg" = "#29421f", "hover_bg" = "#38592a",
		"text" = "#e2eed6", "danger" = "#ff9b7a", "service" = "#9db389",
		"admin_text" = "#ffd27a", "admin_bg" = "#2f2a16",
		"hint_bg" = "#13200f", "hint_text" = "#93ab80", "border" = "#3f6430", "accent" = "#8fd16a", "outline" = "#000000",
	),
	"rose" = list(
		"header_bg" = "#2a1420", "header_text" = "#fff0f6", "mode_text" = "#a07588",
		"row_bg" = "#36192a", "current_bg" = "#4f2440", "hover_bg" = "#6a3055",
		"text" = "#fde4ef", "danger" = "#ff7a8f", "service" = "#c79ab0",
		"admin_text" = "#ffd27a", "admin_bg" = "#3a2a1a",
		"hint_bg" = "#2a1420", "hint_text" = "#c08fa6", "border" = "#7a3a5f", "accent" = "#ff7ab8", "outline" = "#000000",
	),
	"mono" = list(
		"header_bg" = "#161616", "header_text" = "#ffffff", "mode_text" = "#7a7a7a",
		"row_bg" = "#202020", "current_bg" = "#303030", "hover_bg" = "#404040",
		"text" = "#e6e6e6", "danger" = "#ffffff", "service" = "#a0a0a0",
		"admin_text" = "#ffffff", "admin_bg" = "#2a2a2a",
		"hint_bg" = "#161616", "hint_text" = "#8c8c8c", "border" = "#4a4a4a", "accent" = "#bdbdbd", "outline" = "#000000",
	),
	"nanotrasen" = list(
		"header_bg" = "#0b1f3a", "header_text" = "#ffffff", "mode_text" = "#7d9cc7",
		"row_bg" = "#12294a", "current_bg" = "#1d4275", "hover_bg" = "#2b5a9c",
		"text" = "#e6f0ff", "danger" = "#ff9a8a", "service" = "#8fb0d8",
		"admin_text" = "#ffd27a", "admin_bg" = "#2d2a1a",
		"hint_bg" = "#0b1f3a", "hint_text" = "#9db8dd", "border" = "#3d6db3", "accent" = "#4ea1ff", "outline" = "#000000",
	),
	"syndicate" = list(
		"header_bg" = "#1a0606", "header_text" = "#ffffff", "mode_text" = "#9a6a6a",
		"row_bg" = "#240b0b", "current_bg" = "#4a1414", "hover_bg" = "#6b1d1d",
		"text" = "#f2e6e6", "danger" = "#ff5c5c", "service" = "#b08a8a",
		"admin_text" = "#ffc46b", "admin_bg" = "#2e2010",
		"hint_bg" = "#1a0606", "hint_text" = "#c49a9a", "border" = "#8a2020", "accent" = "#ff3b3b", "outline" = "#000000",
	),
	"terminal" = list(
		"header_bg" = "#020a02", "header_text" = "#9dff9d", "mode_text" = "#2f8f2f",
		"row_bg" = "#041204", "current_bg" = "#0a2a0a", "hover_bg" = "#145214",
		"text" = "#6dff6d", "danger" = "#ffcf4d", "service" = "#3fae3f",
		"admin_text" = "#e0ff4d", "admin_bg" = "#0f1a04",
		"hint_bg" = "#020a02", "hint_text" = "#3fae3f", "border" = "#1f7a1f", "accent" = "#6dff6d", "outline" = "#000000",
	),
	"brass" = list(
		"header_bg" = "#2a1d0c", "header_text" = "#fff0cc", "mode_text" = "#a07f45",
		"row_bg" = "#3a2810", "current_bg" = "#5a3e15", "hover_bg" = "#7a5620",
		"text" = "#f5deb0", "danger" = "#ff9b6b", "service" = "#c9a46a",
		"admin_text" = "#fff2a8", "admin_bg" = "#4a3a10",
		"hint_bg" = "#2a1d0c", "hint_text" = "#c9a46a", "border" = "#b8862f", "accent" = "#ffcc55", "outline" = "#000000",
	),
	"cult" = list(
		"header_bg" = "#120208", "header_text" = "#ffe0ec", "mode_text" = "#8a4a63",
		"row_bg" = "#1c0410", "current_bg" = "#3d0a22", "hover_bg" = "#5e1034",
		"text" = "#ffd6e6", "danger" = "#ff4d6d", "service" = "#b07a90",
		"admin_text" = "#ffc46b", "admin_bg" = "#2a1a10",
		"hint_bg" = "#120208", "hint_text" = "#b07a90", "border" = "#9b1048", "accent" = "#ff2d6a", "outline" = "#000000",
	),
	"light" = list(
		"header_bg" = "#d9dce4", "header_text" = "#101218", "mode_text" = "#6a7088",
		"row_bg" = "#f2f3f7", "current_bg" = "#cfe0ff", "hover_bg" = "#bcc6dc",
		"text" = "#1c1e26", "danger" = "#c62828", "service" = "#5c6378",
		"admin_text" = "#8a5a00", "admin_bg" = "#fff0cc",
		"hint_bg" = "#d9dce4", "hint_text" = "#4a5068", "border" = "#9aa0b4", "accent" = "#3d6db3", "outline" = "#ffffff",
	),
	"contrast" = list(
		"header_bg" = "#000000", "header_text" = "#ffffff", "mode_text" = "#c0c0c0",
		"row_bg" = "#000000", "current_bg" = "#003a8c", "hover_bg" = "#0050c8",
		"text" = "#ffffff", "danger" = "#ff4040", "service" = "#c0c0c0",
		"admin_text" = "#ffd400", "admin_bg" = "#000000",
		"hint_bg" = "#000000", "hint_text" = "#ffffff", "border" = "#ffffff", "accent" = "#ffd400", "outline" = "#000000",
	),
))

/// Гладкие шрифты: id -> имя для css. Ширины букв - в context_menu_smooth_text_width().
/// Calibri и Candara сглаживаются на любом кегле; Tahoma, Verdana и Segoe UI по правилам самих шрифтов
/// мельче ~16px экрана рисуются без сглаживания, «пиксельно».
GLOBAL_LIST_INIT(context_menu_font_families, list(
	"segoe" = "Segoe UI",
	"calibri" = "Calibri",
	"candara" = "Candara",
	"tahoma" = "Tahoma",
	"verdana" = "Verdana",
))

/// Шрифты, которые меню умеет рисовать на карте (есть таблица ширин); остальные - только окном
GLOBAL_LIST_INIT(context_menu_map_fonts, list("calibri", "candara", "tahoma", "verdana", "segoe", "pixel"))

/// Кегль шрифта относительно CONTEXT_MENU_FONT_PX: у Calibri и Candara строчные мельче, им нужен кегль крупнее для той же высоты букв
/proc/context_menu_font_size_factor(font)
	switch(font)
		if("calibri")
			return 1.15
		if("candara")
			return 1.1
	return 1

/// Добавка к высоте строки по плотности, в пикселях при 100%
/proc/context_menu_density_padding(density)
	switch(density)
		if("normal")
			return 2
		if("roomy")
			return 4
	return 0

/datum/preferences/proc/context_menu_option(key)
	return context_menu_style_option(context_menu_style, key)

/// Значение настройки из списка настроек игрока, без него или без ключа - по умолчанию
/proc/context_menu_style_option(list/style, key)
	var/list/choices = GLOB.context_menu_style_choices[key]
	var/value = style?[key]
	if(key == "opacity")
		return isnum(value) ? value : CONTEXT_MENU_OPACITY_DEFAULT
	if(key == "accent")
		return istext(value) ? value : ""
	if(!choices)
		return null
	return (value in choices) ? value : choices[1]

/// Значение настройки, приведённое к её типу, или null, если такого варианта нет
/proc/context_menu_style_value(key, value)
	if(key == "opacity")
		if(istext(value))
			value = text2num(value)
		return isnum(value) ? clamp(round(value), CONTEXT_MENU_OPACITY_MIN, 100) : null
	if(key == "accent")
		if(!istext(value))
			return null
		if(!value)
			return ""
		var/static/regex/hex_color = regex(@"^#[0-9a-fA-F]{6}$")
		return hex_color.Find(value) ? lowertext(value) : null
	var/list/choices = GLOB.context_menu_style_choices[key]
	if(!choices)
		return null
	if(isnum(choices[1]) && istext(value))
		value = text2num(value)
	return (value in choices) ? value : null

/// Из сейва остаются только известные настройки с допустимыми значениями
/proc/sanitize_context_menu_style(list/style)
	. = list()
	if(!islist(style))
		return
	for(var/key in style)
		if(!istext(key))
			continue
		var/value = context_menu_style_value(key, style[key])
		if(!isnull(value))
			.[key] = value

/// Вид меню действий из настроек игры. Без value - булева настройка переключается. Открытое меню сразу перерисовывается.
/datum/preferences/proc/set_context_menu_style(key, value)
	if(isnull(value) && length(GLOB.context_menu_style_choices[key]) == 2 && isnum(GLOB.context_menu_style_choices[key][1]))
		value = !context_menu_option(key)
	value = context_menu_style_value(key, value)
	if(isnull(value))
		return FALSE
	LAZYINITLIST(context_menu_style)
	context_menu_style[key] = value
	save_pref_var("context_menu_style")
	GLOB.context_menu_stats.record_change(parent, key, value)
	var/datum/context_menu/menu = parent?.mob?.active_context_menu
	menu?.render()
	return TRUE

/// Сброс вида меню к умолчанию
/datum/preferences/proc/reset_context_menu_style()
	context_menu_style = null
	save_pref_var("context_menu_style")
	GLOB.context_menu_stats.record_change(parent, "вид", "по умолчанию")
	parent?.mob?.active_context_menu?.render()

/// Готовый набор вида целиком: всё, чего в наборе нет, - по умолчанию
/datum/preferences/proc/apply_context_menu_preset(preset_id)
	var/list/preset = GLOB.context_menu_style_presets[preset_id]
	if(!preset)
		return FALSE
	context_menu_style = sanitize_context_menu_style(preset["style"])
	save_pref_var("context_menu_style")
	GLOB.context_menu_stats.record_change(parent, "набор", preset_id)
	parent?.mob?.active_context_menu?.render()
	return TRUE

/// Набор, с которым вид совпадает, или null, если игрок что-то поменял сам
/datum/preferences/proc/current_context_menu_preset()
	for(var/preset_id in GLOB.context_menu_style_presets)
		var/list/preset_style = sanitize_context_menu_style(GLOB.context_menu_style_presets[preset_id]["style"])
		var/matches = TRUE
		for(var/key in GLOB.context_menu_style_choices + CONTEXT_MENU_FREE_OPTIONS)
			if(context_menu_style_option(preset_style, key) != context_menu_option(key))
				matches = FALSE
				break
		if(matches)
			return preset_id

/client/verb/choose_context_menu_preset()
	set category = "OOC"
	set name = "Вид меню ПКМ"
	set desc = "Готовые наборы вида меню действий: тема, шрифт, анимация. Тонкая настройка - в настройках игры, раздел «Меню ПКМ»."
	if(!prefs)
		return
	var/list/options = list()
	for(var/preset_id in GLOB.context_menu_style_presets)
		var/list/preset = GLOB.context_menu_style_presets[preset_id]
		options["[preset["name"]] - [preset["desc"]]"] = preset_id
	options += CONTEXT_MENU_SETTINGS_CHOICE
	var/choice = tgui_input_list(mob, "Набор меняет весь вид меню действий; раскладку ПКМ не трогает.", "Вид меню ПКМ", options)
	if(!choice || QDELETED(src))
		return
	if(choice == CONTEXT_MENU_SETTINGS_CHOICE)
		prefs.ui_interact(mob)
		return
	if(prefs.apply_context_menu_preset(options[choice]))
		to_chat(src, span_notice("Вид меню действий: [GLOB.context_menu_style_presets[options[choice]]["name"]]. Открытое меню уже перерисовано."))

/// Ширина текста гладким шрифтом в сотых долях кегля (замер MeasureText клиента при 100px); жирный шире на десятую
/proc/context_menu_smooth_text_width(text, bold = FALSE, font = "calibri")
	var/static/list/tables
	if(!tables)
		tables = list()
		var/list/sources = list(
			"tahoma" = list(
				"28" = "'",
				"30" = "il",
				"31" = " ",
				"37" = "j",
				"40" = ",.",
				"42" = "f",
				"44" = "t!",
				"47" = ":;",
				"48" = "r-",
				"50" = "I",
				"51" = "()/\[\\]|",
				"53" = "\"",
				"55" = "гJ",
				"59" = "sz",
				"61" = "зсc",
				"62" = "т",
				"63" = "э?",
				"64" = "{}",
				"66" = "кухLkvxy",
				"67" = "Гь",
				"69" = "F",
				"70" = "авеёяae",
				"71" = "З",
				"72" = "очo",
				"73" = "РбP0123456789*_`",
				"74" = "длрSZbdghnpqu",
				"75" = "ЕЁийнпE",
				"76" = "цъ«»",
				"77" = "УХЬXY",
				"78" = "БВТBKT",
				"79" = "V",
				"80" = "АКСЭAC",
				"81" = "Я",
				"83" = "R",
				"85" = "Чм",
				"87" = "U",
				"89" = "ИЙGN",
				"90" = "ЛНПDH&",
				"91" = "ДЦ",
				"92" = "Ъы",
				"94" = "ОOQ",
				"97" = "ж#+<=>",
				"99" = "w",
				"100" = "Ф",
				"101" = "фю",
				"102" = "МM",
				"104" = "ш",
				"105" = "Ыщ",
				"109" = "…",
				"112" = "m",
				"119" = "Ж",
				"120" = "W",
				"121" = "@",
				"125" = "Ш",
				"127" = "ЩЮ",
				"130" = "%",
				"152" = "№",
			),
			"verdana" = list(
				"35" = " ",
				"36" = "il'",
				"46" = "j",
				"47" = "f",
				"48" = ",.",
				"52" = "t!",
				"57" = "Ir",
				"60" = "J()-/:;\[\\]|",
				"61" = "\"",
				"63" = "г",
				"66" = "т",
				"69" = "cs",
				"70" = "зz",
				"71" = "с",
				"73" = "э?",
				"74" = "L",
				"75" = "Г",
				"76" = "ьF",
				"78" = "T",
				"79" = "веёкухekvxy",
				"80" = "РаяPa",
				"81" = "очo",
				"82" = "ЗТУбY",
				"83" = "длрbdgpq",
				"84" = "ЕЁEhnu{}",
				"85" = "ийнпъ0123456789*_`",
				"86" = "ц«»",
				"90" = "SZ",
				"91" = "АБВХЬABVX",
				"92" = "КKR",
				"93" = "СЭмC",
				"94" = "Я",
				"95" = "Ч",
				"97" = "U&",
				"98" = "Л",
				"99" = "ДN",
				"100" = "ИЙНПH",
				"101" = "Ц",
				"102" = "D",
				"103" = "G",
				"104" = "Ъ",
				"105" = "ОOQ",
				"106" = "жы",
				"109" = "Фw#+<=>…",
				"112" = "МфюM",
				"117" = "ш",
				"118" = "щ",
				"122" = "Ы",
				"129" = "Жm",
				"132" = "W",
				"133" = "@",
				"137" = "Ш",
				"138" = "Ю",
				"139" = "Щ",
				"143" = "%",
				"156" = "№",
			),
			"calibri" = list(
				"29" = "'",
				"31" = "il",
				"32" = "j",
				"33" = ",",
				"34" = "I.",
				"36" = ":;",
				"39" = "f`",
				"40" = "()",
				"41" = "t-\[]",
				"42" = "J{}",
				"43" = "!",
				"46" = "гr",
				"51" = "/\\",
				"52" = "тs",
				"53" = "z\"",
				"55" = "с",
				"56" = "зLc",
				"57" = "Г",
				"58" = "хx",
				"59" = "э",
				"60" = "уk",
				"61" = "FSvy|",
				"62" = "кчьZ?",
				"63" = "Зя",
				"64" = "авag",
				"65" = "ЕЁТEY",
				"66" = "еёe#*+<=>_",
				"67" = "T0123456789",
				"68" = "л«»",
				"69" = "РХпKPX",
				"70" = "СУорbdhnopqu",
				"71" = "ЬбнъC",
				"72" = "БВКЭийцBR",
				"74" = "ЧЯ",
				"76" = "V",
				"77" = "АдA",
				"81" = "Л",
				"82" = "ЪD",
				"83" = "НПфH",
				"84" = "G",
				"85" = "ИЙЦU",
				"86" = "ДN",
				"88" = "ОO",
				"89" = "ыQ",
				"90" = "м",
				"91" = "&",
				"92" = "ж…",
				"93" = "Ф",
				"95" = "%",
				"96" = "юw",
				"97" = "ш",
				"100" = "щ",
				"101" = "Ы",
				"106" = "m",
				"107" = "Ж",
				"114" = "МM",
				"115" = "Ш",
				"117" = "Ю",
				"118" = "ЩW",
				"119" = "@",
				"136" = "№",
				"30" = " ",
			),
			"candara" = list(
				"29" = " ij",
				"30" = "l",
				"34" = "!',-.:;|",
				"36" = "/\\",
				"37" = "I`",
				"41" = "f",
				"47" = "r1)?\[]{}",
				"48" = "t(",
				"51" = "г",
				"55" = "J",
				"56" = "s",
				"58" = "з",
				"59" = "т",
				"60" = "сc\"«»",
				"61" = "z2",
				"62" = "уьэy",
				"63" = "ч7",
				"64" = "Гv",
				"65" = "акFLak35",
				"66" = "вл",
				"67" = "пхяx#%*+<=>_",
				"68" = "ТУеёSTe",
				"69" = "ЕЁнEZ",
				"70" = "ий",
				"71" = "Зцu4",
				"72" = "ghn",
				"73" = "СCYd0689",
				"74" = "РХЭборPVXbopq",
				"75" = "дъ",
				"76" = "БЬ",
				"78" = "ВB",
				"79" = "ЯK",
				"80" = "К",
				"81" = "ЧR",
				"82" = "АЛA",
				"83" = "ПG",
				"85" = "ЦыD",
				"86" = "Д",
				"87" = "НH",
				"89" = "Ъф",
				"90" = "ИЙN",
				"91" = "ФмU&",
				"92" = "О",
				"93" = "OQ",
				"95" = "ж",
				"99" = "ю",
				"100" = "ш",
				"102" = "w",
				"105" = "Ы",
				"106" = "щ",
				"109" = "m",
				"114" = "ЖМM",
				"118" = "W",
				"119" = "Ш",
				"122" = "Щ",
				"123" = "Ю",
				"133" = "…",
				"134" = "@№",
			),
			"segoe" = list(
				"27" = " ",
				"29" = ",.:;",
				"31" = "'",
				"32" = "ijl|",
				"35" = "I",
				"36" = "`",
				"38" = "!",
				"40" = "()\[]{}",
				"42" = "Jf",
				"45" = "t",
				"46" = "r",
				"50" = "\\",
				"51" = "г",
				"52" = "\"/",
				"53" = "-",
				"55" = "т*_",
				"56" = "s",
				"59" = "з",
				"60" = "z?",
				"61" = "схэcx",
				"63" = "ГL",
				"64" = "уvy",
				"65" = "F",
				"66" = "кk",
				"67" = "ЕЁьяE«»",
				"68" = "аa",
				"70" = "Твеёлe",
				"71" = "S",
				"72" = "З0123456789",
				"73" = "дT",
				"74" = "РPY",
				"75" = "Учhnu",
				"76" = "БВBZ",
				"77" = "КЬбийнпK",
				"78" = "ХорCXbdgopq",
				"79" = "Яъ#",
				"80" = "цR",
				"82" = "СЭ",
				"83" = "V",
				"86" = "АA",
				"88" = "Ч",
				"89" = "Л",
				"91" = "фGU+<=>",
				"92" = "Д",
				"93" = "мD",
				"94" = "НЪыH",
				"95" = "П",
				"96" = "w",
				"97" = "Ф…",
				"99" = "ЦжN",
				"100" = "ИЙОOQ",
				"104" = "Ы",
				"106" = "ш&",
				"108" = "ю",
				"109" = "%",
				"110" = "щ",
				"115" = "Жm",
				"119" = "МM",
				"124" = "W",
				"126" = "Ш",
				"127" = "@",
				"130" = "Щ",
				"135" = "Ю",
				"149" = "№",
			),
		)
		for(var/font_id in sources)
			tables[font_id] = context_menu_glyph_table(sources[font_id])
	var/list/glyph_widths = tables[font] || tables["calibri"]
	. = 0
	for(var/i in 1 to length_char(text))
		. += glyph_widths[copytext_char(text, i, i + 1)] || 80
	if(bold)
		. *= 1.1
