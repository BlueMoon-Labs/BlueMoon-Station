/proc/valid_mod_hardlight_style(new_color, effect_type)
	var/static/regex/hex_color = regex(@"^#[0-9a-fA-F]{6}$")
	return istext(new_color) && hex_color.Find(new_color) && ispath(effect_type, /datum/overlay_effect)

/obj/item/mod/control/proc/set_hardlight_style(new_color, effect_type)
	if(!valid_mod_hardlight_style(new_color, effect_type))
		return FALSE
	if(hardlight_effect.type == effect_type && hardlight_effect.color == new_color)
		return TRUE
	var/datum/overlay_effect/old_effect = hardlight_effect
	hardlight_effect = new effect_type()
	hardlight_effect.apply_color(new_color)
	update_hardlight()
	qdel(old_effect)
	return TRUE

/datum/mod_hardlight_editor
	var/datum/weakref/mod_ref
	var/atom/movable/screen/map_view/mod_hardlight/preview

/datum/mod_hardlight_editor/New(obj/item/mod/control/mod)
	mod_ref = WEAKREF(mod)
	return ..()

/datum/mod_hardlight_editor/Destroy()
	SStgui.close_uis(src)
	QDEL_NULL(preview)
	mod_ref = null
	return ..()

/datum/mod_hardlight_editor/ui_state(mob/user)
	return GLOB.conscious_state

/datum/mod_hardlight_editor/ui_status(mob/user, datum/ui_state/state)
	var/obj/item/mod/control/mod = mod_ref?.resolve()
	if(!mod?.wearer || user != mod.wearer)
		return UI_CLOSE
	return GLOB.conscious_state.can_use_topic(src, user)

/datum/mod_hardlight_editor/ui_interact(mob/user, datum/tgui/ui)
	if(ui_status(user) != UI_INTERACTIVE)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		var/obj/item/mod/control/mod = mod_ref.resolve()
		QDEL_NULL(preview)
		preview = new()
		preview.generate_view("mod_hardlight_[REF(src)]")
		preview.snapshot(mod.wearer, mod.hardlight_effect)
		ui = new(user, src, "MODHardlight", "Настройка hardlight")
		ui.set_autoupdate(FALSE)
		ui.open()
		preview.display_to(user, ui.window)

/datum/mod_hardlight_editor/ui_close(mob/user)
	QDEL_NULL(preview)
	return ..()

/datum/mod_hardlight_editor/ui_data(mob/user)
	var/obj/item/mod/control/mod = mod_ref?.resolve()
	return list("color" = mod?.hardlight_effect?.color, "effect" = "[mod?.hardlight_effect?.type]")

/datum/mod_hardlight_editor/ui_static_data(mob/user)
	var/obj/item/mod/control/mod = mod_ref?.resolve()
	if(!mod?.wearer || user != mod.wearer)
		return list()
	var/list/effects = list()
	for(var/effect_type in typesof(/datum/overlay_effect))
		effects += list(list("id" = "[effect_type]", "name" = initial(effect_type:name)))
	return list("mapRef" = preview?.assigned_map, "effects" = effects, "has_field" = !!length(preview?.sources))

/datum/mod_hardlight_editor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..() || ui_status(usr) != UI_INTERACTIVE)
		return FALSE
	var/obj/item/mod/control/mod = mod_ref.resolve()
	switch(action)
		if("apply")
			return mod.set_hardlight_style(params["color"], text2path(params["effect"]))
		if("preview")
			preview?.update_preview(mod.wearer, params["color"], text2path(params["effect"]), params["direction"], params["zoom"])
	return FALSE

/atom/movable/screen/map_view/mod_hardlight
	name = "hardlight preview"
	var/mutable_appearance/body
	var/list/base_overlays
	var/list/sources
	var/list/styles = list()
	var/current_effect
	var/current_color
	var/shown_offset = 0
	var/atom/movable/screen/background/background

/atom/movable/screen/map_view/mod_hardlight/Destroy()
	body = null
	base_overlays = null
	sources = null
	styles = null
	QDEL_NULL(background)
	return ..()

/atom/movable/screen/map_view/mod_hardlight/ensure_plane_group()
	if(!popup_plane_group)
		popup_plane_group = new /datum/plane_master_group/popup/on_demand(PLANE_GROUP_POPUP_WINDOW(src), assigned_map)
	popup_plane_group.ensure_popup_depth(shown_offset)
	return popup_plane_group

/atom/movable/screen/map_view/mod_hardlight/display_to_client(client/show_to)
	. = ..()
	if(show_to && background)
		show_to.register_map_obj(background)

/atom/movable/screen/map_view/mod_hardlight/proc/snapshot(mob/living/carbon/human/human, datum/overlay_effect/effect)
	body = new()
	body.appearance = human.appearance
	body.pixel_x = 0
	body.pixel_y = 0
	base_overlays = human.get_overlays_copy(list(BODYPART_EFFECT_LAYER, GENITAL_EFFECT_LAYER, BODY_HARDLIGHT_LAYER))
	sources = list()
	for(var/layer in list(BODYPART_EFFECT_LAYER, GENITAL_EFFECT_LAYER, BODY_HARDLIGHT_LAYER))
		for(var/mutable_appearance/projection as anything in human.overlays_standing[layer])
			var/mutable_appearance/copy = new()
			copy.appearance = projection.appearance
			copy.name = projection.name
			copy.hardlight_icon = projection.hardlight_icon
			copy.hardlight_state = projection.hardlight_state
			sources += copy
	body.overlays = base_overlays + sources
	current_effect = effect.type
	current_color = effect.color
	shown_offset = PLANE_TO_OFFSET(human.plane)
	set_position((MOD_HARDLIGHT_PREVIEW_TILES + 1) / 2, (MOD_HARDLIGHT_PREVIEW_TILES + 1) / 2)
	background = new()
	background.assigned_map = assigned_map
	background.del_on_map_removal = FALSE
	background.fill_rect(1, 1, MOD_HARDLIGHT_PREVIEW_TILES, MOD_HARDLIGHT_PREVIEW_TILES)
	set_view(SOUTH, MOD_HARDLIGHT_PREVIEW_ZOOM)

/atom/movable/screen/map_view/mod_hardlight/proc/set_view(direction, zoom)
	body.setDir(direction)
	body.transform = matrix().Scale(zoom)
	overlays = list(body)

/atom/movable/screen/map_view/mod_hardlight/proc/update_preview(mob/living/carbon/human/human, new_color, effect_type, direction, zoom)
	if(!valid_mod_hardlight_style(new_color, effect_type) || !(direction in GLOB.cardinals) || !isnum(zoom))
		return FALSE
	if(new_color != current_color || effect_type != current_effect)
		var/list/style = styles["[effect_type]"]
		if(!style)
			style = build_style(human, effect_type)
			styles["[effect_type]"] = style
		var/list/colored = list()
		for(var/mutable_appearance/layer as anything in style)
			var/mutable_appearance/copy = new()
			copy.appearance = layer.appearance
			copy.color = new_color
			colored += copy
		body.overlays = base_overlays + colored
		current_effect = effect_type
		current_color = new_color
	set_view(direction, clamp(zoom, MOD_HARDLIGHT_PREVIEW_MIN_ZOOM, MOD_HARDLIGHT_PREVIEW_MAX_ZOOM))
	return TRUE

/atom/movable/screen/map_view/mod_hardlight/proc/build_style(mob/living/carbon/human/human, effect_type)
	var/datum/overlay_effect/effect = new effect_type()
	effect.apply_color(COLOR_WHITE)
	var/list/layers = list()
	for(var/mutable_appearance/source as anything in sources)
		var/mutable_appearance/layer = new()
		layer.appearance = source.appearance
		layer.icon = human.get_overlayed_icon(icon(source.hardlight_icon, source.hardlight_state), effect)
		layer.icon_state = ""
		layer.color = null
		layers += layer
	qdel(effect)
	return layers
