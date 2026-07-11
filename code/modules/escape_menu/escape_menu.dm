GLOBAL_LIST_EMPTY(escape_menus)

/// Opens the escape menu.
/// Verb, hardcoded to Escape, set in the client skin.
/client/verb/open_escape_menu()
	set name = "Open Escape Menu"
	set hidden = TRUE

	var/current_escape_menu = GLOB.escape_menus[ckey]
	if (!isnull(current_escape_menu))
		qdel(current_escape_menu)
		return

	reset_held_keys()

	new /datum/escape_menu(src)

#define PAGE_HOME "PAGE_HOME"
#define PAGE_LEAVE_BODY "PAGE_LEAVE_BODY"

/datum/escape_menu
	/// The client that owns this escape menu
	var/client/client

	VAR_PRIVATE
		ckey

		datum/screen_object_holder/base_holder
		datum/screen_object_holder/page_holder
		/// Слабая ссылка на худ, чьим плейн-мастерам выдан блюр. Прямые ссылки
		/// на плейн-мастеры пережимали GC худа старого тела при смене моба.
		datum/weakref/blurred_hud_ref

		menu_page = PAGE_HOME

/datum/escape_menu/New(client/client)
	ASSERT(!(client.ckey in GLOB.escape_menus))

	ckey = client?.ckey
	src.client = client

	base_holder = new(client)
	populate_base_ui()

	page_holder = new(client)
	show_page()

	RegisterSignal(client, COMSIG_PARENT_QDELETING, PROC_REF(on_client_qdel))
	RegisterSignal(client, COMSIG_CLIENT_MOB_LOGIN, PROC_REF(on_client_mob_login))

	if (!isnull(ckey))
		GLOB.escape_menus[ckey] = src

/datum/escape_menu/Destroy(force, ...)
	if(client)
		UnregisterSignal(client, list(COMSIG_PARENT_QDELETING, COMSIG_CLIENT_MOB_LOGIN))

	QDEL_NULL(base_holder)
	QDEL_NULL(page_holder)

	GLOB.escape_menus -= ckey

	remove_blur()

	return ..()

/datum/escape_menu/proc/on_client_qdel()
	SIGNAL_HANDLER
	PRIVATE_PROC(TRUE)

	qdel(src)

/datum/escape_menu/proc/on_client_mob_login()
	SIGNAL_HANDLER
	PRIVATE_PROC(TRUE)

	// Страницы кроме домашней ссылаются на старое тело - закрываемся
	if (menu_page != PAGE_HOME)
		qdel(src)
		return

	// Клиент сменил тело: переносим блюр со старого худа на плейн-мастеры нового
	remove_blur()
	add_blur()

/datum/escape_menu/proc/show_page()
	PRIVATE_PROC(TRUE)

	page_holder.clear()

	switch (menu_page)
		if (PAGE_HOME)
			show_home_page()
		if (PAGE_LEAVE_BODY)
			show_leave_body_page()
		else
			CRASH("Unknown escape menu page: [menu_page]")

/datum/escape_menu/proc/populate_base_ui()
	PRIVATE_PROC(TRUE)

	for(var/dimmer_type in list(
		/atom/movable/screen/fullscreen/dimmer,
		/atom/movable/screen/fullscreen/dimmer/right,
		/atom/movable/screen/fullscreen/dimmer/bottom,
	))
		var/atom/movable/screen/fullscreen/dimmer/dimmer = new dimmer_type
		dimmer.owner_client = client
		base_holder.give_screen_object(dimmer)
	add_blur()

	base_holder.give_protected_screen_object(give_escape_menu_title())
	base_holder.give_protected_screen_object(give_escape_menu_details())

/datum/escape_menu/proc/open_home_page()
	PRIVATE_PROC(TRUE)

	menu_page = PAGE_HOME
	show_page()

/datum/escape_menu/proc/open_leave_body()
	PRIVATE_PROC(TRUE)

	menu_page = PAGE_LEAVE_BODY
	show_page()

/datum/escape_menu/proc/add_blur()
	PRIVATE_PROC(TRUE)

	var/datum/hud/target_hud = client?.mob?.hud_used
	if (isnull(target_hud))
		return

	blurred_hud_ref = WEAKREF(target_hud)
	for(var/atom/movable/screen/plane_master/plane as anything in blur_plane_masters(target_hud))
		plane.add_filter("escape_menu_blur", 1, list("type" = "blur", "size" = 2))

/datum/escape_menu/proc/remove_blur()
	PRIVATE_PROC(TRUE)

	var/datum/hud/target_hud = blurred_hud_ref?.resolve()
	blurred_hud_ref = null
	if (isnull(target_hud))
		return

	for(var/atom/movable/screen/plane_master/plane as anything in blur_plane_masters(target_hud))
		plane.remove_filter("escape_menu_blur")

/datum/escape_menu/proc/blur_plane_masters(datum/hud/target_hud)
	PRIVATE_PROC(TRUE)

	var/list/planes = list()
	for(var/plane_key in list("[GAME_PLANE]", "[FLOOR_PLANE]", "[WALL_PLANE]", "[ABOVE_WALL_PLANE]"))
		var/atom/movable/screen/plane_master/plane = target_hud.plane_masters[plane_key]
		if (!isnull(plane))
			planes += plane
	return planes

/atom/movable/screen/escape_menu
	plane = ESCAPE_MENU_PLANE
	layer = ESCAPE_MENU_DEFAULT_LAYER
	clear_with_screen = FALSE

/atom/movable/screen/escape_menu/Initialize(mapload, ...)
	. = ..(mapload)

// The escape menu can be opened before SSatoms
INITIALIZE_IMMEDIATE(/atom/movable/screen/escape_menu)

#undef PAGE_HOME
#undef PAGE_LEAVE_BODY
