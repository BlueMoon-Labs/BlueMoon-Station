/**
 * Замена /icon для спрайтшитов: описывает иконку и цепочку операций над ней,
 * но ничего не рисует. Рисует потом rust-g (IconForge) - разом по всему листу и
 * в несколько потоков, вместо десятков тысяч DM-овых icon()/Blend().
 *
 * Собирай через uni_icon(), как через BYOND-овский icon().
 * Трансформы называются с маленькой буквы (scale/crop/blend_color), чтобы не
 * путались с одноимёнными процами /icon.
 */
/datum/universal_icon
	var/icon/icon_file
	var/icon_state
	var/dir
	var/frame
	var/datum/icon_transformer/transform

/// Не создавай напрямую, используй uni_icon().
/datum/universal_icon/New(icon/icon_file, icon_state = "", dir = null, frame = null, datum/icon_transformer/transform = null, color = null)
	#ifdef UNIT_TESTS
	// Проверка небыстрая, а падать может только на ошибке разработчика - потому под тестами.
	//
	// Сверяем именно расширение в строковом виде: путь к DMI всегда кончается на .dmi,
	// а собранная в рантайме иконка печатается как "/icon" либо как безымянный
	// RSC-ресурс. Текстовый путь тоже валиден - в таком виде иконка приезжает назад
	// из universal_icon_from_list(), да и rust-g всё равно получает строку.
	if(copytext("[icon_file]", -4) != ".dmi")
		CRASH("FATAL: universal_icon получил icon_file: [icon_file] - в батчёвые спрайтшиты можно отдавать только DMI-файлы, но не /image, /icon и прочие собранные в рантайме иконки.")
	// Стейт уезжает в rust строкой. null там ломает разбор JSON целого шарда, причём
	// сообщение указывает на позицию в строке, а не на спрайт - лучше падать здесь.
	if(!istext(icon_state))
		CRASH("FATAL: universal_icon получил icon_state [isnull(icon_state) ? "null" : icon_state] для [icon_file] - стейт обязан быть строкой.")
	#endif
	src.icon_file = icon_file
	src.icon_state = icon_state
	src.dir = dir
	src.frame = frame
	if(isnull(transform) && !isnull(color) && uppertext(color) != "#FFFFFF")
		var/datum/icon_transformer/new_transform = new()
		new_transform.blend_color(color, ICON_MULTIPLY)
		src.transform = new_transform
	else if(!isnull(transform))
		src.transform = transform
	else
		src.transform = null

/datum/universal_icon/proc/copy()
	RETURN_TYPE(/datum/universal_icon)
	var/datum/universal_icon/new_icon = new(icon_file, icon_state, dir, frame)
	if(!isnull(transform))
		new_icon.transform = transform.copy()
	return new_icon

/datum/universal_icon/proc/blend_color(color, blend_mode)
	if(!transform)
		transform = new
	transform.blend_color(color, blend_mode)
	return src

/datum/universal_icon/proc/blend_icon(datum/universal_icon/icon_object, blend_mode, x = 1, y = 1)
	if(!transform)
		transform = new
	transform.blend_icon(icon_object, blend_mode, x, y)
	return src

/datum/universal_icon/proc/scale(width, height)
	if(!transform)
		transform = new
	transform.scale(width, height)
	return src

/datum/universal_icon/proc/crop(x1, y1, x2, y2)
	if(!transform)
		transform = new
	transform.crop(x1, y1, x2, y2)
	return src

/datum/universal_icon/proc/flip(dir)
	if(!transform)
		transform = new
	transform.flip(dir)
	return src

/datum/universal_icon/proc/rotate(angle)
	if(!transform)
		transform = new
	transform.rotate(angle)
	return src

/datum/universal_icon/proc/shift(dir, offset, wrap = FALSE)
	if(!transform)
		transform = new
	transform.shift(dir, offset, wrap)
	return src

/datum/universal_icon/proc/swap_color(src_color, dst_color)
	if(!transform)
		transform = new
	transform.swap_color(src_color, dst_color)
	return src

/datum/universal_icon/proc/draw_box(color, x1, y1, x2 = x1, y2 = y1)
	if(!transform)
		transform = new
	transform.draw_box(color, x1, y1, x2, y2)
	return src

/datum/universal_icon/proc/map_colors_rgba(rr, rg, rb, ra, gr, gg, gb, ga, br, bg, bb, ba, ar, ag, ab, aa, r0 = 0, g0 = 0, b0 = 0, a0 = 0)
	if(!transform)
		transform = new
	transform.map_colors(rr, rg, rb, ra, gr, gg, gb, ga, br, bg, bb, ba, ar, ag, ab, aa, r0, g0, b0, a0)
	return src

/datum/universal_icon/proc/map_colors_rgb(rr, rg, rb, gr, gg, gb, br, bg, bb, r0 = 0, g0 = 0, b0 = 0)
	if(!transform)
		transform = new
	transform.map_colors(rr, rg, rb, 0, gr, gg, gb, 0, br, bg, bb, 0, 0, 0, 0, 1, r0, g0, b0, 0)
	return src

/**
 * Аналог /icon/proc/ChangeOpacity: домешивает белый с нужной альфой.
 * amount - от 0 до 1.
 */
/datum/universal_icon/proc/change_opacity(amount)
	if(!transform)
		transform = new
	transform.blend_color("#ffffff[num2hex(clamp(amount, 0, 1) * 255, 2)]", ICON_MULTIPLY)
	return src

/datum/universal_icon/proc/to_list()
	RETURN_TYPE(/list)
	return list("icon_file" = "[icon_file]", "icon_state" = icon_state, "dir" = dir, "frame" = frame, "transform" = !isnull(transform) ? transform.to_list() : list())

/datum/universal_icon/proc/to_json()
	return json_encode(to_list())

/// Собирает описание в настоящую /icon средствами DM. Дорого - только для отладки
/// и сверки с rust-путём в тестах.
/datum/universal_icon/proc/to_icon()
	RETURN_TYPE(/icon)
	var/icon/self = icon(src.icon_file, src.icon_state, dir = src.dir, frame = src.frame)
	if(istype(src.transform))
		src.transform.apply(self)
	return self

/proc/universal_icon_from_list(list/input_in)
	RETURN_TYPE(/datum/universal_icon)
	// Копия, потому что icon_transformer_from_list мутирует переданный список.
	var/list/input = input_in.Copy()
	return uni_icon(input["icon_file"], input["icon_state"], input["dir"], input["frame"], icon_transformer_from_list(input["transform"]))

/// Цепочка операций над иконкой. Формат элементов - ровно тот, что ждёт IconForge,
/// см. RUSTG_ICONFORGE_* в code/__DEFINES/rust_g.dm.
/datum/icon_transformer
	var/list/transforms = null

/datum/icon_transformer/New()
	transforms = list()

/// Применяет операции к настоящей /icon средствами DM (для to_icon и тестов).
/datum/icon_transformer/proc/apply(icon/target)
	RETURN_TYPE(/icon)
	for(var/list/transform as anything in src.transforms)
		switch(transform["type"])
			if(RUSTG_ICONFORGE_BLEND_COLOR)
				target.Blend(transform["color"], transform["blend_mode"])
			if(RUSTG_ICONFORGE_BLEND_ICON)
				var/datum/universal_icon/icon_object = transform["icon"]
				if(!istype(icon_object))
					stack_trace("Невалидная иконка в icon_transformer при apply(): [icon_object]")
					continue
				target.Blend(icon_object.to_icon(), transform["blend_mode"], transform["x"], transform["y"])
			if(RUSTG_ICONFORGE_SCALE)
				target.Scale(transform["width"], transform["height"])
			if(RUSTG_ICONFORGE_CROP)
				target.Crop(transform["x1"], transform["y1"], transform["x2"], transform["y2"])
			if(RUSTG_ICONFORGE_MAP_COLORS)
				target.MapColors(
					transform["rr"], transform["rg"], transform["rb"], transform["ra"],
					transform["gr"], transform["gg"], transform["gb"], transform["ga"],
					transform["br"], transform["bg"], transform["bb"], transform["ba"],
					transform["ar"], transform["ag"], transform["ab"], transform["aa"],
					transform["r0"], transform["g0"], transform["b0"], transform["a0"],
				)
			if(RUSTG_ICONFORGE_FLIP)
				target.Flip(transform["dir"])
			if(RUSTG_ICONFORGE_TURN)
				target.Turn(transform["angle"])
			if(RUSTG_ICONFORGE_SHIFT)
				target.Shift(transform["dir"], transform["offset"], transform["wrap"])
			if(RUSTG_ICONFORGE_SWAP_COLOR)
				target.SwapColor(transform["src_color"], transform["dst_color"])
			if(RUSTG_ICONFORGE_DRAW_BOX)
				target.DrawBox(transform["color"], transform["x1"], transform["y1"], transform["x2"], transform["y2"])
	return target

/datum/icon_transformer/proc/copy()
	RETURN_TYPE(/datum/icon_transformer)
	var/datum/icon_transformer/new_transformer = new()
	for(var/list/transform as anything in src.transforms)
		var/list/copied = transform.Copy()
		// Вложенная иконка - датум, Copy() списка отдал бы ту же ссылку.
		if(copied["type"] == RUSTG_ICONFORGE_BLEND_ICON)
			var/datum/universal_icon/nested = copied["icon"]
			if(istype(nested))
				copied["icon"] = nested.copy()
		new_transformer.transforms += list(copied)
	return new_transformer

/datum/icon_transformer/proc/blend_color(color, blend_mode)
	#ifdef UNIT_TESTS
	if(!istext(color))
		CRASH("Невалидный color в blend_color: [color]")
	if(!isnum(blend_mode))
		CRASH("Невалидный blend_mode в blend_color: [blend_mode]")
	#endif
	transforms += list(list("type" = RUSTG_ICONFORGE_BLEND_COLOR, "color" = color, "blend_mode" = blend_mode))

/datum/icon_transformer/proc/blend_icon(datum/universal_icon/icon_object, blend_mode, x = 1, y = 1)
	#ifdef UNIT_TESTS
	// Тип icon_object проверяется позже, в to_list().
	if(!isnum(blend_mode))
		CRASH("Невалидный blend_mode в blend_icon: [blend_mode]")
	if(!isnum(x) || !isnum(y))
		CRASH("Невалидное смещение в blend_icon: [x],[y]")
	#endif
	transforms += list(list("type" = RUSTG_ICONFORGE_BLEND_ICON, "icon" = icon_object, "blend_mode" = blend_mode, "x" = x, "y" = y))

/datum/icon_transformer/proc/scale(width, height)
	#ifdef UNIT_TESTS
	if(!isnum(width) || !isnum(height))
		CRASH("Невалидные аргументы scale: [width],[height]")
	#endif
	transforms += list(list("type" = RUSTG_ICONFORGE_SCALE, "width" = width, "height" = height))

/datum/icon_transformer/proc/crop(x1, y1, x2, y2)
	#ifdef UNIT_TESTS
	if(!isnum(x1) || !isnum(y1) || !isnum(x2) || !isnum(y2))
		CRASH("Невалидные аргументы crop: [x1],[y1],[x2],[y2]")
	#endif
	transforms += list(list("type" = RUSTG_ICONFORGE_CROP, "x1" = x1, "y1" = y1, "x2" = x2, "y2" = y2))

/datum/icon_transformer/proc/flip(dir)
	#ifdef UNIT_TESTS
	if(!isnum(dir))
		CRASH("Невалидный аргумент flip: [dir]")
	#endif
	transforms += list(list("type" = RUSTG_ICONFORGE_FLIP, "dir" = dir))

/datum/icon_transformer/proc/rotate(angle)
	#ifdef UNIT_TESTS
	if(!isnum(angle))
		CRASH("Невалидный аргумент rotate: [angle]")
	#endif
	transforms += list(list("type" = RUSTG_ICONFORGE_TURN, "angle" = angle))

/datum/icon_transformer/proc/shift(dir, offset, wrap = FALSE)
	#ifdef UNIT_TESTS
	if(!isnum(dir) || !isnum(offset) || (wrap != FALSE && wrap != TRUE))
		CRASH("Невалидные аргументы shift: [dir],[offset],[wrap]")
	#endif
	transforms += list(list("type" = RUSTG_ICONFORGE_SHIFT, "dir" = dir, "offset" = offset, "wrap" = wrap))

/datum/icon_transformer/proc/swap_color(src_color, dst_color)
	#ifdef UNIT_TESTS
	if(!istext(src_color) || !istext(dst_color))
		CRASH("Невалидные аргументы swap_color: [src_color],[dst_color]")
	#endif
	transforms += list(list("type" = RUSTG_ICONFORGE_SWAP_COLOR, "src_color" = src_color, "dst_color" = dst_color))

/datum/icon_transformer/proc/draw_box(color, x1, y1, x2 = x1, y2 = y1)
	#ifdef UNIT_TESTS
	if(!isnum(x1) || !isnum(y1) || !isnum(x2) || !isnum(y2))
		CRASH("Невалидные аргументы draw_box: [x1],[y1],[x2],[y2]")
	#endif
	transforms += list(list("type" = RUSTG_ICONFORGE_DRAW_BOX, "color" = color, "x1" = x1, "y1" = y1, "x2" = x2, "y2" = y2))

/datum/icon_transformer/proc/map_colors(rr, rg, rb, ra, gr, gg, gb, ga, br, bg, bb, ba, ar, ag, ab, aa, r0 = 0, g0 = 0, b0 = 0, a0 = 0)
	transforms += list(list(
		"type" = RUSTG_ICONFORGE_MAP_COLORS,
		"rr" = rr, "rg" = rg, "rb" = rb, "ra" = ra,
		"gr" = gr, "gg" = gg, "gb" = gb, "ga" = ga,
		"br" = br, "bg" = bg, "bb" = bb, "ba" = ba,
		"ar" = ar, "ag" = ag, "ab" = ab, "aa" = aa,
		"r0" = r0, "g0" = g0, "b0" = b0, "a0" = a0,
	))

/// Разворачивает вложенные [/datum/universal_icon] в списки, чтобы цепочку можно было
/// закодировать в JSON для rust-g.
/datum/icon_transformer/proc/to_list()
	RETURN_TYPE(/list)
	var/list/transforms_out = list()
	for(var/list/transform as anything in src.transforms)
		// Копия обязательна: ниже мы подменяем в ней датум на список.
		var/list/this_transform = transform.Copy()
		if(transform["type"] == RUSTG_ICONFORGE_BLEND_ICON)
			var/datum/universal_icon/icon_object = this_transform["icon"]
			if(!istype(icon_object))
				stack_trace("Невалидная иконка в icon_transformer при to_list(): [icon_object]")
				continue
			this_transform["icon"] = icon_object.to_list()
		transforms_out += list(this_transform)
	return transforms_out

/// Обратная операция к /datum/icon_transformer/to_list()
/proc/icon_transformer_from_list(list/input)
	RETURN_TYPE(/datum/icon_transformer)
	var/list/transforms = list()
	for(var/list/transform as anything in input)
		var/list/this_transform = transform.Copy()
		if(transform["type"] == RUSTG_ICONFORGE_BLEND_ICON)
			this_transform["icon"] = universal_icon_from_list(transform["icon"])
		transforms += list(this_transform)
	var/datum/icon_transformer/transformer = new()
	transformer.transforms = transforms
	return transformer

/// Готовый трансформер с домешанным цветом.
/proc/color_transform(color = null)
	RETURN_TYPE(/datum/icon_transformer)
	var/datum/icon_transformer/transform = new()
	if(color)
		transform.blend_color(color, ICON_MULTIPLY)
	return transform

/**
 * Размер кадра DMI по пути к файлу - без загрузки иконки в DM.
 *
 * Размер в DMI один на весь файл, так что читать его достаточно раз на файл, а не
 * раз на спрайт. Возвращает list("width" = ..., "height" = ...) либо null, если
 * rust-g не смог прочитать файл (тогда он и отрисовать его не сможет).
 */
/proc/dmi_frame_dimensions(icon_file)
	RETURN_TYPE(/list)
	// Не через rustg_dmi_read_metadata: тот дефайн зовёт json_decode напрямую и
	// падает, если rust вернул текст ошибки вместо JSON.
	var/list/metadata = safe_json_decode(RUSTG_CALL(RUST_G, "dmi_read_metadata")("[icon_file]"), null)
	if(!islist(metadata) || !isnum(metadata["width"]) || !isnum(metadata["height"]))
		return null
	return list("width" = metadata["width"], "height" = metadata["height"])

/**
 * Иконка типа для превью в UI: как атом выглядит "из коробки".
 *
 * GAGS-слоя (SSgreyscale) у нас нет, так что у greyscale-предметов берётся базовый
 * icon_state - ровно как и на старом DM-пути спрайтшитов.
 */
/proc/get_display_icon_for(atom/atom_path)
	RETURN_TYPE(/datum/universal_icon)
	if(!ispath(atom_path, /atom))
		return null
	return uni_icon(initial(atom_path.icon), initial(atom_path.icon_state), color = initial(atom_path.color))
