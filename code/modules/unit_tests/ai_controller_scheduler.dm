// ===== Событийный планировщик AI-контроллеров =====
//
// Проверяют контракт сна/пробуждения: спящий (AI_STATUS_IDLE) контроллер не
// состоит ни в одной очереди обработки; клиент, вошедший в отслеживаемую
// ячейку грида, будит его синхронно (латентность = 0 тиков, требование спеки
// - не позднее 0.5 c); уход клиента усыпляет; вход клиента в пауна гасит.

///Тестовый контроллер: без сабтри и без idle-поведения
/datum/ai_controller/unit_test_dormant

///Тестовый контроллер с фоновым брождением
/datum/ai_controller/unit_test_wanderer
	idle_behavior = /datum/idle_behavior/idle_random_walk

///Хелпер: "игрок" для CLIENTS-канала на клетке turf
/datum/unit_test/proc/register_fake_player(mob/living/carbon/human/fake_player, turf/where)
	fake_player.forceMove(where)
	if(!islist(SSmobs.clients_by_zlevel) || where.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	SSmobs.clients_by_zlevel[where.z] |= fake_player
	fake_player.enable_client_mobs_in_contents()

/datum/unit_test/proc/unregister_fake_player(mob/living/carbon/human/fake_player)
	var/turf/where = get_turf(fake_player)
	if(where && islist(SSmobs.clients_by_zlevel) && where.z <= SSmobs.clients_by_zlevel.len)
		SSmobs.clients_by_zlevel[where.z] -= fake_player
	fake_player.clear_important_client_contents()

///Спящий контроллер: ноль обработки; вход клиента в ячейку будит синхронно
/datum/unit_test/ai_scheduler_wake_and_sleep/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	var/turf/far_turf = locate(1, 1, run_loc_floor_bottom_left.z)
	if(get_dist(far_turf, run_loc_floor_bottom_left) <= 40)
		far_turf = locate(world.maxx - 1, world.maxy - 1, run_loc_floor_bottom_left.z)
	register_fake_player(fake_player, far_turf)

	var/datum/ai_controller/unit_test_dormant/controller = new(pawn)

	//клиенты на z есть, но далеко: контроллер обязан уснуть
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_IDLE, "A controller with a far-away player must settle into AI_STATUS_IDLE")
	TEST_ASSERT(controller in GLOB.ai_controllers_by_status[AI_STATUS_IDLE], "Idle controller must be in the IDLE bucket")
	TEST_ASSERT(!(controller in SSai_behaviors.processing), "Idle controller must not be in behavior processing")
	TEST_ASSERT(!(controller in GLOB.unplanned_controllers), "Idle controller must not be in the unplanned pool")
	TEST_ASSERT(!(controller in SSai_controllers.currentrun), "Idle controller must not be in the planner's current run")

	//клиент входит в отслеживаемую ячейку: пробуждение в момент сигнала
	fake_player.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "A client entering a tracked cell must wake the controller synchronously")

	//клиент уходит далеко: контроллер снова засыпает
	fake_player.forceMove(far_turf)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_IDLE, "A client leaving the window must put the controller back to sleep")

	unregister_fake_player(fake_player)
	qdel(controller)

///Пустой z (ноль клиентов) = AI_STATUS_OFF, не IDLE
/datum/unit_test/ai_scheduler_off_on_empty_z/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human)
	var/turf/pawn_turf = get_turf(pawn)
	if(!islist(SSmobs.clients_by_zlevel) || pawn_turf.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	var/list/saved_clients = SSmobs.clients_by_zlevel[pawn_turf.z].Copy()
	SSmobs.clients_by_zlevel[pawn_turf.z].Cut()

	var/datum/ai_controller/unit_test_dormant/controller = new(pawn)
	var/status_no_clients = controller.ai_status

	SSmobs.clients_by_zlevel[pawn_turf.z] += saved_clients
	TEST_ASSERT_EQUAL(status_no_clients, AI_STATUS_OFF, "A controller on a clientless z-level must be AI_STATUS_OFF")
	qdel(controller)

///Первый клиент должен попасть в z-реестр до пересчёта OFF-контроллеров
/datum/unit_test/ai_scheduler_first_client_wakes_zlevel/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	var/turf/pawn_turf = get_turf(pawn)
	if(!islist(SSmobs.clients_by_zlevel) || pawn_turf.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	var/list/saved_clients = SSmobs.clients_by_zlevel[pawn_turf.z].Copy()
	SSmobs.clients_by_zlevel[pawn_turf.z].Cut()

	fake_player.forceMove(pawn_turf)
	var/datum/ai_controller/unit_test_dormant/controller = new(pawn)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_OFF, "Sanity: a controller on an empty z-level must start OFF")

	//Порядок настоящего Login(): сначала CLIENTS-канал в /mob/Login(), затем
	//z-реестр в /mob/living/Login(). audiovisual_redirect включает ту же ветку без реального client.
	fake_player.enable_client_mobs_in_contents()
	fake_player.audiovisual_redirect = fake_player
	fake_player.update_z(pawn_turf.z)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "The first client entering a z-level must wake nearby OFF controllers")

	fake_player.audiovisual_redirect = null
	fake_player.update_z(null)
	fake_player.clear_important_client_contents()
	SSmobs.clients_by_zlevel[pawn_turf.z] += saved_clients
	qdel(controller)

///Вход клиента в пауна гасит контроллер, выход - возвращает к жизни
/datum/unit_test/ai_scheduler_client_possession/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	register_fake_player(fake_player, run_loc_floor_bottom_left)

	var/datum/ai_controller/unit_test_dormant/controller = new(pawn)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "Sanity: controller near a player must be ON")

	SEND_SIGNAL(pawn, COMSIG_MOB_CLIENT_LOGIN)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_OFF, "Client login must turn the controller OFF")

	SEND_SIGNAL(pawn, COMSIG_MOB_CLIENT_LOGOUT)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "Client logout must restore the controller")

	unregister_fake_player(fake_player)
	qdel(controller)

///Смерть пауна гасит контроллер, оживление возвращает
/datum/unit_test/ai_scheduler_death_revive/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	register_fake_player(fake_player, run_loc_floor_bottom_left)

	var/datum/ai_controller/unit_test_dormant/controller = new(pawn)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "Sanity: controller near a player must be ON")

	pawn.death()
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_OFF, "A dead pawn's controller must be OFF")

	pawn.revive(TRUE, TRUE)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "A revived pawn's controller must come back ON")

	unregister_fake_player(fake_player)
	qdel(controller)

///Активный контроллер без плана бродит через idle_behavior (бывший no-op починен)
/datum/unit_test/ai_scheduler_unplanned_idle_walk/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	register_fake_player(fake_player, run_loc_floor_bottom_left)

	var/datum/ai_controller/unit_test_wanderer/controller = new(pawn)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "Sanity: controller near a player must be ON")
	TEST_ASSERT(controller in GLOB.unplanned_controllers, "An ON controller with no plan and an idle_behavior must be in the unplanned pool")
	TEST_ASSERT_NOTNULL(controller.idle_behavior, "idle_behavior typepath must be instanced by New()")

	//центр зоны 5x5: любой случайный шаг остаётся на полу резервации
	var/turf/center_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	pawn.forceMove(center_turf)
	//SPT_PROB(25, 100) с гигантским delta_time = гарантированный шаг
	var/turf/start_turf = get_turf(pawn)
	controller.idle_behavior.perform_idle_behavior(100, controller)
	TEST_ASSERT(get_turf(pawn) != start_turf, "perform_idle_behavior must actually move the pawn (the old core never called it)")

	unregister_fake_player(fake_player)
	qdel(controller)

///Nullspace немедленно снимает контроллер с z/grid, возврат регистрирует заново.
/datum/unit_test/ai_scheduler_nullspace_roundtrip/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	register_fake_player(fake_player, run_loc_floor_bottom_left)
	var/datum/ai_controller/unit_test_dormant/controller = new(pawn)
	var/old_z = pawn.z

	TEST_ASSERT(controller in GLOB.ai_controllers_by_zlevel[old_z], "Sanity: possessed pawn must be registered on its z-level")
	pawn.moveToNullspace()
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_OFF, "A nullspace pawn must turn its controller OFF immediately")
	TEST_ASSERT(!(controller in GLOB.ai_controllers_by_zlevel[old_z]), "Nullspace must remove the controller from its old z bucket")
	TEST_ASSERT(!length(controller.our_cells.member_cells), "Nullspace must release all spatial-grid cell subscriptions")

	pawn.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(controller in GLOB.ai_controllers_by_zlevel[old_z], "Returning from nullspace must restore z registration")
	TEST_ASSERT(length(controller.our_cells.member_cells), "Returning from nullspace must rebuild the tracked cell window")
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "Returning near a player must reactivate the controller")

	unregister_fake_player(fake_player)
	qdel(controller)

///Харддел пауна зануляет ссылку молча, и UnpossessPawn приходит уже с null.
///Ранний выход по isnull(pawn) стоял ДО remove_from_unplanned_controllers(),
///поэтому осиротевший контроллер оставался в пуле навсегда и фейлился каждый
///планировочный тик: 357 рантаймов idle_random_walk.dm за 16 прод-раундов.
/datum/unit_test/ai_controller_null_pawn_leaves_unplanned_pool/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	register_fake_player(fake_player, run_loc_floor_bottom_left)
	var/datum/ai_controller/unit_test_wanderer/controller = new(pawn)

	controller.add_to_unplanned_controllers()
	TEST_ASSERT(controller in GLOB.unplanned_controllers, "Sanity: an ON controller with an idle behavior must enter the unplanned pool")

	//именно так выглядит харддел пауна с точки зрения контроллера
	controller.pawn = null
	controller.UnpossessPawn(FALSE)

	TEST_ASSERT(!(controller in GLOB.unplanned_controllers), "A controller unpossessed with a null pawn must still leave the unplanned pool")
	TEST_ASSERT(!(controller in SSunplanned_controllers.currentrun), "A controller unpossessed with a null pawn must also leave the pool's current run")

	unregister_fake_player(fake_player)
	qdel(controller)

///Вторая линия обороны, и в проде она была единственной сработавшей: пул
///вычищал записи только по QDELETED, а осиротевший контроллер жив - его не
///удаляли, и он фейлился каждые 0.25 с сорок минут подряд (round-9887).
/datum/unit_test/ai_unplanned_pool_drops_null_pawn_controller/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	register_fake_player(fake_player, run_loc_floor_bottom_left)
	var/datum/ai_controller/unit_test_wanderer/controller = new(pawn)

	controller.add_to_unplanned_controllers()
	TEST_ASSERT(controller in GLOB.unplanned_controllers, "Sanity: an ON controller with an idle behavior must enter the unplanned pool")
	TEST_ASSERT(SSunplanned_controllers.run_unplanned_controller(controller), "Sanity: a healthy controller must run its idle behavior")

	//харддел пауна: контроллер жив, ссылка молча стала null
	controller.pawn = null

	TEST_ASSERT(!SSunplanned_controllers.run_unplanned_controller(controller), "A controller with a null pawn must not run its idle behavior")
	TEST_ASSERT(!(controller in GLOB.unplanned_controllers), "A controller with a null pawn must be evicted from the pool by the subsystem itself")

	unregister_fake_player(fake_player)
	qdel(controller)

///A malformed controller without background work is just as terminal for this
///pool entry as a deleted controller or pawn; retaining it retries a no-op forever.
/datum/unit_test/ai_unplanned_pool_drops_controller_without_idle_behavior/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/ai_controller/unit_test_dormant/controller = new(pawn)

	//Simulate a stale/malformed entry: the public adder correctly rejects it,
	//but the subsystem still has to clean one that already reached the pool.
	GLOB.unplanned_controllers[controller] = TRUE
	TEST_ASSERT(controller in GLOB.unplanned_controllers, "Sanity: the malformed controller must be present before the subsystem validates it")
	TEST_ASSERT(!SSunplanned_controllers.run_unplanned_controller(controller), "A controller without an idle behavior must report FALSE")
	TEST_ASSERT(!(controller in GLOB.unplanned_controllers), "A controller without an idle behavior must be evicted from the unplanned pool")

	qdel(controller)
