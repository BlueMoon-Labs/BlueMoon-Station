/// Рантайм-флуды прода 10730-10747: каждый тест воспроизводит свою причину.

/datum/unit_test/bloodsucker_power_loop_stops_on_removal/Run()
	var/mob/living/carbon/human/vampire = allocate(/mob/living/carbon/human)
	vampire.mind_initialize()
	var/datum/antagonist/bloodsucker/training/role = vampire.mind.add_antag_datum(/datum/antagonist/bloodsucker/training)
	TEST_ASSERT(istype(role), "Разум получает учебного кровососа.")
	var/datum/action/cooldown/bloodsucker/masquerade/mask = locate() in role.powers
	TEST_ASSERT_NOTNULL(mask, "Masquerade выдан сразу.")
	vampire.blood_volume = BLOOD_VOLUME_NORMAL
	INVOKE_ASYNC(mask, TYPE_PROC_REF(/datum/action/cooldown/bloodsucker, Trigger))
	TEST_ASSERT(mask.active, "Masquerade включился.")
	TEST_ASSERT(!HAS_TRAIT_FROM(vampire, TRAIT_COLDBLOODED, BLOODSUCKER_TRAIT), "Masquerade снял холодную кровь.")

	vampire.mind.remove_antag_datum(/datum/antagonist/bloodsucker/training)
	TEST_ASSERT(!mask.active, "Снятая с антагом сила выключается, а не тянет кровь дальше.")
	var/blood_after_removal = vampire.blood_volume
	sleep(2.5 SECONDS)
	TEST_ASSERT_EQUAL(vampire.blood_volume, blood_after_removal, "Цикл снятой силы остановился.")

/datum/unit_test/bloodsucker_power_loop_stops_on_body_delete/Run()
	var/mob/living/carbon/human/vampire = allocate(/mob/living/carbon/human)
	vampire.mind_initialize()
	var/datum/mind/vampire_mind = vampire.mind
	var/datum/antagonist/bloodsucker/training/role = vampire_mind.add_antag_datum(/datum/antagonist/bloodsucker/training)
	var/datum/action/cooldown/bloodsucker/masquerade/mask = locate() in role.powers
	vampire.blood_volume = BLOOD_VOLUME_NORMAL
	INVOKE_ASYNC(mask, TYPE_PROC_REF(/datum/action/cooldown/bloodsucker, Trigger))
	TEST_ASSERT(mask.active, "Masquerade включился.")

	// Сброс полигона: разум удаляется мимо on_removal, затем тело.
	qdel(vampire_mind)
	qdel(vampire)
	TEST_ASSERT(!mask.active, "Сила удалённого тела выключается.")
	sleep(2.5 SECONDS)
	TEST_ASSERT_NULL(mask.owner, "Сила отпустила удалённое тело.")

/datum/unit_test/fresh_observer_not_ssd/Run()
	var/list/prev_config = auto_cryo_test_enable_config()
	// min_val конфига 600 больше world.time тестового мира, ставим мимо проверки.
	var/datum/config_entry/number/ghost_period = CONFIG_GET_ENTRY(number/ghost_check_time)
	ghost_period.config_entry_value = 1
	// Гост из лобби до переезда клиента живёт без него тик-другой.
	var/mob/dead/observer/ghost = new(run_loc_floor_bottom_left)
	SSauto_cryo.currentrun_ghosts = list()
	SSauto_cryo.next_scan = 0
	SSauto_cryo.fire()
	var/survived = !QDELETED(ghost)
	SSauto_cryo.currentrun_ghosts = list()
	auto_cryo_test_restore_config(prev_config)
	qdel(ghost)
	TEST_ASSERT(survived, "Только что созданный гост не считается SSD с начала раунда.")

/datum/unit_test/firedoor_deleted_mid_animation_no_timers/Run()
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor)
	door.machine_stat &= ~NOPOWER
	TEST_ASSERT(!door.density, "Дверь стоит открытой.")
	INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door/firedoor, close_manually))
	TEST_ASSERT(door.operating, "Дверь закрывается.")
	door.open_manually()
	TEST_ASSERT_EQUAL(door.nextstate, FIREDOOR_OPEN_MANUAL, "Команда открыть отложена до конца анимации.")
	qdel(door)
	sleep(1.5 SECONDS)
	TEST_ASSERT_NULL(door.automatic_close_timer, "Удалённая дверь не взводит таймер автозакрытия.")
	TEST_ASSERT_NULL(door.reopen_timer, "Удалённая дверь не взводит таймер переоткрытия.")

/datum/unit_test/hijack_implant_removal_releases_clicks/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.left_eye_color = "111111"
	user.right_eye_color = "222222"
	var/obj/item/implant/hijack/implant = allocate(/obj/item/implant/hijack)
	TEST_ASSERT(implant.implant(user, null, TRUE), "Имплант встаёт.")
	implant.activate()
	TEST_ASSERT_EQUAL(user.click_intercept, implant, "Включённый имплант перехватывает клики.")
	implant.removed(user)
	TEST_ASSERT_NULL(user.click_intercept, "Извлечённый имплант больше не перехватывает клики.")
	TEST_ASSERT(!user.siliconaccesstoggle, "После извлечения нет доступа силикона.")
	TEST_ASSERT_EQUAL(user.left_eye_color, "111111", "Левый глаз вернул свой цвет.")
	TEST_ASSERT_EQUAL(user.right_eye_color, "222222", "Правый глаз вернул свой цвет.")

/datum/unit_test/scavenging_examine_without_tools/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/structure/deadmesa/body = allocate(/obj/structure/deadmesa)
	body.AddElement(/datum/element/scavenging, 5, list(SCAVENGING_FOUND_NOTHING = 1))
	var/list/lines = body.examine(user)
	TEST_ASSERT(findtext(jointext(lines, "\n"), "bare handed"), "Осмотр кучи без инструментов называет поиск руками.")

/datum/unit_test/swarmer_hud_keeps_base_login_handler/Run()
	var/mob/living/simple_animal/hostile/swarmer/basic/drone = allocate(/mob/living/simple_animal/hostile/swarmer/basic)
	var/datum/hud/swarmer/hud = new(drone)
	drone.set_hud_used(hud)
	TEST_ASSERT_EQUAL(hud.signal_procs[drone][COMSIG_MOB_CLIENT_LOGIN], TYPE_PROC_REF(/datum/hud, on_client_login), "HUD свармера не затирает базовый обработчик входа клиента.")
	TEST_ASSERT_EQUAL(hud.signal_procs[drone][COMSIG_MOB_CLIENT_LOGOUT], TYPE_PROC_REF(/datum/hud, on_client_logout), "HUD свармера не затирает базовый обработчик выхода клиента.")
	var/datum/hud/swarmer/next_hud = new(drone)
	drone.set_hud_used(next_hud)
	TEST_ASSERT(hud.signal_procs?[drone]?[COMSIG_MOB_CLIENT_LOGIN], "Снятый HUD снимает только своё слежение за ядром.")
	qdel(next_hud)
	qdel(hud)

/datum/unit_test/swarmer_analyzer_counts_repeats/Run()
	var/datum/team/swarmer_team/team = new
	var/obj/structure/swarmer/organic_analyzer/analyzer = allocate(/obj/structure/swarmer/organic_analyzer, null, team)
	analyzer.anchored = TRUE
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	for(var/attempt in 1 to 3)
		victim.forceMove(run_loc_floor_bottom_left)
		TEST_ASSERT_EQUAL(team.try_analyze_mob(victim), SWARMER_ANALYZE_FOUND, "Анализатор принимает жертву ([attempt]-й раз).")
		TEST_ASSERT_EQUAL(analyzer.gib_after_analyzing, attempt > 2, "Разбор на части только после двух заходов ([attempt]-й раз).")
		deltimer(analyzer.analyze_timer)
		analyzer.analyze_timer = null
		analyzer.set_occupant(null)
	victim.forceMove(run_loc_floor_bottom_left)
	qdel(analyzer)
	qdel(team)

/datum/unit_test/dream_without_mood/Run()
	var/mob/living/carbon/monkey/sleeper = allocate(/mob/living/carbon/monkey)
	qdel(sleeper.GetComponent(/datum/component/mood))
	sleeper.dream()

/datum/unit_test/anti_magic_probe_keeps_named_args/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	var/datum/component/anti_magic/ward = caster.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5, FALSE)
	// Так спрашивает can_cast() у кнопки заклинания на каждом обновлении.
	TEST_ASSERT(!caster.anti_magic_check(TRUE, FALSE, chargecost = 0, self = TRUE), "Защита без blocks_self не мешает своим заклинаниям.")
	TEST_ASSERT_EQUAL(ward.charges, 5, "Проверка кнопки заклинания не тратит заряды.")
	TEST_ASSERT(caster.anti_magic_check(), "Чужая магия блокируется.")
	TEST_ASSERT_EQUAL(ward.charges, 5, "Проба без цены не тратит заряды.")
	qdel(ward)
	var/obj/item/clothing/head/foilhat/hat = allocate(/obj/item/clothing/head/foilhat)
	TEST_ASSERT(caster.equip_to_slot_if_possible(hat, ITEM_SLOT_HEAD), "Шапочка надета.")
	TEST_ASSERT(!caster.anti_magic_check(), "Шапочка не держит обычную магию.")
	TEST_ASSERT(caster.anti_magic_check(FALSE, FALSE, TRUE), "Шапочка держит ментальную магию.")
