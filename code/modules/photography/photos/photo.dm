/*
 * Photo
 */
/obj/item/photo
	name = "photo"
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "photo"
	item_state = "paper"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	max_integrity = 50
	grind_results = list(/datum/reagent/iodine = 4)
	var/datum/picture/picture
	var/scribble		//Scribble on the back.
	var/datum/weakref/editor_user

/obj/item/photo/Initialize(mapload, datum/picture/P, datum_name = TRUE, datum_desc = TRUE)
	set_picture(P, datum_name, datum_desc, TRUE)
	return ..()

/obj/item/photo/Destroy()
	finish_camera_edit()
	SStgui.close_uis(src)
	picture = null
	return ..()

/obj/item/photo/proc/set_picture(datum/picture/P, setname, setdesc, name_override = FALSE)
	if(!istype(P))
		return
	var/image_changed = picture != P
	picture = P
	update_icon()
	if(P.caption)
		scribble = P.caption
	if(setname && P.picture_name)
		if(name_override)
			name = P.picture_name
		else
			name = "photo - [P.picture_name]"
	if(setdesc && P.picture_desc)
		desc = P.picture_desc
	photo_changed(image_changed)

/obj/item/photo/proc/photo_changed(image_changed = FALSE)
	var/obj/item/storage/photo_album/personal/album = loc
	if(istype(album))
		album.queue_save()
	if(datum_flags & DF_HAS_OPEN_UI)
		if(image_changed)
			update_static_data_for_all_viewers(ignore_cooldown = TRUE)
		else
			SStgui.update_uis(src)

/obj/item/photo/update_icon_state()
	if(!istype(picture) || !picture.picture_image)
		return
	var/icon/I = picture.get_small_icon(initial(icon_state))
	if(I)
		icon = I

/obj/item/photo/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] в последний раз смотрит на фотографию. Похоже, жить больше незачем!"))
	if (user.gender == MALE || (user.gender == PLURAL && ismasculine(user)))
		playsound(user, 'sound/voice/human/manlaugh1.ogg', 50, TRUE)//EVERY TIME I DO IT MAKES ME LAUGH
	else if (user.gender == FEMALE || (user.gender == PLURAL && isfeminine(user)))
		playsound(user, 'sound/voice/human/womanlaugh.ogg', 50, TRUE)
	return OXYLOSS

/obj/item/photo/attack_self(mob/user)
	user.examinate(src)

/obj/item/photo/attackby(obj/item/P, mob/user, params)
	if(burn_paper_product_attackby_check(P, user))
		return
	if(istype(P, /obj/item/pen) || istype(P, /obj/item/toy/crayon))
		if(!user.can_write(P))
			to_chat(user, span_notice("Вы выводите на фотографии неразборчивые каракули!"))
			return
		if(!user.client)
			return
		var/txt = tgui_input_text(user, "Что написать на обороте фотографии?", "Подпись на фотографии", "", 128, encode = TRUE)
		if(txt && !QDELETED(src) && user.client && user.canUseTopic(src, BE_CLOSE))
			scribble = txt
			photo_changed()
		return
	if(istype(P, /obj/item/modular_computer/pda))
		var/obj/item/modular_computer/pda/pda_device = P
		pda_device.picture = picture
		to_chat(user, span_notice("Вы сканируете фотографию с помощью [pda_device]."))
		return
	return ..()

/obj/item/photo/examine(mob/user)
	. = ..()

	if(in_range(src, user) || isobserver(user))
		show(user)
	else
		. += span_warning("Подойдите ближе, чтобы рассмотреть фотографию.")

/obj/item/photo/proc/show(mob/user)
	if(!istype(picture) || (!picture.picture_image && !picture.picture_url))
		to_chat(user, span_warning("На фотографии ничего нет."))
		return
	ui_interact(user)

/obj/item/photo/proc/offer_camera_editor(mob/user, ask = TRUE)
	set waitfor = FALSE
	var/datum/picture/captured_picture = picture
	if((!ask || tgui_alert(user, "Открыть редактор фотографии?", "Редактирование фотографии", list("Нет", "Да")) == "Да") && !QDELETED(src) && open_camera_editor(user))
		return
	if(CONFIG_GET(flag/picture_logging_camera))
		captured_picture?.log_to_file()

/obj/item/photo/proc/open_camera_editor(mob/user)
	if(!user?.client)
		return FALSE
	var/datum/tgui/viewer = SStgui.get_open_ui(user, src)
	viewer?.close()
	editor_user = WEAKREF(user)
	if(ui_interact(user))
		return TRUE
	editor_user = null
	return FALSE

/obj/item/photo/proc/finish_camera_edit()
	if(!editor_user)
		return
	editor_user = null
	if(CONFIG_GET(flag/picture_logging_camera))
		picture?.log_to_file()

/obj/item/photo/ui_state(mob/user)
	if(editor_user?.resolve() == user)
		return GLOB.photo_editor_state
	return GLOB.photo_viewer_state

/obj/item/photo/ui_status(mob/user, datum/ui_state/state)
	return state ? state.can_use_topic(src, user) : UI_CLOSE

/obj/item/photo/ui_interact(mob/user, datum/tgui/ui)
	var/datum/ui_state/state = ui?.state || ui_state(user)
	if(ui_status(user, state) < UI_UPDATE)
		ui?.close()
		return FALSE
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return TRUE
	if(state == GLOB.photo_editor_state)
		ui = new(user, src, "PhotoEditor", "Редактирование фотографии")
	else
		ui = new(user, src, "PhotoViewer", name)
	ui.set_autoupdate(FALSE)
	if(ui.open())
		return TRUE
	qdel(ui)
	return FALSE

/obj/item/photo/ui_static_data(mob/user)
	var/list/data = picture?.photo_ui_media() || list()
	if(editor_user?.resolve() == user)
		data["defaultName"] = html_decode(picture.picture_name)
		data["nameLimit"] = PHOTO_NAME_LIMIT
		data["descriptionLimit"] = PHOTO_DESCRIPTION_LIMIT
		data["captionLimit"] = PHOTO_CAPTION_LIMIT
	return data

/obj/item/photo/ui_data(mob/user)
	return list(
		"photoName" = html_decode(name),
		"description" = desc ? html_decode(desc) : null,
		"caption" = scribble ? html_decode(scribble) : null,
	)

/obj/item/photo/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..() || state != GLOB.photo_editor_state || editor_user?.resolve() != ui.user)
		return FALSE
	switch(action)
		if("cancel")
			ui.close()
			return FALSE
		if("save")
			if(!istext(params["name"]) || !istext(params["description"]) || !istext(params["caption"]))
				return FALSE
			var/photo_name = html_encode_readable(trim(strip_control_chars(params["name"]), PHOTO_NAME_LIMIT + 1))
			var/photo_description = html_encode_readable(trim(strip_control_chars(params["description"]), PHOTO_DESCRIPTION_LIMIT + 1))
			var/photo_caption = html_encode_readable(trim(strip_control_chars(params["caption"]), PHOTO_CAPTION_LIMIT + 1))
			if(length(photo_name))
				picture.picture_name = photo_name
			if(length(photo_description))
				picture.picture_desc = "[photo_description] - [picture.picture_desc]"
			if(length(photo_caption))
				picture.caption = photo_caption
			ui.close()
			if(!QDELETED(src))
				set_picture(picture, TRUE, TRUE)
	return FALSE

/obj/item/photo/ui_close(mob/user, datum/tgui/ui)
	if(ui.state == GLOB.photo_editor_state)
		finish_camera_edit()
	return ..()

GLOBAL_DATUM_INIT(photo_viewer_state, /datum/ui_state/photo_viewer, new)
GLOBAL_DATUM_INIT(photo_editor_state, /datum/ui_state/photo_viewer/editor, new)

/datum/ui_state/photo_viewer/can_use_topic(obj/item/photo/src_object, mob/user)
	var/turf/photo_turf = get_turf(src_object)
	if(!user?.client || !photo_turf || !src_object.picture || !in_range(photo_turf, user))
		return UI_CLOSE
	if(isobserver(user))
		return UI_UPDATE
	return user.shared_ui_interaction(src_object)

/datum/ui_state/photo_viewer/editor/can_use_topic(obj/item/photo/src_object, mob/user)
	if(src_object.editor_user?.resolve() != user || ..() != UI_INTERACTIVE)
		return UI_CLOSE
	return UI_INTERACTIVE

/obj/item/photo/verb/rename()
	set name = "Rename photo"
	set category = "Object"
	set src in usr

	var/mob/living/L = usr
	if(!istype(L) || !L.client)
		return

	var/n_name = tgui_input_text(L, "Как назвать фотографию?", "Название фотографии", "", MAX_NAME_LEN, encode = TRUE)
	if(QDELETED(src) || !L.client)
		return
	// Фотографию можно переименовать и внутри папки в руках.
	if(n_name && (loc == L || loc?.loc == L) && CHECK_MOBILITY(L, MOBILITY_USE))
		name = "photo- '[n_name]'"
		photo_changed()
	add_fingerprint(L)

/obj/item/photo/old
	icon_state = "photo_old"
