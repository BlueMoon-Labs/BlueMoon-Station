/datum/unit_test/proc/blood_brothers_sign_at(turf/spot, datum/team/brother_team/team, area_type)
	if(area_type)
		heretic_test_area(spot, area_type)
	var/obj/effect/decal/cleanable/blood/brother_sign/sign = new(spot)
	allocated += sign
	sign.bind_team(team)
	return sign

/datum/unit_test/proc/blood_brothers_floor(dx, dy)
	return locate(run_loc_floor_bottom_left.x + dx, run_loc_floor_bottom_left.y + dy, run_loc_floor_bottom_left.z)

/// Фото помнит, кто в кадре: спящий - без сознания, учёный в медотсеке - в чужом отделе
/datum/unit_test/blood_brothers_photo_subjects/Run()
	var/mob/living/carbon/human/photographer = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/sleeper = allocate(/mob/living/carbon/human, get_step(photographer, EAST))
	sleeper.mind_initialize()
	sleeper.mind.assigned_role = "Medical Doctor"
	var/turf/ward = get_step(photographer, NORTH)
	heretic_test_area(ward, /area/medical)
	var/mob/living/carbon/human/visitor = allocate(/mob/living/carbon/human, ward)
	visitor.mind_initialize()
	visitor.mind.assigned_role = "Scientist"
	sleeper.Sleeping(10 SECONDS)
	var/obj/item/camera/camera = allocate(/obj/item/camera)
	camera.can_customise = FALSE
	photographer.put_in_hands(camera)
	camera.captureimage(get_turf(photographer), photographer, null, 1, 1)
	var/obj/item/photo/photo = locate() in photographer.held_items
	TEST_ASSERT_NOTNULL(photo, "Фото напечатано")
	allocated += photo
	TEST_ASSERT(length(photo.picture.subjects_seen), "Фото запомнило людей в кадре")
	var/list/sleeper_state = photo.picture.subjects_seen[WEAKREF(sleeper.mind)]
	TEST_ASSERT_NOTNULL(sleeper_state, "Спящий в кадре запомнен")
	TEST_ASSERT(sleeper_state["unconscious"], "Спящий отмечен как без сознания")
	TEST_ASSERT(!sleeper_state["foreign_area"], "Вне отделов чужой зоны нет")
	var/list/visitor_state = photo.picture.subjects_seen[WEAKREF(visitor.mind)]
	TEST_ASSERT_NOTNULL(visitor_state, "Учёный в кадре запомнен")
	TEST_ASSERT(visitor_state["foreign_area"], "Учёный в медотсеке - в чужом отделе")
	TEST_ASSERT(!visitor_state["unconscious"], "Учёный в сознании")
	TEST_ASSERT(!visitor_state["restrained"], "Учёный не скован")
	visitor.mind.assigned_role = "Medical Doctor"
	photographer.dropItemToGround(photo)
	camera.captureimage(get_turf(photographer), photographer, null, 1, 1)
	var/obj/item/photo/second_photo = locate() in photographer.held_items
	TEST_ASSERT_NOTNULL(second_photo, "Второе фото напечатано")
	allocated += second_photo
	var/list/doctor_state = second_photo.picture.subjects_seen[WEAKREF(visitor.mind)]
	TEST_ASSERT(!doctor_state["foreign_area"], "Врач в медотсеке у себя")
	var/datum/picture/copy = photo.picture.Copy()
	allocated += copy
	TEST_ASSERT(length(copy.subjects_seen), "Копия фото помнит людей в кадре")
	var/list/copy_state = copy.subjects_seen[WEAKREF(sleeper.mind)]
	TEST_ASSERT(copy_state["unconscious"], "Копия фото помнит то же")

/// Знак братства держит команда; швабра смывает его, распад команды отвязывает
/datum/unit_test/blood_brothers_sign_registry/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/turf/spot = blood_brothers_floor(1, 0)
	var/obj/effect/decal/cleanable/blood/brother_sign/sign = blood_brothers_sign_at(spot, team, /area/medical)
	TEST_ASSERT(sign in team.signs, "Знак у команды")
	TEST_ASSERT_EQUAL(sign.department, "медицина", "Знак помнит отдел")
	var/obj/item/mop/mop = allocate(/obj/item/mop)
	mop.reagents.add_reagent(/datum/reagent/water, 10)
	mop.clean(spot)
	TEST_ASSERT(QDELETED(sign), "Швабра смывает знак")
	TEST_ASSERT(!(sign in team.signs), "Смытый знак снят с команды")
	var/datum/team/brother_team/doomed = allocate_brother_team(src)
	var/obj/effect/decal/cleanable/blood/brother_sign/orphan = blood_brothers_sign_at(spot, doomed)
	qdel(doomed)
	TEST_ASSERT_NULL(orphan.team, "Распад команды отвязывает знак")
	TEST_ASSERT(!QDELETED(orphan), "Сам знак остаётся на полу")

/// Кнопка знака приходит с клятвой Знак братства, рисунок забирает кровь и оставляет знак с ДНК брата
/datum/unit_test/blood_brothers_sign_action/Run()
	blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/antagonist/brother/brother = first.has_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT_NULL(brother.bond_actions[/datum/action/cooldown/blood_bond/brother_sign], "Без клятвы кнопки знака нет")
	var/datum/blood_oath/brother_sign/oath = new
	TEST_ASSERT(oath.prepare(team), "Знак братства готов")
	team.swear_oath(oath)
	var/datum/action/cooldown/blood_bond/brother_sign/action = brother.bond_actions[/datum/action/cooldown/blood_bond/brother_sign]
	TEST_ASSERT_NOTNULL(action, "Клятва дала кнопку знака")
	TEST_ASSERT_EQUAL(action.owner, first.current, "Кнопка у тела брата")
	var/mob/living/carbon/human/drawer = first.current
	var/turf/spot = get_turf(drawer)
	var/blood_before = drawer.blood_volume
	TEST_ASSERT(action.Trigger(), "Знак нарисован")
	var/obj/effect/decal/cleanable/blood/brother_sign/sign = locate() in spot
	TEST_ASSERT_NOTNULL(sign, "Знак лежит под братом")
	TEST_ASSERT(sign in team.signs, "Знак у команды")
	TEST_ASSERT_EQUAL(round(blood_before - drawer.blood_volume, 1), round(BROTHER_SIGN_BLOOD_COST, 1), "Знак забрал кровь")
	TEST_ASSERT_NOTNULL(sign.blood_DNA[drawer.dna.unique_enzymes], "На знаке ДНК брата")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/brother_sign_draw) in spot, "Набросок убран")
	TEST_ASSERT(!action.IsAvailable(silent = TRUE), "Кнопка на перезарядке")
	var/datum/antagonist/brother/second_brother = second.has_antag_datum(/datum/antagonist/brother)
	var/datum/action/cooldown/blood_bond/brother_sign/second_action = second_brother.bond_actions[/datum/action/cooldown/blood_bond/brother_sign]
	var/mob/living/carbon/human/second_body = second.current
	second_body.forceMove(spot)
	TEST_ASSERT(!second_action.Trigger(), "Второй знак на той же клетке не рисуется")
	var/turf/pale_spot = blood_brothers_floor(2, 2)
	second_body.forceMove(pale_spot)
	second_body.blood_volume = BLOOD_VOLUME_SAFE
	TEST_ASSERT(!second_action.Trigger(), "При кровопотере знак не рисуется")
	TEST_ASSERT_NULL(locate(/obj/effect/decal/cleanable/blood/brother_sign) in pale_spot, "Знака нет")
	TEST_ASSERT_EQUAL(second_body.blood_volume, BLOOD_VOLUME_SAFE, "Кровь не потрачена")

/// Знак братства: знак в отделе, знаки в трёх чужих отделах сразу, знак в перме; лобби и свой отдел для второго шага не в счёт
/datum/unit_test/blood_brothers_oath_brother_sign/Run()
	blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/first = team.members[1]
	first.assigned_role = "Medical Doctor"
	var/datum/blood_oath/brother_sign/oath = new
	TEST_ASSERT(oath.prepare(team), "Знак братства готов")
	team.swear_oath(oath)
	TEST_ASSERT(istext(team.try_seal(first)), "Без знаков печати нет")
	var/obj/effect/decal/cleanable/blood/brother_sign/lobby_sign = blood_brothers_sign_at(blood_brothers_floor(1, 0), team, /area/medical/medbay/lobby)
	TEST_ASSERT(istext(team.try_seal(first)), "Лобби медотсека - не отдел")
	TEST_ASSERT(findtext(oath.sign_note(lobby_sign), "не отдел"), "Рисующему сказано, что лобби не в счёт: [oath.sign_note(lobby_sign)]")
	var/obj/effect/decal/cleanable/blood/brother_sign/ward_sign = blood_brothers_sign_at(blood_brothers_floor(2, 0), team, /area/medical)
	TEST_ASSERT(team.try_seal(first) == TRUE, "Знак в своём медотсеке скрепляет первый шаг")
	TEST_ASSERT(findtext(oath.sign_note(ward_sign), "ваш"), "Рисующему сказано, что отдел свой: [oath.sign_note(ward_sign)]")
	var/obj/effect/decal/cleanable/blood/brother_sign/lab_sign = blood_brothers_sign_at(blood_brothers_floor(3, 0), team, /area/science)
	TEST_ASSERT(findtext(oath.sign_note(lab_sign), "«наука»"), "Знак в чужом отделе назван: [oath.sign_note(lab_sign)]")
	blood_brothers_sign_at(blood_brothers_floor(4, 0), team, /area/engineering)
	var/datum/blood_oath_step/spread_step = oath.steps[2]
	var/spread_condition = spread_step.condition_text(first.current)
	TEST_ASSERT(findtext(spread_condition, "2 из 3"), "Свой медотсек не в счёт: [spread_condition]")
	TEST_ASSERT(findtext(spread_condition, "свои не в счёт: медицина"), "Условие называет свой отдел: [spread_condition]")
	TEST_ASSERT(istext(team.try_seal(first)), "Двух чужих отделов мало")
	blood_brothers_sign_at(blood_brothers_floor(0, 1), team, /area/cargo/storage)
	TEST_ASSERT(findtext(spread_step.condition_text(first.current), "3 из 3"), "Условие считает отделы: [spread_step.condition_text(first.current)]")
	qdel(lab_sign)
	TEST_ASSERT(istext(team.try_seal(first)), "Смытый знак не считается")
	blood_brothers_sign_at(blood_brothers_floor(3, 1), team, /area/service/kitchen)
	TEST_ASSERT(team.try_seal(first) == TRUE, "Знаки в трёх чужих отделах скрепляют второй шаг")
	blood_brothers_sign_at(blood_brothers_floor(1, 1), team, /area/command/meeting_room)
	TEST_ASSERT(istext(team.try_seal(first)), "Зал совещаний не охраняется")
	var/obj/effect/decal/cleanable/blood/brother_sign/prison_sign = blood_brothers_sign_at(blood_brothers_floor(2, 1), team, /area/security/prison)
	TEST_ASSERT(findtext(oath.sign_note(prison_sign), "под носом у охраны"), "Знак в перме помечен охраняемым: [oath.sign_note(prison_sign)]")
	TEST_ASSERT(team.try_seal(first) == TRUE, "Знак в перме скрепляет третий шаг")
	TEST_ASSERT_EQUAL(team.bond_tier, BLOOD_BOND_TIER_MAX, "Три печати")

/// Компромат: фото цели в наручниках, её КПК, фото подброшено в кабинет её начальника
/datum/unit_test/blood_brothers_oath_compromat/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/officer = blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE, "Security Officer")
	var/datum/mind/victim = blood_brothers_target(ANTAG_OPT_IN_TEMPORARY, "Scientist")
	world_state.set_crew(team.members + officer + victim)
	var/turf/office = blood_brothers_floor(3, 3)
	heretic_test_area(office, /area/command/heads_quarters/rd)
	var/datum/blood_oath/compromat/oath = new
	TEST_ASSERT(oath.prepare(team), "Компромат готов")
	TEST_ASSERT_EQUAL(oath.target_mind, victim, "Охрана целью не выпадает")
	TEST_ASSERT_EQUAL(oath.office_type, /area/command/heads_quarters/rd, "Учёного сдают научному руководителю")
	var/datum/blood_oath_step/plant_step = oath.steps[3]
	TEST_ASSERT(findtext(plant_step.desc, "в кабинете научного руководителя"), "Кабинет в описании в предложном падеже: [plant_step.desc]")
	team.swear_oath(oath)
	var/datum/mind/first = team.members[1]
	var/mob/living/carbon/human/sealer = first.current
	var/mob/living/carbon/human/victim_body = victim.current
	victim_body.forceMove(get_step(sealer, EAST))
	var/obj/item/camera/camera = allocate(/obj/item/camera)
	camera.can_customise = FALSE
	sealer.put_in_hands(camera)
	camera.captureimage(get_turf(victim_body), sealer, null, 1, 1)
	var/obj/item/photo/free_photo = locate() in sealer.held_items
	TEST_ASSERT_NOTNULL(free_photo, "Фото напечатано")
	TEST_ASSERT(istext(team.try_seal(first)), "Фото свободной цели - не компромат")
	sealer.dropItemToGround(free_photo)
	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs)
	sealer.put_in_hands(cuffs)
	cuffs.apply_cuffs(victim_body, sealer)
	TEST_ASSERT(victim_body.handcuffed, "Цель в наручниках")
	camera.captureimage(get_turf(victim_body), sealer, null, 1, 1)
	var/obj/item/photo/evidence = locate() in sealer.held_items
	TEST_ASSERT_NOTNULL(evidence, "Снимок в наручниках напечатан")
	TEST_ASSERT(team.try_seal(first) == TRUE, "Фото цели в наручниках скрепляет первый шаг")
	TEST_ASSERT(istext(team.try_seal(first)), "Без документов цели второй шаг не скрепить")
	sealer.dropItemToGround(camera)
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda)
	pda.saved_identification = victim.name
	sealer.put_in_hands(pda)
	TEST_ASSERT(team.try_seal(first) == TRUE, "КПК цели скрепляет второй шаг")
	TEST_ASSERT(istext(team.try_seal(first)), "Фото в руке - ещё не подброшено")
	sealer.transferItemToLoc(evidence, office)
	TEST_ASSERT(team.try_seal(first) == TRUE, "Фото в кабинете начальника скрепляет третий шаг")
	TEST_ASSERT_EQUAL(team.bond_tier, BLOOD_BOND_TIER_MAX, "Три печати")

/// Разлад - с Медиума, не в Лайте и не в Экстенде
/datum/unit_test/blood_brothers_oath_discord_modes/Run()
	blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/blood_oath/discord/oath = allocate(/datum/blood_oath/discord)
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	TEST_ASSERT(!oath.available(team), "В Лайте Разлада нет")
	GLOB.round_type = ROUNDTYPE_EXTENDED
	TEST_ASSERT(!oath.available(team), "В Экстенде Разлада нет")
	GLOB.round_type = ROUNDTYPE_DYNAMIC_MEDIUM
	TEST_ASSERT(oath.available(team), "В Медиуме Разлад есть")

/// Угон - только в Харде с насилием; клятва даёт братьям взлом шаттла
/datum/unit_test/blood_brothers_oath_hijack/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/blood_oath/hijack/oath = new
	GLOB.round_type = ROUNDTYPE_DYNAMIC_MEDIUM
	TEST_ASSERT(!oath.available(team), "В Медиуме Угона нет")
	world_state.set_hard_round(src)
	TEST_ASSERT(oath.available(team), "В Харде Угон есть")
	var/datum/mind/first = team.members[1]
	TEST_ASSERT(!first.get_hijack_speed(), "До клятвы брат шаттл не взломает")
	TEST_ASSERT(oath.prepare(team), "Угон подобрал ценности")
	TEST_ASSERT_EQUAL(length(oath.steps), 3, "Три шага")
	team.swear_oath(oath)
	TEST_ASSERT_EQUAL(first.get_hijack_speed(), BROTHER_HIJACK_SPEED, "Клятва Угона даёт взлом шаттла")
	TEST_ASSERT(!oath.finale_extra_complete(), "Шаттл не угнан")
	var/datum/objective/blood_oath/oath_objective = locate() in team.objectives
	TEST_ASSERT(findtext(oath_objective.explanation_text, oath.finale_extra_text()), "Угон шаттла в тексте цели")
	var/mob/living/carbon/human/sealer = first.current
	for(var/step_index in 1 to 2)
		var/datum/blood_oath_step/heist_item/item_step = oath.steps[step_index]
		sealer.put_in_hands(allocate(item_step.item_type))
		TEST_ASSERT(team.try_seal(first) == TRUE, "Ценность [step_index] скреплена")
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_MAINT_TUNNELS)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	sealer.equip_to_slot_or_del(bag, ITEM_SLOT_BACK)
	card.forceMove(bag)
	TEST_ASSERT(istext(team.try_seal(first)), "Карта без мостика не годится")
	card.access += ACCESS_HEADS
	TEST_ASSERT(team.try_seal(first) == TRUE, "Карта с доступом на мостик в сумке скрепляет третий шаг")

/// Разлад: обесточенный щиток отдела, разобранная ключевая машина, её плата у брата
/datum/unit_test/blood_brothers_oath_discord/Run()
	blood_brothers_oath_world()
	GLOB.round_type = ROUNDTYPE_DYNAMIC_MEDIUM
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/turf/bay = blood_brothers_floor(2, 2)
	var/turf/console_spot = blood_brothers_floor(3, 2)
	heretic_test_area(bay, /area/cargo/storage)
	heretic_test_area(console_spot, /area/cargo/storage)
	var/obj/machinery/power/apc/apc = allocate(/obj/machinery/power/apc, bay)
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo, console_spot)
	var/datum/blood_oath/discord/oath = new
	TEST_ASSERT(oath.prepare(team), "Разлад нашёл отдел")
	TEST_ASSERT("снабжение" in oath.discord_candidates(), "Отдел с консолью снабжения годится")
	oath.set_department("снабжение")
	team.swear_oath(oath)
	TEST_ASSERT_EQUAL(oath.department, "снабжение", "Клятва на снабжение")
	var/datum/mind/first = team.members[1]
	TEST_ASSERT(istext(team.try_seal(first)), "Щитки отдела под током")
	apc.toggle_breaker(first.current)
	TEST_ASSERT(!apc.operating, "Рубильник выключен")
	TEST_ASSERT(team.try_seal(first) == TRUE, "Обесточенный щиток скрепляет первый шаг")
	TEST_ASSERT(istext(team.try_seal(first)), "Консоль снабжения цела")
	var/obj/item/circuitboard/console_board = console.circuit
	console.deconstruct(TRUE)
	var/obj/machinery/computer/cargo/rebuilt = allocate(/obj/machinery/computer/cargo, console_spot)
	TEST_ASSERT(istext(team.try_seal(first)), "На месте разобранной консоли стоит новая - не в счёт")
	qdel(rebuilt)
	TEST_ASSERT(team.try_seal(first) == TRUE, "Разобранная консоль скрепляет второй шаг")
	first.current.put_in_hands(allocate(/obj/item/circuitboard/computer/cargo/request))
	TEST_ASSERT(istext(team.try_seal(first)), "Плата консоли заказов не та")
	first.current.put_in_hands(allocate(/obj/item/circuitboard/computer/cargo))
	TEST_ASSERT(istext(team.try_seal(first)), "Новая плата консоли снабжения - не та самая")
	TEST_ASSERT(!QDELETED(console_board), "Плата пережила разбор")
	var/obj/structure/frame/computer/frame = locate() in console_spot
	TEST_ASSERT_NOTNULL(frame, "От консоли остался каркас")
	allocated += frame
	frame.circuit = null
	allocated += console_board
	first.current.drop_all_held_items()
	first.current.put_in_hands(console_board)
	TEST_ASSERT(team.try_seal(first) == TRUE, "Плата той самой консоли у брата скрепляет третий шаг")
	TEST_ASSERT_EQUAL(team.bond_tier, BLOOD_BOND_TIER_MAX, "Три печати")
