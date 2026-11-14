/// Клиент с экранными картинками: шестерёнка снимает с него blank и забывает его.
/datum/client_interface/cogbar_viewer
	var/list/images = list()

/// Шестерёнка do_after не держит ушедшего клиента: иначе BYOND после Logout искал бы ссылку на него обходом мира
/datum/unit_test/cogbar_drops_client_on_logout

/datum/unit_test/cogbar_drops_client_on_logout/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/cogbar/cog = new(user)
	var/datum/client_interface/cogbar_viewer/viewer = new
	var/image/blank = image('icons/blanks/32x32.dmi', user, "nothing")
	cog.blank = blank
	cog.user_client = viewer
	viewer.images += blank

	SEND_SIGNAL(user, COMSIG_MOB_CLIENT_LOGOUT, null)

	TEST_ASSERT(isnull(cog.user_client), "После логаута шестерёнка не должна держать клиента")
	TEST_ASSERT(!(blank in viewer.images), "После логаута blank шестерёнки должен уйти с экрана клиента")
	qdel(cog)

/// Клиент, которому стопка вторичной карты раздаёт мастера плоскостей.
/datum/client_interface/popup_viewer
	var/list/screen = list()

/datum/client_interface/popup_viewer/proc/register_map_obj(atom/movable/screen/screen_obj)
	screen |= screen_obj

/// Стопка попапа (консоль камер) отпускает удалённого клиента: ui_close() в Logout его уже не видит
/datum/unit_test/popup_plane_group_drops_deleted_client

/datum/unit_test/popup_plane_group_drops_deleted_client/Run()
	var/datum/plane_master_group/popup/group = new(PLANE_GROUP_POPUP_WINDOW(src), "logout_holder_test_map")
	var/datum/client_interface/popup_viewer/viewer = new
	group.register_to_client(viewer)
	TEST_ASSERT(viewer in group.registered_clients, "Стопка должна запомнить клиента, которому показана")

	SEND_SIGNAL(viewer, COMSIG_PARENT_QDELETING, FALSE)

	TEST_ASSERT(!(viewer in group.registered_clients), "Удалённый клиент должен уйти из стопки попапа")
	qdel(group)
