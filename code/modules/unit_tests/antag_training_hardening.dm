#define ANTAG_TRAINING_NOISE_WAIT (5 SECONDS)
#define ANTAG_TRAINING_NOISE_IGNITIONS 7
#define ANTAG_TRAINING_NOISE_CELL_STEP 3
#define ANTAG_TRAINING_NOISE_CELL_INSET 2
#define ANTAG_TRAINING_NOISE_FIRE_STACKS 2
#define ANTAG_TRAINING_WIND_SETTLE_FIRES 3
#define ANTAG_TRAINING_WIND_TOLERANCE 0

/// Пока тест держит список, message_admins складывает сюда свои сообщения.
GLOBAL_LIST(unit_test_admin_messages)

/// Камеры с сетью станции на полигоне не видны ИИ и консолям станции, станционные видны как раньше.
/datum/unit_test/antag_training_station_cameras/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/participant = session.current_body
	var/turf/arena_floor = session.arena.zones["melee"]["spawn"]
	participant.forceMove(arena_floor)
	var/obj/machinery/camera/arena_camera = new(arena_floor)
	arena_camera.c_tag = "Unit Test Arena Camera"
	var/obj/item/clothing/accessory/bodycamera/bodycam = new(arena_floor)
	participant.put_in_hands(bodycam)
	bodycam.melee_attack_chain(participant, participant.w_uniform)
	var/obj/machinery/camera/body_camera = bodycam.builtInCamera
	TEST_ASSERT(body_camera && ("ss13" in body_camera.network), "Бодикамера на полигоне включается в сеть станции.")
	body_camera.c_tag = "Unit Test Arena Bodycam"
	var/obj/machinery/camera/station_camera = allocate(/obj/machinery/camera, run_loc_floor_bottom_left)
	station_camera.c_tag = "Unit Test Station Camera"
	GLOB.cameranet.invalidate_camera_cache()

	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/station_ai = allocate(/mob/living/silicon/ai, run_loc_floor_bottom_left, null, donor)
	TEST_ASSERT_NOTNULL(station_ai.eyeobj, "У ИИ станции есть глаз.")
	var/list/ai_view = station_ai.get_camera_list()
	var/list/ai_cameras = list()
	for(var/camera_name in ai_view)
		ai_cameras += ai_view[camera_name]
	TEST_ASSERT(station_camera in ai_cameras, "ИИ станции видит станционную камеру.")
	TEST_ASSERT(!(arena_camera in ai_cameras), "ИИ станции не видит камеру сети ss13 на полигоне.")
	TEST_ASSERT(!(body_camera in ai_cameras), "ИИ станции не видит бодикамеру участника.")
	TEST_ASSERT(!station_ai.switchCamera(arena_camera) && !station_ai.switchCamera(body_camera), "ИИ станции не переходит к камерам полигона.")
	var/turf/eye_turf = get_turf(station_ai.eyeobj)
	TEST_ASSERT(eye_turf?.z != arena_floor.z, "Глаз ИИ станции не попадает на уровень полигона.")
	TEST_ASSERT(station_ai.switchCamera(station_camera), "ИИ станции переходит к станционной камере.")

	var/obj/machinery/computer/security/console = allocate(/obj/machinery/computer/security, run_loc_floor_bottom_left)
	var/list/console_view = console.get_available_cameras()
	TEST_ASSERT_EQUAL(console_view[station_camera.c_tag], station_camera, "Консоль станции показывает станционную камеру.")
	TEST_ASSERT(!console_view[body_camera.c_tag] && !console_view[arena_camera.c_tag], "Консоль станции не показывает камеры полигона.")

/// Насосы, канистры, взрыв, гранаты, горелка и аплинк на полигоне не пишут администраторам, те же действия на станции пишут.
/datum/unit_test/antag_training_admin_noise
	var/admin_entries_before = 0

/datum/unit_test/antag_training_admin_noise/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/participant = session.current_body
	participant.forceMove(session.arena.zones["melee"]["spawn"])
	var/mob/living/carbon/human/target = session.arena.spawn_target()
	target.forceMove(get_step(participant, EAST))
	var/list/arena_failed = list()
	var/list/arena_noise = noisy_actions(participant, target, arena_failed)

	var/mob/living/carbon/human/station_user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/station_target = allocate(/mob/living/carbon/human, get_step(station_user, EAST))
	var/list/station_failed = list()
	var/list/station_noise = noisy_actions(station_user, station_target, station_failed)

	var/list/loud = list()
	var/list/silent = list()
	for(var/action in arena_noise)
		if(arena_noise[action])
			loud += action
		if(!station_noise[action])
			silent += action
	TEST_ASSERT(!length(arena_failed), "На полигоне не сработало: [arena_failed.Join(", ")].")
	TEST_ASSERT(!length(station_failed), "На станции не сработало: [station_failed.Join(", ")].")
	TEST_ASSERT(!length(loud), "На полигоне пишут администраторам: [loud.Join(", ")].")
	TEST_ASSERT(!length(silent), "На станции не пишут администраторам: [silent.Join(", ")].")

/datum/unit_test/antag_training_admin_noise/proc/noisy_actions(mob/living/carbon/human/user, mob/living/carbon/human/target, list/failed)
	usr = user
	var/turf/spot = get_turf(user)
	var/list/before = spot.contents.Copy()
	. = list()

	for(var/pump_type in list(/obj/machinery/atmospherics/components/binary/pump, /obj/machinery/atmospherics/components/binary/volume_pump))
		var/obj/machinery/atmospherics/components/binary/pump = new pump_type(spot)
		var/datum/tgui/pump_ui = new(user, pump, "AtmosPump")
		pump_ui.status = UI_INTERACTIVE
		start_capture()
		pump.ui_act("power", list(), pump_ui)
		var/turned_on = pump.on
		pump.ui_act("power", list(), pump_ui)
		note_action(., failed, "[pump_type]: включение", turned_on && !pump.on, user, spot)
		qdel(pump_ui)
		var/obj/item/wrench/wrench = new(spot)
		start_capture()
		wrench.melee_attack_chain(user, pump)
		note_action(., failed, "[pump_type]: откручивание", QDELETED(pump), user, spot)

	var/obj/machinery/portable_atmospherics/canister/cut_canister = new(spot)
	var/obj/item/weldingtool/welder = new(spot)
	welder.switched_on(user)
	start_capture()
	welder.melee_attack_chain(user, cut_canister)
	note_action(., failed, "разрезание канистры", QDELETED(cut_canister), user, spot)

	var/obj/machinery/portable_atmospherics/canister/valve_canister = new(spot)
	var/obj/item/tank/internals/oxygen/tank = new(spot)
	user.put_in_hands(tank)
	tank.melee_attack_chain(user, valve_canister)
	var/datum/tgui/canister_ui = new(user, valve_canister, "Canister")
	canister_ui.status = UI_INTERACTIVE
	valve_canister.ui_act("valve", list(), canister_ui)
	var/open_with_tank = valve_canister.valve_open && valve_canister.holding == tank
	start_capture()
	valve_canister.ui_act("eject", list(), canister_ui)
	note_action(., failed, "баллон из открытой канистры", open_with_tank && !valve_canister.holding, user, spot)
	valve_canister.ui_act("valve", list(), canister_ui)
	qdel(canister_ui)

	start_capture()
	var/datum/explosion/blast = explosion(spot, 0, 0, 0, 0)
	wait_for_qdeleted(blast, ANTAG_TRAINING_NOISE_WAIT)
	note_action(., failed, "взрыв", !isnull(blast?.started_at), user, spot)

	var/obj/machinery/syndicatebomb/bomb = new(spot)
	start_capture()
	bomb.start_countdown(user)
	note_action(., failed, "взвод синдикатской бомбы", bomb.active, user, spot)
	qdel(bomb)

	for(var/grenade_type in list(/obj/item/grenade/flashbang, /obj/item/grenade/chem_grenade/teargas))
		var/obj/item/grenade/grenade = new grenade_type(spot)
		start_capture()
		grenade.attack_self(user)
		note_action(., failed, "[grenade_type]: взвод", grenade.active, user, spot)
		qdel(grenade)

	target.adjust_fire_stacks(ANTAG_TRAINING_NOISE_FIRE_STACKS)
	start_capture()
	welder.melee_attack_chain(user, target)
	note_action(., failed, "поджог горелкой", target.on_fire, user, spot)
	target.ExtinguishMob()

	var/obj/item/uplink/uplink = new(spot)
	var/datum/uplink_item/offer = new
	offer.item = /obj/item/pen
	var/saved_mode = GLOB.master_mode
	GLOB.master_mode = ROUNDTYPE_EXTENDED
	start_capture()
	offer.purchase(user, uplink.GetComponent(/datum/component/uplink), uplink)
	GLOB.master_mode = saved_mode
	var/obj/item/pen/bought = locate() in user.held_items
	note_action(., failed, "покупка в аплинке", bought, user, spot)
	qdel(bought)
	qdel(offer)

	GLOB.unit_test_admin_messages = null
	for(var/obj/leftover in spot.contents - before)
		qdel(leftover)

/// Записывает шум действия; действие без результата попадает в failed.
/datum/unit_test/antag_training_admin_noise/proc/note_action(list/results, list/failed, action, happened, mob/user, turf/spot)
	results[action] = captured(user, spot)
	if(!happened)
		failed += action

/datum/unit_test/antag_training_admin_noise/proc/start_capture()
	GLOB.unit_test_admin_messages = list()
	admin_entries_before = length(GLOB.admin_log_entries)

/// Число сообщений и записей лога администраторов о действии этого игрока или на этой клетке.
/datum/unit_test/antag_training_admin_noise/proc/captured(mob/user, turf/spot)
	var/list/markers = list(REF(user), "[spot.x], [spot.y], [spot.z]")
	var/list/texts = GLOB.unit_test_admin_messages.Copy()
	for(var/index in admin_entries_before + 1 to length(GLOB.admin_log_entries))
		texts += GLOB.admin_log_entries[index]
	. = 0
	for(var/text in texts)
		for(var/marker in markers)
			if(findtext(text, marker))
				.++
				break

/datum/unit_test/antag_training_admin_noise/Destroy()
	GLOB.unit_test_admin_messages = null
	return ..()

/// Поджог плазменных стены, пола, дверей, шлюза, листов и бумаги на полигоне не пишет администраторам, тот же поджог на уровне без полигона пишет.
/datum/unit_test/antag_training_admin_noise/plasma/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/participant = session.current_body
	participant.forceMove(arena.zones["pve"]["spawn"])
	var/list/bounds = arena.zones["pve"]["bounds"]
	var/level = arena.private_level.z_value
	var/cell_row = bounds[4] - ANTAG_TRAINING_NOISE_CELL_INSET
	var/datum/turf_reservation/outside = SSmapping.RequestBlockReservation(ANTAG_TRAINING_NOISE_IGNITIONS * ANTAG_TRAINING_NOISE_CELL_STEP, ANTAG_TRAINING_NOISE_CELL_STEP)
	TEST_ASSERT_NOTNULL(outside, "Есть клетки для поджога вне полигона.")
	allocated += outside
	var/list/turf/arena_spots = list()
	var/list/turf/outside_spots = list()
	for(var/index in 1 to ANTAG_TRAINING_NOISE_IGNITIONS)
		var/cell_offset = (index - 1) * ANTAG_TRAINING_NOISE_CELL_STEP + 1
		var/turf/open/cell = locate(bounds[1] + 1 + cell_offset, cell_row, level)
		for(var/turf/border in orange(1, cell))
			border.ChangeTurf(/turf/closed/indestructible)
		cell.air.clear()
		arena_spots += cell
		outside_spots += locate(outside.bottom_left_coords[1] + cell_offset, outside.bottom_left_coords[2] + 1, outside.bottom_left_coords[3])
	TEST_ASSERT(!is_antag_training_atom(outside_spots[1]), "Клетки для сравнения лежат вне уровней полигона.")
	var/list/arena_failed = list()
	var/list/arena_noise = ignitions(participant, arena_spots, arena_failed)

	var/mob/living/carbon/human/outsider = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/list/outside_failed = list()
	var/list/outside_noise = ignitions(outsider, outside_spots, outside_failed)
	for(var/turf/spot as anything in outside_spots)
		for(var/obj/leftover in spot)
			qdel(leftover)
		spot.ChangeTurf(/turf/open/space, /turf/open/space)

	var/list/loud = list()
	var/list/silent = list()
	for(var/target_name in arena_noise)
		if(arena_noise[target_name])
			loud += target_name
		if(!outside_noise[target_name])
			silent += target_name
	TEST_ASSERT(!length(arena_failed), "На полигоне не загорелись: [arena_failed.Join(", ")].")
	TEST_ASSERT(!length(outside_failed), "Вне полигона не загорелись: [outside_failed.Join(", ")].")
	TEST_ASSERT(!length(loud), "Поджог на полигоне пишет администраторам: [loud.Join(", ")].")
	TEST_ASSERT(!length(silent), "Поджог вне полигона не пишет администраторам: [silent.Join(", ")].")

/datum/unit_test/antag_training_admin_noise/plasma/proc/ignitions(mob/living/carbon/human/user, list/turf/spots, list/failed)
	. = list()
	var/obj/item/lighter/lighter = new(get_turf(user))
	lighter.set_lit(TRUE)
	var/turf/wall_spot = spots[1]
	var/turf/floor_spot = spots[2]
	var/list/targets = list(
		"плазменная стена" = wall_spot.ChangeTurf(/turf/closed/wall/mineral/plasma),
		"плазменный пол" = floor_spot.ChangeTurf(/turf/open/floor/mineral/plasma, null, CHANGETURF_INHERIT_AIR),
		"плазменная дверь" = new /obj/structure/mineral_door/transparent/plasma(spots[3]),
		"плазменная фальшстена" = new /obj/structure/falsewall/plasma(spots[4]),
		"плазменный шлюз" = new /obj/machinery/door/airlock/plasma(spots[5]),
		"бумага" = new /obj/item/paper(spots[6]),
		"плазменные листы" = new /obj/item/stack/sheet/mineral/plasma(spots[7]),
	)
	var/index = 0
	for(var/target_name in targets)
		var/atom/target = targets[target_name]
		var/target_type = target.type
		start_capture()
		lighter.melee_attack_chain(user, target)
		note_action(., failed, target_name, ignited(target, target_type), user, spots[++index])
	GLOB.unit_test_admin_messages = null
	qdel(lighter)

/datum/unit_test/antag_training_admin_noise/plasma/proc/ignited(atom/target, target_type)
	if(QDELETED(target) || target.type != target_type)
		return TRUE
	var/obj/burning = target
	return istype(burning) && (burning.resistance_flags & ON_FIRE)

/// Провал выдачи уровня снимает регистрацию общей арены, и следующий вход строит полигон заново.
/datum/unit_test/antag_training_prepare_failure/Run()
	wait_for_closing_training_arenas()
	TEST_ASSERT(!length(GLOB.antag_training_arenas), "Перед проверкой нет живых арен.")
	var/list/saved_levels = GLOB.antag_training_free_levels
	GLOB.antag_training_free_levels = list(null)
	var/datum/antag_training_arena/broken = allocate(/datum/antag_training_arena)
	var/prepared = broken.prepare()
	GLOB.antag_training_free_levels = saved_levels
	TEST_ASSERT(!prepared, "Без уровня арена не готовится.")
	TEST_ASSERT(!length(GLOB.antag_training_arenas), "Провалившаяся арена не остаётся в списке арен.")
	TEST_ASSERT(!GLOB.antag_training_building, "Провал не держит флаг постройки.")
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Следующий вход строит полигон.")
	TEST_ASSERT_EQUAL(GLOB.antag_training_arenas["shared"], session.arena, "В списке новая арена.")
	qdel(broken)
	TEST_ASSERT_EQUAL(GLOB.antag_training_arenas["shared"], session.arena, "Удаление провалившейся арены не снимает новую.")

/// Постройка и очистка полигона не выдувают воздух в космос: на клетках арены не поднимается космический ветер.
/datum/unit_test/antag_training_build_wind/Run()
	wait_for_closing_training_arenas()
	var/datum/antag_training_arena/arena = allocate(/datum/antag_training_arena)
	INVOKE_ASYNC(arena, TYPE_PROC_REF(/datum/antag_training_arena, prepare))
	var/build_peak = 0
	var/list/budget = new_wait_budget(2 MINUTES, "постройка полигона")
	while(!arena.ready && wait_budget_tick(budget))
		build_peak = max(build_peak, count_wind(arena.reservation?.reserved_turfs))
	TEST_ASSERT(arena.ready, "Полигон построен.")
	var/settled_fire = SSair.times_fired + ANTAG_TRAINING_WIND_SETTLE_FIRES
	budget = new_wait_budget(30 SECONDS, "SSair после постройки")
	while(SSair.times_fired < settled_fire && wait_budget_tick(budget))
		build_peak = max(build_peak, count_wind(arena.reservation.reserved_turfs))
	var/list/turf/arena_turfs = arena.reservation.reserved_turfs.Copy()
	arena.begin_cleanup()
	var/cleanup_peak = 0
	budget = new_wait_budget(1 MINUTES, "очистка полигона")
	while(!QDELETED(arena) && wait_budget_tick(budget))
		cleanup_peak = max(cleanup_peak, count_wind(arena_turfs))
	TEST_ASSERT(QDELETED(arena), "Полигон очищается.")
	TEST_ASSERT(build_peak <= ANTAG_TRAINING_WIND_TOLERANCE, "При постройке на арене одновременно до [build_peak] порывов ветра.")
	TEST_ASSERT(cleanup_peak <= ANTAG_TRAINING_WIND_TOLERANCE, "При очистке на арене одновременно до [cleanup_peak] порывов ветра.")

/datum/unit_test/antag_training_build_wind/proc/count_wind(list/turf/turfs)
	. = 0
	for(var/turf/open/floor in turfs)
		if(!QDELETED(floor.space_wind_visual))
			.++

/// Выгрузка сектора EVA убирает шлюзы и окна после откачки воздуха: на клетках сектора не поднимается космический ветер.
/datum/unit_test/antag_training_build_wind/sector_unload/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_sector/sector = session.arena.sectors["eva"]
	TEST_ASSERT(sector.load(), "Сектор EVA загружается.")
	var/list/turf/sector_turfs = sector.turfs.Copy()
	var/settled_fire = SSair.times_fired + ANTAG_TRAINING_WIND_SETTLE_FIRES
	var/list/budget = new_wait_budget(30 SECONDS, "ветер после загрузки сектора")
	var/load_wind = count_wind(sector_turfs)
	while((SSair.times_fired < settled_fire || load_wind) && wait_budget_tick(budget))
		load_wind = count_wind(sector_turfs)
	TEST_ASSERT(!load_wind, "Ветер после загрузки сектора EVA стихает, а не держится на [load_wind] клетках.")
	INVOKE_ASYNC(sector, TYPE_PROC_REF(/datum/antag_training_sector, unload))
	var/unload_peak = 0
	budget = new_wait_budget(1 MINUTES, "выгрузка сектора EVA")
	while(sector.state != ANTAG_TRAINING_SECTOR_UNLOADED && wait_budget_tick(budget))
		unload_peak = max(unload_peak, count_wind(sector_turfs))
	TEST_ASSERT_EQUAL(sector.state, ANTAG_TRAINING_SECTOR_UNLOADED, "Сектор EVA выгружается.")
	TEST_ASSERT(unload_peak <= ANTAG_TRAINING_WIND_TOLERANCE, "При выгрузке сектора EVA одновременно до [unload_peak] порывов ветра.")

#undef ANTAG_TRAINING_NOISE_WAIT
#undef ANTAG_TRAINING_NOISE_IGNITIONS
#undef ANTAG_TRAINING_NOISE_CELL_STEP
#undef ANTAG_TRAINING_NOISE_CELL_INSET
#undef ANTAG_TRAINING_NOISE_FIRE_STACKS
#undef ANTAG_TRAINING_WIND_SETTLE_FIRES
#undef ANTAG_TRAINING_WIND_TOLERANCE
