/area/unit_test_pocket_noteleport
	name = "Pocket No-Teleport Test Room"
	requires_power = FALSE
	area_flags = NOTELEPORT

/obj/effect/eldritch/big/pocket_fixture
	var/list/offered
	var/answer

/obj/effect/eldritch/big/pocket_fixture/prompt_ritual(mob/living/user, list/rituals)
	offered = rituals.Copy()
	return answer

/datum/action/innate/heretic_pocket_leave/prompt_fixture
	var/datum/callback/during_prompt
	var/answer

/datum/action/innate/heretic_pocket_leave/prompt_fixture/choose_exit(list/exits)
	during_prompt?.Invoke()
	return answer

/datum/action/innate/heretic_pocket_leave/prompt_fixture/Destroy()
	during_prompt = null
	return ..()

/datum/eldritch_knowledge/pocket_exit_probe
	name = "Проверочный выход"
	var/list/exits = list()
	var/offers_door = FALSE
	var/door_hold
	var/checks = 0

/datum/eldritch_knowledge/pocket_exit_probe/pocket_exits(mob/living/user)
	return exits

/datum/eldritch_knowledge/pocket_exit_probe/pocket_door(mob/living/user, mob/living/victim)
	if(!offers_door)
		return null
	. = list("name" = "проба", "text" = "Проверочная дверь открывается.", "time" = 0, "check" = CALLBACK(src, PROC_REF(count_check)))
	if(!isnull(door_hold))
		.["hold"] = door_hold

/datum/eldritch_knowledge/pocket_exit_probe/proc/count_check()
	checks++
	return TRUE

/datum/eldritch_knowledge/pocket_exit_probe/proc/close_door()
	offers_door = FALSE

/datum/unit_test/heretic_pocket
	var/list/door_checks = list()
	var/list/previous_sacrificed

/datum/unit_test/heretic_pocket/Destroy()
	if(previous_sacrificed)
		GLOB.heretic_sacrificed_minds = previous_sacrificed
	return ..()

/datum/unit_test/heretic_pocket/proc/pocket_heretic()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	return allocate_heretic()

/datum/unit_test/heretic_pocket/proc/pocket_victim(datum/antagonist/heretic/heretic, turf/location)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, location)
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	heretic.set_hunt_target(soul)
	return victim

/datum/unit_test/heretic_pocket/proc/count_door_check()
	door_checks += world.time
	return TRUE

/datum/unit_test/heretic_pocket/proc/swap_leave_action(datum/heretic_pocket/pocket, answer, datum/callback/during_prompt)
	var/datum/action/innate/heretic_pocket_leave/prompt_fixture/probe = new(pocket)
	probe.answer = answer
	probe.during_prompt = during_prompt
	QDEL_NULL(pocket.leave_action)
	pocket.leave_action = probe
	probe.Grant(pocket.heretic)
	return probe

/datum/unit_test/heretic_pocket/proc/exit_label(datum/antagonist/heretic/heretic, turf/spot)
	var/list/exits = heretic.pocket_exits(heretic.owner.current)
	for(var/label in exits)
		if(exits[label] == spot)
			return label
	return null

/datum/unit_test/heretic_pocket/proc/reset_pocket(datum/heretic_pocket/pocket, mob/living/victim)
	COOLDOWN_RESET(pocket, reopen_cooldown)
	for(var/datum/status_effect/heretic_capture_immunity/immunity as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		qdel(immunity)

/// Дверь уводит цель охоты и еретика в изнанку: цель в центре, еретик рядом, разрыв на входе, действие выхода и таймеры на месте.
/datum/unit_test/heretic_pocket/Run()
	var/datum/antagonist/heretic/heretic = pocket_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(entry, NORTH))
	var/started = world.time
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, door_check = CALLBACK(src, PROC_REF(count_door_check)), door_text = "Проверочная дверь открывается."), "Дверь уводит цель охоты в изнанку.")
	TEST_ASSERT(world.time - started >= HERETIC_POCKET_PULL_TIME - 0.1, "Вход занимает [HERETIC_POCKET_PULL_TIME / (1 SECONDS)] с: прошло [world.time - started] дс.")
	TEST_ASSERT(length(door_checks) >= 3, "Условие двери проверяется до, во время и после канала: [length(door_checks)] раз.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	TEST_ASSERT_NOTNULL(pocket, "Изнанка создаётся при первом входе.")
	TEST_ASSERT(pocket.active, "Изнанка открыта.")
	var/area/room = get_area(victim)
	TEST_ASSERT(istype(room, /area/heretic_pocket), "Цель в изнанке.")
	TEST_ASSERT_EQUAL(room.area_flags & (UNIQUE_AREA | NOTELEPORT | RADIO_BLACKOUT), UNIQUE_AREA | NOTELEPORT | RADIO_BLACKOUT, "Изнанка закрыта для телепортов и радио.")
	TEST_ASSERT_EQUAL(get_turf(victim), pocket.center, "Цель стоит в центре изнанки.")
	TEST_ASSERT(istype(get_area(user), /area/heretic_pocket), "Еретик входит следом.")
	TEST_ASSERT_EQUAL(get_dist(user, victim), 1, "Еретик рядом с целью.")
	TEST_ASSERT_EQUAL(pocket.rift?.loc, entry, "Разрыв остаётся на входе.")
	TEST_ASSERT(pocket.contains(pocket.inner_rift), "Внутренняя сторона разрыва в изнанке.")
	TEST_ASSERT(isclosedturf(get_step(pocket.inner_rift, NORTH)), "Внутренняя сторона разрыва у стены.")
	var/list/rift_states = icon_states(pocket.rift.icon)
	TEST_ASSERT((pocket.rift.icon_state in rift_states) && (pocket.inner_rift.icon_state in rift_states), "Обе стороны разрыва рисуются своими стейтами.")
	TEST_ASSERT_NOTEQUAL(pocket.rift.icon_state, pocket.inner_rift.icon_state, "Снаружи и изнутри разрыв выглядит по-разному.")
	var/glow_found = FALSE
	for(var/mutable_appearance/glow as anything in pocket.rift.overlays)
		if(glow.icon_state == "[pocket.rift.icon_state]_glow" && glow.plane != EMISSIVE_PLANE)
			glow_found = TRUE
	TEST_ASSERT(glow_found, "У разрыва есть слой кромки, который красится чернилами пути.")
	TEST_ASSERT(locate(/datum/action/innate/heretic_pocket_leave) in user.actions, "Еретик получает действие выхода.")
	var/floors = 0
	var/walls = 0
	for(var/turf/tile as anything in pocket.reservation.reserved_turfs)
		if(istype(tile, /turf/open/indestructible/heretic_pocket))
			floors++
		else if(istype(tile, /turf/closed/indestructible/heretic_pocket))
			walls++
	TEST_ASSERT_EQUAL(floors, (HERETIC_POCKET_SIZE - 2) ** 2, "Пол изнанки [HERETIC_POCKET_SIZE - 2]x[HERETIC_POCKET_SIZE - 2].")
	TEST_ASSERT_EQUAL(walls, HERETIC_POCKET_SIZE ** 2 - (HERETIC_POCKET_SIZE - 2) ** 2, "Изнанку окружают стены.")
	var/datum/timedevent/timeout = SStimer.timer_id_dict[pocket.collapse_timer]
	TEST_ASSERT_NOTNULL(timeout, "Изнанку закрывает свой таймер.")
	TEST_ASSERT(abs(timeout.timeToRun - world.time - HERETIC_POCKET_DURATION) < 1, "Изнанка держится [HERETIC_POCKET_DURATION / (1 SECONDS)] с: [timeout.timeToRun - world.time] дс.")
	var/datum/timedevent/warning = SStimer.timer_id_dict[pocket.warning_timer]
	TEST_ASSERT_NOTNULL(warning, "Предупреждение ставит свой таймер.")
	TEST_ASSERT(abs(warning.timeToRun - world.time - (HERETIC_POCKET_DURATION - HERETIC_POCKET_WARNING)) < 1, "Предупреждение за [HERETIC_POCKET_WARNING / (1 SECONDS)] с до конца: [warning.timeToRun - world.time] дс.")
	TEST_ASSERT(findtext(jointext(pocket.rift.examine(crew), " "), "шагнул в никуда"), "Экипаж видит улику у разрыва.")
	TEST_ASSERT_EQUAL(heretic_pocket_anchor(get_turf(victim)), entry, "Для охоты изнанка остаётся у своего входа.")
	TEST_ASSERT_NULL(heretic.hunt_target_unavailable_reason(victim.mind), "Цель в изнанке доступна для обряда.")
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book, user)
	var/list/book_data = book.ui_data(user)
	var/list/hunt_data = book_data["hunt"]
	var/list/pocket_data = hunt_data["pocket"]
	TEST_ASSERT_EQUAL(pocket_data["duration"], HERETIC_POCKET_DURATION / (1 SECONDS), "Кодекс берёт длительность изнанки из дефайна.")
	TEST_ASSERT_EQUAL(pocket_data["tear"], HERETIC_POCKET_TEAR_TIME / (1 SECONDS), "Кодекс берёт время разрыва из дефайна.")
	TEST_ASSERT_EQUAL(pocket_data["cooldown"], HERETIC_POCKET_COOLDOWN / (1 SECONDS), "Кодекс берёт перезарядку изнанки из дефайна.")
	TEST_ASSERT_EQUAL(pocket_data["hold"], HERETIC_POCKET_ENTRY_HOLD / (1 SECONDS), "Кодекс берёт удержание на входе из дефайна.")

/// Изнанка отказывает вне станции, чужой цели, цели в шкафу, под антимагией, под запретом телепортов у входа, еретика или цели, еретику в крите или в наручниках, при открытой изнанке и в перезарядке.
/datum/unit_test/heretic_pocket/refusals/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, victim, entry), "станци"), "Вход вне станции отклонён.")
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	TEST_ASSERT_NULL(heretic.pocket_pull_reason(user, victim, entry), "Цель охоты у входа на станции проходит.")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, get_step(entry, NORTH))
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, stranger, entry), "цель охоты"), "Чужая цель отклонена.")
	TEST_ASSERT_NULL(heretic.pocket_pull_reason(user, stranger, entry, hunt_only = FALSE), "Дверь без охоты берёт любую цель.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, victim, entry), "защищена от магии"), "Антимагия цели не пускает в изнанку.")
	qdel(protection)
	ADD_TRAIT(victim, TRAIT_NO_TELEPORT, "unit_test")
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, victim, entry), "на месте"), "Запрет телепорта у цели не пускает в изнанку.")
	REMOVE_TRAIT(victim, TRAIT_NO_TELEPORT, "unit_test")
	var/turf/sealed = get_step(entry, EAST)
	heretic_test_area(sealed, /area/unit_test_pocket_noteleport)
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, victim, sealed), "телепорт"), "Вход под запретом телепортов отклонён.")
	user.forceMove(sealed)
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, victim, entry), "Отсюда в изнанку не уйти"), "Еретик под запретом телепортов не уходит в изнанку.")
	user.forceMove(run_loc_floor_bottom_left)
	victim.forceMove(sealed)
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, victim, entry), "Завеса не отпустит"), "Цель под запретом телепортов не уходит в изнанку.")
	victim.forceMove(entry)
	user.set_stat(SOFT_CRIT)
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, victim, entry), "сознание"), "Еретик в мягком крите не открывает изнанку.")
	user.set_stat(CONSCIOUS)
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, victim, entry), "наручниках"), "Скованный еретик не открывает изнанку.")
	user.uncuff()
	var/obj/structure/closet/locker = allocate(/obj/structure/closet, entry)
	victim.forceMove(locker)
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, victim, entry), "в шкафу"), "Цель в шкафу завеса не достаёт.")
	TEST_ASSERT(!heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель из шкафа в изнанку не уходит.")
	TEST_ASSERT_EQUAL(victim.loc, locker, "Цель осталась в шкафу.")
	victim.forceMove(entry)
	qdel(locker)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, victim, entry), "уже открыта"), "Вторая дверь не открывает занятую изнанку.")
	heretic.pocket.collapse("проверка")
	for(var/datum/status_effect/heretic_capture_immunity/immunity as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		qdel(immunity)
	var/reason = heretic.pocket_pull_reason(user, victim, entry)
	TEST_ASSERT(findtext(reason, "осталось [HERETIC_POCKET_COOLDOWN / (1 SECONDS)] с"), "Закрытая изнанка ждёт перезарядки: [reason]")

/// Изнанка закрывается по времени, от крита еретика, жезлом или Библией с любой стороны и разрывом руками человека, киборга или зверя; владелец, удерживаемая и скованная цель разрыв не рвут.
/datum/unit_test/heretic_pocket/collapse/Run()
	var/datum/antagonist/heretic/heretic = pocket_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(entry, NORTH))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, crew)
	crew.put_in_hands(rod)
	var/obj/item/storage/book/bible/bible = allocate(/obj/item/storage/book/bible, crew)
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot, get_step(entry, SOUTH))
	var/mob/living/simple_animal/pet/dog/corgi/dog = allocate(/mob/living/simple_animal/pet/dog/corgi, get_step(entry, SOUTHEAST))

	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	TEST_ASSERT(pocket.rift.layer < LYING_MOB_LAYER, "Разрыв лежит под мобами на входе и не перехватывает клики по ним.")
	TEST_ASSERT(pocket.rift.mouse_opacity != MOUSE_OPACITY_TRANSPARENT, "Сам разрыв остаётся кликабельным.")
	var/obj/effect/heretic_pocket_rift/rift = pocket.rift
	var/obj/effect/heretic_pocket_rift/inner = pocket.inner_rift
	var/warning_id = pocket.warning_timer
	pocket.on_timeout()
	TEST_ASSERT(!pocket.active, "Время закрывает изнанку.")
	TEST_ASSERT_EQUAL(get_turf(user), entry, "Еретик выпадает у входа.")
	TEST_ASSERT_EQUAL(get_turf(victim), entry, "Цель выпадает у входа.")
	TEST_ASSERT(QDELETED(rift), "Разрыв снаружи исчезает.")
	TEST_ASSERT(QDELETED(inner), "Разрыв изнутри исчезает.")
	TEST_ASSERT_NULL(SStimer.timer_id_dict[warning_id], "Таймер предупреждения снят.")
	TEST_ASSERT(!(locate(/datum/action/innate/heretic_pocket_leave) in user.actions), "Действие выхода снято.")

	reset_pocket(pocket, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель снова уходит в изнанку.")
	user.adjustBruteLoss(150)
	TEST_ASSERT(user.stat >= SOFT_CRIT, "Еретик в крите.")
	TEST_ASSERT(!pocket.active, "Крит еретика закрывает изнанку.")
	TEST_ASSERT_EQUAL(get_turf(user), entry, "Тело еретика выпадает у входа.")
	user.fully_heal()

	reset_pocket(pocket, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Вход перед жезлом снаружи.")
	rod.melee_attack_chain(crew, pocket.rift)
	TEST_ASSERT(!pocket.active, "Жезл снаружи закрывает изнанку.")

	reset_pocket(pocket, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Вход перед Библией.")
	bible.melee_attack_chain(crew, pocket.rift)
	TEST_ASSERT(!pocket.active, "Библия закрывает изнанку, как и руну.")

	reset_pocket(pocket, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Вход перед жезлом изнутри.")
	pocket.end_entry_hold()
	var/obj/item/nullrod/inner_rod = allocate(/obj/item/nullrod, victim)
	victim.put_in_hands(inner_rod)
	inner_rod.melee_attack_chain(victim, pocket.inner_rift)
	TEST_ASSERT(!pocket.active, "Жезл изнутри закрывает изнанку.")
	qdel(inner_rod)

	reset_pocket(pocket, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Вход перед разрывом снаружи.")
	TEST_ASSERT_EQUAL(pocket.rift.tear_time, HERETIC_POCKET_TEAR_TIME, "Разрыв руками занимает [HERETIC_POCKET_TEAR_TIME / (1 SECONDS)] с.")
	pocket.rift.tear_time = 0.2 SECONDS
	TEST_ASSERT(pocket.rift.tear(crew), "Экипаж разрывает изнанку руками.")
	TEST_ASSERT(!pocket.active, "Разрыв руками закрывает изнанку.")
	TEST_ASSERT_EQUAL(get_turf(victim), entry, "Цель выпадает у входа.")

	reset_pocket(pocket, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Вход перед киборгом.")
	pocket.rift.tear_time = 0.2 SECONDS
	pocket.rift.attack_animal(dog)
	TEST_ASSERT(!LAZYFIND(dog.do_afters, pocket.rift), "Зверь без игрока не начинает рвать разрыв.")
	TEST_ASSERT(pocket.active, "Зверь без игрока разрыв не трогает.")
	pocket.rift.attack_robot(borg)
	TEST_ASSERT(wait_for_var(pocket, NAMEOF(pocket, active), FALSE), "Киборг разрывает изнанку манипуляторами.")

	reset_pocket(pocket, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Вход перед зверем.")
	pocket.rift.tear_time = 0.2 SECONDS
	TEST_ASSERT(pocket.rift.tear(dog), "Зверь рвёт разрыв по тем же правилам.")
	TEST_ASSERT(!pocket.active, "Разрыв зверем закрывает изнанку.")

	reset_pocket(pocket, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Вход перед разрывом изнутри.")
	pocket.end_entry_hold()
	var/obj/effect/heretic_pocket_rift/inner_side = pocket.inner_rift
	inner_side.tear_time = 0.2 SECONDS
	user.forceMove(get_step(inner_side, SOUTHWEST))
	victim.forceMove(get_step(inner_side, SOUTH))
	TEST_ASSERT(!inner_side.tear(user), "Разрыв не отвечает еретику-владельцу.")
	user.start_pulling(victim)
	TEST_ASSERT_EQUAL(victim.pulledby, user, "Еретик держит цель.")
	TEST_ASSERT(!inner_side.tear(victim), "Удерживаемая цель не вырывается.")
	user.stop_pulling()
	victim.handcuffed = allocate(/obj/item/restraints/handcuffs, victim)
	victim.update_handcuffed()
	TEST_ASSERT(!inner_side.tear(victim), "Скованная цель не вырывается.")
	TEST_ASSERT(findtext(jointext(inner_side.examine(victim), " "), "наручников"), "Осмотр изнутри предупреждает про наручники.")
	TEST_ASSERT(pocket.active, "Отказы не закрывают изнанку.")
	victim.uncuff()
	TEST_ASSERT(inner_side.tear(victim), "Цель изнутри разрывает изнанку.")
	TEST_ASSERT(!pocket.active, "Разрыв изнутри закрывает изнанку.")
	TEST_ASSERT_EQUAL(get_turf(victim), entry, "Цель выпадает у входа.")

/// Выход ведёт еретика к своей руне или ремеслу пути на станции, а цель и вещи с пола изнанки выпадают у входа.
/datum/unit_test/heretic_pocket/exits/Run()
	var/datum/antagonist/heretic/heretic = pocket_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	var/turf/rune_spot = locate(user.x + 2, user.y + 2, user.z)
	var/obj/effect/eldritch/big/own_rune = allocate(/obj/effect/eldritch/big, rune_spot)
	own_rune.drawn_by = WEAKREF(heretic.owner)
	var/turf/foreign_spot = locate(user.x + 4, user.y + 4, user.z)
	allocate(/obj/effect/eldritch/big, foreign_spot)
	var/turf/sealed_spot = locate(user.x, user.y + 4, user.z)
	heretic_test_area(sealed_spot, /area/unit_test_pocket_noteleport)
	var/obj/effect/eldritch/big/sealed_rune = allocate(/obj/effect/eldritch/big, sealed_spot)
	sealed_rune.drawn_by = WEAKREF(heretic.owner)
	var/turf/window_spot = locate(user.x + 4, user.y, user.z)
	allocate(/obj/structure/window/fulltile, window_spot)
	var/datum/eldritch_knowledge/pocket_exit_probe/probe = allocate(/datum/eldritch_knowledge/pocket_exit_probe)
	probe.exits = list("Проверочное окно" = window_spot, "Запечатанное ремесло" = sealed_spot)
	heretic.researched_knowledge[probe.type] = probe

	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	var/list/exits = heretic.pocket_exits(user)
	var/list/exit_turfs = list()
	for(var/label in exits)
		exit_turfs += exits[label]
	TEST_ASSERT_EQUAL(exits["Туда, откуда пришли"], entry, "Выход ко входу есть всегда.")
	TEST_ASSERT(rune_spot in exit_turfs, "Своя руна служит выходом.")
	TEST_ASSERT(!(foreign_spot in exit_turfs), "Чужая руна выходом не служит.")
	TEST_ASSERT(!(sealed_spot in exit_turfs), "Под запретом телепортов выхода нет.")
	TEST_ASSERT_EQUAL(exits["Проверочное окно"], window_spot, "Знания пути добавляют свои выходы.")
	var/obj/item/pen/dropped = allocate(/obj/item/pen, get_step(pocket.center, NORTH))
	TEST_ASSERT(!pocket.leave(user, sealed_spot), "Выход под запретом телепортов не открывается.")
	TEST_ASSERT(pocket.active, "Отказ в выходе не закрывает изнанку.")
	TEST_ASSERT(pocket.leave(user, rune_spot), "Еретик выходит к своей руне.")
	TEST_ASSERT_EQUAL(get_turf(user), rune_spot, "Еретик стоит на руне.")
	TEST_ASSERT_EQUAL(get_turf(victim), entry, "Цель выпадает у входа.")
	TEST_ASSERT_EQUAL(get_turf(dropped), entry, "Вещи с пола изнанки выпадают у входа.")
	TEST_ASSERT(!pocket.active, "Выход закрывает изнанку.")

	reset_pocket(pocket, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель снова уходит в изнанку.")
	TEST_ASSERT(pocket.leave(user, window_spot), "Еретик выходит к ремеслу-окну.")
	TEST_ASSERT_EQUAL(get_dist(user, window_spot), 1, "Занятая клетка выхода даёт соседний пол.")
	heretic.researched_knowledge -= probe.type

/// Обряд сердцем в изнанке проходит как на станции: жертва уходит в Мансус, изнанка остаётся открытой.
/datum/unit_test/heretic_pocket/heart_rite/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	previous_sacrificed = GLOB.heretic_sacrificed_minds.Copy()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/user_mind = allocate_mind()
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/ritual_fixture/heretic = allocate(/datum/antagonist/heretic/ritual_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	heretic.test_return_turf = run_loc_floor_top_right
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/datum/eldritch_knowledge/spell/basic/ritual = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	ritual.ritual_time = 1 SECONDS
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_bottom_left)
	TEST_ASSERT(heart.bind(user_mind), "Сердце привязано к еретику.")
	user.put_in_hands(heart)
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	victim.handcuffed = allocate(/obj/item/restraints/handcuffs, victim)
	victim.update_handcuffed()

	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	TEST_ASSERT(heretic.begin_heart_rite(user, victim, heart), "Обряд сердцем в изнанке проходит.")
	TEST_ASSERT_EQUAL(heretic.total_sacrifices, 1, "Обряд в изнанке засчитан.")
	var/datum/heretic_mansus_visit/visit = GLOB.heretic_mansus_visits[victim.mind]
	TEST_ASSERT_NOTNULL(visit, "Жертва уходит в Мансус.")
	allocated += visit
	TEST_ASSERT(!pocket.contains(victim), "Жертва покинула изнанку.")
	TEST_ASSERT(pocket.active, "Начало обряда не закрывает изнанку.")
	TEST_ASSERT_EQUAL(visit.fallback_turf, entry, "Запасной выход Мансуса - вход изнанки.")
	TEST_ASSERT(pocket.leave(user, entry), "Еретик выходит ко входу.")
	TEST_ASSERT(visit.contains(victim), "Закрытие изнанки не забирает жертву из Мансуса.")
	visit.finish()
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Мансус возвращает жертву в коридор станции.")

/// После закрытия цель минуту невосприимчива к изнанке, а изнанка минуту затягивается.
/datum/unit_test/heretic_pocket/release/Run()
	var/datum/antagonist/heretic/heretic = pocket_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	pocket.collapse("проверка")
	var/datum/status_effect/heretic_capture_immunity/immunity = capture_immunity(victim, HERETIC_POCKET_CAPTURE)
	TEST_ASSERT_NOTNULL(immunity, "Цель получает невосприимчивость к изнанке.")
	TEST_ASSERT(abs(immunity.duration - world.time - HERETIC_CAPTURE_IMMUNITY) < 1, "Невосприимчивость [HERETIC_CAPTURE_IMMUNITY / (1 SECONDS)] с: [immunity.duration - world.time] дс.")
	TEST_ASSERT(abs(pocket.reopen_cooldown - world.time - HERETIC_POCKET_COOLDOWN) < 1, "Перезарядка изнанки [HERETIC_POCKET_COOLDOWN / (1 SECONDS)] с: [pocket.reopen_cooldown - world.time] дс.")
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, victim, entry), "приходит в себя"), "Невосприимчивая цель не уходит в изнанку.")

/// Рука по своей руне на «Помощи» уводит готовую цель охоты за руну; без условий руна предлагает прежние обряды.
/datum/unit_test/heretic_pocket/rune_door/Run()
	var/datum/antagonist/heretic/heretic = pocket_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/datum/eldritch_knowledge/spell/basic/ritual = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/turf/rune_spot = get_step(user, NORTHEAST)
	var/obj/effect/eldritch/big/pocket_fixture/rune = allocate(/obj/effect/eldritch/big/pocket_fixture, rune_spot)
	rune.drawn_by = WEAKREF(heretic.owner)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, get_step(rune_spot, EAST))
	user.a_intent = INTENT_HELP

	rune.attack_hand(user)
	TEST_ASSERT_NOTNULL(rune.offered, "Руна предлагает выбор обряда.")
	TEST_ASSERT_NULL(rune.offered[HERETIC_POCKET_RUNE_CHOICE], "Стоящую цель руна не уводит.")
	TEST_ASSERT_EQUAL(rune.offered[ritual.name], ritual, "Прежние обряды остаются в списке.")
	TEST_ASSERT(!rune.is_in_use, "Отказ освобождает руну.")

	victim.handcuffed = allocate(/obj/item/restraints/handcuffs, victim)
	victim.update_handcuffed()
	user.a_intent = INTENT_HARM
	rune.offered = null
	rune.attack_hand(user)
	TEST_ASSERT_NOTNULL(rune.offered, "Руна отвечает на любое намерение.")
	TEST_ASSERT_NULL(rune.offered[HERETIC_POCKET_RUNE_CHOICE], "Без намерения «Помощь» руна не уводит.")
	user.a_intent = INTENT_HELP
	rune.drawn_by = WEAKREF(allocate_mind())
	rune.offered = null
	rune.attack_hand(user)
	TEST_ASSERT_NOTNULL(rune.offered, "Чужая руна тоже открывает выбор.")
	TEST_ASSERT_NULL(rune.offered[HERETIC_POCKET_RUNE_CHOICE], "Чужая руна не уводит.")
	TEST_ASSERT(!istype(get_area(victim), /area/heretic_pocket), "Без двери цель остаётся на станции.")

	rune.drawn_by = WEAKREF(heretic.owner)
	rune.answer = HERETIC_POCKET_RUNE_CHOICE
	rune.offered = null
	rune.attack_hand(user)
	TEST_ASSERT(rune.is_in_use, "Руна занята, пока идёт канал двери.")
	TEST_ASSERT(wait_for_var(rune, NAMEOF(rune, is_in_use), FALSE, 3 SECONDS), "Канал двери заканчивается.")
	TEST_ASSERT_EQUAL(rune.offered[HERETIC_POCKET_RUNE_CHOICE], victim, "Готовую цель у своей руны можно увести.")
	TEST_ASSERT(heretic.pocket?.active, "Руна уводит в изнанку.")
	TEST_ASSERT(istype(get_area(victim), /area/heretic_pocket), "Цель за руной.")
	TEST_ASSERT(istype(get_area(user), /area/heretic_pocket), "Еретик за руной.")
	TEST_ASSERT_EQUAL(heretic.pocket.entry_turf, rune_spot, "Вход изнанки - сама руна.")
	TEST_ASSERT(!rune.is_in_use, "Руна освобождается после двери.")
	TEST_ASSERT(findtext(jointext(rune.examine(user), " "), HERETIC_POCKET_RUNE_CHOICE), "Осмотр руны подсказывает дверь.")

/// Снятие роли выводит всех из изнанки и освобождает резервирование; отдельно созданная изнанка удаляется без следов.
/datum/unit_test/heretic_pocket/teardown/Run()
	var/datum/heretic_pocket/lone = new(null)
	TEST_ASSERT(lone.prepare(), "Изнанка резервирует комнату.")
	var/datum/turf_reservation/lone_reservation = lone.reservation
	var/turf/lone_center = lone.center
	TEST_ASSERT(istype(get_area(lone_center), /area/heretic_pocket), "Комната принадлежит изнанке.")
	qdel(lone)
	TEST_ASSERT(QDELETED(lone_reservation), "Удаление изнанки освобождает резервирование.")
	TEST_ASSERT(!istype(get_area(lone_center), /area/heretic_pocket), "Клетки возвращаются из области изнанки.")
	TEST_ASSERT(!(lone in GLOB.heretic_pockets), "Удалённая изнанка снята с учёта.")

	var/datum/antagonist/heretic/heretic = pocket_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	var/datum/turf_reservation/reserved = pocket.reservation
	var/obj/effect/heretic_pocket_rift/rift = pocket.rift
	var/obj/effect/heretic_pocket_rift/inner = pocket.inner_rift
	heretic.clear_heretic()
	TEST_ASSERT(QDELETED(pocket), "Снятие роли удаляет изнанку.")
	TEST_ASSERT_NULL(heretic.pocket, "Датум еретика не держит удалённую изнанку.")
	TEST_ASSERT(QDELETED(reserved), "Резервирование освобождено.")
	TEST_ASSERT(QDELETED(rift) && QDELETED(inner), "Обе стороны разрыва удалены.")
	TEST_ASSERT_EQUAL(get_turf(user), entry, "Еретик выпадает у входа.")
	TEST_ASSERT_EQUAL(get_turf(victim), entry, "Цель выпадает у входа.")
	TEST_ASSERT(!(pocket in GLOB.heretic_pockets), "Изнанка снята с учёта.")
	TEST_ASSERT(!(locate(/datum/action/innate/heretic_pocket_leave) in user.actions), "Действие выхода снято.")

/// Выход через действие берёт выход заново после окна выбора; закрытие или снятие роли во время выбора ничего не делает и не оставляет ссылок.
/datum/unit_test/heretic_pocket/leave_prompt/Run()
	var/datum/antagonist/heretic/heretic = pocket_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	var/turf/rune_spot = locate(user.x + 2, user.y + 2, user.z)
	var/obj/effect/eldritch/big/rune = allocate(/obj/effect/eldritch/big, rune_spot)
	rune.drawn_by = WEAKREF(heretic.owner)
	var/turf/doomed_spot = locate(user.x + 4, user.y + 4, user.z)
	var/obj/effect/eldritch/big/doomed = allocate(/obj/effect/eldritch/big, doomed_spot)
	doomed.drawn_by = WEAKREF(heretic.owner)

	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	var/rune_label = exit_label(heretic, rune_spot)
	var/doomed_label = exit_label(heretic, doomed_spot)
	TEST_ASSERT_NOTNULL(rune_label, "Своя руна в списке выходов.")
	TEST_ASSERT_NOTNULL(doomed_label, "Вторая руна в списке выходов.")
	var/datum/action/innate/heretic_pocket_leave/prompt_fixture/probe = swap_leave_action(pocket, rune_label)
	probe.Activate()
	TEST_ASSERT_EQUAL(get_turf(user), rune_spot, "Действие выводит к выбранной руне.")
	TEST_ASSERT(QDELETED(probe), "Выход убирает действие.")

	reset_pocket(pocket, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель снова уходит в изнанку.")
	probe = swap_leave_action(pocket, doomed_label, CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel), doomed))
	probe.Activate()
	TEST_ASSERT(QDELETED(doomed), "Руна стёрта, пока было открыто окно выбора.")
	TEST_ASSERT(pocket.active, "Стёртый выход не открывается.")
	TEST_ASSERT(pocket.contains(user), "Еретик остаётся в изнанке.")

	probe.answer = rune_label
	probe.during_prompt = CALLBACK(pocket, TYPE_PROC_REF(/datum/heretic_pocket, collapse), "проверка")
	probe.Activate()
	TEST_ASSERT(QDELETED(probe), "Закрытие во время выбора убирает действие.")
	TEST_ASSERT_NULL(probe.pocket, "Удалённое действие не держит изнанку.")
	TEST_ASSERT_EQUAL(get_turf(user), entry, "Выбор после закрытия не переносит к руне.")

	reset_pocket(pocket, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку перед снятием роли.")
	probe = swap_leave_action(pocket, rune_label, CALLBACK(heretic, TYPE_PROC_REF(/datum/antagonist/heretic, clear_heretic)))
	probe.Activate()
	TEST_ASSERT(QDELETED(pocket), "Снятие роли во время выбора удаляет изнанку.")
	TEST_ASSERT(QDELETED(probe), "Снятие роли убирает действие.")
	TEST_ASSERT_NULL(probe.pocket, "Действие не держит удалённую изнанку.")
	TEST_ASSERT_EQUAL(get_turf(user), entry, "Выбор после снятия роли не переносит к руне.")

/// Клетки изнанки глушат бестелесный переход, а закрытие забирает участника из пустого резерва и вещи со стен.
/datum/unit_test/heretic_pocket/sealed/Run()
	var/datum/antagonist/heretic/heretic = pocket_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	var/turf/wall = get_step(pocket.inner_rift, NORTH)
	TEST_ASSERT(wall.flags_1 & NOJAUNT_1, "Стена изнанки глушит переход.")
	TEST_ASSERT(pocket.center.flags_1 & NOJAUNT_1, "Пол изнанки глушит переход.")
	var/turf/start = get_turf(user)
	var/obj/effect/dummy/phased_mob/spell_jaunt/holder = new(start)
	user.forceMove(holder)
	holder.relaymove(user, WEST)
	TEST_ASSERT_EQUAL(get_turf(holder), start, "Переход не двигается по изнанке к стене.")
	pocket.collapse("проверка")
	TEST_ASSERT_EQUAL(get_turf(user), entry, "Закрытие выносит еретика вместе с оболочкой перехода.")
	user.forceMove(entry)
	qdel(holder)

	reset_pocket(pocket, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель снова уходит в изнанку.")
	var/turf/void_spot
	for(var/turf/candidate as anything in SSmapping.unused_turfs["[pocket.center.z]"])
		if(candidate.flags_1 & UNUSED_RESERVATION_TURF_1)
			void_spot = candidate
			break
	TEST_ASSERT_NOTNULL(void_spot, "На уровне резерва есть пустая клетка.")
	user.forceMove(void_spot)
	var/obj/item/pen/wall_pen = allocate(/obj/item/pen, wall)
	pocket.collapse("проверка")
	TEST_ASSERT_EQUAL(get_turf(user), entry, "Еретик из пустого резерва возвращается ко входу.")
	TEST_ASSERT_EQUAL(get_turf(wall_pen), entry, "Вещи со стен изнанки тоже выпадают у входа.")

/// Занятый вход выпускает на соседний пол, достижимый от входа и не под запретом телепортов, иначе в коридор станции.
/datum/unit_test/heretic_pocket/exit_fallback/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/user_mind = allocate_mind()
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/ritual_fixture/heretic = allocate(/datum/antagonist/heretic/ritual_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	heretic.test_return_turf = run_loc_floor_top_right
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	var/turf/open_side = get_step(entry, EAST)
	user.forceMove(locate(entry.x, entry.y + 3, entry.z))
	for(var/direction in GLOB.alldirs)
		if(direction != EAST)
			heretic_test_area(get_step(entry, direction), /area/unit_test_pocket_noteleport)

	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	allocate(/obj/structure/window/fulltile, entry)
	pocket.collapse("проверка")
	TEST_ASSERT_EQUAL(get_turf(user), open_side, "Занятый вход выпускает на соседний пол своей зоны.")
	TEST_ASSERT_EQUAL(get_turf(victim), open_side, "Цель выпадает рядом со входом.")

	reset_pocket(pocket, victim)
	user.forceMove(locate(entry.x, entry.y + 3, entry.z))
	victim.forceMove(locate(entry.x + 1, entry.y + 3, entry.z))
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель снова уходит в изнанку.")
	heretic_test_area(open_side, /area/unit_test_pocket_noteleport)
	pocket.collapse("проверка")
	TEST_ASSERT_EQUAL(get_turf(user), run_loc_floor_top_right, "Без доступного пола рядом еретик выходит в коридор станции.")

/// Новый вход застаёт комнату чистой: без газа, крови и рун прошлого раза.
/datum/unit_test/heretic_pocket/room_reset/Run()
	var/datum/antagonist/heretic/heretic = pocket_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	pocket.collapse("проверка")
	reset_pocket(pocket, victim)
	var/turf/open/floor = get_step(pocket.center, NORTH)
	floor.air.set_moles(GAS_PLASMA, 50)
	var/obj/effect/decal/cleanable/blood/stain = allocate(/obj/effect/decal/cleanable/blood, floor)
	var/obj/effect/eldritch/big/old_rune = allocate(/obj/effect/eldritch/big, get_step(pocket.center, EAST))
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель снова уходит в изнанку.")
	TEST_ASSERT_EQUAL(floor.air.get_moles(GAS_PLASMA), 0, "Плазма прошлого раза выветрилась.")
	TEST_ASSERT(floor.air.get_moles(GAS_O2) > 0, "В комнате снова обычный воздух.")
	TEST_ASSERT(QDELETED(stain), "Кровь прошлого раза стёрта.")
	TEST_ASSERT(QDELETED(old_rune), "Руна прошлого раза стёрта.")

/datum/antagonist/heretic/door_fixture
	var/answer
	var/list/offered
	var/rite_calls = 0
	var/prompt_timeout
	var/datum/callback/during_prompt

/datum/antagonist/heretic/door_fixture/Destroy()
	during_prompt = null
	return ..()

/datum/antagonist/heretic/door_fixture/heart_alert(mob/living/user, question, list/choices, timeout)
	offered = choices.Copy()
	prompt_timeout = timeout
	during_prompt?.Invoke()
	return answer

/datum/antagonist/heretic/door_fixture/begin_heart_rite(mob/living/user, mob/living/carbon/human/victim, obj/item/living_heart/heart)
	rite_calls++
	return TRUE

/datum/unit_test/proc/allocate_hunt_victim(datum/antagonist/heretic/heretic, turf/location)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, location)
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	heretic.set_hunt_target(soul)
	return victim

/// Сердце без дверей сразу проводит обряд, с дверью спрашивает и по выбору уводит цель в изнанку, с удержанием или без, как решила дверь; внутри изнанки дверей нет; вопрос закрывается сам, а ответ проверяет дверь, сердце в руке и цель рядом заново.
/datum/unit_test/heretic_pocket/heart_doors/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/user_mind = allocate_mind()
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/door_fixture/heretic = allocate(/datum/antagonist/heretic/door_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_bottom_left)
	TEST_ASSERT(heart.bind(user_mind), "Сердце привязано к еретику.")
	user.put_in_hands(heart)
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, entry)
	heretic.answer = HERETIC_POCKET_RITE_HERE

	heart.attack(victim, user)
	TEST_ASSERT_EQUAL(heretic.rite_calls, 1, "Без дверей касание сердцем сразу начинает обряд.")
	TEST_ASSERT_NULL(heretic.offered, "Без дверей сердце ничего не спрашивает.")

	var/datum/eldritch_knowledge/pocket_exit_probe/probe = allocate(/datum/eldritch_knowledge/pocket_exit_probe)
	probe.offers_door = TRUE
	heretic.researched_knowledge[probe.type] = probe
	heart.attack(victim, user)
	TEST_ASSERT_EQUAL(length(heretic.offered), 2, "Сердце предлагает обряд здесь и одну дверь.")
	TEST_ASSERT_EQUAL(heretic.offered[1], HERETIC_POCKET_RITE_HERE, "Первая кнопка - обряд на месте.")
	TEST_ASSERT_EQUAL(heretic.offered[2], "Увести: проба", "Кнопка двери подписана дверью знания.")
	TEST_ASSERT_EQUAL(heretic.rite_calls, 2, "Выбор «здесь» проводит обряд на месте.")
	TEST_ASSERT_NULL(heretic.pocket, "Обряд на месте не открывает изнанку.")

	heretic.answer = null
	TEST_ASSERT(!heretic.touch_hunt_target(user, victim, heart), "Закрытый вопрос ничего не делает.")
	TEST_ASSERT_EQUAL(heretic.rite_calls, 2, "Без ответа обряд не начинается.")
	TEST_ASSERT_NULL(heretic.pocket, "Без ответа цель не уводится.")

	heretic.answer = "Увести: проба"
	TEST_ASSERT(heretic.touch_hunt_target(user, victim, heart), "Выбор двери уводит цель.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	TEST_ASSERT_EQUAL(heretic.pocket.entry_turf, entry, "Вход изнанки - клетка цели.")
	TEST_ASSERT_NOTNULL(heretic.pocket.entry_hold, "Дверь без пометки держит цель на входе.")
	TEST_ASSERT(probe.checks >= 2, "Условие двери проверяется и до, и после входа: [probe.checks] раз.")
	TEST_ASSERT_EQUAL(heretic.rite_calls, 2, "Дверь не начинает обряд на месте.")
	TEST_ASSERT_EQUAL(length(heretic.pocket_doors(user, victim)), 0, "Из изнанки сердце дверей не предлагает.")
	heretic.offered = null
	heart.attack(victim, user)
	TEST_ASSERT_NULL(heretic.offered, "В изнанке сердце ничего не спрашивает.")
	TEST_ASSERT_EQUAL(heretic.rite_calls, 3, "В изнанке касание сердцем проводит обряд.")
	heretic.pocket.collapse("проверка")
	reset_pocket(heretic.pocket, victim)
	user.forceMove(run_loc_floor_bottom_left)
	victim.forceMove(entry)
	probe.door_hold = FALSE
	TEST_ASSERT(heretic.touch_hunt_target(user, victim, heart), "Дверь без удержания уводит цель.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель снова в изнанке.")
	TEST_ASSERT_NULL(heretic.pocket.entry_hold, "Дверь с hold = FALSE не держит цель на входе.")
	heretic.pocket.collapse("проверка")
	TEST_ASSERT_EQUAL(heretic.prompt_timeout, HERETIC_RITUAL_CHOICE_TIMEOUT, "Вопрос сердца закрывается сам через минуту.")

	reset_pocket(heretic.pocket, victim)
	user.forceMove(run_loc_floor_bottom_left)
	victim.forceMove(entry)
	heretic.during_prompt = CALLBACK(probe, TYPE_PROC_REF(/datum/eldritch_knowledge/pocket_exit_probe, close_door))
	TEST_ASSERT(!heretic.touch_hunt_target(user, victim, heart), "Дверь, закрывшаяся за время вопроса, никуда не уводит.")
	TEST_ASSERT(!heretic.pocket.active, "Изнанка не открылась.")
	probe.offers_door = TRUE
	heretic.during_prompt = CALLBACK(user, TYPE_PROC_REF(/mob, dropItemToGround), heart)
	TEST_ASSERT(!heretic.touch_hunt_target(user, victim, heart), "Сердце, выпавшее из руки за время вопроса, дверь не открывает.")
	TEST_ASSERT(!heretic.pocket.active, "Изнанка не открылась без сердца в руке.")
	user.put_in_hands(heart)
	heretic.answer = HERETIC_POCKET_RITE_HERE
	heretic.during_prompt = CALLBACK(victim, TYPE_PROC_REF(/atom/movable, forceMove), locate(entry.x + 2, entry.y, entry.z))
	TEST_ASSERT(!heretic.touch_hunt_target(user, victim, heart), "Цель, унесённая за время вопроса, не принимается на обряд здесь.")
	TEST_ASSERT_EQUAL(heretic.rite_calls, 3, "Обряд над унесённой целью не начался.")
	heretic.during_prompt = null
	victim.forceMove(entry)

	heretic.offered = null
	victim.death()
	heart.attack(victim, user)
	TEST_ASSERT_NULL(heretic.offered, "Мёртвую цель сердце не уводит.")
	TEST_ASSERT_EQUAL(heretic.rite_calls, 4, "Труп цели сердце сразу принимает на обряд.")

/// Общая передышка после другого захвата не держит изнанку, а своя минута изнанки держит.
/datum/unit_test/heretic_pocket/shared_floor/Run()
	var/datum/antagonist/heretic/heretic = pocket_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	heretic_capture_release(victim, "echo", 10 SECONDS)
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, "sand"), "другого захвата"), "Другие захваты ждут общую передышку.")
	TEST_ASSERT_NULL(heretic.pocket_pull_reason(user, victim, entry), "Изнанка не ждёт общую передышку.")
	heretic_capture_release(victim, HERETIC_POCKET_CAPTURE)
	TEST_ASSERT(findtext(heretic.pocket_pull_reason(user, victim, entry), "приходит в себя"), "Своя минута изнанки держит.")

/// Время, жезл и разрыв руками выносят еретика к своему выходу подальше от входа, цель - ко входу: ближайший из дальних, иначе самый дальний из близких, не клетка у входа; без выходов - туда, где еретик стоял, если это не у входа; при крите еретика оба у входа.
/datum/unit_test/heretic_pocket/forced_exit/Run()
	var/datum/antagonist/heretic/heretic = pocket_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/origin = get_turf(user)
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(entry, NORTH))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, crew)

	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	TEST_ASSERT_NULL(exit_label(heretic, origin), "Клетка у самого входа не отдельный выход.")
	pocket.on_timeout()
	TEST_ASSERT_EQUAL(get_turf(user), entry, "Без своих выходов еретик выпадает у входа.")
	TEST_ASSERT_EQUAL(get_turf(victim), entry, "Цель выпадает у входа.")

	var/turf/near = locate(entry.x + 2, entry.y + 1, entry.z)
	var/turf/far = locate(entry.x + 3, entry.y + 3, entry.z)
	var/datum/eldritch_knowledge/pocket_exit_probe/probe = allocate(/datum/eldritch_knowledge/pocket_exit_probe)
	probe.exits = list("Дальний" = far, "Ближний" = near, "У самого входа" = get_step(entry, EAST))
	heretic.researched_knowledge[probe.type] = probe
	var/list/rules = list(
		list(2, near, "ближайший из дальних"),
		list(3, far, "единственный дальний"),
		list(HERETIC_POCKET_ESCAPE_DISTANCE, far, "без дальних - самый дальний из близких"),
	)
	for(var/list/rule as anything in rules)
		reset_pocket(pocket, victim)
		user.forceMove(origin)
		victim.forceMove(entry)
		TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель снова уходит в изнанку ([rule[3]]).")
		pocket.escape_distance = rule[1]
		pocket.on_timeout()
		TEST_ASSERT_EQUAL(get_turf(user), rule[2], "Еретика выносит к выходу: [rule[3]].")
	pocket.escape_distance = 3
	for(var/closer in list("время", "жезл", "руки"))
		reset_pocket(pocket, victim)
		user.forceMove(origin)
		victim.forceMove(entry)
		TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель снова уходит в изнанку ([closer]).")
		switch(closer)
			if("время")
				pocket.on_timeout()
			if("жезл")
				pocket.rift.attackby(rod, crew)
			if("руки")
				pocket.rift.tear_time = 1
				TEST_ASSERT(pocket.rift.tear(crew), "Экипаж рвёт разрыв руками.")
		TEST_ASSERT(!pocket.active, "Изнанка закрыта ([closer]).")
		TEST_ASSERT_EQUAL(get_turf(user), far, "Еретика выносит к выходу подальше от входа ([closer]).")
		TEST_ASSERT_EQUAL(get_turf(victim), entry, "Цель выпадает у входа ([closer]).")

	probe.exits = list()
	var/turf/stood = locate(entry.x + 2, entry.y + 2, entry.z)
	reset_pocket(pocket, victim)
	user.forceMove(stood)
	victim.forceMove(entry)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку, еретик тянул издалека.")
	TEST_ASSERT_NOTNULL(exit_label(heretic, stood), "Клетка, где еретик стоял, - выход из изнанки.")
	pocket.escape_distance = 2
	pocket.on_timeout()
	TEST_ASSERT_EQUAL(get_turf(user), stood, "Без выходов пути еретика выносит туда, где он стоял.")
	TEST_ASSERT_EQUAL(get_turf(victim), entry, "Цель выпадает у входа.")
	pocket.escape_distance = 3
	probe.exits = list("Дальний" = far, "Ближний" = near, "У самого входа" = get_step(entry, EAST))

	reset_pocket(pocket, victim)
	user.forceMove(origin)
	victim.forceMove(entry)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку перед критом.")
	user.set_stat(SOFT_CRIT)
	user.set_stat(CONSCIOUS)
	TEST_ASSERT(!pocket.active, "Крит еретика закрывает изнанку.")
	TEST_ASSERT_EQUAL(get_turf(user), entry, "При крите еретик выпадает у входа.")
	TEST_ASSERT_EQUAL(get_turf(victim), entry, "При крите цель выпадает у входа.")

/// Стоящую цель вход держит без срока, пока свой таймер не снимет удержание через заданное время: «Помощь» его не укорачивает, обряд сердцем успевает начаться, а снятое раньше срока или началом обряда удержание не оставляет на цели метки захвата; без удержания цель входит на ногах.
/datum/unit_test/heretic_pocket/entry_hold/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	previous_sacrificed = GLOB.heretic_sacrificed_minds.Copy()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/user_mind = allocate_mind()
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/ritual_fixture/heretic = allocate(/datum/antagonist/heretic/ritual_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	heretic.test_return_turf = run_loc_floor_top_right
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/datum/eldritch_knowledge/spell/basic/ritual = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	ritual.ritual_time = 1 SECONDS
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_bottom_left)
	TEST_ASSERT(heart.bind(user_mind), "Сердце привязано к еретику.")
	user.put_in_hands(heart)
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	TEST_ASSERT(!heretic.hunt_target_ready(victim), "Стоящая цель к обряду не готова.")

	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0, hold_on_entry = FALSE), "Цель без удержания уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	TEST_ASSERT_NULL(pocket.entry_hold, "Без удержания цель входит на ногах.")
	TEST_ASSERT(!victim.IsParalyzed(), "Без удержания цель может двигаться.")
	pocket.collapse("проверка")
	reset_pocket(pocket, victim)
	user.forceMove(run_loc_floor_bottom_left)
	victim.forceMove(entry)

	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель с удержанием уходит в изнанку.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Удержание входа - захват.")
	victim.SetParalyzed(0)
	TEST_ASSERT_NULL(pocket.entry_hold, "Снятый паралич снимает удержание входа.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Снятое раньше срока удержание не оставляет метку захвата.")
	TEST_ASSERT_NULL(pocket.entry_hold_timer, "Таймер удержания снят вместе с ним.")
	pocket.collapse("проверка")
	reset_pocket(pocket, victim)
	user.forceMove(run_loc_floor_bottom_left)
	victim.forceMove(entry)

	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель с удержанием уходит в изнанку перед обрядом.")
	TEST_ASSERT_NOTNULL(pocket.entry_hold, "Вход держит цель до обряда.")
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING)
	TEST_ASSERT_NULL(pocket.entry_hold, "Начало обряда снимает удержание входа.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Начало обряда снимает метку захвата входа.")
	TEST_ASSERT_NULL(pocket.entry_hold_timer, "Таймер удержания снят вместе с ним.")
	pocket.collapse("проверка")
	reset_pocket(pocket, victim)
	user.forceMove(run_loc_floor_bottom_left)
	victim.forceMove(entry)

	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель снова уходит в изнанку с удержанием.")
	TEST_ASSERT_NOTNULL(pocket.entry_hold, "Вход держит цель.")
	TEST_ASSERT(findtext(jointext(pocket.inner_rift.examine(victim), " "), "держать вас на месте"), "Цель при осмотре разрыва узнаёт об удержании.")
	TEST_ASSERT_EQUAL(pocket.entry_hold.duration, -1, "Удержание без срока: его не укоротить.")
	var/datum/timedevent/release = SStimer.timer_id_dict[pocket.entry_hold_timer]
	TEST_ASSERT(abs(release?.timeToRun - world.time - HERETIC_POCKET_ENTRY_HOLD) < 1, "Удержание снимается через [HERETIC_POCKET_ENTRY_HOLD / (1 SECONDS)] с: [release?.timeToRun - world.time] дс.")
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human, get_step(victim, EAST))
	victim.help_shake_act(helper)
	TEST_ASSERT(victim.IsParalyzed() && !QDELETED(pocket.entry_hold), "«Помощь» не снимает удержание входа.")
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Удержанная цель готова к обряду.")
	qdel(helper)
	TEST_ASSERT(heretic.begin_heart_rite(user, victim, heart), "Обряд сердцем над удержанной целью проходит.")
	TEST_ASSERT_EQUAL(heretic.total_sacrifices, 1, "Обряд засчитан.")
	var/datum/heretic_mansus_visit/visit = GLOB.heretic_mansus_visits[victim.mind]
	TEST_ASSERT_NOTNULL(visit, "Жертва уходит в Мансус.")
	allocated += visit
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "После обряда и лечения Мансуса на жертве нет метки захвата.")
	TEST_ASSERT(pocket.leave(user, entry), "Еретик выходит ко входу.")
	TEST_ASSERT_NULL(pocket.entry_hold, "Закрытие снимает удержание.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "После выхода на жертве нет метки захвата.")
	visit.finish()

/datum/unit_test/heretic_pocket/door_grip
	var/grip_failure = "вопрос не задан"
	var/list/grip_ticks = list()

/datum/unit_test/heretic_pocket/door_grip/proc/inspect_grip(mob/living/carbon/human/victim)
	var/datum/status_effect/heretic_door_grip/grip = victim.has_status_effect(/datum/status_effect/heretic_door_grip)
	if(!grip)
		grip_failure = "прижатия нет"
		return
	if(!victim.IsParalyzed())
		grip_failure = "цель может двигаться"
		return
	if(abs(grip.duration - world.time - HERETIC_POCKET_DOOR_GRIP) > 1)
		grip_failure = "срок [grip.duration - world.time] дс вместо [HERETIC_POCKET_DOOR_GRIP]"
		return
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human, get_step(victim, NORTH))
	victim.help_shake_act(helper)
	qdel(helper)
	if(QDELETED(grip) || !victim.IsParalyzed())
		grip_failure = "«Помощь» подняла цель"
		return
	grip_failure = null

/datum/unit_test/heretic_pocket/door_grip/proc/record_grip(mob/living/victim)
	grip_ticks += !!victim.has_status_effect(/datum/status_effect/heretic_door_grip)
	return TRUE

/// Сердце прижимает цель, пока еретик выбирает дверь и тянет её сквозь завесу: «Помощь» не поднимает, растолкать и нулевой жезл снимают, закрытый вопрос отпускает, повтор только продлевает, дверь без прижатия не прижимает.
/datum/unit_test/heretic_pocket/door_grip/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/user_mind = allocate_mind()
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/door_fixture/heretic = allocate(/datum/antagonist/heretic/door_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_bottom_left)
	TEST_ASSERT(heart.bind(user_mind), "Сердце привязано к еретику.")
	user.put_in_hands(heart)
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, entry)
	var/datum/eldritch_knowledge/pocket_exit_probe/probe = allocate(/datum/eldritch_knowledge/pocket_exit_probe)
	probe.offers_door = TRUE
	heretic.researched_knowledge[probe.type] = probe

	heretic.answer = null
	heretic.during_prompt = CALLBACK(src, PROC_REF(inspect_grip), victim)
	TEST_ASSERT(!heretic.touch_hunt_target(user, victim, heart), "Закрытый вопрос ничего не делает.")
	TEST_ASSERT_NULL(grip_failure, "Пока открыт вопрос, сердце прижимает цель: [grip_failure].")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_door_grip), "Закрытый вопрос отпускает цель.")
	TEST_ASSERT(!victim.IsParalyzed(), "Отпущенная цель может двигаться.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Отпущенная цель без метки захвата.")
	heretic.during_prompt = null

	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, door_check = CALLBACK(src, PROC_REF(record_grip), victim)), "Дверь с каналом уводит цель.")
	TEST_ASSERT(length(grip_ticks) >= 3, "Условие двери проверено до, во время и после канала: [length(grip_ticks)] раз.")
	TEST_ASSERT(!grip_ticks[1], "До канала цель ещё не прижата.")
	for(var/index in 2 to length(grip_ticks))
		TEST_ASSERT(grip_ticks[index], "Весь канал цель прижата: проверка [index] из [length(grip_ticks)].")
	heretic.pocket.collapse("проверка")
	reset_pocket(heretic.pocket, victim)
	victim.remove_status_effect(/datum/status_effect/heretic_door_grip)
	user.forceMove(run_loc_floor_bottom_left)
	victim.forceMove(entry)

	grip_ticks.Cut()
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, door_check = CALLBACK(src, PROC_REF(record_grip), victim), grip = FALSE), "Дверь без прижатия уводит цель.")
	for(var/index in 1 to length(grip_ticks))
		TEST_ASSERT(!grip_ticks[index], "Дверь без прижатия цель не прижимает: проверка [index].")
	heretic.pocket.collapse("проверка")

	var/datum/status_effect/heretic_door_grip/grip = heretic_door_grip(victim, 1 SECONDS)
	TEST_ASSERT_NOTNULL(grip, "Прижатие наложено.")
	TEST_ASSERT_EQUAL(heretic_door_grip(victim, 3 SECONDS), grip, "Повторное прижатие продлевает то же.")
	TEST_ASSERT(abs(grip.duration - world.time - 3 SECONDS) < 1, "Прижатие продлено до 3 секунд.")
	TEST_ASSERT(victim.AmountParalyzed() >= 3 SECONDS - 1, "Паралич продлён вместе с ним: [victim.AmountParalyzed()] дс.")
	heretic_door_grip(victim, 1 SECONDS)
	TEST_ASSERT(abs(grip.duration - world.time - 3 SECONDS) < 1, "Короткий повтор не укорачивает прижатие.")
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, null)
	TEST_ASSERT(QDELETED(grip), "Растолкать - снять прижатие.")
	TEST_ASSERT(!victim.IsParalyzed(), "Растолканная цель может двигаться.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Снятое прижатие не оставляет метки захвата.")

	grip = heretic_door_grip(victim, HERETIC_POCKET_DOOR_GRIP)
	var/mob/living/carbon/human/chaplain = allocate(/mob/living/carbon/human, get_step(entry, NORTH))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, get_turf(chaplain))
	chaplain.put_in_hands(rod)
	victim.attackby(rod, chaplain)
	TEST_ASSERT(QDELETED(grip), "Нулевой жезл снимает прижатие.")
	TEST_ASSERT(!victim.IsParalyzed(), "После жезла цель может двигаться.")

/// Своё живое сердце с пола изнанки при закрытии уходит за завесу, чужие вещи выпадают у входа.
/datum/unit_test/heretic_pocket/stash/Run()
	var/datum/antagonist/heretic/heretic = pocket_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = pocket_victim(heretic, entry)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, pocket.center)
	TEST_ASSERT(heart.bind(user.mind), "Сердце привязано к еретику.")
	var/obj/item/living_heart/stray_heart = allocate(/obj/item/living_heart, pocket.center)
	var/obj/item/pen/pen = allocate(/obj/item/pen, pocket.center)
	pocket.on_timeout()
	TEST_ASSERT(heart in heretic.summon_items, "Своё сердце ушло за завесу.")
	TEST_ASSERT_NULL(heart.loc, "Своё сердце не лежит у входа.")
	TEST_ASSERT_EQUAL(get_turf(stray_heart), entry, "Непривязанное сердце выпадает у входа.")
	TEST_ASSERT_EQUAL(get_turf(pen), entry, "Прочие вещи выпадают у входа.")
	heretic.summon_items -= heart
