/// Клиент, которому показано меню ПКМ: с его экрана меню снимает свои объекты.
/datum/client_interface/context_menu_viewer
	var/list/screen = list()

/// Настоящий Logout() закрывает меню ПКМ и снимает его объекты с экрана клиента, которого у моба в Logout уже нет
/datum/unit_test/context_menu_closes_on_logout

/datum/unit_test/context_menu_closes_on_logout/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1;shift=1")
	TEST_ASSERT_NOTNULL(menu, "Меню не открылось")
	var/list/screen_objects = menu.screen_objects.Copy()
	TEST_ASSERT(length(screen_objects), "Меню без экранных объектов")
	var/datum/client_interface/context_menu_viewer/viewer = new
	viewer.screen += screen_objects
	menu.shown_client = viewer

	user.Logout()

	TEST_ASSERT(QDELETED(menu), "Logout() не закрыл меню ПКМ")
	TEST_ASSERT_NULL(user.active_context_menu, "После Logout() у моба осталось активное меню")
	for(var/atom/movable/screen/object as anything in screen_objects)
		TEST_ASSERT(!(object in viewer.screen), "Объект меню остался на экране ушедшего клиента")
