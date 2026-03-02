/datum/escape_menu/proc/show_home_page()
	page_holder.give_screen_object(
		new /atom/movable/screen/escape_menu/home_button(
			null,
			src,
			"Вернуться",
			/* offset = */ 0,
			CALLBACK(src, PROC_REF(home_resume)),
		)
	)

	page_holder.give_screen_object(
		new /atom/movable/screen/escape_menu/home_button(
			null,
			src,
			"Настройки",
			/* offset = */ 1,
			CALLBACK(src, PROC_REF(home_open_settings)),
		)
	)

	page_holder.give_screen_object(
		new /atom/movable/screen/escape_menu/home_button(
			null,
			src,
			"Остановить Звуки",
			/* offset = */ 2,
			CALLBACK(src, PROC_REF(home_stop_sounds)),
		)
	)

	page_holder.give_screen_object(
		new /atom/movable/screen/escape_menu/home_button/leave_body(
			null,
			src,
			"Покинуть Тело",
			/* offset = */ 3,
			CALLBACK(src, PROC_REF(open_leave_body)),
		)
	)

	page_holder.give_screen_object(
		new /atom/movable/screen/escape_menu/home_button(
			null,
			src,
			"Включить/Выключить Полноэкранный Режим",
			/* offset = */ 5,
			CALLBACK(src, PROC_REF(home_fullscreen)),
		)
	)

/datum/escape_menu/proc/home_resume()
	qdel(src)

/datum/escape_menu/proc/home_open_settings()
	client?.prefs.ShowChoices(client?.mob)
	qdel(src)

/datum/escape_menu/proc/home_stop_sounds()
	var/client/C = usr.client
	SEND_SOUND(usr, sound(null))
	C?.tgui_panel?.stop_music()
	qdel(src)

/datum/escape_menu/proc/home_fullscreen()
	usr.client.prefs.fullscreen = !usr.client.prefs.fullscreen
	usr.client.ToggleFullscreen()

/atom/movable/screen/escape_menu/home_button
	mouse_opacity = MOUSE_OPACITY_OPAQUE

	VAR_PRIVATE
		atom/movable/screen/escape_menu/home_button_text/home_button_text
		datum/escape_menu/escape_menu
		datum/callback/on_click_callback

/atom/movable/screen/escape_menu/home_button/Initialize(
	mapload,
	datum/escape_menu/escape_menu,
	button_text,
	offset,
	on_click_callback,
)
	. = ..(mapload, null)

	src.escape_menu = escape_menu
	src.on_click_callback = on_click_callback

	home_button_text = new /atom/movable/screen/escape_menu/home_button_text(
		src,
		button_text,
	)

	vis_contents += home_button_text

	screen_loc = "NORTH:-[132 + (32 * offset)],WEST:110"
	transform = transform.Scale(6, 1)

/atom/movable/screen/escape_menu/home_button/Destroy()
	maptext = null
	filters = null
	if(home_button_text)
		vis_contents -= home_button_text
		home_button_text.moveToNullspace()
	escape_menu = null
	QDEL_NULL(on_click_callback)
	QDEL_NULL(home_button_text)

	return ..()

/atom/movable/screen/escape_menu/home_button/Click(location, control, params)
	if (!enabled())
		return

	if(on_click_callback)
		on_click_callback.InvokeAsync()

/atom/movable/screen/escape_menu/home_button/MouseEntered(location, control, params)
	if(home_button_text)
		home_button_text.set_hovered(TRUE)

/atom/movable/screen/escape_menu/home_button/MouseExited(location, control, params)
	if(home_button_text)
		home_button_text.set_hovered(FALSE)

/atom/movable/screen/escape_menu/home_button/proc/text_color()
	return enabled() ? "white" : "gray"

/atom/movable/screen/escape_menu/home_button/proc/enabled()
	return TRUE

// Needs to be separated so it doesn't scale
/atom/movable/screen/escape_menu/home_button_text
	maptext_width = 200
	maptext_height = 50
	pixel_x = -80

	VAR_PRIVATE
		button_text
		hovered = FALSE

/atom/movable/screen/escape_menu/home_button_text/Initialize(mapload, button_text)
	. = ..(mapload, null)

	src.button_text = button_text
	update_text()

/// Sets the hovered state of the button, and updates the text
/atom/movable/screen/escape_menu/home_button_text/proc/set_hovered(hovered)
	if (src.hovered == hovered)
		return

	src.hovered = hovered
	update_text()

/atom/movable/screen/escape_menu/home_button_text/proc/update_text()
	var/atom/movable/screen/escape_menu/home_button/escape_menu_loc = loc

	maptext = "<span style='font-size: 16px; color: [istype(escape_menu_loc) ? escape_menu_loc.text_color() : "white"]; font-family: \"Comic Sans MS\"'>[button_text]</span>"

	if (hovered && (!istype(escape_menu_loc) || escape_menu_loc.enabled()))
		maptext = "<u>[maptext]</u>"

/atom/movable/screen/escape_menu/home_button/leave_body

/atom/movable/screen/escape_menu/home_button/leave_body/Initialize(
	mapload,
	datum/escape_menu/escape_menu,
	button_text,
	offset,
	on_click_callback,
)
	. = ..()

	if(escape_menu?.client)
		RegisterSignal(escape_menu.client, COMSIG_CLIENT_MOB_LOGIN, PROC_REF(on_client_mob_login))

/atom/movable/screen/escape_menu/home_button/leave_body/Destroy()
	if(escape_menu?.client)
		UnregisterSignal(escape_menu.client, COMSIG_CLIENT_MOB_LOGIN)
	return ..()

/atom/movable/screen/escape_menu/home_button/leave_body/enabled()
	if (!..())
		return FALSE

	return isliving(escape_menu?.client?.mob)

/atom/movable/screen/escape_menu/home_button/leave_body/proc/on_client_mob_login()
	SIGNAL_HANDLER

	home_button_text.update_text()
