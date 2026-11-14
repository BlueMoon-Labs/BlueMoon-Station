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
	TEST_ASSERT(findtext(jointext(lines, "\n"), "Можно обыскать: голыми руками."), "Осмотр кучи без инструментов называет поиск руками.")
	var/obj/structure/deadmesa/pile = allocate(/obj/structure/deadmesa)
	pile.AddElement(/datum/element/scavenging, 5, list(SCAVENGING_FOUND_NOTHING = 1), null, 12 SECONDS, TRUE, list(TOOL_SHOVEL = 0.6))
	lines = pile.examine(user)
	TEST_ASSERT(findtext(jointext(lines, "\n"), "Можно обыскать: лопатой или голыми руками."), "Осмотр кучи называет инструмент по-русски одной фразой.")

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

/datum/unit_test/firedoor_deleted_mid_manual_open_no_timers/Run()
	var/obj/machinery/door/firedoor/closed/door = allocate(/obj/machinery/door/firedoor/closed)
	door.machine_stat &= ~NOPOWER
	TEST_ASSERT(door.density, "Дверь стоит закрытой.")
	INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door/firedoor, open_manually))
	TEST_ASSERT(door.operating, "Дверь открывается по команде игрока.")
	qdel(door)
	sleep(1.5 SECONDS)
	TEST_ASSERT_NULL(door.automatic_close_timer, "Удалённая посреди открытия дверь не взводит защиту от автозакрытия.")

/datum/unit_test/bloodsucker_feed_stops_on_removal/Run()
	var/mob/living/carbon/human/vampire = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	vampire.mind_initialize()
	prey.mind_initialize()
	var/datum/antagonist/bloodsucker/training/role = vampire.mind.add_antag_datum(/datum/antagonist/bloodsucker/training)
	var/datum/action/cooldown/bloodsucker/feed/feed = locate() in role.powers
	TEST_ASSERT_NOTNULL(feed, "Feed выдан сразу.")
	vampire.start_pulling(prey, GRAB_AGGRESSIVE, supress_message = TRUE)
	vampire.setGrabState(GRAB_AGGRESSIVE)
	vampire.blood_volume = BLOOD_VOLUME_BAD
	INVOKE_ASYNC(feed, TYPE_PROC_REF(/datum/action/cooldown/bloodsucker, Trigger))
	var/list/budget = new_wait_budget(10 SECONDS, "кормление началось")
	while(!role.poweron_feed)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(role.poweron_feed, "Кровосос пьёт кровь.")
	vampire.mind.remove_antag_datum(/datum/antagonist/bloodsucker/training)
	sleep(2.5 SECONDS)
	TEST_ASSERT(!feed.active, "Снятый вместе с ролью Feed выключен.")
	TEST_ASSERT(!HAS_TRAIT_FROM(vampire, TRAIT_MUTE, "bloodsucker_feed"), "Рот освободился.")

/datum/unit_test/bloodsucker_gohome_survives_removal/Run()
	var/mob/living/carbon/human/vampire = allocate(/mob/living/carbon/human)
	vampire.mind_initialize()
	var/datum/antagonist/bloodsucker/training/role = vampire.mind.add_antag_datum(/datum/antagonist/bloodsucker/training)
	role.coffin = allocate(/obj/structure/closet/crate/coffin)
	var/datum/action/cooldown/bloodsucker/gohome/vanish = new
	role.BuyPower(vanish)
	vampire.blood_volume = BLOOD_VOLUME_NORMAL
	var/list/finished = list()
	INVOKE_ASYNC(src, PROC_REF(trigger_and_mark), vanish, finished)
	sleep(1 SECONDS)
	vampire.mind.remove_antag_datum(/datum/antagonist/bloodsucker/training)
	TEST_ASSERT_NULL(vanish.owner, "Vanishing Act снят вместе с ролью.")
	var/list/budget = new_wait_budget(15 SECONDS, "Vanishing Act закончился")
	while(!length(finished))
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(length(finished), "Снятая сила дорабатывает без ошибок.")
	TEST_ASSERT_EQUAL(vampire.loc, run_loc_floor_bottom_left, "Снятая сила не уносит бывшего кровососа в гроб.")
	qdel(vanish)

/datum/unit_test/bloodsucker_gohome_survives_removal/proc/trigger_and_mark(datum/action/cooldown/bloodsucker/power, list/finished)
	power.Trigger()
	finished += TRUE

/datum/unit_test/bloodsucker_quiet_power_removal/Run()
	var/mob/living/carbon/human/vampire = allocate(/mob/living/carbon/human)
	vampire.mind_initialize()
	var/datum/antagonist/bloodsucker/training/role = vampire.mind.add_antag_datum(/datum/antagonist/bloodsucker/training)
	var/datum/action/cooldown/bloodsucker/masquerade/mask = locate() in role.powers
	var/datum/action/cooldown/bloodsucker/veil/veil = new
	role.BuyPower(veil)
	vampire.blood_volume = BLOOD_VOLUME_NORMAL
	INVOKE_ASYNC(mask, TYPE_PROC_REF(/datum/action/cooldown/bloodsucker, Trigger))
	INVOKE_ASYNC(veil, TYPE_PROC_REF(/datum/action/cooldown/bloodsucker, Trigger))
	TEST_ASSERT(mask.active && veil.active, "Masquerade и Veil включены.")
	var/smoke_before = 0
	for(var/obj/effect/particle_effect/smoke/vampsmoke/puff in range(4, vampire))
		smoke_before++
	GLOB.unit_test_chat_capture = list()
	vampire.mind.remove_antag_datum(/datum/antagonist/bloodsucker/training)
	var/list/heard = list()
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		if(entry[1] == vampire || entry[1] == vampire.mind)
			heard += entry[2]
	GLOB.unit_test_chat_capture = null
	var/smoke_after = 0
	for(var/obj/effect/particle_effect/smoke/vampsmoke/puff in range(4, vampire))
		smoke_after++
	var/chat = jointext(heard, "\n")
	TEST_ASSERT(!findtext(chat, "последний раз"), "Снятие роли не печатает реплику выключения Masquerade.")
	TEST_ASSERT(smoke_after <= smoke_before, "Снятие роли не пускает дым Veil.")
	TEST_ASSERT_EQUAL(vampire.name, vampire.real_name, "Veil вернул настоящее имя.")
	qdel(veil)

/datum/unit_test/chaplain_armwraps_allow_own_spells/Run()
	var/mob/living/carbon/human/chaplain = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/gloves/fingerless/pugilist/chaplain/wraps = allocate(/obj/item/clothing/gloves/fingerless/pugilist/chaplain)
	TEST_ASSERT(chaplain.equip_to_slot_if_possible(wraps, ITEM_SLOT_GLOVES), "Обмотки надеты.")
	TEST_ASSERT(chaplain.anti_magic_check(), "Обмотки держат чужую магию.")
	TEST_ASSERT(!chaplain.anti_magic_check(TRUE, FALSE, chargecost = 0, self = TRUE), "Обмотки не мешают священнику колдовать.")

/datum/unit_test/hypnotic_gaze_blocked_by_foilhat/Run()
	var/mob/living/carbon/human/hypnotist = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	target.mind_initialize()
	var/obj/item/clothing/head/foilhat/hat = allocate(/obj/item/clothing/head/foilhat)
	TEST_ASSERT(target.equip_to_slot_if_possible(hat, ITEM_SLOT_HEAD), "Шапочка надета.")
	var/datum/action/cooldown/hypnotize/gaze = new
	gaze.Grant(hypnotist)
	hypnotist.start_pulling(target, GRAB_AGGRESSIVE, supress_message = TRUE)
	hypnotist.setGrabState(GRAB_AGGRESSIVE)
	INVOKE_ASYNC(gaze, TYPE_PROC_REF(/datum/action/cooldown/hypnotize, Activate))
	TEST_ASSERT(!LAZYLEN(hypnotist.do_afters), "Гипновзгляд не начинается на цели в шапочке из фольги.")
	qdel(gaze)

/datum/unit_test/hijack_implant_removed_mid_remote_hijack/Run()
	var/obj/machinery/power/apc/apc = allocate(/obj/machinery/power/apc)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/obj/item/implant/hijack/implant = allocate(/obj/item/implant/hijack)
	TEST_ASSERT(implant.implant(user, null, TRUE), "Имплант встаёт.")
	INVOKE_ASYNC(implant, TYPE_PROC_REF(/obj/item/implant/hijack, hijack_remotely), apc)
	TEST_ASSERT(apc.being_hijacked, "Удалённый взлом начался.")
	implant.removed(user)
	sleep(4.5 SECONDS)
	TEST_ASSERT(!apc.being_hijacked, "Взлом извлечённым имплантом снят с APC.")
	TEST_ASSERT(!implant.hijacking, "Извлечённый имплант не считает себя занятым.")
	TEST_ASSERT_EQUAL(user.light_range, 0, "Бывший носитель не светится.")

/proc/hijack_test_wait(obj/machinery/power/apc/apc)
	var/waited = 0
	while(apc.being_hijacked && waited < 3 SECONDS)
		sleep(world.tick_lag)
		waited += world.tick_lag

/datum/unit_test/hijack_apc_at_area_limit_releases_flags/Run()
	var/obj/machinery/power/apc/apc = allocate(/obj/machinery/power/apc)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/obj/item/implant/hijack/implant = allocate(/obj/item/implant/hijack)
	TEST_ASSERT(implant.implant(user, null, TRUE), "Имплант встаёт.")
	TEST_ASSERT_NOTNULL(apc.area, "APC стоит в зоне.")
	for(var/area/other as anything in GLOB.sortedAreas)
		if(other != apc.area && length(user.siliconaccessareas) < HIJACK_APC_MAX_AMOUNT)
			user.siliconaccessareas += other
	TEST_ASSERT_EQUAL(length(user.siliconaccessareas), HIJACK_APC_MAX_AMOUNT, "Взломщик уже держит предельное число зон.")
	user.cached_multiplicative_actions_slowdown = 0.05
	INVOKE_ASYNC(apc, TYPE_PROC_REF(/obj/machinery/power/apc, hijack), user)
	TEST_ASSERT(apc.being_hijacked, "Взлом начался.")
	hijack_test_wait(apc)
	var/stuck_apc = apc.being_hijacked
	var/stuck_implant = implant.hijacking
	var/taken = (apc.area in user.siliconaccessareas)
	user.siliconaccessareas = list()
	TEST_ASSERT(!stuck_apc, "Взлом сверх предела зон снят с APC.")
	TEST_ASSERT(!stuck_implant, "Имплант после отказа по пределу зон снова свободен.")
	TEST_ASSERT(!taken && !apc.hijacker, "Шестнадцатая зона не взята.")

/datum/unit_test/hijack_apc_counter_after_relinquish/Run()
	var/obj/machinery/power/apc/apc = allocate(/obj/machinery/power/apc)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/mob/living/carbon/human/previous = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/obj/item/implant/hijack/implant = allocate(/obj/item/implant/hijack)
	TEST_ASSERT(implant.implant(user, null, TRUE), "Имплант встаёт.")
	TEST_ASSERT(previous.toggleSiliconAccessArea(apc.area), "Прежний взломщик держит зону.")
	apc.hijacker = previous
	user.cached_multiplicative_actions_slowdown = 0.05
	INVOKE_ASYNC(apc, TYPE_PROC_REF(/obj/machinery/power/apc, hijack), user)
	TEST_ASSERT(apc.being_hijacked, "Контр-взлом начался.")
	// Relinquish APC прежнего владельца посреди контр-взлома.
	apc.hijacker = null
	previous.toggleSiliconAccessArea(apc.area)
	hijack_test_wait(apc)
	TEST_ASSERT(!apc.being_hijacked, "Контр-взлом отпущенного APC закончился.")
	TEST_ASSERT(!implant.hijacking, "Имплант после контр-взлома свободен.")
	TEST_ASSERT_EQUAL(apc.hijacker, user, "Отпущенный APC достался контр-взломщику.")
	TEST_ASSERT(!(apc.area in previous.siliconaccessareas), "Прежний взломщик зону не вернул.")
	user.siliconaccessareas = list()
	apc.hijacker = null

/datum/unit_test/hijack_apc_implant_removed_mid_hijack/Run()
	var/obj/machinery/power/apc/apc = allocate(/obj/machinery/power/apc)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	apc.hijack(stranger)
	TEST_ASSERT(!apc.being_hijacked, "Без импланта взлом не начинается.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/obj/item/implant/hijack/implant = allocate(/obj/item/implant/hijack)
	TEST_ASSERT(implant.implant(user, null, TRUE), "Имплант встаёт.")
	user.cached_multiplicative_actions_slowdown = 0.05
	INVOKE_ASYNC(apc, TYPE_PROC_REF(/obj/machinery/power/apc, hijack), user)
	TEST_ASSERT(apc.being_hijacked, "Взлом начался.")
	implant.removed(user)
	hijack_test_wait(apc)
	var/taken = (apc.area in user.siliconaccessareas)
	user.siliconaccessareas = list()
	TEST_ASSERT(!apc.being_hijacked, "Взлом извлечённым имплантом снят с APC.")
	TEST_ASSERT(!implant.hijacking, "Извлечённый имплант не считает себя занятым.")
	TEST_ASSERT(!taken && !apc.hijacker, "Без импланта зона не взята.")

/datum/unit_test/hijack_apc_abilities_only_for_hijacker/Run()
	var/obj/machinery/power/apc/apc = allocate(/obj/machinery/power/apc)
	if(!apc.cell)
		apc.cell = new /obj/item/stock_parts/cell/high(apc)
	apc.cell.charge = apc.cell.maxcharge
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/obj/item/implant/hijack/implant = allocate(/obj/item/implant/hijack)
	var/obj/item/implant/hijack/stranger_implant = allocate(/obj/item/implant/hijack)
	TEST_ASSERT(implant.implant(user, null, TRUE) && stranger_implant.implant(stranger, null, TRUE), "Импланты встают.")
	implant.activate()
	stranger_implant.activate()
	TEST_ASSERT_NULL(apc.hijack_ability_implant(user, 85), "Невзломанный APC никому не даёт осушить ячейку.")
	apc.hijacker = user
	TEST_ASSERT(apc.hijack_ability_implant(user, 85) == implant, "Взломщик может осушить свой APC.")
	TEST_ASSERT_NULL(apc.hijack_ability_implant(stranger, 35), "Чужой взломщик не управляет этим APC.")
	apc.cell.charge = apc.cell.maxcharge * 0.5
	var/drain_on_half = apc.hijack_ability_implant(user, 85)
	var/lockdown_on_half = apc.hijack_ability_implant(user, 35)
	apc.hijacker = null
	TEST_ASSERT_NULL(drain_on_half, "Осушение требует 85% заряда.")
	TEST_ASSERT(lockdown_on_half == implant, "Блокировке дверей хватает половины заряда.")

/datum/unit_test/bloodsucker_mesmerize_windup_after_removal/Run()
	var/mob/living/carbon/human/vampire = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	vampire.mind_initialize()
	var/datum/antagonist/bloodsucker/training/role = vampire.mind.add_antag_datum(/datum/antagonist/bloodsucker/training)
	var/datum/action/cooldown/bloodsucker/targeted/mesmerize/gaze = new
	role.BuyPower(gaze)
	gaze.FireTargetedPower(victim)
	TEST_ASSERT(gaze.signal_procs?[victim]?[COMSIG_MOVABLE_MOVED], "Замах следит за жертвой.")
	vampire.mind.remove_antag_datum(/datum/antagonist/bloodsucker/training)
	TEST_ASSERT_NULL(gaze.owner, "Сила снята вместе с ролью.")
	gaze.apply_effects(vampire, victim, 10 SECONDS)
	var/stunned = victim.IsStun()
	var/still_watching = gaze.signal_procs?[victim]?[COMSIG_MOVABLE_MOVED]
	qdel(gaze)
	TEST_ASSERT(!stunned, "Снятая сила не дотягивает гипноз до жертвы.")
	TEST_ASSERT(!still_watching, "Снятая сила больше не следит за шагами жертвы.")

/datum/unit_test/bloodsucker_haste_removed_mid_dash/Run()
	var/mob/living/carbon/human/vampire = allocate(/mob/living/carbon/human)
	vampire.mind_initialize()
	var/datum/antagonist/bloodsucker/training/role = vampire.mind.add_antag_datum(/datum/antagonist/bloodsucker/training)
	var/datum/action/cooldown/bloodsucker/targeted/haste/dash = new
	role.BuyPower(dash)
	dash.speed_override = 1 SECONDS
	INVOKE_ASYNC(dash, TYPE_PROC_REF(/datum/action/cooldown/bloodsucker/targeted/haste, FireTargetedPower), run_loc_floor_top_right)
	TEST_ASSERT(dash.signal_procs?[vampire]?[COMSIG_MOVABLE_MOVED], "Рывок следит за шагами.")
	vampire.mind.remove_antag_datum(/datum/antagonist/bloodsucker/training)
	sleep(1.5 SECONDS)
	var/still_watching = dash.signal_procs?[vampire]?[COMSIG_MOVABLE_MOVED]
	qdel(dash)
	TEST_ASSERT(!still_watching, "Рывок снятой силы отписался от шагов тела.")

/datum/unit_test/ssd_body_ghost_keeps_disconnect_time/Run()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	body.ckey = "unit_test_ssd_ghost"
	body.lastclienttime = 1
	var/mob/dead/observer/ghost = body.ghostize(TRUE)
	TEST_ASSERT_NOTNULL(ghost, "Тело SSD-игрока даёт госта.")
	var/inherited = ghost.lastclienttime
	qdel(ghost)
	TEST_ASSERT_EQUAL(inherited, 1, "Гост SSD-игрока продолжает отсчёт автокрио с момента отключения.")
