#define PDA_CAMERA_PAGE_SIZE 12
#define PDA_CAMERA_PRINT_UPLOAD_TIME (2.5 SECONDS)
#define PDA_CAMERA_MAX_RADIUS 3
#define PDA_CAMERA_CURSOR 'icons/effects/mouse_pointers/pda_camera.dmi'
#define PDA_CAMERA_VIEWFINDER_DELAY (0.2 SECONDS)
#define PDA_CAMERA_VIEWFINDER_IDLE_DELAY (0.5 SECONDS)
#define PDA_CAMERA_CLOUD_LIMIT 50
#define PDA_CAMERA_CLOUD_TIER_1_LIMIT 200

/datum/computer_file/program/pda_camera
	filename = "Camera"
	filedesc = "Камера"
	category = PROGRAM_CATEGORY_CREW
	extended_desc = "Снимает фотографии, хранит их на ПДА и сохраняет в личное облако."
	usage_flags = PROGRAM_PDA
	size = 2
	tgui_id = "NtosCamera"
	program_icon = "camera"
	var/list/datum/picture/local_photos
	var/flash_enabled = FALSE
	var/capturing = FALSE
	COOLDOWN_DECLARE(shutter_cooldown)
	var/datum/weakref/viewer_ref
	var/datum/weakref/viewer_ui_ref
	var/cloud_directory
	var/tab = "camera"
	var/aim_requested = FALSE
	var/aiming = FALSE
	var/list/gallery_ids
	var/list/gallery_rows
	var/gallery_page = 1
	var/gallery_pages = 1
	var/selected_id
	var/datum/picture/cloud_selection
	var/edit_mode
	var/print_open = FALSE
	var/print_message
	var/datum/weakref/printer_ref
	var/print_upload_timer
	var/print_job = 0
	var/print_transferred = FALSE
	var/frame_radius_x = PDA_CAMERA_MAX_RADIUS
	var/frame_radius_y = PDA_CAMERA_MAX_RADIUS
	var/list/local_thumbnails
	var/client/aim_client
	var/previous_cursor
	var/previous_mouse_up
	var/previous_mouse_down
	var/aim_time_zone
	var/atom/movable/screen/map_view/photo_viewfinder/viewfinder
	var/viewfinder_timer
	var/viewfinder_idle_timer = FALSE
	var/viewfinder_cursor_dirty = FALSE
	var/datum/weakref/viewfinder_target_ref
	var/datum/weakref/viewfinder_origin_ref
	var/photos_taken = 0
	var/list/share_contacts
	var/datum/weakref/attachment_chat_ref
	var/datum/weakref/syndimatic_ref
	var/syndimatic_kind

/datum/computer_file/program/pda_camera/Destroy()
	close_camera_window()
	QDEL_LIST_ASSOC_VAL(local_photos)
	local_photos = null
	local_thumbnails = null
	return ..()

/datum/computer_file/program/pda_camera/kill_program(forced = FALSE)
	close_camera_window()
	return ..()

/datum/computer_file/program/pda_camera/ui_interact(mob/user, datum/tgui/ui)
	if(!isliving(user) || !user.client || !user.ckey || computer?.active_program != src)
		return
	var/datum/ui_state/state = ui_state(user)
	if(state.can_use_topic(computer, user) != UI_INTERACTIVE)
		return
	var/datum/tgui/current_ui = viewer_ui_ref?.resolve()
	if(current_ui?.user == user)
		if(!current_ui.initialized || SStgui.try_update_ui(user, src, current_ui))
			return
	else
		current_ui?.close()
	open_camera_ui(user)

/datum/computer_file/program/pda_camera/proc/open_camera_ui(mob/user, datum/pda_chat/attachment_chat, datum/computer_file/program/syndimatic/syndimatic, syndimatic_kind)
	clear_session()
	viewer_ref = WEAKREF(user)
	cloud_directory = pda_photo_cloud_path(user.ckey)
	if(attachment_chat || syndimatic)
		attachment_chat_ref = WEAKREF(attachment_chat)
		syndimatic_ref = WEAKREF(syndimatic)
		src.syndimatic_kind = syndimatic_kind
		tab = "local"
		refresh_gallery(1)
	RegisterSignal(user, COMSIG_MOB_CLIENT_LOGOUT, PROC_REF(on_viewer_logout))
	var/datum/tgui/ui = new(user, src, tgui_id, filedesc)
	viewer_ui_ref = WEAKREF(ui)
	RegisterSignal(ui, COMSIG_PARENT_QDELETING, PROC_REF(on_viewer_ui_deleted))
	ui.set_autoupdate(FALSE)
	if(ui.open())
		ui.send_asset(get_asset_datum(/datum/asset/simple/headers))
	else
		qdel(ui)

/datum/computer_file/program/pda_camera/ui_status(mob/user, datum/ui_state/state)
	if(viewer_ref?.resolve() != user || computer?.active_program != src || !computer.enabled)
		return UI_CLOSE
	return ..()

/datum/computer_file/program/pda_camera/ui_close(mob/user, datum/tgui/ui)
	if(viewer_ui_ref?.resolve() == ui)
		clear_session()
	return ..()

/datum/computer_file/program/pda_camera/proc/on_viewer_ui_deleted(datum/tgui/ui)
	SIGNAL_HANDLER
	clear_session()

/datum/computer_file/program/pda_camera/proc/on_viewer_logout(mob/user)
	SIGNAL_HANDLER
	clear_session()

/datum/computer_file/program/pda_camera/proc/close_camera_window()
	var/datum/tgui/ui = viewer_ui_ref?.resolve()
	clear_session()
	ui?.close()

/datum/computer_file/program/pda_camera/proc/clear_session()
	stop_aiming()
	clear_selection()
	var/mob/viewer = viewer_ref?.resolve()
	if(viewer)
		UnregisterSignal(viewer, COMSIG_MOB_CLIENT_LOGOUT)
	var/datum/tgui/ui = viewer_ui_ref?.resolve()
	if(ui)
		UnregisterSignal(ui, COMSIG_PARENT_QDELETING)
	viewer_ref = null
	viewer_ui_ref = null
	cloud_directory = null
	attachment_chat_ref = null
	syndimatic_ref = null
	syndimatic_kind = null
	gallery_ids = null
	gallery_rows = null
	tab = "camera"

/datum/computer_file/program/pda_camera/proc/clear_selection()
	cancel_print_upload()
	print_open = FALSE
	print_message = null
	print_transferred = FALSE
	edit_mode = null
	share_contacts = null
	selected_id = null
	QDEL_NULL(cloud_selection)

/datum/computer_file/program/pda_camera/ui_static_data(mob/user)
	return list(
		"nameLimit" = PHOTO_NAME_LIMIT,
		"descriptionLimit" = PHOTO_DESCRIPTION_LIMIT,
		"captionLimit" = PHOTO_CAPTION_LIMIT,
		"printDuration" = PDA_CAMERA_PRINT_UPLOAD_TIME * 100,
		"maxFrameSize" = PDA_CAMERA_MAX_RADIUS * 2 + 1,
		"serverUtcOffset" = rustg_formatted_timestamp("%z"),
	)

/datum/computer_file/program/pda_camera/ui_data(mob/user)
	var/list/data = get_header_data()
	if(viewer_ref?.resolve() != user)
		return data
	data["tab"] = tab
	data["flash"] = flash_enabled
	data["frameWidth"] = frame_radius_x * 2 + 1
	data["frameHeight"] = frame_radius_y * 2 + 1
	data["viewfinder"] = aiming ? "aiming" : (aim_requested ? "blocked" : "idle")
	data["viewfinderMap"] = viewfinder?.assigned_map
	data["capturing"] = capturing
	data["localCount"] = length(local_photos)
	data["page"] = gallery_page
	data["pages"] = gallery_pages
	data["editMode"] = edit_mode
	data["shareContacts"] = share_contacts
	data["attachmentPicker"] = !!attachment_chat_ref
	data["syndimaticPicker"] = syndimatic_kind
	data["printOpen"] = print_open
	data["printMessage"] = print_message
	data["printJob"] = print_upload_timer ? print_job : null
	data["printTransferred"] = print_transferred
	var/datum/picture/selected = get_selection()
	if(selected)
		var/list/photo = list(
			"id" = selected_id,
			"name" = html_decode(selected.picture_name),
			"description" = html_decode(selected.picture_desc),
			"caption" = selected.caption ? html_decode(selected.caption) : "",
		)
		if(print_open)
			var/obj/machinery/photocopier/printer = print_upload_timer ? printer_ref?.resolve() : find_printer(user)
			data["printerNearby"] = !!printer
			data["printerError"] = (!print_upload_timer && printer) ? printer.pda_photo_print_error() : null
		else if(!share_contacts)
			photo["uploaded"] = (tab == "local" && is_uploaded(selected_id))
			photo["stationCaptureTime"] = selected.station_capture_time
			photo["captureTimeZone"] = selected.capture_time_zone
			photo["serverCaptureTime"] = selected.server_capture_time
			photo += selected.photo_ui_media()
		data["photo"] = photo
	else
		data["photo"] = null
	data["gallery"] = (tab != "camera" && !selected) ? gallery_rows : null
	return data

/datum/computer_file/program/pda_camera/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	var/mob/user = ui?.user
	if(. || !user?.client || viewer_ref?.resolve() != user)
		return .
	if(attachment_chat_ref && !(action in list("tab", "page", "select", "back", "attach_photo", "cancel_attachment")))
		return FALSE
	if(syndimatic_ref && !(action in list("tab", "page", "select", "back", "select_syndimatic_photo", "cancel_syndimatic_picker")))
		return FALSE
	switch(action)
		if("toggle_flash")
			if(tab != "camera" || capturing)
				return FALSE
			flash_enabled = !flash_enabled
			queue_viewfinder_refresh()
		if("set_width", "set_height")
			var/size = params["size"]
			if(tab != "camera" || capturing || !isnum(size))
				return FALSE
			var/radius = clamp(round(size / 2), 0, PDA_CAMERA_MAX_RADIUS)
			if(action == "set_width")
				frame_radius_x = radius
			else
				frame_radius_y = radius
			viewfinder?.resize_frame(frame_radius_x, frame_radius_y)
			queue_viewfinder_refresh()
		if("shutter")
			if(tab != "camera" || capturing)
				return FALSE
			if(aim_requested)
				stop_aiming()
			else if(COOLDOWN_FINISHED(src, shutter_cooldown))
				aim_requested = TRUE
				if(can_aim(user))
					var/static/regex/time_zone_pattern = regex("^\[a-zA-Z0-9_+/-\]+$")
					var/time_zone = params["timeZone"]
					if(istext(time_zone) && length(time_zone) <= 64 && time_zone_pattern.Find(time_zone))
						aim_time_zone = time_zone
					start_aiming(user)
		if("tab")
			var/destination = params["tab"]
			if(destination != "camera" && destination != "local" && destination != "cloud")
				return FALSE
			if((attachment_chat_ref || syndimatic_ref) && destination == "camera")
				return FALSE
			stop_aiming()
			clear_selection()
			ui.set_autoupdate(FALSE)
			tab = destination
			if(tab == "camera")
				gallery_ids = null
				gallery_rows = null
			else
				refresh_gallery(1)
		if("page")
			var/page = params["page"]
			if(tab == "camera" || selected_id || !isnum(page))
				return FALSE
			refresh_gallery(round(page))
		if("select")
			var/id = params["id"]
			if(tab == "camera" || selected_id || !istext(id) || !gallery_ids?.Find(id))
				return FALSE
			if(tab == "cloud")
				cloud_selection = read_pda_cloud_photo(cloud_photo_path(id), TRUE)
				if(!cloud_selection)
					to_chat(user, span_warning("Не удалось открыть фотографию из облака."))
					refresh_gallery(gallery_page)
					return TRUE
			selected_id = id
		if("back")
			clear_selection()
			ui.set_autoupdate(FALSE)
			if(tab != "camera")
				refresh_gallery(gallery_page)
		if("edit", "upload")
			if(print_open || share_contacts || !get_selection())
				return FALSE
			if(action == "upload" && (tab != "local" || is_uploaded(selected_id) || !can_upload_to_cloud(user)))
				return FALSE
			edit_mode = action
		if("cancel_edit")
			edit_mode = null
		if("save")
			if(params["id"] != selected_id || !save_selection(params, user))
				return FALSE
		if("delete")
			var/datum/picture/selected = get_selection()
			if(!selected || edit_mode || print_open || share_contacts || params["id"] != selected_id || params["tab"] != tab)
				return FALSE
			if(tab == "local")
				local_photos -= selected_id
				if(local_thumbnails)
					local_thumbnails -= selected_id
				qdel(selected)
			else if(!delete_pda_cloud_photo(cloud_photo_path(selected_id)))
				to_chat(user, span_warning("Не удалось удалить фотографию из облака."))
				return FALSE
			clear_selection()
			refresh_gallery(gallery_page)
		if("request_share")
			if(!get_selection() || edit_mode || print_open || share_contacts)
				return FALSE
			var/datum/computer_file/program/messenger/messenger = get_share_messenger(user)
			if(!messenger)
				return FALSE
			share_contacts = messenger.get_messengers()
			if(!length(share_contacts))
				share_contacts = null
				to_chat(user, span_warning("В адресной книге нет получателей."))
				return FALSE
		if("cancel_share")
			share_contacts = null
		if("share_photo")
			var/contact_ref = params["recipient"]
			if(!share_contacts || !istext(contact_ref) || params["id"] != selected_id || params["tab"] != tab)
				return FALSE
			return share_photo(user, contact_ref)
		if("attach_photo", "cancel_attachment")
			var/datum/pda_chat/chat = attachment_chat_ref?.resolve()
			if(!attachment_chat_ref)
				return FALSE
			var/datum/computer_file/program/messenger/messenger = locate() in computer.get_all_files()
			if(!messenger)
				return FALSE
			if(action == "cancel_attachment")
				if(!computer.switch_program(messenger, user))
					return FALSE
				computer.ui_interact(user)
				return TRUE
			var/datum/picture/photo = get_selection()
			if(!photo || !chat || params["id"] != selected_id || params["tab"] != tab || messenger.saved_chats[REF(chat)] != chat || messenger.viewing_messages_of != REF(chat))
				return FALSE
			return open_photo_chat(user, messenger, chat, photo)
		if("select_syndimatic_photo", "cancel_syndimatic_picker")
			var/datum/computer_file/program/syndimatic/syndimatic = syndimatic_ref?.resolve()
			if(!syndimatic || syndimatic.computer != computer || computer.active_program != src)
				return FALSE
			var/datum/picture/photo
			if(action == "select_syndimatic_photo")
				photo = get_selection()
				if(!photo || params["id"] != selected_id || params["tab"] != tab)
					return FALSE
			return syndimatic.return_from_syndimatic_picker(user, syndimatic_kind, photo)
		if("request_print")
			if(!get_selection() || edit_mode || share_contacts)
				return FALSE
			print_open = TRUE
			ui.set_autoupdate(TRUE)
		if("start_print")
			if(!print_open || print_upload_timer || params["id"] != selected_id)
				return FALSE
			if(!start_print(user))
				return FALSE
		if("cancel_print")
			cancel_print_upload()
			print_open = FALSE
			print_message = null
			print_transferred = FALSE
			ui.set_autoupdate(FALSE)
		else
			return FALSE
	return TRUE

/datum/computer_file/program/pda_camera/proc/can_aim(mob/user)
	// ПДА находится в персонаже, поэтому проверяем турф под персонажем.
	return user?.client && user.client.eye == user && computer?.loc == user && isturf(user.loc) && user.is_holding(computer) && !user.incapacitated()

/datum/computer_file/program/pda_camera/proc/start_aiming(mob/user)
	aiming = TRUE
	aim_client = user.client
	previous_cursor = aim_client.mouse_override_icon
	previous_mouse_up = aim_client.mouse_up_icon
	previous_mouse_down = aim_client.mouse_down_icon
	aim_client.mouse_override_icon = PDA_CAMERA_CURSOR
	aim_client.mouse_up_icon = PDA_CAMERA_CURSOR
	aim_client.mouse_down_icon = PDA_CAMERA_CURSOR
	aim_client.mouse_pointer_icon = PDA_CAMERA_CURSOR
	RegisterSignal(user, COMSIG_MOB_CLICKON, PROC_REF(on_photo_click))
	RegisterSignal(user, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_STATCHANGE), PROC_REF(on_aim_moved))
	RegisterSignal(user, COMSIG_MOB_CLIENT_MOUSEMOVE, PROC_REF(on_aim_mouse_moved))
	RegisterSignal(user, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_HUD_CREATED), PROC_REF(on_aim_invalidated))
	RegisterSignal(computer, list(COMSIG_MOVABLE_MOVED, COMSIG_ITEM_DROPPED, COMSIG_ITEM_EQUIPPED), PROC_REF(on_aim_moved))
	RegisterSignal(aim_client, COMSIG_CLIENT_SET_EYE, PROC_REF(on_aim_moved))
	viewfinder = new
	viewfinder.generate_view("pda_camera_[REF(src)]_map")
	viewfinder.show_frame(aim_client, frame_radius_x, frame_radius_y)
	viewfinder_cursor_dirty = TRUE
	queue_viewfinder_refresh()

/datum/computer_file/program/pda_camera/proc/stop_aiming()
	aim_requested = FALSE
	aim_time_zone = null
	if(!aiming)
		return
	aiming = FALSE
	if(viewfinder_timer)
		deltimer(viewfinder_timer)
		viewfinder_timer = null
	viewfinder_idle_timer = FALSE
	viewfinder_cursor_dirty = FALSE
	viewfinder_target_ref = null
	viewfinder_origin_ref = null
	QDEL_NULL(viewfinder)
	if(aim_client)
		UnregisterSignal(aim_client, COMSIG_CLIENT_SET_EYE)
	restore_aim_cursor()
	var/mob/viewer = viewer_ref?.resolve()
	if(viewer)
		UnregisterSignal(viewer, list(COMSIG_MOB_CLICKON, COMSIG_MOVABLE_MOVED, COMSIG_MOB_STATCHANGE, COMSIG_MOB_CLIENT_MOUSEMOVE, COMSIG_PARENT_QDELETING, COMSIG_MOB_HUD_CREATED))
	if(computer)
		UnregisterSignal(computer, list(COMSIG_MOVABLE_MOVED, COMSIG_ITEM_DROPPED, COMSIG_ITEM_EQUIPPED))

/datum/computer_file/program/pda_camera/proc/restore_aim_cursor()
	if(aim_client)
		if(aim_client.mouse_override_icon == PDA_CAMERA_CURSOR)
			aim_client.mouse_override_icon = previous_cursor
		if(aim_client.mouse_up_icon == PDA_CAMERA_CURSOR)
			aim_client.mouse_up_icon = previous_mouse_up
		if(aim_client.mouse_down_icon == PDA_CAMERA_CURSOR)
			aim_client.mouse_down_icon = previous_mouse_down
		if(aim_client.mouse_pointer_icon == PDA_CAMERA_CURSOR)
			aim_client.mouse_pointer_icon = aim_client.mouse_override_icon || initial(aim_client.mouse_pointer_icon)
			aim_client.mob?.update_mouse_pointer()
	aim_client = null
	previous_cursor = null
	previous_mouse_up = null
	previous_mouse_down = null

/datum/computer_file/program/pda_camera/proc/on_aim_invalidated(mob/source)
	SIGNAL_HANDLER
	stop_aiming()
	if(!QDELETED(source))
		INVOKE_ASYNC(src, PROC_REF(push_update))

/datum/computer_file/program/pda_camera/proc/on_aim_mouse_moved(mob/user, atom/target, turf/location, control, params)
	SIGNAL_HANDLER
	if(control != "mapwindow.map" && control != "map")
		return
	viewfinder_cursor_dirty = TRUE
	queue_viewfinder_refresh()

/datum/computer_file/program/pda_camera/proc/queue_viewfinder_refresh()
	if(!viewfinder || (!viewfinder_cursor_dirty && !viewfinder_target_ref && !viewfinder_timer))
		return
	if(viewfinder_timer)
		if(!viewfinder_idle_timer)
			return
		deltimer(viewfinder_timer)
	viewfinder_idle_timer = FALSE
	viewfinder_timer = addtimer(CALLBACK(src, PROC_REF(refresh_viewfinder)), PDA_CAMERA_VIEWFINDER_DELAY, TIMER_STOPPABLE)

/datum/computer_file/program/pda_camera/proc/get_viewfinder_cursor_turf(mob/user, params)
	if(!params || !isturf(user.loc))
		return null
	var/list/modifiers = params2list(params)
	if(modifiers[SCREEN_LOC])
		return parse_caught_click_modifiers(modifiers, user.loc, user.client)

/datum/computer_file/program/pda_camera/proc/refresh_viewfinder()
	viewfinder_timer = null
	if(!aiming || QDELETED(viewfinder))
		return
	var/mob/viewer = viewer_ref?.resolve()
	if(!can_aim(viewer) || computer.active_program != src || !computer.enabled)
		stop_aiming()
		aim_requested = TRUE
		push_update()
		return
	var/turf/center = viewfinder_target_ref?.resolve()
	if(aim_client.mouse_control_object == "mapwindow.map" || aim_client.mouse_control_object == "map")
		if(viewfinder_cursor_dirty)
			var/atom/target = aim_client.mouse_object_ref?.resolve()
			var/turf/location = aim_client.mouse_location_ref?.resolve()
			if(istype(target, /atom/movable/screen/click_catcher) || !target)
				center = isturf(location) ? location : get_viewfinder_cursor_turf(viewer, aim_client.mouseParams)
			else
				center = istype(target, /atom/movable/screen) ? null : get_turf(target)
		else if(center && viewfinder_origin_ref?.resolve() != viewer.loc)
			// Камера сдвинулась под неподвижной мышью. Берём её позицию относительно нового центра.
			center = get_viewfinder_cursor_turf(viewer, aim_client.mouseParams)
		viewfinder_target_ref = WEAKREF(center)
		viewfinder_origin_ref = WEAKREF(viewer.loc)
	viewfinder_cursor_dirty = FALSE
	if(!center)
		viewfinder.clear_frame()
		return
	var/changed
	if(!viewer.is_blind() && camera_can_target(center, viewer, flash_enabled))
		changed = viewfinder.update_frame(center, viewer, frame_radius_x, frame_radius_y, flash_enabled)
	else
		changed = viewfinder.clear_frame()
	// Свет и двери могут меняться без движения мыши. Неподвижный кадр проверяем реже.
	viewfinder_idle_timer = !changed
	viewfinder_timer = addtimer(CALLBACK(src, PROC_REF(refresh_viewfinder)), changed ? PDA_CAMERA_VIEWFINDER_DELAY : PDA_CAMERA_VIEWFINDER_IDLE_DELAY, TIMER_STOPPABLE)

/datum/computer_file/program/pda_camera/proc/on_aim_moved(datum/source)
	SIGNAL_HANDLER
	if(can_aim(viewer_ref?.resolve()))
		queue_viewfinder_refresh()
		return
	stop_aiming()
	aim_requested = TRUE
	INVOKE_ASYNC(src, PROC_REF(push_update))

/datum/computer_file/program/pda_camera/proc/on_photo_click(mob/user, atom/target, params)
	SIGNAL_HANDLER
	if(istype(target, /atom/movable/screen))
		return NONE
	if(!can_aim(user) || computer.active_program != src || !computer.enabled)
		stop_aiming()
		aim_requested = TRUE
		INVOKE_ASYNC(src, PROC_REF(push_update))
		return NONE
	var/list/modifiers = params2list(params)
	if(!modifiers[LEFT_CLICK] || modifiers[RIGHT_CLICK] || modifiers[SHIFT_CLICK] || modifiers[CTRL_CLICK] || modifiers[ALT_CLICK] || modifiers[MIDDLE_CLICK])
		return NONE
	var/turf/center = get_turf(target)
	if(!camera_can_target(center, user, flash_enabled))
		return COMSIG_MOB_CANCEL_CLICKON
	var/time_zone = aim_time_zone
	stop_aiming()
	capturing = TRUE
	COOLDOWN_START(src, shutter_cooldown, 1 SECONDS)
	INVOKE_ASYNC(src, PROC_REF(take_picture), center, user, flash_enabled, frame_radius_x, frame_radius_y, time_zone)
	return COMSIG_MOB_CANCEL_CLICKON

/datum/computer_file/program/pda_camera/proc/take_picture(turf/center, mob/user, use_flash, radius_x, radius_y, time_zone)
	if(QDELETED(src))
		return
	var/id
	var/datum/picture/picture
	try
		if(!QDELETED(computer))
			id = rustg_generate_uuid_v7()
			var/station_capture_time = "[time2text(world.timeofday, "DD.MM")].[GLOB.year_integer] [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]"
			var/server_capture_time = rustg_formatted_timestamp("%d.%m.%Y %H:%M:%S")
			var/turf/device_turf = get_turf(computer)
			if(use_flash && device_turf)
				device_turf.flash_lighting_fx(8)
			play_camera_shutter(computer)
			picture = capture_camera_picture(center, user, radius_x, radius_y, use_flash)
			if(picture)
				picture.station_capture_time = station_capture_time
				picture.capture_time_zone = time_zone
				picture.server_capture_time = server_capture_time
	catch(var/exception/error)
		QDEL_NULL(picture)
		stack_trace("Ошибка съёмки камерой ПДА: [error]")
	capturing = FALSE
	if(QDELETED(src))
		qdel(picture)
		return
	if(picture)
		photos_taken++
		picture.picture_name = "Фотография №[photos_taken]"
		LAZYINITLIST(local_photos)
		local_photos.Insert(1, id)
		local_photos[id] = picture
		if(tab == "local" && !selected_id)
			refresh_gallery(gallery_page)
	push_update()

/datum/computer_file/program/pda_camera/proc/cloud_photo_path(id)
	return "[cloud_directory][id].sav"

/datum/computer_file/program/pda_camera/proc/is_uploaded(id)
	var/path = cloud_photo_path(id)
	return fexists(path) || fexists("[path].bak")

/datum/computer_file/program/pda_camera/proc/can_upload_to_cloud(mob/user)
	if(!cloud_directory)
		return FALSE
	if(IS_CKEY_DONATOR_GROUP(user.ckey, DONATOR_GROUP_TIER_2))
		return TRUE
	var/limit = IS_CKEY_DONATOR_GROUP(user.ckey, DONATOR_GROUP_TIER_1) ? PDA_CAMERA_CLOUD_TIER_1_LIMIT : PDA_CAMERA_CLOUD_LIMIT
	if(length(pda_photo_cloud_ids(cloud_directory, sort_ids = FALSE)) >= limit)
		to_chat(user, span_warning("Достигнут лимит облака ([limit] фото). Освободите место, чтобы загрузить новый снимок."))
		return FALSE
	return TRUE

/datum/computer_file/program/pda_camera/proc/get_selection()
	if(!selected_id)
		return null
	if(tab == "local")
		return local_photos?[selected_id]
	return cloud_selection

/datum/computer_file/program/pda_camera/proc/get_share_messenger(mob/user)
	var/obj/item/modular_computer/pda/device = computer
	var/datum/computer_file/program/messenger/messenger = locate() in device?.get_all_files()
	if(!istype(device) || device.toff || !messenger?.sending_and_receiving)
		to_chat(user, span_warning("Отправка сообщений на этом ПДА недоступна."))
		return null
	return messenger

/datum/computer_file/program/pda_camera/proc/share_photo(mob/user, contact_ref)
	var/list/contact = share_contacts[contact_ref]
	var/datum/picture/photo = get_selection()
	if(!contact || !photo)
		return FALSE
	var/datum/computer_file/program/messenger/messenger = get_share_messenger(user)
	if(!messenger)
		return FALSE
	var/datum/computer_file/program/messenger/recipient = locate(contact_ref)
	var/obj/item/modular_computer/pda/recipient_device = istype(recipient) ? recipient.computer : null
	if(!istype(recipient_device) || QDELETED(recipient) || recipient.invisible || !recipient.sending_and_receiving || recipient_device.hidden || recipient_device.toff || is_ghost_cafe_pda(recipient_device) || messenger.training_side_differs(recipient))
		to_chat(user, span_warning("ПДА получателя больше недоступен."))
		return FALSE
	if((recipient_device.saved_identification || "Unknown") != contact["name"] || (recipient_device.saved_job || "Unknown") != contact["job"])
		to_chat(user, span_warning("Данные получателя изменились. Откройте список получателей заново."))
		return FALSE
	// Камера может отправить фото до первого открытия мессенджера на обоих ПДА.
	if(!(REF(messenger) in GLOB.pda_messengers))
		add_messenger(messenger)
	if(!(contact_ref in GLOB.pda_messengers))
		add_messenger(recipient)
	var/datum/pda_chat/chat = messenger.find_chat_by_recipient(contact_ref) || messenger.create_chat(contact_ref)
	return open_photo_chat(user, messenger, chat, photo)

/datum/computer_file/program/pda_camera/proc/open_photo_chat(mob/user, datum/computer_file/program/messenger/messenger, datum/pda_chat/chat, datum/picture/photo)
	if(!chat?.can_reply || chat.blocked)
		to_chat(user, span_warning("К этому чату нельзя прикрепить фотографию."))
		return FALSE
	var/attachment = messenger.encode_photo_attachment(photo)
	if(!attachment)
		to_chat(user, span_warning("Не удалось прикрепить фотографию."))
		return FALSE
	var/obj/item/modular_computer/device = computer
	if(!device.switch_program(messenger, user))
		return FALSE
	chat.photo_attachment = attachment
	chat.visible_in_recents = TRUE
	messenger.viewing_messages_of = REF(chat)
	device.ui_interact(user)
	return TRUE

/datum/computer_file/program/pda_camera/proc/refresh_gallery(page)
	gallery_ids = tab == "cloud" ? pda_photo_cloud_ids(cloud_directory) : local_photos
	gallery_pages = max(1, CEILING(length(gallery_ids) / PDA_CAMERA_PAGE_SIZE, 1))
	gallery_page = clamp(page, 1, gallery_pages)
	gallery_rows = list()
	var/start = (gallery_page - 1) * PDA_CAMERA_PAGE_SIZE + 1
	for(var/index = start to min(start + PDA_CAMERA_PAGE_SIZE - 1, length(gallery_ids)))
		var/id = gallery_ids[index]
		var/photo_name
		var/thumbnail
		if(tab == "cloud")
			var/list/metadata = read_pda_cloud_photo(cloud_photo_path(id))
			if(!metadata)
				continue
			photo_name = metadata["name"]
			thumbnail = metadata["thumbnail"]
		else
			var/datum/picture/photo = local_photos[id]
			photo_name = photo.picture_name
			thumbnail = local_thumbnails?[id]
			if(!thumbnail)
				thumbnail = pda_photo_thumbnail(photo.picture_image)
				LAZYINITLIST(local_thumbnails)
				local_thumbnails[id] = thumbnail
		gallery_rows += list(list(
			"id" = id,
			"name" = html_decode(photo_name),
			"thumbnail" = thumbnail,
			"uploaded" = (tab == "local" && is_uploaded(id)),
		))

/datum/computer_file/program/pda_camera/proc/save_selection(list/params, mob/user)
	var/datum/picture/selected = get_selection()
	if(!edit_mode || !selected || !istext(params["name"]) || !istext(params["description"]) || !istext(params["caption"]))
		return FALSE
	var/uploading = edit_mode == "upload"
	var/saving_to_cloud = uploading || tab == "cloud"
	if(saving_to_cloud && (uploading ? is_uploaded(selected_id) : !is_uploaded(selected_id)))
		to_chat(user, span_warning("Состояние фотографии в облаке изменилось. Откройте галерею заново."))
		return FALSE
	if(uploading && !can_upload_to_cloud(user))
		return FALSE
	var/photo_name = html_encode_readable(trim(strip_control_chars(params["name"]), PHOTO_NAME_LIMIT + 1))
	if(!length(photo_name))
		photo_name = selected.picture_name
	var/photo_desc = selected.picture_desc
	// Длинное описание сцены сохраняется целиком, пока игрок не заменит его в редакторе.
	if(params["description"] != html_decode(photo_desc))
		photo_desc = html_encode_readable(trim(strip_control_chars(params["description"]), PHOTO_DESCRIPTION_LIMIT + 1))
	var/photo_caption = html_encode_readable(trim(strip_control_chars(params["caption"]), PHOTO_CAPTION_LIMIT + 1))
	if(saving_to_cloud)
		var/datum/picture/edited = selected.Copy()
		edited.picture_name = photo_name
		edited.picture_desc = photo_desc
		edited.caption = photo_caption
		var/saved = save_pda_cloud_photo(cloud_photo_path(selected_id), edited, local_thumbnails?[selected_id])
		qdel(edited)
		if(!saved)
			to_chat(user, span_warning("Не удалось сохранить фотографию в облаке."))
			return FALSE
	selected.picture_name = photo_name
	selected.picture_desc = photo_desc
	selected.caption = photo_caption
	edit_mode = null
	return TRUE

/datum/computer_file/program/pda_camera/proc/in_printer_range(obj/machinery/photocopier/printer, mob/user)
	var/turf/device_turf = get_turf(computer)
	var/turf/user_turf = get_turf(user)
	var/turf/printer_turf = printer?.loc
	return isturf(printer_turf) && device_turf && user_turf && printer_turf.z == device_turf.z && printer_turf.z == user_turf.z && get_dist(printer_turf, device_turf) <= 1 && get_dist(printer_turf, user_turf) <= 1

/datum/computer_file/program/pda_camera/proc/find_printer(mob/user)
	var/turf/device_turf = get_turf(computer)
	if(!device_turf)
		return null
	var/obj/machinery/photocopier/nearby
	for(var/obj/machinery/photocopier/printer in range(1, device_turf))
		if(QDELETED(printer) || !in_printer_range(printer, user))
			continue
		if(!printer.pda_photo_print_error())
			return printer
		if(!nearby)
			nearby = printer
	return nearby

/datum/computer_file/program/pda_camera/proc/start_print(mob/user)
	var/obj/machinery/photocopier/printer = find_printer(user)
	if(!printer || printer.pda_photo_print_error() || !get_selection())
		return FALSE
	printer_ref = WEAKREF(printer)
	RegisterSignal(printer, COMSIG_PARENT_QDELETING, PROC_REF(on_printer_deleted))
	RegisterSignal(printer, COMSIG_MOVABLE_MOVED, PROC_REF(on_print_moved))
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_print_moved))
	RegisterSignal(computer, COMSIG_MOVABLE_MOVED, PROC_REF(on_print_moved))
	print_message = null
	print_transferred = FALSE
	print_job++
	print_upload_timer = addtimer(CALLBACK(src, PROC_REF(finish_print_upload), print_job), PDA_CAMERA_PRINT_UPLOAD_TIME, TIMER_STOPPABLE)
	computer.play_ping()
	return TRUE

/datum/computer_file/program/pda_camera/proc/on_print_moved(datum/source)
	SIGNAL_HANDLER
	if(in_printer_range(printer_ref?.resolve(), viewer_ref?.resolve()))
		return
	cancel_print_upload("Передача отменена. Подойдите вплотную к принтеру.")
	INVOKE_ASYNC(src, PROC_REF(push_update))

/datum/computer_file/program/pda_camera/proc/on_printer_deleted(obj/machinery/photocopier/printer)
	SIGNAL_HANDLER
	cancel_print_upload("Передача отменена. Принтер уничтожен.", printer)
	INVOKE_ASYNC(src, PROC_REF(push_update))

/datum/computer_file/program/pda_camera/proc/cancel_print_upload(message, obj/machinery/photocopier/deleted_printer)
	if(!print_upload_timer)
		return
	deltimer(print_upload_timer)
	print_upload_timer = null
	var/obj/machinery/photocopier/printer = deleted_printer || printer_ref?.resolve()
	printer_ref = null
	if(printer)
		UnregisterSignal(printer, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
	var/mob/viewer = viewer_ref?.resolve()
	if(viewer)
		UnregisterSignal(viewer, COMSIG_MOVABLE_MOVED)
	if(computer)
		UnregisterSignal(computer, COMSIG_MOVABLE_MOVED)
	print_message = message

/datum/computer_file/program/pda_camera/proc/finish_print_upload(job)
	if(!print_upload_timer || job != print_job)
		return
	var/mob/viewer = viewer_ref?.resolve()
	var/datum/tgui/ui = viewer_ui_ref?.resolve()
	var/obj/machinery/photocopier/printer = printer_ref?.resolve()
	var/datum/picture/selected = get_selection()
	ui?.process_status()
	if(!viewer?.client || !ui || ui.closing || ui.status != UI_INTERACTIVE || !selected || !in_printer_range(printer, viewer))
		cancel_print_upload("Передача отменена.")
	else
		var/error_message = printer.start_pda_photo_print(selected)
		print_transferred = !error_message
		cancel_print_upload(error_message)
	push_update()

#undef PDA_CAMERA_PAGE_SIZE
#undef PDA_CAMERA_PRINT_UPLOAD_TIME
#undef PDA_CAMERA_MAX_RADIUS
#undef PDA_CAMERA_CURSOR
#undef PDA_CAMERA_VIEWFINDER_DELAY
#undef PDA_CAMERA_VIEWFINDER_IDLE_DELAY
#undef PDA_CAMERA_CLOUD_LIMIT
#undef PDA_CAMERA_CLOUD_TIER_1_LIMIT
