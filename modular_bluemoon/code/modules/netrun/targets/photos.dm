// MARK: Фотографии из видеопотока и печать на модульном компьютере

/// Bound rendering work, while retaining the ordinary camera's full 7-turf radius.
#define NETRUN_PHOTO_MAX_RADIUS 10
/// One memory cell holds the rendered area of an 8x8-turf image.
#define NETRUN_PHOTO_TILES_PER_CELL 64

/obj/machinery/camera
	var/netrun_next_photo = 0
	var/netrun_photographing = FALSE

/obj/machinery/camera/netrun_extra_commands()
	. = ..()
	. += "cam_photo"

/obj/machinery/camera/proc/netrun_photo_radius()
	return clamp(round(view_range), 0, NETRUN_PHOTO_MAX_RADIUS)

/obj/machinery/camera/proc/netrun_photo_storage_size()
	var/side = netrun_photo_radius() * 2 + 1
	return max(1, CEILING(side * side / NETRUN_PHOTO_TILES_PER_CELL, 1))

/datum/netrun_command/cam_photo
	id = "cam_photo"
	name = "Сохранить кадр"
	desc = "Снять настоящую фотографию видимой области камеры в файл памяти. Файл можно перенести на шард и распечатать."
	help = "Кадр соответствует дальности и видимости камеры: обычный радиус 7 даёт 15×15 клеток. Радиус ограничен 10, память — одна ячейка на каждые начатые 64 клетки (обычный кадр — 4). Между кадрами проходит не меньше 5 секунд."
	access = NETRUN_ACCESS_USER
	icon = "camera"
	trace = 2

/datum/netrun_command/cam_photo/ui_entry(datum/component/netrun_node/node, datum/netrun_console/console, full_id)
	. = ..()
	if(console.view_denial(node))
		.["allowed"] = FALSE

/datum/netrun_command/cam_photo/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/reason = console.view_denial(node)
	if(reason)
		console.log_line(reason, "bad")
		return
	var/obj/machinery/camera/camera = node.parent
	if(!camera.status || !camera.can_use())
		return "Камера не передаёт изображение."
	if(camera.netrun_photographing || world.time < camera.netrun_next_photo)
		return "Камера ещё сохраняет предыдущий кадр."
	var/photo_size = camera.netrun_photo_storage_size()
	if(netrun_storage_used(console.inventory.local_store.files) + photo_size > console.inventory.local_store.capacity)
		return "Для фотографии нужно [photo_size] ячейки свободной памяти."
	camera.netrun_photographing = TRUE
	camera.netrun_next_photo = world.time + 5 SECONDS
	var/obj/item/camera/netrun_capture/capture = new(get_turf(camera))
	// captureimage takes radii. Use the actual camera's cached LOS/XRay visibility,
	// rather than the temporary renderer's generic photographer view.
	var/radius = camera.netrun_photo_radius()
	var/list/visible_turfs = camera.get_visible_turfs().Copy()
	capture.captureimage(camera, null, FALSE, radius, radius, visible_turfs)
	if(!QDELETED(camera))
		camera.netrun_photographing = FALSE
	var/datum/picture/picture = capture.result
	capture.result = null
	qdel(capture)
	if(!picture)
		return "Не удалось получить кадр."
	if(QDELETED(console) || QDELETED(node))
		qdel(picture)
		return
	var/file_name = netrun_file_name("[node.address]_[world.time].png", "camera.png")
	picture.picture_name = file_name
	var/datum/netrun_file/file = new(file_name, NETRUN_FILE_PHOTO, "Кадр камеры [node.address]", photo_size)
	file.picture = picture
	if(!console.store_file(file))
		qdel(file)
		return "Не хватает места для сохранения кадра."
	console.inventory.selected_file_uid = file.uid
	return "Фотография сохранена: [file.name]."

/// Временный рендерер: использует captureimage, но передаёт picture в файл вместо печати.
/obj/item/camera/netrun_capture
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	flash_enabled = FALSE
	silent = TRUE
	can_customise = FALSE
	var/datum/picture/result

/obj/item/camera/netrun_capture/after_picture(mob/user, datum/picture/picture, proximity_flag)
	result = picture

/obj/item/camera/netrun_capture/Destroy()
	QDEL_NULL(result)
	return ..()

/// Принтер тратит обычную бумагу и выдаёт штатный /obj/item/photo с независимым снимком.
/obj/item/computer_hardware/printer/proc/print_picture(datum/picture/picture, photo_title)
	if(!picture?.picture_image || !stored_paper || !holder || !check_functionality())
		return FALSE
	var/datum/picture/copy = picture.Copy()
	copy.caption = picture.caption
	if(photo_title)
		copy.picture_name = photo_title
	new /obj/item/photo(holder.drop_location(), copy)
	stored_paper--
	return TRUE

#undef NETRUN_PHOTO_MAX_RADIUS
#undef NETRUN_PHOTO_TILES_PER_CELL
