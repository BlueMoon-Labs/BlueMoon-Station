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

/// Клиент с экраном, картинками и мобом: держатели кладут ему оверлеи и снимают их сами.
/datum/client_interface/holder_viewer
	var/list/images = list()
	var/list/screen = list()
	var/mob/mob
	var/datum/parallax_holder/parallax_holder

/datum/client_interface/holder_viewer/proc/register_map_obj(atom/movable/screen/screen_obj)
	screen |= screen_obj

/datum/client_interface/holder_viewer/proc/clear_map(map_name)
	return

/// Пузырь речи и прочие flick_overlay: таймер не держит клиента, иначе каждый ушедший в 3 с после чужой реплики стоил бы обхода мира
/datum/unit_test/flick_overlay_timer_holds_no_client

/datum/unit_test/flick_overlay_timer_holds_no_client/Run()
	var/datum/client_interface/holder_viewer/viewer = new
	var/image/flash = image('icons/blanks/32x32.dmi', run_loc_floor_bottom_left, "nothing")
	var/refs_before = refcount(viewer)
	flick_to(viewer, flash)
	var/refs_after = refcount(viewer)

	TEST_ASSERT(flash in viewer.images, "flick_overlay должен показать картинку клиенту")
	TEST_ASSERT(refs_after == refs_before, "Таймер flick_overlay держит клиента: ссылок было [refs_before], стало [refs_after]")
	remove_image_from_client(flash, WEAKREF(viewer))
	TEST_ASSERT(!(flash in viewer.images), "remove_image_from_client должен снимать картинку по weakref клиента")

/// Мех шлёт пузырь речи пилота: в списке получателей мог оказаться моб, это не должно ронять показ остальным
/datum/unit_test/flick_overlay_skips_non_clients

/datum/unit_test/flick_overlay_skips_non_clients/Run()
	var/mob/living/carbon/human/hearer = allocate(/mob/living/carbon/human)
	var/datum/client_interface/holder_viewer/viewer = new
	var/image/bubble = image('icons/blanks/32x32.dmi', run_loc_floor_bottom_left, "nothing")
	flick_overlay(bubble, list(hearer, viewer, null), 10 SECONDS)
	TEST_ASSERT(bubble in viewer.images, "Моб в списке получателей сорвал показ пузыря клиенту")
	remove_image_from_client(bubble, WEAKREF(viewer))

/// Отдельный кадр: чтения через viewer в Run() держат его во временных слотах и сбивают refcount.
/datum/unit_test/flick_overlay_timer_holds_no_client/proc/flick_to(datum/client_interface/holder_viewer/viewer, image/flash)
	var/list/show_to = list(viewer)
	flick_overlay(flash, show_to, 10 SECONDS)

/// Небо вознёсшегося еретика звучит до конца раунда: ушедший слушатель уходит из listeners
/datum/unit_test/heretic_sky_voice_drops_deleted_listener

/datum/unit_test/heretic_sky_voice_drops_deleted_listener/Run()
	var/datum/eldritch_knowledge/final_eldritch/moon_final/final = allocate(/datum/eldritch_knowledge/final_eldritch/moon_final)
	var/datum/heretic_sky_voice/voice = GLOB.heretic_sky.begin(final, heretic_sky_test_station_turf(), 30 SECONDS)
	var/datum/client_interface/holder_viewer/viewer = new
	voice.start_for(viewer, voice.path().sky_loop)
	var/listened = (viewer in voice.listeners)

	SEND_SIGNAL(viewer, COMSIG_PARENT_QDELETING, FALSE)
	var/kept = (viewer in voice.listeners)
	heretic_sky_test_clear()

	TEST_ASSERT(listened, "Голос неба должен запомнить слушателя")
	TEST_ASSERT(!kept, "Удалённый клиент должен уйти из слушателей неба")

/// Разлом живёт весь раунд: удалённый клиент еретика уходит из visible_clients
/datum/unit_test/reality_smash_drops_deleted_viewer

/datum/unit_test/reality_smash_drops_deleted_viewer/Run()
	var/obj/effect/reality_smash/smash = allocate(/obj/effect/reality_smash, run_loc_floor_bottom_left)
	var/datum/mind/heretic = new("holder_test_heretic")
	var/datum/client_interface/holder_viewer/viewer = new
	smash.show_to_viewer(heretic, viewer)
	TEST_ASSERT(smash.visible_clients[heretic] == viewer, "Разлом должен запомнить клиента еретика")

	SEND_SIGNAL(viewer, COMSIG_PARENT_QDELETING, FALSE)

	TEST_ASSERT(!(heretic in smash.visible_clients), "Удалённый клиент еретика должен уйти из разлома")

/// Метка крови культа: удалённый клиент культиста уходит из получателей картинки
/datum/unit_test/cult_blood_mark_drops_deleted_recipient

/datum/unit_test/cult_blood_mark_drops_deleted_recipient/Run()
	var/datum/team/cult/team = new
	var/datum/client_interface/holder_viewer/viewer = new
	team.track_blood_target_recipient(viewer)
	var/tracked = (viewer in team.blood_target_image_recipients)

	SEND_SIGNAL(viewer, COMSIG_PARENT_QDELETING, FALSE)
	var/kept = (viewer in team.blood_target_image_recipients)
	qdel(team)

	TEST_ASSERT(tracked, "Культ должен запомнить получателя метки")
	TEST_ASSERT(!kept, "Удалённый клиент должен уйти из получателей метки")

/// Сияние и кометный пояс держат оверлеи по клиенту: ушедший уходит из всех списков, параллакс в префах возвращается
/datum/unit_test/sky_events_drop_deleted_client

/datum/unit_test/sky_events_drop_deleted_client/Run()
	var/datum/round_event/aurora_caelus/aurora = new(FALSE)
	SSdirector.running -= aurora
	var/datum/client_interface/holder_viewer/aurora_viewer = new
	aurora.add_ion_overlay(aurora_viewer)
	var/aurora_tracked = !!aurora.ion_overlays[aurora_viewer]
	SEND_SIGNAL(aurora_viewer, COMSIG_PARENT_QDELETING, FALSE)
	var/aurora_kept = (aurora_viewer in aurora.ion_overlays)
	qdel(aurora)

	var/datum/round_event/comet_belt/comet = new(FALSE)
	SSdirector.running -= comet
	var/datum/client_interface/holder_viewer/comet_viewer = new
	comet_viewer.mob = allocate(/mob/living/carbon/human)
	comet_viewer.prefs = new
	comet_viewer.prefs.parallax = PARALLAX_LOW
	comet.setup_client(comet_viewer)
	var/comet_tracked = !!comet.comet_overlays[comet_viewer]
	SEND_SIGNAL(comet_viewer, COMSIG_PARENT_QDELETING, FALSE)
	var/comet_kept = (comet_viewer in comet.comet_overlays) || (comet_viewer in comet.glow_overlays) || (comet_viewer in comet.saved_parallax)
	var/restored_parallax = comet_viewer.prefs.parallax
	QDEL_LIST(comet.all_overlay_objects)
	qdel(comet)

	TEST_ASSERT(aurora_tracked, "Сияние должно выдать клиенту оверлей")
	TEST_ASSERT(!aurora_kept, "Удалённый клиент должен уйти из оверлеев сияния")
	TEST_ASSERT(comet_tracked, "Кометный пояс должен выдать клиенту оверлеи")
	TEST_ASSERT(!comet_kept, "Удалённый клиент должен уйти из списков кометного пояса")
	TEST_ASSERT_EQUAL(restored_parallax, PARALLAX_LOW, "Префы ушедшего должны получить свой параллакс назад")

/// Галлюцинация: удалённый клиент цели не держится до её конца, а живой (смена тела) остаётся для снятия картинок
/datum/unit_test/hallucination_drops_deleted_client

/datum/unit_test/hallucination_drops_deleted_client/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/obj/effect/hallucination/simple/vision = allocate(/obj/effect/hallucination/simple, run_loc_floor_bottom_left, target)
	var/datum/client_interface/holder_viewer/viewer = new

	vision.owner_client = viewer
	GLOB.clients += viewer
	SEND_SIGNAL(target, COMSIG_MOB_CLIENT_LOGOUT, null)
	GLOB.clients -= viewer
	var/kept_live = (vision.owner_client == viewer)
	// Сменив тело, игрок выходит уже из нового: цель логаута не видит, остаётся удаление самого клиента
	SEND_SIGNAL(viewer, COMSIG_PARENT_QDELETING, FALSE)
	var/kept_after_quit = !isnull(vision.owner_client)

	var/obj/effect/hallucination/simple/gone_vision = allocate(/obj/effect/hallucination/simple, run_loc_floor_bottom_left, target)
	var/datum/client_interface/holder_viewer/gone = new
	gone_vision.owner_client = gone
	SEND_SIGNAL(target, COMSIG_MOB_CLIENT_LOGOUT, null)

	TEST_ASSERT(kept_live, "Живой клиент после смены тела должен остаться, чтобы с него сняли картинку")
	TEST_ASSERT(!kept_after_quit, "Клиент, вышедший из нового тела, не должен держаться в галлюцинации")
	TEST_ASSERT(isnull(gone_vision.owner_client), "Удалённый клиент не должен держаться в галлюцинации")

/// Админская панель, удаляемая при закрытии, не оставляет клиента в очереди SSgarbage
/datum/unit_test/closed_admin_panel_drops_client

/datum/unit_test/closed_admin_panel_drops_client/Run()
	var/datum/outfit_manager/panel = new(null)
	panel.owner = new /datum/client_interface/holder_viewer
	panel.ui_close(null)
	TEST_ASSERT(isnull(panel.owner), "Закрытая панель снаряжения держит клиента")

/// Окно секретов закрыли, пока ui_act спит на подтверждении: после него действие пишет лог от имени админа, клиент нужен живым
/datum/unit_test/closed_admin_panel_keeps_live_client

/datum/unit_test/closed_admin_panel_keeps_live_client/Run()
	var/datum/client_interface/holder_viewer/admin = new
	GLOB.clients += admin
	var/datum/secrets_menu/secrets = new(allocate(/mob/living/carbon/human))
	secrets.holder = admin
	secrets.ui_close()
	var/secrets_kept = (secrets.holder == admin)
	var/datum/outfit_manager/outfits = new(null)
	outfits.owner = admin
	outfits.ui_close(null)
	var/outfits_kept = (outfits.owner == admin)
	GLOB.clients -= admin

	TEST_ASSERT(secrets_kept, "Закрытие секретов отняло клиента у спящего ui_act")
	TEST_ASSERT(outfits_kept, "Закрытие панели снаряжения отняло клиента у спящего ui_act")

/// Экран карты (меню профессий, hardlight, создание персонажа) отпускает удалённого клиента, даже если его не закрыли через ui_close
/datum/unit_test/map_view_drops_deleted_client

/datum/unit_test/map_view_drops_deleted_client/Run()
	var/atom/movable/screen/map_view/view = allocate(/atom/movable/screen/map_view)
	view.generate_view("logout_holder_test_view")
	var/datum/client_interface/holder_viewer/viewer = new
	view.display_to_client(viewer)
	TEST_ASSERT(view.registered_client == viewer, "Экран карты должен запомнить зрителя")

	SEND_SIGNAL(viewer, COMSIG_PARENT_QDELETING, FALSE)

	TEST_ASSERT(isnull(view.registered_client), "Удалённый клиент не должен держаться в экране карты")
	TEST_ASSERT(!(viewer in view.popup_plane_group.registered_clients), "Удалённый клиент должен уйти из стопки экрана карты")

/// Подсветка создателя шаттлов и админские панели логов отпускают удалённого клиента
/datum/unit_test/tool_overlays_drop_deleted_client

/datum/unit_test/tool_overlays_drop_deleted_client/Run()
	var/datum/shuttle_creator_overlay_holder/overlay = new
	var/datum/client_interface/holder_viewer/builder = new
	overlay.add_client(builder)
	SEND_SIGNAL(builder, COMSIG_PARENT_QDELETING, FALSE)
	var/overlay_kept = !isnull(overlay.holder)
	qdel(overlay)

	var/datum/admin_log_viewer/panel = new(new /datum/client_interface/holder_viewer)
	SEND_SIGNAL(panel.owner, COMSIG_PARENT_QDELETING, FALSE)
	var/panel_kept = !isnull(panel.owner)
	qdel(panel)

	var/datum/log_viewer/player_logs = new(null)
	var/datum/client_interface/holder_viewer/target = new
	player_logs.set_target_client(target)
	SEND_SIGNAL(target, COMSIG_PARENT_QDELETING, FALSE)
	var/target_kept = !isnull(player_logs.target_client)
	qdel(player_logs)

	TEST_ASSERT(!overlay_kept, "Подсветка шаттла держит удалённого клиента")
	TEST_ASSERT(!panel_kept, "Панель логов админа держит удалённого клиента")
	TEST_ASSERT(!target_kept, "Логи игрока держат удалённого клиента цели")

/// Окно tgui уходящего моба: у него client ещё есть, когда у моба в Logout уже нет.
/datum/logout_test_window
	var/client

/datum/logout_test_ui
	var/datum/logout_test_window/window

/// Смена моба посреди голосования: ui_close в Logout видит user.client == null и снимает клиента по окну
/datum/unit_test/vote_drops_client_on_mob_change

/datum/unit_test/vote_drops_client_on_mob_change/Run()
	var/mob/living/carbon/human/old_body = allocate(/mob/living/carbon/human)
	var/datum/client_interface/holder_viewer/viewer = new
	var/datum/logout_test_ui/closing_ui = new
	closing_ui.window = new
	closing_ui.window.client = viewer
	SSvote.voting |= viewer

	SSvote.ui_close(old_body, closing_ui)
	var/kept = (viewer in SSvote.voting)
	SSvote.voting -= viewer

	TEST_ASSERT(!kept, "Голосование держит клиента, сменившего моба с открытым окном")
