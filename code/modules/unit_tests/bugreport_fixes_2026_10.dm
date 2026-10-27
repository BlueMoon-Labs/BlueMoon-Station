/// Запертый в шкафу враждебный моб не бьёт соседа через стенку шкафа, а снаружи бьёт.
/datum/unit_test/hostile_melee_not_from_closet

/datum/unit_test/hostile_melee_not_from_closet/Run()
	var/mob/living/simple_animal/hostile/brute = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	brute.melee_damage_lower = 10
	brute.melee_damage_upper = 10
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/structure/closet/locker = allocate(/obj/structure/closet, run_loc_floor_bottom_left)
	brute.forceMove(locker)

	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(brute)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	var/datum/ai_behavior/hostile_melee_attack/fangs = GET_AI_BEHAVIOR(/datum/ai_behavior/hostile_melee_attack)

	var/health_before = prey.health
	fangs.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT_EQUAL(prey.health, health_before, "Моб из шкафа ударил соседа")
	TEST_ASSERT(!brute.in_melee, "Моб в шкафу считает себя в ближнем бою")

	brute.forceMove(run_loc_floor_bottom_left)
	fangs.perform(0.5, controller, BB_AI_CURRENT_TARGET)
	TEST_ASSERT(prey.health < health_before, "Моб снаружи шкафа не ударил соседа")
	qdel(controller)

/// Цель в кровавом прыжке не годится враждебному мобу, пока не выйдет из фазы.
/datum/unit_test/hostile_ignores_phased_target

/datum/unit_test/hostile_ignores_phased_target/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/demon = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT(hunter.CanAttack(demon), "Обычная цель не годится враждебному мобу")

	var/obj/effect/dummy/phased_mob/slaughter/blood_pool = allocate(/obj/effect/dummy/phased_mob/slaughter, get_turf(demon))
	demon.forceMove(blood_pool)
	TEST_ASSERT(!hunter.CanAttack(demon), "Враждебный моб видит цель в кровавом прыжке")
	demon.forceMove(run_loc_floor_bottom_left)

/// Из шкафа на лестнице кнопки смены этажа не выкидывают моба наружу.
/datum/unit_test/move_vertically_blocked_in_container

/datum/unit_test/move_vertically_blocked_in_container/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/obj/structure/ladder/bottom = allocate(/obj/structure/ladder, locate(84, 60, levels[1]))
	var/obj/structure/ladder/top = allocate(/obj/structure/ladder, locate(84, 60, levels[2]))
	TEST_ASSERT_EQUAL(bottom.up, top, "Лестницы на соседних этажах не связались")
	var/mob/living/carbon/human/sitter = allocate(/mob/living/carbon/human, get_turf(bottom))
	var/obj/structure/closet/locker = allocate(/obj/structure/closet, get_turf(bottom))
	sitter.forceMove(locker)
	TEST_ASSERT(!sitter.move_vertically(UP), "Из шкафа удалось сменить этаж")
	TEST_ASSERT_EQUAL(sitter.loc, locker, "Смена этажа вытащила моба из шкафа")
	sitter.forceMove(get_turf(bottom))

/// Изучение во внешней сети не попадает в объявление станционной рации, в станционной - попадает.
/datum/unit_test/research_announce_station_web_only

/datum/unit_test/research_announce_station_web_only/Run()
	var/datum/techweb/outpost_web = new
	var/node_id = SSresearch.techweb_nodes[1]
	SSresearch.on_node_researched(node_id, outpost_web)
	TEST_ASSERT(!SSresearch.station_research_node_ids[node_id], "Изучение во внешней сети ушло в станционное объявление")
	SSresearch.on_node_researched(node_id, SSresearch.science_tech)
	TEST_ASSERT(SSresearch.station_research_node_ids[node_id], "Изучение в станционной сети не ушло в станционное объявление")

	deltimer(SSresearch.research_batch_timer)
	SSresearch.research_batch_timer = null
	SSresearch.pending_research_node_ids.Cut()
	SSresearch.station_research_node_ids.Cut()
	qdel(outpost_web)

/// Счёт гост-роли помечен внешним, Crab-17 его пропускает.
/datum/unit_test/ghost_role_account_offstation

/datum/unit_test/ghost_role_account_offstation/Run()
	var/obj/effect/mob_spawn/human/pirate/spawner = allocate(/obj/effect/mob_spawn/human/pirate, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/pirate = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	spawner.handlebank(pirate)
	var/datum/bank_account/pirate_account
	for(var/datum/bank_account/account as anything in SSeconomy.bank_accounts)
		if(account.account_id == pirate.account_id)
			pirate_account = account
	TEST_ASSERT_NOTNULL(pirate_account, "Гост-роль не получила счёт")
	TEST_ASSERT(pirate_account.offstation, "Счёт гост-роли не помечен внешним")
	qdel(pirate_account)

/// Маркинги молей ложатся под обычные маркинги, а не поверх них.
/datum/unit_test/insect_markings_below_body_markings

/datum/unit_test/insect_markings_below_body_markings/Run()
	var/datum/sprite_accessory/insect_markings/markings = GLOB.insect_markings_list["Deathshead"]
	TEST_ASSERT_NOTNULL(markings, "Нет маркинга молей Deathshead")
	TEST_ASSERT(markings.overlay_layer < -MARKING_LAYER, "Маркинги молей выше обычных маркингов")
	TEST_ASSERT(markings.overlay_layer > -BODYPARTS_LAYER, "Маркинги молей ниже тела")

/// Все этажи станции на миникарте режутся по одной рамке.
/datum/unit_test/minimap_floors_share_frame

/datum/unit_test/minimap_floors_share_frame/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/datum/minimap/lower = new(levels[1], 50, 50, 70, 70, "lower", FALSE)
	var/datum/minimap/upper = new(levels[2], 50, 50, 70, 70, "upper", FALSE)
	lower.finalize(50, 50, 70, 70)
	upper.finalize(50, 50, 70, 70)
	TEST_ASSERT_EQUAL(lower.map_icon.Width(), upper.map_icon.Width(), "Этажи миникарты разной ширины")
	TEST_ASSERT_EQUAL(lower.map_icon.Height(), upper.map_icon.Height(), "Этажи миникарты разной высоты")
	TEST_ASSERT_EQUAL(lower.map_icon.Width(), 21, "Рамка миникарты не совпала с заданной")

#ifdef LOWMEMORYMODE
/// LOWMEMORYMODE собирается без PNG NanoMap: станция получает старую схему зон.
/datum/unit_test/minimap_fallback_without_nanomap

/datum/unit_test/minimap_fallback_without_nanomap/Run()
	var/datum/asset/simple/nanomaps/nanomaps = get_asset_datum(/datum/asset/simple/nanomaps)
	TEST_ASSERT_EQUAL(length(nanomaps.map_data), 0, "В LOWMEMORYMODE манифест NanoMap не пуст")
	var/list/old_minimaps = SSminimaps.station_minimaps
	var/datum/minimap_group/old_group = SSminimaps.station_minimap
	SSminimaps.station_minimaps = list()
	SSminimaps.build_minimaps()
	var/list/built = SSminimaps.station_minimaps
	SSminimaps.station_minimaps = old_minimaps
	SSminimaps.station_minimap = old_group
	TEST_ASSERT(length(built), "Без NanoMap у станции нет миникарты")
	for(var/datum/minimap/floor_map as anything in built)
		TEST_ASSERT_NOTNULL(floor_map.map_icon, "Этаж [floor_map.name] без изображения")
		TEST_ASSERT_NULL(floor_map.department_map_icon, "Схема зон получила слой отделов NanoMap")
#endif
