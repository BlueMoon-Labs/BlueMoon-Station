/datum/round_event_control/minor_outside/distress_capsule/test_site
	typepath = null
	var/turf/test_site

/datum/round_event_control/minor_outside/distress_capsule/test_site/find_site(first_only = FALSE)
	return test_site

/datum/round_event_control/minor_outside/derelict_satellite/test_site
	typepath = null
	var/turf/test_site

/datum/round_event_control/minor_outside/derelict_satellite/test_site/find_site(first_only = FALSE)
	return test_site

/datum/round_event_control/minor_outside/lost_mining_drone/test_site
	typepath = null
	var/turf/test_site

/datum/round_event_control/minor_outside/lost_mining_drone/test_site/find_site(first_only = FALSE)
	return test_site

/datum/round_event_control/tour_group/test_route
	typepath = null
	var/list/test_route = list()

/datum/round_event_control/tour_group/test_route/find_attractions()
	return test_route.Copy()

/datum/round_event/ghost_role/tour_group/no_volunteers

/datum/round_event/ghost_role/tour_group/no_volunteers/get_candidates(jobban, gametypecheck, be_special)
	return list()

/// Отсеки, которых нет на картах: медбей для выписки пилота и подотсеки библиотеки для маршрута.
/area/medical/minor_outside_test_ward
	name = "Minor Outside Test Ward"

/area/service/library/minor_outside_test_hall
	name = "Minor Outside Test Library"

/area/service/library/abandoned/minor_outside_test_ruin
	name = "Minor Outside Test Ruin"

/// Поверхность шахтёрского уровня под небом: с местной фауной и без неё.
/area/minor_outside_test_wastes
	name = "Minor Outside Test Wastes"
	outdoors = TRUE
	area_flags = UNIQUE_AREA | MOB_SPAWN_ALLOWED

/area/minor_outside_test_wastes/no_fauna
	name = "Minor Outside Test Quiet Wastes"
	area_flags = UNIQUE_AREA

/datum/unit_test/minor_incidents_outside
	var/list/turf/borrowed_turfs = list()

/datum/unit_test/minor_incidents_outside/Run()
	var/area/home_area = get_area(run_loc_floor_bottom_left)
	check_drone_lure_terrain()
	for(var/turf/borrowed as anything in borrowed_turfs)
		home_area.contents.Add(borrowed)
	check_hull_search()
	check_capsule_rescue()
	check_capsule_unclaimed()
	check_capsule_beacon()
	check_capsule_species_gear()
	check_capsule_discharge()
	check_satellite()
	check_mining_drone()
	check_drone_repair()
	check_tour_catalog()
	check_tour_stamps()
	check_tour_actions()
	check_tour_completion()
	check_tour_spawn()
	check_tour_director_release()
	check_tour_partial_release()

/datum/unit_test/minor_incidents_outside/proc/make_event(event_path)
	var/datum/round_event/event = allocate(event_path, FALSE)
	SSdirector.running -= event
	return event

/datum/unit_test/minor_incidents_outside/proc/claim_new_items(turf/spot, list/before)
	var/list/created = spot.contents - before
	allocated += created
	return created

/datum/unit_test/minor_incidents_outside/proc/department_balance(account_id)
	var/datum/bank_account/department/account = SSeconomy.get_dep_account(account_id)
	TEST_ASSERT_NOTNULL(account, "Нужен бюджет отдела [account_id]")
	return account.account_balance

/datum/unit_test/minor_incidents_outside/proc/personal_balance(mob/living/carbon/human/person)
	var/datum/bank_account/account = person.get_bank_account()
	return account?.account_balance

/// Сотрудник станции с надетой ID-картой и счётом на ней.
/datum/unit_test/minor_incidents_outside/proc/make_crew(turf/spot, job = "Assistant", list/access = list())
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human, spot)
	person.mind_initialize()
	person.mind.assigned_role = job
	var/datum/bank_account/account = allocate(/datum/bank_account, job, null)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = account
	card.access = access.Copy()
	person.equip_to_slot(card, ITEM_SLOT_ID)
	return person

/datum/unit_test/minor_incidents_outside/proc/make_tourist(turf/spot, list/route, datum/star_route_tour/tour)
	var/mob/living/carbon/human/tourist = allocate(/mob/living/carbon/human, spot)
	tourist.mind_initialize()
	tourist.mind.assigned_role = "Ghost Role"
	var/obj/item/tour_guidebook/guide = allocate(/obj/item/tour_guidebook, spot, route, tour)
	guide.set_owner(tourist)
	tourist.put_in_hands(guide)
	return guide

/// Найденная клетка у корпуса - открытый космос, обшивка не ближе заданного.
/datum/unit_test/minor_incidents_outside/proc/check_hull_search()
	TEST_ASSERT(!outside_is_clear_space(run_loc_floor_bottom_left, 2), "Пол тестовой комнаты не может быть местом в космосе")
	var/turf/site = outside_find_hull_space(2, 4)
	if(!site)
		log_test("minor_incidents_outside: на текущей станции нет космоса у внешних шлюзов")
		return
	TEST_ASSERT(isspaceturf(site) && istype(site.loc, /area/space), "Место капсулы должно быть в открытом космосе")
	TEST_ASSERT(is_station_level(site.z), "Место капсулы должно быть на станционном уровне")
	for(var/turf/nearby as anything in RANGE_TURFS(1, site))
		TEST_ASSERT(isspaceturf(nearby), "Капсула не должна касаться обшивки")

/datum/unit_test/minor_incidents_outside/proc/check_capsule_rescue()
	var/turf/spot = run_loc_floor_bottom_left
	var/datum/round_event_control/minor_outside/distress_capsule/test_site/control = allocate(/datum/round_event_control/minor_outside/distress_capsule/test_site)
	TEST_ASSERT(!control.director_preflight(), "Без космоса у обшивки капсула не должна тратить бюджет")
	TEST_ASSERT_NOTNULL(control.director_preflight_failure, "Провал preflight капсулы объясняется директору")
	TEST_ASSERT(!control.execute_action(), "Запуск без места должен сообщать об отказе")
	control.test_site = spot
	TEST_ASSERT(control.director_preflight(), "С местом у обшивки preflight должен проходить")
	var/datum/round_event/minor_outside/distress_capsule/event = make_event(/datum/round_event/minor_outside/distress_capsule)
	TEST_ASSERT(event.announce_when > event.start_when, "Экипаж узнаёт о капсуле позже гостов")
	event.control = control
	event.start()
	var/obj/structure/distress_capsule/capsule = event.spawned_ref?.resolve()
	TEST_ASSERT_NOTNULL(capsule, "Событие должно создавать капсулу")
	allocated += capsule
	TEST_ASSERT_EQUAL(capsule.loc, spot, "Капсула появляется в найденной клетке")
	var/datum/component/gps/gps = capsule.GetComponent(/datum/component/gps)
	TEST_ASSERT_EQUAL(gps?.gpstag, "Сигнал бедствия", "У капсулы должен быть GPS-сигнал бедствия")
	TEST_ASSERT(capsule.beacon_timer, "Закрытая капсула подаёт звуковой сигнал")
	var/obj/effect/mob_spawn/human/distress_survivor/spawner = capsule.spawner
	TEST_ASSERT_EQUAL(spawner?.loc, capsule, "Спаунер пилота лежит внутри капсулы")
	TEST_ASSERT(spawner in GLOB.mob_spawners[spawner.name], "Роль пилота видна в меню гост-ролей")
	TEST_ASSERT_EQUAL(spawner.category, "midround", "Пилот капсулы - мидраунд-роль в меню спаунеров")
	var/mob/living/carbon/human/survivor = spawner.create()
	allocated += survivor
	TEST_ASSERT_EQUAL(survivor.loc, capsule, "Пилот появляется внутри закрытой капсулы")
	TEST_ASSERT(QDELETED(spawner) && isnull(capsule.spawner), "Занятая роль убирает спаунер")
	TEST_ASSERT_NULL(capsule.wait_timer, "После занятия роли капсула не пустеет по таймеру")
	TEST_ASSERT(survivor.getBruteLoss() > 0 && survivor.getOxyLoss() > 0, "Пилот ранен и надышался дымом")
	TEST_ASSERT(survivor.health > 0, "Пилот ранен умеренно и в сознании")
	TEST_ASSERT(istype(survivor.wear_suit, /obj/item/clothing/suit/space/fragile), "Пилот в аварийном скафандре")
	TEST_ASSERT(istype(survivor.ears, /obj/item/radio/headset), "У пилота есть гарнитура")
	TEST_ASSERT(survivor.internal, "Баллон пилота подключён")
	TEST_ASSERT_NOTNULL(survivor.GetComponent(/datum/component/distress_rescue), "За пилотом следит премия медбею")
	TEST_ASSERT(capsule.open_hatch(), "Люк можно вскрыть")
	TEST_ASSERT_EQUAL(survivor.loc, spot, "Вскрытый люк выпускает пилота")
	TEST_ASSERT_NULL(capsule.beacon_timer, "Открытая капсула больше не пищит")
	TEST_ASSERT_NULL(capsule.GetComponent(/datum/component/gps), "Сигнал бедствия гаснет после вскрытия")
	TEST_ASSERT_EQUAL(capsule.icon_state, "capsule_open", "Вскрытая капсула выглядит открытой")
	TEST_ASSERT(!capsule.open_hatch(), "Открытый люк не вскрывается повторно")
	var/list/before = spot.contents.Copy()
	qdel(capsule)
	claim_new_items(spot, before)
	TEST_ASSERT(!QDELETED(survivor), "Удаление капсулы не трогает пилота")

/datum/unit_test/minor_incidents_outside/proc/check_capsule_unclaimed()
	var/turf/spot = run_loc_floor_top_right
	var/obj/structure/distress_capsule/waiting = allocate(/obj/structure/distress_capsule, spot)
	var/obj/effect/mob_spawn/human/distress_survivor/unclaimed = waiting.spawner
	var/role_name = unclaimed.name
	TEST_ASSERT(waiting.stop_waiting(), "Незанятая роль истекает")
	TEST_ASSERT(QDELETED(unclaimed), "Истёкший спаунер удаляется")
	TEST_ASSERT(!(unclaimed in GLOB.mob_spawners[role_name]), "Истёкшая роль пропадает из меню")
	TEST_ASSERT_NULL(waiting.beacon_timer, "Пустая капсула перестаёт пищать")
	TEST_ASSERT_NOTNULL(waiting.GetComponent(/datum/component/gps), "Сигнал пустой капсулы остаётся в GPS")
	var/obj/item/distress_flight_recorder/recorder = locate() in waiting
	TEST_ASSERT_NOTNULL(recorder, "В пустой капсуле остаётся самописец")
	TEST_ASSERT(locate(/obj/item/storage/firstaid/regular) in waiting, "В пустой капсуле остаётся аварийный набор")
	TEST_ASSERT(!waiting.stop_waiting(), "Набор выдаётся один раз")
	var/list/before = spot.contents.Copy()
	TEST_ASSERT(waiting.open_hatch(), "Пустую капсулу можно вскрыть")
	claim_new_items(spot, before)
	TEST_ASSERT_EQUAL(recorder.loc, spot, "Самописец выпадает из вскрытой капсулы")
	TEST_ASSERT(length(recorder.transcript) > 1, "Самописец хранит запись полёта")

	var/obj/structure/distress_capsule/early = allocate(/obj/structure/distress_capsule, spot)
	var/obj/effect/mob_spawn/human/distress_survivor/early_spawner = early.spawner
	before = spot.contents.Copy()
	TEST_ASSERT(early.open_hatch(), "Капсулу можно вскрыть до того, как роль займут")
	var/list/created = claim_new_items(spot, before)
	TEST_ASSERT(QDELETED(early_spawner), "Вскрытая пустая капсула закрывает роль пилота")
	TEST_ASSERT(locate(/obj/item/distress_flight_recorder) in created, "Во вскрытой пустой капсуле лежит самописец")
	TEST_ASSERT_NULL(early.wait_timer, "Вскрытая капсула не ждёт пилота")

/// Маяк пищит, пока не сел аккумулятор, и не крутит вечный цикл.
/datum/unit_test/minor_incidents_outside/proc/check_capsule_beacon()
	var/obj/structure/distress_capsule/capsule = allocate(/obj/structure/distress_capsule, run_loc_floor_top_right)
	capsule.silence_beacon()
	capsule.beacon_beep()
	TEST_ASSERT_NOTNULL(capsule.beacon_timer, "Пока аккумулятор жив, маяк ставит следующий писк")
	capsule.beacon_until = world.time
	capsule.silence_beacon()
	capsule.beacon_beep()
	TEST_ASSERT_NULL(capsule.beacon_timer, "Севший маяк больше не пищит")
	var/mob/living/carbon/human/rescuer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT(findtext(jointext(capsule.examine(rescuer), " "), "маяк молчит"), "При осмотре видно, что маяк замолчал")

/// Плазмамену при загрузке персонажа достаются плазменный баллон и костюм, ID остаётся на месте.
/datum/unit_test/minor_incidents_outside/proc/check_capsule_species_gear()
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	pilot.equipOutfit(/datum/outfit/distress_survivor)
	pilot.set_species(/datum/species/plasmaman)
	var/obj/item/card/id/card = pilot.wear_id
	distress_survivor_species_gear(pilot)
	TEST_ASSERT(istype(pilot.internal, /obj/item/tank/internals/plasmaman), "Плазмамен дышит из плазменного баллона")
	TEST_ASSERT_EQUAL(pilot.s_store, pilot.internal, "Плазменный баллон стоит в слоте скафандра")
	TEST_ASSERT(istype(pilot.w_uniform, /obj/item/clothing/under/plasmaman), "Под скафандром у плазмамена его костюм")
	TEST_ASSERT(locate(/obj/item/clothing/head/helmet/space/plasmaman) in pilot.held_items, "Шлем плазмамена у пилота в руках")
	TEST_ASSERT_EQUAL(pilot.wear_id, card, "Замена костюма не роняет ID-карту")
	TEST_ASSERT(istype(pilot.wear_suit, /obj/item/clothing/suit/space/fragile), "Скафандр остаётся на пилоте")

	var/mob/living/carbon/human/human_pilot = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	human_pilot.equipOutfit(/datum/outfit/distress_survivor)
	var/obj/item/tank/oxygen = human_pilot.s_store
	distress_survivor_species_gear(human_pilot)
	TEST_ASSERT_EQUAL(human_pilot.s_store, oxygen, "Человеку оставляют кислородный баллон")

/// Премию медбею приносит пилот, вышедший из медбея здоровым, а не подлечившийся где-то ещё.
/datum/unit_test/minor_incidents_outside/proc/check_capsule_discharge()
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/component/distress_rescue/rescue = pilot.AddComponent(/datum/component/distress_rescue)
	var/area/corridor = get_area(run_loc_floor_bottom_left)
	var/area/ward = new /area/medical/minor_outside_test_ward
	var/area/bar = new /area/service/library/minor_outside_test_hall
	allocated += list(ward, bar)
	var/balance = department_balance(ACCOUNT_MED)
	rescue.on_enter_area(pilot, corridor)
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_MED), balance, "Без медбея премии нет")
	pilot.adjustBruteLoss(60)
	rescue.on_enter_area(pilot, ward)
	rescue.on_enter_area(pilot, corridor)
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_MED), balance, "Больного пилота не выписывают")
	pilot.fully_heal()
	rescue.on_enter_area(pilot, bar)
	rescue.on_enter_area(pilot, corridor)
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_MED), balance, "Пилот, подлечившийся вне медбея, премии медбею не приносит")
	pilot.adjustBruteLoss(60)
	rescue.on_enter_area(pilot, ward)
	pilot.fully_heal()
	rescue.on_enter_area(pilot, corridor)
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_MED), balance + 300, "Пилот, вылеченный в медбее, на выходе приносит медбею 300 кредитов")
	TEST_ASSERT(QDELETED(rescue), "Премия выплачивается один раз")

/datum/unit_test/minor_incidents_outside/proc/check_satellite()
	var/turf/spot = run_loc_floor_bottom_left
	var/datum/round_event_control/minor_outside/derelict_satellite/test_site/control = allocate(/datum/round_event_control/minor_outside/derelict_satellite/test_site)
	TEST_ASSERT_EQUAL(control.get_disruption(), DIRECTOR_DISRUPTION_AMBIENT, "Спутник - фоновое событие")
	TEST_ASSERT(!control.director_preflight(), "Без космоса у обшивки спутник не должен тратить бюджет")
	control.test_site = spot
	TEST_ASSERT(control.director_preflight(), "С местом у обшивки preflight должен проходить")
	TEST_ASSERT(findtext(control.get_announcement_text(), "[SATELLITE_DATA_CORE_POINTS]"), "Объявление называет премию из таблицы исследований")
	TEST_ASSERT(findtext(control.get_announcement_text(), "Металлолом"), "Объявление оставляет экипажу металлолом, а не лом")
	var/datum/round_event/minor_outside/derelict_satellite/event = make_event(/datum/round_event/minor_outside/derelict_satellite)
	event.control = control
	event.start()
	var/obj/structure/derelict_satellite/satellite = event.spawned_ref?.resolve()
	TEST_ASSERT_NOTNULL(satellite, "Событие должно создавать спутник")
	allocated += satellite
	TEST_ASSERT(satellite.GetComponent(/datum/component/gps), "У спутника должен быть GPS-сигнал")
	TEST_ASSERT(!satellite.dismantle(), "Раму нельзя срезать, пока кожух на месте")
	TEST_ASSERT(satellite.unbolt_panels(), "Кожух снимается ключом")
	TEST_ASSERT_EQUAL(satellite.icon_state, "satellite_open", "Без кожуха спутник выглядит вскрытым")
	TEST_ASSERT(!satellite.unbolt_panels(), "Кожух снимается один раз")
	var/list/before = spot.contents.Copy()
	TEST_ASSERT(satellite.dismantle(), "Раскрытый спутник разбирается сваркой")
	var/list/created = claim_new_items(spot, before)
	TEST_ASSERT(QDELETED(satellite), "Разобранный спутник исчезает")
	var/obj/item/satellite_data_core/core = locate() in created
	TEST_ASSERT_NOTNULL(core, "Из спутника выпадает ядро данных")
	TEST_ASSERT(locate(/obj/item/circuitboard) in created, "Из спутника выпадает плата")
	TEST_ASSERT(locate(/obj/item/stack/sheet/metal) in created, "Из спутника выпадает металлолом")
	var/list/core_points = techweb_item_point_check(core)
	TEST_ASSERT_EQUAL(core_points?[TECHWEB_POINT_TYPE_GENERIC], SATELLITE_DATA_CORE_POINTS, "Деструктивный анализатор даёт за ядро обещанные очки")
	var/datum/export/sale
	for(var/datum/export/export as anything in GLOB.exports_list)
		if(export.applies_to(core, EXPORT_CARGO))
			sale = export
			break
	TEST_ASSERT_NOTNULL(sale, "Ядро данных можно продать через карго")
	TEST_ASSERT_EQUAL(sale?.get_cost(core, EXPORT_CARGO), sale?.init_cost, "Цена ядра не зависит от эластичности")

/datum/unit_test/minor_incidents_outside/proc/check_mining_drone()
	var/turf/spot = run_loc_floor_top_right
	var/datum/round_event_control/minor_outside/lost_mining_drone/test_site/control = allocate(/datum/round_event_control/minor_outside/lost_mining_drone/test_site)
	TEST_ASSERT_EQUAL(control.get_disruption(), DIRECTOR_DISRUPTION_AMBIENT, "Дрон шахтёров - фоновое событие")
	TEST_ASSERT(!lost_drone_valid_site(run_loc_floor_bottom_left), "Пол помещения не годится для места крушения")
	control.test_site = spot
	TEST_ASSERT(!control.director_preflight(), "Без шахтёров на смене дрон не должен падать")
	var/mob/living/carbon/human/miner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	miner.mind_initialize()
	miner.mind.assigned_role = "Shaft Miner"
	TEST_ASSERT(control.director_preflight(), "Шахтёр на смене и место крушения дают preflight")
	control.test_site = null
	TEST_ASSERT(!control.director_preflight(), "Без места крушения preflight не проходит")
	control.test_site = spot
	var/datum/round_event/minor_outside/lost_mining_drone/event = make_event(/datum/round_event/minor_outside/lost_mining_drone)
	event.control = control
	event.start()
	var/obj/structure/crashed_mining_drone/drone = event.spawned_ref?.resolve()
	TEST_ASSERT_NOTNULL(drone, "Событие должно создавать обломки дрона")
	allocated += drone
	var/datum/component/gps/gps = drone.GetComponent(/datum/component/gps)
	TEST_ASSERT_EQUAL(gps?.gpstag, "MD-7", "У дрона должен быть GPS MD-7")
	TEST_ASSERT_NOTNULL(drone.particles, "Над обломками поднимается дым")
	TEST_ASSERT(drone.lure_timer, "Дым со временем приманит фауну")
	var/list/before = spot.contents.Copy()
	TEST_ASSERT(drone.open_cargo(), "Грузовой отсек вскрывается")
	var/list/created = claim_new_items(spot, before)
	var/obj/item/storage/bag/ore/satchel = locate() in created
	TEST_ASSERT_NOTNULL(satchel, "В отсеке лежит мешок с рудой")
	var/ore_points = 0
	for(var/obj/item/stack/ore/ore in satchel)
		ore_points += ore.points * ore.amount
	TEST_ASSERT(ore_points > 0, "Руда в мешке чего-то стоит")
	var/obj/item/card/mining_point_card/card = locate() in created
	TEST_ASSERT(card?.points > 0, "В отсеке лежит карта шахтёрских очков")
	before = spot.contents.Copy()
	TEST_ASSERT(!drone.open_cargo(), "Награда выдаётся один раз")
	TEST_ASSERT(!length(claim_new_items(spot, before)), "Повторное вскрытие ничего не создаёт")
	TEST_ASSERT_NULL(drone.GetComponent(/datum/component/gps), "Опустевший дрон не засоряет GPS")
	TEST_ASSERT_NULL(drone.particles, "Дым над вскрытым дроном гаснет")
	TEST_ASSERT_NULL(drone.lure_timer, "Вскрытый дрон больше не приманивает фауну")
	TEST_ASSERT_EQUAL(drone.icon_state, "drone_wreck_open", "Вскрытый дрон выглядит вскрытым")
	TEST_ASSERT(!drone.advance_repair(miner) && isnull(drone.reboot(miner)), "Вскрытый ломом дрон уже не починить")

/// Ремонт превращает обломки в дрона-компаньона.
/datum/unit_test/minor_incidents_outside/proc/check_drone_repair()
	var/turf/spot = run_loc_floor_top_right
	var/mob/living/carbon/human/miner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/structure/crashed_mining_drone/wreck = allocate(/obj/structure/crashed_mining_drone, spot)
	TEST_ASSERT(findtext(jointext(wreck.examine(miner), " "), "кабеля"), "При осмотре виден следующий шаг ремонта")
	TEST_ASSERT_NULL(wreck.reboot(miner), "Без проводки и обшивки контроллер не запускается")
	TEST_ASSERT(wreck.advance_repair(miner), "Проводка заменяется")
	TEST_ASSERT(wreck.advance_repair(miner), "Корпус латается")
	TEST_ASSERT(!wreck.advance_repair(miner), "Лишних шагов ремонта нет")
	var/mob/living/simple_animal/hostile/mining_drone/minebot = wreck.reboot(miner)
	TEST_ASSERT_NOTNULL(minebot, "Починенный дрон встаёт на ходовую")
	allocated += minebot
	TEST_ASSERT_EQUAL(minebot.loc, spot, "Дрон-компаньон появляется на месте обломков")
	TEST_ASSERT(QDELETED(wreck), "Обломки исчезают после запуска")

/// Обломки падают туда, где водится фауна, а дым приманивает её только с открытой поверхности в прямой видимости.
/datum/unit_test/minor_incidents_outside/proc/check_drone_lure_terrain()
	var/area/wastes = new /area/minor_outside_test_wastes
	var/area/quiet = new /area/minor_outside_test_wastes/no_fauna
	allocated += list(wastes, quiet)
	var/turf/wreck_spot = run_loc_floor_bottom_left
	var/turf/far_spot = run_loc_floor_top_right
	var/list/turf/far_turfs = list(far_spot, get_step(far_spot, WEST), get_step(far_spot, SOUTH))
	borrowed_turfs += wreck_spot
	quiet.contents.Add(wreck_spot)
	TEST_ASSERT(!lost_drone_valid_site(wreck_spot), "Обломки не падают на поверхность, где не водится фауна")
	wastes.contents.Add(wreck_spot)
	TEST_ASSERT(lost_drone_valid_site(wreck_spot), "Открытая поверхность с фауной годится для места крушения")

	var/obj/structure/crashed_mining_drone/smoking = allocate(/obj/structure/crashed_mining_drone, wreck_spot)
	var/list/lured = smoking.lure_fauna()
	allocated += lured
	TEST_ASSERT(!length(lured), "Из помещений рядом с обломками дым никого не приманивает")
	TEST_ASSERT_NULL(smoking.lure_timer, "Дым приманивает один раз")

	var/obj/structure/falsewall/screen = allocate(/obj/structure/falsewall, locate(wreck_spot.x + 2, wreck_spot.y + 2, wreck_spot.z))
	borrowed_turfs += far_turfs
	for(var/turf/far as anything in far_turfs)
		wastes.contents.Add(far)
	lured = smoking.lure_fauna()
	allocated += lured
	TEST_ASSERT(!length(lured), "Существа не выходят из-за непрозрачной преграды")

	qdel(screen)
	lured = smoking.lure_fauna()
	allocated += lured
	TEST_ASSERT(length(lured) >= 1 && length(lured) <= 2, "Дым приманивает одно-два существа с открытой поверхности")
	for(var/mob/living/creature as anything in lured)
		TEST_ASSERT(istype(creature, /mob/living/simple_animal/hostile/asteroid), "Приманены местные существа")
		TEST_ASSERT_EQUAL(get_area(creature), wastes, "Существа выходят с поверхности, где водится фауна")
		TEST_ASSERT(get_dist(creature, smoking) >= 3, "Существа выходят из округи, а не прямо из обломков")
	QDEL_LIST(lured)
	qdel(smoking)

/datum/unit_test/minor_incidents_outside/proc/check_tour_catalog()
	var/list/station_route = tour_station_attractions()
	TEST_ASSERT(length(station_route) <= 5, "В путеводителе не больше пяти достопримечательностей")
	TEST_ASSERT(!("театр" in station_route), "Театр за доступом не входит в маршрут")
	for(var/label in station_route)
		TEST_ASSERT(islist(station_route[label]), "Остановка - список типов отсека")
	var/list/catalog = tour_attraction_catalog()
	var/list/library_roots = catalog["библиотека"]
	var/area/hall = new /area/service/library/minor_outside_test_hall
	var/area/ruin = new /area/service/library/abandoned/minor_outside_test_ruin
	allocated += list(hall, ruin)
	TEST_ASSERT(tour_area_matches(hall, library_roots), "Зал библиотеки - остановка маршрута")
	TEST_ASSERT(!tour_area_matches(ruin, library_roots), "Заброшенная библиотека в техах не засчитывается")

/// Штамп ставит сотрудник станции ID-картой, турист сам себе его не ставит; гид рядом получает плату.
/datum/unit_test/minor_incidents_outside/proc/check_tour_stamps()
	var/turf/spot = run_loc_floor_bottom_left
	var/area/here = get_area(spot)
	var/datum/star_route_tour/tour = allocate(/datum/star_route_tour, "tour_test")
	var/obj/item/tour_guidebook/guide = make_tourist(spot, list("тестовая комната" = list(here.type), "бар" = list(/area/service/bar)), tour)
	var/mob/living/carbon/human/tourist = guide.owner
	guide.attack_self(tourist)
	TEST_ASSERT(guide.opened, "Путеводитель открывается в руке")
	TEST_ASSERT(!length(guide.stamped), "Турист не может поставить штамп себе сам")
	var/obj/item/card/id/visitor_card = allocate(/obj/item/card/id)
	var/obj/item/tour_guidebook/other_guide = make_tourist(spot, list("тестовая комната" = list(here.type)), tour)
	SEND_SIGNAL(tourist, COMSIG_ATOM_ITEM_INTERACTION, other_guide.owner, visitor_card, null)
	TEST_ASSERT(!length(guide.stamped), "Другой турист штамп не ставит")

	var/mob/living/carbon/human/host = make_crew(get_step(spot, NORTH), "Bartender")
	var/mob/living/carbon/human/escort = make_crew(get_step(spot, EAST), "Assistant")
	var/escort_balance = personal_balance(escort)
	var/host_balance = personal_balance(host)
	var/result = SEND_SIGNAL(tourist, COMSIG_ATOM_ITEM_INTERACTION, host, host.wear_id, null)
	TEST_ASSERT(result & TOOL_ACT_TOOLTYPE_SUCCESS, "Касание ID-картой не превращается в удар")
	TEST_ASSERT(guide.stamped["тестовая комната"], "Сотрудник ставит штамп ID-картой в отсеке маршрута")
	TEST_ASSERT(!guide.stamped["бар"], "Штамп ставится только за тот отсек, где стоит турист")
	TEST_ASSERT_EQUAL(personal_balance(escort), escort_balance + 150, "Гид рядом получает 150 кредитов за остановку")
	TEST_ASSERT_EQUAL(personal_balance(host), host_balance, "Ставящий штамп сотрудник гидом не считается")
	SEND_SIGNAL(other_guide.owner, COMSIG_ATOM_ITEM_INTERACTION, host, host.wear_id, null)
	TEST_ASSERT(other_guide.stamped["тестовая комната"], "Второй турист группы получает тот же штамп")
	TEST_ASSERT_EQUAL(personal_balance(escort), escort_balance + 150, "За одну остановку группы гид получает плату один раз")
	TEST_ASSERT("guidebook_stamp_1" in guide.update_overlays(), "Штамп виден на открытой странице")

/// Штамп за действие персонала: коктейль в баре, благословение в часовне, книга от библиотекаря.
/datum/unit_test/minor_incidents_outside/proc/check_tour_actions()
	var/turf/spot = run_loc_floor_top_right
	var/area/here = get_area(spot)
	var/obj/item/tour_guidebook/guide = make_tourist(spot, list("бар" = list(here.type), "часовня" = list(here.type), "библиотека" = list(here.type), "спортзал" = list(/area/commons/fitness)))
	var/mob/living/carbon/human/tourist = guide.owner
	SEND_SIGNAL(tourist, COMSIG_ADD_MOOD_EVENT, "quality_drink", /datum/mood_event/quality_nice)
	TEST_ASSERT(guide.stamped["бар"], "Хороший коктейль в баре ставит штамп бара")

	var/mob/living/carbon/human/layman = make_crew(get_step(spot, WEST), "Assistant")
	var/obj/item/storage/book/bible/bible = allocate(/obj/item/storage/book/bible)
	TEST_ASSERT_EQUAL(SEND_SIGNAL(tourist, COMSIG_ATOM_ITEM_INTERACTION, layman, bible, null), NONE, "Библия в руках мирянина штамп не ставит")
	var/mob/living/carbon/human/chaplain = make_crew(get_step(spot, SOUTH), "Chaplain")
	chaplain.mind.isholy = TRUE
	var/result = SEND_SIGNAL(tourist, COMSIG_ATOM_ITEM_INTERACTION, chaplain, bible, null)
	TEST_ASSERT(result & TOOL_ACT_TOOLTYPE_SUCCESS, "Благословение не превращается в удар Библией")
	TEST_ASSERT(guide.stamped["часовня"], "Благословение священника ставит штамп часовни")

	var/mob/living/carbon/human/curator = make_crew(get_step(spot, SOUTHWEST), "Curator", list(ACCESS_LIBRARY))
	var/obj/item/book/book = allocate(/obj/item/book)
	curator.put_in_hands(book)
	SEND_SIGNAL(tourist, COMSIG_ATOM_ITEM_INTERACTION, curator, book, null)
	TEST_ASSERT(guide.stamped["библиотека"], "Книга от библиотекаря ставит штамп библиотеки")
	TEST_ASSERT(book in tourist.held_items, "Книга переходит туристу")
	TEST_ASSERT(!guide.stamped["спортзал"], "Действия персонала не ставят чужие штампы")

/// Полный маршрут: сувенир, настроение, отзыв и плата в бюджет сервиса.
/datum/unit_test/minor_incidents_outside/proc/check_tour_completion()
	var/turf/spot = run_loc_floor_bottom_left
	var/area/here = get_area(spot)
	var/obj/item/tour_guidebook/guide = make_tourist(spot, list("тестовая комната" = list(here.type)))
	var/mob/living/carbon/human/tourist = guide.owner
	var/datum/component/mood/mood = tourist.GetComponent(/datum/component/mood) || tourist.AddComponent(/datum/component/mood)
	var/balance = department_balance(ACCOUNT_SRV)
	var/mob/living/carbon/human/host = make_crew(get_step(spot, NORTH))
	SEND_SIGNAL(tourist, COMSIG_ATOM_ITEM_INTERACTION, host, host.wear_id, null)
	TEST_ASSERT(guide.souvenir_given, "За полный маршрут выдаётся сувенир")
	var/globes = 0
	for(var/obj/item/tour_snowglobe/globe in tourist.held_items)
		allocated += globe
		globes++
	TEST_ASSERT_EQUAL(globes, 1, "Сувенир оказывается в руках туриста")
	TEST_ASSERT(istype(mood.mood_events["star_route_tour"], /datum/mood_event/star_route_tour), "Пройденный маршрут поднимает настроение")
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_SRV), balance + 300, "За полный маршрут бюджет сервиса получает 300 кредитов")
	TEST_ASSERT(!guide.complete_route(), "Маршрут закрывается один раз")
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_SRV), balance + 300, "Плата сервису не повторяется")

/datum/unit_test/minor_incidents_outside/proc/check_tour_spawn()
	var/turf/spot = run_loc_floor_top_right
	var/area/here = get_area(spot)
	var/list/route = list("тестовая комната" = list(here.type), "бар" = list(/area/service/bar), "часовня" = list(/area/service/chapel), "библиотека" = list(/area/service/library))
	var/datum/round_event_control/tour_group/test_route/control = allocate(/datum/round_event_control/tour_group/test_route)
	TEST_ASSERT_EQUAL(control.get_disruption(), DIRECTOR_DISRUPTION_AMBIENT, "Туристы - фоновое событие")
	control.test_route = route.Copy(1, 4)
	TEST_ASSERT(!control.director_preflight(), "Маршрут меньше четырёх отсеков не запускается")
	var/datum/round_event/ghost_role/tour_group/no_volunteers/empty_poll = make_event(/datum/round_event/ghost_role/tour_group/no_volunteers)
	empty_poll.control = control
	TEST_ASSERT_EQUAL(empty_poll.spawn_role(), MAP_ERROR, "Без маршрута туристы не прилетают")
	control.test_route = route.Copy()
	TEST_ASSERT_EQUAL(empty_poll.spawn_role(), NOT_ENOUGH_PLAYERS, "Пустой опрос возвращается как провал для возврата бюджета")
	TEST_ASSERT(!length(empty_poll.spawned_mobs), "Пустой опрос никого не создаёт")

	var/mob/living/carbon/human/visitor = allocate(/mob/living/carbon/human, spot)
	visitor.mind_initialize()
	var/datum/round_event/ghost_role/tour_group/event = make_event(/datum/round_event/ghost_role/tour_group)
	event.attractions = route.Copy()
	var/obj/item/tour_guidebook/guide = event.equip_tourist(visitor)
	TEST_ASSERT(visitor.mind.assigned_role in GLOB.exp_specialmap[EXP_TYPE_SPECIAL], "Туристов не выбирают мидраунд-антагами")
	TEST_ASSERT(!is_effective_crew_mob(visitor), "Турист не считается экипажем у директора")
	var/obj/item/card/id/card = visitor.wear_id
	TEST_ASSERT_EQUAL(card?.assignment, "Visitor", "У туриста гостевая карта")
	TEST_ASSERT(!length(card?.access), "Гостевая карта не даёт доступа")
	TEST_ASSERT(istype(visitor.wear_neck, /obj/item/camera), "У туриста фотоаппарат")
	TEST_ASSERT(guide in visitor.held_items, "Путеводитель выдаётся в руки")
	TEST_ASSERT_EQUAL(guide.owner, visitor, "Путеводитель знает своего туриста")
	TEST_ASSERT_EQUAL(length(guide.attractions), length(route), "Путеводитель хранит маршрут группы")

	var/mob/living/carbon/human/plasma_visitor = allocate(/mob/living/carbon/human, spot)
	plasma_visitor.mind_initialize()
	plasma_visitor.set_species(/datum/species/plasmaman)
	var/obj/item/tour_guidebook/plasma_guide = event.equip_tourist(plasma_visitor)
	TEST_ASSERT(istype(plasma_visitor.w_uniform, /obj/item/clothing/under/plasmaman), "Плазмамен-турист в своём костюме, а не в шортах")
	TEST_ASSERT(istype(plasma_visitor.head, /obj/item/clothing/head/helmet/space/plasmaman), "Плазмамен-турист в шлеме")
	TEST_ASSERT(istype(plasma_visitor.internal, /obj/item/tank/internals/plasmaman), "Плазмамен-турист дышит из плазменного баллона")
	TEST_ASSERT(!(plasma_visitor.internal in plasma_visitor.held_items), "Баллон убран из рук в слот")
	TEST_ASSERT(plasma_guide in plasma_visitor.held_items, "Путеводитель плазмамена тоже в руках")

/// Прошедший маршрут турист перестаёт быть нагрузкой директора.
/datum/unit_test/minor_incidents_outside/proc/check_tour_director_release()
	var/datum/round_event_control/tour_group/test_route/control = allocate(/datum/round_event_control/tour_group/test_route)
	var/mob/living/carbon/human/tourist = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	tourist.mind_initialize()
	var/datum/star_route_tour/tour = allocate(/datum/star_route_tour, control.action_name())
	tour.tourist_minds += WEAKREF(tourist.mind)
	var/list/saved_spawns = SSdirector.live_ghost_role_spawns
	SSdirector.live_ghost_role_spawns = list()
	TEST_ASSERT(SSdirector.track_ghost_role_spawn(control, list(tourist), log_execution = FALSE), "Турист переходит на живой трекинг директора")
	var/load = SSdirector.get_ghost_role_intensity(only_antag = FALSE)
	tour.end_tour()
	var/released_load = SSdirector.get_ghost_role_intensity(only_antag = FALSE)
	SSdirector.live_ghost_role_spawns = saved_spawns
	TEST_ASSERT(load > 0, "Пока идёт экскурсия, турист - нагрузка директора")
	TEST_ASSERT_EQUAL(released_load, 0, "После экскурсии турист не держит intensity директора")
	TEST_ASSERT(!length(tour.tourist_minds), "Отпущенные туристы забываются")

/// Турист, прошедший маршрут раньше группы, снимает свою долю нагрузки, а не держит её за всех.
/datum/unit_test/minor_incidents_outside/proc/check_tour_partial_release()
	var/datum/round_event_control/tour_group/test_route/control = allocate(/datum/round_event_control/tour_group/test_route)
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	first.mind_initialize()
	second.mind_initialize()
	var/datum/star_route_tour/tour = allocate(/datum/star_route_tour, control.action_name())
	tour.tourist_minds += list(WEAKREF(first.mind), WEAKREF(second.mind))
	var/list/saved_spawns = SSdirector.live_ghost_role_spawns
	SSdirector.live_ghost_role_spawns = list()
	SSdirector.track_ghost_role_spawn(control, list(first, second), log_execution = FALSE)
	var/group_load = SSdirector.get_ghost_role_intensity(only_antag = FALSE)
	tour.release(first.mind)
	var/released_load = SSdirector.get_ghost_role_intensity(only_antag = FALSE)
	SSdirector.live_ghost_role_spawns = saved_spawns
	TEST_ASSERT(group_load > 0, "Группа из двух туристов - нагрузка директора")
	TEST_ASSERT(abs(released_load - group_load / 2) < 0.01, "Отпущенный турист из двух снимает половину нагрузки группы: [released_load] из [group_load]")
