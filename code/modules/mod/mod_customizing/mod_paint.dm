#define MODPAINT_MAX_COLOR_VALUE 1.25
#define MODPAINT_MIN_COLOR_VALUE 0
#define MODPAINT_MAX_SECTION_COLORS 2
#define MODPAINT_MIN_SECTION_COLORS 0.25
#define MODPAINT_MAX_OVERALL_COLORS 4
#define MODPAINT_MIN_OVERALL_COLORS 1.5

/obj/item/mod/paint
	name = "MOD paint kit"
	desc = "Этот набор перекрасит ваш MOD-костюм во что-то уникальное."
	icon = 'icons/obj/clothing/modsuit/mod_construction.dmi'
	icon_state = "paintkit"
	var/datum/mod_paint_editor/editor

/obj/item/mod/paint/Destroy()
	QDEL_NULL(editor)
	return ..()

/obj/item/mod/paint/pre_attack(atom/attacked_atom, mob/living/user, params)
	var/obj/item/mod/control/mod = attacked_atom
	var/obj/item/clothing/mod_part/part = attacked_atom
	if(istype(part))
		mod = part.mod
	if(!istype(mod))
		return ..()
	if(mod.is_active() || mod.is_activating())
		balloon_alert(user, "сначала отключите MOD!")
		return STOP_ATTACK_PROC_CHAIN
	if(editor?.get_target() == attacked_atom && editor.can_edit(user))
		editor.ui_interact(user)
		return STOP_ATTACK_PROC_CHAIN
	QDEL_NULL(editor)
	editor = new(src, mod, attacked_atom, user)
	editor.ui_interact(user)
	return STOP_ATTACK_PROC_CHAIN

/datum/mod_paint_editor
	var/datum/weakref/kit_ref
	var/datum/weakref/mod_ref
	var/datum/weakref/target_ref
	var/datum/weakref/user_ref
	var/list/skins
	var/message

/datum/mod_paint_editor/New(obj/item/mod/paint/kit, obj/item/mod/control/mod, obj/item/target, mob/user)
	kit_ref = WEAKREF(kit)
	mod_ref = WEAKREF(mod)
	target_ref = WEAKREF(target)
	user_ref = WEAKREF(user)
	skins = mod.theme.skins.Copy()
	skins[mod.get_visual_skin()] = TRUE
	if(istype(target, /obj/item/clothing/mod_part))
		var/obj/item/clothing/mod_part/part = target
		skins[part.get_visual_skin()] = TRUE
	return ..()

/datum/mod_paint_editor/Destroy()
	SStgui.close_uis(src)
	var/obj/item/mod/paint/kit = kit_ref?.resolve()
	if(kit?.editor == src)
		kit.editor = null
	kit_ref = null
	mod_ref = null
	target_ref = null
	user_ref = null
	skins = null
	return ..()

/datum/mod_paint_editor/proc/get_mod()
	RETURN_TYPE(/obj/item/mod/control)
	return mod_ref?.resolve()

/datum/mod_paint_editor/proc/get_target()
	RETURN_TYPE(/obj/item)
	return target_ref?.resolve()

/datum/mod_paint_editor/proc/can_edit(mob/user)
	var/obj/item/mod/paint/kit = kit_ref?.resolve()
	var/obj/item/mod/control/mod = get_mod()
	var/obj/item/target = get_target()
	if(!user || user != user_ref?.resolve() || QDELETED(kit) || QDELETED(mod) || QDELETED(target))
		return FALSE
	if(user.incapacitated() || !user.is_holding(kit) || !user.CanReach(target) || mod.is_active() || mod.is_activating())
		return FALSE
	return target == mod || (target in mod.get_mod_parts(include_cell = FALSE))

/datum/mod_paint_editor/ui_state(mob/user)
	return GLOB.conscious_state

/datum/mod_paint_editor/ui_status(mob/user, datum/ui_state/state)
	return can_edit(user) ? GLOB.conscious_state.can_use_topic(src, user) : UI_CLOSE

/datum/mod_paint_editor/ui_host()
	return get_target()

/datum/mod_paint_editor/ui_interact(mob/user, datum/tgui/ui)
	if(!can_edit(user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui || QDELETED(src))
		return
	ui = new(user, src, "MODpaint", "MOD Paint Kit")
	ui.set_autoupdate(FALSE)
	if(!ui.open() || QDELETED(src) || !can_edit(user))
		qdel(src)
		return

/datum/mod_paint_editor/ui_close(mob/user)
	. = ..()
	qdel(src)

/datum/mod_paint_editor/ui_static_data(mob/user)
	var/obj/item/target = get_target()
	var/obj/item/mod/control/mod = get_mod()
	var/list/options = list()
	for(var/skin in skins)
		options += list(list("id" = skin))
	var/obj/item/clothing/mod_part/part = target
	var/current_skin = istype(part) ? part.get_visual_skin() : mod.get_visual_skin()
	var/current_color = target.atom_colours ? target.atom_colours[FIXED_COLOUR_PRIORITY] : null
	var/list/limits = list("channelMin" = MODPAINT_MIN_SECTION_COLORS, "channelMax" = MODPAINT_MAX_SECTION_COLORS, "totalMin" = MODPAINT_MIN_OVERALL_COLORS, "totalMax" = MODPAINT_MAX_OVERALL_COLORS)
	return list("target" = target.name, "skin" = current_skin, "color" = current_color, "skins" = options, "layers" = get_preview_layers(), "limits" = limits, "luma" = list(LUMA_R, LUMA_G, LUMA_B))

/datum/mod_paint_editor/ui_data(mob/user)
	return list("message" = message, "presets" = get_presets(user))

/datum/mod_paint_editor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..() || !can_edit(usr))
		return FALSE
	message = null
	switch(action)
		if("cancel")
			SStgui.close_uis(src)
			return TRUE
		if("apply")
			return apply_style(params, usr)
		if("save_preset")
			return save_preset(params, usr)
	return FALSE

/datum/mod_paint_editor/proc/read_style(list/params)
	RETURN_TYPE(/list)
	var/skin = params["skin"]
	if(!isnull(skin) && (!istext(skin) || !(skin in skins)))
		return
	var/list/style = list("skin" = skin, "paint" = !!params["paint"])
	if(!style["paint"])
		return style
	var/list/color = read_color(params)
	if(!color)
		return
	style["color"] = color
	return style

/datum/mod_paint_editor/proc/read_color(list/params)
	RETURN_TYPE(/list)
	switch(params["mode"])
		if("tint")
			var/static/regex/hex_color = regex(@"^#[0-9a-fA-F]{6}$")
			if(istext(params["color"]) && hex_color.Find(params["color"]))
				return color_hex2color_matrix(params["color"])
		if("hsv")
			var/hue = params["hue"]
			var/saturation = params["saturation"]
			var/value = params["value"]
			if(!isnum(hue) || !isnum(saturation) || !isnum(value))
				return
			if(hue < 0 || hue > 360 || saturation < 0 || saturation > 2 || value < 0 || value > MODPAINT_MAX_COLOR_VALUE)
				return
			return expand_matrix(color_matrix_hsv(hue, saturation, value))
		if("matrix")
			var/list/values = params["matrix"]
			if(!islist(values) || length(values) != 9)
				return
			for(var/value in values)
				if(!isnum(value) || value < MODPAINT_MIN_COLOR_VALUE || value > MODPAINT_MAX_COLOR_VALUE)
					return
			return expand_matrix(values)

/datum/mod_paint_editor/proc/expand_matrix(list/values)
	RETURN_TYPE(/list)
	return list(values[1], values[2], values[3], 0, values[4], values[5], values[6], 0, values[7], values[8], values[9], 0, 0, 0, 0, 1, 0, 0, 0, 0)

/datum/mod_paint_editor/proc/valid_color(list/color)
	var/total = 0
	for(var/channel in 1 to 3)
		var/amount = color[channel] + color[channel + 4] + color[channel + 8]
		if(amount < MODPAINT_MIN_SECTION_COLORS || amount > MODPAINT_MAX_SECTION_COLORS)
			message = "Цветовой канал должен оставаться в пределах [MODPAINT_MIN_SECTION_COLORS * 100]–[MODPAINT_MAX_SECTION_COLORS * 100]%."
			return FALSE
		total += amount
	if(total < MODPAINT_MIN_OVERALL_COLORS || total > MODPAINT_MAX_OVERALL_COLORS)
		message = "Общая интенсивность цвета должна оставаться в пределах [MODPAINT_MIN_OVERALL_COLORS * 100]–[MODPAINT_MAX_OVERALL_COLORS * 100]%."
		return FALSE
	return TRUE

/datum/mod_paint_editor/proc/apply_style(list/params, mob/user)
	var/list/style = read_style(params)
	if(!style || (style["paint"] && !valid_color(style["color"])))
		return TRUE
	var/obj/item/mod/control/mod = get_mod()
	var/obj/item/target = get_target()
	var/new_skin = style["skin"]
	if(new_skin)
		if(target == mod)
			if(mod.theme.hide_worn_sprites && new_skin == mod.skin)
				mod.set_mod_skin(new_skin)
			else
				mod.set_visual_skin(new_skin)
		else
			var/obj/item/clothing/mod_part/part = target
			part.set_paint_skin(new_skin)
	if(style["paint"])
		var/new_color = params["mode"] == "tint" ? params["color"] : style["color"]
		if(target == mod)
			mod.set_mod_color(new_color)
		else
			target.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
			target.add_atom_colour(new_color, FIXED_COLOUR_PRIORITY)
	mod.wearer?.regenerate_icons()
	playsound(target, 'sound/effects/spray3.ogg', 50, TRUE)
	SStgui.close_uis(src)
	return TRUE

/datum/mod_paint_editor/proc/get_preset_store(mob/user, mode)
	RETURN_TYPE(/list)
	var/datum/preferences/prefs = user?.client?.prefs
	var/obj/item/target = get_target()
	if(!prefs || !target)
		return list()
	var/list/store
	switch(mode)
		if("tint")
			store = prefs.color_presets_tint
		if("hsv")
			store = prefs.color_presets_hsv
		if("matrix")
			store = prefs.color_presets_matrix
	if(!islist(store))
		return list()
	if(!islist(store[target.type]))
		store[target.type] = list()
	return store[target.type]

/datum/mod_paint_editor/proc/get_presets(mob/user)
	var/list/presets = list()
	for(var/mode in list("tint", "hsv", "matrix"))
		var/list/store = get_preset_store(user, mode)
		for(var/name in store)
			presets += list(list("name" = name, "mode" = mode, "value" = store[name]))
	return presets

/datum/mod_paint_editor/proc/save_preset(list/params, mob/user)
	var/list/color = read_color(params)
	if(!color || !valid_color(color))
		return TRUE
	var/name = tgui_input_text(user, "Название пресета", "Сохранение окраски", max_length = 40, multiline = FALSE)
	if(!can_edit(user) || !length(name))
		return FALSE
	name = strip_control_chars(name)
	if(!length(name))
		return FALSE
	var/value
	switch(params["mode"])
		if("tint")
			value = params["color"]
		if("hsv")
			value = list("hue" = params["hue"], "sat" = params["saturation"], "val" = params["value"])
		if("matrix")
			var/list/matrix_value = params["matrix"]
			matrix_value = matrix_value.Copy()
			matrix_value += list(0, 0, 0)
			value = matrix_value
	var/list/store = get_preset_store(user, params["mode"])
	store[name] = value
	user.client.prefs.save_preferences()
	return TRUE

/datum/mod_paint_editor/proc/get_preview_layers()
	var/obj/item/mod/control/mod = get_mod()
	var/obj/item/target = get_target()
	var/list/layers = list()
	for(var/obj/item/part as anything in list(mod, mod.get_boots(), mod.get_chestplate(), mod.get_gauntlets(), mod.get_helmet()))
		if(!part)
			continue
		var/skin = mod.get_visual_skin()
		if(istype(part, /obj/item/clothing/mod_part))
			var/obj/item/clothing/mod_part/suit_part = part
			skin = suit_part.get_visual_skin()
		var/selected = target == mod || target == part
		var/list/sprites = list()
		sprites[skin] = get_part_sprite(part, skin)
		if(selected)
			for(var/option in skins)
				sprites[option] = get_part_sprite(part, option)
		layers += list(list("skin" = skin, "color" = part.color, "selected" = selected, "sprites" = sprites))
	return layers

/datum/mod_paint_editor/proc/get_part_sprite(obj/item/part, skin)
	var/static/list/cache = list()
	var/state = "[skin]-[initial(part.icon_state)]-sealed"
	if(!(state in cached_icon_states(part.mob_overlay_icon)))
		state = "[skin]-[initial(part.icon_state)]"
	var/key = "[part.mob_overlay_icon]|[state]"
	if(!cache[key])
		cache[key] = icon2base64(icon(part.mob_overlay_icon, state, SOUTH, 1))
	return cache[key]

#undef MODPAINT_MAX_COLOR_VALUE
#undef MODPAINT_MIN_COLOR_VALUE
#undef MODPAINT_MAX_SECTION_COLORS
#undef MODPAINT_MIN_SECTION_COLORS
#undef MODPAINT_MAX_OVERALL_COLORS
#undef MODPAINT_MIN_OVERALL_COLORS

/obj/item/mod/skin_applier
	name = "MOD skin applier"
	desc = "Этот одноразовый аппликатор скинов добавит скин к MOD-костюмам определённого типа."
	icon = 'icons/obj/clothing/modsuit/mod_construction.dmi'
	icon_state = "skinapplier"
	var/skin = "civilian"
	var/compatible_theme = /datum/mod_theme

/obj/item/mod/skin_applier/Initialize(mapload)
	. = ..()
	name = "MOD [skin] skin applier"

/obj/item/mod/skin_applier/pre_attack(atom/attacked_atom, mob/living/user, params)
	if(!istype(attacked_atom, /obj/item/mod/control))
		return ..()
	var/obj/item/mod/control/mod = attacked_atom
	if(mod.is_active() || mod.is_activating())
		balloon_alert(user, "suit is active!")
		return TRUE
	if(!istype(mod.theme, compatible_theme))
		balloon_alert(user, "incompatible theme!")
		return TRUE
	mod.set_mod_skin(skin)
	balloon_alert(user, "skin applied")
	qdel(src)
	return TRUE

/obj/item/mod/skin_applier/honkerative
	skin = "honkerative"
	compatible_theme = /datum/mod_theme/antagonist/syndicate
