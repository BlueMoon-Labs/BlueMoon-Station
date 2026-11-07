#define ANTAG_TRAINING_SWARMER_TEST_DISMANTLE_WAIT (12 SECONDS)

/datum/unit_test/proc/antag_training_swarmer_ready(mob/living/simple_animal/hostile/swarmer/body)
	var/list/budget = new_wait_budget(5 SECONDS, "задержка действия сворма")
	while(!(body.CheckActionCooldown() && body.CheckActionCooldown(immediate = TRUE)) && wait_budget_tick(budget))
		continue

/datum/unit_test/proc/antag_training_swarmer_free_side(mob/living/body)
	for(var/turf/open/side in orange(1, body))
		if(!side.is_blocked_turf() && !(locate(/obj/item) in side) && !(locate(/obj/structure) in side) && !(locate(/obj/machinery) in side) && !(locate(/mob/living) in side))
			return side
	return null

/datum/unit_test/proc/antag_training_swarmer_click(mob/living/simple_animal/hostile/swarmer/body, atom/target, params)
	antag_training_swarmer_ready(body)
	usr = body
	body.ClickOn(target, params)
	usr = null

/// Кнопка HUD без клетки: на клетке теста её держал бы кэш view() после удаления.
/datum/unit_test/proc/antag_training_swarmer_button(button_type)
	var/atom/movable/screen/button = new button_type
	allocated += button
	return button

/datum/unit_test/proc/antag_training_swarmer_press(atom/movable/screen/button, mob/user)
	usr = user
	button.Click()
	usr = null

/// Учебный сворм: кнопки пульта, поедание листов, разбор своей машины в ресурсы, отказ на обстановке ядра и чужих вещах, оболочка без призраков в лимите целей, перенос манекена внутри полигона, маяк строителя - отказ.
/datum/unit_test/antag_training_swarmer/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/swarmer)
	TEST_ASSERT(session.prepare(), "Полигон готовит сворма.")
	var/datum/antag_training_program/creature/swarmer/program = session.program
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/simple_animal/hostile/swarmer/training/body = session.current_body
	TEST_ASSERT(istype(body) && body.mind == session.avatar_mind, "Разум участника в учебном сворме-универсале.")
	var/datum/antagonist/swarmer_training/role = program.role(session)
	TEST_ASSERT(istype(role) && role.training == session, "Учебный датум сворма привязан к сеансу.")
	TEST_ASSERT_EQUAL(body.resources, body.max_resources, "Сворм появляется с полным запасом ресурсов.")
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	for(var/option in program.options)
		TEST_ASSERT(length(program.option_hints[option]), "У кнопки «[option]» есть подсказка.")
	body.forceMove(arena.zones["melee"]["spawn"])

	body.resources = 0
	antag_training_console_act(session, console, "program_option", list("option" = "Ресурсы до максимума"))
	TEST_ASSERT_EQUAL(body.resources, body.max_resources, "Кнопка доводит ресурсы до предела.")

	antag_training_console_act(session, console, "program_option", list("option" = "Материалы"))
	var/obj/item/stack/sheet/metal/metal = locate() in range(1, body)
	var/obj/item/stack/sheet/glass/glass = locate() in range(1, body)
	TEST_ASSERT(metal && glass, "Рядом лежат металл и стекло.")
	TEST_ASSERT_EQUAL(metal.training_owner?.resolve(), session, "Материалы принадлежат участнику.")
	body.resources = 0
	var/sheets = metal.amount
	antag_training_swarmer_click(body, metal)
	TEST_ASSERT_EQUAL(body.resources, 1, "Лист металла даёт единицу ресурсов.")
	TEST_ASSERT_EQUAL(metal.amount, sheets - 1, "Стопка теряет один лист.")
	qdel(metal)
	qdel(glass)

	var/list/budget = new_wait_budget(5 SECONDS, "задержка выдачи")
	while(world.time < session.next_supply_at && wait_budget_tick(budget))
		continue
	antag_training_console_act(session, console, "program_option", list("option" = "Машина на разбор"))
	var/obj/machinery/recharger/machine
	for(var/obj/machinery/recharger/candidate in range(1, body))
		if(candidate.training_owner?.resolve() == session)
			machine = candidate
	TEST_ASSERT_NOTNULL(machine, "Рядом стоит машина участника.")
	var/turf/machine_spot = get_turf(machine)
	antag_training_swarmer_ready(body)
	usr = body
	INVOKE_ASYNC(body, TYPE_PROC_REF(/mob, ClickOn), machine)
	usr = null
	budget = new_wait_budget(20 SECONDS, "разбор машины")
	while(!QDELETED(machine) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(QDELETED(machine), "Клик по своей машине разбирает её.")
	var/obj/item/stack/sheet/metal/scrap = locate() in machine_spot
	TEST_ASSERT_NOTNULL(scrap, "Разбор оставляет металл.")
	body.resources = 0
	antag_training_swarmer_click(body, scrap)
	TEST_ASSERT_EQUAL(body.resources, 1, "Металл разобранной машины съедается в ресурсы.")

	var/turf/side = antag_training_swarmer_free_side(body)
	TEST_ASSERT_NOTNULL(side, "Рядом есть свободная клетка.")
	var/obj/machinery/recharger/fixture = allocate(/obj/machinery/recharger, side)
	GLOB.unit_test_chat_capture = list()
	antag_training_swarmer_click(body, fixture)
	var/core_refused = antag_training_chat_heard(body, "Обстановку ядра")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(!QDELETED(fixture) && core_refused, "Машину ядра полигона сворм не разбирает.")
	side = antag_training_swarmer_free_side(body)
	var/datum/stranger = new
	allocated += stranger
	var/obj/item/stack/sheet/glass/foreign = allocate(/obj/item/stack/sheet/glass, side, 5)
	foreign.training_owner = WEAKREF(stranger)
	antag_training_swarmer_click(body, foreign)
	TEST_ASSERT(!QDELETED(foreign) && foreign.amount == 5 && body.resources == 1, "Стекло другого участника сворм не ест.")
	var/obj/structure/sign/antag_training_board/board = locate() in range(4, arena.zones["melee"]["spawn"])
	TEST_ASSERT_NOTNULL(board, "В зоне ближнего боя стоит стенд.")
	for(var/turf/open/near in orange(1, board))
		if(!near.is_blocked_turf() && !(locate(/mob/living) in near))
			body.forceMove(near)
			break
	var/board_integrity = board.obj_integrity
	antag_training_swarmer_click(body, board)
	TEST_ASSERT(!QDELETED(board) && board.obj_integrity == board_integrity, "Стенд полигона сворм не трогает.")

	body.forceMove(arena.zones["melee"]["spawn"])
	body.resources = body.max_resources
	var/spawners_before = length(GLOB.mob_spawners)
	var/pois_before = length(GLOB.poi_list)
	var/atom/movable/screen/swarmer/Replicate/replicate = antag_training_swarmer_button(/atom/movable/screen/swarmer/Replicate)
	INVOKE_ASYNC(src, PROC_REF(antag_training_swarmer_press), replicate, body)
	budget = new_wait_budget(20 SECONDS, "репликация")
	while(!(locate(/obj/structure/antag_training_swarmer_shell) in get_turf(body)) && wait_budget_tick(budget))
		continue
	var/obj/structure/antag_training_swarmer_shell/shell = locate() in get_turf(body)
	TEST_ASSERT_NOTNULL(shell, "Кнопка репликации создаёт учебную оболочку.")
	TEST_ASSERT_NULL(locate(/obj/effect/mob_spawn) in get_turf(body), "Репликация не создаёт спавнер для призраков.")
	TEST_ASSERT_EQUAL(length(GLOB.mob_spawners), spawners_before, "Меню спавнеров призраков не меняется.")
	TEST_ASSERT_EQUAL(length(GLOB.poi_list), pois_before, "Оболочка не попадает в меню орбиты.")
	TEST_ASSERT((shell in arena.targets) && shell.training_owner?.resolve() == session, "Оболочка - цель участника в общем лимите.")
	TEST_ASSERT_EQUAL(body.resources, body.max_resources - body.replicate_cost, "Репликация тратит свою цену.")
	antag_training_swarmer_click(body, shell)
	TEST_ASSERT(QDELETED(shell) && !(shell in arena.targets), "Съеденная оболочка снимается с учёта.")
	TEST_ASSERT_EQUAL(body.resources, body.max_resources, "Съеденная оболочка возвращает цену.")

	var/turf/spot = arena.zones["melee"]["target"]
	while(arena.has_target_room())
		TEST_ASSERT(arena.claim_target(new /obj/item/pen(spot), session), "Свободное место в лимите принимает цель.")
	GLOB.unit_test_chat_capture = list()
	INVOKE_ASYNC(src, PROC_REF(antag_training_swarmer_press), replicate, body)
	budget = new_wait_budget(20 SECONDS, "отказ репликации по лимиту")
	while(!antag_training_chat_heard(body, arena.target_limit_refusal()) && wait_budget_tick(budget))
		continue
	var/limit_refused = antag_training_chat_heard(body, arena.target_limit_refusal())
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(limit_refused, "Сверх лимита целей репликация отказывает с сообщением.")
	TEST_ASSERT_NULL(locate(/obj/structure/antag_training_swarmer_shell) in get_turf(body), "Сверх лимита оболочка не создаётся.")
	TEST_ASSERT_EQUAL(body.resources, body.max_resources, "Отказ не тратит ресурсы.")
	for(var/obj/item/pen/pen in spot)
		qdel(pen)

	antag_training_console_act(session, console, "program_option", list("option" = "Цель для переноса"))
	var/mob/living/carbon/human/dummy
	for(var/mob/living/carbon/human/candidate in arena.targets)
		if(candidate.training_owner?.resolve() == session)
			dummy = candidate
	TEST_ASSERT_NOTNULL(dummy, "Цель для переноса создана и принадлежит участнику.")
	TEST_ASSERT_EQUAL(arena.match_zone(dummy), "melee", "Цель встаёт в зоне сворма.")
	TEST_ASSERT(dummy.Adjacent(body), "Цель стоит вплотную к сворму.")
	antag_training_swarmer_ready(body)
	usr = body
	INVOKE_ASYNC(body, TYPE_PROC_REF(/mob, ClickOn), dummy, "ctrl=1")
	usr = null
	budget = new_wait_budget(10 SECONDS, "перенос цели")
	while(arena.match_zone(dummy) == "melee" && wait_budget_tick(budget))
		continue
	var/dummy_zone = arena.match_zone(dummy)
	TEST_ASSERT(arena.owns_area(get_area(dummy)) && dummy_zone != "melee" && dummy_zone != "hub" && arena.zones[dummy_zone], "Ctrl+клик переносит манекен в другую зону полигона, но не в центр.")
	TEST_ASSERT(istype(dummy.handcuffed, /obj/item/restraints/handcuffs/energy), "Перенесённый человек скован энергонаручниками.")

	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option(/mob/living/simple_animal/hostile/swarmer/builder/training)))
	var/mob/living/simple_animal/hostile/swarmer/builder/training/builder = session.current_body
	TEST_ASSERT(istype(builder) && builder.mind == session.avatar_mind && QDELETED(body), "Смена вида пересаживает участника в строителя.")
	TEST_ASSERT_EQUAL(builder.resources, builder.max_resources, "Строитель появляется с полным запасом.")
	var/ai_swarmers = length(GLOB.AISwarmers)
	var/atom/movable/screen/swarmer/CreateSwarmBeacon/beacon_button = antag_training_swarmer_button(/atom/movable/screen/swarmer/CreateSwarmBeacon)
	GLOB.unit_test_chat_capture = list()
	usr = builder
	beacon_button.Click()
	usr = null
	var/beacon_refused = antag_training_chat_heard(builder, "На полигоне недоступно")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(beacon_refused, "Маяк роя на полигоне отказывает с сообщением.")
	TEST_ASSERT_NULL(locate(/mob/living/simple_animal/hostile/megafauna/swarmer_swarm_beacon) in range(2, builder), "Маяк роя не создаётся.")
	TEST_ASSERT_EQUAL(builder.resources, builder.max_resources, "Отказ маяка не тратит ресурсы.")
	TEST_ASSERT_EQUAL(length(GLOB.AISwarmers), ai_swarmers, "ИИ-свормов не прибавляется.")
	pass(view(0, run_loc_floor_bottom_left))

/// Связь роя, событие свормов и меню орбиты не видят учебного сворма, а для свормов станции работают как прежде.
/datum/unit_test/antag_training_swarmer_isolated/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/swarmer)
	TEST_ASSERT(session.prepare(), "Полигон готовит сворма.")
	var/mob/living/simple_animal/hostile/swarmer/training/body = session.current_body
	var/mob/living/simple_animal/hostile/swarmer/training/partner = allocate(/mob/living/simple_animal/hostile/swarmer/training, get_turf(body))
	TEST_ASSERT_EQUAL(partner.training_origin?.resolve(), session.arena, "Второй учебный сворм на полигоне.")
	var/mob/living/simple_animal/hostile/swarmer/station_swarmer = allocate(/mob/living/simple_animal/hostile/swarmer, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/swarmer/station_partner = allocate(/mob/living/simple_animal/hostile/swarmer, run_loc_floor_bottom_left)
	var/mob/dead/observer/outsider = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/mob/dead/observer/watcher = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	watcher.forceMove(get_turf(body))

	GLOB.unit_test_chat_capture = list()
	body.say("[MODE_TOKEN_BINARY] swarm-arena-probe")
	station_swarmer.say("[MODE_TOKEN_BINARY] swarm-station-probe")
	var/partner_heard = antag_training_chat_heard(partner, "swarm-arena-probe")
	var/watcher_heard = antag_training_chat_heard(watcher, "swarm-arena-probe")
	var/outsider_heard_training = antag_training_chat_heard(outsider, "swarm-arena-probe")
	var/station_heard_training = antag_training_chat_heard(station_partner, "swarm-arena-probe")
	var/training_heard_station = antag_training_chat_heard(partner, "swarm-station-probe")
	var/station_heard_station = antag_training_chat_heard(station_partner, "swarm-station-probe")
	var/outsider_heard_station = antag_training_chat_heard(outsider, "swarm-station-probe")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(partner_heard && watcher_heard, "Связь роя полигона слышат его свормы и наблюдатель на полигоне.")
	TEST_ASSERT(!outsider_heard_training && !station_heard_training, "Связь роя полигона не слышат наблюдатели и свормы станции.")
	TEST_ASSERT(!training_heard_station, "Учебный сворм не слышит рой станции.")
	TEST_ASSERT(station_heard_station && outsider_heard_station, "Рой станции по-прежнему слышат его свормы и наблюдатели.")

	var/datum/round_event/spawn_swarmer/event = new(FALSE)
	body.mock_client = new /datum/client_interface()
	var/training_blocks = event.find_swarmer()
	station_swarmer.mock_client = new /datum/client_interface()
	var/station_blocks = event.find_swarmer()
	body.mock_client = null
	station_swarmer.mock_client = null
	event.kill()
	qdel(event)
	TEST_ASSERT(!training_blocks, "Учебный сворм с игроком не мешает событию свормов.")
	TEST_ASSERT(station_blocks, "Сворм станции с игроком по-прежнему блокирует событие.")

	station_swarmer.mind_initialize()
	allocated += station_swarmer.mind
	var/datum/orbit_menu/menu = new(outsider)
	allocated += menu
	var/list/antagonist_refs = list()
	for(var/list/entry as anything in menu.ui_static_data(outsider)["antagonists"])
		antagonist_refs += entry["ref"]
	TEST_ASSERT(!(orbit_poi_ref(body) in antagonist_refs), "Учебный сворм не виден призракам среди антагонистов.")
	TEST_ASSERT(orbit_poi_ref(station_swarmer) in antagonist_refs, "Сворм станции по-прежнему виден призракам среди антагонистов.")

/// На общем полигоне сворм не ест стартовый набор и оболочку другого участника и не переносит его самого, в центре не ставит ловушек, а его оболочки, ловушки и баррикады уходят с его выходом.
/datum/unit_test/antag_training_swarmer_others/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/swarmer)
	TEST_ASSERT(session.prepare(), "Полигон готовит сворма.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_session/other = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(other.prepare(arena), "Второй участник входит на тот же полигон.")
	var/mob/living/simple_animal/hostile/swarmer/training/body = session.current_body
	var/mob/living/carbon/human/stranger = other.current_body
	var/obj/item/restraints/handcuffs/kit_item = stranger.l_store
	TEST_ASSERT(istype(kit_item) && kit_item.training_kit_owner?.resolve() == other, "Наручники из набора второго участника помечены его сеансом.")
	TEST_ASSERT_NULL(kit_item.training_owner, "Метка набора не делает предмет объектом для очистки.")

	body.forceMove(arena.zones["melee"]["spawn"])
	var/turf/side = antag_training_swarmer_free_side(body)
	stranger.transferItemToLoc(kit_item, side, TRUE)
	body.resources = 0
	antag_training_swarmer_click(body, kit_item)
	TEST_ASSERT(!QDELETED(kit_item) && kit_item.loc == side && body.resources == 0, "Предмет набора другого участника в ядре не съедается.")
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	TEST_ASSERT(sector.load(), "Тёмный сектор загружается.")
	side = null
	for(var/turf/open/floor/spot in sector.turfs)
		if(spot.is_blocked_turf())
			continue
		body.forceMove(spot)
		side = antag_training_swarmer_free_side(body)
		if(side)
			break
	TEST_ASSERT(side && istype(get_area(side), /area/antag_training/sector), "Рядом со свормом есть свободный пол сектора.")
	kit_item.forceMove(side)
	antag_training_swarmer_click(body, kit_item)
	TEST_ASSERT(!QDELETED(kit_item) && kit_item.loc == side && body.resources == 0, "Предмет набора другого участника в секторе не съедается.")

	var/obj/structure/antag_training_swarmer_shell/foreign_shell = new(side)
	foreign_shell.resource_value = body.replicate_cost
	TEST_ASSERT(arena.claim_target(foreign_shell, other), "Оболочка второго участника учтена за ним.")
	antag_training_swarmer_click(body, foreign_shell)
	TEST_ASSERT(!QDELETED(foreign_shell) && body.resources == 0, "Оболочку другого участника сворм не ест.")
	qdel(foreign_shell)

	stranger.forceMove(side)
	var/turf/stranger_spot = get_turf(stranger)
	GLOB.unit_test_chat_capture = list()
	antag_training_swarmer_click(body, stranger, "ctrl=1")
	var/person_refused = antag_training_chat_heard(body, "Других участников")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(person_refused && get_turf(stranger) == stranger_spot && !stranger.handcuffed, "Другого участника сворм не переносит.")
	var/floor_type = side.type
	side.ChangeTurf(/turf/open/space/basic)
	GLOB.unit_test_chat_capture = list()
	antag_training_swarmer_click(body, side)
	var/space_refused = antag_training_chat_heard(body, "участник")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(space_refused && !stranger.IsKnockdown() && !QDELETED(kit_item), "Клик по космосу сектора под другим участником его не задевает.")
	side.ChangeTurf(floor_type)

	body.forceMove(arena.zones["melee"]["spawn"])
	var/obj/machinery/recharger/machine = new(antag_training_swarmer_free_side(body))
	machine.training_owner = WEAKREF(session)
	antag_training_swarmer_ready(body)
	usr = body
	INVOKE_ASYNC(body, TYPE_PROC_REF(/mob, ClickOn), machine)
	usr = null
	machine.training_owner = WEAKREF(other)
	var/list/budget = new_wait_budget(ANTAG_TRAINING_SWARMER_TEST_DISMANTLE_WAIT, "разбор машины, сменившей владельца")
	while(!QDELETED(machine) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!QDELETED(machine), "Машина, ставшая чужой за время разбора, не разбирается.")
	qdel(machine)

	body.forceMove(arena.entry_turf)
	body.resources = body.max_resources
	var/atom/movable/screen/swarmer/FabricateTrap/trap_button = antag_training_swarmer_button(/atom/movable/screen/swarmer/FabricateTrap)
	var/atom/movable/screen/swarmer/Barricade/barricade_button = antag_training_swarmer_button(/atom/movable/screen/swarmer/Barricade)
	var/atom/movable/screen/swarmer/Replicate/replicate_button = antag_training_swarmer_button(/atom/movable/screen/swarmer/Replicate)
	antag_training_swarmer_press(trap_button, body)
	TEST_ASSERT(!(locate(/obj/structure/swarmer/trap) in get_turf(body)) && body.resources == body.max_resources, "В безопасном центре ловушка не ставится.")

	body.forceMove(arena.zones["melee"]["spawn"])
	antag_training_swarmer_press(trap_button, body)
	var/obj/structure/swarmer/trap/trap = locate() in get_turf(body)
	TEST_ASSERT(trap && trap.training_owner?.resolve() == session, "На площадке ловушка ставится и принадлежит участнику.")
	body.forceMove(get_step(body, WEST))
	antag_training_swarmer_press(barricade_button, body)
	INVOKE_ASYNC(src, PROC_REF(antag_training_swarmer_press), replicate_button, body)
	budget = new_wait_budget(20 SECONDS, "оболочка")
	while(!(locate(/obj/structure/antag_training_swarmer_shell) in get_turf(body)) && wait_budget_tick(budget))
		continue
	var/obj/structure/swarmer/blockade/barricade = locate() in get_turf(body)
	var/obj/structure/antag_training_swarmer_shell/shell = locate() in get_turf(body)
	TEST_ASSERT(barricade && shell, "Баррикада и оболочка построены.")
	qdel(session)
	budget = new_wait_budget(30 SECONDS, "уборка построек сворма")
	while(!(QDELETED(trap) && QDELETED(barricade) && QDELETED(shell)) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(QDELETED(trap) && QDELETED(barricade) && QDELETED(shell), "Выход участника убирает его оболочки, ловушки и баррикады.")
	TEST_ASSERT(!other.finished && !QDELETED(kit_item), "Второй участник и его вещи остаются.")

#undef ANTAG_TRAINING_SWARMER_TEST_DISMANTLE_WAIT
