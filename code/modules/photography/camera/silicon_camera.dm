
/obj/item/camera/siliconcam
	name = "silicon photo camera"
	var/in_camera_mode = FALSE
	var/list/datum/picture/stored = list()

/obj/item/camera/siliconcam/ai_camera
	name = "AI photo camera"
	flash_enabled = FALSE

/obj/item/camera/siliconcam/proc/toggle_camera_mode(mob/user)
	if(in_camera_mode)
		camera_mode_off(user)
	else
		camera_mode_on(user)

/obj/item/camera/siliconcam/proc/camera_mode_off(mob/user)
	in_camera_mode = FALSE
	to_chat(user, span_boldnotice("Режим съёмки выключен."))

/obj/item/camera/siliconcam/proc/camera_mode_on(mob/user)
	in_camera_mode = TRUE
	to_chat(user, span_boldnotice("Режим съёмки включён."))

/obj/item/camera/siliconcam/proc/selectpicture(mob/user)
	if(!user.client)
		return
	if(!length(stored))
		to_chat(user, span_boldannounce("Нет сохранённых снимков."))
		return
	var/list/photos_by_label = list()
	var/list/used_labels = list()
	for(var/datum/picture/photo as anything in stored)
		var/label = avoid_assoc_duplicate_keys(html_decode(photo.picture_name) || "Снимок", used_labels)
		photos_by_label[label] = photo
	var/selected_label = tgui_input_list(user, "Выберите снимок.", "Сохранённые снимки", photos_by_label)
	if(QDELETED(src) || !user.client || isnull(selected_label))
		return
	return photos_by_label[selected_label]

/obj/item/camera/siliconcam/proc/viewpictures(mob/user)
	var/datum/picture/selection = selectpicture(user)
	if(istype(selection))
		show_picture(user, selection)

/obj/item/camera/siliconcam/ai_camera/after_picture(mob/user, datum/picture/picture, proximity_flag)
	var/number = stored.len
	picture.picture_name = "Image [number] (taken by [loc.name])"
	stored[picture] = TRUE
	to_chat(user, span_unconscious("Снимок сохранён."))

/obj/item/camera/siliconcam/robot_camera
	name = "Cyborg photo camera"
	var/printcost = 2

/obj/item/camera/siliconcam/robot_camera/after_picture(mob/user, datum/picture/picture, proximity_flag)
	var/mob/living/silicon/robot/C = loc
	if(istype(C) && istype(C.connected_ai))
		var/number = C.connected_ai.aicamera.stored.len
		picture.picture_name = "Image [number] (taken by [loc.name])"
		C.connected_ai.aicamera.stored[picture] = TRUE
		to_chat(user, span_unconscious("Снимок сохранён в удалённой базе данных."))
	else
		var/number = stored.len
		picture.picture_name = "Image [number] (taken by [loc.name])"
		stored[picture] = TRUE
		to_chat(user, span_unconscious("Снимок сохранён в локальной памяти. Он автоматически загрузится в базу данных при синхронизации законов с ИИ."))

/obj/item/camera/siliconcam/robot_camera/selectpicture(mob/user)
	var/mob/living/silicon/robot/R = loc
	if(istype(R) && R.connected_ai)
		R.picturesync()
		return R.connected_ai.aicamera.selectpicture(user)
	else
		return ..()

/obj/item/camera/siliconcam/robot_camera/verb/borgprinting()
	set category ="Robot Commands"
	set name = "Print Image"
	set src in usr
	if(usr.stat == DEAD)
		return
	borgprint(usr)

/obj/item/camera/siliconcam/robot_camera/proc/borgprint(mob/user)
	var/mob/living/silicon/robot/C = loc
	if(!istype(C) || C.toner < 20)
		to_chat(user, span_warning("Недостаточно тонера для печати снимка."))
		return
	var/datum/picture/selection = selectpicture(user)
	if(!istype(selection) || QDELETED(src) || QDELETED(C) || loc != C || C.stat == DEAD)
		return
	if(C.toner < 20)
		to_chat(user, span_warning("Недостаточно тонера для печати снимка."))
		return
	var/obj/item/photo/p = new /obj/item/photo(C.loc, selection)
	p.pixel_x = rand(-10, 10)
	p.pixel_y = rand(-10, 10)
	C.toner -= printcost	 //All fun allowed.
	visible_message("Из узкой щели на корпусе [C.name] выезжает фотография.")
	to_chat(user, span_notice("Вы печатаете фотографию."))
