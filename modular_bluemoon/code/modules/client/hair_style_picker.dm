// Хейр пикер перенос с моего старого пра, немного доработан в плане производительности. Один раз рендерим лысую куклу, после чего берем листы причесок и раскидываем по слотам.

#define HAIR_PICKER_TAB_HAIR "hair"
#define HAIR_PICKER_TAB_FACIAL "facial"
#define HAIR_PICKER_TAB_GRAD "grad"

#define HAIR_PICKER_MODE_PREFS 1
#define HAIR_PICKER_MODE_MIRROR 2
#define HAIR_PICKER_MODE_SCISSORS 3
#define HAIR_PICKER_MODE_RAZOR 4
#define HAIR_PICKER_MODE_CUSTOM 5

#define HAIR_PICKER_PAGE_SIZE 28
#define HAIR_PICKER_COLS 4

#define HAIR_PICKER_PAD 4

GLOBAL_LIST_EMPTY(hair_style_pickers)

// В сейве храним отдельные массивы имён для каждой вкладки.
/proc/sanitize_hair_style_favorites(candidate)
	var/list/stored = islist(candidate) ? candidate : list()
	var/list/sanitized = list()
	for(var/style_tab in list(HAIR_PICKER_TAB_HAIR, HAIR_PICKER_TAB_FACIAL, HAIR_PICKER_TAB_GRAD))
		var/list/styles = stored[style_tab]
		var/list/valid_styles = list()
		if(islist(styles) && !is_assoc_list(styles))
			for(var/style_name in styles)
				if(istext(style_name) && length(style_name))
					valid_styles |= style_name
		sanitized[style_tab] = valid_styles
	return sanitized

/datum/hair_style_picker
	/// Делаем все через ключи, в данном случае сикей
	var/owner_ckey
	var/mode = HAIR_PICKER_MODE_PREFS
	var/datum/preferences/prefs
	var/mob/living/carbon/human/target
	var/atom/movable/check_atom
	var/apply_sound
	// Способности могут разрешать выбор цвета без предмета-красителя.
	var/allow_color_without_spray = FALSE
	// Цвета для предпросмотра до нажатия Apply; не записываются в настройки или предмет.
	var/preview_hair_color
	var/preview_facial_color
	var/preview_grad_color
	// Обработчик получает выбранный стиль, вкладку и цвет, возвращает TRUE после успешного применения.
	var/datum/callback/apply_callback
	var/applying = FALSE
	var/list/allowed_tabs = list()
	var/tab = HAIR_PICKER_TAB_HAIR
	var/search = ""
	var/favorites_only = FALSE
	var/page = 1
	var/selected
	var/list/base_cache = list()
	// Положение исходного спрайта на расширенном холсте для каждого направления.
	var/list/base_offsets = list()
	var/render_dir = SOUTH
	var/is_taur = FALSE
	var/img_w = 40
	var/img_h = 40
	var/portrait_width = 40
	var/portrait_rows = 19
	var/build_attempts = 0 // попытка построить базу...
	var/sheet_cache_key
	var/sheet_b64
	var/sheet_cell_w = 32
	var/sheet_cell_h = 32
	var/preview_cache_key
	var/list/preview_portraits = list()
	var/preview_full_b64
	var/cached_list_tab
	var/list/cached_list

/datum/preferences/proc/open_hair_style_picker(mob/user, start_tab)
	if(!user?.client)
		return
	var/datum/hair_style_picker/picker = create_hair_style_picker(user)
	picker.setup_prefs(src, start_tab, user)
	picker.finalize(user)

/proc/open_mirror_hair_picker(mob/user, mob/living/carbon/human/subject, atom/movable/mirror)
	if(!user?.client || !subject?.dna)
		return FALSE
	var/datum/hair_style_picker/picker = create_hair_style_picker(user)
	picker.setup_live(user, subject, mirror, HAIR_PICKER_MODE_MIRROR, null)
	return picker.finalize(user)

/proc/open_scissors_hair_picker(mob/user, mob/living/carbon/human/subject, obj/item/razor/scissors/scissors)
	if(!user?.client || !subject?.dna)
		return FALSE
	var/datum/hair_style_picker/picker = create_hair_style_picker(user)
	picker.setup_live(user, subject, scissors, HAIR_PICKER_MODE_SCISSORS, 'modular_bluemoon/krashly/sound/scissors.ogg')
	return picker.finalize(user)

/proc/open_razor_hair_picker(mob/user, mob/living/carbon/human/subject, obj/item/razor/straight_razor/razor)
	if(!user?.client || !subject?.dna)
		return FALSE
	var/datum/hair_style_picker/picker = create_hair_style_picker(user)
	picker.setup_live(user, subject, razor, HAIR_PICKER_MODE_RAZOR, 'modular_bluemoon/krashly/sound/straight_razor.ogg')
	return picker.finalize(user)

// Выбор для других инструментов и способностей с собственными условиями применения.
/proc/open_live_hair_style_picker(mob/user, mob/living/carbon/human/subject, atom/movable/source, list/tabs, datum/callback/on_apply, allow_color_without_spray = FALSE)
	if(!user?.client || !subject?.dna || QDELETED(source))
		return FALSE
	var/datum/hair_style_picker/picker = create_hair_style_picker(user)
	picker.setup_live(user, subject, source, HAIR_PICKER_MODE_CUSTOM, null)
	picker.allowed_tabs = tabs & picker.allowed_tabs
	if(length(picker.allowed_tabs))
		picker.tab = picker.allowed_tabs[1]
		picker.selected = picker.default_selection()
	picker.apply_callback = on_apply
	picker.allow_color_without_spray = allow_color_without_spray
	return picker.finalize(user)

/proc/create_hair_style_picker(mob/user)
	var/picker_key = user.ckey || REF(user)
	var/datum/hair_style_picker/old = GLOB.hair_style_pickers[picker_key]
	if(old)
		qdel(old)
	var/datum/hair_style_picker/picker = new
	picker.owner_ckey = picker_key
	return picker

/datum/hair_style_picker/proc/setup_prefs(datum/preferences/new_prefs, start_tab, mob/user)
	mode = HAIR_PICKER_MODE_PREFS
	prefs = new_prefs
	allowed_tabs = list()
	var/list/species_traits = prefs?.pref_species?.species_traits || list()
	if(HAIR in species_traits)
		allowed_tabs += HAIR_PICKER_TAB_HAIR
	if(FACEHAIR in species_traits)
		allowed_tabs += HAIR_PICKER_TAB_FACIAL
	if(HAIR in species_traits)
		allowed_tabs += HAIR_PICKER_TAB_GRAD
	if(!length(allowed_tabs))
		return
	tab = (start_tab in allowed_tabs) ? start_tab : allowed_tabs[1]
	selected = default_selection()

/datum/hair_style_picker/proc/setup_live(mob/user, mob/living/carbon/human/new_target, atom/movable/new_check, new_mode, sound_file)
	mode = new_mode
	target = new_target
	check_atom = new_check
	apply_sound = sound_file
	allowed_tabs = list()
	var/list/species_traits = target?.dna?.species?.species_traits || list()
	switch(mode)
		if(HAIR_PICKER_MODE_MIRROR)
			if(HAIR in species_traits)
				allowed_tabs += HAIR_PICKER_TAB_HAIR
			if((FACEHAIR in species_traits) && target.gender != FEMALE)
				allowed_tabs += HAIR_PICKER_TAB_FACIAL
			tab = HAIR_PICKER_TAB_HAIR
		if(HAIR_PICKER_MODE_SCISSORS)
			if(HAIR in species_traits)
				allowed_tabs += HAIR_PICKER_TAB_HAIR
			tab = HAIR_PICKER_TAB_HAIR
		if(HAIR_PICKER_MODE_RAZOR)
			if(FACEHAIR in species_traits)
				allowed_tabs += HAIR_PICKER_TAB_FACIAL
			tab = HAIR_PICKER_TAB_FACIAL
		if(HAIR_PICKER_MODE_CUSTOM)
			if(HAIR in species_traits)
				allowed_tabs += HAIR_PICKER_TAB_HAIR
			if(FACEHAIR in species_traits)
				allowed_tabs += HAIR_PICKER_TAB_FACIAL
			if(HAIR in species_traits)
				allowed_tabs += HAIR_PICKER_TAB_GRAD
	if(!length(allowed_tabs))
		return
	if(!(tab in allowed_tabs))
		tab = allowed_tabs[1]
	selected = default_selection()

/datum/hair_style_picker/proc/finalize(mob/user)
	if(!length(allowed_tabs))
		qdel(src)
		return FALSE
	GLOB.hair_style_pickers[owner_ckey] = src
	ui_interact(user)
	return TRUE

/datum/hair_style_picker/Destroy(force, ...)
	SStgui.close_uis(src)
	if(GLOB.hair_style_pickers[owner_ckey] == src)
		GLOB.hair_style_pickers -= owner_ckey
	base_cache = null
	base_offsets = null
	sheet_b64 = null
	preview_portraits = null
	preview_full_b64 = null
	cached_list = null
	prefs = null
	target = null
	check_atom = null
	apply_sound = null
	apply_callback = null
	return ..()


/datum/hair_style_picker/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HairStylePicker")
		ui.open()

/datum/hair_style_picker/ui_state(mob/user)
	return GLOB.always_state

/datum/hair_style_picker/ui_status(mob/user, datum/ui_state/state)
	. = ..()
	if(. != UI_INTERACTIVE)
		return
	if(!check_atom)
		return
	if(QDELETED(check_atom) || !user?.canUseTopic(check_atom, BE_CLOSE, FALSE, NO_TK, TRUE, TRUE))
		. = UI_CLOSE

/datum/hair_style_picker/ui_close(mob/user)
	if(QDELETED(src))
		return
	addtimer(CALLBACK(src, PROC_REF(destroy_if_idle)), 1 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

/datum/hair_style_picker/proc/destroy_if_idle()
	if(QDELETED(src) || applying)
		return
	if(length(SStgui.get_all_open_uis(src)))
		return
	qdel(src)

/datum/hair_style_picker/proc/can_preview_full_body(mob/user)
	if(prefs)
		return user?.client?.prefs == prefs
	return user == target

/datum/hair_style_picker/ui_data(mob/user)
	. = list()
	if(!length(allowed_tabs))
		.["error"] = TRUE
		.["labels"] = build_labels(user)
		return
	if(!length(base_cache))
		build_attempts++
		if(build_attempts > 3 || !build_all_bases())
			.["error"] = TRUE
			.["labels"] = build_labels(user)
			return
	if(!(tab in allowed_tabs))
		tab = allowed_tabs[1]
	if(!selected)
		selected = default_selection()

	var/list/favorites = get_favorites(user)
	var/list/all_entries = get_tab_full_list()
	var/list/entries = all_entries
	if(favorites_only || length(search))
		var/needle = lowertext(search)
		entries = list()
		for(var/style_name in all_entries)
			if(favorites_only && !(style_name in favorites))
				continue
			if(length(needle) && !findtext(lowertext(style_name), needle))
				continue
			entries += style_name
	var/total = length(entries)
	var/pages = max(1, CEILING(total / HAIR_PICKER_PAGE_SIZE, 1))
	page = clamp(page, 1, pages)
	var/list/page_names = list()
	if(total)
		var/end = min(total, page * HAIR_PICKER_PAGE_SIZE)
		var/i = (page - 1) * HAIR_PICKER_PAGE_SIZE + 1
		while(i <= end)
			page_names += entries[i]
			i++

	var/list/applied = list(
		"hair" = applied_hair() || "",
		"facial" = applied_facial() || "",
		"grad" = applied_grad() || "",
	)
	var/applied_hair_style = applied["hair"]
	var/applied_facial_style = applied["facial"]
	var/applied_grad_style = applied["grad"]
	var/selected_key = selected || ""
	var/can_preview_full = can_preview_full_body(user)
	var/color_key = "[applied_hair_color()]|[applied_facial_color()]|[applied_grad_color()]|[get_mcolor()]"
	// единственное место где можно было сэкономить
	var/sheet_key = "[tab]|[page]|[search]|[favorites_only]|[applied_hair_style]|[applied_facial_style]|[applied_grad_style]|[color_key]"
	if(sheet_key != sheet_cache_key)
		sheet_cache_key = sheet_key
		sheet_b64 = build_sheet_b64(page_names)
	// selected может меняться отдельно от листа, ключ для каждого свой
	var/preview_key = "[can_preview_full]|[render_dir]|[tab]|[selected_key]|[applied_hair_style]|[applied_facial_style]|[applied_grad_style]|[color_key]"
	if(preview_key != preview_cache_key)
		preview_cache_key = preview_key
		build_preview_b64(can_preview_full)

	.["allowed_tabs"] = allowed_tabs
	.["mode"] = mode
	.["can_preview_full"] = can_preview_full
	.["can_change_color"] = can_change_color(user)
	.["is_taur"] = is_taur
	.["tab"] = tab
	.["dir"] = render_dir
	.["search"] = search
	.["favorites"] = favorites
	.["favorites_only"] = favorites_only
	.["page"] = page
	.["pages"] = pages
	.["total"] = total
	.["names"] = page_names
	.["selected"] = selected
	.["applied"] = applied
	.["sheet"] = sheet_b64 || null
	.["cell_w"] = sheet_cell_w
	.["cell_h"] = sheet_cell_h
	.["cols"] = HAIR_PICKER_COLS
	.["preview_portraits"] = preview_portraits
	.["preview_full"] = can_preview_full ? (preview_full_b64 || null) : null
	.["img_w"] = img_w
	.["img_h"] = img_h
	.["head_w"] = portrait_width
	.["head_h"] = portrait_rows
	.["labels"] = build_labels(user)

/datum/hair_style_picker/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui?.user || usr
	switch(action)
		if("dir")
			if(!can_preview_full_body(user))
				return
			var/new_dir = text2num("[params["dir"]]")
			if(!(new_dir in list(NORTH, SOUTH, EAST, WEST)))
				return
			if(new_dir == render_dir)
				return
			render_dir = new_dir
			return TRUE

		if("tab")
			var/new_tab = params["tab"]
			if(!(new_tab in allowed_tabs))
				return
			tab = new_tab
			page = 1
			selected = default_selection()
			return TRUE

		if("search")
			var/search_raw = params["search"]
			search = copytext(strip_control_chars("[search_raw]"), 1, 65)
			page = 1
			return TRUE

		if("page")
			var/page_raw = params["page"]
			page = max(1, isnum(page_raw) ? page_raw : (text2num("[page_raw]") || 1))
			return TRUE

		if("favorites_only")
			favorites_only = !favorites_only
			page = 1
			return TRUE

		if("toggle_favorite")
			var/datum/preferences/viewer_prefs = user?.client?.prefs
			var/style_name = params["name"]
			if(!viewer_prefs || params["tab"] != tab || !(style_name in get_tab_full_list()))
				return
			var/list/favorites = get_favorites(user)
			if(style_name in favorites)
				favorites -= style_name
			else
				favorites |= style_name
			viewer_prefs.favorite_hair_styles[tab] = favorites
			viewer_prefs.save_single_pref("favorite_hair_styles", viewer_prefs.favorite_hair_styles)
			if(favorites_only)
				sheet_cache_key = null
			return TRUE

		if("select")
			var/candidate = params["name"]
			if(!(candidate in get_tab_full_list()))
				return
			selected = candidate
			return TRUE

		if("color")
			if(applying)
				return
			applying = TRUE
			var/changed = FALSE
			try
				changed = change_color(user)
			catch(var/exception/color_error)
				stack_trace("hair_style_picker: ошибка выбора цвета: [color_error]")
			if(QDELETED(src))
				return
			applying = FALSE
			destroy_if_idle()
			return !QDELETED(src) && changed

		if("apply")
			if(applying)
				return
			if(!isnull(params["name"]))
				var/candidate = params["name"]
				if(params["tab"] != tab || !(candidate in get_tab_full_list()))
					return
				selected = candidate
			applying = TRUE
			try
				ui?.close()
				apply_selection(user, ui)
			catch(var/exception/apply_error)
				stack_trace("hair_style_picker: ошибка применения выбора: [apply_error]")
			if(QDELETED(src))
				return
			applying = FALSE
			destroy_if_idle()
			return

// При вызове из красителя отдельный спрей в руках не требуется.
/datum/hair_style_picker/proc/get_color_spray(mob/user)
	if(istype(check_atom, /obj/item/dyespray) && !QDELETED(check_atom))
		var/obj/item/dyespray/source_spray = check_atom
		return source_spray.can_change_color ? source_spray : null
	for(var/obj/item/dyespray/spray in user?.held_items)
		if(!QDELETED(spray) && spray.can_change_color)
			return spray
	return null

/datum/hair_style_picker/proc/can_change_color(mob/user)
	if(QDELETED(user) || !(tab in allowed_tabs))
		return FALSE
	if(prefs)
		return user.client?.prefs == prefs
	if(QDELETED(target) || QDELETED(check_atom))
		return FALSE
	if(!allow_color_without_spray && !get_color_spray(user))
		return FALSE
	return user.canUseTopic(check_atom, BE_CLOSE, FALSE, NO_TK, TRUE, TRUE) && user.canUseTopic(target, BE_CLOSE, FALSE, NO_TK, TRUE, TRUE)

/datum/hair_style_picker/proc/change_color(mob/user)
	if(!can_change_color(user))
		return FALSE
	var/color_tab = tab
	var/obj/item/dyespray/spray = get_color_spray(user)
	var/list/labels = build_labels(user)
	var/tab_label = labels["tab_[color_tab]"]
	var/current_color = get_tab_color()
	var/new_color = input(user, tab_label, labels["color"], "#[current_color]") as color|null
	// За время диалога могли сменить вкладку, отойти от цели или убрать спрей из рук.
	if(QDELETED(src) || !new_color || tab != color_tab || !can_change_color(user))
		return FALSE
	if(!prefs && !allow_color_without_spray && (QDELETED(spray) || get_color_spray(user) != spray))
		return FALSE
	new_color = sanitize_hexcolor(new_color, 6)
	switch(color_tab)
		if(HAIR_PICKER_TAB_HAIR)
			preview_hair_color = new_color
		if(HAIR_PICKER_TAB_FACIAL)
			preview_facial_color = new_color
		if(HAIR_PICKER_TAB_GRAD)
			preview_grad_color = new_color
	// Пересобираем и лист миниатюр, и все направления предпросмотра в следующем ui_data.
	sheet_cache_key = null
	preview_cache_key = null
	return TRUE

/datum/hair_style_picker/proc/apply_selection(mob/user, datum/tgui/ui)
	if(!user || !selected)
		return FALSE
	if(!(tab in allowed_tabs) || !(selected in get_tab_full_list()))
		return FALSE
	if(prefs)
		switch(tab)
			if(HAIR_PICKER_TAB_HAIR)
				prefs.hair_style = selected
			if(HAIR_PICKER_TAB_FACIAL)
				prefs.facial_hair_style = selected
			if(HAIR_PICKER_TAB_GRAD)
				prefs.grad_style = selected
		apply_preview_colors()
		prefs.ShowChoices(user, rebuild_preview = TRUE)
		return TRUE

	if(QDELETED(target) || !check_atom || QDELETED(check_atom))
		return FALSE
	if(!user.canUseTopic(check_atom, BE_CLOSE, FALSE, NO_TK, TRUE, TRUE))
		return FALSE
	if(!user.canUseTopic(target, BE_CLOSE, FALSE, NO_TK, TRUE, TRUE))
		return FALSE
	// Спрей мог оказаться вне рук между выбором цвета и Apply.
	var/has_color_changes = !isnull(preview_hair_color) || !isnull(preview_facial_color) || !isnull(preview_grad_color)
	if(has_color_changes && !can_change_color(user))
		return FALSE
	if(apply_callback)
		if(QDELETED(apply_callback) || (apply_callback.object != GLOBAL_PROC && QDELETED(apply_callback.object)))
			return FALSE
		if(!apply_callback.Invoke(selected, tab, get_tab_color()))
			return FALSE
		if(QDELETED(src) || QDELETED(target))
			return FALSE
		if(apply_preview_colors())
			target.update_hair()
		return TRUE
	switch(tab)
		if(HAIR_PICKER_TAB_HAIR)
			target.hair_style = selected
		if(HAIR_PICKER_TAB_FACIAL)
			target.facial_hair_style = selected
		if(HAIR_PICKER_TAB_GRAD)
			target.grad_style = selected
	// Зеркало: женщины всегда с бритой - как и раньше.
	if(mode == HAIR_PICKER_MODE_MIRROR && target.gender == FEMALE)
		target.facial_hair_style = "Shaved"
	apply_preview_colors()
	target.update_hair()
	if(mode == HAIR_PICKER_MODE_MIRROR)
		target.update_mutant_bodyparts()
	if(apply_sound)
		playsound(check_atom, apply_sound, 20, TRUE)
	return TRUE

// После успешного применения стиля сохраняем все выбранные цвета доступных вкладок.
/datum/hair_style_picker/proc/apply_preview_colors()
	. = FALSE
	if((HAIR_PICKER_TAB_HAIR in allowed_tabs) && !isnull(preview_hair_color))
		if(prefs)
			prefs.hair_color = preview_hair_color
		else
			target.hair_color = preview_hair_color
		. = TRUE
	if((HAIR_PICKER_TAB_FACIAL in allowed_tabs) && !isnull(preview_facial_color))
		if(prefs)
			prefs.facial_hair_color = preview_facial_color
		else
			target.facial_hair_color = preview_facial_color
		. = TRUE
	if((HAIR_PICKER_TAB_GRAD in allowed_tabs) && !isnull(preview_grad_color))
		if(prefs)
			prefs.grad_color = preview_grad_color
		else
			target.grad_color = preview_grad_color
		. = TRUE

// яндере-дев
/datum/hair_style_picker/proc/applied_hair()
	return prefs ? prefs.hair_style : target?.hair_style

/datum/hair_style_picker/proc/applied_facial()
	return prefs ? prefs.facial_hair_style : target?.facial_hair_style

/datum/hair_style_picker/proc/applied_grad()
	return prefs ? prefs.grad_style : target?.grad_style

/datum/hair_style_picker/proc/applied_hair_color()
	if(!isnull(preview_hair_color))
		return preview_hair_color
	return prefs ? prefs.hair_color : target?.hair_color

/datum/hair_style_picker/proc/applied_facial_color()
	if(!isnull(preview_facial_color))
		return preview_facial_color
	return prefs ? prefs.facial_hair_color : target?.facial_hair_color

/datum/hair_style_picker/proc/applied_grad_color()
	if(istype(check_atom, /obj/item/dyespray) && !QDELETED(check_atom))
		var/obj/item/dyespray/spray = check_atom
		if(!spray.can_change_color)
			return spray.get_dye_color(target)
	if(!isnull(preview_grad_color))
		return preview_grad_color
	return prefs ? prefs.grad_color : target?.grad_color

/datum/hair_style_picker/proc/get_tab_color()
	switch(tab)
		if(HAIR_PICKER_TAB_HAIR)
			return applied_hair_color()
		if(HAIR_PICKER_TAB_FACIAL)
			return applied_facial_color()
		if(HAIR_PICKER_TAB_GRAD)
			return applied_grad_color()

/datum/hair_style_picker/proc/get_species()
	if(prefs)
		return prefs.pref_species
	return target?.dna?.species

/datum/hair_style_picker/proc/get_mcolor()
	var/list/feature_list
	if(prefs)
		feature_list = prefs.features
	else if(target?.dna)
		feature_list = target.dna.features
	return feature_list ? feature_list["mcolor"] : null

/datum/hair_style_picker/proc/default_selection()
	switch(tab)
		if(HAIR_PICKER_TAB_HAIR)
			return applied_hair()
		if(HAIR_PICKER_TAB_FACIAL)
			return applied_facial()
		if(HAIR_PICKER_TAB_GRAD)
			return applied_grad() || "None"
	return null

/datum/hair_style_picker/proc/get_favorites(mob/user)
	var/datum/preferences/viewer_prefs = user?.client?.prefs
	var/list/favorite_tabs = viewer_prefs?.favorite_hair_styles
	if(!islist(favorite_tabs))
		return list()
	var/list/favorites = favorite_tabs[tab]
	return islist(favorites) ? favorites : list()

/datum/hair_style_picker/proc/get_tab_full_list()
	if(cached_list_tab == tab && length(cached_list))
		return cached_list
	var/list/base
	switch(tab)
		if(HAIR_PICKER_TAB_HAIR)
			base = GLOB.hair_styles_list
		if(HAIR_PICKER_TAB_FACIAL)
			base = GLOB.facial_hair_styles_list
		if(HAIR_PICKER_TAB_GRAD)
			base = GLOB.hair_gradients_list
		else
			return list()
	if(!base)
		return list()
	if(prefs && length(owner_ckey))
		base = prefs.filter_accessories_by_ckey(base, owner_ckey)
	cached_list_tab = tab
	cached_list = base
	return base

/datum/hair_style_picker/proc/build_labels(mob/user)
	var/datum/preferences/lang_prefs = prefs || user?.client?.prefs
	var/use_translations = lang_prefs?.use_modern_translations
	var/is_russian = use_translations && lang_prefs?.modern_ui_language == 1
	. = list()
	.["tab_hair"] = use_translations ? get_modern_text("hair_style", lang_prefs) : "Hair Style"
	.["tab_facial"] = use_translations ? get_modern_text("facial_hair_style", lang_prefs) : "Facial Hair"
	.["tab_grad"] = use_translations ? get_modern_text("hair_gradient", lang_prefs) : "Hair Gradient"
	.["title"] = is_russian ? "Выбор прически" : "Hair Style"
	.["apply"] = is_russian ? "Применить" : "Apply"
	.["color"] = is_russian ? "Цвет" : "Color"
	.["color_requires_spray"] = is_russian ? "Возьмите [/obj/item/dyespray::name] в руки, чтобы активировать кнопку." : "Hold [/obj/item/dyespray::name] to enable this button."
	if(istype(check_atom, /obj/item/dyespray))
		var/obj/item/dyespray/spray = check_atom
		if(!spray.can_change_color)
			.["color_requires_spray"] = is_russian ? "Цвет этого баллончика задан заранее." : "This spray has a fixed color."
	.["search"] = is_russian ? "Поиск..." : "Search..."
	.["favorites"] = is_russian ? "Избранное" : "Favorites"
	.["preview"] = is_russian ? "Превью" : "Preview"
	.["portrait"] = is_russian ? "Портрет" : "Portrait"
	.["full"] = is_russian ? "Всё тело" : "Full body"
	.["page"] = is_russian ? "Страница" : "Page"
	.["selected"] = is_russian ? "Выбрано:" : "Selected:"
	.["empty"] = is_russian ? "Ничего не найдено" : "Nothing found"

// рендер
/datum/hair_style_picker/proc/get_base_icon(dir)
	. = base_cache["[dir]"]
	if(.)
		return
	if(!build_all_bases())
		return null
	return base_cache["[dir]"]

/datum/hair_style_picker/proc/build_all_bases()
	var/slot_key = "hair_style_picker_[owner_ckey]_[rand(1, 999999)]"
	var/mob/living/carbon/human/dummy/mannequin = generate_or_wait_for_human_dummy(slot_key, regenerate = FALSE)
	var/list/dirs = list(SOUTH, WEST, NORTH, EAST)
	base_cache = list()
	base_offsets = list()
	img_w = 0
	img_h = 0
	try
		if(prefs)
			prefs.copy_to(mannequin, icon_updates = TRUE, roundstart_checks = FALSE, initial_spawn = TRUE)
		else if(target?.dna)
			target.dna.transfer_identity(mannequin, transfer_SE = FALSE, copy_clothing = TRUE)
		mannequin.hair_style = "Bald"
		mannequin.facial_hair_style = "Shaved"
		mannequin.grad_style = null
		mannequin.update_body()
		mannequin.update_body_parts()
		mannequin.update_mutant_bodyparts()
		mannequin.update_hair()
		mannequin.update_mutations_overlay()
		is_taur = mannequin.have_tauric_body()
		for(var/dir in dirs)
			mannequin.dir = dir
			var/list/offsets = list()
			var/icon/result = getFlatIcon(mannequin, defdir = dir, no_anim = TRUE, icon_offsets = offsets)
			if(!isicon(result))
				continue
			result.Crop(1 - HAIR_PICKER_PAD, 1 - HAIR_PICKER_PAD, result.Width() + HAIR_PICKER_PAD, result.Height() + HAIR_PICKER_PAD)
			base_cache["[dir]"] = result
			base_offsets["[dir]"] = list("x" = offsets["x"] + HAIR_PICKER_PAD, "y" = offsets["y"] + HAIR_PICKER_PAD)
			img_w = max(img_w, result.Width())
			img_h = max(img_h, result.Height())
	catch(var/exception/base_error)
		stack_trace("hair_style_picker: не собралась база превью: [base_error]")
	clear_human_dummy(slot_key)
	if(length(base_cache) != length(dirs))
		base_cache.Cut()
		base_offsets.Cut()
		return FALSE
	// Полный рост использует общий размер, портрет кадрируется относительно головы.
	for(var/dir in dirs)
		var/icon/base = base_cache["[dir]"]
		base.Crop(1, 1, img_w, img_h)
	portrait_width = world.icon_size + 2 * HAIR_PICKER_PAD
	portrait_rows = round(world.icon_size * 0.5) + HAIR_PICKER_PAD
	build_attempts = 0
	return TRUE

// самая вкусная часть, попытка отрисовывать только голову сжатием композиции
/datum/hair_style_picker/proc/crop_head(icon/source, dir = SOUTH)
	if(!isicon(source))
		return null
	var/icon/cropped = new /icon(source)
	var/list/offsets = base_offsets["[dir]"]
	var/left = offsets["x"] - HAIR_PICKER_PAD + 1
	var/top = offsets["y"] + world.icon_size + HAIR_PICKER_PAD
	cropped.Crop(left, top - portrait_rows + 1, left + portrait_width - 1, top)
	return cropped

/datum/hair_style_picker/proc/compose_preview(hair_style, facial_style, grad_style, dir = SOUTH)
	var/icon/base = get_base_icon(dir)
	if(!base)
		return null
	var/datum/species/species = get_species()
	if(!species)
		return null
	var/icon/result = new /icon(base)
	try
		var/datum/sprite_accessory/facial = GLOB.facial_hair_styles_list[facial_style]
		if(facial && (FACEHAIR in species.species_traits))
			blend_accessory(result, facial, resolve_color(facial, applied_facial_color()), species, OFFSET_FHAIR, dir)
		var/datum/sprite_accessory/hair = GLOB.hair_styles_list[hair_style]
		if(hair && (HAIR in species.species_traits))
			blend_accessory(result, hair, resolve_color(hair, applied_hair_color()), species, OFFSET_HAIR, dir)
			// Градиент рисуется только поверх окрашиваемых волос - как в handle_hair.
			if(hair.do_colouration && grad_style)
				var/datum/sprite_accessory/gradient = GLOB.hair_gradients_list[grad_style]
				if(gradient)
					blend_gradient(result, hair, gradient, species, dir)
	catch(var/exception/compose_error)
		stack_trace("hair_style_picker: ошибка композиции превью ([hair_style]/[facial_style]/[grad_style]): [compose_error]")
		return null
	return result

/datum/hair_style_picker/proc/resolve_color(datum/sprite_accessory/accessory, base_color)
	if(!accessory?.do_colouration || !length(base_color))
		return null
	var/datum/species/species = get_species()
	if(species?.hair_color)
		if(species.hair_color == "mutcolor")
			var/mutcolor = get_mcolor()
			return length(mutcolor) ? "#" + mutcolor : null
		return "#" + species.hair_color
	return "#" + base_color

/datum/hair_style_picker/proc/accessory_icon(datum/sprite_accessory/accessory, dir)
	// PNG-превью должно содержать один кадр: анимация размножает весь лист миниатюр при экспорте.
	if(icon_state_has_directional_frames(accessory.icon, accessory.icon_state))
		return icon(accessory.icon, accessory.icon_state, dir, 1, FALSE)
	return icon(accessory.icon, accessory.icon_state, SOUTH, 1, FALSE)

/datum/hair_style_picker/proc/blend_accessory(icon/target, datum/sprite_accessory/accessory, color, datum/species/species, offset_key, dir)
	var/icon/part = accessory_icon(accessory, dir)
	if(color)
		part.Blend(color, ICON_MULTIPLY)
	if(species.hair_alpha < 255)
		part.Blend(rgb(255, 255, 255, species.hair_alpha), ICON_MULTIPLY)
	var/list/offset = islist(species.offset_features) ? species.offset_features[offset_key] : null
	var/list/origin = base_offsets["[dir]"]
	blend_at(target, part, origin["x"] + (offset ? offset[1] : 0), origin["y"] + (offset ? offset[2] : 0))

/datum/hair_style_picker/proc/blend_gradient(icon/target, datum/sprite_accessory/hair, datum/sprite_accessory/gradient, datum/species/species, dir)
	var/icon/part = accessory_icon(gradient, dir)
	part.Blend(accessory_icon(hair, dir), ICON_ADD)
	var/grad_color = applied_grad_color()
	if(length(grad_color))
		part.Blend("#" + grad_color, ICON_MULTIPLY)
	var/list/origin = base_offsets["[dir]"]
	blend_at(target, part, origin["x"], origin["y"])

/datum/hair_style_picker/proc/blend_at(icon/target, icon/part, dx, dy)
	target.Blend(part, ICON_OVERLAY, max(1, dx + 1), max(1, dy + 1))

/datum/hair_style_picker/proc/compose_cell(style_name)
	switch(tab)
		if(HAIR_PICKER_TAB_HAIR)
			return compose_preview(style_name, applied_facial(), applied_grad(), SOUTH)
		if(HAIR_PICKER_TAB_FACIAL)
			return compose_preview(applied_hair(), style_name, applied_grad(), SOUTH)
		if(HAIR_PICKER_TAB_GRAD)
			return compose_preview(applied_hair(), applied_facial(), style_name, SOUTH)
	return null

/datum/hair_style_picker/proc/build_preview_b64(can_preview_full = FALSE)
	preview_portraits = list()
	preview_full_b64 = null
	if(!selected)
		return FALSE
	var/hair_style = tab == HAIR_PICKER_TAB_HAIR ? selected : applied_hair()
	var/facial_style = tab == HAIR_PICKER_TAB_FACIAL ? selected : applied_facial()
	var/grad_style = tab == HAIR_PICKER_TAB_GRAD ? selected : applied_grad()
	for(var/dir in list(SOUTH, WEST, NORTH, EAST))
		var/icon/preview = compose_preview(hair_style, facial_style, grad_style, dir)
		if(!preview)
			return FALSE
		if(can_preview_full && dir == render_dir)
			preview_full_b64 = icon2base64(preview)
		var/icon/head = crop_head(preview, dir)
		if(head)
			preview_portraits["[dir]"] = icon2base64(head)
	return TRUE

/datum/hair_style_picker/proc/build_sheet_b64(list/names)
	sheet_cell_w = portrait_width
	sheet_cell_h = portrait_rows
	if(!length(names))
		return FALSE
	var/list/cells = list()
	for(var/style_name in names)
		var/icon/cell = compose_cell(style_name)
		if(!cell)
			cell = get_base_icon(SOUTH)
			if(!cell)
				return FALSE
		cell = crop_head(cell)
		if(!cell)
			return FALSE
		cells += cell
	var/rows = max(1, CEILING(length(names) / HAIR_PICKER_COLS, 1))
	var/icon/sheet
	try
		sheet = icon('icons/effects/effects.dmi', "nothing")
		sheet.Scale(HAIR_PICKER_COLS * portrait_width, rows * portrait_rows)
		var/i = 0
		for(var/icon/cell in cells)
			var/col = i % HAIR_PICKER_COLS
			var/row = round(i / HAIR_PICKER_COLS)
			sheet.Blend(cell, ICON_OVERLAY, 1 + col * portrait_width, sheet.Height() - row * portrait_rows - portrait_rows + 1)
			i++
	catch(var/exception/sheet_error)
		stack_trace("hair_style_picker: не собрался лист миниатюр: [sheet_error]")
		return FALSE
	return icon2base64(icon(sheet, "", SOUTH, 1, FALSE))

#undef HAIR_PICKER_TAB_HAIR
#undef HAIR_PICKER_TAB_FACIAL
#undef HAIR_PICKER_TAB_GRAD
#undef HAIR_PICKER_MODE_PREFS
#undef HAIR_PICKER_MODE_MIRROR
#undef HAIR_PICKER_MODE_SCISSORS
#undef HAIR_PICKER_MODE_RAZOR
#undef HAIR_PICKER_MODE_CUSTOM
#undef HAIR_PICKER_PAGE_SIZE
#undef HAIR_PICKER_COLS
#undef HAIR_PICKER_PAD
