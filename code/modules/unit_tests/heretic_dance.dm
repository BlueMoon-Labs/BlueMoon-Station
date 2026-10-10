/datum/unit_test/proc/allocate_dance_heretic(turf/location)
	var/datum/antagonist/heretic/heretic = allocate_heretic(location)
	heretic.research_knowledge(/datum/eldritch_knowledge/base_dance, heretic.owner.current)
	return heretic

/datum/unit_test/proc/allocate_dance_victim(turf/location)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, location || run_loc_floor_bottom_left)
	victim.mind_initialize()
	return victim

/// Ставит часы так, чтобы сейчас была доля номер index со смещением offset в децисекундах.
/datum/unit_test/proc/set_dance_beat(datum/eldritch_knowledge/base_dance/dance, index, offset = 0)
	dance.beat_origin = world.time - index * dance.beat_ds - offset
	dance.sync_bar()
	dance.lag_grace_until = -1

/datum/unit_test/proc/start_dance_music(datum/eldritch_knowledge/base_dance/dance)
	dance.last_combat_at = world.time

/// Точность по доле: точно, в долю, мимо и сильная доля такта.
/datum/unit_test/heretic_dance_timing/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	TEST_ASSERT_EQUAL(dance.style_id, HERETIC_DANCE_STYLE_WALTZ, "Путь начинается с Вальса.")
	set_dance_beat(dance, 3)
	TEST_ASSERT_EQUAL(dance.timing(user), HERETIC_DANCE_PERFECT, "Клик ровно в долю - точно.")
	TEST_ASSERT(dance.last_timing_strong, "Третья доля Вальса - начало такта.")
	set_dance_beat(dance, 1, 2)
	TEST_ASSERT_EQUAL(dance.timing(user), HERETIC_DANCE_ON_BEAT, "Две десятых секунды от доли - в долю.")
	TEST_ASSERT(!dance.last_timing_strong, "Вторая доля не сильная.")
	set_dance_beat(dance, 1, 4)
	TEST_ASSERT_EQUAL(dance.timing(user), HERETIC_DANCE_MISS, "Между долями - мимо.")

/// Такт копится от любого удара, больше - в долю; с 4 работает пассивка, вне боя он тает.
/datum/unit_test/heretic_dance_takt/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	dance.register_strike(user, victim, HERETIC_DANCE_MISS, FALSE)
	TEST_ASSERT_EQUAL(dance.combat_resource, 1, "Удар мимо доли всё равно даёт Такт.")
	dance.register_strike(user, victim, HERETIC_DANCE_MISS, FALSE)
	TEST_ASSERT_EQUAL(dance.combat_resource, 1, "Удары мимо доли дают Такт не чаще раза в секунду.")
	dance.register_strike(user, victim, HERETIC_DANCE_ON_BEAT, FALSE)
	TEST_ASSERT_EQUAL(dance.combat_resource, 3, "Удар в долю даёт 2 Такта.")
	TEST_ASSERT(!dance.passive_active, "До 4 Такта пассивка стиля молчит.")
	dance.register_strike(user, victim, HERETIC_DANCE_PERFECT, FALSE)
	TEST_ASSERT_EQUAL(dance.combat_resource, 6, "Точный удар даёт 3 Такта.")
	TEST_ASSERT(dance.passive_active && user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_waltz), "С 4 Такта Вальс ускоряет шаг.")
	dance.last_combat_at = world.time - HERETIC_DANCE_COMBAT_WINDOW - 1
	for(var/beat in 1 to 10)
		dance.decay_takt()
	TEST_ASSERT(dance.combat_resource < 6, "Вне боя Такт тает.")
	dance.combat_resource = 1
	dance.update_passive()
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_waltz), "Растаявший Такт снимает пассивку.")

/// Смена стиля в сильную долю сохраняет Такт и удваивает акцент; мимо - ждёт сильной доли, повторный выбор меняет сразу и делит Такт.
/datum/unit_test/heretic_dance_style_link/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	TEST_ASSERT(!dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO), "Танго закрыто до Хватки в долю.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	dance.combat_resource = 6
	dance.last_combat_at = world.time
	set_dance_beat(dance, 3)
	TEST_ASSERT(dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO), "Выученное Танго выбирается.")
	TEST_ASSERT_EQUAL(dance.combat_resource, 6, "Связка в сильную долю сохраняет Такт.")
	TEST_ASSERT(dance.link_bonus, "Связка удваивает следующий акцент.")
	TEST_ASSERT_EQUAL(dance.beat_ds, 7.5, "Часы идут в темпе Танго.")
	set_dance_beat(dance, 1, 3)
	TEST_ASSERT(dance.switch_style(user, HERETIC_DANCE_STYLE_WALTZ), "Вальс выбран мимо сильной доли.")
	TEST_ASSERT_EQUAL(dance.style_id, HERETIC_DANCE_STYLE_TANGO, "Выбранный мимо сильной доли стиль ждёт её.")
	TEST_ASSERT_EQUAL(dance.combat_resource, 6, "Ожидание сильной доли Такт не трогает.")
	set_dance_beat(dance, 1, 3)
	TEST_ASSERT(dance.switch_style(user, HERETIC_DANCE_STYLE_WALTZ), "Повторный выбор меняет стиль сразу.")
	TEST_ASSERT_EQUAL(dance.style_id, HERETIC_DANCE_STYLE_WALTZ, "Стиль сменился сразу.")
	TEST_ASSERT_EQUAL(dance.combat_resource, 3, "Смена сразу мимо сильной доли делит Такт пополам.")

/// Фигура Вальса из четырёх шагов в долю подхватывает соседа в вальс.
/datum/unit_test/heretic_dance_figure_lead/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/partner = allocate_dance_victim(get_step(user, WEST))
	start_dance_music(dance)
	var/index = 1
	for(var/direction in list(NORTH, EAST, SOUTH))
		set_dance_beat(dance, index++)
		dance.on_dance_step(user, direction)
	TEST_ASSERT(!partner.has_status_effect(/datum/status_effect/heretic_dance/lead), "Три шага ещё не фигура.")
	set_dance_beat(dance, index)
	dance.on_dance_step(user, WEST)
	TEST_ASSERT(partner.has_status_effect(/datum/status_effect/heretic_dance/lead), "Квадрат Вальса подхватывает соседа.")
	var/turf/before = get_turf(user)
	user.Move(get_step(user, EAST), EAST)
	TEST_ASSERT_EQUAL(get_turf(partner), before, "Ведомый заходит на прежнюю клетку ведущего.")
	TEST_ASSERT(dance.door_holds(user, partner), "Ведомый открывает дверь в изнанку.")

/// Пропущенная доля начинает рисунок заново, а брошенная на две доли фигура гаснет сама.
/datum/unit_test/heretic_dance_figure_reset/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	start_dance_music(dance)
	set_dance_beat(dance, 1)
	dance.on_dance_step(user, NORTH)
	set_dance_beat(dance, 3)
	dance.on_dance_step(user, EAST)
	TEST_ASSERT_EQUAL(length(dance.figure_steps), 1, "После пропущенной доли рисунок начат заново.")
	set_dance_beat(dance, 6)
	dance.on_beat()
	TEST_ASSERT_EQUAL(length(dance.figure_steps), 0, "Фигура без шагов две доли подряд погасла.")

/// Ходьба с зажатой клавишей: лишние шаги в долю и шаги между долями не рвут рисунок, в долю засчитывается шаг по рисунку.
/datum/unit_test/heretic_dance_figure_walk/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/partner = allocate_dance_victim(get_step(user, WEST))
	start_dance_music(dance)
	for(var/offset in list(-2, 0, 2, 4))
		set_dance_beat(dance, 1, offset)
		dance.on_dance_step(user, NORTH)
	TEST_ASSERT_EQUAL(dance.figure_progress(), 1, "Четыре шага вокруг одной доли - один шаг фигуры.")
	set_dance_beat(dance, 2, -4)
	dance.on_dance_step(user, EAST)
	set_dance_beat(dance, 2, -2)
	dance.on_dance_step(user, NORTH)
	TEST_ASSERT_EQUAL(dance.figure_progress(), 1, "Шаг не по рисунку в окне доли пока не засчитан как сбой.")
	set_dance_beat(dance, 2, 1)
	dance.on_dance_step(user, EAST)
	TEST_ASSERT_EQUAL(dance.figure_progress(), 2, "Поворот в нужную сторону внутри окна доли засчитан.")
	set_dance_beat(dance, 2, 2)
	dance.on_dance_step(user, SOUTH)
	TEST_ASSERT_EQUAL(dance.figure_progress(), 2, "Ранний поворот к следующему шагу не портит засчитанную долю.")
	set_dance_beat(dance, 3, -2)
	dance.on_dance_step(user, SOUTH)
	set_dance_beat(dance, 4, 2)
	dance.on_dance_step(user, WEST)
	TEST_ASSERT(partner.has_status_effect(/datum/status_effect/heretic_dance/lead), "Квадрат собран ходьбой с зажатой клавишей.")

/// Без музыки (ни боя, ни Такта) шаги не складываются в фигуру.
/datum/unit_test/heretic_dance_figure_silent/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	TEST_ASSERT(dance.music_silent(), "Без боя и Такта музыка молчит.")
	set_dance_beat(dance, 1)
	dance.on_dance_step(user, NORTH)
	TEST_ASSERT_EQUAL(length(dance.figure_steps), 0, "Шаг в тишине не начинает фигуру.")
	dance.combat_resource = 1
	TEST_ASSERT(!dance.music_silent(), "С Тактом музыка звучит.")
	set_dance_beat(dance, 2)
	dance.on_dance_step(user, NORTH)
	TEST_ASSERT_EQUAL(length(dance.figure_steps), 1, "Под музыку шаг начинает фигуру.")

/// Хватка в «Помощи» заражает человека; дефибриллятор, святая вода, сон и жезл лечат, заражённых не больше шести.
/datum/unit_test/heretic_dance_earworm/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	user.a_intent = INTENT_HELP
	dance.on_mansus_grasp(victim, user, TRUE)
	var/datum/status_effect/heretic_dance_earworm/earworm = victim.has_status_effect(/datum/status_effect/heretic_dance_earworm)
	TEST_ASSERT_NOTNULL(earworm, "Хватка в «Помощи» заражает человека.")
	SEND_SIGNAL(victim, COMSIG_LIVING_ELECTROCUTE_ACT, 10)
	TEST_ASSERT(QDELETED(earworm), "Разряд тока лечит навязчивый такт.")
	dance.infect(user, victim)
	earworm = victim.has_status_effect(/datum/status_effect/heretic_dance_earworm)
	victim.reagents.add_reagent(/datum/reagent/water/holywater, 5)
	earworm.tick()
	TEST_ASSERT(QDELETED(earworm), "Святая вода лечит навязчивый такт.")
	victim.reagents.clear_reagents()
	dance.infect(user, victim)
	earworm = victim.has_status_effect(/datum/status_effect/heretic_dance_earworm)
	victim.SetSleeping(30 SECONDS)
	for(var/tick in 1 to 5)
		earworm.tick()
	TEST_ASSERT(QDELETED(earworm), "Десять секунд сна лечат навязчивый такт.")
	victim.SetSleeping(0)
	var/list/infected = list()
	for(var/count in 1 to HERETIC_DANCE_EARWORM_LIMIT + 1)
		var/mob/living/carbon/human/extra = allocate_dance_victim()
		dance.infect(user, extra)
		infected += extra
	TEST_ASSERT_EQUAL(length(dance.earworms), HERETIC_DANCE_EARWORM_LIMIT, "Заражённых не больше шести.")
	var/mob/living/carbon/human/first = infected[1]
	TEST_ASSERT(!first.has_status_effect(/datum/status_effect/heretic_dance_earworm), "Седьмое заражение вытесняет самое старое.")

/// Схема шагов идёт в дело, заражает прошедших, блёкнет после трёх и стирается шваброй; к ней ведёт выход изнанки.
/datum/unit_test/heretic_dance_diagram/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/turf/spot = get_step(user, EAST)
	user.a_intent = INTENT_HELP
	var/progress = heretic.deed.progress
	TEST_ASSERT(dance.on_mansus_grasp(spot, user, TRUE), "Хватка в «Помощи» по полу рисует схему.")
	var/obj/effect/heretic_dance_diagram/diagram = locate() in spot
	TEST_ASSERT_NOTNULL(diagram, "Схема лежит на полу.")
	TEST_ASSERT(heretic.deed.progress > progress || heretic.deed.tier > 0, "Новый отдел продвигает дело.")
	TEST_ASSERT(length(dance.pocket_exits(user)), "Схема - выход из изнанки.")
	for(var/count in 1 to HERETIC_DANCE_DIAGRAM_CHARGES)
		var/mob/living/carbon/human/walker = allocate_dance_victim(get_step(spot, NORTH))
		walker.forceMove(spot)
		TEST_ASSERT(walker.has_status_effect(/datum/status_effect/heretic_dance_earworm), "Прошедший по схеме подхватывает мелодию.")
	TEST_ASSERT(QDELETED(diagram), "После трёх заражений схема блёкнет.")
	TEST_ASSERT(dance.draw_diagram(user, spot), "На месте поблёкшей можно нарисовать новую.")
	diagram = locate() in spot
	SEND_SIGNAL(diagram, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
	TEST_ASSERT(QDELETED(diagram), "Швабра стирает схему.")

/// Слух: наушники-заглушки и глухота закрывают от музыки, шлем - нет.
/datum/unit_test/heretic_dance_hearing/Run()
	var/mob/living/carbon/human/listener = allocate_dance_victim()
	TEST_ASSERT(heretic_dance_can_hear(listener), "Обычный человек слышит музыку.")
	var/obj/item/clothing/head/helmet/sec/helmet = allocate(/obj/item/clothing/head/helmet/sec)
	listener.equip_to_slot_or_del(helmet, ITEM_SLOT_HEAD)
	TEST_ASSERT(heretic_dance_can_hear(listener), "Шлем СБ музыку не глушит.")
	var/obj/item/clothing/ears/earmuffs/muffs = allocate(/obj/item/clothing/ears/earmuffs)
	listener.equip_to_slot_or_del(muffs, ITEM_SLOT_EARS_LEFT)
	TEST_ASSERT(!heretic_dance_can_hear(listener), "Наушники-заглушки глушат музыку.")
	listener.dropItemToGround(muffs)
	ADD_TRAIT(listener, TRAIT_DEAF, "test")
	TEST_ASSERT(!heretic_dance_can_hear(listener), "Глухой музыку не слышит.")

/// Танго-приглашение рывком приводит заражённого, партнёр открывает дверь; заглушки и чужая хватка срывают.
/datum/unit_test/heretic_dance_invite/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_invite)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(get_step(user, EAST), EAST))
	TEST_ASSERT_NOTNULL(dance.invite_block_reason(user, victim), "Незаражённого не пригласить.")
	dance.infect(user, victim)
	set_dance_beat(dance, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO)
	TEST_ASSERT(dance.invite(user, victim), "Заражённого в 2 клетках можно пригласить.")
	var/datum/status_effect/heretic_dance/invited/invite = victim.has_status_effect(/datum/status_effect/heretic_dance/invited)
	TEST_ASSERT_NOTNULL(invite, "Приглашение держит цель.")
	invite.on_dance_beat(dance, 1, FALSE)
	TEST_ASSERT(get_dist(user, victim) > 1, "Первая доля Танго - только телеграф.")
	invite.on_dance_beat(dance, 2, FALSE)
	TEST_ASSERT(get_dist(user, victim) <= 1, "Танго рывком приводит цель вплотную.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_dance/partner), "Дошедшая цель - партнёр.")
	TEST_ASSERT(dance.door_holds(user, victim), "Партнёр открывает дверь в изнанку.")
	var/mob/living/carbon/human/muffled = allocate_dance_victim(get_step(user, NORTH))
	dance.infect(user, muffled)
	var/obj/item/clothing/ears/earmuffs/muffs = allocate(/obj/item/clothing/ears/earmuffs)
	muffled.equip_to_slot_or_del(muffs, ITEM_SLOT_EARS_LEFT)
	TEST_ASSERT_NOTNULL(dance.invite_block_reason(user, muffled), "Заглушки закрывают от Приглашения.")

/// Срыв приглашения чужой хваткой на телеграфе возвращает перезарядку.
/datum/unit_test/heretic_dance_invite_break/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_invite)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(get_step(user, EAST), EAST))
	var/mob/living/carbon/human/helper = allocate_dance_victim(get_step(victim, NORTH))
	dance.infect(user, victim)
	TEST_ASSERT(dance.invite(user, victim), "Приглашение начинается.")
	var/datum/status_effect/heretic_dance/invited/invite = victim.has_status_effect(/datum/status_effect/heretic_dance/invited)
	helper.start_pulling(victim)
	TEST_ASSERT_NOTNULL(invite.hold_reason(), "Чужая хватка держит цель.")
	invite.on_dance_beat(dance, 1, FALSE)
	TEST_ASSERT(QDELETED(invite), "Удержанная цель выходит из танца.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_capture_immunity) == null, "Несостоявшийся захват не даёт невосприимчивости.")

/// Маскарад надевает одну маску на еретика и заражённых рядом; попадание разбивает маску.
/datum/unit_test/heretic_dance_masquerade/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_masquerade)
	var/mob/living/carbon/human/dancer = allocate_dance_victim(get_step(user, EAST))
	dance.infect(user, dancer)
	TEST_ASSERT(dance.start_masquerade(user), "Маскарад начинается.")
	TEST_ASSERT_EQUAL(user.name_override, "танцор в маске", "Имя еретика скрыто.")
	TEST_ASSERT(dancer.has_status_effect(/datum/status_effect/heretic_dance/masked), "Заражённый рядом тоже под маской.")
	TEST_ASSERT_EQUAL(dancer.name_override, "танцор в маске", "Имя заражённого скрыто.")
	TEST_ASSERT(!dance.start_masquerade(user), "Второй маскарад поверх первого не начинается.")
	dancer.apply_damage(5, BRUTE)
	TEST_ASSERT(!dancer.has_status_effect(/datum/status_effect/heretic_dance/masked), "Попадание разбивает маску.")
	TEST_ASSERT_NULL(dancer.name_override, "Разбитая маска возвращает имя.")
	user.remove_status_effect(/datum/status_effect/heretic_dance/masquerade)
	TEST_ASSERT_NULL(user.name_override, "Конец маскарада возвращает имя еретику.")

/// Колокол за 4 Такта тянет стоящих соседей в хоровод, лежачих - нет; втянутые повторяют шаги и выматываются.
/datum/unit_test/heretic_dance_bell/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_bell)
	var/mob/living/carbon/human/stander = allocate_dance_victim(get_step(user, NORTH))
	var/mob/living/carbon/human/lier = allocate_dance_victim(get_step(user, SOUTH))
	lier.set_resting(TRUE, TRUE)
	dance.combat_resource = 3
	TEST_ASSERT(!dance.ring_bell(user), "Без 4 Такта колокол не звонит.")
	dance.combat_resource = 4
	TEST_ASSERT(dance.ring_bell(user), "Колокол звонит за 4 Такта.")
	TEST_ASSERT_EQUAL(dance.combat_resource, 0, "Колокол тратит 4 Такта.")
	TEST_ASSERT(stander.has_status_effect(/datum/status_effect/heretic_dance/horovod), "Стоящий втянут в хоровод.")
	TEST_ASSERT(!lier.has_status_effect(/datum/status_effect/heretic_dance/horovod), "Лежачий не пляшет.")
	var/turf/expected = get_step(stander, EAST)
	user.Move(get_step(user, EAST), EAST)
	TEST_ASSERT(wait_for_var(stander, NAMEOF(stander, loc), expected), "Втянутый повторяет шаг еретика.")
	TEST_ASSERT_EQUAL(stander.getStaminaLoss(), HERETIC_DANCE_HOROVOD_STAMINA, "Каждый шаг хоровода выматывает.")

/// Тарантелла: пять укусов срывают цель в неконтролируемую пляску.
/datum/unit_test/heretic_dance_tarantism/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	for(var/bite in 1 to 4)
		victim.apply_status_effect(/datum/status_effect/heretic_dance/tarantism, dance)
	var/datum/status_effect/heretic_dance/tarantism/stacks = victim.has_status_effect(/datum/status_effect/heretic_dance/tarantism)
	TEST_ASSERT_EQUAL(stacks?.stacks, 4, "Укусы копят тарантизм.")
	stacks.on_dance_beat(dance, 1, FALSE)
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 0, "Слабая доля не выматывает.")
	stacks.on_dance_beat(dance, 0, TRUE)
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 16, "Сильная доля выматывает по 4 за стак.")
	victim.apply_status_effect(/datum/status_effect/heretic_dance/tarantism, dance)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_dance/frenzy), "Пятый укус срывает в пляску.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_dance/tarantism), "Сорвавшийся в пляску сбрасывает стаки.")

/// Барабан в долю отыгрывает ослабленный акцент стиля по заражённым; не чаще раза в 4 доли.
/datum/unit_test/heretic_dance_drum/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_drum)
	var/obj/item/heretic_path_relic/dance/drum = allocate(/obj/item/heretic_path_relic/dance, get_turf(user))
	drum.creator = WEAKREF(heretic.owner)
	drum.knowledge_ref = WEAKREF(heretic.get_knowledge(/datum/eldritch_knowledge/spell/dance_drum))
	TEST_ASSERT(user.put_in_hands(drum), "Барабан берётся в руку.")
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(get_step(user, EAST), EAST))
	dance.infect(user, victim)
	set_dance_beat(dance, 1, 4)
	TEST_ASSERT(drum.beat(user), "Барабан бьёт.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 5, "Вне доли барабан лишь выматывает.")
	TEST_ASSERT(!drum.beat(user), "Барабан ждёт 4 доли.")
	drum.ready_beat = 0
	set_dance_beat(dance, 2)
	victim.confused = 0
	TEST_ASSERT(drum.beat(user), "Барабан в долю бьёт снова.")
	TEST_ASSERT(victim.confused > 0, "Ослабленный акцент Вальса путает заражённого.")

/// Сердце не останавливается: с 4 Такта сбивание с ног короче.
/datum/unit_test/heretic_dance_heart/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_heart)
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_STABLEHEART), "Сердце еретика не встаёт.")
	user.Knockdown(4 SECONDS)
	TEST_ASSERT(user.AmountKnockdown() > 3.9 SECONDS, "Без Такта сбивание полное.")
	user.SetKnockdown(0)
	dance.combat_resource = HERETIC_DANCE_PASSIVE_TAKT
	user.Knockdown(4 SECONDS)
	TEST_ASSERT(user.AmountKnockdown() <= 3 SECONDS + 1, "С 4 Такта сбивание короче на четверть.")

/// Болеро поднимает ступень со временем, фальшивая нота сбивает её и глушит музыку, но не чаще раза в 15 секунд.
/datum/unit_test/heretic_dance_bolero/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	dance.start_bolero()
	TEST_ASSERT(dance.bolero_active(), "Болеро играет.")
	dance.bolero_next_at = world.time
	dance.bolero_beat(FALSE)
	TEST_ASSERT_EQUAL(dance.bolero_stage, 1, "Ступень растёт со временем.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_waltz), "Первая ступень навсегда даёт пассивку Вальса.")
	heretic_dance_false_note(get_turf(user))
	TEST_ASSERT_EQUAL(dance.bolero_stage, 0, "Фальшивая нота сбивает ступень.")
	TEST_ASSERT(!dance.bolero_active(), "Фальшивая нота глушит Болеро.")
	dance.bolero_silent_until = 0
	dance.bolero_next_at = world.time
	dance.bolero_beat(FALSE)
	heretic_dance_false_note(get_turf(user))
	TEST_ASSERT_EQUAL(dance.bolero_stage, 1, "Вторая нота подряд Болеро не сбивает.")
	dance.stop_bolero()
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_waltz), "Конец Болеро снимает его пассивки.")

/// Связка в бою даёт вход стиля, три разных стиля за 20 секунд - Попурри; пассивка стиля включает ауру, значок показывает стиль.
/datum/unit_test/heretic_dance_entrances/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_drum)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	var/datum/status_effect/heretic_dance_style/status = user.has_status_effect(/datum/status_effect/heretic_dance_style)
	TEST_ASSERT_NOTNULL(status, "Значок стиля появляется с путём.")
	dance.combat_resource = 6
	dance.update_passive()
	TEST_ASSERT_NOTNULL(dance.aura, "Пассивка стиля включает ауру.")
	dance.last_combat_at = world.time
	set_dance_beat(dance, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO)
	TEST_ASSERT(dance.entrance_strike_until >= world.time, "Вход в Танго усиливает следующий удар.")
	TEST_ASSERT_EQUAL(status.linked_alert.icon_state, "dance_style_tango", "Значок показывает Танго.")
	dance.last_combat_at = world.time
	set_dance_beat(dance, 4)
	dance.switch_style(user, HERETIC_DANCE_STYLE_WALTZ)
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_dance_glide), "Вход в Вальс ускоряет.")
	dance.last_combat_at = world.time
	set_dance_beat(dance, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TARANTELLA)
	var/datum/status_effect/heretic_dance/tarantism/bite = victim.has_status_effect(/datum/status_effect/heretic_dance/tarantism)
	TEST_ASSERT_EQUAL(bite?.stacks, 2, "Третий стиль за 20 секунд - Попурри: вход Тарантеллы вдвойне.")
	dance.last_combat_at = -INFINITY
	set_dance_beat(dance, 6)
	dance.switch_style(user, HERETIC_DANCE_STYLE_WALTZ)
	user.remove_status_effect(/datum/status_effect/heretic_dance_glide)
	set_dance_beat(dance, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO)
	TEST_ASSERT(!user.has_status_effect(/datum/status_effect/heretic_dance_glide), "Вне боя входов нет.")

/// Стиль, выбранный мимо сильной доли, вступает на следующей сильной доле без потери Такта и без удвоения акцента.
/datum/unit_test/heretic_dance_queued_switch/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	dance.combat_resource = 6
	set_dance_beat(dance, 1, 4)
	TEST_ASSERT(dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO), "Танго встаёт в очередь.")
	TEST_ASSERT_EQUAL(dance.pending_style_id, HERETIC_DANCE_STYLE_TANGO, "Ждёт сильной доли.")
	dance.stop_clock()
	dance.beat_index = dance.meter - 1
	set_dance_beat(dance, dance.meter)
	dance.on_beat()
	TEST_ASSERT_EQUAL(dance.style_id, HERETIC_DANCE_STYLE_TANGO, "На сильной доле вступает Танго.")
	TEST_ASSERT_NULL(dance.pending_style_id, "Очередь пуста.")
	TEST_ASSERT_EQUAL(dance.combat_resource, 6, "Такт сохранён.")
	TEST_ASSERT(!dance.link_bonus, "Вступление по очереди акцент не удваивает.")
	TEST_ASSERT_EQUAL(dance.beat_ds, 7.5, "Часы идут в темпе Танго.")

/// Перезарядка фигуры идёт в долях подряд и не начинается заново от смены стиля.
/datum/unit_test/heretic_dance_figure_cooldown_switch/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	dance.figure_ready_beat = dance.beat_total + 4
	set_dance_beat(dance, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO)
	TEST_ASSERT(dance.figure_ready_beat - dance.beat_total <= 4, "Смена стиля не отодвигает готовность фигуры.")

/// Фриз сервера: сетка долей догоняет музыку клиента, действия сразу после фриза не считаются промахом и не рвут фигуру.
/datum/unit_test/heretic_dance_lag/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	start_dance_music(dance)
	set_dance_beat(dance, 1, 4)
	TEST_ASSERT_EQUAL(dance.timing(user), HERETIC_DANCE_MISS, "Без лага между долями - мимо.")
	set_dance_beat(dance, 1, 4)
	var/origin = dance.beat_origin
	dance.bar_real_start -= 8
	TEST_ASSERT_EQUAL(dance.timing(user), HERETIC_DANCE_ON_BEAT, "Сразу после фриза промах прощается.")
	TEST_ASSERT(abs(origin - 8 - dance.beat_origin) < 1, "Сетка долей сдвинулась вслед за музыкой.")
	set_dance_beat(dance, 1)
	dance.on_dance_step(user, NORTH)
	dance.bar_real_start -= 3
	dance.on_dance_step(user, EAST)
	TEST_ASSERT_EQUAL(length(dance.figure_steps), 2, "Шаги, пришедшие пачкой после фриза, не рвут рисунок.")

/// Болеро: темп Болеро поверх стиля, пассивка Танго работает, пока танцуете Вальс.
/datum/unit_test/heretic_dance_bolero_passives/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	dance.start_bolero()
	TEST_ASSERT_EQUAL(dance.beat_ds, HERETIC_DANCE_BOLERO_BEAT, "Болеро задаёт свой темп.")
	TEST_ASSERT_EQUAL(dance.meter, HERETIC_DANCE_BOLERO_METER, "Болеро задаёт свой размер.")
	dance.set_bolero_stage(2)
	TEST_ASSERT_EQUAL(dance.style_id, HERETIC_DANCE_STYLE_WALTZ, "Танцуется Вальс.")
	var/before = victim.getBruteLoss()
	dance.register_strike(user, victim, HERETIC_DANCE_ON_BEAT, FALSE, TRUE)
	TEST_ASSERT_EQUAL(round(victim.getBruteLoss() - before, 0.01), HERETIC_DANCE_TANGO_BONUS, "Удержанная Болеро пассивка Танго добавляет урон в Вальсе.")
	dance.stop_bolero()
	TEST_ASSERT_EQUAL(dance.beat_ds, 8.5, "Конец Болеро возвращает темп стиля.")

/// Все восемь фраз стиля идут в ход.
/datum/unit_test/heretic_dance_phrases/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/datum/heretic_dance_style/style = dance.current_style()
	var/list/heard = list()
	for(var/bar in 1 to 200)
		heard |= dance.next_phrase(style)
	TEST_ASSERT_EQUAL(length(heard), length(style.phrases), "Звучат все фразы стиля.")

/// Урок Пляски проходит пять шагов по настоящим действиям: удары в долю, квадрат, смена стиля, приглашение, спасение.
/datum/unit_test/heretic_dance_lesson/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/target = allocate_dance_victim(get_step(user, WEST))
	var/datum/heretic_dance_lesson/lesson = new(null, dance, user, target)
	allocated += lesson
	TEST_ASSERT(heretic.get_knowledge(/datum/eldritch_knowledge/dance_grasp), "Урок открывает Танго.")
	dance.register_strike(user, target, HERETIC_DANCE_MISS, FALSE)
	TEST_ASSERT_EQUAL(lesson.hits, 0, "Удар мимо доли не засчитан.")
	for(var/hit in 1 to 3)
		dance.register_strike(user, target, HERETIC_DANCE_ON_BEAT, FALSE)
	TEST_ASSERT_EQUAL(lesson.stage, 2, "Три удара в долю открывают квадрат.")
	var/index = 1
	for(var/direction in list(NORTH, EAST, SOUTH, WEST))
		set_dance_beat(dance, index++)
		dance.on_dance_step(user, direction)
	TEST_ASSERT_EQUAL(lesson.stage, 3, "Квадрат рядом с мишенью открывает смену стиля.")
	set_dance_beat(dance, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO)
	TEST_ASSERT_EQUAL(lesson.stage, 4, "Смена стиля открывает приглашение.")
	dance.infect(user, target, TRUE)
	TEST_ASSERT(lesson.infected, "Заражение засчитано.")
	SEND_SIGNAL(dance, COMSIG_HERETIC_DANCE_EVENT, "partner", target, null)
	TEST_ASSERT(lesson.finished(), "Без полигона шаг спасения завершается сразу, урок пройден.")

/// Каждая ступень Болеро зовёт призрачную пару вокруг вознёсшегося; конец Болеро их убирает.
/datum/unit_test/heretic_dance_bolero_ghosts/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	dance.start_bolero()
	dance.set_bolero_stage(3)
	TEST_ASSERT_EQUAL(length(dance.bolero_ghosts), 3, "Три ступени - три пары.")
	var/obj/effect/abstract/heretic_dance_ghost/ghost = dance.bolero_ghosts[1]
	TEST_ASSERT(ghost in user.vis_contents, "Пара кружит вокруг вознёсшегося.")
	dance.stop_bolero()
	TEST_ASSERT_EQUAL(length(dance.bolero_ghosts), 0, "Конец Болеро убирает пары.")
	TEST_ASSERT(QDELETED(ghost), "Пара удалена.")

/// Рампа Финала встаёт на клетках края зоны удара.
/datum/unit_test/heretic_dance_finale_zone/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(run_loc_floor_bottom_left)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	dance.mark_finale_zone(FALSE)
	var/turf/edge = locate(user.x + 3, user.y + 1, user.z)
	var/obj/effect/temp_visual/heretic_dance_finale_edge/lamp = locate() in edge
	TEST_ASSERT_NOTNULL(lamp, "На краю зоны стоит рампа.")
	TEST_ASSERT_EQUAL(lamp?.dir, EAST, "Рампа стоит по внешней кромке.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_dance_finale_edge) in get_step(user, NORTHEAST), "Внутри зоны рампы нет.")

/// Пляска смерти с работающей пассивкой оставляет костяные следы там, откуда шагнули.
/datum/unit_test/heretic_dance_bone_steps/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_bell)
	set_dance_beat(dance, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_MACABRE)
	dance.combat_resource = 6
	dance.update_passive()
	var/turf/from = get_turf(user)
	set_dance_beat(dance, 1)
	dance.on_dance_step(user, NORTH, from)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_dance_bone_steps) in from, "Шаг в долю оставил костяной след.")

/// После двух верных шагов прощается один сбой - пропущенная доля или шаг не по рисунку; следующий шаг подсказан.
/datum/unit_test/heretic_dance_figure_slip/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	start_dance_music(dance)
	set_dance_beat(dance, 1)
	dance.on_dance_step(user, NORTH)
	set_dance_beat(dance, 2)
	dance.on_dance_step(user, EAST)
	TEST_ASSERT_EQUAL(dance.next_figure_dir(), SOUTH, "Следующий шаг квадрата - назад.")
	set_dance_beat(dance, 4)
	dance.on_dance_step(user, SOUTH)
	TEST_ASSERT_EQUAL(dance.figure_progress(), 3, "Пропущенная доля после двух верных шагов прощена.")
	set_dance_beat(dance, 6)
	dance.on_dance_step(user, WEST)
	TEST_ASSERT_EQUAL(length(dance.figure_steps), 1, "Второй сбой начинает рисунок заново.")
	set_dance_beat(dance, 11)
	dance.on_dance_step(user, NORTH)
	set_dance_beat(dance, 12)
	dance.on_dance_step(user, EAST)
	set_dance_beat(dance, 13)
	dance.on_dance_step(user, NORTH)
	TEST_ASSERT_EQUAL(dance.figure_progress(), 2, "Шаг не по рисунку прощён и не сбивает начатую фигуру.")
	dance.on_dance_step(user, SOUTH)
	TEST_ASSERT_EQUAL(dance.figure_progress(), 3, "После прощённого шага верный в ту же долю продолжает фигуру.")

/// Квадрат без цели ждёт 4 доли и подхватывает врага, как только тот рядом; предпочитает последнего, по кому ударили.
/datum/unit_test/heretic_dance_figure_held/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	start_dance_music(dance)
	var/index = 1
	for(var/direction in list(NORTH, EAST, SOUTH, WEST))
		set_dance_beat(dance, index++)
		dance.on_dance_step(user, direction)
	TEST_ASSERT(dance.figure_held(), "Квадрат без соседа ждёт цели.")
	var/mob/living/carbon/human/bystander = allocate_dance_victim(get_step(user, WEST))
	var/mob/living/carbon/human/foe = allocate_dance_victim(get_step(user, EAST))
	dance.register_strike(user, foe, HERETIC_DANCE_ON_BEAT, FALSE)
	TEST_ASSERT(foe.has_status_effect(/datum/status_effect/heretic_dance/lead), "Удар по врагу рядом запускает ждущую фигуру на нём.")
	TEST_ASSERT(!bystander.has_status_effect(/datum/status_effect/heretic_dance/lead), "Квадрат подхватывает того, по кому ударили.")
	TEST_ASSERT(!dance.figure_held(), "Сработавшая фигура больше не ждёт.")
	TEST_ASSERT(dance.figure_ready_beat > dance.beat_total, "Сработавшая фигура остывает.")

/// Ждущая фигура рассыпается через 4 доли без цели.
/datum/unit_test/heretic_dance_figure_held_expires/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	start_dance_music(dance)
	var/index = 1
	for(var/direction in list(NORTH, EAST, SOUTH, WEST))
		set_dance_beat(dance, index++)
		dance.on_dance_step(user, direction)
	dance.beat_total += 5
	dance.try_held_figure(user)
	TEST_ASSERT(!dance.figure_held(), "Фигура рассыпалась.")
	TEST_ASSERT_EQUAL(dance.held_figure_until, -1, "Ожидание снято.")
	TEST_ASSERT(dance.figure_ready_beat <= dance.beat_total, "Несработавшая фигура не уходит на перезарядку.")

/// Клавиша прошлого стиля возвращает стиль, из которого ушли.
/datum/unit_test/heretic_dance_previous_style/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	TEST_ASSERT(!dance.hotkey_style(user, null), "Прошлого стиля ещё нет.")
	TEST_ASSERT(!dance.hotkey_style(user, HERETIC_DANCE_STYLE_TANGO), "Закрытый стиль клавишей не выбирается.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	set_dance_beat(dance, 3)
	TEST_ASSERT(dance.hotkey_style(user, HERETIC_DANCE_STYLE_TANGO), "Клавиша стиля меняет стиль.")
	TEST_ASSERT_EQUAL(dance.style_id, HERETIC_DANCE_STYLE_TANGO, "Танцуется Танго.")
	set_dance_beat(dance, 4)
	TEST_ASSERT(dance.hotkey_style(user, null), "Клавиша прошлого стиля срабатывает.")
	TEST_ASSERT_EQUAL(dance.style_id, HERETIC_DANCE_STYLE_WALTZ, "Вернулся Вальс.")
	TEST_ASSERT_EQUAL(dance.previous_style_id, HERETIC_DANCE_STYLE_TANGO, "Прошлым стал Танго.")

/// Фраза такта Болеро одна на такт для танцоров и всего уровня.
/datum/unit_test/heretic_dance_bolero_phrase/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	dance.start_bolero()
	var/list/heard = list()
	for(var/bar in 1 to 20)
		dance.beat_total++
		var/phrase = dance.bolero_phrase()
		for(var/listener in 1 to 5)
			TEST_ASSERT_EQUAL(dance.bolero_phrase(), phrase, "Все слышат в такте одну фразу.")
		heard |= phrase
	TEST_ASSERT(length(heard) > 1, "Такты Болеро не повторяют одну фразу.")
	dance.stop_bolero()

/// Сработавшая новая фигура забирает ждущую: второй раз старая не сработает.
/datum/unit_test/heretic_dance_figure_held_consumed/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	start_dance_music(dance)
	var/index = 1
	for(var/direction in list(NORTH, EAST, SOUTH, WEST))
		set_dance_beat(dance, index++)
		dance.on_dance_step(user, direction)
	TEST_ASSERT(dance.figure_held(), "Квадрат без соседа ждёт цели.")
	var/mob/living/carbon/human/partner = allocate_dance_victim(get_step(user, EAST))
	for(var/direction in list(NORTH, EAST, SOUTH, WEST))
		set_dance_beat(dance, index++)
		dance.on_dance_step(user, direction)
	TEST_ASSERT(partner.has_status_effect(/datum/status_effect/heretic_dance/lead), "Новый квадрат подхватил соседа.")
	TEST_ASSERT_EQUAL(dance.held_figure_until, -1, "Ждущая фигура израсходована новой.")

/// Окна точности: Тарантелла уже, запас на джиттер расширяет их, но не больше 0,5 дс.
/datum/unit_test/heretic_dance_jitter_slack/Run()
	TEST_ASSERT_EQUAL(heretic_dance_grade(0.9), HERETIC_DANCE_PERFECT, "Одна десятая секунды от доли - точно.")
	TEST_ASSERT_EQUAL(heretic_dance_grade(0.9, 0.6), HERETIC_DANCE_ON_BEAT, "В Тарантелле то же отклонение уже только в долю.")
	TEST_ASSERT_EQUAL(heretic_dance_grade(0.9, 0.6, heretic_dance_jitter_slack(80)), HERETIC_DANCE_PERFECT, "Джиттер 80 мс возвращает точность Тарантелле.")
	TEST_ASSERT_EQUAL(heretic_dance_jitter_slack(0), 0, "Без джиттера запаса нет.")
	TEST_ASSERT_EQUAL(heretic_dance_jitter_slack(1000), HERETIC_DANCE_JITTER_SLACK_CAP, "Запас ограничен сверху.")
	TEST_ASSERT_EQUAL(heretic_dance_grade(2.5 + HERETIC_DANCE_JITTER_SLACK_CAP + 0.2, 1, heretic_dance_jitter_slack(1000)), HERETIC_DANCE_MISS, "Даже с запасом между долями - мимо.")

/// Музыка идёт периодом: вступление, куплет и сбивка перед сменой стиля; после смены - снова вступление.
/datum/unit_test/heretic_dance_phrase_period/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/datum/heretic_dance_style/style = dance.current_style()
	dance.music_entry = TRUE
	TEST_ASSERT_EQUAL(dance.next_phrase(style), style.phrase(8), "Музыка начинается вступлением.")
	for(var/index in 1 to 7)
		TEST_ASSERT_EQUAL(dance.next_phrase(style), style.phrase(index), "Такт [index] периода идёт по порядку.")
	TEST_ASSERT_EQUAL(dance.next_phrase(style), style.phrase(1), "После сбивки период начинается снова.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	set_dance_beat(dance, 1, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO)
	TEST_ASSERT_EQUAL(dance.next_phrase(style), style.phrase(7), "Перед сменой стиля звучит сбивка.")
	set_dance_beat(dance, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO)
	var/datum/heretic_dance_style/tango = dance.current_style()
	TEST_ASSERT_EQUAL(dance.next_phrase(tango), tango.phrase(8), "Новый стиль вступает с вступления.")

/// Завершённая фигура оставляет кульминацию своего стиля, а не общий акцент.
/datum/unit_test/heretic_dance_figure_culmination/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	start_dance_music(dance)
	allocate_dance_victim(get_step(user, EAST))
	var/index = 1
	for(var/direction in list(NORTH, EAST, SOUTH, WEST))
		set_dance_beat(dance, index++)
		dance.on_dance_step(user, direction)
	var/obj/effect/temp_visual/heretic_dance/figure/culmination = locate() in get_turf(user)
	TEST_ASSERT_NOTNULL(culmination, "Квадрат оставил кульминацию.")
	TEST_ASSERT_EQUAL(culmination?.icon_state, "dance_figure_waltz", "Кульминация в рисунке Вальса.")
	TEST_ASSERT(culmination?.icon_state in icon_states(culmination?.icon), "Рисунок кульминации есть в иконке.")
	for(var/id in GLOB.heretic_dance_styles)
		var/datum/heretic_dance_style/style = GLOB.heretic_dance_styles[id]
		TEST_ASSERT("dance_figure_[id]" in icon_states('modular_bluemoon/icons/obj/heretic_dance_effects.dmi'), "У стиля [style.name] есть своя кульминация.")
		TEST_ASSERT(isfile(style.figure_sound), "У стиля [style.name] есть свой звук фигуры.")

/// Растолкавший партнёра видит, как рвётся лента, и получает подтверждение.
/datum/unit_test/heretic_dance_rescue_fx/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/partner = allocate_dance_victim(get_step(user, EAST))
	var/mob/living/carbon/human/helper = allocate_dance_victim(get_step(partner, EAST))
	partner.apply_status_effect(/datum/status_effect/heretic_dance/partner, dance)
	TEST_ASSERT(partner.has_status_effect(/datum/status_effect/heretic_dance/partner), "Партнёр в танце.")
	SEND_SIGNAL(partner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, helper)
	TEST_ASSERT(!partner.has_status_effect(/datum/status_effect/heretic_dance/partner), "Спасатель вырвал партнёра.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_dance/rescue) in get_turf(partner), "Лента рвётся на глазах.")

/// Фальшивая нота рассыпает призрачные пары, конец тишины собирает оркестр обратно.
/datum/unit_test/heretic_dance_false_note_break/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	dance.start_bolero()
	dance.set_bolero_stage(3)
	heretic_dance_false_note(get_turf(user))
	TEST_ASSERT(dance.bolero_broken, "Оркестр сбит.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_dance/false_note) in get_turf(user), "Фальшивую ноту видно.")
	var/obj/effect/abstract/heretic_dance_ghost/ghost = dance.bolero_ghosts[1]
	TEST_ASSERT_EQUAL(ghost.alpha, 0, "Пары рассыпались.")
	dance.bolero_silent_until = 0
	dance.bolero_beat(FALSE)
	TEST_ASSERT(!dance.bolero_broken, "После тишины оркестр вступает снова.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_dance/orchestra_return) in get_turf(user), "Возвращение оркестра видно.")
	TEST_ASSERT_EQUAL(ghost.alpha, initial(ghost.alpha), "Пары вернулись.")
	dance.stop_bolero()

/// Под Болеро сильная доля сбрасывает болу с ног, слабая доля и тишина после фальшивой ноты - нет.
/datum/unit_test/heretic_dance_bolero_fetters/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	dance.start_bolero()
	var/obj/item/restraints/legcuffs/bola/bola = allocate(/obj/item/restraints/legcuffs/bola)
	bola.ensnare(user)
	TEST_ASSERT_EQUAL(user.legcuffed, bola, "Бола опутала танцора.")
	dance.bolero_silent_until = world.time + 10 SECONDS
	dance.bolero_beat(TRUE)
	TEST_ASSERT_EQUAL(user.legcuffed, bola, "Пока Болеро молчит, бола держит.")
	dance.bolero_silent_until = 0
	dance.bolero_beat(FALSE)
	TEST_ASSERT_EQUAL(user.legcuffed, bola, "Слабая доля болу не сбрасывает.")
	dance.bolero_beat(TRUE)
	TEST_ASSERT_NULL(user.legcuffed, "Сильная доля сбросила болу.")
	TEST_ASSERT_EQUAL(bola.loc, get_turf(user), "Бола лежит под ногами.")
	TEST_ASSERT_NULL(user.has_status_effect(/datum/status_effect/bola_snared), "Подножка болы снята.")
	dance.stop_bolero()

/// Большой хоровод не берёт только что отплясавшего и называет это в отказе.
/datum/unit_test/heretic_dance_great_horovod_rest/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	dance.start_bolero()
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(get_step(user, EAST), EAST))
	var/obj/effect/proc_holder/spell/self/heretic_dance/great_horovod/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_dance/great_horovod)
	victim.apply_status_effect(/datum/status_effect/heretic_dance_horovod_rest)
	spell.cast(list(user), user)
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_dance/horovod), "Только что отплясавшего хоровод не берёт.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "Прошлый хоровод"), "Отказ называет недавний хоровод: [spell.heretic_failure_reason]")
	victim.remove_status_effect(/datum/status_effect/heretic_dance_horovod_rest)
	spell.cast(list(user), user)
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_dance/horovod), "Отдохнувшего хоровод берёт.")
	dance.stop_bolero()

/// Перед ударом Финала пары стягиваются к вознёсшемуся, на ударе разлетаются обратно.
/datum/unit_test/heretic_dance_finale_breath/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	dance.start_bolero()
	dance.set_bolero_stage(HERETIC_DANCE_BOLERO_STAGES + 1)
	var/obj/effect/abstract/heretic_dance_ghost/ghost = dance.bolero_ghosts[1]
	dance.beat_index = dance.meter - 1
	dance.bolero_beat(FALSE)
	TEST_ASSERT(ghost.transform.a < 1, "На вдохе пары стянулись.")
	dance.finale_pulse()
	TEST_ASSERT_EQUAL(ghost.transform.a, 1, "После удара пары вернулись на круг.")
	dance.stop_bolero()

/// Схема шагов вне станции ложится, но в дело не идёт.
/datum/unit_test/heretic_dance_diagram_off_station/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/turf/spot = get_step(user, EAST)
	var/progress = heretic.deed.progress
	TEST_ASSERT(dance.draw_diagram(user, spot), "Схема ложится и вне станции.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/heretic_dance_diagram) in spot, "Схема лежит на полу.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, progress, "Схема вне станции в дело не идёт.")
	TEST_ASSERT_EQUAL(heretic.deed.tier, 0, "Ступень дела не растёт.")

/// Хватка в бою тоже заражает человека и копит Такт.
/datum/unit_test/heretic_dance_combat_grasp_infects/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	user.a_intent = INTENT_DISARM
	dance.on_mansus_grasp(victim, user, TRUE)
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_dance_earworm), "Хватка в «Обезоружить» заражает.")
	TEST_ASSERT(dance.combat_resource > 0, "Боевая хватка копит Такт.")

/// Приглашение без заражённых в радиусе отказывает при нажатии кнопки, с заражённым рядом - нет.
/datum/unit_test/heretic_dance_invite_needs_infected/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_invite)
	var/obj/effect/proc_holder/spell/pointed/heretic_dance/invite/spell = locate() in user.mind.spell_list
	TEST_ASSERT_NOTNULL(spell, "Приглашение выучено.")
	spell.Trigger(user)
	TEST_ASSERT(!spell.active, "Без заражённых прицел не берётся.")
	TEST_ASSERT_NOTNULL(spell.heretic_failure_reason, "Отказ объяснён сразу.")
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(get_step(user, EAST), EAST))
	dance.infect(user, victim)
	TEST_ASSERT_NULL(dance.invite_idle_reason(user), "Заражённый в радиусе - Приглашению есть кого звать.")

/// Барабан принимает удар чуть раньше доли, на которой он готов.
/datum/unit_test/heretic_dance_drum_early/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_drum)
	var/obj/item/heretic_path_relic/dance/drum = allocate(/obj/item/heretic_path_relic/dance, get_turf(user))
	drum.creator = WEAKREF(heretic.owner)
	drum.knowledge_ref = WEAKREF(heretic.get_knowledge(/datum/eldritch_knowledge/spell/dance_drum))
	TEST_ASSERT(user.put_in_hands(drum), "Барабан берётся в руку.")
	drum.ready_beat = dance.beat_total + 1
	set_dance_beat(dance, 2, 4)
	TEST_ASSERT(!drum.beat(user), "Мимо доли до готовности барабан молчит.")
	set_dance_beat(dance, 2, -1)
	TEST_ASSERT(drum.beat(user), "Удар чуть раньше готовой доли засчитан.")

/// Такт сверх 4 добавляет удару клинком в долю урон; удар мимо доли прибавки не получает.
/datum/unit_test/heretic_dance_crescendo/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	dance.combat_resource = HERETIC_DANCE_TAKT_MAX
	dance.register_strike(user, victim, HERETIC_DANCE_MISS, FALSE, TRUE)
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Мимо доли крещендо молчит.")
	dance.combat_resource = HERETIC_DANCE_TAKT_MAX
	dance.register_strike(user, victim, HERETIC_DANCE_ON_BEAT, FALSE, TRUE)
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), HERETIC_DANCE_TAKT_MAX - HERETIC_DANCE_PASSIVE_TAKT, "Удар в долю при 10 Такта: +6 урона.")

/// Акценты: Вальс выматывает, Танго валит одну цель не чаще раза в 6 секунд, Канкан бросает одну цель не чаще, Пляска смерти тянет ударенного.
/datum/unit_test/heretic_dance_accents/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	var/datum/heretic_dance_style/waltz = GLOB.heretic_dance_styles[HERETIC_DANCE_STYLE_WALTZ]
	waltz.accent(dance, user, victim, 1)
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), HERETIC_DANCE_ACCENT_STAMINA, "Акцент Вальса выматывает.")
	victim.setStaminaLoss(0)
	var/datum/heretic_dance_style/tango = GLOB.heretic_dance_styles[HERETIC_DANCE_STYLE_TANGO]
	tango.accent(dance, user, victim, 1)
	var/datum/status_effect/heretic_dance_dipped/dipped = victim.has_status_effect(/datum/status_effect/heretic_dance_dipped)
	TEST_ASSERT_NOTNULL(dipped, "Кортэ Танго запоминает цель.")
	TEST_ASSERT(round(dipped.duration - world.time, 0.1) <= HERETIC_DANCE_ACCENT_LOCK, "Замок кортэ - 6 секунд: [dipped.duration - world.time] дс.")
	victim.SetKnockdown(0)
	victim.setStaminaLoss(0)
	victim.forceMove(get_step(user, EAST))
	var/datum/heretic_dance_style/cancan = GLOB.heretic_dance_styles[HERETIC_DANCE_STYLE_CANCAN]
	cancan.accent(dance, user, victim, 1)
	TEST_ASSERT_NOTNULL(victim.throwing, "Мах Канкана бросает цель.")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_dance_kicked), "Мах запоминает цель.")
	QDEL_NULL(victim.throwing)
	victim.forceMove(get_step(user, EAST))
	cancan.accent(dance, user, victim, 1)
	TEST_ASSERT_NULL(victim.throwing, "Второй мах в замке не бросает.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 40, "Но выматывает оба раза.")
	victim.setStaminaLoss(0)
	var/mob/living/carbon/human/far = allocate_dance_victim(get_step(get_step(user, NORTH), NORTH))
	var/datum/heretic_dance_style/macabre = GLOB.heretic_dance_styles[HERETIC_DANCE_STYLE_MACABRE]
	macabre.accent(dance, user, far, 1)
	TEST_ASSERT_EQUAL(get_dist(user, far), 1, "Колокол тянет ударенного к танцору.")
	TEST_ASSERT_EQUAL(far.getStaminaLoss(), HERETIC_DANCE_ACCENT_STAMINA, "И выматывает его.")

/// Акцент Тарантеллы бьёт по стакам, не сжигая их; метка сжигает стаки вдвое сильнее.
/datum/unit_test/heretic_dance_tarantella_accent/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	for(var/bite in 1 to 3)
		victim.apply_status_effect(/datum/status_effect/heretic_dance/tarantism, dance)
	var/datum/heretic_dance_style/tarantella = GLOB.heretic_dance_styles[HERETIC_DANCE_STYLE_TARANTELLA]
	tarantella.accent(dance, user, victim, 1)
	var/datum/status_effect/heretic_dance/tarantism/stacks = victim.has_status_effect(/datum/status_effect/heretic_dance/tarantism)
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 15, "Акцент бьёт 5 за стак.")
	TEST_ASSERT_EQUAL(stacks?.stacks, 3, "Обычный акцент стаки не сжигает.")
	tarantella.accent(dance, user, victim, 2)
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 45, "Двойной акцент бьёт 10 за стак.")
	TEST_ASSERT(QDELETED(stacks), "Двойной акцент сжигает стаки.")

/// Партнёр не выходит из танца, пока сердце прижимает его к двери.
/datum/unit_test/heretic_dance_partner_waits_for_heart/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/partner = allocate_dance_victim(get_step(user, EAST))
	var/datum/status_effect/heretic_dance/partner/effect = partner.apply_status_effect(/datum/status_effect/heretic_dance/partner, dance)
	TEST_ASSERT(partner.IsParalyzed(), "Партнёр замирает целиком, руки тоже.")
	heretic_door_grip(partner, 3 SECONDS)
	effect.duration = world.time - 1
	effect.process()
	TEST_ASSERT(!QDELETED(effect), "Под хваткой двери партнёр ждёт.")
	partner.remove_status_effect(/datum/status_effect/heretic_door_grip)
	effect.duration = world.time - 1
	effect.process()
	TEST_ASSERT(QDELETED(effect), "Без хватки двери танец кончается в срок.")
	TEST_ASSERT(!partner.IsParalyzed(), "Конец танца отпускает партнёра.")

/// В меню стиля каждый выученный танец подписан своей ролью.
/datum/unit_test/heretic_dance_style_roles/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	for(var/id in GLOB.heretic_dance_styles)
		var/datum/heretic_dance_style/style = GLOB.heretic_dance_styles[id]
		TEST_ASSERT(length(style.role), "У стиля [style.name] есть роль.")
	var/datum/heretic_dance_style/waltz = GLOB.heretic_dance_styles[HERETIC_DANCE_STYLE_WALTZ]
	var/list/choices = dance.style_choices()
	TEST_ASSERT_EQUAL(choices["[waltz.name] - [waltz.role]"], HERETIC_DANCE_STYLE_WALTZ, "Вальс в меню подписан ролью.")
	TEST_ASSERT_EQUAL(length(choices), 1, "В меню только выученные стили.")

/// Отказ сердца по несломленной цели напоминает способ захвата своего пути.
/datum/unit_test/heretic_dance_capture_hint/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_DANCE]
	TEST_ASSERT(findtext(heretic.hunt_not_ready_reason(), path.capture_summary), "Отказ называет способ захвата Пляски.")

/datum/unit_test/proc/dance_figure(datum/eldritch_knowledge/base_dance/dance, mob/living/user, list/directions)
	var/index = 1
	for(var/direction in directions)
		set_dance_beat(dance, index++)
		dance.on_dance_step(user, direction)

/datum/unit_test/proc/dance_link(datum/eldritch_knowledge/base_dance/dance, mob/living/user, style_id)
	set_dance_beat(dance, dance.meter)
	dance.switch_style(user, style_id)

/// Номер «Па-де-де»: после квадрата связка в Танго и очо делают ведомого партнёром на 3 секунды, цель охоты - на 6.
/datum/unit_test/heretic_dance_routine_pas_de_deux/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, WEST))
	start_dance_music(dance)
	dance_figure(dance, user, list(NORTH, EAST, SOUTH, WEST))
	dance_link(dance, user, HERETIC_DANCE_STYLE_TANGO)
	TEST_ASSERT_EQUAL(dance.armed_routine?.id, "pas_de_deux", "Связка в Танго после квадрата открыла номер.")
	var/datum/status_effect/heretic_dance/lead/lead = victim.has_status_effect(/datum/status_effect/heretic_dance/lead)
	TEST_ASSERT(lead?.duration >= dance.routine_until, "Ведение держится до конца номера.")
	dance_figure(dance, user, list(EAST, WEST, EAST))
	var/datum/status_effect/heretic_dance/partner/partner = victim.has_status_effect(/datum/status_effect/heretic_dance/partner)
	TEST_ASSERT_NOTNULL(partner, "Очо опрокинуло ведомого в кортэ: он партнёр.")
	TEST_ASSERT(round(partner.duration - world.time, 0.1) <= 3 SECONDS, "Не цель охоты держится партнёром 3 секунды: [partner.duration - world.time] дс.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_dance/lead), "Ведение сменилось партнёрством.")
	TEST_ASSERT(dance.door_holds(user, victim), "Партнёра из номера сердце уводит в изнанку.")
	TEST_ASSERT_NULL(dance.armed_routine, "Исполненный номер закрыт.")
	var/mob/living/carbon/human/target = allocate_dance_victim(get_step(user, NORTH))
	heretic.hunt_target = target.mind
	dance.routine_ready_at = 0
	victim.remove_status_effect(/datum/status_effect/heretic_dance/partner)
	victim.forceMove(run_loc_floor_top_right)
	dance_link(dance, user, HERETIC_DANCE_STYLE_WALTZ)
	dance.figure_ready_beat = 0
	dance_figure(dance, user, list(NORTH, EAST, SOUTH, WEST))
	TEST_ASSERT(target.has_status_effect(/datum/status_effect/heretic_dance/lead), "Квадрат повёл цель охоты.")
	dance_link(dance, user, HERETIC_DANCE_STYLE_TANGO)
	dance_figure(dance, user, list(EAST, WEST, EAST))
	partner = target.has_status_effect(/datum/status_effect/heretic_dance/partner)
	TEST_ASSERT(partner && round(partner.duration - world.time, 0.1) >= HERETIC_DANCE_PARTNER_TIME, "Цель охоты держится партнёром [HERETIC_DANCE_PARTNER_TIME / (1 SECONDS)] секунд.")

/// Номер «Пляска мертвецов»: после линии Канкана связка в Пляску смерти и процессия тянут в хоровод на 6 секунд из 4 клеток.
/datum/unit_test/heretic_dance_routine_danse_macabre/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(run_loc_floor_bottom_left)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_masquerade)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_bell)
	user.setDir(SOUTH)
	var/mob/living/carbon/human/far = allocate_dance_victim(locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z))
	start_dance_music(dance)
	dance_link(dance, user, HERETIC_DANCE_STYLE_CANCAN)
	dance_figure(dance, user, list(NORTH, NORTH, SOUTH, SOUTH))
	dance_link(dance, user, HERETIC_DANCE_STYLE_MACABRE)
	TEST_ASSERT_EQUAL(dance.armed_routine?.id, "danse_macabre", "Связка в Пляску смерти после линии открыла номер.")
	dance_figure(dance, user, list(NORTH, NORTH, NORTH, NORTH))
	var/datum/status_effect/heretic_dance/horovod/horovod = far.has_status_effect(/datum/status_effect/heretic_dance/horovod)
	TEST_ASSERT_NOTNULL(horovod, "Хоровод номера достал врага в [get_dist(user, far)] клетках.")
	TEST_ASSERT(horovod?.duration - world.time >= 6 SECONDS - 1, "Хоровод номера длится 6 секунд.")

/// Номер «Танго смерти»: после очо связка в Тарантеллу и четыре точных укуса срывают цель в долгую пляску и взрывают тарантизм на 32 ушиба.
/datum/unit_test/heretic_dance_routine_death_tango/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_drum)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	start_dance_music(dance)
	dance_link(dance, user, HERETIC_DANCE_STYLE_TANGO)
	dance_figure(dance, user, list(EAST, WEST, EAST))
	dance_link(dance, user, HERETIC_DANCE_STYLE_TARANTELLA)
	TEST_ASSERT_EQUAL(dance.armed_routine?.id, "death_tango", "Связка в Тарантеллу после очо открыла номер.")
	var/brute_before = 0
	for(var/bite in 1 to HERETIC_DANCE_BITE_HITS)
		dance.combat_resource = 0
		brute_before = victim.getBruteLoss()
		dance.register_strike(user, victim, HERETIC_DANCE_PERFECT, FALSE, TRUE)
	var/datum/status_effect/heretic_dance/frenzy/frenzy = victim.has_status_effect(/datum/status_effect/heretic_dance/frenzy)
	TEST_ASSERT(frenzy?.duration - world.time >= 6 SECONDS - 1, "Укусы номера срывают цель в пляску на 6 секунд.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_dance/tarantism), "Номер взорвал тарантизм.")
	TEST_ASSERT_EQUAL(round(victim.getBruteLoss() - brute_before, 0.01), 32, "Взрыв тарантизма номера - 32 ушиба.")

/// Номер «Исчезновение»: после процессии связка в Канкан и линия надевают маску и дают рывок со скоростью.
/datum/unit_test/heretic_dance_routine_vanishing/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(run_loc_floor_bottom_left)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_masquerade)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_bell)
	user.setDir(SOUTH)
	allocate_dance_victim(get_step(user, NORTHEAST))
	start_dance_music(dance)
	dance_link(dance, user, HERETIC_DANCE_STYLE_MACABRE)
	dance_figure(dance, user, list(NORTH, NORTH, NORTH, NORTH))
	dance_link(dance, user, HERETIC_DANCE_STYLE_CANCAN)
	TEST_ASSERT_EQUAL(dance.armed_routine?.id, "vanishing", "Связка в Канкан после процессии открыла номер.")
	dance_figure(dance, user, list(NORTH, NORTH, SOUTH, SOUTH))
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_dance/masquerade), "Номер надел маску.")
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_dance_glide), "Номер разогнал танцора.")

/// Смена стиля мимо сильной доли номер не открывает.
/datum/unit_test/heretic_dance_routine_needs_link/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	allocate_dance_victim(get_step(user, WEST))
	start_dance_music(dance)
	dance_figure(dance, user, list(NORTH, EAST, SOUTH, WEST))
	set_dance_beat(dance, 1)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO)
	TEST_ASSERT_EQUAL(dance.style_id, HERETIC_DANCE_STYLE_TANGO, "Повторный выбор сменил стиль сразу.")
	TEST_ASSERT_NULL(dance.armed_routine, "Торопливая смена номер не открыла.")

/// У каждого номера своя кульминация в иконке и свой звук; кульминация остаётся там, где номер начался.
/datum/unit_test/heretic_dance_routine_assets/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	for(var/id in GLOB.heretic_dance_routines)
		var/datum/heretic_dance_routine/routine = GLOB.heretic_dance_routines[id]
		TEST_ASSERT("dance_routine_[id]" in icon_states('modular_bluemoon/icons/obj/heretic_dance_effects.dmi'), "У номера [routine.name] есть кульминация.")
		TEST_ASSERT(isfile(routine.sound), "У номера [routine.name] есть свой звук.")
	var/turf/stage = get_turf(user)
	var/datum/heretic_dance_routine/vanishing = GLOB.heretic_dance_routines["vanishing"]
	user.forceMove(get_step(stage, NORTH))
	dance.routine_fx(user, vanishing, stage)
	var/obj/effect/temp_visual/heretic_dance/routine/culmination = locate() in stage
	TEST_ASSERT_EQUAL(culmination?.icon_state, "dance_routine_vanishing", "Кульминация Исчезновения осталась на месте рывка.")

/// Кольцо доли и ромбы фигуры висят на прозрачной для мыши опоре в vis_contents танцора, а не на нём самом.
/datum/unit_test/heretic_dance_hints_click_through/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	dance.cue_ring = dance.body_hint_image('modular_bluemoon/icons/obj/heretic_dance_effects.dmi', "dance_cue_ring")
	dance.figure_hud = dance.body_hint_image('modular_bluemoon/icons/obj/heretic_dance_marks.dmi')
	var/image/ring = dance.cue_ring
	var/obj/effect/abstract/heretic_vfx_image_anchor/anchor = ring.loc
	TEST_ASSERT(istype(anchor), "Кольцо доли висит на опоре, а не на танцоре.")
	TEST_ASSERT_EQUAL(dance.figure_hud.loc, anchor, "Подсказки на теле делят одну опору.")
	TEST_ASSERT(anchor in user.vis_contents, "Опора в vis_contents танцора и ходит вместе с ним.")
	TEST_ASSERT_EQUAL(anchor.mouse_opacity, MOUSE_OPACITY_TRANSPARENT, "Опора не ловит клики.")
	TEST_ASSERT(!(anchor.vis_flags & VIS_INHERIT_ID), "Опора не выдаёт себя за танцора.")
	dance.clear_hints()
	TEST_ASSERT(QDELETED(anchor), "Снятые подсказки удаляют опору.")
	TEST_ASSERT(!(anchor in user.vis_contents), "Удалённая опора уходит из vis_contents танцора.")
	TEST_ASSERT_NULL(ring.loc, "Снятое кольцо не держит удалённую опору.")
